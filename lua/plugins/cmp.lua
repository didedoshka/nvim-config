return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "hrsh7th/cmp-path",  commit = "d83839a" },
        {
            "L3MON4D3/LuaSnip",
            -- config = function()
            --     require("luasnip").setup({ delete_check_events = { "TextChanged" } })
            -- end,
        },
        "saadparwaiz1/cmp_luasnip",
        -- "rafamadriz/friendly-snippets",
        {
            "windwp/nvim-autopairs",
            opts = {
                fast_wrap = {},
                disable_filetype = { "TelescopePrompt", "vim" },
            },
            config = function(_, opts)
                require("nvim-autopairs").setup(opts)

                local cmp_autopairs = require "nvim-autopairs.completion.cmp"
                -- local function a()
                --     return function(evt)
                --         print(dump(evt))
                --         local entry = evt.entry
                --         local commit_character = entry:get_commit_characters()
                --         print(dump(commit_character))
                --     end
                -- end
                -- require("cmp").event:on("confirm_done", a())
                require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
            end,
        },
        { "hrsh7th/cmp-buffer" },

    },

    config = function()
        local luasnip = require("luasnip")
        local cmp = require("cmp")

        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load()

        cmp.setup({
            snippet = {
                expand = function(args)
                    -- print(dump(args))
                    vim.api.nvim_paste(args.body, false, -1)
                    -- luasnip.lsp_expand(args.body)
                end,
            },

            window = {
                completion = { winhighlight = "Normal:NormalFloat", border = "single" },
                documentation = { winhighlight = "Normal:NormalFloat", border = "single" },
            },

            mapping = cmp.mapping.preset.insert({
                ['<CR>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.confirm({
                            select = true,
                        })
                    else
                        fallback()
                    end
                end),

                ["<Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(1) then
                        luasnip.jump(1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),

                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),

            -- mapping = cmp.mapping.preset.insert({
            --     ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            --     ["<C-f>"] = cmp.mapping.scroll_docs(4),
            --     ["<C-e>"] = cmp.mapping.abort(),
            --     ["<CR>"] = cmp.mapping.confirm({ select = true }),
            -- }),

            sources = {
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "path" },
                { name = "buffer" },
            },

            experimental = { ghost_text = true },
        })
    end
}
