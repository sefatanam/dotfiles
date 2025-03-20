return {
  {
    "nvimtools/none-ls.nvim",
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettierd,
          null_ls.builtins.formatting.shfmt,
          null_ls.builtins.formatting.cbfmt,
          null_ls.builtins.formatting.goimports,
          null_ls.builtins.formatting.gofumpt,
          null_ls.builtins.formatting.templ,

          null_ls.builtins.diagnostics.eslint_d
        },
      })
    end
  }

}

-- Support link
--https://www.reddit.com/r/neovim/comments/1fdpap9/eslint_error_could_not_parse_linter_output_due_to/
