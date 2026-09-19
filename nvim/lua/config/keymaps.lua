-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- All custom keymaps live in config/customize.lua; this file just pulls it in
-- so LazyVim's auto-load (by filename, on VeryLazy) still picks them up.
require("config.customize")
