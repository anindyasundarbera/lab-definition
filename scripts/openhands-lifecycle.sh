#!/usr/bin/env bash
# Agent Lab OpenHands Agent Server lifecycle adapter (OH-001D Stage 5).
#
# Owns the disposable candidate workspace -> container lifecycle for the
# digest-pinned OpenHands Agent Server image. Enforces the Agent Lab
# isolation boundary: loopback-only dynamic port, no Docker socket, no host
# HOME, no definition repo mount, exactly one approved workspace bind mount,
# immutable digest-qualified image ref, `--pull never`, baked entrypoint/user,
# and container hardening (no-new-privileges, cap-drop ALL, non-privileged).
#
# This script performs NO Docker/runtime execution policy beyond starting the
# managed server per the boundary above. It is the only entry point used by
# `bin/lab openhands`. State is parsed, never sourced.
set -euo pipefail

# ---------------------------------------------------------------------------
# Immutable image contract (OH-001B / OH-001D Stage 4).
# ---------------------------------------------------------------------------
readonly OH_IMAGE_REF="ghcr.io/openhands/agent-server@sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02"
readonly OH_PLATFORM="linux/amd64"
readonly OH_CONTAINER_PORT="8000"

# Ownership labels. Stop/remove verify BOTH the labels and the recorded
# container id before any destructive action.
readonly OH_LABEL_COMPONENT="agent-lab.component=openhands"
readonly OH_LABEL_MANAGED="agent-lab.managed=true"

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

# ---------------------------------------------------------------------------
# State and credential locations.
#
# Per-instance state/credentials live under $LAB_ROOT/state/openhands and are
# removed on stop. The OH_SECRET_KEY is a stable per-deployment encryption key
# (upstream requires it to be stable across server restarts so persisted
# encrypted secrets remain decryptable). It is generated once, persisted
# outside Git under $LAB_ROOT/secrets/openhands, and NEVER deleted by stop and
# NEVER printed. SESSION_API_KEY is generated fresh every start. The per-start
# credentials.env carries both keys for the container --env-file and is
# deleted on stop.
# ---------------------------------------------------------------------------
OH_STATE_DIR="${LAB_ROOT}/state/openhands"
OH_STATE_FILE="${OH_STATE_DIR}/instance.state"
OH_CRED_FILE="${OH_STATE_DIR}/credentials.env"
OH_SECRET_DIR="${LAB_ROOT}/secrets/openhands"
OH_SECRET_FILE="${OH_SECRET_DIR}/oh-secret-key"
# Atomic single-start lock (a directory; mkdir is the atomic primitive). A
# concurrent start fails without touching state/credentials.
OH_START_LOCK="${OH_STATE_DIR}/start.lock"

# ---------------------------------------------------------------------------
# Safe, non-executable key=value parsing. NEVER sources state/credential
# files; matches a single key prefix and prints the remainder of the line.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# >=256-bit entropy from baseline Linux/Bash primitives only (/dev/urandom +
# coreutils od). 64 bytes = 512 bits, hex-encoded. No new dependency.
# ---------------------------------------------------------------------------
generate_secret() {
    od -An -v -tx1 -N64 /dev/urandom | tr -d ' \n'
}

# Persistent OH_SECRET_KEY: generated once if absent, reused across restarts.
# Stored outside Git, never printed, never deleted by stop. Directory 0700,
# file 0600. Caller captures stdout internally; it is never echoed to the
# terminal.
ensure_persistent_secret() {
    mkdir -p "$OH_SECRET_DIR"
    chmod 0700 "$OH_SECRET_DIR"

    if [[ ! -f "$OH_SECRET_FILE" ]]; then
        (
            umask 077
            generate_secret > "$OH_SECRET_FILE"
        )
    fi

    # Enforce restrictive mode unconditionally so a pre-existing key on disk
    # also has its mode restored to 0600.
    chmod 0600 "$OH_SECRET_FILE"

    [[ -s "$OH_SECRET_FILE" ]] || die "persistent OH_SECRET_KEY file is empty or missing: $OH_SECRET_FILE"
}

persistent_secret() {
    [[ -r "$OH_SECRET_FILE" ]] || return 1
    local val
    IFS= read -r val < "$OH_SECRET_FILE" || true
    printf '%s' "$val"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Workspace validation. The existing real path must resolve strictly below
# $LAB_ROOT/workspaces/; reject symlink/path escape, the lab definition root,
# the filesystem root, host HOME itself, Docker/runtime sockets, or anything
# outside the workspaces tree. A workspace legitimately under
# $LAB_ROOT/workspaces/ is allowed even if that subtree sits below host HOME
# on the accepted host; only HOME as the workspace root is rejected.
# ---------------------------------------------------------------------------
validate_workspace() {
    local ws_arg="$1"
    local ws_real ws_root home_real

    # Reject newline/carriage-return so a crafted path cannot structurally
    # inject key=value state lines. '=' as value data remains safe.
    if [[ "$ws_arg" == *$'\n'* || "$ws_arg" == *$'\r'* ]]; then
        die "workspace path must not contain newline or carriage-return characters"
    fi

    ws_root="$(cd -P "$LAB_WORKSPACES_ROOT" 2>/dev/null && pwd -P)" \
        || die "workspaces root not found: $LAB_WORKSPACES_ROOT"

    if [[ ! -e "$ws_arg" ]]; then
        die "workspace path does not exist: $ws_arg"
    fi

    # Require a directory before any cd; a bind mount source must be a
    # directory workspace.
    if [[ ! -d "$ws_arg" ]]; then
        die "workspace path is not a directory: $ws_arg"
    fi

    # Resolve the real path strictly (cd -P follows symlinks). A symlink that
    # escapes the workspaces tree resolves outside it and is rejected below.
    ws_real="$(cd -P "$ws_arg" && pwd -P)"

    # Must be strictly below the workspaces root.
    case "$ws_real/" in
        "${ws_root}/"*) ;;
        *)
            die "workspace '$ws_arg' resolves to '$ws_real', outside $ws_root"
            ;;
    esac

    if [[ "$ws_real" == "$ws_root" ]]; then
        die "workspace must be a subdirectory below $ws_root, not the root itself"
    fi

    # Reject the lab definition root tree.
    case "$ws_real/" in
        "${LAB_DEFINITION_ROOT}/"*)
            die "workspace must not be inside the lab definition root tree"
            ;;
    esac

    # Reject the filesystem root.
    if [[ "$ws_real" == "/" ]]; then
        die "workspace must not be the filesystem root"
    fi

    # Reject host HOME itself (not its descendants): $LAB_ROOT commonly lives
    # under HOME on the accepted host, so an approved workspaces/ subtree may
    # legitimately be below HOME. Only HOME as the workspace root is rejected.
    if [[ -n "${HOME:-}" && -d "$HOME" ]]; then
        home_real="$(cd -P "$HOME" && pwd -P)"
        if [[ "$ws_real" == "$home_real" ]]; then
            die "workspace must not be host HOME itself ($home_real)"
        fi
    fi

    # Reject common container runtime socket paths.
    case "$ws_real" in
        /var/run/docker.sock|/run/docker.sock|/var/run/podman/podman.sock|/run/podman/podman.sock)
            die "workspace path must not be a container runtime socket"
            ;;
    esac

    printf '%s\n' "$ws_real"
}

# ---------------------------------------------------------------------------
# Docker preconditions: require the docker CLI and a reachable daemon before
# any image inspection.
# ---------------------------------------------------------------------------
require_docker() {
    command -v docker >/dev/null 2>&1 \
        || die "docker is required but was not found on PATH"
    docker info >/dev/null 2>&1 \
        || die "docker daemon is not reachable (docker info failed)"
}

# ---------------------------------------------------------------------------
# Atomic single-start lock. mkdir is the atomic primitive: it succeeds only
# when it creates the directory. A concurrent start fails here without
# touching state/credentials. The lock is always released on every exit path
# via the start EXIT trap (or explicitly on commit).
# ---------------------------------------------------------------------------
acquire_start_lock() {
    mkdir "$OH_START_LOCK" 2>/dev/null \
        || die "another 'lab openhands start' is in progress (lock held: $OH_START_LOCK). Remove it only if no start is running."
}

release_start_lock() {
    rmdir "$OH_START_LOCK" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Require the immutable image to be present locally (never pull). Require
# linux/amd64 platform metadata on the local image.
# ---------------------------------------------------------------------------
ensure_local_image() {
    if ! docker image inspect "$OH_IMAGE_REF" >/dev/null 2>&1; then
        die "local image not found: $OH_IMAGE_REF
       Pull is disabled (--pull never). Pre-pull the immutable image:
         docker pull $OH_IMAGE_REF"
    fi

    local img_platform
    img_platform="$(docker image inspect "$OH_IMAGE_REF" --format '{{.Os}}/{{.Architecture}}')"
    if [[ "$img_platform" != "$OH_PLATFORM" ]]; then
        die "local image platform is '$img_platform', required '$OH_PLATFORM'"
    fi
}

# Verify a container id carries both ownership labels.
verify_owned_labels() {
    local cid="$1"
    local lc lm

    if ! docker inspect "$cid" >/dev/null 2>&1; then
        return 1
    fi

    lc="$(docker inspect "$cid" --format '{{index .Config.Labels "agent-lab.component"}}')"
    lm="$(docker inspect "$cid" --format '{{index .Config.Labels "agent-lab.managed"}}')"
    [[ "$lc" == "openhands" && "$lm" == "true" ]]
}

# ---------------------------------------------------------------------------
# start <workspace-path>
# ---------------------------------------------------------------------------
cmd_start() {
    local ws_arg="${1:-}"

    if [[ -z "$ws_arg" ]]; then
        die "start requires a workspace path
Usage: lab openhands start <workspace-path>"
    fi

    local ws
    ws="$(validate_workspace "$ws_arg")"

    local OH_NAME="agent-lab-openhands"

    # Docker preconditions before any image inspection.
    require_docker

    # Ensure the state dir exists so the atomic start lock directory can be
    # created beneath it.
    mkdir -p "$OH_STATE_DIR"
    chmod 0700 "$OH_STATE_DIR"

    # Acquire the atomic single-start lock BEFORE checking/removing stale
    # state or checking the fixed container name. A concurrent start fails
    # here without touching state/credentials. The EXIT trap (set just below)
    # always releases the lock on every exit path.
    acquire_start_lock

    # Transactional cleanup. Before docker run (OH_CREATED_CRED=0,
    # OH_PENDING_CID empty) the trap ONLY releases the lock — it never
    # touches existing state/credentials, so a winner's state is never
    # deleted. After credentials are written it also removes only this
    # invocation's per-instance credentials/state; after docker run it also
    # removes only this invocation's newly-created owned container. The
    # persistent OH_SECRET_KEY is never touched here.
    OH_CREATED_CRED=0
    OH_PENDING_CID=""
    _start_cleanup() {
        if [[ -n "${OH_PENDING_CID:-}" ]] \
           && docker inspect "$OH_PENDING_CID" >/dev/null 2>&1 \
           && verify_owned_labels "$OH_PENDING_CID"; then
            docker rm -f "$OH_PENDING_CID" >/dev/null 2>&1 || true
        fi
        if [[ "${OH_CREATED_CRED:-0}" -eq 1 ]]; then
            rm -f "$OH_CRED_FILE" "$OH_STATE_FILE"
        fi
        release_start_lock
    }
    trap _start_cleanup EXIT

    # One active managed server. If valid state binds a live container,
    # refuse. Malformed state is retained (never deleted blindly) and
    # reported; the trap releases only the lock on these die paths.
    if [[ -f "$OH_STATE_FILE" ]]; then
        local existing_cid
        if ! existing_cid="$(state_get "$OH_STATE_FILE" container_id 2>/dev/null)" \
           || [[ -z "$existing_cid" ]]; then
            die "malformed instance state at $OH_STATE_FILE (no container_id); refusing to proceed. Inspect and remove it manually."
        fi
        if docker inspect "$existing_cid" >/dev/null 2>&1; then
            die "a managed OpenHands instance is already running (container $existing_cid).
       Run 'lab openhands stop' first."
        fi
        # Stale state (recorded container gone): clear it defensively.
        rm -f "$OH_STATE_FILE" "$OH_CRED_FILE"
    fi

    # If a container with the fixed managed name exists but no valid state
    # binds it, REFUSE rather than auto-removing it (even if labels look
    # owned). Never clobber a container we cannot bind via valid state.
    if docker inspect "$OH_NAME" >/dev/null 2>&1; then
        die "a container named '$OH_NAME' already exists but no valid state binds it; refusing to start. Inspect and remove it manually."
    fi

    ensure_local_image

    # Stable per-deployment OH_SECRET_KEY (persisted, never printed, never
    # deleted by stop) + fresh per-start SESSION_API_KEY (never printed).
    ensure_persistent_secret
    local session_key secret_key
    session_key="$(generate_secret)"
    secret_key="$(persistent_secret)" \
        || die "could not read persistent OH_SECRET_KEY from $OH_SECRET_FILE"

    # Write per-instance credentials (mode 0600) BEFORE docker run so
    # --env-file is ready. Values are hex; safe in KEY=VALUE env files and not
    # exposed on `ps`. This file is deleted on stop; the persistent
    # OH_SECRET_KEY file is separate and is never deleted here.
    (
        umask 077
        printf 'SESSION_API_KEY=%s\n' "$session_key" > "$OH_CRED_FILE"
        printf 'OH_SECRET_KEY=%s\n' "$secret_key" >> "$OH_CRED_FILE"
    )
    chmod 0600 "$OH_CRED_FILE"
    OH_CREATED_CRED=1

    local container_id
    container_id="$(docker run -d \
        --name "$OH_NAME" \
        --platform "$OH_PLATFORM" \
        --pull never \
        --security-opt no-new-privileges:true \
        --cap-drop ALL \
        -e OH_ENABLE_VNC=false \
        --env-file "$OH_CRED_FILE" \
        --label "$OH_LABEL_COMPONENT" \
        --label "$OH_LABEL_MANAGED" \
        -p 127.0.0.1::${OH_CONTAINER_PORT} \
        --mount type=bind,source="${ws}",target=/workspace \
        "$OH_IMAGE_REF")" \
        || die "docker run failed"
    OH_PENDING_CID="$container_id"

    # Resolve the dynamically assigned loopback host port.
    local port_line host_port
    port_line="$(docker port "$container_id" "$OH_CONTAINER_PORT" 2>/dev/null || true)"
    host_port="${port_line##*:}"

    if [[ -z "$host_port" || ! "$host_port" =~ ^[0-9]+$ ]]; then
        die "could not resolve dynamic loopback host port for container $container_id"
    fi

    local image_id
    image_id="$(docker inspect "$container_id" --format '{{.Image}}')" \
        || die "could not inspect image id for container $container_id"

    # Write instance state (mode 0600). Non-executable parsed data; never
    # sourced (see state_get).
    (
        umask 077
        {
            printf 'container_id=%s\n' "$container_id"
            printf 'container_name=%s\n' "$OH_NAME"
            printf 'workspace=%s\n' "$ws"
            printf 'host_port=%s\n' "$host_port"
            printf 'host_url=http://127.0.0.1:%s\n' "$host_port"
            printf 'image_ref=%s\n' "$OH_IMAGE_REF"
            printf 'image_id=%s\n' "$image_id"
            printf 'created=%s\n' "$(date +%s)"
        } > "$OH_STATE_FILE"
    ) || die "could not write instance state at $OH_STATE_FILE"
    chmod 0600 "$OH_STATE_FILE"

    # State committed: release the lock and disarm the post-run cleanup trap.
    OH_PENDING_CID=""
    OH_CREATED_CRED=0
    release_start_lock
    trap - EXIT

    echo "Started OpenHands Agent Server."
    echo "  container: $container_id"
    echo "  name:      $OH_NAME"
    echo "  image:     $OH_IMAGE_REF"
    echo "  platform:  $OH_PLATFORM"
    echo "  workspace: $ws"
    echo "  url:       http://127.0.0.1:${host_port}"
    echo "  state:     $OH_STATE_FILE"
}

# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------
cmd_status() {
    if [[ ! -f "$OH_STATE_FILE" ]]; then
        echo "No managed OpenHands instance."
        return 0
    fi

    local cid name ws port url ref img_id created
    cid="$(state_get "$OH_STATE_FILE" container_id)" || die "malformed state: $OH_STATE_FILE"
    name="$(state_get "$OH_STATE_FILE" container_name)" || name=""
    ws="$(state_get "$OH_STATE_FILE" workspace)" || ws=""
    port="$(state_get "$OH_STATE_FILE" host_port)" || port=""
    url="$(state_get "$OH_STATE_FILE" host_url)" || url=""
    ref="$(state_get "$OH_STATE_FILE" image_ref)" || ref=""
    img_id="$(state_get "$OH_STATE_FILE" image_id)" || img_id=""
    created="$(state_get "$OH_STATE_FILE" created)" || created=""

    echo "Managed OpenHands Agent Server"
    echo "  state file: $OH_STATE_FILE"

    if ! docker inspect "$cid" >/dev/null 2>&1; then
        echo "  STALE: recorded container $cid is not present."
        echo "  Run 'lab openhands stop' to clear stale state."
        return 1
    fi

    if ! verify_owned_labels "$cid"; then
        echo "  STALE: recorded container $cid is no longer agent-lab managed."
        echo "  Run 'lab openhands stop' to clear stale state."
        return 1
    fi

    local running
    running="$(docker inspect "$cid" --format '{{.State.Running}}')"

    echo "  container id: $cid"
    echo "  container:    ${name:-<unknown>}"
    echo "  running:      $running"
    echo "  image ref:    ${ref:-<unknown>}"
    echo "  image id:     ${img_id:-<unknown>}"
    echo "  workspace:    ${ws:-<unknown>}"
    echo "  host port:    ${port:-<unknown>}"
    echo "  url:          ${url:-<unknown>}"
    echo "  created:      ${created:-<unknown>}"
}

# ---------------------------------------------------------------------------
# stop (idempotent; removes only the owned recorded container; never the
# workspace)
# ---------------------------------------------------------------------------
cmd_stop() {
    # Idempotent: nothing to do when no state exists.
    if [[ ! -f "$OH_STATE_FILE" ]]; then
        echo "No managed OpenHands instance to stop."
        return 0
    fi

    local cid
    # Malformed state: retain it for inspection rather than deleting blindly.
    if ! cid="$(state_get "$OH_STATE_FILE" container_id 2>/dev/null)" || [[ -z "$cid" ]]; then
        die "malformed instance state at $OH_STATE_FILE; refusing to delete. Inspect and remove it manually."
    fi

    # Recorded container already gone: idempotent cleanup of per-instance
    # state/credentials only. The persistent OH_SECRET_KEY is never deleted.
    if ! docker inspect "$cid" >/dev/null 2>&1; then
        rm -f "$OH_STATE_FILE" "$OH_CRED_FILE"
        echo "Recorded container $cid is already gone; cleared stale instance state/credentials."
        return 0
    fi

    # Verify labels + recorded container id before any destructive action.
    if ! verify_owned_labels "$cid"; then
        die "recorded container $cid is not agent-lab managed; refusing to stop/remove. State/credentials retained."
    fi

    # Graceful stop and remove. No || true: failures retain state/credentials
    # so the caller can retry.
    docker stop "$cid" >/dev/null 2>&1 \
        || die "docker stop failed for $cid; state/credentials retained for retry."
    docker rm "$cid" >/dev/null 2>&1 \
        || die "docker rm failed for $cid; state/credentials retained for retry."

    # Confirm the container is actually gone before deleting state/credentials.
    if docker inspect "$cid" >/dev/null 2>&1; then
        die "container $cid still present after stop/remove; state/credentials retained."
    fi

    # Remove per-instance credentials and state. The workspace is never
    # deleted, and the persistent OH_SECRET_KEY is never deleted by stop.
    rm -f "$OH_STATE_FILE" "$OH_CRED_FILE"
    echo "Stopped and removed managed OpenHands container $cid; cleared instance state/credentials."
}

# ---------------------------------------------------------------------------
usage() {
    cat <<USAGE
Usage: lab openhands <command> [args]

Commands:
  start <workspace-path>   Start the managed Agent Server for an approved
                           workspace (must exist below \$LAB_ROOT/workspaces/).
  status                   Show the managed instance state and container.
  stop                     Idempotently stop/remove the owned managed
                           container and clear state/credentials. Never
                           deletes the workspace.

Image:        $OH_IMAGE_REF
Platform:     $OH_PLATFORM
State dir:    $OH_STATE_DIR (mode 0700; per-instance, cleared on stop)
Secret dir:   $OH_SECRET_DIR (mode 0700; OH_SECRET_KEY persisted, never printed,
              never deleted by stop)
USAGE
}

main() {
    local subcmd="${1:-}"

    case "$subcmd" in
        start)
            shift
            cmd_start "$@"
            ;;
        status)
            cmd_status
            ;;
        stop)
            cmd_stop
            ;;
        ""|-h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown openhands subcommand: $subcmd" >&2
            usage >&2
            exit 2
            ;;
    esac
}

main "$@"