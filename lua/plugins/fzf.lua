return
{
    "ibhagwan/fzf-lua",
    config = function()
        local fzf_lua = require("fzf-lua")
        fzf_lua.setup({
            "ivy",
            fzf_colors = { true },
            hls = {
                -- normal         = "Normal",
                -- border         = "Normal",
                -- title          = "Normal",
                -- title_flags    = "Normal",
                -- backdrop       = "Normal",
                -- preview_normal = "Normal",
                -- preview_border = "Normal",
                -- preview_title  = "Normal",
                -- cursor         = "Normal",
                -- editor CursorLine is subtle; the picker's selected line keeps the old loud look
                cursorline     = "CurSearch",
                -- cursorlinenr   = "Normal",
                -- search         = "Normal",
                -- scrollborder_e = "Normal",
                -- scrollborder_f = "Normal",
                -- scrollfloat_e  = "Normal",
                -- scrollfloat_f  = "Normal",
                -- help_normal    = "Normal",
                -- help_border    = "Normal",
                header_bind    = "Normal",
                header_text    = "Normal",
                path_colnr     = "Normal",
                path_linenr    = "Normal",
                buf_name       = "Normal",
                buf_id         = "Normal",
                buf_nr         = "Normal",
                buf_linenr     = "Normal",
                buf_flag_cur   = "Normal",
                buf_flag_alt   = "Normal",
                -- tab_title      = "Normal",
                -- tab_marker     = "Normal",
                -- dir_icon       = "Normal",
                -- dir_part       = "Normal",
                -- file_part      = "Normal",
                -- live_prompt    = "Normal",
                -- live_sym       = "Normal",
                -- cmd_ex         = "Normal",
                -- cmd_buf        = "Normal",
                -- cmd_global     = "Normal",
                fzf            = {
                    -- normal = "Normal",
                    -- cursorline = "CurSearch",
                    -- match = "Normal",
                    -- border = "Normal",
                    -- scrollbar = "Normal",
                    -- separator = "Normal",
                    gutter = "CurSearch",
                    -- header = "Normal",
                    -- info = "Normal",
                    -- pointer = "CurSearch",
                    -- marker = "Normal",
                    -- spinner = "Normal",
                    -- prompt = "Normal",
                    -- query = "Normal",
                }
            },
            grep = {
                multiline = 1,
            },
            -- ctrl-q dumps every result to a new quickfix list, from any picker.
            -- The prefix must not contain "accept": fzf-lua runs the action through
            -- execute-silent, and accept would close fzf before it ran (measured:
            -- "unsupported action: <first entry>", empty quickfix).
            -- [1] = true keeps the default actions: without it this table
            -- replaces them wholesale (config.lua build_bind_tables).
            actions = {
                files = {
                    [1] = true,
                    ["ctrl-q"] = {
                        fn = require("fzf-lua.actions").file_sel_to_qf,
                        prefix = "select-all",
                    },
                },
                buffers = {
                    [1] = true,
                    ["ctrl-q"] = {
                        fn = require("fzf-lua.actions").buf_sel_to_qf,
                        prefix = "select-all",
                    },
                },
            },
        })

        fzf_lua.register_ui_select()

        -- With a .workspace (lua/workspace.lua) the picker searches its directories
        -- from its root instead of the cwd; entries then read yt/yt/..., library/cpp/...
        -- <C-f> inside the picker reopens it in the current buffer's directory,
        -- keeping the typed query (ported from the old telescope config).
        -- The buffer dir is captured at launch: inside the action the current
        -- buffer is no longer the one the picker was opened from.
        local function with_buffer_dir(picker)
            return function()
                local dir = vim.fn.expand('%:h')
                if dir == '' then dir = '.' end
                local ws = require('workspace').find()
                picker({
                    cwd = ws and ws.root,
                    -- an empty .workspace means the root itself: {} makes rg search nothing
                    search_paths = ws and #ws.dirs > 0 and ws.dirs or nil,
                    keymap = { fzf = { ['ctrl-f'] = false } }, -- default is preview-page-down
                    actions = {
                        ['ctrl-f'] = function(_, opts)
                            picker({ cwd = dir, no_ignore = true, query = opts.last_query })
                        end,
                    },
                })
            end
        end

        vim.keymap.set('n', '<leader>o',
            with_buffer_dir(fzf_lua.files),
            { desc = '(o)pen file' }
        )

        vim.keymap.set('n', '<leader>h',
            with_buffer_dir(fzf_lua.live_grep),
            { desc = 'grep in files' }
        )

        -- vim.keymap.set('n', '<leader>s', function()
        --     local default = vim.fn.expand('%:h')
        --     if default == '' then default = '.' end
        --     vim.ui.input({ prompt = 'grep dir: ', default = default, completion = 'dir' }, function(dir)
        --         if dir and dir ~= '' then
        --             fzf_lua.live_grep({ cwd = dir })
        --         end
        --     end)
        -- end, { desc = '(s)earch in directory' })


        vim.keymap.set('n', '<leader>p',
            fzf_lua.helptags,
            { desc = 'neovim help' }
        )
    end
}
