#!/usr/bin/env bash
set -euo pipefail

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
BOOTSTRAP_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"

# Derive LAB_DEFINITION_ROOT from the bootstrap script's location by default.
# Respect an externally supplied value instead of overwriting it.
if [[ -n "${LAB_DEFINITION_ROOT:-}" ]]; then
    LAB_DEFINITION_ROOT="$(cd "$LAB_DEFINITION_ROOT" && pwd -P)"
else
    LAB_DEFINITION_ROOT="$(cd "$BOOTSTRAP_ROOT/.." && pwd -P)"
fi

# Derive LAB_ROOT from the definition parent by default. Respect an externally
# supplied persistent root instead of clobbering it.
if [[ -n "${LAB_ROOT:-}" ]]; then
    LAB_ROOT="$(cd "$LAB_ROOT" && pwd -P)"
else
    LAB_ROOT="$(cd "$LAB_DEFINITION_ROOT/.." && pwd -P)"
fi

# shellcheck source=/dev/null
source "$BOOTSTRAP_ROOT/versions.env"

LAB_RUNTIME_ROOT="$LAB_ROOT/runtime"
LAB_RUNTIME_BIN="$LAB_RUNTIME_ROOT/bin"

mkdir -p \
    "$LAB_ROOT/components" \
    "$LAB_ROOT/control-plane" \
    "$LAB_ROOT/dagger" \
    "$LAB_ROOT/projects" \
    "$LAB_ROOT/config" \
    "$LAB_ROOT/state" \
    "$LAB_ROOT/workspaces" \
    "$LAB_ROOT/evidence" \
    "$LAB_ROOT/logs" \
    "$LAB_ROOT/secrets" \
    "$LAB_ROOT/tmp" \
    "$LAB_ROOT/scripts" \
    "$LAB_RUNTIME_ROOT/bin" \
    "$LAB_RUNTIME_ROOT/python" \
    "$LAB_RUNTIME_ROOT/uv-tools" \
    "$LAB_RUNTIME_ROOT/uv-tool-bin" \
    "$LAB_RUNTIME_ROOT/cache"

chmod 700 "$LAB_ROOT/secrets"

echo "Agent Lab Bootstrap"
echo "==================="
echo
echo "LAB_ROOT=$LAB_ROOT"
echo "uv pin=$LAB_UV_VERSION"
echo

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: Git is required on the host." >&2
    exit 1
fi

if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo "ERROR: curl or wget is required on the host." >&2
    exit 1
fi

UV_BIN="$LAB_RUNTIME_BIN/uv"

install_uv() {
    local installer_url
    installer_url="https://astral.sh/uv/${LAB_UV_VERSION}/install.sh"

    echo "Installing lab-managed uv $LAB_UV_VERSION..."
    echo "Destination: $LAB_RUNTIME_BIN"

    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl --proto '=https' --tlsv1.2 -LsSf "$installer_url" |
            env UV_UNMANAGED_INSTALL="$LAB_RUNTIME_BIN" sh
    else
        wget -qO- "$installer_url" |
            env UV_UNMANAGED_INSTALL="$LAB_RUNTIME_BIN" sh
    fi
}

if [[ -x "$UV_BIN" ]]; then
    CURRENT_UV_VERSION="$("$UV_BIN" --version | awk '{print $2}')"

    if [[ "$CURRENT_UV_VERSION" == "$LAB_UV_VERSION" ]]; then
        echo "Lab-managed uv $LAB_UV_VERSION already installed."
    else
        echo "Lab-managed uv is $CURRENT_UV_VERSION; expected $LAB_UV_VERSION."
        install_uv
    fi
else
    install_uv
fi

ACTUAL_UV_VERSION="$("$UV_BIN" --version | awk '{print $2}')"

if [[ "$ACTUAL_UV_VERSION" != "$LAB_UV_VERSION" ]]; then
    echo "ERROR: uv verification failed." >&2
    echo "Expected: $LAB_UV_VERSION" >&2
    echo "Actual:   $ACTUAL_UV_VERSION" >&2
    exit 1
fi

# Keep the convenience workspace launcher available.
# Target the resolved definition root so a detached candidate checkout (where
# the definition does not live in a sibling "lab-definition" directory) still
# links to the correct bin/lab.
ln -sfn "$LAB_DEFINITION_ROOT/bin/lab" "$LAB_ROOT/scripts/lab"

echo
echo "Bootstrap toolchain:"
echo "  uv: $("$UV_BIN" --version)"
echo "  path: $UV_BIN"

echo
echo "Bootstrap complete."
echo
echo "Next:"
echo "  $LAB_ROOT/scripts/lab doctor"
