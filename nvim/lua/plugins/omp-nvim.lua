return {
  "l3aro/omp.nvim",
  version = "*", -- Latest stable release
  -- Disable the default <leader>oa maps; init runs before the plugin loads
  init = function()
    vim.g.omp_nvim_no_keymaps = true
  end,
  keys = {
    { "<leader>oa", "<Cmd>OmpAsk<CR>", desc = "omp: ask" },
    {
      "<leader>oa",
      function()
        require("omp_nvim").ask()
      end,
      mode = "x",
      desc = "omp: ask selection",
    },
    {
      "<leader>oA",
      function()
        require("omp_nvim").ask({ hold = true })
      end,
      desc = "omp: ask (hold)",
    },
    {
      "<leader>oA",
      function()
        require("omp_nvim").ask({ hold = true })
      end,
      mode = "x",
      desc = "omp: ask selection (hold)",
    },
  },
}
