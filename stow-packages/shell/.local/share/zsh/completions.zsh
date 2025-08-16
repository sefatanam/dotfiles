# completions.zsh - Shell completions and initialization

# Bun completions
[ -s "/Users/sefat/.bun/_bun" ] && source "/Users/sefat/.bun/_bun"

# Zoxide initialization
eval "$(zoxide init zsh)"

# Atuin initialization (without ctrl-r)
eval "$(atuin init zsh --disable-ctrl-r)"

# X-cmd initialization
[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X"