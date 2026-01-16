return {
  "b0o/incline.nvim",
  dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
  config = function()
    local helpers = require("incline.helpers")
    local navic = require("nvim-navic")
    local devicons = require("nvim-web-devicons")
    require("incline").setup({
      window = {
        padding = 0,
        margin = { horizontal = 0, vertical = 0 },
      },
      -- @REVIEW: Debounce to reduce render frequency
      debounce_threshold = {
        falling = 50,
        rising = 10,
      },
      render = function(props)
        -- @REVIEW: Skip rendering for large files
        if vim.b[props.buf] and vim.b[props.buf].large_file then
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          return { " ", filename, " ", guibg = "#44406e" }
        end

        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then
          filename = "[No Name]"
        end
        local ft_icon, ft_color = devicons.get_icon_color(filename)
        local modified = vim.bo[props.buf].modified
        local res = {
          ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
          " ",
          { filename, gui = modified and "bold,italic" or "bold" },
          guibg = "#44406e",
        }
        -- @REVIEW: Only show navic breadcrumbs when focused (reduces LSP queries)
        if props.focused then
          local navic_data = navic.get_data(props.buf)
          -- @REVIEW: Limit breadcrumb depth for performance
          if navic_data then
            local max_items = 3
            local start_idx = math.max(1, #navic_data - max_items + 1)
            for i = start_idx, #navic_data do
              local item = navic_data[i]
              table.insert(res, {
                { " > ", group = "NavicSeparator" },
                { item.icon, group = "NavicIcons" .. item.type },
                { item.name, group = "NavicText" },
              })
            end
          end
        end
        table.insert(res, " ")
        return res
      end,
    })
  end,
  -- Optional: Lazy load Incline
  event = "VeryLazy",
}
