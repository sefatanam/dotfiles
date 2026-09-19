# Neovim Config

[LazyVim](https://github.com/LazyVim/LazyVim)-based config. Personal keymaps and
overrides live in [`lua/config/customize.lua`](lua/config/customize.lua), loaded
via `lua/config/keymaps.lua` (LazyVim auto-loads that filename on `VeryLazy`).
Everything below is custom — for LazyVim's own defaults, see its
[keymaps docs](https://www.lazyvim.org/keymaps).

Plugin-specific keys (e.g. `ufo.lua`, `opencode.lua`, `pi-nvim.lua`) are defined
in their own plugin spec files under `lua/plugins/` and aren't listed here.

## Normal mode

| Key | Action |
| --- | --- |
| `D` | Delete to end of line into the void register (doesn't clobber `"`) |
| `<leader>drr` | Refresh LSP diagnostics |
| `<leader>fs` | Format file (or range in visual mode) |
| `<leader>jt` | Jump to next `template:` |
| `<leader>js` | Jump to next `style.` |
| `<leader>jc` | Jump to next `Component {` |
| `zR` | Open all folds (ufo) |
| `zM` | Close all folds (ufo) |
| `<S-Tab>` | Previous buffer |
| `<Tab>` | Next buffer |
| `te` | Open new tab |
| `hs` | Horizontal split |
| `vs` | Vertical split |
| `<leader>vr` | Rename variable (LSP) |
| `<leader>p` | Paste without replacing the default register |
| `<leader>up` | Toggle "performance mode" for large files (disables relativenumber, cursorline, treesitter-context, ufo) |

## Visual mode

| Key | Action |
| --- | --- |
| `<leader>fs` | Format range |
| `<leader>p` | Paste without replacing the default register |

## Insert mode

| Key | Action |
| --- | --- |
| `<C-j>` | Exit insert mode and open a new line below (`<Esc>o`) |

## Terminal mode

| Key | Action |
| --- | --- |
| `<Esc>` | Exit terminal mode |

## Commands

| Command | Action |
| --- | --- |
| `:TOhtml` | Render the current buffer to HTML and save it to `~/Downloads/<file>-ShareBySefat.html` |

## VS Code (`vim.g.vscode`)

When running inside the [VSCode Neovim extension](https://github.com/vscode-neovim/vscode-neovim),
a separate set of keymaps forwards to VS Code commands instead:

| Key | Action |
| --- | --- |
| `<leader>t` | Toggle terminal |
| `<leader>b` | Toggle breakpoint |
| `<leader>d` | Show hover |
| `<leader>a` | Quick fix |
| `<leader>sp` | Show problems panel |
| `<leader>cn` | Clear all notifications |
| `<leader>ff` | Quick open |
| `<leader>cp` | Show command palette |
| `<leader>pr` | Run code (Code Runner) |
| `<leader>fd` | Format document |

The buffer/split keymaps (`<S-Tab>`, `<Tab>`, `te`, `hs`, `vs`) and the `zR`/`zM`
fold keymaps are skipped in VS Code mode, since those rely on plugins that
aren't loaded there.
