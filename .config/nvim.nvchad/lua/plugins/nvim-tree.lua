return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    require("nvim-tree").setup {
      hijack_netrw = true,
      sync_root_with_cwd = true,
      sort = {
        sorter = "case_sensitive",
      },
      renderer = {
        group_empty = true,
        add_trailing = true,
        highlight_git = false,
        full_name = false,
        highlight_opened_files = "all",
        root_folder_label = ":t",
        indent_width = 2,
        indent_markers = {
          enable = true,
          inline_arrows = true,
          icons = {
            corner = "└",
            edge = "│",
            item = "│",
            none = " ",
          },
        },
      },
      filters = {
        -- dotfiles = true,
        dotfiles = false,
        git_clean = false,
        no_buffer = false,
        exclude = { 'node_modules', 'dist' },
      },
      view = {
        -- width = 50, -- Default width for the tree
        preserve_window_proportions = true, -- Keep window proportions when resizing
        -- side = "right",
        -- relativenumber = true,
        adaptive_size = true,
      },
      auto_reload_on_write = true, -- Reload tree when files are written
      update_focused_file = {
        enable = true,             -- Update the focused file
        update_cwd = true,         -- Update the working directory
      },
      git = {
        enable = true, -- Show git status in the tree
      },
      diagnostics = {
        enable = true, -- Show diagnostics in the tree
        icons = {
          hint = "",
          info = "",
          warning = "",
          error = "",
        },
      },
    }

    -- Persist nvim-tree width across sessions
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        local width = vim.g.nvim_tree_width
        if width then
          vim.cmd("vertical resize " .. width)
        end
      end,
    })

    vim.api.nvim_create_autocmd("WinLeave", {
      pattern = "NvimTree*",
      callback = function()
        vim.g.nvim_tree_width = vim.api.nvim_win_get_width(0)
      end,
    })
  end,
}
