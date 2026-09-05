local M = {}

local plugins = {
  pi = {
    spec = "carderne/pi-nvim",
    keys = {
      { "<leader>ap", "<cmd>PiSend<cr>", mode = "n", desc = "Pi Send" },
      { "<leader>af", "<cmd>PiSendFile<cr>", mode = "n", desc = "Pi Send File" },
      { "<leader>as", "<cmd>PiSendSelection<cr>", mode = "v", desc = "Pi Send Selection" },
      { "<leader>aS", ":lua PiSendSelectionSilent()<cr>", mode = "v", desc = "Pi Send Selection (Silent)" },
      { "<leader>ab", "<cmd>PiSendBuffer<cr>", mode = "n", desc = "Pi Send Buffer" },
      { "<leader>ai", "<cmd>PiPing<cr>", mode = "n", desc = "Pi Ping" },
    },
  },
  claude = {
    spec = "coder/claudecode.nvim",
    keys = {
      { "<leader>ac", "<cmd>ClaudeCodeStart<cr>", mode = "n", desc = "Start Claude connection" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", mode = "n", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",  mode = "v", desc = "Send to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", mode = "n", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   mode = "n", desc = "Deny diff" },
    },
  },
  opencode = {
    spec = "nickjvandyke/opencode.nvim",
    keys = {
      { "<C-q>", function() require("opencode").ask("@this: ", { submit = true }) end, mode = { "n", "x" }, desc = "Ask opencode…" },
      { "<C-x>", function() require("opencode").select() end, mode = { "n", "x" }, desc = "Execute opencode action…" },
      { "<C-.>", function() require("opencode").toggle() end, mode = { "n", "t" }, desc = "Toggle opencode" },
      { "go", function() return require("opencode").operator("@this ") end, mode = { "n", "x" }, expr = true, desc = "Add range to opencode" },
    },
  },
}

function M.activate(name)
  local plugin = plugins[name]
  if not plugin then
    vim.notify("Unknown AI plugin: " .. tostring(name) .. ". Available: pi, claude, opencode", vim.log.levels.ERROR)
    return
  end

  -- Load the plugin via lazy.nvim
  require("lazy").load({ plugin.spec })

  -- Apply keymaps
  for _, keymap in ipairs(plugin.keys) do
    vim.keymap.set(keymap.mode or "n", keymap[1], keymap[2], { desc = keymap.desc })
  end

  vim.notify("Activated AI: " .. name)
end

-- Create the command
vim.api.nvim_create_user_command("AIActivate", function(opts)
  M.activate(opts.args)
end, { nargs = 1 })

return M
