return {
  "m4xshen/autoclose.nvim",
  event = "BufEnter",
  config = function()
    require("autoclose").setup{}
  end,
}
