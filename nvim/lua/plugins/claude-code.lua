return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  enable  = false,
  lazy = true,
  opts = {
    -- No embedded terminal: this Neovim instance only runs the WebSocket/MCP
    -- server + lock file. Sends are delivered to whatever external `claude`
    -- process is IDE-connected (e.g. `claude` running in another terminal),
    -- instead of opening/toggling a blank terminal split beside Neovim.
    terminal = {
      provider = "none",
    },
  },
  config = true,
  cmd = {
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },
  keys = {
    { "<leader>a",  nil,                        desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCodeStart<cr>", desc = "Start Claude connection" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",  mode = "v",                      desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
  },
}

