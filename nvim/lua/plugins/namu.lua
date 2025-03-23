return {
  {
    "bassamsdata/namu.nvim",
    lazy = false,
    config = function()
      require("namu").setup({
        namu_symbols = {
          enable = true,
          options = {}, -- here you can configure namu
        },
        colorscheme = {
          enable = false,
          options = {
            -- NOTE: if you activate persist, then please remove any vim.cmd("colorscheme ...") in your config, no needed anymore
            persist = true, -- very efficient mechanism to Remember selected colorscheme
            write_shada = false, -- If you open multiple nvim instances, then probably you need to enable this
          },
        },
        ui_select = { enable = true }, -- vim.ui.select() wrapper
      })

      vim.keymap.set("n", "<leader>ns", ":Namu symbols<cr>", {
        desc = "Jump to LSP symbol",
        silent = true,
      })

      vim.keymap.set("n", "<leader>th", ":Namu colorscheme<cr>", {
        desc = "Colorscheme Picker",
        silent = true,
      })
    end,
  },
}
