-- Rex config: tmux-style keys on a Ctrl+A prefix.
-- Additive only: every key below is unused by Rex's defaults (they all use cmd/ctrl+tab/etc.).
-- Link to ~/.config/rex/init.lua, then run: rex config check && rex config reload

local P = "ctrl+a>"

-- Prefix pass-through: Ctrl+A Ctrl+A sends a literal Ctrl+A (readline "home") to the terminal
rex.bind(P .. "ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Windows (Rex: tabs) ---------------------------------------------------------
rex.bind(P .. "c", "client.tab.new")
rex.bind(P .. "n", "client.tab.next")
rex.bind(P .. "p", "client.tab.previous")
rex.bind(P .. ",", "client.tab.rename")
rex.bind(P .. "shift+7", "client.tab.close")  -- &
rex.bind(P .. "shift+,", "client.tab.move.backward") -- <
rex.bind(P .. "shift+.", "client.tab.move.forward")  -- >
for i = 1, 9 do
  rex.bind(P .. tostring(i), "client.tab.goto", { index = i })
end
rex.bind("ctrl+left", "client.tab.previous")
rex.bind("ctrl+right", "client.tab.next")

-- Panes (Rex: blocks) ---------------------------------------------------------
rex.bind(P .. "v", "pane.split.right")
rex.bind(P .. "s", "pane.split.down")
rex.bind(P .. "shift+5", "pane.split.right")  -- %
rex.bind(P .. "shift+'", "pane.split.down")   -- "
rex.bind(P .. "h", "pane.focus.left")
rex.bind(P .. "j", "pane.focus.down")
rex.bind(P .. "k", "pane.focus.up")
rex.bind(P .. "l", "pane.focus.right")
rex.bind(P .. "o", "pane.focus_next")
rex.bind(P .. "x", "pane.close")
rex.bind(P .. "z", "pane.zoom")
rex.bind(P .. "space", "pane.balance")
rex.bind(P .. "shift+[", "pane.move.up")      -- {
rex.bind(P .. "shift+]", "pane.move.down")    -- }
rex.bind(P .. "b", "pane.move_to_new_tab")    -- break-pane
rex.bind(P .. "shift+1", "pane.move_to_new_tab") -- !
rex.bind(P .. "shift+j", "pane.move_to_tab")  -- join-pane
rex.bind("shift+left", "pane.focus.left")
rex.bind("shift+down", "pane.focus.down")
rex.bind("shift+up", "pane.focus.up")
rex.bind("shift+right", "pane.focus.right")

-- Resize: Ctrl+A r enters a mode (like tmux's repeatable -r binds); Enter/Esc leaves
rex.mode("resize", { exclusive = true })
rex.bind(P .. "r", "client.mode.enter", { name = "resize" })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right",
                        left = "left", down = "down", up = "up", right = "right" }) do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir, amount = 5 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")

-- Sessions --------------------------------------------------------------------
rex.bind(P .. "ctrl+n", "session.new")
rex.bind(P .. "ctrl+j", "session.switch")
rex.bind(P .. "shift+9", "session.previous")  -- (
rex.bind(P .. "shift+0", "session.next")      -- )
rex.bind(P .. "shift+4", "session.rename")    -- $
rex.bind(P .. "shift+x", "session.close")
rex.bind(P .. "w", "pane.go_to")
rex.bind("ctrl+down", "session.switch")
rex.bind("ctrl+up", "pane.go_to")

-- Copy mode / scrollback ------------------------------------------------------
rex.bind(P .. "[", "client.scroll.page_up")
rex.bind(P .. "]", "pane.paste")
rex.bind(P .. "/", "client.find.open")

-- Misc ------------------------------------------------------------------------
rex.bind(P .. "shift+r", "client.config.reload")
rex.bind(P .. "ctrl+b", "client.sidebar.toggle")
rex.bind(P .. "shift+;", "client.palette.toggle") -- :
rex.bind(P .. "shift+/", "client.palette.toggle") -- ?
rex.bind(P .. "f", "pane.float")
