require "nvchad.options"
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true
-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

vim.opt.scrolloff = 30
vim.opt.relativenumber = true -- Enable relative number
vim.opt.number = true         -- Also show the current line number
vim.opt.expandtab = true      -- Convert tabs to spaces
vim.opt.smartindent = true    -- Enable smart indentation
vim.opt.shiftwidth = 2        -- Number of spaces for each indentation level
vim.opt.tabstop = 2           -- Number of spaces a tab counts for
vim.opt.softtabstop = 2       -- Number of spaces a tab key inserts

vim.opt.list = true
vim.opt.listchars:append("space:.")

vim.diagnostic.config({
  virtual_text = true,     -- Show inline diagnostics
  signs = true,            -- Show signs in the gutter
  underline = true,        -- Underline the diagnostic text
  update_in_insert = true, -- Update diagnostics in insert mode
  severity_sort = true,    -- Sort diagnostics by severity
})

vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false


vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.timeoutlen = 250
vim.opt.showmatch = true
vim.opt.synmaxcol = 300 -- stop syntax highlighting for performance
vim.opt.laststatus = 2 -- always show statusline

vim.opt.numberwidth = 1
vim.opt.showcmd = true
vim.opt.cmdheight = 0

-- Search
vim.o.incsearch = true -- starts searching as soon as typing, without enter needed
vim.o.ignorecase = true -- ignore letter case when searching
vim.o.smartcase = true -- case insentive unless capitals used in searcher

vim.opt.updatetime = 50
-- vim.opt.colorcolumn = "120"

vim.treesitter.language.register("angular", "angular.html")

vim.o.foldcolumn = "1" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true


vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = true,  -- This ensures diagnostics are updated while typing
  }
)
