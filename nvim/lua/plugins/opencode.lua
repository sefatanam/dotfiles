return {
  "nickjvandyke/opencode.nvim",
  lazy = true,
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {}

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above
    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
  end,
}
