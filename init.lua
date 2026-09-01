-- Created by didedoshka on May 24

-- set leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- set indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- set number
vim.opt.number = true
vim.opt.relativenumber = true

-- sync clipboard between vim and os
vim.g.clipboard = "osc52"
vim.opt.clipboard = "unnamed,unnamedplus"
-- set wrap and max text width
vim.opt.wrap = false
vim.opt.linebreak = true
-- vertical screens: zt alone puts the line at the very top, keep some context above it
vim.opt.scrolloff = 5
-- vim.opt.colorcolumn = "120"

-- highlight the line of the cursor in every window
vim.opt.cursorline = true

vim.opt.undofile = true

-- borders on all floats that don't set their own (dap widgets, lsp hover, cmp)
vim.opt.winborder = "single"

-- set filetypes
-- .log files are only claimed as ytlog when the first line has the YTsaurus
-- shape (<timestamp>\t<level>\t...); zst logs re-detect as .log after gzip.vim
-- decompresses them, so one sniff covers both.
local function is_ytlog(_, bufnr)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    if line and line:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d,%d+%s+%a%s+") then
        return "ytlog"
    end
end

vim.filetype.add({
    extension = { ["keymap"] = "cpp" },
    pattern = {
        ['.*.cpp.inc'] = 'cpp',
        ['.*.h.inc'] = 'cpp',
        ['.*%.log'] = is_ytlog,
        ['.*%.log%.zst'] = is_ytlog,
    },
})

-- set russian
vim.opt.keymap = "russian-yasherty"
vim.opt.iminsert = 0
vim.keymap.set('i', '<C-l>', '<C-^>', { remap = true })

-- set listchars
vim.opt.list = true
vim.opt.listchars = { tab = '  ', eol = '¬', trail = '·' }

-- installing lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- init.lua's own autocmds live in one augroup, cleared on re-create, so
-- :Reload (plugin/reload.lua) can re-source this file without duplicating them
local init_group = vim.api.nvim_create_augroup("init", { clear = true })

-- autocommand for opening typst file
vim.api.nvim_create_autocmd("FileType", {
    group = init_group,
    callback = function(args)
        if args['match'] == 'typst' then
            vim.keymap.set('i', '$', '$<C-l>', { remap = true, buffer = args.buf })
        end
    end
})

-- terminals default to nonumber (:h terminal-config); re-enable for jumps in output
vim.api.nvim_create_autocmd("TermOpen", {
    group = init_group,
    callback = function()
        vim.wo.number = true
        vim.wo.relativenumber = true
    end,
})

-- autosaving
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = init_group,
    pattern = { "*.*" },
    callback = function()
        if vim.bo.buftype == "" and vim.bo.modifiable and vim.fn.expand("%") ~= "" and vim.bo.filetype ~= "" then
            vim.cmd("silent update")
        end
    end,
})


-- working with buffers
vim.keymap.set("n", "<leader>q", "<cmd>bp<bar>sp<bar>bn<bar>bd<cr>", { desc = "close buffer" })
vim.keymap.set("n", "<C-j>", "<C-i>", { desc = "" })
vim.keymap.set("n", "<C-k>", "<C-o>", { desc = "" })
vim.keymap.set("n", "<C-o>", function() print("habit") end, { desc = "" })
vim.keymap.set("n", "y", "<C-w>", { desc = "Window commands *CTRL-W*" })
vim.keymap.set("n", "<leader>t", "<cmd>terminal<cr>", { desc = "(t)erminal" })
-- vim.keymap.set("n", "gm", "m", { desc = "set mark" })

-- habits
vim.keymap.set("n", "<tab>", function() print("habit") end, { desc = "" })
vim.keymap.set("n", "s", function() print("habit") end, { desc = "" })
vim.keymap.set("v", "s", function() print("habit") end, { desc = "" })
vim.keymap.set("n", "S", function() print("habit") end, { desc = "" })
vim.keymap.set("v", "S", function() print("habit") end, { desc = "" })

-- running lua
-- vim.keymap.set("n", "<bs>?", ":.lua<cr>", { desc = "execute current (l)ua code" })
-- vim.keymap.set("v", "<bs>?", ":lua<cr>", { desc = "execute current (l)ua code" })

-- headless box, no browser: gx (and anything else calling vim.ui.open)
-- copies the url to the local clipboard through osc52 instead
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.open = function(uri)
    vim.fn.setreg("+", uri)
    vim.notify("copied: " .. uri)
end

-- terminal
vim.keymap.set("t", "<C-e>", "<c-\\><c-n>")
vim.opt.scrollback = 100000

vim.cmd.colorscheme('dide')

vim.go.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor,a:Cursor"
vim.diagnostic.config({ virtual_text = true })

vim.keymap.set("n", "<leader>m", "<cmd>restart<cr>", { desc = "restart nvim" })

require("gdb_bt_qf").setup({})

-- setting plugins
require("lazy").setup({
    -- colorscheme
    -- require("plugins.ayu"),

    {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("ibl").setup({
                indent = { highlight = "Comment", char = "▏" },
                scope = { enabled = false }
            })
            local hooks = require "ibl.hooks"
            hooks.register(
                hooks.type.WHITESPACE,
                hooks.builtin.hide_first_space_indent_level
            )
        end,
    },

    -- flit
    require("plugins.flit"),

    -- fzf-lua
    require("plugins.fzf"),

    -- file explorer
    require("plugins.oil"),

    -- cmp
    require("plugins.cmp"),

    -- treesitter
    require("plugins.treesitter"),

    -- lspconfig
    require("plugins.lspconfig"),

    -- comment
    require("plugins.comment"),

    -- lazygit
    require("plugins.lazygit"),

    -- nvim launched inside :terminal opens in this instance instead of nesting
    require("plugins.flatten"),

    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup({
                delay = 2000,
                icons = {
                    mappings = false,
                    -- the defaults for these are nerd-font glyphs
                    keys = {
                        Up = "<Up> ",
                        Down = "<Down> ",
                        Left = "<Left> ",
                        Right = "<Right> ",
                        C = "C-",
                        M = "M-",
                        D = "D-",
                        S = "S-",
                        CR = "<CR> ",
                        Esc = "<Esc> ",
                        ScrollWheelDown = "<ScrollDown> ",
                        ScrollWheelUp = "<ScrollUp> ",
                        NL = "<NL> ",
                        BS = "<BS> ",
                        Space = "<Space> ",
                        Tab = "<Tab> ",
                        F1 = "F1",
                        F2 = "F2",
                        F3 = "F3",
                        F4 = "F4",
                        F5 = "F5",
                        F6 = "F6",
                        F7 = "F7",
                        F8 = "F8",
                        F9 = "F9",
                        F10 = "F10",
                        F11 = "F11",
                        F12 = "F12",
                    },
                },
            })
        end,
    },

    require("plugins.dap"),

    -- disk persistence for dap breakpoints; actions.lua in debugmaster's fork
    -- saves through it when present, see that repo's CLAUDE.md
    require("plugins.persistent-breakpoints"),

    -- imperative project tasks from .litre.lua files, local checkout
    require("plugins.litre"),

    -- / and :s with pcre2 via rg, local checkout
    require("plugins.pcre"),

    -- nvim-as-tmux: per-project servers, :Connect hops, quitguard; local checkout
    require("plugins.no-tmux"),

    {
        "catgoose/nvim-colorizer.lua",
        config = function()
            require("colorizer").setup({
                user_default_options = {
                    names = false, -- "Name" codes like Blue or red
                },
            })
        end,
    },

    {
        'hiphish/rainbow-delimiters.nvim',
        config = function()
            require('rainbow-delimiters.setup').setup {
                highlight = {
                    "SemanticHighlightingColor1",
                    "SemanticHighlightingColor11",
                    "SemanticHighlightingColor9",
                    "SemanticHighlightingColor6",
                },
                condition = function(bufnr)
                    local max_filesize = 1024 * 1024 -- 1 MiB
                    local ok, stats = pcall(
                        vim.uv.fs_stat,
                        vim.api.nvim_buf_get_name(bufnr)
                    )

                    return not ok or not stats or stats.size <= max_filesize
                end,
            }
        end
    },

    {
        "zk-org/zk-nvim",
        config = function()
            require("zk").setup()
        end
    },

    {
        "johmsalas/text-case.nvim",
        config = function()
            require("textcase").setup({})
        end,
    },

    require("plugins.lualine"),

    -- arcadia work inside nvim (:ArcFzfCs, :ArcFzfPrs, :ArcPrView, :ArcBlame, ...), local checkout
    {
        dir = vim.fn.expand("~/personal/arc.nvim"),
        config = function()
            require("arc").setup()
            -- the next letter is the same thing on the PR instead of the checkout
            vim.keymap.set("n", "<leader>ab", "<cmd>ArcBlame<cr>", { desc = "(a)rc (b)lame" })
            vim.keymap.set("n", "<leader>ac", "<cmd>ArcPrBlame<cr>", { desc = "(a)rc PR blame" })
            vim.keymap.set("n", "<leader>ad", "<cmd>ArcDiff<cr>", { desc = "(a)rc (d)iff" })
            vim.keymap.set("n", "<leader>ae", "<cmd>ArcPrDiff<cr>", { desc = "(a)rc PR diff" })
            -- `:` not <cmd>: in visual mode it carries the selection as the range (#L2-4)
            vim.keymap.set({ "n", "x" }, "<leader>al", ":ArcLinkCreate<cr>", { desc = "(a)rc (l)ink" })
            vim.keymap.set("n", "<leader>ap", "<cmd>ArcPrView<cr>", { desc = "(a)rc (p)r view" })
        end,
    },

    {
        "SmiteshP/nvim-navic",
        config = function()
            local navic = require("nvim-navic")
            navic.setup({
                lsp = { auto_attach = true },
                icons = {
                    enabled = false,
                },
            })

            local navic_on = false

            vim.keymap.set("n", "<leader>n", function()
                if navic_on then
                    vim.o.winbar = ""
                else
                    vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
                end
                navic_on = not navic_on
            end, { desc = "toggle navic" })
        end
    },

    -- files pinned to chars + open buffers on `s`, local checkout (arrow's successor)
    require("plugins.fzf-pin"),

    {
        'MeanderingProgrammer/render-markdown.nvim',
        config = function()
            require("render-markdown").setup({
                -- Disable gutter signs globally (optional, but recommended if you hate clutter)
                sign = { enabled = false },

                heading = {
                    icons = {}, -- Disables heading icons (like 󰲡, 󰲣)
                    signs = {}, -- Disables the heading indicators in the gutter
                },

                bullet = {
                    icons = {}, -- Disables custom bullet point icons
                },

                checkbox = {
                    -- Instead of Nerd Font icons, revert to standard text brackets
                    unchecked = { icon = '[ ]' },
                    checked   = { icon = '[x]' },
                    -- (Alternatively, use icon = '' to remove them completely)
                },

                code = {
                    sign = false,   -- Disables the language icon in the gutter
                    style = 'none', -- Keeps the background highlighting but removes extra flair
                },

                callout = {
                    -- If you use Obsidian-style callouts (> [!INFO]), you may need to
                    -- overwrite the defaults to strip their icons as well.
                    note = { icon = '' },
                    tip = { icon = '' },
                    warning = { icon = '' },
                    -- etc...
                }
            })
        end,
    },

    -- {
    --     "m4xshen/hardtime.nvim",
    --     config = function()
    --         vim.opt.showmode = false
    --         require("hardtime").setup({
    --             disabled_keys = {
    --                 ["<Up>"] = false,
    --                 ["<Down>"] = false,
    --                 ["<Left>"] = false,
    --                 ["<Right>"] = false,
    --             }
    --         })
    --     end
    -- },

    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = {
            "lewis6991/async.nvim",
        },
    },

    {
        "mbbill/undotree",
        config = function()
            vim.g.undotree_WindowLayout = 2
        end
    },

}, {
    -- dev plugins (dev = true in a spec) come from ~/personal when the
    -- checkout exists, and from github on machines that don't have it
    dev = { path = "~/personal", fallback = true },
})
