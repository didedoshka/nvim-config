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

        -- search recent
        vim.keymap.set('n', '<leader>sr', require('telescope.builtin').oldfiles)
        -- search buffers
        vim.keymap.set('n', '<leader>sb', require('telescope.builtin').buffers)
        -- search project files
        vim.keymap.set('n', '<leader>o', require('telescope.builtin').find_files)
        -- search by grep
        vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep)
    end
}
