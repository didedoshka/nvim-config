#!/usr/bin/env bash
# PostToolUse hook: after Claude writes a .lua file in this config, run the
# offline suite and hand back any breakage at the edit that caused it.
#
# Runs the whole suite, not just the linter, on purpose: lua-language-server
# does not catch cross-module breakage. Renaming gdb_bt_qf's M.setup() while
# init.lua still calls it is "no problems found" to --check, and only actually
# loading the code notices. Measured in this repo, not assumed.
#
# Contract: reads the tool-call JSON on stdin, exits 2 with diagnostics on
# stderr to report a failure, 0 to stay quiet.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

input=$(cat)

if command -v jq >/dev/null 2>&1; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Only Lua, and only Lua belonging to this config: editing a plugin's source or
# another repo's Lua says nothing about whether this config still loads.
[[ "$file_path" == *.lua ]] || exit 0
case "$file_path" in
    "$ROOT"/*) ;;
    *) exit 0 ;;
esac

if ! output=$("$ROOT/tests/run.sh" 2>&1); then
    printf 'tests/run.sh failed after editing %s:\n\n%s\n' "$file_path" "$output" >&2
    exit 2
fi

exit 0
