# CLAUDE.md

didedoshka's personal, minimalistic Neovim config (Lua, `lazy.nvim`).

## Philosophy
- Keep the vim look and feel; avoid clutter, popups, and noisy UI.
- Every line must be understandable — prefer small, explicit Lua over abstraction.
  A clever abstraction that saves five lines is a regression here.

## Layout
- `init.lua` — options, filetypes, autocmds, global keymaps, and the `lazy.setup{}` list.
- `lua/plugins/<name>.lua` — one lazy spec per file, `require`d into `init.lua`; short specs
  go inline in `init.lua` instead.
- `plugin/*.lua` — auto-loaded custom features. `lua/gdb_bt_qf.lua` — GDB backtrace → quickfix.
- `colors/dide.lua` + `lua/lualine/themes/dide.lua` — custom colorscheme and statusline theme.
  Edit colours via the `colors` table at the top, never inline hex.
- `snippets/` (mini.snippets), `queries/`, `keymap/`, `tests/`.
- `notes/` — all docs; only `readme.md` and this file live at the root.
  **`notes/project_organization.md` is the full map — read it before any structural change.**
  `notes/plugin_list.md` is the plugin inventory.
- `lazy-lock.json` is gitignored; never commit it.

## Conventions
- Plugin specs always use `config = function()`, never the declarative `keys`/`opts` fields.
- Leader is `<space>`; every keymap carries a `desc` with the mnemonic in parens, e.g. `(u)ndotree`.
- 4 spaces, expandtab.
- `s`, `S`, `x`, `X`, `<C-o>` deliberately print `"habit"` instead of their default. Not a bug;
  don't "fix" them.

## Verifying
- Run `./tests/run.sh` after any Lua change — lint + both tiers, offline, ~1s. A `Write|Edit`
  hook runs it automatically. `.claude/skills/verify/SKILL.md` has the tiers and what needs a human.
- Two traps, both measured in this repo:
  - **`nvim` exits 0 even when `init.lua` throws** — the traceback only reaches stderr. Never
    verify an init.lua change by exit code alone.
  - **`lua-language-server` does not catch cross-module breakage.** Renaming `gdb_bt_qf`'s
    `M.setup()` while `init.lua` calls it is "no problems found". Only loading the code catches
    it — so the hook runs the whole suite, not just the linter. Don't reduce it to a lint.
- Point `lua-language-server --check` at the workspace root, or it won't find `.luarc.json` and
  every `vim` becomes an undefined global.
- Don't add `stylua`: `lua_ls` already formats via EmmyLuaCodeStyle, configured by `.luarc.json`.

## Environment
- Arcadia: clangd and ruff run via `ya tool`; the arcadia commands (`:Cs`, `:Prs`, `:Blame`, …)
  live in a separate local plugin, `~/personal/arc-nvim`.
- No standalone `lua`/`luajit` on this box — `nvim --clean -l` **is** the Lua runtime for tests.
