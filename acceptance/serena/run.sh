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
ACCEPTANCE_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
LAB_DEFINITION_ROOT="$(cd "$ACCEPTANCE_ROOT/../.." && pwd -P)"
LAB_ROOT="$(cd "$LAB_DEFINITION_ROOT/.." && pwd -P)"

LAB_BIN="$LAB_DEFINITION_ROOT/bin/lab"

PROJECT_ROOT="$LAB_ROOT/tmp/acceptance/serena-python"

SERENA="$LAB_ROOT/runtime/uv-tool-bin/serena"
SERENA_PYTHON="$LAB_ROOT/runtime/uv-tools/serena-agent/bin/python"

export SERENA_HOME="$LAB_ROOT/state/serena"
export SERENA_USAGE_REPORTING=false

export UV_PYTHON_INSTALL_DIR="$LAB_ROOT/runtime/python"
export UV_PYTHON_BIN_DIR="$LAB_ROOT/runtime/bin"
export UV_TOOL_DIR="$LAB_ROOT/runtime/uv-tools"
export UV_TOOL_BIN_DIR="$LAB_ROOT/runtime/uv-tool-bin"
export UV_CACHE_DIR="$LAB_ROOT/runtime/cache/uv"

export PATH="$LAB_ROOT/runtime/bin:$LAB_ROOT/runtime/uv-tool-bin:$PATH"

echo "Serena Acceptance"
echo "================="
echo
echo "Project: $PROJECT_ROOT"
echo "Serena:  $SERENA"
echo "Python:  $SERENA_PYTHON"
echo

if [[ ! -x "$SERENA" ]]; then
    echo "ERROR: Lab-managed Serena is missing." >&2
    exit 1
fi

if [[ ! -x "$SERENA_PYTHON" ]]; then
    echo "ERROR: Serena Python environment is missing." >&2
    exit 1
fi

rm -rf "$PROJECT_ROOT"
mkdir -p "$PROJECT_ROOT"

cat > "$PROJECT_ROOT/calculator.py" <<'PY'
class Calculator:
    def add(self, left: int, right: int) -> int:
        return left + right

    def subtract(self, left: int, right: int) -> int:
        return left - right
PY

cat > "$PROJECT_ROOT/service.py" <<'PY'
from calculator import Calculator


class CalculationService:
    def __init__(self) -> None:
        self.calculator = Calculator()

    def total(self, left: int, right: int) -> int:
        return self.calculator.add(left, right)
PY

cat > "$PROJECT_ROOT/test_service.py" <<'PY'
from service import CalculationService


def test_total() -> None:
    service = CalculationService()
    assert service.total(20, 22) == 42
PY

cat > "$PROJECT_ROOT/README.md" <<'EOF'
# Serena Acceptance Project

Disposable Agent Lab fixture for validating Serena semantic code intelligence.
EOF

cd "$PROJECT_ROOT"

git init -q
git config user.name "Agent Lab Acceptance"
git config user.email "agent-lab@localhost"
git add .
git commit -qm "create Serena acceptance fixture"

echo "=== Baseline repository ==="
git status --short
git log --oneline -1

echo
echo "=== Serena project creation + indexing ==="

"$LAB_BIN" serena project create --index "$PROJECT_ROOT"

echo
echo "=== Serena project configuration ==="

test -f "$PROJECT_ROOT/.serena/project.yml"
cat "$PROJECT_ROOT/.serena/project.yml"

echo
echo "=== Serena health check ==="

cd "$PROJECT_ROOT"
"$LAB_BIN" serena project health-check

echo
echo "=== MCP semantic smoke test ==="

"$SERENA_PYTHON" \
    "$ACCEPTANCE_ROOT/smoke_client.py" \
    "$SERENA" \
    "$PROJECT_ROOT"

echo
echo "=== Containment ==="

case "$PROJECT_ROOT" in
    "$LAB_ROOT"/*)
        echo "[PASS] Acceptance project is inside LAB_ROOT"
        ;;
    *)
        echo "ERROR: Acceptance project escaped LAB_ROOT" >&2
        exit 1
        ;;
esac

case "$SERENA_HOME" in
    "$LAB_ROOT"/*)
        echo "[PASS] SERENA_HOME is inside LAB_ROOT"
        ;;
    *)
        echo "ERROR: SERENA_HOME escaped LAB_ROOT" >&2
        exit 1
        ;;
esac

echo
echo "=== Repository mutation check ==="

UNEXPECTED_CHANGES="$(
    git status --porcelain |
    grep -v '^?? \.serena/' || true
)"

if [[ -n "$UNEXPECTED_CHANGES" ]]; then
    echo "ERROR: Serena unexpectedly modified source-controlled files:"
    echo "$UNEXPECTED_CHANGES"
    exit 1
fi

echo "[PASS] Source-controlled fixture was not modified"

echo
echo "================================"
echo "SERENA_ACCEPTANCE=PASS"
echo "================================"
