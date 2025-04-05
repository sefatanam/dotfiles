return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      open = true,
      follow = true,
    },
    -- picker = {
    --   sources = {
    --     explorer = {
    --       layout = {
    --         -- layout = { position = "left" },
    --       },
    --     },
    --   },
    -- },
  },
  keys = {
    {
      "<C-n>",
      function()
        Snacks.explorer()
      end,
    },
  },
}
