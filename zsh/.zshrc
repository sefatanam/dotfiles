#!/bin/zsh
# .zshrc - Main zsh configuration (sources modular components)
export LANG=en_US.UTF-8

ZSH_CONFIG_DIR="$HOME/.local/share/zsh"

# @DISABLED: Auto-compilation - use zsh-recompile manually if needed
# _compile_zsh_file() {
#     local file="$1"
#     [[ -f "$file" && ( ! -f "${file}.zwc" || "$file" -nt "${file}.zwc" ) ]] && zcompile "$file"
# }

_source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

_source_if_exists "$ZSH_CONFIG_DIR/exports.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/aliases.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/functions.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/completions.zsh"

[[ -f ~/.private ]] && source ~/.private
[[ -f "$HOME/.dotfiles/zsh/private" ]] && source "$HOME/.dotfiles/zsh/private"

# zsh plugins
unset -f _source_if_exists
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

_load_syntax_highlighting() {
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    unset -f _load_syntax_highlighting
}
# Load after first prompt using precmd hook
_first_prompt_hook() {
    _load_syntax_highlighting
    # Remove this hook after first run
    add-zsh-hook -d precmd _first_prompt_hook
    unset -f _first_prompt_hook
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _first_prompt_hook

# OpenJDK 21
export JAVA_HOME="/opt/homebrew/opt/openjdk"
export PATH="$JAVA_HOME/bin:$PATH"

# export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
# export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# @REVIEW: Cached starship init for faster startup (like zoxide/atuin)
_starship_cache="$HOME/.cache/zsh-init/starship-init.zsh"
if [[ ! -f "$_starship_cache" ]] || [[ "$_starship_cache" -ot $(command -v starship) ]]; then
    mkdir -p "$HOME/.cache/zsh-init"
    starship init zsh > "$_starship_cache"
fi
source "$_starship_cache"
unset _starship_cache

# # Valdi configuration begin
# export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
# export JAVA_HOME=`/usr/libexec/java_home -v 11`
# export ANDROID_HOME="$HOME/.valdi/android_home"
# export ANDROID_NDK_HOME="$ANDROID_HOME/ndk-bundle"
# # Valdi configuration end

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/sefat/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/sefat/.lmstudio/bin"
# End of LM Studio CLI section

export PATH="$HOME/.local/bin:$PATH"
