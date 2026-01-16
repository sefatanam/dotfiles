return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      html = { "prettier", "biome", stop_after_first = true },
      javascript = { "biome", stop_after_first = true },
      typescript = { "biome", stop_after_first = true },
      json = { "biome", "prettier", stop_after_first = true },
      jsonc = { "biome", "prettier", stop_after_first = true },
      css = { "biome", "prettier", stop_after_first = true },
      go = { "goimports", "gofumpt" },
      lua = { "stylua" },
    },
    formatters = {
      prettier = {
        prepend_args = function(_, ctx)
          -- Add tailwind plugin for files that might use Tailwind
          print("Formatting with prettier, filetype:", ctx.filetype)
          local tailwind_filetypes = { "html", "vue", "svelte", "astro" }

          for _, ft in ipairs(tailwind_filetypes) do
            if ctx.filetype == ft then
              return { "--plugin", "prettier-plugin-tailwindcss" }
            end
          end

          return {}
        end,
      },
    },
  },
}
