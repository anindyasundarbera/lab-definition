#!/usr/bin/env bash
# OH-001D Stage 5 lifecycle acceptance for the OpenHands Agent Server adapter.
#
# Drives the Agent Lab lifecycle adapter (`lab openhands start/stop/status`)
# against a disposable workspace and verifies the OH-001D Stage 5 isolation
# and image contract invariants on the actual container. It performs NO
# conversation/LLM/provider/tool/agent task: the only runtime probe is the
# authenticated metadata endpoint `/server_info`.
#
# Never prints secrets or response bodies. Required PASS markers are emitted
# only when their corresponding check passes.
set -euo pipefail

# ---------------------------------------------------------------------------
# Script path and root derivation (mirrors bin/lab / acceptance convention).
# ---------------------------------------------------------------------------
resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local dir

    while [[ -h "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "$source")"

        if [[ "$source" != /* ]]; then
            source="$dir/$source"
        fi
    done

    dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
    printf '%s/%s\n' "$dir" "$(basename "$source")"
}

SCRIPT_PATH="$(resolve_script_path)"

if [[ -n "${LAB_DEFINITION_ROOT:-}" ]]; then
    LAB_DEFINITION_ROOT="$(cd "$LAB_DEFINITION_ROOT" && pwd -P)"
else
    LAB_DEFINITION_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd -P)"
fi

if [[ -n "${LAB_ROOT:-}" ]]; then
    LAB_ROOT="$(cd "$LAB_ROOT" && pwd -P)"
else
    LAB_ROOT="$(cd "$LAB_DEFINITION_ROOT/.." && pwd -P)"
fi

export LAB_ROOT
export LAB_DEFINITION_ROOT
export LAB_WORKSPACES_ROOT="${LAB_ROOT}/workspaces"

LAB_BIN="$LAB_DEFINITION_ROOT/bin/lab"

# Immutable image contract (must match the adapter exactly).
readonly OH_IMAGE_REF="ghcr.io/openhands/agent-server@sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02"
readonly OH_PLATFORM="linux/amd64"

# State/credential locations (must match the adapter).
OH_STATE_DIR="${LAB_ROOT}/state/openhands"
OH_STATE_FILE="${OH_STATE_DIR}/instance.state"
OH_CRED_FILE="${OH_STATE_DIR}/credentials.env"
OH_SECRET_DIR="${LAB_ROOT}/secrets/openhands"
OH_SECRET_FILE="${OH_SECRET_DIR}/oh-secret-key"

FAILURES=0

# Ownership safety: this test may stop ONLY an instance it successfully
# started and that still binds to the same recorded container id. A
# pre-existing instance is never stopped by this test.
STARTED_BY_TEST=0
TEST_CID=""

# Temp header file holding the Authorization header for authenticated probes,
# so the secret never appears on the curl argv. Created lazily in the auth
# section; the EXIT trap and the post-probe cleanup both remove it.
AUTH_HEADER_FILE=""

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; FAILURES=$((FAILURES + 1)); }
mark() { printf '%s=PASS\n' "$1"; }

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

# Safe, non-executable key=value parser (never sources state/credential files).
state_get() {
    local file="$1"
    local key="$2"
    local line

    [[ -r "$file" ]] || return 1

    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            "${key}="*)
                printf '%s\n' "${line#${key}=}"
                return 0
                ;;
        esac
    done < "$file"

    return 1
}

# Portable octal permission reader. Tries GNU `stat -c '%a'`, then BSD/macOS
# `stat -f '%Lp'`; fails (returns 1) if neither works. No Perl/Python.
file_mode() {
    local path="$1"
    local mode

    if mode="$(stat -c '%a' "$path" 2>/dev/null)"; then
        printf '%s\n' "$mode"
        return 0
    fi
    if mode="$(stat -f '%Lp' "$path" 2>/dev/null)"; then
        printf '%s\n' "$mode"
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Disposable acceptance workspace below $LAB_ROOT/workspaces/.
# ---------------------------------------------------------------------------
ACCEPTANCE_WS_BASE="$LAB_WORKSPACES_ROOT/acceptance"
ACCEPTANCE_WS="${ACCEPTANCE_WS_BASE}/openhands-lifecycle-$$-$(date +%s)"

cleanup() {
    local err=$?

    # Stop ONLY an instance this test successfully started and that still
    # binds to the same recorded container id. Never stop a pre-existing
    # instance, even on failure.
    if [[ "${STARTED_BY_TEST:-0}" -eq 1 && -n "${TEST_CID:-}" && -f "$OH_STATE_FILE" ]]; then
        local bound_cid
        if bound_cid="$(state_get "$OH_STATE_FILE" container_id 2>/dev/null)" \
           && [[ "$bound_cid" == "$TEST_CID" ]]; then
            bash "$LAB_BIN" openhands stop >/dev/null 2>&1 || true
        fi
    fi

    # Always remove only this test's uniquely constructed workspace. The
    # persistent OH_SECRET_KEY is never removed by this trap. Also remove the
    # temp Authorization header file if it was created (fallback; the auth
    # section removes it immediately after the probes).
    rm -rf "$ACCEPTANCE_WS" >/dev/null 2>&1 || true
    rm -f "$AUTH_HEADER_FILE" >/dev/null 2>&1 || true
    return $err
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Preconditions.
# ---------------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    die "docker is required for this acceptance test"
fi
if ! docker info >/dev/null 2>&1; then
    die "docker daemon is not reachable"
fi
if ! command -v curl >/dev/null 2>&1; then
    die "curl is required for this acceptance test"
fi

echo "OpenHands Lifecycle Acceptance (OH-001D Stage 5)"
echo "================================================"
echo
echo "LAB_ROOT:           $LAB_ROOT"
echo "LAB_DEFINITION_ROOT: $LAB_DEFINITION_ROOT"
echo "Adapter:            $LAB_BIN openhands"
echo "Image:              $OH_IMAGE_REF"
echo "Platform:           $OH_PLATFORM"
echo

# Canonical definition HEAD/status snapshot; must be unchanged on exit.
canon_head_before="$(git -C "$LAB_DEFINITION_ROOT" rev-parse HEAD 2>/dev/null || true)"
canon_status_before="$(git -C "$LAB_DEFINITION_ROOT" status --porcelain 2>/dev/null || true)"

# Container inventory snapshot; must be unchanged after stop.
inventory_before="$(docker ps -aq | sort)"

# Ownership safety: require NO managed OpenHands instance/state is active for
# this acceptance before we start one. This test must never run against, or
# clobber, a pre-existing managed instance.
if [[ -f "$OH_STATE_FILE" ]]; then
    die "managed OpenHands instance state already exists at $OH_STATE_FILE; refusing to run acceptance against a pre-existing instance. Run 'lab openhands stop' first."
fi
if docker inspect agent-lab-openhands >/dev/null 2>&1; then
    die "a container named 'agent-lab-openhands' already exists; refusing to run acceptance against a pre-existing instance."
fi

# Create the disposable acceptance workspace with a sentinel.
mkdir -p "$ACCEPTANCE_WS"
printf 'openhands-lifecycle-acceptance-sentinel\n' > "$ACCEPTANCE_WS/SENTINEL"

echo "Workspace:          $ACCEPTANCE_WS"
echo

# ---------------------------------------------------------------------------
# Start ONLY through the adapter.
# ---------------------------------------------------------------------------
echo "=== Start via adapter ==="
if ! bash "$LAB_BIN" openhands start "$ACCEPTANCE_WS"; then
    fail "adapter start returned non-zero"
    exit 1
fi

if [[ ! -f "$OH_STATE_FILE" ]]; then
    fail "adapter did not write instance state"
    exit 1
fi

CID="$(state_get "$OH_STATE_FILE" container_id)" || { fail "state missing container_id"; exit 1; }
RECORDED_IMAGE_ID="$(state_get "$OH_STATE_FILE" image_id)" || RECORDED_IMAGE_ID=""
RECORDED_PORT="$(state_get "$OH_STATE_FILE" host_port)" || RECORDED_PORT=""

if [[ -z "$CID" ]]; then
    fail "recorded container id is empty"
    exit 1
fi

# A non-empty CID is now bound: the EXIT trap may stop it (and only it) if
# state still binds this CID. Set this BEFORE the presence check so the trap
# can clean up state/container if that check fails.
STARTED_BY_TEST=1
TEST_CID="$CID"

if ! docker inspect "$CID" >/dev/null 2>&1; then
    fail "managed container $CID is not present after start"
    exit 1
fi

pass "adapter started managed container $CID"
echo

# ---------------------------------------------------------------------------
# Image contract: exact image/ref/id + linux/amd64 + baked entrypoint/cmd/user.
# ---------------------------------------------------------------------------
echo "=== Image contract ==="

config_image="$(docker inspect "$CID" --format '{{.Config.Image}}')"
container_image_id="$(docker inspect "$CID" --format '{{.Image}}')"
local_image_id="$(docker image inspect "$OH_IMAGE_REF" --format '{{.Id}}')"
image_platform="$(docker image inspect "$OH_IMAGE_REF" --format '{{.Os}}/{{.Architecture}}')"
# RepoDigests carries the digest-qualified pull ref. .Id must NOT be assumed
# to equal the manifest digest; the authoritative immutable-image check is
# that RepoDigests contains the exact digest-qualified ref. RepoDigests is not
# secret, but never print response bodies elsewhere.
repo_digest="$(docker image inspect "$OH_IMAGE_REF" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)"
# .Platform may be absent on older Docker; treat as best-effort (the image
# platform check above is the authoritative linux/amd64 requirement).
container_platform="$(docker inspect "$CID" --format '{{.Platform}}' 2>/dev/null || true)"

image_contract_ok=1
[[ "$config_image" == "$OH_IMAGE_REF" ]] || { fail "Config.Image is '$config_image', expected immutable ref"; image_contract_ok=0; }
[[ "$container_image_id" == "$local_image_id" ]] || { fail "container image id != local image id"; image_contract_ok=0; }
[[ "$container_image_id" == "$RECORDED_IMAGE_ID" ]] || { fail "container image id != recorded image id"; image_contract_ok=0; }
# Require the exact immutable digest-qualified ref in RepoDigests (not .Id).
[[ "$repo_digest" == "$OH_IMAGE_REF" ]] \
    || { fail "RepoDigests[0] is '$repo_digest', expected exact immutable ref $OH_IMAGE_REF"; image_contract_ok=0; }
[[ "$image_platform" == "$OH_PLATFORM" ]] || { fail "image platform '$image_platform' != '$OH_PLATFORM'"; image_contract_ok=0; }
if [[ -n "$container_platform" && "$container_platform" != "$OH_PLATFORM" ]]; then
    fail "container platform '$container_platform' != '$OH_PLATFORM'"
    image_contract_ok=0
fi

# Baked image contract (OH-001D Stage 5 preflight): Entrypoint
# ["tini","--","/usr/local/bin/openhands-agent-server"], Cmd null,
# User "openhands", WorkingDir "/". The adapter overrides none of these.
entrypoint_json="$(docker inspect "$CID" --format '{{json .Config.Entrypoint}}')"
cmd_json="$(docker inspect "$CID" --format '{{json .Config.Cmd}}')"
config_user="$(docker inspect "$CID" --format '{{.Config.User}}')"
config_workdir="$(docker inspect "$CID" --format '{{.Config.WorkingDir}}')"

[[ "$entrypoint_json" == '["tini","--","/usr/local/bin/openhands-agent-server"]' ]] \
    || { fail "baked Entrypoint is '$entrypoint_json'"; image_contract_ok=0; }
[[ "$cmd_json" == "null" ]] \
    || { fail "baked Cmd is '$cmd_json' (expected null)"; image_contract_ok=0; }
[[ "$config_user" == "openhands" ]] \
    || { fail "baked User is '$config_user' (expected openhands)"; image_contract_ok=0; }
[[ "$config_workdir" == "/" ]] \
    || { fail "baked WorkingDir is '$config_workdir' (expected /)"; image_contract_ok=0; }

if [[ "$image_contract_ok" -eq 1 ]]; then
    pass "image ref/id, linux/amd64, and baked entrypoint/cmd/user/workdir match contract"
fi
echo

# ---------------------------------------------------------------------------
# Container hardening.
# ---------------------------------------------------------------------------
echo "=== Container hardening ==="

privileged="$(docker inspect "$CID" --format '{{.HostConfig.Privileged}}')"
security_json="$(docker inspect "$CID" --format '{{json .HostConfig.SecurityOpt}}')"
capdrop_json="$(docker inspect "$CID" --format '{{json .HostConfig.CapDrop}}')"
env_json="$(docker inspect "$CID" --format '{{json .Config.Env}}')"

hardening_ok=1
[[ "$privileged" == "false" ]] || { fail "Privileged is '$privileged' (expected false)"; hardening_ok=0; }
printf '%s' "$security_json" | grep -q 'no-new-privileges:true' \
    || { fail "no-new-privileges:true not in SecurityOpt"; hardening_ok=0; }
printf '%s' "$capdrop_json" | grep -q '"ALL"' \
    || { fail "cap-drop ALL not present"; hardening_ok=0; }
# OH_ENABLE_VNC=false must be present in the container env.
printf '%s' "$env_json" | grep -q '"OH_ENABLE_VNC=false"' \
    || { fail "OH_ENABLE_VNC=false not in container env"; hardening_ok=0; }
# Secret env names present (values never printed). SESSION_API_KEY/OH_SECRET_KEY.
printf '%s' "$env_json" | grep -q '"SESSION_API_KEY=' \
    || { fail "SESSION_API_KEY env name not present"; hardening_ok=0; }
printf '%s' "$env_json" | grep -q '"OH_SECRET_KEY=' \
    || { fail "OH_SECRET_KEY env name not present"; hardening_ok=0; }

if [[ "$hardening_ok" -eq 1 ]]; then
    pass "privileged=false, no-new-privileges, cap-drop ALL, OH_ENABLE_VNC=false, secret env names present"
    mark "OPENHANDS_CONTAINER_HARDENING"
fi
echo

# ---------------------------------------------------------------------------
# Single workspace bind mount; no Docker socket, no host HOME, no definition.
# ---------------------------------------------------------------------------
echo "=== Workspace mount boundary ==="

# Enumerate mounts as `type|source|destination` lines (no jq). Iterate every
# mount so socket/HOME/definition rejection is evaluated regardless of the
# bind mount count.
mount_lines="$(docker inspect "$CID" --format '{{range .Mounts}}{{.Type}}|{{.Source}}|{{.Destination}}{{"\n"}}{{end}}')"
bind_count=0
mount_ok=1
no_socket_ok=1
no_home_ok=1

home_real=""
if [[ -n "${HOME:-}" && -d "$HOME" ]]; then
    home_real="$(cd -P "$HOME" && pwd -P)"
fi

while IFS='|' read -r m_type m_source m_target || [[ -n "$m_type" ]]; do
    [[ -n "$m_type" ]] || continue

    if [[ "$m_type" == "bind" ]]; then
        bind_count=$((bind_count + 1))

        if [[ "$m_target" != "/workspace" ]]; then
            fail "bind mount destination is '$m_target' (expected /workspace)"
            mount_ok=0
        fi
        if [[ "$m_source" != "$ACCEPTANCE_WS" ]]; then
            fail "bind mount source is '$m_source' (expected $ACCEPTANCE_WS)"
            mount_ok=0
        fi

        # Reject runtime sockets.
        case "$m_source" in
            /var/run/docker.sock|/run/docker.sock|/var/run/podman/podman.sock|/run/podman/podman.sock)
                fail "bind mount source is a runtime socket: $m_source"
                no_socket_ok=0
                mount_ok=0
                ;;
        esac

        # Reject host HOME itself, not its descendants. $LAB_ROOT commonly
        # lives under HOME on the accepted host, so the approved Agent Lab
        # workspace may legitimately be a descendant of HOME. Only HOME as the
        # bind source root is a violation (OPENHANDS_NO_HOST_HOME).
        if [[ -n "$home_real" && "$m_source" == "$home_real" ]]; then
            fail "bind mount source is host HOME itself: $m_source"
            no_home_ok=0
            mount_ok=0
        fi

        # Reject the lab definition root tree.
        case "$m_source/" in
            "${LAB_DEFINITION_ROOT}/"*)
                fail "bind mount source is inside the lab definition root tree: $m_source"
                mount_ok=0
                ;;
        esac
    fi
done <<< "$mount_lines"

# Any non-bind mount (e.g. a socket pseudo-mount or a named volume) also
# breaks the single-workspace boundary.
total_mounts="$(printf '%s\n' "$mount_lines" | grep -c . || true)"
if [[ "$total_mounts" -ne 1 ]]; then
    fail "expected exactly 1 mount total, found $total_mounts"
    mount_ok=0
fi
if [[ "$bind_count" -ne 1 ]]; then
    fail "expected exactly 1 bind mount, found $bind_count"
    mount_ok=0
fi

if [[ "$mount_ok" -eq 1 ]]; then
    pass "exactly one bind mount: $ACCEPTANCE_WS -> /workspace"
    mark "OPENHANDS_SINGLE_WORKSPACE_MOUNT"
fi
if [[ "$no_socket_ok" -eq 1 ]]; then
    pass "no Docker/runtime socket mount"
    mark "OPENHANDS_NO_DOCKER_SOCKET"
fi
if [[ "$no_home_ok" -eq 1 ]]; then
    pass "no host HOME mount"
    mark "OPENHANDS_NO_HOST_HOME"
fi
echo

# ---------------------------------------------------------------------------
# Loopback dynamic port: only 8000 bound on 127.0.0.1 with a dynamic HostPort;
# 8002 unpublished.
# ---------------------------------------------------------------------------
echo "=== Port binding ==="

pb_json="$(docker inspect "$CID" --format '{{json .HostConfig.PortBindings}}')"
ns_ports_json="$(docker inspect "$CID" --format '{{json .NetworkSettings.Ports}}')"

port_ok=1

# RECORDED_PORT must be a non-empty numeric value recorded by the adapter.
# Do NOT reject it merely because its value is 8000; dynamic allocation is
# established by the adapter syntax `-p 127.0.0.1::8000` and the exact Docker
# port mapping below, not by excluding a number.
if [[ -z "$RECORDED_PORT" || ! "$RECORDED_PORT" =~ ^[0-9]+$ ]]; then
    fail "recorded host port is missing or non-numeric: '${RECORDED_PORT:-}'"
    port_ok=0
fi

# 8000 is published; 8002 is NOT published (no HostConfig binding, no
# NetworkSettings binding object).
printf '%s' "$pb_json" | grep -q '"8000/tcp"' \
    || { fail "8000/tcp not present in HostConfig.PortBindings"; port_ok=0; }
if printf '%s' "$pb_json" | grep -q '"8002/tcp"'; then
    fail "8002/tcp must not be published (found in HostConfig.PortBindings)"
    port_ok=0
fi
if printf '%s' "$ns_ports_json" | grep -q '"8002/tcp":\['; then
    fail "8002/tcp must not be published (found binding in NetworkSettings.Ports)"
    port_ok=0
fi
# Loopback HostIp.
printf '%s' "$ns_ports_json" | grep -q '"HostIp":"127.0.0.1"' \
    || { fail "8000 HostIp is not 127.0.0.1"; port_ok=0; }

# Precise Docker port mapping: 8000/tcp must map exactly to
# 127.0.0.1:${RECORDED_PORT}; 8002/tcp must be unpublished (empty).
port_8000="$(docker port "$CID" 8000/tcp 2>/dev/null || true)"
port_8002="$(docker port "$CID" 8002/tcp 2>/dev/null || true)"

if [[ "$port_8000" != "127.0.0.1:${RECORDED_PORT}" ]]; then
    fail "docker port 8000/tcp is '$port_8000', expected exactly 127.0.0.1:${RECORDED_PORT}"
    port_ok=0
fi
if [[ -n "$port_8002" ]]; then
    fail "docker port 8002/tcp must be empty/unpublished, got '$port_8002'"
    port_ok=0
fi

if [[ "$port_ok" -eq 1 ]]; then
    pass "8000 bound on 127.0.0.1 with dynamic HostPort ${RECORDED_PORT}; 8002 unpublished"
    mark "OPENHANDS_LOOPBACK_DYNAMIC_PORT"
fi
echo

# ---------------------------------------------------------------------------
# State/credential and persistent-secret permissions are restrictive. The
# persistent OH_SECRET_KEY value is never printed; only modes/presence are
# checked.
# ---------------------------------------------------------------------------
echo "=== State, credential, and persistent-secret permissions ==="

perm_ok=1
[[ -d "$OH_STATE_DIR" ]] || { fail "state dir missing"; perm_ok=0; }
state_dir_mode="$(file_mode "$OH_STATE_DIR" || true)"
[[ "$state_dir_mode" == "700" ]] || { fail "state dir mode is '$state_dir_mode' (expected 700)"; perm_ok=0; }
state_file_mode="$(file_mode "$OH_STATE_FILE" || true)"
[[ "$state_file_mode" == "600" ]] || { fail "state file mode is '$state_file_mode' (expected 600)"; perm_ok=0; }
cred_file_mode="$(file_mode "$OH_CRED_FILE" || true)"
[[ "$cred_file_mode" == "600" ]] || { fail "credential file mode is '$cred_file_mode' (expected 600)"; perm_ok=0; }

# Persistent OH_SECRET_KEY: dir 0700, file 0600, present and non-empty.
[[ -d "$OH_SECRET_DIR" ]] || { fail "persistent secret dir missing"; perm_ok=0; }
secret_dir_mode="$(file_mode "$OH_SECRET_DIR" || true)"
[[ "$secret_dir_mode" == "700" ]] || { fail "persistent secret dir mode is '$secret_dir_mode' (expected 700)"; perm_ok=0; }
secret_file_mode="$(file_mode "$OH_SECRET_FILE" || true)"
[[ "$secret_file_mode" == "600" ]] || { fail "persistent secret file mode is '$secret_file_mode' (expected 600)"; perm_ok=0; }
[[ -s "$OH_SECRET_FILE" ]] || { fail "persistent secret file is empty or missing"; perm_ok=0; }

if [[ "$perm_ok" -eq 1 ]]; then
    pass "state dir 0700, state/credential files 0600, persistent secret dir 0700/file 0600"
fi
echo

# ---------------------------------------------------------------------------
# Authentication enforcement via /server_info (the only runtime probe).
# Unauthenticated must be 401/403; authenticated must be 2xx. Never print the
# secret or the response body.
# ---------------------------------------------------------------------------
echo "=== Authentication enforcement (/server_info) ==="

SERVER_URL="http://127.0.0.1:${RECORDED_PORT}/server_info"

# Read the session key from the credentials file; never echo it.
SESSION_API_KEY="$(state_get "$OH_CRED_FILE" SESSION_API_KEY)" || { fail "credentials file missing SESSION_API_KEY"; exit 1; }
if [[ -z "$SESSION_API_KEY" ]]; then
    fail "SESSION_API_KEY is empty"
    exit 1
fi

# Keep the secret off the curl argv: write only the header line into a
# uniquely named temp file under the 0700 state dir, mode 0600. The file
# content is never echoed to the terminal. curl reads the header from the
# file via -H "@<file>", so argv carries only the file path.
AUTH_HEADER_FILE="${OH_STATE_DIR}/auth-header-$$-$(date +%s)"
(
    umask 077
    printf 'Authorization: Bearer %s\n' "$SESSION_API_KEY" > "$AUTH_HEADER_FILE"
)
chmod 0600 "$AUTH_HEADER_FILE"

# Bounded readiness: authenticated GET must reach 2xx within the deadline.
deadline=$((SECONDS + 60))
auth_code="000"
while (( SECONDS < deadline )); do
    auth_code="$(curl -s -o /dev/null -w '%{http_code}' \
        -H "@${AUTH_HEADER_FILE}" \
        "$SERVER_URL" 2>/dev/null || true)"
    if [[ "$auth_code" =~ ^2 ]]; then
        break
    fi
    sleep 1
done

# Unauthenticated probe (after readiness); no Authorization header.
unauth_code="$(curl -s -o /dev/null -w '%{http_code}' "$SERVER_URL" 2>/dev/null || true)"

# Remove the temp header file immediately; the EXIT trap is a fallback.
rm -f "$AUTH_HEADER_FILE" >/dev/null 2>&1 || true
AUTH_HEADER_FILE=""

# Status codes are neither secret nor body; safe to report.
echo "  authenticated /server_info -> $auth_code"
echo "  unauthenticated /server_info -> $unauth_code"

auth_ok=1
if [[ ! "$auth_code" =~ ^2 ]]; then
    fail "authenticated /server_info did not return 2xx (got $auth_code)"
    auth_ok=0
fi
if [[ "$unauth_code" != "401" && "$unauth_code" != "403" ]]; then
    fail "unauthenticated /server_info must be 401 or 403 (got $unauth_code)"
    auth_ok=0
fi

if [[ "$auth_ok" -eq 1 ]]; then
    pass "authentication enforced on /server_info"
    mark "OPENHANDS_AUTH_ENFORCED"
fi
echo

# Explicitly: no conversation/LLM/provider/tool/agent task was created. The
# only runtime probe above is the metadata endpoint /server_info (GET).
pass "no conversation/LLM/provider/tool/agent task created"
echo

# ---------------------------------------------------------------------------
# Stop via adapter and verify cleanup.
# ---------------------------------------------------------------------------
echo "=== Stop via adapter and cleanup ==="

cleanup_ok=1
if ! bash "$LAB_BIN" openhands stop; then
    fail "adapter stop returned non-zero"
    cleanup_ok=0
else
    pass "adapter stop returned success"
fi

# Managed container gone.
if docker inspect "$CID" >/dev/null 2>&1; then
    fail "managed container $CID still present after stop"
    cleanup_ok=0
else
    pass "managed container removed"
fi

# Unrelated container inventory unchanged.
inventory_after="$(docker ps -aq | sort)"
if [[ "$inventory_before" != "$inventory_after" ]]; then
    fail "container inventory changed across the test"
    cleanup_ok=0
else
    pass "container inventory unchanged"
fi

# State and per-instance credentials cleaned up.
if [[ -e "$OH_STATE_FILE" ]]; then
    fail "instance state file still present after stop"
    cleanup_ok=0
else
    pass "instance state removed"
fi
if [[ -e "$OH_CRED_FILE" ]]; then
    fail "per-instance credentials file still present after stop"
    cleanup_ok=0
else
    pass "per-instance credentials removed"
fi

# Persistent OH_SECRET_KEY must survive stop (value never printed). Only the
# per-instance credentials are removed; the stable encryption key is
# preserved across restarts.
if [[ ! -e "$OH_SECRET_FILE" ]]; then
    fail "persistent OH_SECRET_KEY file was removed during stop"
    cleanup_ok=0
else
    pass "persistent OH_SECRET_KEY preserved across stop"
fi
persist_mode_after="$(file_mode "$OH_SECRET_FILE" || true)"
if [[ "$persist_mode_after" != "600" ]]; then
    fail "persistent OH_SECRET_KEY file mode changed to '$persist_mode_after' (expected 600)"
    cleanup_ok=0
fi

# Workspace is removable (container no longer holds the bind mount).
rm -rf "$ACCEPTANCE_WS"
if [[ -e "$ACCEPTANCE_WS" ]]; then
    fail "acceptance workspace was not removable after stop"
    cleanup_ok=0
else
    pass "acceptance workspace removable (not deleted by adapter)"
fi

# Canonical definition HEAD/status unchanged.
canon_head_after="$(git -C "$LAB_DEFINITION_ROOT" rev-parse HEAD 2>/dev/null || true)"
canon_status_after="$(git -C "$LAB_DEFINITION_ROOT" status --porcelain 2>/dev/null || true)"
if [[ "$canon_head_before" != "$canon_head_after" ]]; then
    fail "canonical definition HEAD changed"
    cleanup_ok=0
else
    pass "canonical definition HEAD unchanged"
fi
if [[ "$canon_status_before" != "$canon_status_after" ]]; then
    fail "canonical definition working-tree status changed"
    cleanup_ok=0
else
    pass "canonical definition status unchanged"
fi

if [[ "$cleanup_ok" -eq 1 ]]; then
    mark "OPENHANDS_LIFECYCLE_CLEANUP"
fi
echo

# ---------------------------------------------------------------------------
# Result.
# ---------------------------------------------------------------------------
echo "================================"
if [[ "$FAILURES" -eq 0 ]]; then
    mark "OH_001D_STAGE5_LIFECYCLE_ACCEPTANCE"
    echo "================================"
    exit 0
fi

echo "OH_001D_STAGE5_LIFECYCLE_ACCEPTANCE=FAIL ($FAILURES failure(s))" >&2
echo "================================"
exit 1