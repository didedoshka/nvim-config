return
{
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()

        require 'nvim-treesitter.configs'.setup {
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            }
        }
    end
}
