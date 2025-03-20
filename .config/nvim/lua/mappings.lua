require "nvchad.mappings"

-- add yours here
local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode", unique = true })

map("i", "jk", "<ESC>")

-- TELESCOPE MAPPINGS AND REMOVE DEFAULT LSP KEY BINDINGS

-- Remove the default mapping (if needed)
vim.keymap.del("n", "<leader>ds")
vim.keymap.set("n", "<leader>ds", "<cmd>Telescope diagnostics<CR>", { noremap = true, silent = true,  unique=true, desc = "LSP diagnostics loclist (Telescope)" })

-- Define Telescope overrides
vim.keymap.set("n", "<leader>gd", function()
  require("telescope.builtin").lsp_definitions()
end, { noremap = true, silent = true, desc = "Telescope LSP definitions" })

vim.keymap.set("n", "<leader>gD", function()
  require("telescope.builtin").lsp_declarations()
end, { noremap = true, silent = true, desc = "Telescope LSP declarations" })

vim.keymap.set("n", "<leader>gi", function()
  require("telescope.builtin").lsp_implementations()
end, { noremap = true, silent = true, desc = "Telescope LSP implementations" })

vim.keymap.set("n", "<leader>gr", function()
  require("telescope.builtin").lsp_references()
end, { noremap = true, silent = true, desc = "Telescope LSP references" })

map({ "n", "v" }, "<leader>ghc", "<cmd>Telescope git_commits<CR>", { unique = true, desc = "Commits" })
map({ "n", "v" }, "<leader>ghb", "<cmd>Telescope git_branches<CR>", { unique = true, desc = "Git branch list" })

map({ "n", "v" }, "<leader>ml", "<cmd>Telescope marks<CR>", { unique = true, desc = "Show all marks list" })
map({ "n", "v" }, "<leader>mc", "<cmd>:delm! | delm A-Z0-9<CR>", { unique = true, desc = "Clear marks list" })

vim.api.nvim_set_keymap('n', '<leader>de', ':lua vim.lsp.diagnostic.refresh()<CR>', { noremap = true, silent = true, unique=true })

vim.keymap.set({ "n", "v", "i" }, "<leader>fs", function()
  vim.lsp.buf.format {
    async = false,
    timeout_ms = 500,
  }
end, { unique = true, desc = "Format file or range (in visual mode)" })

-- vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
-- vim.keymap.set("n", "I", vim.lsp.buf.implementation, opts)

map("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, desc = "Exit terminal mode" })

-- vim.keymap.set("v", "<leader>mb", "di****<esc>hhp", { desc = "Auto bold" })
-- vim.keymap.set("v", "<leader>mi", "di**<esc>hp", { desc = "Auto italic" })
-- vim.keymap.set("v", "<leader>ml", "di[]()<esc>hhhpllli", { desc = "Auto link" })
-- vim.keymap.set("v", "<leader>mc", "di``<esc>hp", { desc = "Auto backtick" })
--

-- Jumps
vim.keymap.set("n", "<leader>jt", "<cmd>/template:<cr><cmd>nohl<cr>", { unique = true, desc = "Jump to template" })
vim.keymap.set("n", "<leader>js", "<cmd>/style.:<cr><cmd>nohl<cr>", { unique = true, desc = "Jump to styles" })
vim.keymap.set("n", "<leader>jc", "<cmd>/Component {<cr><cmd>nohl<cr>", { unique = true, desc = "Jump to component" })

-- ufo
vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

vim.api.nvim_create_user_command("TOhtml", function()
  local tohtml = require "tohtml"
  local bufname = vim.api.nvim_buf_get_name(0)
  local filename = bufname:match "^.+/(.+)$" or "Untitled"
  local final_filename = filename .. "-ShareBySefat.html"
  local filepath = os.getenv "HOME" .. "/Downloads/" .. final_filename
  local output = tohtml.tohtml(0, { title = "My Code" })

  local file = io.open(filepath, "w")
  if file then
    file:write(table.concat(output, "\n"))
    file:close()
    print("Yo! HTML saved to " .. filepath)
  else
    print "Error: Unable to save file."
  end
end, {})
