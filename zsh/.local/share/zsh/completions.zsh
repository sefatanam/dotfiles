# completions.zsh - Shell completions and initialization

_zsh_init_cache="$HOME/.cache/zsh-init"
mkdir -p "$_zsh_init_cache"

if command -v bun >/dev/null 2>&1; then
    bun() {
        unset -f bun
        [ -s "/Users/anam/.bun/_bun" ] && source "/Users/anam/.bun/_bun"
        command bun "$@"
    }
fi

if command -v zoxide >/dev/null 2>&1; then
    _zoxide_cache="$_zsh_init_cache/zoxide-init.zsh"
    if [[ ! -f "$_zoxide_cache" ]] || [[ "$_zoxide_cache" -ot $(command -v zoxide) ]]; then
        zoxide init zsh > "$_zoxide_cache"
    fi
    source "$_zoxide_cache"
fi

if command -v atuin >/dev/null 2>&1; then
    _atuin_cache="$_zsh_init_cache/atuin-init.zsh"
    if [[ ! -f "$_atuin_cache" ]] || [[ "$_atuin_cache" -ot $(command -v atuin) ]]; then
        atuin init zsh --disable-ctrl-r > "$_atuin_cache"
    fi
    source "$_atuin_cache"
fi

[ -f "$HOME/.x-cmd.root/X" ] && source "$HOME/.x-cmd.root/X"

bindkey '^F' _directory_suggestion_widget

unset _zsh_init_cache _zoxide_cache _atuin_cache