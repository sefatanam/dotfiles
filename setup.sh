#!/bin/bash

set -euo pipefail

BREWFILE="brew/Brewfile"
STOW_ROOT="stow-packages"
STOW_PACKAGES=("shell" "editor")
PRIVATE_DIRS=("$HOME/.config/private")

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()    { echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

ensure_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew ready."
}

apply_brew_bundle() {
    local path="$1"
    if [ -f "$path" ]; then
        info "Syncing Brewfile: $path"
        brew install stow
        brew bundle --file="$path"
        success "Brew bundle synced."
    fi
}

apply_stow() {
    local root="$1"
    shift
    local pkgs=("$@")

    info "Syncing Symlinks..."
    cd "$root"
    for pkg in "${pkgs[@]}"; do
        if [ -d "$pkg" ]; then
            stow -t "$HOME" -D "$pkg" 2>/dev/null || true
            stow -t "$HOME" "$pkg"
            success "Stowed $pkg"
        fi
    done
    cd - > /dev/null
}

ensure_dirs() {
    local dirs=("$@")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            touch "$dir/.env"
            warn "Created $dir (add secrets to .env)"
        fi
    done
}
ensure_omp_config() {
    local root="$1"
    local config="$root/omp/agent/config.yml"
    local target="$HOME/.omp/agent/config.yml"
    if [ -f "$config" ]; then
        info "Linking OMP config..."
        mkdir -p "$(dirname "$target")"
        ln -sf "$config" "$target"
        success "OMP config linked."
    fi
}

main() {
    local root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    ensure_homebrew
    apply_brew_bundle "$root/$BREWFILE"
    apply_stow "$root/$STOW_ROOT" "${STOW_PACKAGES[@]}"
    ensure_dirs "${PRIVATE_DIRS[@]}"
    ensure_omp_config "$root"

    echo -e "\n${GREEN}✨ Setup complete!${NC}"
    info "Restart terminal or run 'source ~/.zshrc'"
}

main "$@"
