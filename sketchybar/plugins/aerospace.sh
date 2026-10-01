#!/bin/bash
# Renders AeroSpace workspace chips into sketchybar.
#
# Three visual states per workspace:
#   focused              -> chip highlighted, app icons shown
#   non-empty, unfocused -> chip drawn, app icons shown (see ICONS_ON_ALL)
#   empty, unfocused     -> hidden entirely
#
# Uses exactly two `aerospace` calls and one batched `sketchybar --set`,
# so cost is constant regardless of workspace count.

# Maps app names to glyph ligatures (":ghostty:" and friends) from
# sketchybar-app-font, which the chip labels are rendered in. Sourced rather
# than executed per app so the mapping costs no subprocesses.
source "$(dirname "${BASH_SOURCE[0]}")/icon_map.sh"

# Max glyphs per chip before the rest are elided. A chip with more windows
# than this would otherwise push the clock off a narrow display.
MAX_ICONS=5

# Show app icons on every non-empty workspace. Set to 0 to show them only
# on the focused workspace.
ICONS_ON_ALL=1

# workspace|true|false for every workspace, including empty ones.
WORKSPACES=$(aerospace list-workspaces --all --format '%{workspace}|%{workspace-is-focused}' 2>/dev/null)
[ -z "$WORKSPACES" ] && exit 0

# workspace|app-name, one line per open window. Absence of a workspace
# here is what defines "empty" -- there is no workspace-is-empty format key.
WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)

args=()

# Workspaces that end up drawn, in bar order. Separators are decided from
# this afterwards, since "is there a chip to my right" is not knowable
# until every workspace has been classified.
visible=()

while IFS='|' read -r ws focused; do
  [ -z "$ws" ] && continue

  # Dedupe app names while preserving window order. sort -u would be wrong
  # here: it reorders.
  names=$(printf '%s\n' "$WINDOWS" | awk -F'|' -v w="$ws" \
    '$1 == w && !seen[$2]++ { print $2 }')

  # One glyph per distinct app, space-separated. Deduped on the glyph too:
  # two apps can share an icon (and everything unknown shares :default:),
  # which would otherwise render as a repeated glyph. Tracked in a string
  # rather than an associative array -- macOS ships bash 3.2, which has none.
  apps=""
  seen=""
  count=0
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    __icon_map "$name"
    case "$seen" in *"$icon_result"*) continue ;; esac
    seen="$seen$icon_result"
    [ "$count" -ge "$MAX_ICONS" ] && break
    apps="${apps:+$apps }$icon_result"
    count=$((count + 1))
  done <<< "$names"

  if [ "$focused" = "true" ]; then
    visible+=("$ws")
    args+=(--set "space.$ws"
      drawing=on
      background.drawing=on
      icon.color=0xffffffff)
    if [ -n "$apps" ]; then
      args+=(label="$apps" label.drawing=on)
    else
      args+=(label.drawing=off)
    fi
  elif [ -n "$apps" ]; then
    visible+=("$ws")
    if [ "$ICONS_ON_ALL" = "1" ]; then
      args+=(--set "space.$ws"
        drawing=on
        background.drawing=off
        icon.color=0xffffffff
        label="$apps"
        label.drawing=on)
    else
      args+=(--set "space.$ws"
        drawing=on
        background.drawing=off
        icon.color=0xffffffff
        label.drawing=off)
    fi
  else
    args+=(--set "space.$ws" drawing=off)
    args+=(--set "space.$ws.sep" drawing=off)
  fi
done <<< "$WORKSPACES"

# A chip's separator is drawn iff a visible chip follows it, which leaves the
# last one bare. Hidden chips had theirs switched off in the loop above.
last=$(( ${#visible[@]} - 1 ))
for i in "${!visible[@]}"; do
  if [ "$i" -lt "$last" ]; then
    args+=(--set "space.${visible[$i]}.sep" drawing=on)
  else
    args+=(--set "space.${visible[$i]}.sep" drawing=off)
  fi
done

# Single IPC roundtrip for all workspaces.
[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
