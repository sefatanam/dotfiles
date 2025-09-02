-- ~/.config/nvim/lua/plugins/mini-ai.lua

return {
  "echasnovski/mini.ai",
  version = false, -- Fetch from `main`, which includes `mini.extra`  [oai_citation:37‡github.com](https://github.com/echasnovski/mini.nvim/discussions/36?utm_source=chatgpt.com) [oai_citation:38‡github.com](https://github.com/echasnovski/mini.nvim?utm_source=chatgpt.com)
  event = "VeryLazy", -- Load on first idle for performance
  cond = vim.g.vscode, -- Only load `mini.ai` when NOT in VSCode  [oai_citation:39‡lazyvim.github.io](https://lazyvim.github.io/extras/editor/mini-files?utm_source=chatgpt.com) [oai_citation:40‡stackoverflow.com](https://stackoverflow.com/questions/76757832/how-to-configure-lazy-nvim-with-mini-files?utm_source=chatgpt.com)

  dependencies = {
    {
      "echasnovski/mini.extra",
      version = false, -- Ensure `mini.extra` is present; uses main branch  [oai_citation:41‡github.com](https://github.com/echasnovski/mini.nvim/discussions/36?utm_source=chatgpt.com) [oai_citation:42‡github.com](https://github.com/echasnovski/mini.nvim?utm_source=chatgpt.com)
      cond = vim.g.vscode, -- Only install/load `mini.extra` in standalone Neovim  [oai_citation:43‡lazyvim.github.io](https://lazyvim.github.io/extras/editor/mini-files?utm_source=chatgpt.com) [oai_citation:44‡stackoverflow.com](https://stackoverflow.com/questions/76757832/how-to-configure-lazy-nvim-with-mini-files?utm_source=chatgpt.com)
    },
  },

  config = function()
    -- Both `mini.ai` and `mini.extra` are guaranteed to be on `runtimepath` now  [oai_citation:45‡lazyvim.github.io](https://lazyvim.github.io/plugins/coding?utm_source=chatgpt.com) [oai_citation:46‡github.com](https://github.com/echasnovski/mini.nvim/discussions/36?utm_source=chatgpt.com)
    local ai = require("mini.ai")
    local extra = require("mini.extra")

    ai.setup({
      mappings = {
        around = "a",
        inside = "i",
      },
      custom_textobjects = {
        -- Use the `mini.extra` generator for “e” textobjects  [oai_citation:47‡github.com](https://github.com/echasnovski/mini.nvim?utm_source=chatgpt.com) [oai_citation:48‡github.com](https://github.com/echasnovski/mini.nvim?utm_source=chatgpt.com)
        e = extra.gen_ai_spec.buffer(),
      },
    })
  end,
}
