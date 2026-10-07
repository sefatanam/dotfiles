return {
  -- { "ydkulks/cursor-dark.nvim", lazy = true, },
  -- { 'marko-cerovac/material.nvim',     lazy = true },
  -- { "sainnhe/gruvbox-material",        lazy = true },
  -- { "olivercederborg/poimandres.nvim", lazy = true },
  -- { "lourenci/github-colors",          lazy = true },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    -- Transparent mode: follows the `transparency` command (config/transparency.lua).
    opts = function()
      local transparency = require("config.transparency")
      return transparency.rose_pine_opts(transparency.enabled())
    end,
    config = function(_, opts)
      require("rose-pine").setup(opts)
      require("config.transparency").setup()
    end,
  },
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
}
