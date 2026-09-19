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

echo
if [ "$fail" -eq 0 ]; then
    echo "✨ setup-validate.sh: all checks passed."
else
    echo "setup-validate.sh: failures above."
    exit 1
fi
