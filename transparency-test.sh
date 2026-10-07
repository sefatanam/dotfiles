#!/bin/bash
# Tests for transparent mode: the `transparency` command and the Neovim module that
# follows it.
#
# These are the pre-agreed seams: the command's state reader, state transition and
# Ghostty renderer are pure functions (sourced with TRANSPARENCY_TESTING=1), and the
# Neovim module's rose-pine option builder is pure Lua, run in a bare headless nvim.
# Everything runs against a throwaway $XDG_STATE_HOME / $XDG_CONFIG_HOME; Ghostty is
# never reloaded.
#
#   ./transparency-test.sh

set -uo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$REPO_ROOT/zsh/.local/bin/transparency"
NVIM_MODULE_DIR="$REPO_ROOT/nvim/lua"

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
export XDG_STATE_HOME="$sandbox/state" XDG_CONFIG_HOME="$sandbox/config"
mkdir -p "$XDG_CONFIG_HOME/ghostty"

TRANSPARENCY_TESTING=1 . "$SCRIPT"

pass=0 fail=0
check() { if [ "$1" -eq 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi }

# expect_eq <label> <want> <got>
expect_eq() {
    local label="$1" want="$2" got="$3"
    if [ "$got" = "$want" ]; then
        echo "✅ $label: $got"
        check 0
    else
        echo "❌ $label: expected '$want', got '$got'"
        check 1
    fi
}

# expect_has <label> <needle> <haystack>
expect_has() {
    local label="$1"
    if printf '%s\n' "$3" | grep -qF -- "$2"; then
        echo "✅ $label: found '$2'"
        check 0
    else
        echo "❌ $label: missing '$2'"
        check 1
    fi
}

state_file="$XDG_STATE_HOME/transparent-mode"
ghostty_file="$XDG_CONFIG_HOME/ghostty/transparent-mode.conf"

# --- paths ---------------------------------------------------------------------
expect_eq "state file honours XDG_STATE_HOME" "$state_file" "$(transparency_state_file)"
expect_eq "ghostty include lives beside the ghostty config" "$ghostty_file" "$(transparency_ghostty_file)"

# --- reading state -------------------------------------------------------------
expect_eq "missing state reads as off" "off" "$(transparency_read_state)"
mkdir -p "$XDG_STATE_HOME"
echo "on" > "$state_file"
expect_eq "on reads as on" "on" "$(transparency_read_state)"
printf 'on\n\n' > "$state_file"
expect_eq "trailing blank lines are tolerated" "on" "$(transparency_read_state)"
echo "maybe" > "$state_file"
expect_eq "garbage reads as off" "off" "$(transparency_read_state)"
rm -f "$state_file"

# --- transitions ---------------------------------------------------------------
expect_eq "on from off" "on" "$(transparency_next_state off on)"
expect_eq "off from on" "off" "$(transparency_next_state on off)"
expect_eq "toggle off -> on" "on" "$(transparency_next_state off toggle)"
expect_eq "toggle on -> off" "off" "$(transparency_next_state on toggle)"
transparency_next_state off bogus >/dev/null 2>&1
expect_eq "unknown argument is rejected" "1" "$?"

# --- Ghostty include -----------------------------------------------------------
on_conf="$(transparency_render_ghostty on)"
off_conf="$(transparency_render_ghostty off)"
expect_has "on: translucent" "background-opacity = 0.85" "$on_conf"
expect_has "on: blurred" "background-blur-radius = 20" "$on_conf"
expect_has "on: no split dimming stacked on blur" "unfocused-split-opacity = 1.0" "$on_conf"
expect_has "off: opaque" "background-opacity = 1.0" "$off_conf"
expect_has "off: no blur" "background-blur-radius = 0" "$off_conf"

# --- the command end to end (reload disabled) -------------------------------------
export TRANSPARENCY_NO_RELOAD=1
"$SCRIPT" on >/dev/null
expect_eq "'transparency on' writes the state" "on" "$(cat "$state_file")"
expect_eq "'transparency on' writes the ghostty include" "$on_conf" "$(cat "$ghostty_file")"
"$SCRIPT" toggle >/dev/null
expect_eq "'transparency toggle' flips it off" "off" "$(cat "$state_file")"
expect_eq "include follows the state" "$off_conf" "$(cat "$ghostty_file")"
expect_eq "'transparency status' reports it" "off" "$("$SCRIPT" status)"
expect_eq "no argument reports status" "off" "$("$SCRIPT")"
"$SCRIPT" bogus >/dev/null 2>&1
expect_eq "bad argument exits non-zero" "1" "$?"
expect_eq "bad argument leaves state alone" "off" "$(cat "$state_file")"
leftovers="$(find "$XDG_STATE_HOME" "$XDG_CONFIG_HOME" -name '*.tmp.*' | wc -l | tr -d ' ')"
expect_eq "atomic writes leave no temp files" "0" "$leftovers"

# --- Neovim module -------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
    lua_test="$sandbox/test.lua"
    cat > "$lua_test" <<EOF
package.path = "$NVIM_MODULE_DIR/?.lua;" .. package.path
local t = require("config.transparency")
local out = {}
local function emit(k, v) out[#out + 1] = k .. "=" .. tostring(v) end

emit("path", t.state_file())

local f = io.open(t.state_file(), "w"); f:write("on\n"); f:close()
emit("read_on", t.enabled())
f = io.open(t.state_file(), "w"); f:write("nope\n"); f:close()
emit("read_garbage", t.enabled())
os.remove(t.state_file())
emit("read_missing", t.enabled())

local on, off = t.rose_pine_opts(true), t.rose_pine_opts(false)
emit("on_transparency", on.styles.transparency)
emit("on_float", on.highlight_groups.NormalFloat and on.highlight_groups.NormalFloat.bg)
emit("on_pmenu", on.highlight_groups.Pmenu and on.highlight_groups.Pmenu.bg)
emit("on_border", on.highlight_groups.FloatBorder and on.highlight_groups.FloatBorder.bg)
emit("off_transparency", off.styles.transparency)
emit("off_overrides", next(off.highlight_groups) == nil)

emit("winhl", t.sidebar_winhl("Normal:SnacksNormal,NormalNC:SnacksNormalNC,NormalFloat:SnacksPickerList,FloatBorder:SnacksPickerListBorder,CursorLine:Visual"))

-- apply() against a stub rose-pine that deep-merges like the real one: "off" after
-- "on" must not keep the on-only highlight overrides.
local cfg = { options = { highlight_groups = {} } }
package.loaded["rose-pine.config"] = cfg
package.loaded["rose-pine"] = {
  setup = function(opts) cfg.options = vim.tbl_deep_extend("force", cfg.options, opts) end,
}
f = io.open(t.state_file(), "w"); f:write("on\n"); f:close()
t.apply()
f = io.open(t.state_file(), "w"); f:write("off\n"); f:close()
t.apply()
emit("off_after_on_overrides", next(cfg.options.highlight_groups) == nil)
os.remove(t.state_file())
io.write(table.concat(out, "\n") .. "\n")
EOF
    lua_out="$(nvim --headless -u NONE -l "$lua_test" 2>&1)"
    field() { printf '%s\n' "$lua_out" | sed -n "s/^$1=//p"; }
    expect_eq "nvim: same state file as the command" "$state_file" "$(field path)"
    expect_eq "nvim: on reads as enabled" "true" "$(field read_on)"
    expect_eq "nvim: garbage reads as disabled" "false" "$(field read_garbage)"
    expect_eq "nvim: missing reads as disabled" "false" "$(field read_missing)"
    expect_eq "nvim: on turns rose-pine transparency on" "true" "$(field on_transparency)"
    expect_eq "nvim: on keeps floats solid" "surface" "$(field on_float)"
    expect_eq "nvim: on keeps the completion menu solid" "surface" "$(field on_pmenu)"
    expect_eq "nvim: on keeps float borders solid" "surface" "$(field on_border)"
    expect_eq "nvim: off leaves rose-pine transparency off" "false" "$(field off_transparency)"
    expect_eq "nvim: off adds no highlight overrides" "true" "$(field off_overrides)"
    expect_eq "nvim: sidebar backgrounds point at SnacksSidebar, other mappings kept" \
        "Normal:SnacksSidebar,NormalNC:SnacksSidebar,NormalFloat:SnacksSidebar,FloatBorder:SnacksPickerListBorder,CursorLine:Visual" \
        "$(field winhl)"
    expect_eq "nvim: switching off live drops the on-only overrides" "true" "$(field off_after_on_overrides)"
else
    echo "⏭  nvim not installed - skipping Neovim module tests"
fi

echo
echo "────────────────────────────────────────"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ] || exit 1
echo "✨ all tests passed"
