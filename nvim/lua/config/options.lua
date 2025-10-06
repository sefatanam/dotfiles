-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Display while file path include file name in the winbar
--
-- vim.opt.winbar = "%=%m %f"
vim.opt.sidescrolloff = 5
vim.opt.scrolloff = 5
vim.opt.relativenumber = true -- Enable relative number
vim.opt.number = true -- Also show the current line number
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.shiftwidth = 2 -- Number of spaces for each indentation level
vim.opt.tabstop = 2 -- Number of spaces a tab counts for
vim.opt.softtabstop = 2 -- Number of spaces a tab key inserts
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "•",
  nbsp = "␣",
}

vim.opt.updatetime = 100
vim.opt.timeoutlen = 300
vim.opt.synmaxcol = 250
vim.opt.smartindent = true
vim.opt.termguicolors = true -- Enable 24-bit RGB colors
vim.opt.signcolumn = "yes"

vim.opt.listchars:append("space:.")
-- Set to false to disable auto format
vim.g.lazyvim_eslint_auto_format = false
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
-- vim.g.snacks_animate = false

vim.o.viewoptions = "cursor,slash,unix" -- remove 'folds' from view options
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.g.autoformat = false

-- Wrapping / Scrolling
vim.opt.wrap = true -- No line wrapping
vim.opt.scrolloff = 8 -- Keep context lines when scrolling
vim.opt.sidescrolloff = 8


-- Completion
vim.opt.completeopt = { "menuone", "noselect" }
vim.opt.shortmess:append("c")
vim.opt.pumheight = 10

