return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "hrsh7th/cmp-path",           commit = "d83839a" },
        {
            "windwp/nvim-autopairs",
            opts = {
                fast_wrap = {},
                disable_filetype = { "TelescopePrompt", "vim" },
            },
            config = function(_, opts)
                require("nvim-autopairs").setup(opts)

                local cmp_autopairs = require "nvim-autopairs.completion.cmp"
                require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
            end,
        },
        { "hrsh7th/cmp-buffer" },
        { "abeldekat/cmp-mini-snippets" },
        { "hrsh7th/cmp-cmdline" },
    },

    config = function()
        local cmp = require("cmp")
        local gen_loader = require('mini.snippets').gen_loader
        require('mini.snippets').setup({
            snippets = {
                gen_loader.from_lang(),
            },
            mappings = {
                expand = '',
                jump_next = '<C-j>',
                jump_prev = '<C-k>',
                stop = '<C-c>',
            },
        })

        local cmp_mapping = {
            ['<C-n>'] = {
                i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
            },
            ['<C-p>'] = {
                i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
            },
            ['<C-y>'] = {
                i = cmp.mapping.confirm({ select = true }),
                c = cmp.mapping.confirm({ select = true }),
            },
            ['<C-e>'] = {
                i = cmp.mapping.abort(),
                c = cmp.mapping.abort(),
            },
        }

        cmp.setup({
            snippet = {
                expand = function(args)          -- mini.snippets expands snippets from lsp...
                    local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
                    insert({ body = args.body }) -- Insert at cursor
                    cmp.resubscribe({ "TextChangedI", "TextChangedP" })
                    require("cmp.config").set_onetime({ sources = {} })
                end,
            },

            window = {
                completion = { winhighlight = "Normal:NormalFloat", border = "single" },
                documentation = { winhighlight = "Normal:NormalFloat", border = "single" },
            },

            mapping = cmp_mapping,

            sources = {
                { name = "mini_snippets" },
                { name = "nvim_lsp" },
                { name = "path" },
                { name = "buffer" },
            },

            experimental = { ghost_text = true },
        })

        -- cmp.setup.cmdline('/', {
        --     sources = {
        --         { name = 'buffer' }
        --     },
        -- })

        cmp.setup.cmdline(':', {
            mapping = cmp_mapping,
            sources = cmp.config.sources({
                { name = 'path' }
            }, {
                {
                    name = 'cmdline',
                    option = {
                        ignore_cmds = { 'Man', '!' }
                    }
                }
            }),
        })
    end
}
