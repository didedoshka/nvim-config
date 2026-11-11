#!/usr/bin/env bash
# Offline Lua edit checks, shared by the Codex and Claude PostToolUse hooks.
#
# Runs the whole suite, not just the linter, on purpose: lua-language-server
# does not catch cross-module breakage. Renaming gdb_bt_qf's M.setup() while
# init.lua still calls it is "no problems found" to --check, and only actually
# loading the code notices. Measured in this repo, not assumed.
#
# Contract: exits 2 with diagnostics on
# stderr to report a failure, 0 to stay quiet.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! output=$("$ROOT/tests/run.sh" 2>&1); then
    printf 'tests/run.sh failed:\n\n%s\n' "$output" >&2
    exit 2
fi

exit 0
