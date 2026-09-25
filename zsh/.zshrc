#!/bin/zsh
export LANG=en_US.UTF-8

ZSH_CONFIG_DIR="$HOME/.local/share/zsh"

_source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

_source_if_exists "$ZSH_CONFIG_DIR/exports.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/aliases.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/local.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/functions.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/completions.zsh"

[[ -f "$HOME/.dotfiles/zsh/private" ]] && source "$HOME/.dotfiles/zsh/private"


# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/opt/zinit/zinit.zsh

# deja setup start
if [[ -r "$HOME/.local/share/deja/init.zsh" ]]; then
  source "$HOME/.local/share/deja/init.zsh"
else
  eval "$(deja init zsh)"
fi

zinit ice wait"0" lucid depth=1 pick"deja.plugin.zsh"
zinit light Giammarco-Ferranti/deja
#deja setup end

eval "$(starship init zsh)"
