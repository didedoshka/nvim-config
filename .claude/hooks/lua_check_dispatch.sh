#!/usr/bin/env bash
# PostToolUse router for cross-repo sessions rooted in this config.
#
# Hooks only load from the session root's settings, so when a session here
# edits a repo under ~/personal (reachable via permissions.additionalDirectories),
# that repo's own lua-check hook never fires. This routes the payload to the
# check of whichever repo owns the edited file; each repo's script computes its
# own root from its location, so they run unmodified.
#
# The repo is derived from the path, not enumerated: an enumerated list here
# already diverged once (pcre.nvim was silently unchecked). A ~/personal repo
# missing its hook is a loud exit 2, not a silent pass.
set -uo pipefail

input=$(cat)

if command -v jq >/dev/null 2>&1; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
fi

case "$file_path" in
    "$HOME"/personal/*/*)
        repo="${file_path#"$HOME"/personal/}"
        repo="$HOME/personal/${repo%%/*}"
        hook="$repo/.claude/hooks/lua-check.sh"
        if [[ ! -x "$hook" ]]; then
            [[ "$file_path" == *.lua ]] || exit 0
            echo "no lua-check hook at $hook -- this edit was NOT verified; create the hook (see the sibling repos') or run that repo's tests yourself" >&2
            exit 2
        fi ;;
    *)
        hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lua_check.sh" ;;
esac

printf '%s' "$input" | "$hook"
