return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'nickjvandyke/opencode.nvim' },
  opts = function(_, opts)
    if not opts.sections then
      opts.sections = {}
    end
    if not opts.sections.lualine_z then
      opts.sections.lualine_z = {}
    end
    table.insert(opts.sections.lualine_z, {
      function()
        return require("opencode").statusline()
      end,
    })
  end,
}
