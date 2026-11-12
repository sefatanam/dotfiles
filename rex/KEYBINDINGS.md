# tmux → Rex (default keys)

How to do what you do in tmux using **Rex's stock keybindings**. No config is loaded, and `~/.config/rex/` stays empty.

Rex terms: tmux *window* = **tab**, tmux *pane* = **pane**, *session* = **session**. Rex's keys use `Cmd`, not a prefix, so there is nothing to press first.

## Sessions

| Task | tmux (yours) | Rex default |
|---|---|---|
| **List / switch sessions** | `Prefix Ctrl+J`, `Ctrl+↓` | `Cmd+K` (Change Session…) |
| **Create new session** | `Prefix Ctrl+N` | `Shift+Cmd+N` |
| Go to anything (tree) | `Ctrl+↑`, `Prefix w` | `Cmd+P` |
| Toggle sidebar | `Prefix Ctrl+B` | `Cmd+/` |
| Toggle activity panel | — | `Cmd+.` |
| Refresh sessions | — | `Cmd+R` |
| Rename / close / next / previous session | `Prefix $`, kill-session, `Prefix )` `(` | no key; use the command palette `Shift+Cmd+P` |
| Detach | `Prefix d` | not needed; the server keeps sessions alive |

CLI: `rex ls` lists sessions, `rex new NAME` creates one, `rex session rename`, `rex kill`.

## Tabs (tmux windows)

| Task | tmux (yours) | Rex default |
|---|---|---|
| New | `Prefix c` | `Cmd+T` |
| Next / previous | `Prefix n/p`, `Ctrl+→/←` | `Ctrl+Tab` / `Ctrl+Shift+Tab`, or `Shift+Cmd+]` / `Shift+Cmd+[` |
| Go to tab 1–9 | `Prefix 1`…`9` | `Cmd+1`…`Cmd+9` |
| Close | `Prefix &` | `Alt+Cmd+W` |
| Move left / right | `Prefix <` / `>` | `Ctrl+Shift+PageUp` / `PageDown` |
| Rename | `Prefix ,` | no key; palette |

## Panes

| Task | tmux (yours) | Rex default |
|---|---|---|
| Split side-by-side | `Prefix v` / `%` | `Cmd+D` |
| Split stacked | `Prefix s` / `"` | `Shift+Cmd+D` |
| Split in any direction | — | `Shift+Cmd+←/→/↑/↓` |
| Split best fit | — | `Cmd+Enter` |
| Focus left/down/up/right | `Prefix h/j/k/l`, `Shift+Arrows` | `Alt+Cmd+←/↓/↑/→` |
| Next / previous pane | `Prefix o` | `Cmd+]` / `Cmd+[` |
| Close pane | `Prefix x` | `Cmd+W` |
| Zoom | `Prefix z` | `Shift+Cmd+Enter` |
| Move pane | `Prefix {` / `}` | `Alt+Shift+Cmd+Arrows` |
| Floating pane (like a popup) | `display-popup` | `Alt+Cmd+Enter` (minimize: `Alt+Cmd+M`) |
| Resize | `Prefix Shift+Arrows` | no default key; mouse-drag, or palette |
| Balance splits | `Prefix Space` (approx.) | no key; palette |
| Break pane to tab | `Prefix b` | no key; palette (Move Pane to New Tab) |
| Join pane to another tab | `Prefix J` | no key; palette (Move Pane to Tab…) |
Okay now I come to a conclusion, to a point. Here in Rex by default, I don't have any key binding for now to resize the Rex pane so do it in a way 
## Copy mode and misc

| Task | tmux (yours) | Rex default |
|---|---|---|
| Search | `/` in copy mode | `Cmd+F`, next `Cmd+G`, previous `Shift+Cmd+G` |
| Jump between prompts | — | `Cmd+↑` / `Cmd+↓` |
| Copy / paste | `y`, `Prefix ]` | `Cmd+C` / `Cmd+V` (no vi copy-mode) |
| Command prompt | `Prefix :` | `Shift+Cmd+P` (command palette) |
| Reload config | `Prefix r` | no key; palette (Reload Config) or `rex config reload` |
| Font size | — | `Cmd+=` / `Cmd+-` / `Cmd+0` |
| Go to directory | — | `Shift+Cmd+G` |

Anything marked "palette" is reachable with `Shift+Cmd+P`.

## Without a Rex equivalent

Pane numbers, marked panes, last-pane (`;`) and last-window, tmux-resurrect/continuum (restore after reboot is unverified), vim-tmux-navigator, and popups that launch lazygit/yazi (floating panes exist, but I found no documented way to launch a program in one).

## Optional: tmux-style prefix

If you ever want `Ctrl+A` as a prefix, [`init.lua.tmux`](./init.lua.tmux) has it. **It is inactive.** Rex only reads `init.lua`, so nothing happens until you link it yourself:

```sh
ln -s ~/.dotfiles/rex/init.lua.tmux ~/.config/rex/init.lua && rex config reload
```

To go back to stock, remove `~/.config/rex/init.lua` and reload. The file adds only `Ctrl+A …` sequences and `Ctrl`/`Shift`+arrow keys, and overrides no Rex default. `rex config check` passed on it (68 bindings, no errors). I haven't tried it in the app.

Sources: [Mac Actions](https://www.superlogical.com/rex/docs/reference/mac-actions), [Key Sequences](https://www.superlogical.com/rex/docs/customize/key-sequences).
