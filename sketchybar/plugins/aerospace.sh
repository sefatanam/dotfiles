#!/bin/bash
# Renders AeroSpace workspace chips into sketchybar.
#
# Three visual states per workspace:
#   focused              -> chip highlighted, app names shown
#   non-empty, unfocused -> chip drawn, app names shown (see NAMES_ON_ALL)
#   empty, unfocused     -> hidden entirely
#
# Uses exactly two `aerospace` calls and one batched `sketchybar --set`,
# so cost is constant regardless of workspace count.

# Max width of the app-name label before ellipsis. sketchybar's
# label.max_chars is not reported by --query, so truncate here instead
# to keep the rendered value inspectable.
MAX_LABEL=30

# Show app names on every non-empty workspace. Set to 0 to show them only
# on the focused workspace.
NAMES_ON_ALL=1

# workspace|true|false for every workspace, including empty ones.
WORKSPACES=$(aerospace list-workspaces --all --format '%{workspace}|%{workspace-is-focused}' 2>/dev/null)
[ -z "$WORKSPACES" ] && exit 0

# workspace|app-name, one line per open window. Absence of a workspace
# here is what defines "empty" -- there is no workspace-is-empty format key.
WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)

args=()

while IFS='|' read -r ws focused; do
  [ -z "$ws" ] && continue

  # Dedupe app names while preserving window order, then join with ", ".
  # sort -u would be wrong here: it reorders.
  apps=$(printf '%s\n' "$WINDOWS" | awk -F'|' -v w="$ws" \
    '$1 == w && !seen[$2]++ { printf "%s%s", (n++ ? ", " : ""), $2 }')

  if [ ${#apps} -gt $MAX_LABEL ]; then
    apps="${apps:0:$((MAX_LABEL - 1))}…"
  fi

  if [ "$focused" = "true" ]; then
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
    if [ "$NAMES_ON_ALL" = "1" ]; then
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
  fi
done <<< "$WORKSPACES"

# Single IPC roundtrip for all workspaces.
[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
