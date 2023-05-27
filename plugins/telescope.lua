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

    -- telescope recent
    vim.keymap.set('n', '<leader>sr', require('telescope.builtin').oldfiles)
    -- telescope buffers
    vim.keymap.set('n', '<leader>sb', require('telescope.builtin').buffers)
    -- telescope project files
    vim.keymap.set('n', '<leader>sp', require('telescope.builtin').find_files)
    -- telescope by grep
    vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep)
  end
}
