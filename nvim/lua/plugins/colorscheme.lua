return {
  {
    "ydkulks/cursor-dark.nvim",
    lazy = true,
    config = function()
      require("cursor-dark").setup({
        style = "dark-midnight",
        -- For a transparent background
        -- transparent = true,
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
  { 'marko-cerovac/material.nvim',     lazy = true },
  { "sainnhe/gruvbox-material",        lazy = true },
  { "olivercederborg/poimandres.nvim", lazy = true },
  { "lourenci/github-colors",          lazy = true },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "github-colors",
      colorscheme = "gruvbox-material",
    },
  },
}
