return {
  'rmagatti/auto-session',
  lazy = false,
  opts = {
    suppressed_dirs = { '~/nvim-session' },
  },

  config = function()
    require('auto-session').setup {}
  end
}
