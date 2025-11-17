-- Created by didedoshka on May 24

-- function to print a table
--
vim.deprecate = function() end

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
vim.opt.clipboard = "unnamedplus"
-- set wrap and max text width
vim.opt.wrap = false
-- vim.opt.colorcolumn = "120"

vim.opt.undofile = true

-- set extensions
vim.filetype.add({ extension = { ["keymap"] = "cpp" } })

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

local table_of_plugins = {}
-- autocommand for wrapping in typst file
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        local bufnr = args.buf
        if vim.bo[bufnr].filetype == "typst" or vim.bo[bufnr].filetype == "markdown" then
            vim.opt.wrap = true
        else
            vim.opt.wrap = false
        end
    end
})

-- autocommand for opening typst file
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        if args['match'] == 'typst' then
            vim.opt.iminsert = 1
            vim.keymap.set('i', '$', '$<C-l>', { remap = true, buffer = args.buf })
        end
    end
})

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    pattern = { "*.py", "*.cpp", "*.h", "*.c", "*.S", "*.txt", "*.lua", "*.typ", "*.md", "*.proto", "*.go", "*.rs" },
    command = "silent update"
})

-- vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
--     pattern = { "*.rs" },
--     command = "w"
-- })

-- working with buffers
vim.keymap.set("n", "<leader>q", "<cmd>bp<bar>sp<bar>bn<bar>bd<cr>", { desc = "close buffer" })
vim.keymap.set("n", "<C-j>", "<C-i>", { desc = "" })
vim.keymap.set("n", "<C-k>", "<C-o>", { desc = "" })
vim.keymap.set("n", "<C-o>", function() print("habit") end, { desc = "" })
vim.keymap.set("n", "<tab>", "<C-w>", { desc = "" })

-- running lua
-- vim.keymap.set("n", "<bs>?", ":.lua<cr>", { desc = "execute current (l)ua code" })
-- vim.keymap.set("v", "<bs>?", ":lua<cr>", { desc = "execute current (l)ua code" })

-- terminal
vim.keymap.set("t", "<C-e>", "<c-\\><c-n>")
vim.opt.scrollback = 100000

vim.cmd.colorscheme('dide')

vim.go.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor,a:Cursor"
vim.diagnostic.config({ virtual_text = true })

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

    -- telescope
    require("plugins.telescope"),

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

    {
        "mbbill/undotree",
        config = function()
            vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "(u)ndotree" })
            vim.g.undotree_WindowLayout = 2
        end
    },

    {
        "folke/which-key.nvim",
        lazy = false,
        opts = {
            delay = 2000,
            icons = {
                mappings = false,
            },
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "buffer-local mappings",
            },
        },
    },

    require("plugins.dap"),

    {
        'echasnovski/mini.nvim',
        version = '*',
        config = function()
            require('mini.splitjoin').setup()
            -- require('mini.surround').setup()
        end
    },

    {
        "catgoose/nvim-colorizer.lua",
        opts = {
            user_default_options = {
                names = false, -- "Name" codes like Blue or red
            },
        },
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
            }
        end
    },

    {
        "zk-org/zk-nvim",
        config = function()
            require("zk").setup()
            vim.keymap.set("n", "<leader>zn", "<cmd>ZkNew<cr>", { desc = "(z)k (n)ew" })
            vim.keymap.set("n", "<leader>zi", "<cmd>ZkInsertLink<cr>", { desc = "(z)k (i)nsert" })
            vim.keymap.set("n", "<leader>zb", "<cmd>ZkBacklinks<cr>", { desc = "(z)k (b)acklinks" })
        end
    },

    {
        "johmsalas/text-case.nvim",
        config = function()
            require("textcase").setup({})
        end,
    },

    require("plugins.lualine"),

    {
        "didedoshka/brd",
    },

    {
        "perillo/qbe.vim",
    },

    {
        "SmiteshP/nvim-navic",
        config = function()
            local navic = require("nvim-navic")
            navic.setup({
                lsp = { auto_attach = true },
                icons = {
                    File = '',
                    Module = '',
                    Namespace = '',
                    Package = '',
                    Class = '',
                    Method = '',
                    Property = '',
                    Field = '',
                    Constructor = '',
                    Enum = '',
                    Interface = '',
                    Function = '',
                    Variable = '',
                    Constant = '',
                    String = '',
                    Number = '',
                    Boolean = '',
                    Array = '',
                    Object = '',
                    Key = '',
                    Null = '',
                    EnumMember = '',
                    Struct = '',
                    Event = '',
                    Operator = '',
                    TypeParameter = '',
                }
            })
            -- vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
        end
    }

    -- {
    --     'MeanderingProgrammer/render-markdown.nvim',
    --     opts = {},
    -- },
})
