return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      codelens    = { enabled = false },
      -- document-highlight-on-CursorHold is actually driven by snacks.nvim's
      -- `words` module (LazyVim has no `document_highlight` opt to disable it
      -- through), see nvim/lua/plugins/snacks.lua for the real toggle.
      servers = {
        ["*"] = {
          capabilities = {
            workspace = {
              -- critical for monorepos: stops LSP watching node_modules + entire workspace
              didChangeWatchedFiles = { dynamicRegistration = false },
            },
          },
          -- Neovim's own default is already 150ms; double it so heavier
          -- servers (vtsls/jdtls/angularls) reparse on fewer, larger bursts
          -- of typing instead of nearly every keystroke
          flags = { debounce_text_changes = 300 },
        },
        -- HTML LSP: attach to both html and htmlangular filetypes
        -- This ensures HTML features work in Angular templates alongside Angular LSP
        html = {
          filetypes = { "html", "htmlangular" },
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
