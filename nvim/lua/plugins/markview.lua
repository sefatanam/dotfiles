-- For `plugins/markview.lua` users.
return {
  "OXY2DEV/markview.nvim",
  lazy = false,
  config = function()
    require("markview").setup()
  end,
}
