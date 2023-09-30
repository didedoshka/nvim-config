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
vim.opt.clipboard = "unnamedplus"

-- set wrap and max text width
vim.opt.wrap = false
vim.opt.colorcolumn = "120"

-- set extensions
vim.filetype.add({ extension = { ["keymap"] = "cpp" } })

-- set russian
vim.opt.keymap = "russian-yasherty"
vim.opt.iminsert = 0


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

-- setting plugins
require("lazy").setup(
-- table of plugins
    {
        -- colorscheme
        require("plugins.ayu"),

        -- flit
        require("plugins.flit"),

        -- telescope
        require("plugins.telescope"),

        -- filetree
        require("plugins.nerdtree"),

        -- cmp
        require("plugins.cmp"),

        -- treesitter
        require("plugins.treesitter"),

        -- lspconfig
        require("plugins.lspconfig"),

        {
            "jose-elias-alvarez/null-ls.nvim",
            config = function()
                require("null-ls").setup({
                    sources = require("null-ls").builtins.formatting.autopep8.with({
                        extra_args = { "--max-line-length", "119" }
                    })
                })
            end,
            dependencies = { "nvim-lua/plenary.nvim" }
        },
        -- comment
        require("plugins.comment"),

        -- lazygit
        require("plugins.lazygit")
    }

)
