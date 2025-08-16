local function foldTextFormatter(virtText, lnum, endLnum, width, truncate)
  local hlgroup = "NonText"
  local newVirtText = {}
  local suffix = "    " .. tostring(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, hlgroup })
  return newVirtText
end

-- ~/.config/nvim/lua/plugins/ufo.lua

return {
  "kevinhwang91/nvim-ufo",
  -- Ensure 'promise-async' is installed as a dependency
  dependencies = { "kevinhwang91/promise-async" },

  -- Only load nvim-ufo when NOT running inside VSCode
  cond = not vim.g.vscode,

  -- You can choose an event or key-based lazy-loading.
  -- Here we load on VimEnter so folds are ready when buffer opens:
  event = "VimEnter",

  config = function()
    -- At this point, both nvim-ufo and promise-async are on runtimepath
    local ufo = require("ufo") -- [oai_citation:10‡ericapisani.dev](https://www.ericapisani.dev/how-to-install-nvim-ufo-in-lazyvim-to-enable-foldable-code-blocks/?utm_source=chatgpt.com)

    -- Optional: configure provider selector, fold handlers, etc.
    ufo.setup({
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" },
        json = { "array" },
        c = { "comment", "region" },
      },
      open_fold_hl_timeout = 150,
      preview = {
        win_config = {
          border = { "", "─", "", "", "", "─", "", "" },
          winhighlight = "Normal:Folded",
          winblend = 0,
        },
        mappings = {
          scrollU = "<C-u>",
          scrollD = "<C-d>",
          jumpTop = "[",
          jumpBot = "]",
        },
      },
      provider_selector = function(_, ft, _)
        local lsp_exceptions = {
          "markdown",
          "md",
          "mdx",
          "agx",
          "svx",
          "sh",
          "css",
          "html",
          "python",
        }
        if vim.tbl_contains(lsp_exceptions, ft) then
          return { "treesitter", "indent" }
        end
        return { "treesitter", "indent" }
        -- return { "lsp", "indent" }
      end,
    })

    -- Keymaps for folding actions
    vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open All Folds" })
    vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close All Folds" })
    vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds, { desc = "Open Folds Except Kinds" })
    vim.keymap.set("n", "zm", ufo.closeFoldsWith, { desc = "Close Folds With Level" })

    -- Peek folded lines (fallback hover if no folds to peek)
    vim.keymap.set("n", "F", function()
      local winid = ufo.peekFoldedLinesUnderCursor()
      if not winid then
        -- If no folded lines, fall back to LSP hover or Coc action
        vim.fn.CocActionAsync("definitionHover") -- if using Coc.nvim
        vim.lsp.buf.hover() -- if using built-in LSP
      end
    end, { desc = "Peek Folded Lines / Hover" })
  end,
}
