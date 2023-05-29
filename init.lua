-- Created by didedoshka on May 24

-- setting leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- setting indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- setting number
vim.opt.number = true
vim.opt.relativenumber = true

-- command line only visible in command mode
-- vim.opt.cmdheight = 0

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

    -- comment
    require("plugins.comment"),

    -- lazygit
    require("plugins.lazygit")
  }

)
