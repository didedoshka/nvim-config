return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "hrsh7th/cmp-path", commit = "d83839a" },
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets"
  },


  config = function()
    capabilities = require("cmp_nvim_lsp").default_capabilities() -- yes, it is global variable used in lua/lspconfig.lua

    require("luasnip.loaders.from_vscode").lazy_load()

    local cmp = require("cmp")
    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
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
      }
    })
  end
}
