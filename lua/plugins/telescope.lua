return
{
    'nvim-telescope/telescope.nvim',
    tag = 'v0.1.9',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
        },
        'nvim-telescope/telescope-ui-select.nvim',
        'segoon/telescope-arcadia-codesearch.nvim',
    },

    config = function()
        local telescope = require('telescope')
        local builtin = require('telescope.builtin')
        local themes = require('telescope.themes')
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        local utils = require('telescope.utils')

        local function buffer_dir()
            return utils.buffer_dir()
        end

        local function reopen_in_buffer_dir(picker_fn, opts)
            opts = opts or {}

            return function(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local prompt = picker:_get_prompt()

                actions.close(prompt_bufnr)

                picker_fn(vim.tbl_extend('force', opts, {
                    cwd = buffer_dir(),
                    no_ignore = true,
                    default_text = prompt,
                }))
            end
        end

        local function picker_with_buffer_dir_mapping(picker_fn, opts)
            opts = opts or {}

            return function(extra_opts)
                extra_opts = extra_opts or {}

                local final_opts = vim.tbl_extend('force', opts, extra_opts)

                picker_fn(vim.tbl_extend('force', final_opts, {
                    attach_mappings = function(_, map)
                        map({ 'i', 'n' }, '<C-f>', reopen_in_buffer_dir(picker_fn, final_opts))

                        return true
                    end,
                }))
            end
        end

        local find_files = picker_with_buffer_dir_mapping(builtin.find_files, {
            no_ignore = true,
        })

        local live_grep = picker_with_buffer_dir_mapping(builtin.live_grep, {
            no_ignore = true,
        })

        telescope.setup {
            defaults = {
                layout_strategy = 'vertical',
                borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
            },
            extensions = {
                ['ui-select'] = {
                    themes.get_dropdown {},
                },
            },
        }

        pcall(telescope.load_extension, 'fzf')
        pcall(telescope.load_extension, 'ui-select')
        pcall(telescope.load_extension, 'textcase')
        pcall(telescope.load_extension, 'arcadia_cs')

        vim.keymap.set(
            'n',
            '<leader>b',
            builtin.buffers,
            { desc = 'look at open (b)uffers' }
        )

        vim.keymap.set(
            'n',
            '<leader>o',
            find_files,
            { desc = '(o)pen file' }
        )

        vim.keymap.set(
            'n',
            '<leader>h',
            live_grep,
            { desc = 'grep in files' }
        )

        vim.keymap.set(
            'v',
            '<leader>h',
            function()
                live_grep({
                    default_text = vim.fn.expand('<cword>'),
                })
            end,
            { desc = 'grep selected/current word in files' }
        )

        vim.keymap.set(
            'n',
            '<leader>g',
            builtin.current_buffer_fuzzy_find,
            { desc = '(g)rep current buffer' }
        )

        vim.keymap.set(
            'n',
            '<leader>p',
            builtin.help_tags,
            { desc = 'neovim help' }
        )

        vim.keymap.set(
            'v',
            '<leader>p',
            function()
                builtin.help_tags({
                    default_text = vim.fn.expand('<cword>'),
                })
            end,
            { desc = 'neovim help' }
        )

        vim.keymap.set(
            'n',
            '<leader>m',
            function()
                telescope.extensions.arcadia_cs.arcadia_cs({ root = 1 })
            end,
            { desc = 'arcadia code search' }
        )
    end,
}
