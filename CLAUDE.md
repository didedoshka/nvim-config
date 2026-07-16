# CLAUDE.md

didedoshka's personal, minimalistic Neovim config (Lua, `lazy.nvim`).

## Philosophy (see `readme.md`)
- Keep the vim look and feel; avoid clutter, popups, and noisy UI.
- Every line of config must be understandable — prefer small, explicit Lua over abstraction.

## Layout
- `init.lua` — core options, filetypes, autocmds (autosave on `TextChanged`/`InsertLeave`), global keymaps, and the `lazy.setup{}` plugin list.
- `lua/plugins/*.lua` — one file per plugin spec; `require("plugins.<name>")` into `init.lua`. Inline specs live directly in `init.lua`.
- `plugin/*.lua` — auto-loaded custom features (e.g. `keymaps_to_buffer`). The arcadia-work commands (`:Cs`, `:Prs`, `:Blame`, `:ArcanumLink`, …) live in a separate local plugin, `~/personal/arc-nvim`.
- `colors/dide.lua`, `lua/lualine/themes/dide.lua` — custom `dide` colorscheme + statusline theme (see below).
- `snippets/`, `queries/`, `keymap/` — LuaSnip snippets, treesitter queries, russian keymap.
- `lazy-lock.json` — plugin lockfile; gitignored, **not** committed.
- `notes/` — all notes and docs: `ideas.md` (backlog), `plugin_list.md`, `project_organization.md`, `cheatsheet-bracket-and-g.md`, research notes. Only `readme.md` and `CLAUDE.md` stay at the root.

## Conventions (see `notes/project_organization.md`)
- Plugin specs always use `config = function()`, never `keys`/`opts`.
- Leader is `<space>`; keymaps use `desc` with the mnemonic letter in parens, e.g. `(u)ndotree`.
- Indentation: 4 spaces, expandtab.
- Some keys (`s`, `S`, `x`, `X`, `<C-o>`) are deliberately disabled as "habit" breakers or repurposed (`s` = arrow.nvim).

## Adding a plugin
Create `lua/plugins/<name>.lua` returning a lazy spec, then add `require("plugins.<name>")` to the list in `init.lua` — or inline it if it's short. See `notes/plugin_list.md` for the full inventory of installed plugins and what each does.

## `colors/dide.lua` (self-contained custom colorscheme, no plugin)
- **Highlight groups** — light, low-contrast theme built from one `colors` palette table; `set_groups()` maps it onto base/Treesitter/LSP/plugin groups. Edit colors via the `colors` table, not inline hex.
- **Semantic highlighting** — original feature (toggle `<leader>s`): colors each variable/type by a hash of its name so identical names share a color. Palette generated in OKLab for even perceptual spacing into `SemanticHighlightingColor{N}` groups, applied via Treesitter queries + extmarks on `FileType`.
