return {
  "colomb8/rambo.nvim",
  event = "VeryLazy",
  config = function()
    require("rambo").setup({
      -- c_right_mode = 'bow', -- 'bow' or 'eow'
      -- op_prefix = '', -- '' or '<C-q>' or '<C-g>'
      -- hl_select_spec = { -- hl_spec or false
      --   bg = '#732BF5', -- Neon Violet
      -- },
    })
  end,
}
