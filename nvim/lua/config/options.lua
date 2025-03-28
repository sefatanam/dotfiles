-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.winbar = "%=%m %f"

vim.opt.scrolloff = 30
vim.opt.relativenumber = true -- Enable relative number
vim.opt.number = true -- Also show the current line number
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.shiftwidth = 2 -- Number of spaces for each indentation level
vim.opt.tabstop = 2 -- Number of spaces a tab counts for
vim.opt.softtabstop = 2 -- Number of spaces a tab key inserts
vim.opt.list = true
vim.opt.listchars:append("space:.")
-- Set to false to disable auto format
vim.g.lazyvim_eslint_auto_format = false
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"