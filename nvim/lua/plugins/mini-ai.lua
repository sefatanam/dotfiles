return {
  'echasnovski/mini.ai',
  version = false,
  event = 'VeryLazy',
  dependencies = {
    {
      'echasnovski/mini.extra',
      version = false,
    },
  },
  config = function()
    require('mini.ai').setup({
      mappings = {
        around = 'a',
        inside = 'i',
      },
      custom_textobjects = {
        e = require('mini.extra').gen_ai_spec.buffer(),
      },
    })
  end,
}
