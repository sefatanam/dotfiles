# Context

Glossary of the keybinding vocabulary used across this repo. Deliberately abstract:
these are *concepts*, not per-tool facts. Tool-specific naming quirks and bindings live in
[site/keybindings.html](site/keybindings.html), not here — keeping this file free of implementation
detail is what stops it turning into a second, worse copy of the keybindings reference.

## chord

A modifier key or keys held together with a base key, pressed as one gesture — `Cmd+C`,
`Ctrl+Alt+Delete`, `Alt+Shift+H`.

## keybinding

An explicit mapping from a chord (or key sequence) to an action, declared in some tool's
config. "When you press X, do Y."

## keymap

The set of keybindings in effect at a given moment. Keymaps layer: tmux has several key
tables, an editor has one per mode, and a prefix or leader key temporarily introduces
another.

## prefix

A chord that must precede a second key to reach a set of bindings. Pressing it enters a
temporary keymap layer; the next chord selects an action and the layer closes.

## leader

A prefix used to group an editor's non-mnemonic bindings under a leader chord, so the
mnemonic keys stay free.

## mode

A context with its own keymap. Tools that have them each invent their own set of modes,
and which bindings apply depends on the mode you are in.

## split

A window or pane divided into two regions. Orientation is described differently by
different tools, and the terms often invert between them — see the Gotchas section of
[site/keybindings.html](site/keybindings.html) rather than assuming.

## inherited keymap

A binding that works because the tool ships it by default, not because this repo
configures it. Such a binding disappears silently if the tool's defaults change, so the
keybindings reference marks them separately from ones declared here.

## keybindings reference

The page listing every keybinding, grouped by the layer that owns the key (window manager
outermost, shell innermost). Answers "what does this key do, and which tool catches it?"

## wiki

The page describing each tool on its own: what it is for, where its config lives, what
was changed, and that tool's keybindings. Answers "what is this tool and how is it set up?"
A tool's keybindings appear in both the wiki and the keybindings reference, and the two
always agree.

## transparent mode

A single on/off appearance setting for the whole terminal workflow. When on, the terminal
window is translucent and blurred, and every tool running inside it lets that background
show through instead of painting its own. When off, everything is opaque. It is one
switch for the whole workflow, never set per tool, and it applies to light and dark themes alike.
