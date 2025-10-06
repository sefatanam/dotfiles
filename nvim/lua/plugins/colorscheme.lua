return {
  {
    "webhooked/kanso.nvim",
    config = function()
      require("kanso").setup({
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = {},
        typeStyle = {},
        transparent = true,
        dimInactive = false,
        terminalColors = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    config = function()
      require('nightfox').setup({
        options = {
          transparent = true
        }
      })
    end
  },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('github-theme').setup({
        options = {
          transparent = true
        }
      })

    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "kanso-zen",
      colorscheme = "Terafox",
    },
  },
}
