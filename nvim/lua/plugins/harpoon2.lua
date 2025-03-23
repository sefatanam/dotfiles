return {
  {
    "ThePrimeagen/harpoon",
    lazy = false,
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local harpoon = require "harpoon"
      harpoon.setup()

      local conf = require("telescope.config").values

      vim.keymap.set("n", "<leader>mh", function()
        harpoon:list():add()
      end, { unique = true, desc = "Add current file to harpoon" })

      local function open_harpoon_list(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table {
              results = file_paths,
            },
            previewer = conf.file_previewer {},
            sorter = conf.generic_sorter {},
          })
          :find()
      end

      vim.keymap.set("n", "<leader>lh", function()
        open_harpoon_list(harpoon:list())
      end, { unique = true, desc = "Open harpoon window" })
    end,
  },
}
