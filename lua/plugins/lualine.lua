return {
    "nvim-lualine/lualine.nvim",
    config = function()
        -- 1. Track live LSP progress ourselves. Neovim only exposes the active
        --    percentage in the LspProgress event payload (client.progress.pending
        --    stores just the title string), so we stash it per client+token.
        --    progress[client_id][token] = <number> | true (no percent) | "done"
        local progress = {}

        vim.api.nvim_create_augroup("LualineLspProgress", { clear = true })
        vim.api.nvim_create_autocmd("LspProgress", {
            group = "LualineLspProgress",
            callback = function(args)
                local id = args.data.client_id
                local params = args.data.params
                local token = params.token
                local value = params.value

                progress[id] = progress[id] or {}
                if value.kind == "end" then
                    -- Show "ok!" briefly when a task finishes, then fade to idle
                    progress[id][token] = "done"
                    vim.defer_fn(function()
                        if progress[id] and progress[id][token] == "done" then
                            progress[id][token] = nil
                            require("lualine").refresh()
                        end
                    end, 2000)
                else -- "begin" or "report"
                    progress[id][token] = value.percentage or true
                end

                require("lualine").refresh()
            end,
        })

        -- 2. The Lualine formatting function: attached clients + exactly 4
        --    characters of progress each, so the layout never shifts.
        local function lsp_status()
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            if #clients == 0 then
                return ""
            end

            local builder = {}
            for _, client in ipairs(clients) do
                local pct_str = "   " -- 3 spaces when idle

                local tasks = progress[client.id]
                if tasks then
                    -- Priority: active percentage > active load > just-finished
                    local num, loading, done
                    for _, pct in pairs(tasks) do
                        if type(pct) == "number" then
                            num = num or pct
                        elseif pct == "done" then
                            done = true
                        else
                            loading = true
                        end
                    end
                    if num then
                        pct_str = num >= 100 and "ok!" or string.format("%2d%%", num)
                    elseif loading then
                        pct_str = "..." -- loading, no percentage provided
                    elseif done then
                        pct_str = "ok!"
                    end
                end

                local name = client.name:gsub("language.server", "ls")
                table.insert(builder, name .. " " .. pct_str)
            end

            -- Escape '%' so lualine doesn't treat it as a statusline format item
            return (table.concat(builder, " "):gsub("%%", "%%%%"))
        end

        local dmode_enabled = false
        vim.api.nvim_create_autocmd("User", {
            pattern = "DebugModeChanged",
            callback = function(args)
                dmode_enabled = args.data.enabled
                require('lualine').refresh()
            end
        })

        -- local navic = require("nvim-navic")

        require("lualine").setup({
            options = {
                theme = "dide",
                globalstatus = false,
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
            },
            sections = {
                lualine_a = {
                    {
                        "mode",
                        fmt = function(str) return dmode_enabled and "DEBUG" or str end,
                        -- color = function(tb) return dmode_enabled and "dCursor" or tb end,
                    },
                },
                lualine_b = {},
                lualine_c = {
                    { "filename",   path = 1 },
                    { "filetype" },
                    -- { "branch" },
                    -- { "diff" },
                    { "diagnostics" },
                    {},
                },
                lualine_x = {
                    { lsp_status },
                },
                lualine_y = { { "progress" }, { "location" } },
                lualine_z = {},
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
            -- winbar = {
            --     lualine_c = {
            --         "navic",
            --         color_correction = nil,
            --         navic_opts = nil
            --     }
            -- }

        })
    end,
}
