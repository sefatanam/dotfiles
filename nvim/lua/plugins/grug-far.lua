return {
  "MagicDuck/grug-far.nvim",
  keys = {
    {
      "<leader>sr",
      function()
        local word = vim.fn.expand("<cword>")
        local current_file = vim.fn.expand("%:p")
        local ext = vim.fn.expand("%:e")
        local filetype_glob = ext ~= "" and ("**/*." .. ext) or ""

        local current_dir = vim.fn.expand("%:p:h")
        local choices = { "Current file", "Entire project" }
        if ext ~= "" then
          table.insert(choices, "*." .. ext .. " (current dir)")
          table.insert(choices, "*." .. ext .. " (entire project)")
        end

        vim.ui.select(choices, { prompt = "Search & Replace scope:" }, function(choice)
          if not choice then return end
          local prefills = { search = word }
          if choice == "Current file" then
            prefills.paths = current_file
          elseif choice:match("current dir") then
            prefills.paths = current_dir
            prefills.filesFilter = "*." .. ext
          elseif choice:match("entire project") then
            prefills.filesFilter = "*." .. ext
          end
          require("grug-far").open({ prefills = prefills })
        end)
      end,
      desc = "Search & Replace (choose scope)",
    },
  },
}
