return
{
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
        },
        'nvim-telescope/telescope-ui-select.nvim',
    },

    config = function()
        pcall(require('telescope').load_extension, 'fzf')

        require('telescope').setup {
            defaults = {
                layout_strategy = 'vertical',
                borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' }
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown {
                        -- even more opts
                    }

                    -- pseudo code / specification for writing custom displays, like the one
                    -- for "codeactions"
                    -- specific_opts = {
                    --   [kind] = {
                    --     make_indexed = function(items) -> indexed_items, width,
                    --     make_displayer = function(widths) -> displayer
                    --     make_display = function(displayer) -> function(e)
                    --     make_ordinal = function(e) -> string
                    --   },
                    --   -- for example to disable the custom builtin "codeactions" display
                    --      do the following
                    --   codeactions = false,
                    -- }
                }
            },
        }

        require("telescope").load_extension("ui-select")

        vim.keymap.set('n', '<leader>b', require('telescope.builtin').buffers, { desc = "look at open (b)uffers" })
        vim.keymap.set('n', '<leader>o', function()
                require('telescope.builtin').find_files({ no_ignore = true })
            end,
            { desc = "(o)pen file (current working directory)" })

        vim.keymap.set('n', '<leader>e', function()
            require('telescope.builtin').find_files({ cwd = require('telescope.utils').buffer_dir(), no_ignore = true })
        end, { desc = "open file (current file's directory)" })

        vim.keymap.set('n', '<leader>h', require('telescope.builtin').live_grep,
            { desc = "grep in files. (h) is near f-find and g-grep" })
        vim.keymap.set('n', '<leader>g', require('telescope.builtin').current_buffer_fuzzy_find,
            { desc = "(g)rep current buffer" })
        vim.keymap.set('n', '<leader>s', require('telescope.builtin').lsp_document_symbols,
            { desc = "lsp document (s)ymbols" })
        vim.keymap.set('n', '<leader>t', require('telescope.builtin').help_tags,
            { desc = "neovim help" })
    end
}
