#!/bin/zsh
# .zshrc - Main zsh configuration (sources modular components)
export LANG=en_US.UTF-8

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh

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

source $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# @REVIEW: Clean up helper functions
unset -f _compile_zsh_file _source_compiled