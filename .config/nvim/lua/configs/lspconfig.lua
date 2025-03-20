-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local ok, mason_registry = pcall(require, "mason-registry")

if not ok then
  vim.notify "mason-registry could not be loaded"
  return
end

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig.util"
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

lspconfig.ts_ls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

lspconfig.cssls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
}

lspconfig.html.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
}

lspconfig.gopls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
}

lspconfig.jsonls.setup {
  cmd = { "vscode-json-languageserver", "--stdio" },
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
  filetypes = { "json", "jsonc" },
  init_options = {
    provideFormatter = true,
  },
  single_file_support = true,
}

local angularls_path = mason_registry.get_package("angular-language-server"):get_install_path()

local cmd = {
  "ngserver",
  "--stdio",
  "--tsProbeLocations",
  table.concat({
    angularls_path,
    vim.uv.cwd(),
  }, ","),
  "--ngProbeLocations",
  table.concat({
    angularls_path .. "/node_modules/@angular/language-server",
    vim.uv.cwd(),
  }, ","),
}

lspconfig.angularls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  root_dir = util.root_pattern("angular.json", "project.json"),
  cmd = cmd,
  on_new_config = function(new_config, new_root_dir)
    new_config.cmd = cmd
  end,
}

-- For linting setup
-- https://www.reddit.com/r/neovim/comments/le1duu/nvim_lsp_and_typescript_eslint_and_prettier/
