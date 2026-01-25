return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = {
    -- Reduced max_lines for better performance
    max_lines = 3,
    -- Trim to min lines for snappier feel
    min_window_height = 0,
    -- Disable for large files (synced with autocmds.lua threshold)
    on_attach = function(buf)
      local line_count = vim.api.nvim_buf_line_count(buf)
      -- Disable context for files > 1500 lines
      return line_count <= 1500
    end,
  },
}
