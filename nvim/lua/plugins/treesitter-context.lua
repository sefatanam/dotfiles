-- @REVIEW: Treesitter context optimization for large files
return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = {
    -- @REVIEW: Reduced max_lines for better performance
    max_lines = 3,
    -- @REVIEW: Trim to min lines for snappier feel
    min_window_height = 0,
    -- @REVIEW: Disable for large files
    on_attach = function(buf)
      local line_count = vim.api.nvim_buf_line_count(buf)
      -- Disable context for files > 500 lines
      return line_count <= 500
    end,
  },
}
