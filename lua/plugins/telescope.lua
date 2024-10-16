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
    },

    config = function()
        pcall(require('telescope').load_extension, 'fzf')

        require('telescope').setup {
            defaults = {
                layout_strategy = 'vertical',
                borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' }
            },
        }
        vim.keymap.set('n', '<leader>b', require('telescope.builtin').buffers, { desc = "look at open (b)uffers" })
        vim.keymap.set('n', '<leader>o', require('telescope.builtin').find_files, { desc = "(o)pen file" })
        vim.keymap.set('n', '<leader>h', require('telescope.builtin').live_grep,
            { desc = "grep in files. (h) is near f-find and g-grep" })
        vim.keymap.set('n', '<leader>g', require('telescope.builtin').current_buffer_fuzzy_find,
            { desc = "(g)rep current buffer" })
        vim.keymap.set('n', '<leader>s', require('telescope.builtin').lsp_document_symbols,
            { desc = "lsp document (s)ymbols" })
    end
}
