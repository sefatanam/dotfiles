return {
  "carderne/pi-nvim",
  lazy = true,
  config = function()
    require("pi-nvim").setup()

    -- Custom function to send selection without asking for a prompt
    _G.PiSendSelectionSilent = function()
      local pi = require("pi-nvim")
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.visualmode() })
      local selection = table.concat(lines, "\n")

      if selection == "" then
        vim.notify("Empty selection", vim.log.levels.WARN)
        return
      end

      local header = string.format("%s lines %d-%d", vim.fn.expand("%:."), start_pos[2], end_pos[2])
      local message = string.format("Context only: Please remember the following code from %s but DO NOT respond or analyze it yet. Just acknowledge you received it and wait for my specific instructions.\n\n```%s\n%s\n```", header, vim.bo.filetype, selection)
      pi.prompt(message)
    end

    -- Override the keymap to use the silent version
    vim.keymap.set("v", "<leader>as", ":lua PiSendSelectionSilent()<CR>", { silent = true, desc = "Pi Send Selection (Silent)" })
  end
}
