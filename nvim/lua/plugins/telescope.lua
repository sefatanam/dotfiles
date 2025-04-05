return {
  {
    "nvim-telescope/telescope.nvim", -- Core Telescope plugin
    cmd = "Telescope", -- Lazy load on command
    dependencies = {
      "nvim-telescope/telescope-ui-select.nvim",
    },
    keys = {
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = {
            "node_modules",
            ".git",
            ".cache",
            ".github",
            ".vscode",
            ".idea",
            ".gitignore",
            ".gitattributes",
            ".gitmodules",
            ".DS_Store",
            ".editorconfig",
            ".eslintignore",
            ".eslintrc",
            ".prettierignore",
            ".prettierrc",
            ".stylelintrc",
            ".stylelintignore",
            ".huskyrc",
            ".lintstagedrc",
            ".browserslistrc",
            ".babelrc",
            "package-lock.json",
            "yarn.lock",
            "composer.lock",
            "Gemfile.lock",
            "package.json",
          },
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob",
            "!.git/",
            "--glob",
            "!node_modules/",
          },
          layout_config = {
            prompt_position = "top", -- Move search bar back to top
          },
          sorting_strategy = "ascending", -- Results show below search bar
        },
        pickers = {
          quickfix = { theme = "dropdown" },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })

      vim.keymap.set("n", "<leader>ds", "<cmd>Telescope diagnostics<CR>", { noremap = true, silent = true })

      -- Load Extensions
      telescope.load_extension("ui-select")
    end,
  },
}
