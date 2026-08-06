# CLAUDE.md

didedoshka's personal, minimalistic Neovim config (Lua, `lazy.nvim`).

This config is the hub of a coupled stack: sessions rooted here can also work on
`~/personal/arc.nvim`, `~/personal/debugmaster.nvim`, `~/personal/litre.nvim`,
`~/personal/no-tmux.nvim` and `~/personal/pcre.nvim` (via `additionalDirectories`).
Their instructions load with this file; when editing one of them, follow its rules —
and read its `.claude/skills/verify/SKILL.md` for that repo's verify tiers, since only
this repo's skills are listed here.

@~/personal/arc.nvim/CLAUDE.md
@~/personal/debugmaster.nvim/CLAUDE.md

## Philosophy
- Keep the vim look and feel; avoid clutter, popups, and noisy UI.
- Every line must be understandable — prefer small, explicit Lua over abstraction.
  A clever abstraction that saves five lines is a regression here.
- Don't update these docs as a side effect of a code change. If a change makes a line stale,
  delete the line rather than rewriting it, and ask before adding new prose. Inventories —
  plugin lists, keymap tables, directory trees — are derivable from the code and rot; the
  only things worth writing down are decisions, rationale, and measured traps.

## Layout
- `init.lua` — options, filetypes, autocmds, global keymaps, and the `lazy.setup{}` list.
- `lua/plugins/<name>.lua` — one lazy spec per file, `require`d into `init.lua`; short specs
  go inline in `init.lua`, added before the closing `})`.
- `plugin/*.lua` — auto-loaded custom features. `lua/gdb_bt_qf.lua` — GDB backtrace → quickfix.
- `colors/dide.lua` + `lua/lualine/themes/dide.lua` — custom colorscheme and statusline theme.
  Edit colours via the `colors` table at the top, never inline hex.
- `snippets/` (mini.snippets), `queries/`, `keymap/`, `tests/`.
- `notes/` — didedoshka's own notes and research, not yours. `ideas.md` in particular is theirs;
  don't edit it. Only `readme.md` and this file live at the root.
- `lazy-lock.json` is gitignored; never commit it.

## Conventions
- Plugin specs always use `config = function()`, never the declarative `keys`/`opts` fields.
- Leader is `<space>`; every keymap carries a `desc` with the mnemonic in parens, e.g. `(u)ndotree`.
- 4 spaces, expandtab.
- `s`, `S`, `<C-o>` deliberately print `"habit"` instead of their default. Not a bug;
  don't "fix" them. `s`, `x` and `<bs>` are layer leaders (arrow.nvim, litre, debug).

## Verifying
- Run `./tests/run.sh` after any Lua change — lint + both tiers, offline, ~1s. A `Write|Edit`
  hook runs it automatically. `.claude/skills/verify/SKILL.md` has the tiers and what needs a human.
- Commit each verified change without asking (`area: lowercase summary`). Never rewrite
  history — no amend, rebase, or reset past a commit; fix forward with a new commit,
  so nothing is ever lost.
- Three traps, all measured in this repo:
  - **`nvim` exits 0 even when `init.lua` throws** — the traceback only reaches stderr. Never
    verify an init.lua change by exit code alone.
  - **`lua-language-server` does not catch cross-module breakage.** Renaming `gdb_bt_qf`'s
    `M.setup()` while `init.lua` calls it is "no problems found". Only loading the code catches
    it — so the hook runs the whole suite, not just the linter. Don't reduce it to a lint.
  - **`tests/core_spec.lua` must never `:edit` a real file** — applying `dide` registers a
    `FileType` autocmd that needs nvim-treesitter, absent under `--clean`.
- Point `lua-language-server --check` at the workspace root, or it won't find `.luarc.json` and
  every `vim` becomes an undefined global (~270 of them).
- Don't add `stylua`: `lua_ls` already formats via EmmyLuaCodeStyle, configured by `.luarc.json`.

## LSP & formatting
- Formatting is none-ls, not the language servers — clangd's own formatting is disabled in its
  `on_attach`. Python is the exception: `ruff format` via the ruff LSP.
- Python is split: `pyright` type-checks, `ruff` lints and formats. To avoid duplicate reports
  pyright's `reportUnused*` are set to `none`, and its always-on greyed "not accessed" hints are
  filtered out at `vim.diagnostic.set`. Ruff's lint mirrors CI flake8
  (`~/arc/build/config/tests/flake8/flake8.conf`).

## Environment
- Arcadia: clangd and ruff run via `ya tool`; the arcadia commands (`:Cs`, `:Prs`, `:Blame`, …)
  live in a separate local plugin, `~/personal/arc.nvim`.
- No standalone `lua`/`luajit` on this box — `nvim --clean -l` **is** the Lua runtime for tests.
