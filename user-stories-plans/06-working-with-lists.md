# Story 06 — working with lists

> Список types: files changed in a PR · interesting files · backtrace · issues ·
> default grep/rg.
> Wanted: jumplist beyond `C-j`/`C-k`; save/parse lists; unify quickfix vs fzf-lua.

## Verdict
Medium effort, high leverage — this is the *connective tissue* under stories 02, 03, 05.
The right move is **not** a new list abstraction. It's to pick one durable list
(**quickfix**) as the backbone and make fzf-lua a first-class *feeder* into it. Almost
everything else you listed is then "a command that fills the quickfix list".

## The model
```
                 sources                         the one durable list        selectors
  ┌───────────────────────────────┐            ┌──────────────────┐     ┌──────────────┐
  │ :GdbBtQf        (backtrace)    │            │                  │     │ fzf-lua      │
  │ :ArcChangedFiles (PR files)    │  ───────►  │    quickfix      │ ◄── │  ctrl-q sends│
  │ :Qf   (paste grep/issue text)  │  fill      │   + 10-deep stack│     │  results in  │
  │ <leader>j (diagnostics)        │            │  + :QfSave/:QfLoad│    └──────────────┘
  │ grep / rg                      │            └──────────────────┘
  └───────────────────────────────┘                    ▲
                            :cnext/:cprev entries · :colder/:cnewer lists
```
- **quickfix = durable, navigable, stackable, persistable.** It now survives jumps
  (story 05, done — `gd`/`gi` no longer clobber it), has a 10-deep stack, and
  `getqflist`/`setqflist` make save/load trivial. (No dedicated nav keymaps were added;
  use built-in `:cnext`/`:cprev` and `:colder`/`:cnewer`.)
- **fzf-lua = the fuzzy entry point.** Its job is to *find* and to *route into* quickfix,
  not to be a second parallel list system.

### Piece 1 — fzf-lua `ctrl-q` sends selection to quickfix (unify the two)
fzf-lua already binds `ctrl-q` to "send to quickfix" in most pickers; make it explicit
and universal so the muscle memory is one key everywhere:
```lua
-- in lua/plugins/fzf.lua setup({...})
actions = {
    files = {
        ["ctrl-q"] = require("fzf-lua").actions.file_edit_or_qf, -- multi-select -> qf
    },
},
-- and for grep/lsp lists, fzf-lua's default ctrl-q = actions.file_sel_to_qf already applies.
```
Workflow becomes: `<leader>h` (live grep) → multi-select or `ctrl-q` → durable quickfix →
`:cnext`/`:cprev` to walk it. That is the "unify workflow" you asked for: fzf finds, quickfix keeps.

### Piece 2 — sources that fill quickfix → `code/arc_lists.lua`
[`code/arc_lists.lua`](code/arc_lists.lua) (syntax-checked) adds:

| Command | List it produces |
| --- | --- |
| `:ArcChangedFiles [rev]` | files changed in your branch (working copy, or vs `<rev>`) → quickfix |
| `:Qf` | parse the current buffer, or a `:'<,'>` range, as `path:line[:col[:text]]` **or** paste from an issue/backtrace → quickfix (uses `errorformat`) |
| `:QfSave <name>` / `:QfLoad <name>` / `:QfLists` | persist and reload named lists (JSON under `stdpath('data')/qflists`) |

- `:ArcChangedFiles` covers "all files changed in a PR" and "changed files" directly.
- `:Qf` covers "issues" and "any pasted list": paste the text of a tracker issue that
  contains `path:line` references, `:Qf`, and every reference is a navigable entry. It's
  the general form of what `gdb_bt_qf.lua` does for backtraces (which stays as-is).
- `:QfSave`/`:QfLoad` covers "save lists, parse them" and "interesting files" — build a
  list once, `:QfSave interesting`, reload it days later.

### Piece 3 — jumplist / changes beyond `C-j` / `C-k`
You already remap `C-j` = `<C-i>` (forward) and `C-k` = `<C-o>` (back). To *see and pick*
within the jumplist (not just step), fzf-lua has dedicated pickers:
```lua
-- suggested, pick your own keys:
vim.keymap.set('n', "<leader>'", require('fzf-lua').jumps,   { desc = "jump(') list" })
vim.keymap.set('n', '<leader>;', require('fzf-lua').changes, { desc = "changes (;) list" })
```
These give a fuzzy, previewable view of jumps/changes — the "use the jumplist as a list,
not just two keys" part.

### Piece 4 (optional) — a plain location yank for pasting
Tiny helper that pairs with `:Qf` and with "paste to claude":
```lua
-- copy "relpath:line" of the cursor (arc-root-relative) to the + register
vim.api.nvim_create_user_command("CopyLoc", function()
    local f = vim.api.nvim_buf_get_name(0)
    local root = vim.trim(vim.system({ "arc", "root" }, { cwd = vim.fs.dirname(f), text = true }):wait().stdout or "")
    local rel = root ~= "" and f:sub(#root + 2) or vim.fn.fnamemodify(f, ":.")
    local loc = rel .. ":" .. vim.api.nvim_win_get_cursor(0)[1]
    vim.fn.setreg("+", loc); vim.notify(loc)
end, { desc = "copy relpath:line to clipboard" })
```

## Recommended order within this story
1. `arc_lists.lua` (`:Qf`, `:ArcChangedFiles`, save/load) — immediate, self-contained.
2. fzf-lua `ctrl-q` unification (Piece 1) — one config edit.
3. jumps/changes pickers + `CopyLoc` — optional polish.

## What I deliberately did *not* propose
- A bespoke list datatype / floating list-manager UI. It fights your "look and feel like
  vim, no clutter" rule and duplicates quickfix. The whole point is that quickfix already
  *is* the list engine; it was just (a) getting clobbered (fixed by story 05) and (b) hard
  to fill from your real sources (fixed by `arc_lists.lua`).
