#!/bin/bash
# Validates the declarative install.conf convention (see setup.sh and
# readme.md "Adding a new tool"). Run this after adding or editing any
# install.conf. Touches only a throwaway sandbox $HOME, never the real one.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/setup.sh"  # safe: main() only runs when setup.sh is executed directly

fail=0
ok()   { echo "✅ $1"; }
bad()  { echo "❌ $1"; fail=1; }

# --- 1. Every real install.conf in the repo parses cleanly -----------------
for conf in "$ROOT"/*/install.conf; do
    [ -f "$conf" ] || continue
    tool="$(basename "$(dirname "$conf")")"
    while IFS= read -r raw || [ -n "$raw" ]; do
        line="$(_install_conf_normalize "$raw")"
        [ -z "$line" ] && continue
        directive="${line%% *}"
        case "$directive" in
            PLATFORM|LINK|POST) ;;
            *) bad "$tool/install.conf: unknown directive '$directive'" ;;
        esac
        if [ "$directive" = "LINK" ]; then
            rest="${line#* }"
            src="${rest%% -> *}"
            [ -e "$(dirname "$conf")/$src" ] || bad "$tool/install.conf: LINK source '$src' missing"
        fi
    done < "$conf"
done
[ "$fail" -eq 0 ] && ok "repo install.conf files parse and their LINK sources exist"

# --- 2. apply_declared_installs, exercised end to end against fixtures -----
sandbox="$(mktemp -d)"
fixtures="$(mktemp -d)"
trap 'rm -rf "$sandbox" "$fixtures"' EXIT

mkdir -p "$fixtures/widget"
echo "payload" > "$fixtures/widget/file.txt"
cat > "$fixtures/widget/install.conf" <<'EOF'
LINK file.txt -> ~/.widget/file.txt
POST touch post-ran.marker
EOF

mkdir -p "$fixtures/other-os-only"
echo "payload" > "$fixtures/other-os-only/file.txt"
cat > "$fixtures/other-os-only/install.conf" <<'EOF'
PLATFORM never-a-real-platform
LINK file.txt -> ~/.other-os-only/file.txt
EOF

mkdir -p "$fixtures/clobber-guard"
echo "payload" > "$fixtures/clobber-guard/file.txt"
mkdir -p "$sandbox/.clobber-guard"
echo "pre-existing real file, must survive" > "$sandbox/.clobber-guard/file.txt"
cat > "$fixtures/clobber-guard/install.conf" <<'EOF'
LINK file.txt -> ~/.clobber-guard/file.txt
EOF

real_home="$HOME"
HOME="$sandbox"
apply_declared_installs "$fixtures" >/dev/null
HOME="$real_home"

if [ -L "$sandbox/.widget/file.txt" ] && [ "$(cat "$sandbox/.widget/file.txt")" = "payload" ]; then
    ok "LINK creates a symlink to the declared source"
else
    bad "LINK did not create the expected symlink"
fi

if [ -f "$fixtures/widget/post-ran.marker" ]; then
    ok "POST runs with CWD set to the tool's own directory"
else
    bad "POST did not run (or ran with the wrong CWD)"
fi

if [ ! -e "$sandbox/.other-os-only" ]; then
    ok "PLATFORM gate skips LINK/POST on a non-matching platform"
else
    bad "PLATFORM gate failed to skip a non-matching platform"
fi

if [ "$(cat "$sandbox/.clobber-guard/file.txt")" = "pre-existing real file, must survive" ]; then
    ok "LINK leaves a pre-existing real file alone instead of clobbering it"
else
    bad "LINK clobbered a pre-existing real file"
fi

# --- 3. --dry-run never touches anything, and non-interactive runs refuse
#        to sync Homebrew packages without --yes -----------------------------
mkdir -p "$fixtures/dry-widget"
echo "payload" > "$fixtures/dry-widget/file.txt"
cat > "$fixtures/dry-widget/install.conf" <<'EOF'
LINK file.txt -> ~/.dry-widget/file.txt
POST touch dry-post-ran.marker
EOF

real_home="$HOME"
HOME="$sandbox"
DRY_RUN=1
apply_declared_installs "$fixtures" >/dev/null
DRY_RUN=0
HOME="$real_home"

if [ ! -e "$sandbox/.dry-widget" ] && [ ! -f "$fixtures/dry-widget/dry-post-ran.marker" ]; then
    ok "DRY_RUN=1 skips LINK and POST entirely"
else
    bad "DRY_RUN=1 still made a real change"
fi

if ! (echo | FORCE_YES=0 confirm_or_abort "test prompt" >/dev/null 2>&1); then
    ok "confirm_or_abort refuses on a non-interactive stdin without --yes"
else
    bad "confirm_or_abort proceeded on a non-interactive stdin without --yes"
fi

# --- 4. `LINK . -> dest` links the tool directory itself, and an existing
#        real file at dest is left alone (the shape every ~/.config/<app>
#        entry now uses). -----------------------------------------------------
dot_root="$(mktemp -d)"
dot_target="$(mktemp -d)"
mkdir -p "$dot_root/app"
echo "payload" > "$dot_root/app/config"
printf 'LINK . -> ~/.config/app\nLINK config -> ~/keepme\n' > "$dot_root/app/install.conf"
echo "mine" > "$dot_target/keepme"

DRY_RUN=0
HOME="$dot_target"
( apply_declared_installs "$dot_root" >/dev/null 2>&1 )
HOME="$real_home"

if [ "$(readlink "$dot_target/.config/app")" = "$dot_root/app" ]; then
    ok "LINK . links the tool directory itself"
else
    bad "LINK . did not link $dot_target/.config/app to the tool directory"
fi

if [ ! -L "$dot_target/keepme" ] && [ "$(cat "$dot_target/keepme")" = "mine" ]; then
    ok "LINK leaves an existing real file alone"
else
    bad "LINK clobbered an existing real file"
fi

rm -rf "$dot_root" "$dot_target"

# --- 5. The site/ pages are not stale w.r.t. the configs they document --------------
# The generated regions of site/keybindings.html and site/wiki.html come from the tracked configs. --check
# regenerates in memory and diffs, so this never modifies the repo. ----------------

# `set -e` would abort on the failing command substitution, so capture the status
# with an explicit `||` guard instead of a plain `; rc=$?`.
keybindings_check_exit=0
keybindings_check_out="$("$ROOT/update-keybindings.sh" --check 2>&1)" || keybindings_check_exit=$?

if [ "$keybindings_check_exit" -eq 0 ]; then
    ok "site/ pages match the configs they document"
else
    bad "site/ pages are stale - run ./update-keybindings.sh"
    # grep exits 1 when the stale source printed no warning, which under `set -e`
    # + pipefail would abort the run before the summary. Guard both ends.
    printf '%s\n' "$keybindings_check_out" | { grep '⚠️' || true; } | sed 's/^/     /'
fi

# --- 6. Transparent mode is wired up (see CONTEXT.md) ------------------------------
# Read-only: checks the Ghostty include, the command on PATH, and that the real state
# file (if any) holds a valid value and Ghostty's generated include agrees with it.
if grep -qx 'config-file = ?transparent-mode.conf' "$ROOT/ghostty/config"; then
    ok "ghostty/config includes the transparent-mode file"
else
    bad "ghostty/config is missing 'config-file = ?transparent-mode.conf'"
fi

if [ "$(command -v transparency 2>/dev/null)" = "$HOME/.local/bin/transparency" ]; then
    ok "transparency is on PATH"
else
    bad "transparency is not on PATH as ~/.local/bin/transparency - run ./setup.sh to link it"
fi

state_file="$(TRANSPARENCY_TESTING=1; . "$ROOT/zsh/.local/bin/transparency"; transparency_state_file)"
if [ ! -e "$state_file" ]; then
    ok "transparent mode has no state yet (defaults to off)"
else
    state_now="$(head -n 1 "$state_file")"
    case "$state_now" in
        on|off)
            expected_conf="$(TRANSPARENCY_TESTING=1; . "$ROOT/zsh/.local/bin/transparency"; transparency_render_ghostty "$state_now")"
            ghostty_conf="$(TRANSPARENCY_TESTING=1; . "$ROOT/zsh/.local/bin/transparency"; transparency_ghostty_file)"
            if [ "$(cat "$ghostty_conf" 2>/dev/null)" = "$expected_conf" ]; then
                ok "transparent mode is '$state_now' and Ghostty's include agrees"
            else
                bad "Ghostty's include doesn't match transparent mode '$state_now' - run: transparency $state_now"
            fi
            ;;
        *) bad "$state_file holds '$state_now' - expected on or off" ;;
    esac
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "✨ setup-validate.sh: all checks passed."
else
    echo "setup-validate.sh: failures above."
    exit 1
fi
