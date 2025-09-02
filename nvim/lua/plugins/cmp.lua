return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local cmp = require("cmp")
    -- NOTE: Window borders
    opts.window = {
      completion    = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    }
    return opts
  end,
}
