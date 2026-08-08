#!/usr/bin/env bash
# @REVIEW: pi bootstrap for a fresh machine.
# Stow already symlinks extensions/ prompts/ skills/ into ~/.pi/agent/.
# This only handles the two things stow should NOT own: settings.json (merged, not
# symlinked, so machine-local keys like lastChangelogVersion stay local) and the
# graphify CLI (a binary, not a dotfile).
set -euo pipefail

PI_DIR="$HOME/.pi/agent"
TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.pi/agent/settings.template.json"

mkdir -p "$PI_DIR"

# 1. Seed settings.json from template if missing; else merge template keys in (template wins
#    for our managed keys, machine keeps everything else). Needs python3.
if [ ! -f "$PI_DIR/settings.json" ]; then
  cp "$TEMPLATE" "$PI_DIR/settings.json"
  echo "pi: seeded settings.json from template"
else
  python3 - "$PI_DIR/settings.json" "$TEMPLATE" <<'PY'
import json, sys
live_path, tmpl_path = sys.argv[1], sys.argv[2]
live = json.load(open(live_path))
tmpl = json.load(open(tmpl_path))
live.update(tmpl)              # ponytail: template is source of truth for managed keys
json.dump(live, open(live_path, "w"), indent=2)
print("pi: merged template into existing settings.json")
PY
fi

# 2. graphify CLI (skill is already symlinked via stow; the binary is not a dotfile)
if ! command -v graphify >/dev/null 2>&1; then
  if command -v uv >/dev/null 2>&1; then
    uv tool install graphifyy && echo "pi: installed graphify CLI"
  else
    echo "pi: uv not found — install uv, then 'uv tool install graphifyy'"
  fi
fi

echo "pi: bootstrap done. Run 'pi list' to confirm extensions load."
