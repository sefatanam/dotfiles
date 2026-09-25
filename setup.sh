#!/bin/bash

set -euo pipefail

BREWFILE="brew/Brewfile"
STOW_ROOT="stow-packages"
STOW_PACKAGES=("shell" "editor" "git")
GIT_HOOKS_DIR="git/hooks"

DRY_RUN=0
FORCE_YES=0

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()    { echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

# Gate for anything that reaches outside the repo (installs/upgrades
# packages, mainly). Dry-run always passes without running the command;
# --yes/-y always passes; otherwise it prompts, and — critically — refuses
# by default when stdin isn't a terminal, so a non-interactive invocation
# (a script, a copy-pasted one-liner piped in, an agent) can't silently
# trigger a real package sync.
confirm_or_abort() {
    local prompt="$1"
    [ "$DRY_RUN" -eq 1 ] && return 0
    [ "$FORCE_YES" -eq 1 ] && return 0
    if [ ! -t 0 ]; then
        warn "Not an interactive terminal — skipping: $prompt (pass --yes to run non-interactively, or --dry-run to preview)"
        return 1
    fi
    local reply
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            info "[dry-run] Would install Homebrew."
            return
        fi
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew ready."
}

apply_brew_bundle() {
    local path="$1"
    [ -f "$path" ] || return

    if [ "$DRY_RUN" -eq 1 ]; then
        info "[dry-run] Would sync Brewfile: $path"
        command -v brew >/dev/null 2>&1 && brew bundle check --file="$path" --verbose || true
        return
    fi
    if ! confirm_or_abort "Install/upgrade Homebrew packages from $path?"; then
        return
    fi

    info "Syncing Brewfile: $path"
    brew install stow
    brew bundle --file="$path"
    success "Brew bundle synced."
}

apply_stow() {
    local root="$1"
    shift
    local pkgs=("$@")

    info "Syncing Symlinks..."
    cd "$root"
    for pkg in "${pkgs[@]}"; do
        if [ -d "$pkg" ]; then
            # An empty array expanded under `set -u` is an "unbound variable"
            # error on bash 3.2 (macOS's /bin/bash, what the shebang runs) —
            # branch explicitly instead of building a conditional flags array.
            if [ "$DRY_RUN" -eq 1 ]; then
                stow -n -t "$HOME" -D "$pkg" 2>/dev/null || true
                stow -n -t "$HOME" "$pkg"
                success "Would stow $pkg (dry-run)"
            else
                stow -t "$HOME" -D "$pkg" 2>/dev/null || true
                stow -t "$HOME" "$pkg"
                success "Stowed $pkg"
            fi
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
    if [ "$DRY_RUN" -eq 1 ]; then
        info "[dry-run] Would wire git hooks to $hooks"
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

# Strips comments and leading/trailing whitespace from one install.conf line.
# Shared with setup-validate.sh's static check, so the parsing rules only
# live in one place.
_install_conf_normalize() {
    local line="$1"
    line="${line%%#*}"
    printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
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
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        warn "$tool: existing $dest left alone (back it up and re-run)"
        return
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        info "[dry-run] $tool: would link $dest -> $abs_src"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$abs_src" "$dest"
    success "$tool: linked $dest"
}

apply_declared_installs() {
    local root="$1"
    local conf dir tool platform raw line directive rest

    for conf in "$root"/*/install.conf; do
        [ -f "$conf" ] || continue
        dir="$(dirname "$conf")"
        tool="$(basename "$dir")"
        platform=""

        while IFS= read -r raw || [ -n "$raw" ]; do
            line="$(_install_conf_normalize "$raw")"
            [ -z "$line" ] && continue

            directive="${line%% *}"
            rest="${line#* }"

            case "$directive" in
                PLATFORM)
                    platform="$rest"
                    ;;
                LINK|POST)
                    if [ -n "$platform" ] && [ "$platform" != "$(_dotfiles_os)" ]; then
                        continue
                    fi
                    if [ "$directive" = "LINK" ]; then
                        _apply_declared_link "$tool" "$dir" "$rest"
                    elif [ "$DRY_RUN" -eq 1 ]; then
                        info "[dry-run] $tool: would run POST: $rest"
                    else
                        info "Running $tool post-install..."
                        (cd "$dir" && eval "$rest")
                        success "$tool post-install done."
                    fi
                    ;;
                *)
                    warn "$conf: unknown install.conf directive '$directive'"
                    ;;
            esac
        done < "$conf"
    done
}

# --- Post-setup reminders ---------------------------------------------------
#
# The steps setup.sh deliberately cannot do: anything that is a secret (SSH
# keys are never committed) or a path that only exists on one machine. Rather
# than a static checklist that rots, each check reads the *current* config and
# reports only what is actually missing on THIS machine — so a fully set-up
# box prints nothing but a clean bill of health.

REMINDERS=()
remind() { REMINDERS+=("$1"); }

# Every signingkey referenced by the git configs (the global one plus any
# conditional include, e.g. git/gitconfig.gitlab), with ~ expanded.
_declared_signing_keys() {
    local root="$1"
    grep -h '^[[:space:]]*signingkey' "$root"/git/gitconfig "$root"/git/gitconfig.* 2>/dev/null \
        | sed -e 's/.*=[[:space:]]*//' -e "s|^~|$HOME|" \
        | sort -u
}

# Every gitdir: path a live (non-commented) includeIf is scoped to.
_declared_includeif_dirs() {
    local root="$1"
    grep -h '^[[:space:]]*\[includeIf' "$root"/git/gitconfig 2>/dev/null \
        | grep -o 'gitdir:[^"]*' \
        | sed -e 's/^gitdir://' -e "s|^~|$HOME|" \
        | sort -u
}

collect_reminders() {
    local root="$1"
    local key dir loaded=0

    # SSH signing keys: referenced by gitconfig, never committed. Without
    # them every commit fails outright, since commit.gpgsign is global.
    while IFS= read -r key; do
        [ -z "$key" ] && continue
        if [ ! -f "$key" ]; then
            remind "Missing SSH signing key: $key
      Referenced by git/gitconfig*. commit.gpgsign is on globally, so commits
      will fail until it exists. Copy it (and its private half) from the old
      machine, or: ssh-keygen -t ed25519 -f ${key%.pub} && add the .pub to GitHub/GitLab"
        elif [ ! -f "${key%.pub}" ]; then
            remind "Public key present but private half missing: ${key%.pub}
      Signing needs both. Copy the private key over with mode 600."
        fi
    done <<EOF
$(_declared_signing_keys "$root")
EOF

    # allowed_signers: only affects verification, not signing, so it warns
    # separately rather than as part of the key check above.
    if [ ! -f "$HOME/.ssh/allowed_signers" ]; then
        remind "Missing ~/.ssh/allowed_signers (gpg.ssh.allowedSignersFile)
      Signing still works; 'git log --show-signature' can't verify without it.
      One 'email ssh-ed25519 AAAA...' line per key you sign with."
    fi

    # An agent with no identities means a passphrase prompt on every commit,
    # which is also what lazygit's overrideGpg assumes away.
    if ssh-add -l >/dev/null 2>&1; then loaded=1; fi
    if [ "$loaded" -eq 0 ] && [ -n "$(_declared_signing_keys "$root")" ]; then
        remind "No keys loaded in ssh-agent
      Load each signing key once so there's no passphrase prompt per commit:
      ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
    fi

    # A conditional identity scoped to a directory that doesn't exist here is
    # the silent failure mode: no error, commits just use the wrong identity.
    while IFS= read -r dir; do
        [ -z "$dir" ] && continue
        if [ ! -d "$dir" ]; then
            remind "includeIf path does not exist: $dir
      git/gitconfig switches identity for repos under it. Until it exists (or
      you repoint the includeIf), repos there silently use the default identity."
        fi
    done <<EOF
$(_declared_includeif_dirs "$root")
EOF

    # Gitignored files with committed templates.
    if [ ! -f "$root/zsh/.local/share/zsh/local.zsh" ]; then
        remind "Missing zsh/.local/share/zsh/local.zsh (gitignored: network/client details)
      cp zsh/.local/share/zsh/local.zsh.example zsh/.local/share/zsh/local.zsh"
    fi
    if [ ! -f "$root/zsh/private" ]; then
        remind "Missing zsh/private (secrets/API keys, scrubbed by the commit hooks)
      Create it with 'export KEY=value' lines. See git/README.md §6."
    fi
}

print_reminders() {
    local root="$1"
    collect_reminders "$root"

    echo
    if [ "${#REMINDERS[@]}" -eq 0 ]; then
        success "Manual steps: nothing outstanding — keys, agent and local files all present."
        return
    fi

    warn "Manual steps setup.sh can't do (secrets and machine-specific paths):"
    local item
    for item in "${REMINDERS[@]}"; do
        echo -e "    ${YELLOW}•${NC} $item"
        echo
    done
    info "See readme.md \"Manual steps on a new machine\" and git/SIGNING.md."
}

usage() {
    cat <<EOF
Usage: setup.sh [--dry-run] [--yes]

  --dry-run, -n   Show what would change without changing anything
                  (stow runs with -n; the Brewfile sync is replaced by
                  a read-only 'brew bundle check').
  --yes, -y       Skip the confirmation before installing/upgrading
                  Homebrew packages (for non-interactive runs).
  --help, -h      Show this message.
EOF
}

main() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run|-n) DRY_RUN=1 ;;
            --yes|-y) FORCE_YES=1 ;;
            --help|-h) usage; exit 0 ;;
            *) warn "Unknown argument: $arg (see --help)"; exit 1 ;;
        esac
    done

    local root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    ensure_homebrew
    apply_brew_bundle "$root/$BREWFILE"
    apply_stow "$root/$STOW_ROOT" "${STOW_PACKAGES[@]}"
    ensure_git_hooks "$root"
    apply_declared_installs "$root"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "\n${BLUE}🔍 Dry run complete — nothing was changed.${NC}"
    else
        echo -e "\n${GREEN}✨ Setup complete!${NC}"
        info "Restart terminal or run 'source ~/.zshrc'"
    fi

    # Read-only checks, so they run in dry-run too — this is the one part of
    # setup.sh whose whole job is to tell you what it *didn't* do.
    print_reminders "$root"
}

# Sourceable (see setup-validate.sh) without running main — only executes
# when the script is run directly, not when it's sourced for its functions.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
