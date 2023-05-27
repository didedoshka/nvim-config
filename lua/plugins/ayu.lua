return
{
  "Shatur/neovim-ayu",
  config = function()
    local colors = require("ayu.colors")
    colors.generate()
    require("ayu").setup {
      overrides = function()
        return { LineNr = { fg = colors.comment } }
      end
    }
    require("ayu").colorscheme()
  end,
}
