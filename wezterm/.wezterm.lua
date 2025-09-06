-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("JetBrainsMono Nerd Font Propo")
config.font_size = 16

config.enable_tab_bar = false

config.window_decorations = "TITLE | RESIZE"
-- config.window_background_opacity = 0.8
-- config.macos_window_background_blur = 10

config.default_cursor_style = "BlinkingBar"

-- Performance and GPU acceleration settings
config.front_end = "WebGpu"
config.animation_fps = 60
config.max_fps = 60

-- Ensure accurate color rendering
config.bold_brightens_ansi_colors = false
config.use_fancy_tab_bar = false

config.force_reverse_video_cursor = true

-- Manual kanso-zen colors (official theme not available in WezTerm)
config.colors = {
  foreground = "#C5C9C7",
  background = "#090E13",

  cursor_bg = "#C5C9C7",
  cursor_fg = "#090E13",
  cursor_border = "#C5C9C7",

  selection_fg = "#C5C9C7",
  selection_bg = "#22262D",

  scrollbar_thumb = "#22262D",
  split = "#22262D",

  ansi = {
    "#090E13", -- black
    "#C4746E", -- red  
    "#8A9A7B", -- green
    "#C4B28A", -- yellow
    "#8BA4B0", -- blue
    "#A292A3", -- magenta
    "#8EA4A2", -- cyan
    "#A4A7A4", -- white
  },
  brights = {
    "#5C6066", -- bright black
    "#E46876", -- bright red
    "#87A987", -- bright green
    "#E6C384", -- bright yellow
    "#7FB4CA", -- bright blue
    "#938AA9", -- bright magenta
    "#7AA89F", -- bright cyan
    "#C5C9C7", -- bright white
  },
}
-- and finally, return the configuration to wezterm
return config
