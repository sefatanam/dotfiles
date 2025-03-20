return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    depepedencies = {},
    opts = {
      history = true,
      delete_check_events = "TextChanged",
      function()
        LazyVim.cmp.actions.snippet_forward = function()
          if require("luasnip").jumpable(1) then
            vim.schedule(function()
              require("luasnip").jump(1)
            end)
            return true
          end
        end
        LazyVim.cmp.actions.snippet_stop = function()
          if require("luasnip").expand_or_jumpable() then -- or just jumpable(1) is fine?
            require("luasnip").unlink_current()
            return true
          end
        end
      end,
      function(_, opts)
        opts.snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        }
        table.insert(opts.sources, { name = "luasnip" })
      end,
    },
  },
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "tailwind-tools",
      "onsails/lspkind-nvim",
    },
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
    config = function()
      local cmp = require "cmp"
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_snipmate").load({ path = { "~/.config/nvim/snippets" } })
      local lspkind = require "lspkind"
      local tailwind_tools = require "tailwind-tools.cmp"

      local winopts = {
        border = "single",
        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
      }
      local cmp_kinds = {
        Text = "  ",
        Method = "  ",
        Function = "  ",
        Constructor = "  ",
        Field = "  ",
        Variable = "  ",
        Class = "  ",
        Interface = "  ",
        Module = "  ",
        Property = "  ",
        Unit = "  ",
        Value = "  ",
        Enum = "  ",
        Keyword = "  ",
        Snippet = "  ",
        Color = "  ",
        File = "  ",
        Reference = "  ",
        Folder = "  ",
        EnumMember = "  ",
        Constant = "  ",
        Struct = "  ",
        Event = "  ",
        Operator = "  ",
        TypeParameter = "  ",
      }
      cmp.setup {
        enabled = true,
        -- preselect = cmp.PreselectMode.None,
        completeopt = "menu,menuone,noselect,noinsert",
        formatting = {
          expandable_indicator = true,
          fields = { "abbr", "kind", "menu" },
          -- format = function(_, vim_item)
          --   vim_item.kind = (cmp_kinds[vim_item.kind] or "") .. vim_item.kind
          --   return vim_item
          -- end,
          format = lspkind.cmp_format {
            before = tailwind_tools.lspkind_format,
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            symbol_map = cmp_kinds,
          },
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(winopts),
          documentation = cmp.config.window.bordered(winopts),
        },
        mapping = cmp.mapping.preset.insert {
          -- ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          -- ["<C-f>"] = cmp.mapping.scroll_docs(4),
          -- ["<C-Space>"] = cmp.mapping.complete(),
          -- ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm { select = true },
        },
        sources = cmp.config.sources(
          {
            { name = "nvim_lsp" },
            { name = "luasnip" },
          },
          {
            { name = "buffer" },
          }
        ),
        completion = {
          completeopt = "menu,menuone,noinsert,noselect",
        },
      }
    end,
  } }
