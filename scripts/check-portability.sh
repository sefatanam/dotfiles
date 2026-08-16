#!/usr/bin/env bash
# check-portability.sh - fails if OS-specific literals leak into shared config.
#
# This is the regression guard for the cross-platform dotfiles design. Making
# the repo work on both platforms once is easy; this is what stops it drifting
# back into commented-out OS blocks.
#
# Usage: scripts/check-portability.sh [ROOT]
#   ROOT defaults to the repo root. Passing it explicitly (as the tests do)
#   also skips the $HOME stow checks, which are meaningless against a fixture.
set -uo pipefail

if [[ $# -ge 1 ]]; then
    ROOT="$1"
    CHECK_HOME=0
else
    ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    CHECK_HOME=1
fi

violations=0

report() {
    violations=$((violations + 1))
    printf '  VIOLATION: %s\n' "$1"
}

# Exempt from ALL rules. These files necessarily contain the very patterns the
# guard hunts for:
#   docs/superpowers/     - the design spec and this plan quote old paths, brew
#                           prefixes, and "#For MacOS" tags as examples. Without
#                           this the guard flags its own design documents.
#   .superpowers/         - similarly contains superpowers design docs and progress.
#   scripts/*portability* - the guard and its tests contain the patterns literally.
is_exempt_all() {
    case "$1" in
        */docs/superpowers/*)                return 0 ;;
        */.superpowers/*)                    return 0 ;;
        */scripts/check-portability.sh)      return 0 ;;
        */scripts/test-check-portability.sh) return 0 ;;
        *) return 1 ;;
    esac
}

# Paths permitted to hold a hardcoded Homebrew prefix. These are the only places
# that must know the real paths: the shell's platform detection, and the two
# installers, which run before any shell config is loaded.
is_brew_allowed() {
    case "$1" in
        */zsh/.local/share/zsh/platform.zsh) return 0 ;;
        */setup.sh)                          return 0 ;;
        */bash-install.sh)                   return 0 ;;
        *) return 1 ;;
    esac
}

# Paths permitted to hold /Users/ strings:
#   .claude/settings.local.json - machine-local tool state, not dotfile config.
#                                 Also gitignored as of Task 5.
is_users_allowed() {
    case "$1" in
        */.claude/settings.local.json) return 0 ;;
        *) return 1 ;;
    esac
}

while IFS= read -r file; do
    is_exempt_all "$file" && continue

    if grep -qE '/opt/homebrew|/home/linuxbrew' "$file" 2>/dev/null; then
        is_brew_allowed "$file" || report "hardcoded brew prefix: ${file#"$ROOT"/}"
    fi
    if grep -q '/Users/' "$file" 2>/dev/null; then
        is_users_allowed "$file" || report "hardcoded /Users/ path: ${file#"$ROOT"/}"
    fi
    if grep -qiE '#[[:space:]]*for[[:space:]]+(macos|mac|linux|ubuntu)\b' "$file" 2>/dev/null; then
        report "comment/uncomment OS tag: ${file#"$ROOT"/}"
    fi
done < <(find "$ROOT" -type f \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/themes/*' 2>/dev/null)

# Both OS packages stowed at once means conflicting symlinks in $HOME.
if [[ $CHECK_HOME -eq 1 ]]; then
    count_links_into() {
        local pkg="$1" n=0 link target
        while IFS= read -r link; do
            target="$(readlink "$link" 2>/dev/null || true)"
            case "$target" in *"stow-packages/$pkg/"*) n=$((n + 1)) ;; esac
        done < <(find "$HOME" "$HOME/.config" -maxdepth 2 -type l 2>/dev/null)
        printf '%s' "$n"
    }
    darwin_links="$(count_links_into os-darwin)"
    linux_links="$(count_links_into os-linux)"
    if [[ "$darwin_links" -gt 0 && "$linux_links" -gt 0 ]]; then
        report "both os-darwin and os-linux are stowed into \$HOME"
    fi
fi

if [[ $violations -eq 0 ]]; then
    printf 'check-portability: clean\n'
    exit 0
fi
printf '\ncheck-portability: %d violation(s)\n' "$violations"
exit 1
