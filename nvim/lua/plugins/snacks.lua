return {
  "folke/snacks.nvim",
  opts = {
    image        = { enabled = true, force = false, env = { SNACKS_GHOSTTY = true } },
    scroll       = { enabled = false }, -- scroll animation causes lag on large files
    statuscolumn = { enabled = false }, -- redraws on every scroll
    animate      = { enabled = false }, -- stops all snacks animations
    indent       = { enabled = false }, -- indent guides redraw on every scroll
    bigfile      = { enabled = true, size = 1.5 * 1024 * 1024, notify = true },
    explorer     = {
      open = true,
      follow = true,
    },
    picker       = {
      enabled = true,
      win = {
        input = {
          keys = {
            ["<a-o>"] = { "opencode_send", mode = { "n", "i" } },
          },
        },
      },
      sources = {
        explorer = {
          layout = {
            layout = { position = "right" },
          },
        },
      },
    },
  },
  actions = {
    opencode_send = function(picker) ---@param picker snacks.Picker
      local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
        return item.file
            and require("opencode").format({ path = item.file, from = item.pos, to = item.end_pos })
            or item.text
      end, picker:selected({ fallback = true }))

      require("opencode").prompt(table.concat(items, ", ") .. " ")
    end,
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
