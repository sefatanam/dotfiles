return {
  "l3aro/omp.nvim",
  version = "*", -- Latest stable release
  dependencies = { "folke/snacks.nvim" },
  -- Disable the default <leader>oa maps; init runs before the plugin loads
  init = function()
    vim.g.omp_nvim_no_keymaps = true
  end,
  keys = {
    -- omp itself is a separate process; this plugin only bridges to an
    -- already-running instance, so open it in a terminal first.
    {
      "<leader>oo",
      function()
        Snacks.terminal({ "omp" }, { cwd = LazyVim.root() })
      end,
      desc = "omp: open (Root Dir)",
    },
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
