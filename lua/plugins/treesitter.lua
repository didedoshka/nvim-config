return
{
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()

        local interesting_objects = {
            "@class.outer",
            "@conditional.outer",
            "@function.outer",
            "@loop.outer",
            "@return.outer",
        }

        require('nvim-treesitter.configs').setup({
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<leader>m",
                    node_incremental = "<leader>m",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
            textobjects = {
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        ["<cr>"] = {
                            query = interesting_objects
                        },
                    },
                    goto_previous_start = {
                        ["<bs>"] = {
                            query = interesting_objects
                        }
                    },
                },
            },
        })
    end
}
