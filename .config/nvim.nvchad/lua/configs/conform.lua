local options = {
  event = { "BufReadPre", "BufNewFile" },
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettierd" },
    html = { "prettierd" },
    css = { "prettierd" },
    scss = { "prettierd" },
    typescript = { "prettierd" },
  },
}

return options
