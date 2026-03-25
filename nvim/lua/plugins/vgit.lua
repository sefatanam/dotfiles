return {
  "tanvirtin/vgit.nvim",
  branch = "v1.0.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = { "VGit" },
  keys = {
    { "<leader>ggd", function() require("vgit").project_diff_preview() end, desc = "VGit project diff" },
  },
  config = function()
    require("vgit").setup({})
  end,
}
