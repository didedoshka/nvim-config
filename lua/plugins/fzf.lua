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
                -- cursorline     = "Normal",
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
        })

        fzf_lua.register_ui_select()

        vim.keymap.set('n', '<leader>b',
            fzf_lua.buffers,
            { desc = 'look at open (b)uffers' }
        )

        vim.keymap.set('n', '<leader>o',
            fzf_lua.files,
            { desc = '(o)pen file' }
        )

        vim.keymap.set('n', '<leader>h',
            fzf_lua.live_grep,
            { desc = 'grep in files' }
        )

        vim.keymap.set('n', '<leader>g',
            fzf_lua.grep_curbuf,
            { desc = '(g)rep current buffer' }
        )

        vim.keymap.set('n', '<leader>p',
            fzf_lua.helptags,
            { desc = 'neovim help' }
        )
    end
}
