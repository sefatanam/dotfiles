#!/bin/zsh
# .zshrc - Main zsh configuration (sources modular components)

export LANG=en_US.UTF-8

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Source modular configuration files
ZSH_CONFIG_DIR="$HOME/.local/share/zsh"
[[ -f "$ZSH_CONFIG_DIR/exports.zsh" ]] && source "$ZSH_CONFIG_DIR/exports.zsh"
[[ -f "$ZSH_CONFIG_DIR/aliases.zsh" ]] && source "$ZSH_CONFIG_DIR/aliases.zsh"
[[ -f "$ZSH_CONFIG_DIR/functions.zsh" ]] && source "$ZSH_CONFIG_DIR/functions.zsh"
[[ -f "$ZSH_CONFIG_DIR/completions.zsh" ]] && source "$ZSH_CONFIG_DIR/completions.zsh"

# Source private configuration if it exists
[[ -f ~/.private ]] && source ~/.private

# Source Powerlevel10k theme and configuration
source $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh