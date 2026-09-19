#!/bin/bash

set -euo pipefail

BREWFILE="brew/Brewfile"
STOW_ROOT="stow-packages"
STOW_PACKAGES=("shell" "editor" "git")
GIT_HOOKS_DIR="git/hooks"

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

ensure_git_hooks() {
    local root="$1"
    local hooks="$GIT_HOOKS_DIR"

    # core.hooksPath lives in .git/config, which is never version-controlled —
    # so a fresh clone has to be re-pointed at git/hooks here.
    if [ ! -d "$root/$hooks" ]; then
        return
    fi
    if ! git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
        warn "Not a git repo: $root (skipping hooks)"
        return
    fi

    info "Wiring git hooks..."
    chmod +x "$root/$hooks"/* 2>/dev/null || true
    git -C "$root" config core.hooksPath "$hooks"
    success "Git hooks wired to $hooks"
}

# --- Declarative per-tool install recipes -----------------------------------
#
# A tool that needs more than a plain `stow` symlink (a link outside $HOME's
# stowed tree, or a one-off command after linking) declares it in its own
# <tool>/install.conf instead of getting a bespoke ensure_<tool>() function
# here. One line per directive:
#
#   PLATFORM darwin              # optional; restricts the whole file to an OS
#   LINK <src> -> <dest>         # src is relative to the tool's own dir
#   POST <shell command>         # run with CWD set to the tool's own dir
#
# See readme.md ("Adding a new tool") for the full convention.

_dotfiles_os() {
    case "$(uname -s)" in
        Darwin) echo darwin ;;
        Linux) echo linux ;;
        *) echo other ;;
    esac
}

_apply_declared_link() {
    local tool="$1" dir="$2" spec="$3"
    local src="${spec%% -> *}"
    local dest="${spec#* -> }"
    dest="${dest/#\~/$HOME}"
    local abs_src="$dir/$src"

    if [ ! -e "$abs_src" ]; then
        warn "$tool: install.conf points at missing $abs_src"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        warn "$tool: existing $dest left alone (back it up and re-run)"
        return
    fi
    ln -sfn "$abs_src" "$dest"
    success "$tool: linked $dest"
}

apply_declared_installs() {
    local root="$1"
    local conf dir tool platform line directive rest

    for conf in "$root"/*/install.conf; do
        [ -f "$conf" ] || continue
        dir="$(dirname "$conf")"
        tool="$(basename "$dir")"
        platform=""

        while IFS= read -r line || [ -n "$line" ]; do
            line="${line%%#*}"
            line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            [ -z "$line" ] && continue

            directive="${line%% *}"
            rest="${line#* }"

            case "$directive" in
                PLATFORM)
                    platform="$rest"
                    ;;
                LINK)
                    if [ -n "$platform" ] && [ "$platform" != "$(_dotfiles_os)" ]; then
                        continue
                    fi
                    _apply_declared_link "$tool" "$dir" "$rest"
                    ;;
                POST)
                    if [ -n "$platform" ] && [ "$platform" != "$(_dotfiles_os)" ]; then
                        continue
                    fi
                    info "Running $tool post-install..."
                    (cd "$dir" && eval "$rest")
                    success "$tool post-install done."
                    ;;
                *)
                    warn "$conf: unknown install.conf directive '$directive'"
                    ;;
            esac
        done < "$conf"
    done
}

main() {
    local root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    ensure_homebrew
    apply_brew_bundle "$root/$BREWFILE"
    apply_stow "$root/$STOW_ROOT" "${STOW_PACKAGES[@]}"
    ensure_git_hooks "$root"
    apply_declared_installs "$root"

    echo -e "\n${GREEN}✨ Setup complete!${NC}"
    info "Restart terminal or run 'source ~/.zshrc'"
}

# Sourceable (see setup-validate.sh) without running main — only executes
# when the script is run directly, not when it's sourced for its functions.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
