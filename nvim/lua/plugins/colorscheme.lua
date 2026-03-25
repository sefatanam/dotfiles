return {
  {
    "ydkulks/cursor-dark.nvim",
    lazy = true,
    config = function()
      -- vim.cmd.colorscheme("cursor-dark-midnight")
      require("cursor-dark").setup({
        -- For theme
        style = "dark-midnight",
        -- For a transparent background
        -- transparent = true,
        -- If you have dashboard-nvim plugin installed
        dashboard = true,
      })
    end,
  },
  {
    "dgox16/oldworld.nvim",
    lazy = true,
  },
  {
    "webhooked/kanso.nvim",
    lazy = true,
    config = function()
      require("kanso").setup({
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = {},
        typeStyle = {},
        -- transparent = true,
        -- dimInactive = false,
        terminalColors = true,
        -- styles = {
        --   sidebars = "transparent",
        --   floats = "transparent",
        -- },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
    -- config = function()
    --   require('nightfox').setup({
    --     options = {
    --       transparent = true
    --     }
    --   })
    -- end
  },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "metalelf0/black-metal-theme-neovim", lazy = true },
  { "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
  { "sainnhe/everforest", lazy = true },
  { "olimorris/onedarkpro.nvim", lazy = true },
  { "olivercederborg/poimandres.nvim", lazy = true },
  {
    "rockyzhang24/arctic.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    name = "arctic",
    branch = "main",
    lazy = true,
  },
  { "Yazeed1s/oh-lucy.nvim", lazy = true },
  -- {
  --   'projekt0n/github-nvim-theme',
  --   name = 'github-theme',
  --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require('github-theme').setup({
  --       options = {
  --         transparent = true
  --       }
  --     })
  --
  --   end,
  -- },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "kanso-zen",
      -- colorscheme = "Terafox",
      colorscheme = "gruvbox-material",
      -- colorscheme = "everforest",
    },
  },
}
