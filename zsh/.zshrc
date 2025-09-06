#!/bin/zsh
# .zshrc - Main zsh configuration (sources modular components)
export LANG=en_US.UTF-8

# @NOT-NEED: p10k instant prompt (disabled for starship migration)
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# @NOT-NEED: oh-my-zsh configuration (disabled for starship migration)
# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="powerlevel10k/powerlevel10k"
# plugins=(git)
# source $ZSH/oh-my-zsh.sh

ZSH_CONFIG_DIR="$HOME/.local/share/zsh"

_compile_zsh_file() {
    local file="$1"
    [[ -f "$file" && ( ! -f "${file}.zwc" || "$file" -nt "${file}.zwc" ) ]] && zcompile "$file"
}

_source_compiled() {
    local file="$1"
    if [[ -f "$file" ]]; then
        _compile_zsh_file "$file"
        source "$file"
    fi
}

_source_compiled "$ZSH_CONFIG_DIR/exports.zsh"
_source_compiled "$ZSH_CONFIG_DIR/aliases.zsh"
_source_compiled "$ZSH_CONFIG_DIR/functions.zsh"
_source_compiled "$ZSH_CONFIG_DIR/completions.zsh"

[[ -f ~/.private ]] && _source_compiled ~/.private
[[ -f "$HOME/.dotfiles/zsh/private" ]] && _source_compiled "$HOME/.dotfiles/zsh/private"

_compile_zsh_file ~/.zshrc

# @NOT-NEED: powerlevel10k theme loading (disabled for starship migration)
# source $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# zsh plugins
unset -f _compile_zsh_file _source_compiled
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# OpenJDK 21
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# Starship prompt
eval "$(starship init zsh)"
