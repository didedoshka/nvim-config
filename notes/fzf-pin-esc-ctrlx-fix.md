# fzf-pin picker: esc-after-i and ctrl-x fixes (2026-08-14)

Two bugs in the fzf-pin menus (`s` bookmarks, `<CR>` servers, `x` litre), fixed in
fzf-pin.nvim commit `5b9453f` (+ `767af3c` in no-tmux, `311f30c` here).

## Symptoms

1. After entering search with `i`, `esc` closed the whole window — no way back to the
   bound-chars state.
2. `ctrl-x` (unpin) broke the menu: unpin then close in sequence didn't work, and dead
   fzf processes piled up on the box.

## Root cause

The fzf-lua setup runs the **"hide" profile**: `esc` doesn't close a picker, it *hides*
it (the fzf process stays alive for resume), and every action gets rewritten into an
`execute-silent` wrapper that hides the window first.

- The picker's own `esc` bind was silently overwritten by that rewrite.
- The old `ctrl-x` path closed the picker and reopened it via `vim.schedule`, racing
  fzf-lua's hide/teardown — broken window state plus orphaned hidden fzf processes
  (several were found running, e.g. leftover `servers>` pickers).

## Fix (all in fzf-pin.nvim `picker.lua`)

- `ctrl-x` is now a `{ fn, reload }` action: the window never closes; fzf reloads the
  list in place after the unpin. Contents is a function that also rebuilds the lookup
  maps, so they always match the shown list. The old "truthy return from `unpin()`
  reopens" contract is gone — consumers' `return true` were removed.
- `esc` undoes `i`: a `transform` bind checks `$FZF_PROMPT` (the prompt switches to
  `search> ` on `i` and doubles as the mode flag). In search mode esc clears the query,
  restores prompt/header and rebinds all chars — the exact pre-`i` state; otherwise esc
  closes as before.
- `no_hide = true`: the picker is a modal menu, not a resumable search. Opting out of
  the hide profile keeps the esc bind ours and stops leaking hidden fzf processes.

## How it was verified

Offline suites of all three repos, plus live end-to-end runs: a real nvim with this
config driven in a pty (open menu, `i`, type, esc restores, pinned char activates;
ctrl-x reloads in place, double ctrl-x, esc, reopen — both `s` and `<CR>` menus).
Harness gotcha worth remembering: the pty must be drained continuously, otherwise nvim
blocks on terminal writes and stops reading keys, faking breakage.

Running nvim servers pick up the fix only after a restart.
