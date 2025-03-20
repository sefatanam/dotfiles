return {

  "joeveiga/ng.nvim",
  config = function()
    local ng = require "ng"
    ng.setup()
    local opts = { noremap = true, silent = true }

    vim.keymap.set("n", "<leader>at", ng.goto_template_for_component, opts)
    vim.keymap.set("n", "<leader>ac", ng.goto_component_with_template_file, opts)
    vim.keymap.set("n", "<leader>aT", ng.get_template_tcb, opts)
  end,
}
