return {
  "nvzone/menu",
  dependencies = { "nvzone/volt" },

  vim.keymap.set({ "n", "v", "i" }, "<RightMouse>", function()
    require("menu.utils").delete_old_menus()
    vim.cmd.exec '"normal! \\<RightMouse>"'
    -- clicked buf
    local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
    local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"
    require("menu").open(options, { mouse = true })
  end, { unique = true }),
}
