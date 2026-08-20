#!/usr/bin/env bash
# Offline check suite for this config. No network, no services, no arc mount.
#
#   tests/run.sh          # lint + both test tiers
#   tests/run.sh --quick  # skip the lint pass
#
# Exits non-zero if anything fails.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

STATUS=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
    STATUS=1
    printf '\n=== FAILED: %s ===\n' "$1"
}

# --- 1. lint -----------------------------------------------------------------
# lua-language-server must be pointed at the workspace root: given a single file
# or a subdirectory it never finds .luarc.json, and then every `vim` is an
# undefined global. Default checklevel (Warning) is deliberate -- at Hint this
# repo reports ~30 unused-local/unused-function notes on deliberate style.
if [[ "${1:-}" != "--quick" ]]; then
    if command -v lua-language-server >/dev/null 2>&1; then
        if ! lua-language-server --check "$ROOT" --logpath="$TMP/lls" 2>&1 | tail -1 | grep -q "no problems found"; then
            lua-language-server --check "$ROOT" --logpath="$TMP/lls2" 2>&1 | grep -v "^Initializing" | tail -40
            fail "lua-language-server --check"
        else
            echo "lint: no problems found"
        fi
    else
        echo "lint: SKIPPED (lua-language-server not on PATH)"
    fi
fi

# --- 2. core tier ------------------------------------------------------------
# --clean: no plugins, no user config. Proves the parts that are ours still work
# on a bare nvim, and keeps this tier green on a fresh clone.
if ! nvim --clean -l tests/core_spec.lua; then
    fail "tests/core_spec.lua"
fi

# --- 3. init tier ------------------------------------------------------------
# Loads the real init.lua with the real plugins. Skipped rather than run when
# lazy is not installed, so a fresh clone does not trigger a plugin download.
LAZY="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
if [[ ! -d "$LAZY" ]]; then
    echo "init: SKIPPED (lazy.nvim not installed at $LAZY; run nvim once)"
else
    # nvim exits 0 even when init.lua raises -- the traceback only goes to
    # stderr. So the exit code alone cannot prove init.lua loaded cleanly:
    # treat any stderr output as a failure too.
    # Run from a terminal inside nvim, $NVIM is set and flatten.nvim hands the
    # whole process to the host, which exits 0 with no output at all -- the
    # spec never runs and this tier passes vacuously (measured). Drop it.
    if ! env -u NVIM nvim --headless -u init.lua -l tests/init_spec.lua 2>"$TMP/init.err"; then
        fail "tests/init_spec.lua"
    fi
    if [[ -s "$TMP/init.err" ]]; then
        cat "$TMP/init.err"
        fail "init.lua wrote to stderr (a load error, or a failing assertion)"
    fi
fi

exit $STATUS
