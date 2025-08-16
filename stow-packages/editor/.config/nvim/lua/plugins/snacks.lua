return {
  "folke/snacks.nvim",
  opts = {
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
  keys = {
    {
      "<C-n>",
      function()
        if Snacks.picker.get({ source = "explorer" })[1] == nil then
          Snacks.picker.explorer()
        elseif Snacks.picker.get({ source = "explorer" })[1]:is_focused() == true then
          Snacks.picker.explorer()
        elseif Snacks.picker.get({ source = "explorer" })[1]:is_focused() == false then
          Snacks.picker.get({ source = "explorer" })[1]:focus()
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
