#!/bin/bash
# migrate-to-stow.sh - Safely migrate from manual symlinks to Stow

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${CYAN}🚀 Starting migration from manual symlinks to Stow...${NC}"

# 1. Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}✅ Checking prerequisites...${NC}"
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo -e "${RED}❌ Dotfiles directory not found: $DOTFILES_DIR${NC}"
        exit 1
    fi
    
    if ! command -v stow &> /dev/null; then
        echo -e "${YELLOW}Installing GNU Stow...${NC}"
        brew install stow
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# 2. Run comprehensive scan
run_scan() {
    echo -e "${BLUE}🔍 Scanning current symlink setup...${NC}"
    "$DOTFILES_DIR/scripts/helpers/scan-symlinks.sh" scan
}

# 3. Create backup and remove old symlinks
backup_and_remove() {
    echo -e "${BLUE}💾 Creating backup and removing old symlinks...${NC}"
    "$DOTFILES_DIR/scripts/helpers/scan-symlinks.sh" backup
    "$DOTFILES_DIR/scripts/helpers/scan-symlinks.sh" remove
}

# 4. Move configurations to Stow packages
move_to_stow_packages() {
    echo -e "${BLUE}📦 Moving configurations to Stow packages...${NC}"
    
    cd "$DOTFILES_DIR"
    
    # Move shell configurations
    if [[ -f "zsh/zshrc" ]]; then
        cp "zsh/zshrc" "stow-packages/shell/.zshrc"
        echo -e "${GREEN}  ✓ Moved zshrc${NC}"
    fi
    
    if [[ -f "zsh/zprofile" ]]; then
        cp "zsh/zprofile" "stow-packages/shell/.zprofile"
        echo -e "${GREEN}  ✓ Moved zprofile${NC}"
    fi
    
    if [[ -f "starship/starship.toml" ]]; then
        cp "starship/starship.toml" "stow-packages/shell/.config/starship/starship.toml"
        echo -e "${GREEN}  ✓ Moved starship config${NC}"
    fi
    
    # Move terminal configurations
    if [[ -f "tmux/tmux.conf" ]]; then
        cp "tmux/tmux.conf" "stow-packages/terminal/.tmux.conf"
        echo -e "${GREEN}  ✓ Moved tmux config${NC}"
    fi
    
    if [[ -f "p10k/p10k.zsh" ]]; then
        cp "p10k/p10k.zsh" "stow-packages/terminal/.p10k.zsh"
        echo -e "${GREEN}  ✓ Moved p10k config${NC}"
    fi
    
    if [[ -d "ghostty" ]]; then
        cp -r "ghostty"/* "stow-packages/terminal/.config/ghostty/"
        echo -e "${GREEN}  ✓ Moved ghostty config${NC}"
    fi
    
    # Move editor configurations
    if [[ -d "nvim" ]]; then
        cp -r "nvim" "stow-packages/editor/.config/"
        echo -e "${GREEN}  ✓ Moved nvim config${NC}"
    fi
    
    # Move desktop configurations
    if [[ -d "aerospace" ]]; then
        cp -r "aerospace" "stow-packages/desktop/.config/"
        echo -e "${GREEN}  ✓ Moved aerospace config${NC}"
    fi
    
    if [[ -d "raycast" ]]; then
        cp -r "raycast" "stow-packages/desktop/.config/"
        echo -e "${GREEN}  ✓ Moved raycast config${NC}"
    fi
    
    # Move development configurations
    if [[ -f "git/gitconfig" ]]; then
        cp "git/gitconfig" "stow-packages/development/.gitconfig"
        echo -e "${GREEN}  ✓ Moved git config${NC}"
    fi
    
    if [[ -f "git/gitignore" ]]; then
        cp "git/gitignore" "stow-packages/development/.gitignore_global"
        echo -e "${GREEN}  ✓ Moved git ignore${NC}"
    fi
    
    if [[ -d "git/hooks" ]]; then
        cp -r "git/hooks" "stow-packages/development/.local/share/git/"
        echo -e "${GREEN}  ✓ Moved git hooks${NC}"
    fi
    
    if [[ -d "mcp" ]]; then
        cp -r "mcp" "stow-packages/development/.config/"
        echo -e "${GREEN}  ✓ Moved mcp config${NC}"
    fi
    
    # Move system configurations
    if [[ -d "macos" ]]; then
        cp -r "macos" "stow-packages/system/.config/"
        echo -e "${GREEN}  ✓ Moved macOS config${NC}"
    fi
    
    echo -e "${GREEN}✅ Configuration files moved to Stow packages${NC}"
}

# 5. Create modular zsh configuration
create_modular_zsh() {
    echo -e "${BLUE}🔧 Creating modular zsh configuration...${NC}"
    
    # Read current zshrc
    if [[ -f "$DOTFILES_DIR/stow-packages/shell/.zshrc" ]]; then
        # Create modular files
        cat > "$DOTFILES_DIR/stow-packages/shell/.local/share/zsh/exports.zsh" << 'EOF'
# exports.zsh - Environment variables and PATH modifications

export LANG=en_US.UTF-8

# Homebrew
export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"

# Go configuration
export GOROOT=$(ls -d /opt/homebrew/Cellar/go/*/libexec | tail -n 1)
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PNPM
export PNPM_HOME="/Users/sefat/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# NVM setup
export NVM_DIR=~/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [[ $- == *i* ]]; then
  nvm use default > /dev/null
fi

# Bit
case ":$PATH:" in
  *":/Users/sefat/bin:"*) ;;
  *) export PATH="$PATH:/Users/sefat/bin" ;;
esac

# OpenCode
export PATH=/Users/sefat/.opencode/bin:$PATH
export EDITOR="nvim"
EOF

        cat > "$DOTFILES_DIR/stow-packages/shell/.local/share/zsh/aliases.zsh" << 'EOF'
# aliases.zsh - All command aliases

# Directory navigation
alias cdd='cd_to_dir ~/Documents/'
alias cds='cd_to_dir'

# Enhanced ls
alias es='eza -alF --color=always --sort=size | grep -v /'

# Applications
alias n='nvim'
alias g='lazygit'

# Zsh management
alias reload-zsh="source ~/.zshrc"
alias edit-zsh="nvim ~/.zshrc"

# Git aliases
alias gs='git status'
alias gp='git pull --rebase'
alias gP='git push'
alias gc='git commit -m'
alias grh='git reset --hard'
alias gts='git stash'
alias gtp='git stash pop'
alias gl='git log --oneline'
alias gcn='git config --local user.name "$GIT_NAME"'
alias gce='git config --local user.email "$GIT_EMAIL"'
alias gcl='gce && gcn'
alias gcll='git config --local --list'
alias grp="git remote prune origin"

# Tmux aliases
alias t='tmux'
alias ta='tmux attach -t'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias ts='tmux switch -t'
alias td='tmux detach'

# NPM aliases
alias ns="npm start"
alias nd="npm run dev"

# Utility aliases
alias cat="glow"
alias c='clear'
alias e='exit'

# GitHub aliases
alias gh-create='gh repo create --private --source=. --remote=origin && git push -u --all && gh browse'

# GitHub Copilot aliases
alias ghca="gh extension install github/gh-copilot"
alias ghcs="gh copilot suggest"
alias ghce="gh copilot explain"
alias ghcup="gh extension upgrade gh-copilot"
EOF

        cat > "$DOTFILES_DIR/stow-packages/shell/.local/share/zsh/functions.zsh" << 'EOF'
# functions.zsh - Custom shell functions

# Enhanced directory navigation with fzf
cd_to_dir() {
    local selected_dir
    selected_dir=$(fd -t d . "$1" | fzf +m --height 50% --preview 'tree -C {}')
    if [[ -n "$selected_dir" ]]; then
        cd "$selected_dir" || return 1
    fi
}

# Yazi file manager integration
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Video optimization with ffmpeg
optimize() {
    if [ -z "$1" ]; then
        echo "Usage: optimize /path/to/video"
        return 1
    fi

    local input_video="$1"
    local filename_without_ext="${input_video%.*}"
    local output_video="${filename_without_ext}_optimized.mov"

    ffmpeg -i "$input_video" -vf scale=1280:720 "$output_video"

    echo "✅ Optimized video saved as: $output_video"
}

# Angular project creation
function ngnew() {
    if [[ $# -eq 1 ]]; then
        local app_name=$1
        npx -p @angular/cli@latest ng new "$app_name" --package-manager=pnpm --skip-install --skip-tests
    elif [[ $# -eq 2 ]]; then
        local version=$1
        local app_name=$2
        npx -p @angular/cli@$version ng new "$app_name" --package-manager=pnpm --skip-install --skip-tests
    else
        echo "Usage: ngnew [app-name] or ngnew [version] [app-name]"
    fi
}
EOF

        cat > "$DOTFILES_DIR/stow-packages/shell/.local/share/zsh/completions.zsh" << 'EOF'
# completions.zsh - Shell completions and initialization

# Bun completions
[ -s "/Users/sefat/.bun/_bun" ] && source "/Users/sefat/.bun/_bun"

# Zoxide initialization
eval "$(zoxide init zsh)"

# Atuin initialization (without ctrl-r)
eval "$(atuin init zsh --disable-ctrl-r)"

# X-cmd initialization
[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X"
EOF

        # Create new modular zshrc
        cat > "$DOTFILES_DIR/stow-packages/shell/.zshrc" << 'EOF'
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
EOF

        echo -e "${GREEN}✅ Created modular zsh configuration${NC}"
    fi
}

# Main migration workflow
main() {
    echo -e "${CYAN}🚀 Dotfiles Migration to Stow${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    check_prerequisites
    run_scan
    
    echo -e "\n${YELLOW}⚠️  This will:${NC}"
    echo -e "${YELLOW}   1. Create a backup of your current setup${NC}"
    echo -e "${YELLOW}   2. Remove all existing dotfiles symlinks${NC}"
    echo -e "${YELLOW}   3. Move configurations to Stow packages${NC}"
    echo -e "${YELLOW}   4. Create modular configuration files${NC}"
    
    read -p "Continue with migration? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Migration cancelled.${NC}"
        return 0
    fi
    
    backup_and_remove
    move_to_stow_packages
    create_modular_zsh
    
    echo -e "\n${GREEN}✅ Migration completed successfully!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${GREEN}1. Run 'make install' to setup with Stow${NC}"
    echo -e "${GREEN}2. Restart your terminal or run 'source ~/.zshrc'${NC}"
    echo -e "${GREEN}3. Test your configuration${NC}"
    echo -e "${BLUE}4. If needed, restore with the backup script${NC}"
}

main "$@"