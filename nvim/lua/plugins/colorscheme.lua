return {
  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanso").setup({
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = {},
        typeStyle = {},
        transparent = false,
        dimInactive = false,
        terminalColors = true,
        colors = {
          palette = {},
          theme = { zen = {}, pearl = {}, ink = {}, all = {} },
        },
        overrides = function(colors)
          return {}
        end,
        background = {
          dark = "zen", -- Use zen theme for dark mode
          light = "zen" -- Use zen theme for light mode
        },
      })
      -- @REVIEW: Load zen variant directly using kanso's load function
      require("kanso").load("zen")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanso",
    },
  },
}
