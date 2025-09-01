# exports.zsh - Environment variables and PATH modifications

export LANG=en_US.UTF-8

# Cache PATH modifications for ultra-fast startup
if [[ ! -f "$HOME/.cache/zsh-path.cache" ]] || [[ "$HOME/.cache/zsh-path.cache" -ot "$0" ]]; then
    mkdir -p "$HOME/.cache"
    {
        echo "#Cached PATH configuration"
        echo "export DYLD_LIBRARY_PATH=\"/opt/homebrew/lib:\$DYLD_LIBRARY_PATH\""
        echo "export GOROOT=\"/opt/homebrew/lib/go\""
        echo "export GOPATH=\$HOME/go"
        echo "export BUN_INSTALL=\"\$HOME/.bun\""
        echo "export PNPM_HOME=\"/Users/sefat/Library/pnpm\""
        echo "export NVM_DIR=~/.nvm"
        echo "export EDITOR=\"nvim\""
        
        # Build optimized PATH
        local NEW_PATH="/opt/homebrew/lib/go/bin:\$HOME/go/bin:\$HOME/.bun/bin:/Users/sefat/Library/pnpm:/Users/sefat/bin:/Users/sefat/.opencode/bin:\$PATH"
        echo "export PATH=\"$NEW_PATH\""
    } > "$HOME/.cache/zsh-path.cache"
fi
source "$HOME/.cache/zsh-path.cache"

# Ultra-fast lazy loading functions
nvm() {
    unset -f nvm npm node npx
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm "$@"
}

# Single lazy loader for all Node tools
for cmd in npm node npx; do
    eval "$cmd() { nvm > /dev/null; $cmd \"\$@\"; }"
done