return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "hrsh7th/cmp-path",  commit = "d83839a" },
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
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

    },


    config = function()
        capabilities = require("cmp_nvim_lsp").default_capabilities() -- yes, it is global variable used in lua/lspconfig.lua

        local ls = require("luasnip")

        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load()

        -- vim.keymap.set({ "i" }, "<CR>", function() ls.expand() end, { silent = true })
        vim.keymap.set({ "i", "s" }, " ",
            function()
                if ls.locally_jumpable(1) then
                    ls.jump(1)
                else
                    vim.api.nvim_put({ " " }, "", false, true)
                    print(10)
                end
            end
        )

        local cmp = require("cmp")
        cmp.setup({
            snippet = {
                expand = function(args)
                    ls.lsp_expand(args.body)
                end,
            },

            window = {
                -- completion = cmp.config.window.bordered(),
                -- documentation = cmp.config.window.bordered(),
            },

            mapping = cmp.mapping.preset.insert({
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
            }),

            sources = {
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "path" },
                { name = "buffer" },
            }
        })
    end
}
