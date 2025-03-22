return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("noice").setup {
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
          },
        },
        routes = {
          {
            filter = {
              event = "notify",
              find = "No information available",
            },
            opts = { skip = true },
          },
          { filter = { find = "E162" }, view = "mini" },
          {
            filter = {
              event = "msg_show",
              any = {
                { find = "; after #%d+" },
                { find = "; before #%d+" },
                { find = "fewer lines" },
                { find = "written" },
                { find = "Conflict %[%d+" },
                { find = "Col %d+" },
              },
            },
            view = "mini",
          },
          { filter = { event = "msg_show", find = "search hit BOTTOM" }, skip = true },
          { filter = { event = "msg_show", find = "search hit TOP" }, skip = true },
          { filter = { event = "emsg", find = "E23" }, skip = true },
          { filter = { event = "emsg", find = "E20" }, skip = true },
          { filter = { find = "No signature help" }, skip = true },
          { filter = { find = "E37" }, skip = true },
          { filter = { find = "E31" }, skip = true },
          { filter = { find = "Error detected while processing BufReadPost Autocommands for" }, skip = true },
        },
        views = {

          cmdline_popup = {
            position = {
              row = "50%",
              col = "50%",
            },
          },
        },
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = true, -- add a border to hover docs and signature help
        },
      }
    end,
  },
}
