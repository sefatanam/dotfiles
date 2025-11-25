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
            persist = true, -- very efficient mechanism to Remember selected colorscheme
            write_shada = false, -- If you open multiple nvim instances, then probably you need to enable this
          },
        },
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
