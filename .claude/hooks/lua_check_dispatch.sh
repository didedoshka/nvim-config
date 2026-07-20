#!/usr/bin/env bash
# PostToolUse router for cross-repo sessions rooted in this config.
#
# Hooks only load from the session root's settings, so when a session here
# edits ~/personal/arc.nvim or ~/personal/debugmaster.nvim (reachable via
# permissions.additionalDirectories), those repos' own lua-check hooks never
# fire. This routes the payload to the check of whichever repo owns the edited
# file; each repo's script computes its own root from its location, so they
# run unmodified.
set -uo pipefail

input=$(cat)

if command -v jq >/dev/null 2>&1; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
fi

case "$file_path" in
    "$HOME"/personal/arc.nvim/*)
        hook="$HOME/personal/arc.nvim/.claude/hooks/lua-check.sh" ;;
    "$HOME"/personal/debugmaster.nvim/*)
        hook="$HOME/personal/debugmaster.nvim/.claude/hooks/lua-check.sh" ;;
    "$HOME"/personal/litre.nvim/*)
        hook="$HOME/personal/litre.nvim/.claude/hooks/lua-check.sh" ;;
    *)
        hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lua_check.sh" ;;
esac

printf '%s' "$input" | "$hook"
