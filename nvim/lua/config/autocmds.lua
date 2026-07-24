-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("DisableConceal", { clear = true }),
  pattern = { "json", "jsonc", "markdown" },
  callback = function()
    vim.wo.conceallevel = 0
  end,
})

-- Automatically disable heavy features for large files
-- NOTE: Adjust these thresholds based on your machine's performance
--   - Lower values (500 lines / 50KB) = more aggressive, better for slow machines
--   - Higher values (2000 lines / 500KB) = less aggressive, keeps more features
vim.g.large_file_threshold_lines = 1500
vim.g.large_file_threshold_bytes = 100 * 1024 -- 100KB

local large_file_group = vim.api.nvim_create_augroup("LargeFileOptimization", { clear = true })

vim.api.nvim_create_autocmd("BufReadPre", {
  group = large_file_group,
  callback = function(args)
    local file_size = vim.fn.getfsize(args.file)
    if file_size > vim.g.large_file_threshold_bytes or file_size == -2 then
      vim.b.large_file = true
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = large_file_group,
  callback = function(args)
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if line_count > vim.g.large_file_threshold_lines then
      vim.b.large_file = true
    end

    if vim.b.large_file then
      -- Disable expensive features for large files
      vim.opt_local.relativenumber = false
      vim.opt_local.cursorline = false
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      vim.opt_local.list = false -- Disable listchars (space dots, etc.)

      -- Disable treesitter highlighting for very large files
      if line_count > 2000 then
        vim.cmd("TSBufDisable highlight")
        vim.cmd("TSBufDisable indent")
      end

      -- Disable treesitter-context
      local ok, ts_context = pcall(require, "treesitter-context")
      if ok then
        ts_context.disable()
      end

      -- Disable nvim-ufo folding
      local ufo_ok, ufo = pcall(require, "ufo")
      if ufo_ok then
        ufo.detach()
      end

      -- Disable incline breadcrumbs
      local incline_ok, incline = pcall(require, "incline")
      if incline_ok then
        incline.disable()
      end

      vim.notify("Large file detected: Performance mode enabled", vim.log.levels.INFO)
    end
  end,
})

-- vim.api.nvim_create_autocmd("BufReadPost", {
--   group = vim.api.nvim_create_augroup("RestoreCursor", { clear = true }),
--   callback = function()
--     local mark = vim.api.nvim_buf_get_mark(0, '"')
--     if mark[1] > 0 then vim.api.nvim_win_set_cursor(0, mark) end
--   end,
-- })


