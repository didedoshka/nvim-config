# Project organization

didedoshka's personal, minimalistic Neovim config (Lua, `lazy.nvim`). This document
describes how the config is laid out and the conventions to follow when editing it.

## Philosophy (see `readme.md`)

1. Look and feel like vim; keep the vim workflow. No clutter, popups, or noisy UI.
2. Every line of config must be understandable — prefer small, explicit Lua over abstraction.

## Directory layout

- `init.lua` — the entry point. Core options, filetypes, autocmds, global keymaps, `lazy`
  bootstrap, and the `require("lazy").setup({ ... })` plugin list.
- `lua/plugins/*.lua` — one file per plugin, each returning a `lazy.nvim` spec table, pulled
  into `init.lua` via `require("plugins.<name>")`. Short specs are inlined directly in `init.lua`.
- `plugin/*.lua` — auto-loaded custom features (no plugin manager involved):
  - `keymaps_to_buffer.lua` — `<leader>y` dumps `<leader>`/`<bs>` mappings into a scratch buffer.
  - `test_ui.lua` — coroutine/`vim.ui` experiment (`<bs>y`); scratch, not a real feature.
- `lua/gdb_bt_qf.lua` — module `require`d in `init.lua`; parses a GDB backtrace into the quickfix
  list. Commands: `:GdbBtQf` (whole buffer), `:GdbBtQfSelection` (visual range). `root` maps GDB's
  `/...` paths onto `~/arc/...`.
- `colors/dide.lua` — the custom `dide` colorscheme (self-contained, no plugin); see below.
- `lua/lualine/themes/dide.lua` — matching statusline theme (light, `#FFFFFF` bg).
- `keymap/russian-yasherty.vim` — Russian keymap layer (`vim.opt.keymap`); toggle insert-mode
  language with `<C-l>` (mapped to `<C-^>`).
- `queries/` — custom Treesitter queries. `c/highlights.scm` tunes C highlighting; `queries/yamake`
  is used by the local `tree-sitter-yamake` grammar.
- `snippets/*.lua` — `mini.snippets` language files (`c`, `cpp`, `lua`), loaded via
  `gen_loader.from_lang()`; each returns a list of `{ prefix, body }` tables.
- `notes/` — everything written rather than executed: `ideas.md` (backlog), `plugin_list.md`,
  this file, `cheatsheet-*.md`, and research notes. Only `readme.md` and `CLAUDE.md` live at
  the root.
- `.gitignore` — ignores `lazy-lock.json` (the lockfile is **not** committed) and `.DS_Store`.

## Plugin specs: always `config`, never `keys`/`opts`

Define every `lazy.nvim` plugin with a `config = function() ... end` block. Do **not** use the
declarative `keys` or `opts` fields — all setup and keymaps go inside `config`:

```lua
{
    "author/plugin",
    config = function()
        require("plugin").setup({ ... })
        vim.keymap.set("n", "<leader>x", ..., { desc = "(x) description" })
    end,
}
```

A single style across the whole config keeps it uniform and easy to read.

## Where plugins live

Inline plugin specs live directly in the `lazy.setup({ ... })` table at the end of `init.lua`;
add new inline plugins before the closing `})` rather than creating a new file, unless asked.
Larger specs get their own `lua/plugins/<name>.lua` and a `require("plugins.<name>")` entry in the list.

### Plugins by area

- **Editing/motion** — `flit`/`leap` (`f`/`t` + labels), `Comment` (`<leader>/`), `nvim-autopairs`,
  `text-case` (`ga*`), `refactoring.nvim` (`:Refactor`), `nvim-rip-substitute` (`<leader>rs`),
  `arrow.nvim` (bookmarks, leader `s`), `undotree` (`<leader>u`).
- **Completion/snippets** — `nvim-cmp` + `cmp-*` sources with `mini.snippets` (`lua/plugins/cmp.lua`).
- **LSP/format** — `nvim-lspconfig` + `none-ls` + `lsp_signature` (`lua/plugins/lspconfig.lua`).
- **Treesitter** — `nvim-treesitter` with on-`FileType` auto-install + local `yamake` grammar.
- **Navigation/UI** — `fzf-lua` (`<leader>o/b/h/g/p`), `oil.nvim` (`<leader>w`/`<leader>t`),
  `lualine` (custom LSP-progress component), `which-key`, `nvim-navic` (`<leader>n`),
  `indent-blankline`, `rainbow-delimiters`, `nvim-colorizer`, `render-markdown`.
- **Git** — `lazygit.nvim` (`<leader>c`).
- **Debug** — `debugmaster.nvim` + `nvim-dap` + `brd` (`<leader>i`, codelldb for cpp).
- **Notes** — `zk-nvim` (`<leader>z*`).

## LSP & formatting

- Servers configured/enabled in `lspconfig.lua`: `lua_ls`, `pyright`, `clangd`, `cmake`,
  `tinymist`, `rust_analyzer`, `ruff`, `protols`, `gopls`. Shared `capabilities` from `cmp_nvim_lsp`.
  Several servers run through `ya tool …` (clangd, ruff).
- Python tooling is split: `pyright` does type-checking + navigation, `ruff` (via `ya tool ruff
  server`) does lint + formatting. Ruff's lint mirrors CI flake8
  (`~/arc/build/config/tests/flake8/flake8.conf`): `select = { E, W, F, N }`, `lineLength = 200`.
  To avoid duplicate "unused" reports, pyright's `reportUnused*` are set to `none` and its always-on
  greyed "not accessed" hints (Unnecessary tag) are filtered out at `vim.diagnostic.set` (pyright
  namespace only).
- Other formatting is done by **none-ls** (not the language servers). clangd's own formatting is
  disabled in its `on_attach`. Sources: `cmake_format`, `prettier`, `clang_format` (custom
  `ads-clang-format`). Python formatting is `ruff format` via the ruff LSP, not none-ls.
- `<leader>f` formats: whole file in normal mode, selection-only in visual mode. Range formatting is
  supported by clang-format (`--offset`/`--length` via none-ls) and `ruff format` (`--range` via the
  ruff LSP).
- LSP keymaps are set per-buffer on `LspAttach` (`gd`, `gr`, `K`, `<leader>r`, `<leader>a`, `[d`/`]d`,
  inlay-hint toggle `<leader>v`, and custom `[f`/`[c`/`go` document-symbol jumps).

## Custom colorscheme (`colors/dide.lua`)

- **Highlight groups** — light, low-contrast theme built from one `colors` palette table at the top;
  `set_groups()` maps it onto base/Treesitter/LSP/plugin groups. Edit colors via the table, not inline hex.
- **Semantic highlighting** (original feature, toggle `<leader>s`) — colors each variable/type by a
  hash of its name so identical names share a color. Palette generated in OKLab for even perceptual
  spacing into `SemanticHighlightingColor{N}` groups, applied via Treesitter queries + extmarks on `FileType`.

## Conventions

- Leader and localleader are both `<space>`.
- Indentation: 4 spaces, `expandtab`.
- Keymaps use `desc` with the mnemonic letter in parens, e.g. `(u)ndotree`, `(o)pen file`.
- Jump/window keys are remapped: `<C-j>` = jump-forward (`<C-i>`), `<C-k>` = jump-back (`<C-o>`),
  `<tab>` = window prefix (`<C-w>`).
- Habit-breakers: `s`, `S`, `x`, `X`, `<C-o>` print `"habit"` instead of their default; some are
  repurposed as layer leaders (`s` = arrow.nvim, `<bs>` = brd).
- Autosave: buffers `:update` on `TextChanged`/`InsertLeave` (real files only).

## Environment integration (Yandex / Arcadia)

This config assumes an Arcadia checkout at `~/arc` and Yandex tooling:
- clangd runs as `ya tool clangd`; ruff as `ya tool ruff server`; C++ formatting uses `ads-clang-format`.
- `gdb_bt_qf.lua` relies on `arc` and `~/arc` paths; the arcanum link commands
  (`:ArcanumLink`, `:ArcanumOpen`, …) live in `~/personal/arc-nvim`.
- Treesitter pulls a local `tree-sitter-yamake` grammar from `~/arc/devtools/ide/tree-sitter-yamake`
  and registers `ya.make` as the `yamake` filetype.
