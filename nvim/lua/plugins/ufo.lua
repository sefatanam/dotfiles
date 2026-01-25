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

  -- @REVIEW: Changed to BufReadPost for lazy loading
  event = "BufReadPost",

  config = function()
    -- @REVIEW: Skip setup for large files
    if vim.b.large_file then
      return
    end

    -- At this point, both nvim-ufo and promise-async are on runtimepath
    local ufo = require("ufo")

    -- @REVIEW: Optimized ufo setup with performance tweaks
    ufo.setup({
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" },
        json = { "imports", "comment", "region", "marker" },
        c = { "comment", "region" },
      },
      -- @REVIEW: Reduced highlight timeout for snappier feel
      open_fold_hl_timeout = 100,
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
      -- @REVIEW: Use indent-based folding for better performance (treesitter is expensive)
      provider_selector = function(bufnr, ft, _)
        -- Skip treesitter for large files (>1500 lines), use indent only
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        if line_count > 1500 then
          return { "indent" }
        end

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
        -- @REVIEW: Default to indent for performance, treesitter as fallback
        return { "indent" }
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
        vim.lsp.buf.hover()                      -- if using built-in LSP
      end
    end, { desc = "Peek Folded Lines / Hover" })
  end,
}
