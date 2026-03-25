-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
map("n", ";", ":", { desc = "CMD enter command mode", noremap = true })
map("n", "D", '"_d$', { desc = "Delete to the vois register.", noremap = true })


vim.api.nvim_set_keymap(
  "n",
  "<leader>drr",
  ":lua vim.lsp.diagnostic.refresh()<CR>",
  { noremap = true, silent = true, unique = true }
)

map({ "n", "v", "i" }, "<leader>fs", function()
  vim.lsp.buf.format({ async = true })
end, { unique = true, desc = "Format file or range (in visual mode)" })

map("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, desc = "Exit terminal mode" })

-- vim.keymap.set("v", "<leader>mb", "di****<esc>hhp", { desc = "Auto bold" })
-- vim.keymap.set("v", "<leader>mi", "di**<esc>hp", { desc = "Auto italic" })
-- vim.keymap.set("v", "<leader>ml", "di[]()<esc>hhhpllli", { desc = "Auto link" })
-- vim.keymap.set("v", "<leader>mc", "di``<esc>hp", { desc = "Auto backtick" })

-- Jumps
map("n", "<leader>jt", "<cmd>/template:<cr><cmd>nohl<cr>", { unique = true, desc = "Jump to template" })
map("n", "<leader>js", "<cmd>/style.:<cr><cmd>nohl<cr>", { unique = true, desc = "Jump to styles" })
map("n", "<leader>jc", "<cmd>/Component {<cr><cmd>nohl<cr>", { unique = true, desc = "Jump to component" })

if not vim.g.vscode then
  -- ufo
  map("n", "zR", require("ufo").openAllFolds)
  map("n", "zM", require("ufo").closeAllFolds)
end

vim.api.nvim_create_user_command("TOhtml", function()
  local tohtml = require("tohtml")
  local bufname = vim.api.nvim_buf_get_name(0)
  local filename = bufname:match("^.+/(.+)$") or "Untitled"
  local final_filename = filename .. "-ShareBySefat.html"
  local filepath = os.getenv("HOME") .. "/Downloads/" .. final_filename
  local output = tohtml.tohtml(0, { title = final_filename, style = "colorful" })

  local file = io.open(filepath, "w")
  if file then
    file:write(table.concat(output, "\n"))
    file:close()
    print("Yo! HTML saved to " .. filepath)
  else
    print("Error: Unable to save file.")
  end
end, {})

if not vim.g.vscode then
  -- Map H to previous buffer
  map("n", "<S-Tab>", ":bprev<CR>", { desc = "Previous buffer", silent = true, unique = true })
  -- Map L to next buffer
  map("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer", silent = true, unique = true })
  -- New tab
  map("n", "te", ":tabedit")
  -- Split window
  map("n", "hs", ":split<Return>", { desc = "Horizontal Split", silent = true, unique = true })
  map("n", "vs", ":vsplit<Return>", { desc = "Verticle Split", silent = true, unique = true })
end

if vim.g.vscode then
  local keymap = vim.keymap.set
  local opts = {
    noremap = true,
    silent = true,
  }

  -- remap leader key
  keymap("n", "<Space>", "", opts)
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  -- general keymaps
  keymap({ "n", "v" }, "<leader>t", "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>")
  keymap({ "n", "v" }, "<leader>b", "<cmd>lua require('vscode').action('editor.debug.action.toggleBreakpoint')<CR>")
  keymap({ "n", "v" }, "<leader>d", "<cmd>lua require('vscode').action('editor.action.showHover')<CR>")
  keymap({ "n", "v" }, "<leader>a", "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>")
  keymap({ "n", "v" }, "<leader>sp", "<cmd>lua require('vscode').action('workbench.actions.view.problems')<CR>")
  keymap({ "n", "v" }, "<leader>cn", "<cmd>lua require('vscode').action('notifications.clearAll')<CR>")
  keymap({ "n", "v" }, "<leader>ff", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>")
  keymap({ "n", "v" }, "<leader>cp", "<cmd>lua require('vscode').action('workbench.action.showCommands')<CR>")
  keymap({ "n", "v" }, "<leader>pr", "<cmd>lua require('vscode').action('code-runner.run')<CR>")
  keymap({ "n", "v" }, "<leader>fd", "<cmd>lua require('vscode').action('editor.action.formatDocument')<CR>")
end

-- ref theprimeagen
vim.keymap.set({"n","v"}, "<leader>p","\",_dP", { noremap = true, silent = true, desc = "Paste without replacing the default register" })

-- @REVIEW: Toggle performance mode for large files
map("n", "<leader>up", function()
  vim.b.large_file = not vim.b.large_file
  if vim.b.large_file then
    -- Enable performance mode
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline = false
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.list = false

    local ok, ts_context = pcall(require, "treesitter-context")
    if ok then ts_context.disable() end

    local ufo_ok, ufo = pcall(require, "ufo")
    if ufo_ok then ufo.detach() end

    vim.notify("Performance mode: ON", vim.log.levels.INFO)
  else
    -- Disable performance mode
    vim.opt_local.relativenumber = true
    vim.opt_local.cursorline = true
    vim.opt_local.list = true

    local ok, ts_context = pcall(require, "treesitter-context")
    if ok then ts_context.enable() end

    local ufo_ok, ufo = pcall(require, "ufo")
    if ufo_ok then ufo.attach() end

    vim.notify("Performance mode: OFF", vim.log.levels.INFO)
  end
end, { desc = "Toggle performance mode" })
