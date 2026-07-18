# Plugin list

All plugins managed by `lazy.nvim`, grouped by area. Specs live inline in `init.lua` or in
`lua/plugins/<name>.lua`. Notable dependencies are noted inline.

## Editing & motion

| Plugin | Description |
| --- | --- |
| `ggandor/flit.nvim` | 1-char `f`/`F`/`t`/`T` motions with labels (deps: `leap.nvim`, `tpope/vim-repeat`). |
| `numtostr/comment.nvim` | Toggle comments (`<leader>/`). |
| `windwp/nvim-autopairs` | Auto-insert matching brackets/quotes (cmp dependency). |
| `johmsalas/text-case.nvim` | Case coercion (`gas` snake, `gac` camel, `gad` dash; `:Subs`). |
| `ThePrimeagen/refactoring.nvim` | Refactoring operations (`:Refactor`; dep `lewis6991/async.nvim`). |
| `chrisgrieser/nvim-rip-substitute` | ripgrep-based search/replace UI (`<leader>rs`). |
| `otavioschwanck/arrow.nvim` | Per-project file bookmarks (leader key `s`). |
| `mbbill/undotree` | Visualize the undo history (`<leader>u`). |

## Completion & snippets

| Plugin | Description |
| --- | --- |
| `hrsh7th/nvim-cmp` | Completion engine; sources `cmp-nvim-lsp`, `cmp-path`, `cmp-buffer`, `cmp-cmdline`. |
| `nvim-mini/mini.nvim` | Provides `mini.snippets` for snippet expansion (via `abeldekat/cmp-mini-snippets`). |

## LSP & formatting

| Plugin | Description |
| --- | --- |
| `neovim/nvim-lspconfig` | LSP client configuration (lua_ls, pyright, clangd, ruff, gopls, …). |
| `nvimtools/none-ls.nvim` | External tools as LSP sources; used here for formatting (clang-format, prettier, cmake; Python lint/format is handled by ruff). |
| `ray-x/lsp_signature.nvim` | Function signature hint while typing. |

## Treesitter

| Plugin | Description |
| --- | --- |
| `nvim-treesitter/nvim-treesitter` | Syntax parsing/highlighting; auto-installs parsers on `FileType`, plus a local `yamake` grammar. |

## Navigation & UI

| Plugin | Description |
| --- | --- |
| `ibhagwan/fzf-lua` | Fuzzy finder — files `<leader>o`, buffers `<leader>b`, live grep `<leader>h`, buffer grep `<leader>g`, help `<leader>p`; also `vim.ui.select`. |
| `stevearc/oil.nvim` | Edit the filesystem as a buffer (`<leader>w` cwd, `<leader>t` project root). |
| `nvim-lualine/lualine.nvim` | Statusline (custom `dide` theme + live LSP-progress component). |
| `folke/which-key.nvim` | Popup of pending keybindings (`<leader>?` for buffer-local). |
| `SmiteshP/nvim-navic` | Breadcrumb of the current code location; winbar toggle `<leader>n`. |
| `lukas-reineke/indent-blankline.nvim` | Indentation guides. |
| `hiphish/rainbow-delimiters.nvim` | Color-matched nested brackets. |
| `catgoose/nvim-colorizer.lua` | Highlight color codes (`#rrggbb`, etc.) in-line. |
| `MeanderingProgrammer/render-markdown.nvim` | In-buffer Markdown rendering (icons stripped to stay minimal). |

## Git

| Plugin | Description |
| --- | --- |
| `kdheepak/lazygit.nvim` | Open the lazygit TUI (`<leader>c`; dep `nvim-lua/plenary.nvim`). |

## Debugging

| Plugin | Description |
| --- | --- |
| `debugmaster.nvim` | Debug UI/mode over `nvim-dap` (dep `mfussenegger/nvim-dap`). Fork of `MironPascalCaseFan/debugmaster.nvim`, local checkout at `~/personal/debugmaster.nvim`. |
| `brd` | Build/run/debug helper driving DAP configs (`<leader>i` → `:BrdConfig`; codelldb for C++). Local checkout at `~/personal/brd`. |

## Notes

| Plugin | Description |
| --- | --- |
| `zk-org/zk-nvim` | Zettelkasten notes — new `<leader>zn`, insert link `<leader>zi`, backlinks `<leader>zb`. |

## Disabled / available

| Plugin | Description |
| --- | --- |
| `Shatur/neovim-ayu` | Alternative colorscheme in `lua/plugins/ayu.lua`; not loaded (the custom `dide` colorscheme is used instead). |
