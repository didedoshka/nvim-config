# ideas.md TODO — implementation & explanations (19.07)

## 1. Буфер обмена / регистры

Your setup: `vim.g.clipboard = "osc52"` + `vim.opt.clipboard = "unnamed,unnamedplus"`.

### Which register gets what (stock vim behaviour)

- `"` (unnamed) — **every** `y`, `d`, `c`, `x`, `s` writes here. `p` reads from it by default.
- `0` — the last **yank only**. Deletes never touch it. This is the answer to
  "I yanked, then deleted something, and paste gives me the deleted text": use `"0p`.
- `1`–`9` — delete history. `1` gets the last "big" delete/change (≥ one line, or with motions
  like `d/foo`), and older ones shift down `1→2→…→9`. `".` repeated with `u` lets you do
  `"1p` then `u.u.u.` to cycle candidates.
- `-` — "small delete" register: deletes of less than one line (`dw`, `x`, …).
- `a`–`z` — named, explicit only (`"ayy`); uppercase `"Ayy` **appends** to `a`.
- `_` — black hole: `"_dd` deletes without clobbering anything.
- Read-only: `:` (last cmdline), `.` (last inserted text), `%` (current file), `/` (last search).
- `+` / `*` — the OS clipboard(s); on this headless box both go through OSC52 to the
  **local** terminal's clipboard.

Useful everywhere: `:registers` to inspect, `<C-r><reg>` to insert a register in
insert/cmdline mode (`<C-r>0`, `<C-r>+`, `<C-r>/`).

### What your `clipboard=unnamed,unnamedplus` does

Every yank **and delete** is mirrored into both `*` and `+` (i.e. sent to your local
clipboard via OSC52), and plain `p` pastes from `+`. Two consequences:

1. `dd` overwrites your system clipboard — the classic "I copied a URL in the browser,
   deleted a line in vim, and the URL is gone" annoyance.
2. Plain `p` triggers an OSC52 clipboard *read*, which not every terminal answers
   (some prompt, some silently return nothing).

If either bites, the common alternative is: **stop syncing implicitly, sync yanks only**:

```lua
vim.opt.clipboard = ""            -- registers stay local
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        if vim.v.event.operator == "y" and vim.v.event.regname == "" then
            vim.fn.setreg("+", vim.fn.getreg('"'))
        end
    end,
})
```

Then `y` still lands in the local clipboard, deletes don't, and `p` pastes the fast
in-vim register (paste from the OS with `"+p` explicitly). Not applied — your call.

## 2. Обновление ya tools по крону + симлинки — implemented (needs 2 commands)

`crontab` is **forbidden for your user on this box** ("You (dagorokhov) are not allowed
to use this program"), so this is a systemd **user timer** instead. It automates the
pattern you already started by hand with `ads-clang-format` → `~/.local/cellar/`.

Installed:

- `~/.local/bin/ya-tool-refresh` — for each tool in the list at the top
  (`cs ruff ads-clang-format`, edit to taste): resolves the real binary with
  `ya tool <t> --print-path`, copies it into `~/.local/cellar/<t>/<t>` (only when
  changed, atomically), and symlinks `~/.local/bin/<t>` to the copy. The copy is the
  point: ya GC can delete old `~/.ya/tools` versions, the cellar copy survives, so the
  tool works even when ya's backend is down.
- `~/.config/systemd/user/ya-tool-refresh.service` + `.timer` — daily, `Persistent=true`
  (catches up after reboots), randomized ±1h.

The permission sandbox wouldn't let me chmod/enable, so run once:

```
! chmod +x ~/.local/bin/ya-tool-refresh && ~/.local/bin/ya-tool-refresh
! systemctl --user daemon-reload && systemctl --user enable --now ya-tool-refresh.timer
```

Natural follow-up (not done): once `~/.local/bin/ruff` exists, `lspconfig.lua` could use
`{ vim.fn.expand("~/.local/bin/ruff"), "server" }` instead of `ya tool ruff server` — then
the ruff LSP also survives ya being down (the `-- важно что когда лежит сервер ya tool
c++ не работает` item).

## 3. Красивый markdown (markview) — explanation, recommend staying

markview.nvim renders more than render-markdown: bordered tables, inline LaTeX, HTML
entities, fancier headings/callouts, plus its own live "hybrid" edit mode. The costs, for
this config specifically:

- Its default look leans **heavily** on nerd-font glyphs — you'd redo the same de-icing
  you already did for render-markdown, but across a much larger option surface.
- It's a bigger, faster-moving codebase with more UI chrome — against the "vim look and
  feel, no clutter" philosophy.
- render-markdown meanwhile gained most of the visible wins (tables, headings, code
  blocks) since you first evaluated it.

Recommendation: stay on render-markdown; revisit markview only if you concretely miss
LaTeX/table-border rendering. If you do try it, the whole diff is swapping one plugin
spec — nothing else in the config depends on which one renders markdown.

## 4. Открывать ссылку в браузере — implemented

This box is headless (no `xdg-open`, no `$DISPLAY`), so nothing here can *open* a
browser. What works: `init.lua` now overrides `vim.ui.open`, so **`gx`** (normal or
visual, understands markdown links) copies the URL to your **local** clipboard through
OSC52 and notifies — then paste it in the browser. Anything else that calls
`vim.ui.open` (lazy.nvim's `o` on a plugin, etc.) gets the same behaviour instead of an
"no handler" error. Also worth knowing: most terminals open URLs directly on
click/cmd-click, no vim involvement.

## 5. fzf-lua grep in a directory / :Cs — implemented + already possible

- New keymap **`<leader>s`** — "(s)earch in directory": prompts for a directory
  (default: the current file's directory, `<Tab>` completes paths), then runs fzf-lua
  `live_grep` with that cwd. Plain `<leader>h` stays as-is for cwd-wide grep.
  Mind the usual rule: don't point it at `~/a` or 1–2 levels below it.
- **`:Cs` already scopes** — it passes its args straight to `cs` as flags:
  - `:Cs -f ^yt/yt/core/` — restrict to a path (RE2 regex on the file path);
  - `:Cs -f (yt/|library/cpp/yt)` — several paths at once;
  - `-j` / `-c` — exclude junk / vendored code.
  (`-E` "current folder" is useless from nvim: the picker always runs from the arc
  root, so `-E` = whole repo.) No arc-nvim change needed.
