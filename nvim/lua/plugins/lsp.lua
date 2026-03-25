return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints        = { enabled = false },
      codelens           = { enabled = false },
      document_highlight = { enabled = false }, -- no LSP re-query on every CursorHold
      servers = {
        ["*"] = {
          capabilities = {
            workspace = {
              -- critical for monorepos: stops LSP watching node_modules + entire workspace
              didChangeWatchedFiles = { dynamicRegistration = false },
            },
          },
        },
        -- only start in Svelte projects (svelte.config.* must exist)
        svelte = {
          root_dir = require("lspconfig.util").root_pattern(
            "svelte.config.js",
            "svelte.config.ts",
            "svelte.config.mjs"
          ),
        },
        -- only start in Vue/Nuxt projects (vue.config.* or nuxt.config.* must exist)
        volar = {
          root_dir = require("lspconfig.util").root_pattern(
            "vue.config.js",
            "vue.config.ts",
            "nuxt.config.js",
            "nuxt.config.ts"
          ),
        },
      },
    },
  },
}
