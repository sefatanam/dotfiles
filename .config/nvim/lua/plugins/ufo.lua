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

return {
  "kevinhwang91/nvim-ufo",
  dependencies = "kevinhwang91/promise-async",
  event = "VimEnter", -- needed for folds to load in time and comments closed
  -- keys = {
  -- 	-- stylua: ignore start
  -- 	{ "zm", function() require("ufo").closeAllFolds() end, desc = " 󱃄 Close All Folds" },
  -- 	{ "zr", function() require("ufo").openFoldsExceptKinds { "comment", "imports" } end, desc = " 󱃄 Open All Regular Folds" },
  -- 	{ "zR", function() require("ufo").openFoldsExceptKinds {} end, desc = " 󱃄 Open All Folds" },
  -- 	{ "z1", function() require("ufo").closeFoldsWith(1) end, desc = " 󱃄 Close L1 Folds" },
  -- 	{ "z2", function() require("ufo").closeFoldsWith(2) end, desc = " 󱃄 Close L2 Folds" },
  -- 	{ "z3", function() require("ufo").closeFoldsWith(3) end, desc = " 󱃄 Close L3 Folds" },
  -- 	{ "z4", function() require("ufo").closeFoldsWith(4) end, desc = " 󱃄 Close L4 Folds" },
  --   -- stylua: ignore end
  -- },
  opts = {
    -- when opening the buffer, close these fold kinds
    -- use `:UfoInspect` to get available fold kinds from the LSP
    close_fold_kinds = { "imports", "comment" },
    open_fold_hl_timeout = 1000,
    -- fold_virt_text_handler = foldTextFormatter,
  },
  config = function()
    require("ufo").setup {
      open_fold_hl_timeout = 150,
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" },
        json = { "array" },
        c = { "comment", "region" },
      },
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
        -- INFO some filetypes only allow indent, some only LSP, some only
        -- treesitter. However, ufo only accepts two kinds as priority,
        -- therefore making this function necessary :/
        local lspWithOutFolding = { "markdown", "md", "mdx", "agx", "svx", "sh", "css", "html", "python" }
        if vim.tbl_contains(lspWithOutFolding, ft) then
          return { "treesitter", "indent" }
        end
        return { "treesitter", "indent" }
        -- return { "lsp", "indent" }
      end,
    }
    vim.keymap.set("n", "zR", require("ufo").openAllFolds)
    vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
    vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
    vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
    vim.keymap.set("n", "F", function()
      local winid = require("ufo").peekFoldedLinesUnderCursor()
      if not winid then
        -- choose one of coc.nvim and nvim lsp
        vim.fn.CocActionAsync "definitionHover" -- coc.nvim
        vim.lsp.buf.hover()
      end
    end)
  end,
}
