return {
  "folke/snacks.nvim",
  opts = {
    image       = { enabled = true, force = false, env = { SNACKS_GHOSTTY = true } },
    scroll      = { enabled = false },      -- scroll animation causes lag on large files
    statuscolumn= { enabled = false },      -- redraws on every scroll
    animate     = { enabled = false },      -- stops all snacks animations
    indent      = { enabled = false },      -- indent guides redraw on every scroll
    bigfile     = { enabled = true, size = 1.5 * 1024 * 1024, notify = true },
    explorer = {
      open = true,
      follow = true,
    },
    picker = {
      sources = {
        explorer = {
          layout = {
            layout = { position = "right" },
          },
        },
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    vim.ui.select = require("snacks").picker.select
  end,
  keys = {
    {
      "<C-n>",
      function()
        local p = Snacks.picker.get({ source = "explorer" })[1]
        if p == nil then
          Snacks.picker.explorer()
        elseif p:is_focused() then
          Snacks.picker.explorer()
        else
          p:focus()
        end
      end,
    },
    {
      "<leader>e",
      function()
        local explorer_pickers = Snacks.picker.get({ source = "explorer" })
        for _, v in pairs(explorer_pickers) do
          if v:is_focused() then
            v:close()
          else
            v:focus()
          end
        end
        if #explorer_pickers == 0 then
          Snacks.picker.explorer()
        end
      end,
    },
  },
}
