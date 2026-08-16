#!/usr/bin/env bash
# Tests for check-portability.sh, driven off temp-dir fixtures so the tests
# never depend on the repo's current cleanliness.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/test-helpers.sh"

GUARD="$HERE/check-portability.sh"

fixture() {
    local dir
    dir="$(mktemp -d)"
    mkdir -p "$dir/stow-packages/shell"
    printf '%s' "$dir"
}

echo "check-portability.sh"

# --- clean tree passes ---
d="$(fixture)"
printf 'export EDITOR="nvim"\n' > "$d/stow-packages/shell/.zshrc"
assert_exit 0 "clean tree passes" "$GUARD" "$d"
rm -rf "$d"

# --- hardcoded brew prefixes are caught ---
d="$(fixture)"
printf 'source /opt/homebrew/share/foo.zsh\n' > "$d/stow-packages/shell/.zshrc"
assert_exit 1 "catches /opt/homebrew in a stow package" "$GUARD" "$d"
rm -rf "$d"

d="$(fixture)"
printf 'source /home/linuxbrew/.linuxbrew/share/foo.zsh\n' > "$d/stow-packages/shell/.zshrc"
assert_exit 1 "catches /home/linuxbrew in a stow package" "$GUARD" "$d"
rm -rf "$d"

# --- platform.zsh is allowed to hold the real prefixes ---
d="$(fixture)"
mkdir -p "$d/zsh/.local/share/zsh"
printf 'BREW_PREFIX=/opt/homebrew\n' > "$d/zsh/.local/share/zsh/platform.zsh"
assert_exit 0 "allows brew prefix inside platform.zsh" "$GUARD" "$d"
rm -rf "$d"

# --- /Users/ paths are caught ---
d="$(fixture)"
printf 'export PATH="/Users/sefat/bin:$PATH"\n' > "$d/stow-packages/shell/.zshrc"
assert_exit 1 "catches /Users/ path" "$GUARD" "$d"
rm -rf "$d"

# --- allowlisted locations may contain /Users/ ---
d="$(fixture)"
mkdir -p "$d/.claude"
printf '{"permissions":["/Users/sefat/x"]}\n' > "$d/.claude/settings.local.json"
assert_exit 0 "allows /Users/ in .claude/settings.local.json" "$GUARD" "$d"
rm -rf "$d"

d="$(fixture)"
mkdir -p "$d/docs/superpowers/specs"
printf 'the old path was /Users/sefat/Desktop\n' > "$d/docs/superpowers/specs/x.md"
assert_exit 0 "allows /Users/ in docs/superpowers (specs quote old paths)" "$GUARD" "$d"
rm -rf "$d"

# docs/superpowers is exempt from EVERY rule, not just the /Users/ one - the
# spec and plan quote brew prefixes and OS tags too. Without this the guard
# flags its own design documents.
d="$(fixture)"
mkdir -p "$d/docs/superpowers/specs"
printf 'example: source /opt/homebrew/x #For MacOS\n' > "$d/docs/superpowers/specs/x.md"
assert_exit 0 "docs/superpowers is exempt from all rules" "$GUARD" "$d"
rm -rf "$d"

# --- comment/uncomment tags are caught ---
d="$(fixture)"
printf '# source /some/path #For MacOS\n' > "$d/stow-packages/shell/.zshrc"
assert_exit 1 "catches '#For MacOS' tag" "$GUARD" "$d"
rm -rf "$d"

d="$(fixture)"
printf '# For Ubuntu\nexport X=1\n' > "$d/stow-packages/shell/.zshrc"
assert_exit 1 "catches '# For Ubuntu' tag" "$GUARD" "$d"
rm -rf "$d"

finish
