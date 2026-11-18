#!/bin/bash
# Regenerate the generated regions of the pages in site/ from the tracked configs.
#
# Six sources: AeroSpace, tmux, Ghostty, Alacritty, Neovim, zsh. Each owns one region,
# and every page that carries that region's fences gets the same body
# (site/keybindings.html has all six; site/wiki.html has one per tool panel), fenced by
#   <!-- BEGIN GENERATED:<source> -->  ...  <!-- END GENERATED:<source> -->
# Only the text between the fences is ever rewritten; everything outside is yours.
#
#   ./update-keybindings.sh            rewrite the regions in place
#   ./update-keybindings.sh --check    exit 1 if the page is stale, touch nothing
#
# Structure: each render_*_rows function emits TSV (key <TAB> what-it-does) and nothing
# else. One shared formatter classifies each row into an action group and renders the
# Markdown, so grouping lives in exactly one place.
#
# Design rules this script follows deliberately:
#   * A source that cannot be read is SKIPPED with a warning and its region is left
#     byte-identical. A doc generator must never be able to destroy the doc.
#   * tmux is introspected (`tmux list-keys`), not parsed, so tmux's ~150 inherited
#     defaults are visible and can be labelled. Neovim is parsed statically: booting
#     headless LazyVim would install plugins and vary by machine.
#   * Output is locale-independent (LC_ALL=C on every sort) and scrubbed of absolute
#     home paths, so a page generated on one machine still validates on another.
#
# House style: bash + awk, like setup.sh / setup-validate.sh / tmux-validate.sh.
# (python3's identity in PATH is not stable across machines and tomllib needs 3.11+,
# so every source here is line-oriented enough for awk. BSD awk: no gensub, no match
# with an array arg.)

set -uo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults are overridable from the environment so the test harness can exercise
# replace_region in --check mode without going through main().
# DOCS is a colon-separated list of pages; DOC (a single page) is still honoured.
CHECK_ONLY="${CHECK_ONLY:-0}"
DOCS="${DOCS:-${DOC:-$REPO_ROOT/site/keybindings.html:$REPO_ROOT/site/wiki.html}}"

usage() {
    cat <<EOF
Usage: update-keybindings.sh [--check]

  --check     Verify the pages in site/ match the configs, changing nothing.
              Exits 1 if it is stale, or if a source could not be read.
  --help, -h  Show this message.

With no arguments every generated region in site/ is rewritten in place.
EOF
}

# Parse arguments explicitly. Anything unrecognised is a usage error, because the
# default behaviour is to rewrite a tracked file: silently treating a typo'd --check
# (or --help) as "no arguments" would rewrite the page when the caller asked for
# something read-only.
while [ $# -gt 0 ]; do
    case "$1" in
        --check) CHECK_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "❌ unknown option: $1" >&2; echo >&2; usage >&2; exit 1 ;;
        *)  echo "❌ unexpected argument: $1" >&2; echo >&2; usage >&2; exit 1 ;;
    esac
    shift
done

warn()  { echo "⚠️  $*" >&2; }
die()   { echo "❌ $*" >&2; exit 1; }
ok()    { echo "✅ $*"; }

IFS=: read -r -a DOC_LIST <<< "$DOCS"
for doc in "${DOC_LIST[@]}"; do
    [ -f "$doc" ] || die "page not found at $doc"
done

# All scratch files live in one directory that the EXIT trap removes wholesale.
# Tracking individual files in an array does not work here: render_*_rows and
# group_and_render are invoked inside command substitutions, so a subshell adds to
# its own copy of the array and the parent never learns about those files. A
# directory sidesteps that -- a file created in a subshell is still inside WORKDIR.
# An explicit path template is required: BSD mktemp ignores $TMPDIR for a bare one.
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/keybindings.XXXXXX")"
cleanup() { [ -n "${WORKDIR:-}" ] && [ -d "$WORKDIR" ] && rm -rf "$WORKDIR"; }
trap cleanup EXIT
# mktmp <varname> -- create a scratch file and put its path in <varname>.
mktmp() { local f; f="$(mktemp "$WORKDIR/kb.XXXXXX")" || return 1; printf -v "$1" '%s' "$f"; }

# ---------------------------------------------------------------------------
# Action classification. First match wins, so order is significant: the
# specific commands come before the generic verbs.
# ---------------------------------------------------------------------------
classify() {
    local c; c="$(printf '%s' "$(printf '%s' "$1" | tr 'A-Z' 'a-z')")"
    case "$c" in
        *split-window*|*split_vertical*|*split_horizontal*|*new-pane*) echo "Split" ;;
        *resize-pane*|*resize_mode*|*toggle-zoom*)                  echo "Resize" ;;
        *copy-mode*|*paste-buffer*|*copy-pane*|*send-keys*)          echo "Copy mode & buffers" ;;
        # A terminal chord that emits the raw prefix byte is a pass-through into the
        # multiplexer, so group it with the multiplexer rather than the terminal.
        text:\\x01*)                                                 echo "Multiplexer pass-through" ;;
        *clipboard*)                                                  echo "Clipboard" ;;
        *display-popup*|*popup*)                                     echo "Popups & launchers" ;;
        *lazygit*|*yazi*|*fzf*)                                      echo "Popups & launchers" ;;
        *session*|*workspace*)                                       echo "Sessions & workspaces" ;;
        *move-pane*|*swap-pane*|*move-window*|*swap-window*|*join-pane*|*break-pane*|*move-client*|*rotate-window*)
                                                                    echo "Move & swap" ;;
        # AeroSpace names its window moves "move left", not "move-pane".
        *"move left"*|*"move right"*|*"move up"*|*"move down"*|*"move-workspace-to-monitor"*)
                                                                    echo "Move & swap" ;;
        # Entering or leaving a binding mode is navigation between contexts, not an
        # unclassifiable side effect.
        *"mode main"*|*"mode resize"*|*"mode service"*)                echo "Switch mode" ;;
        *select-pane*|*focus_pane*|*focus\ *|*focus-*|*next-tab*|*previous-tab*|*switch-client*|*choose-tree*|*last-window*|*list-sessions*|*select-window*|*next-window*|*previous-window*|*last-pane*)
                                                                    echo "Focus & navigate" ;;
        *select-layout*|*"layout "*)                                 echo "Layout" ;;
        *source-file*|*reload_config*|*resurrect*|*continuum*)       echo "Reload & session persistence" ;;
        *command-prompt*|*list-keys*|*customize-mode*)                echo "Command prompt" ;;
        *detach*|*kill-*|*list-buffers*|*choose-buffer*)             echo "Detach & buffers" ;;
        *format*|*lsp*|*diagnostic*|*dap*)                          echo "LSP & diagnostics" ;;
        *fold*|*ufo*|*peek*)                                         echo "Folds" ;;
        *template*|*/style\.*|*jump*|*grug*|*far\ *|*trouble*)       echo "Jump & project" ;;
        *tmuxnavigate*)                                              echo "Jump & project" ;;
        *buffer*|*file*|*find*)                                      echo "Files & buffers" ;;
        *copy*|*paste*)                                              echo "Clipboard" ;;
        *delete*|*_d\$*|*normal!*)                                   echo "Edit" ;;
        # Anchor the bare "ai" case: an unanchored *ai* also matches "mode main",
        # "wait", "detail" and "maintain", which are not AI anything.
        *claude*|*omp*|*opencode*|*open-code*|*"ai "*|*" ai")           echo "AI agents" ;;
        *) echo "Other" ;;
    esac
}

# Category display order. A row's category is sorted by its position in this list, so
# sections appear in a stable, deliberate order rather than in key order.
ACTION_ORDER=(
    "Multiplexer pass-through" "Focus & navigate" "Switch mode" "Split" "Move & swap"
    "Resize" "Layout"
    "Popups & launchers" "Sessions & workspaces" "Files & buffers"
    "Copy mode & buffers" "Clipboard" "Edit" "Jump & project"
    "Folds" "LSP & diagnostics" "AI agents" "Reload & session persistence"
    "Command prompt" "Detach & buffers" "Other"
)

# Group TSV rows into action sections and render HTML.
#   $1 = column-2 heading, $2 = third column heading ("-" to omit the column)
#   $3 = what column 3 means: "source" (declared/inherited) or "mode", or "" for none.
# The distinction matters: the page's "declared only" toggle reads data-decl, so a
# mode column must not be squashed into the same attribute -- doing so hid every row
# of the five tables that have no declared/inherited split.
group_and_render() {
    local col2="$1" col3="$2" kind="${3:-}"
    local classified; mktmp classified

    # order_str is the bare category names, one per line, so a category's display
    # position is its line number. (Keeping an "N=Category" prefix here would make
    # the `^Category$` lookup below never match and silently sort by key instead.)
    local order_i=0 order_str=""
    for cat in "${ACTION_ORDER[@]}"; do
        order_str+="$cat"$'\n'
        order_i=$((order_i + 1))
    done

    local row key what extra cat pos
    while IFS=$'\t' read -r key what extra; do
        [ -n "$key" ] || continue
        cat="$(classify "$what")"
        pos="$(grep -n -x -- "$cat" <<< "$order_str" | cut -d: -f1)"
        # A category missing from ACTION_ORDER must not sort as position 0 and
        # hijack the first section; send it to the end.
        [ -n "$pos" ] || pos="${#ACTION_ORDER[@]}"
        printf '%s\t%s\t%s\t%s\t%s\n' "$pos" "$cat" "$key" "$what" "$extra"
    done <<< "$ROWS" | sort -t$'\t' -k1,1n -k3,3 > "$classified"

    awk -F'\t' -v col2="$col2" -v col3="$col3" -v kind="$kind" '
        # Escape for an HTML text node. Ampersand first, or it would double-escape the
        # entities the later two introduce.
        function esc(s) {
            gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s)
            return s
        }
        # Attribute values additionally need quotes neutralised, or a value
        # containing one would close the attribute and inject markup.
        function escattr(s) {
            gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s)
            gsub(/"/, "\\&quot;", s)
            return s
        }
        function open_group(cat) {
            if (open) { print "</tbody>"; print "</table>"; print "</section>"; print "" }
            print "<section class=\"grp\">"
            print "<h3>" esc(cat) " <span class=\"grp-count\"></span></h3>"
            print "<p class=\"nomatch hidden\">No matches.</p>"
            print "<table class=\"kb\" data-generated>"
            print "<thead><tr><th scope=\"col\">Key</th><th scope=\"col\">" esc(col2) "</th>" \
                  ((col3 == "-") ? "" : "<th scope=\"col\">" esc(col3) "</th>") "</tr></thead>"
            print "<tbody>"
            open = 1
        }
        {
            if (!seen[$2]++) open_group($2)

            # data-decl is reserved for declared/inherited; a mode column becomes
            # data-mode instead, and neither is emitted when there is no column 3.
            attr = ""
            cell = ""
            if (col3 != "-") {
                if (kind == "source") {
                    attr = " data-decl=\"" escattr($5) "\""
                    cell = "<td class=\"s\"><span class=\"tag " escattr($5) "\">" esc($5) "</span></td>"
                } else if (kind == "mode") {
                    attr = " data-mode=\"" escattr($5) "\""
                    cell = "<td class=\"s\">" esc($5) "</td>"
                } else {
                    cell = "<td class=\"s\">" esc($5) "</td>"
                }
            }
            print "<tr" attr "><td class=\"k\"><kbd>" esc($3) "</kbd></td>" \
                  "<td class=\"w\">" esc($4) "</td>" cell "</tr>"
        }
        END {
            if (open) { print "</tbody>"; print "</table>"; print "</section>" }
        }
    ' "$classified"
}

# ---------------------------------------------------------------------------
# Row producers. Each emits: key <TAB> what-it-does [<TAB> extra-column]
# ---------------------------------------------------------------------------

render_aerospace_rows() {
    local f="$REPO_ROOT/aerospace/aerospace.toml"
    [ -f "$f" ] || return 1
    awk '
        BEGIN { sq = sprintf("%c", 39); q = "[" "\"" sq "]" }
        /^\[mode\./ {
            # The binding mode becomes a real column, not an injected pseudo-row:
            # which mode you are in decides which bindings apply, so hiding it
            # behind a header would misrepresent the config.
            mode = $0
            sub(/^\[mode\./, "", mode); sub(/\..*$/, "", mode)
            next
        }
        /^\[/ { mode = "" }
        mode != "" {
            line = $0
            sub(/^[ \t]+/, "", line)
            if (line ~ /^#/ || line == "") next
            if (line !~ /^[A-Za-z0-9_-]+[ \t]*=/) next
            k = line; sub(/[ \t]*=.*/, "", k); sub(/[ \t]+$/, "", k)
            v = line; sub(/^[^=]*=[ \t]*/, "", v)
            # AeroSpace writes a binding two ways: main/resize use a bare quoted
            # string, service uses a TOML array whose second element is the mode to
            # switch to. Matching only the quoted form silently dropped every
            # service binding, so branch on the actual opening character.
            first = substr(v, 1, 1)
            if (first == "[") {
                end = index(v, "]")
                if (end == 0) next
                v = substr(v, 2, end - 2)
                gsub(sq, "", v)
                gsub(/[ \t]+/, " ", v)
                sub(/^ /, "", v); sub(/ $/, "", v)
                gsub(/, ?/, ", ", v)
            } else if (first == "\"" || first == sq) {
                # Search past the opening quote, or index() just finds it again.
                rest = substr(v, 2)
                end = index(rest, first)
                if (end == 0) next
                v = substr(rest, 1, end - 1)
            } else next
            if (k != "" && v != "") printf "%s\t%s\t%s\n", k, v, mode
        }
    ' "$f"
}

render_tmux_rows() {
    local f="$REPO_ROOT/tmux/.tmux.conf"
    command -v tmux >/dev/null 2>&1 || return 1
    [ -f "$f" ] || return 1

    # tmux 3.7c's `list-keys` ignores -F here, so parse the default line format:
    #   bind-key [-r|-n] [-T <table>] <key> <command...>
    local sock keys_file rc
    mktmp keys_file

    # Introspect on a PRIVATE socket, never the default one. If a tmux server is
    # already running, `tmux -f <conf> list-keys` connects to it and ignores -f
    # entirely -- so the "generated" table would be live server state, and editing
    # .tmux.conf without reloading it would leave --check passing. Proof: with a
    # server up, `tmux -f /nonexistent.conf list-keys` still prints the whole
    # prefix table and exits 0.
    #
    # Side effect to be aware of: booting a server runs the config's `run` lines,
    # which in this repo install tpm. They are idempotent once ~/.tmux/plugins
    # exists, which is why this is acceptable for a read-only introspection.
    sock="keybindings-gen-$$"
    tmux -L "$sock" -f "$f" start-server \; list-keys -T prefix > "$keys_file" 2>/dev/null
    rc=$?
    tmux -L "$sock" kill-server >/dev/null 2>&1 || true
    [ "$rc" -eq 0 ] || return 1
    [ -s "$keys_file" ] || return 1

    # Keys the repo declares, normalised the way list-keys renders them so the
    # declared/inherited column compares like with like. Two normalisations matter:
    # list-keys capitalises bare key names (`space` -> `Space`) and escapes punctuation
    # (`%` -> `\%`) that the config writes bare; both are compared lowercased and
    # unescaped.
    local declfile
    mktmp declfile
    # declfile is created by mktmp inside this same function body, so the registration
    # lands in the caller's TMPFILES and the EXIT trap reaps it.
    awk '
        # Only real bind directives. Without this guard every `set -g status-right …`
        # line and status-format fragment in the file would count as a key.
        !/^[ \t]*bind(-key)?[ \t]+/ { next }
        {
            line = $0
            sub(/^[ \t]*bind(-key)?[ \t]+/, "", line)
            while (line ~ /^-[a-zA-Z]+[ \t]/) sub(/^-[a-zA-Z]+[ \t]*/, "", line)
            if (line ~ /^-T[ \t]/) sub(/^-T[ \t]+[^ \t]+[ \t]*/, "", line)
            if (!match(line, /^[^ \t]+/)) next
            k = substr(line, 1, RLENGTH)
            # Strip quoting characters (both kinds) from each end. Built with sprintf
            # because a literal quote cannot appear inside this single-quoted program.
            cls = "[" sprintf("%c", 34) sprintf("%c", 39) "]"
            gsub("^" cls "|" cls "$", "", k)
            gsub(/\\/, "", k)        # unescape punctuation, e.g.  \%  ->  %
            # A key that is nothing but quotes once stripped is tmux quoting the
            # double-quote character itself.
            if (k == "") k = sprintf("%c", 34)
            print tolower(k)
        }
    ' "$f" | sort -u > "$declfile"

    awk -v df="$declfile" '
        BEGIN { while ((getline k < df) > 0) declared[k] = 1; close(df) }
        /^bind-key[ \t]+/ {
            rest = $0
            sub(/^bind-key[ \t]+/, "", rest)
            while (rest ~ /^(-r|-n|-N|-T)[ \t]/) {
                if (rest ~ /^-T[ \t]/) sub(/^-T[ \t]+[^ \t]+[ \t]*/, "", rest)
                else sub(/^-[a-zA-Z]+[ \t]*/, "", rest)
            }
            if (!match(rest, /^[^ \t]+/)) next
            key = substr(rest, 1, RLENGTH)
            cmd = substr(rest, RLENGTH + 1)
            sub(/^[ \t]+/, "", cmd)
            # Compare normalised: list-keys capitalises key names and escapes
            # punctuation the config writes bare, so compare lowercased + unescaped.
            nk = tolower(key)
            gsub(/\\/, "", nk)
            printf "%s\t%s\t%s\n", key, cmd, ((nk in declared) ? "declared" : "inherited")
        }
    ' "$keys_file"
}

render_ghostty_rows() {
    local f="$REPO_ROOT/ghostty/config"
    [ -f "$f" ] || return 1
    # keybind = <key>=<action>  (two '=' separators, so -F= is required; with whitespace
    # separation $2 would be the '=' itself)
    awk -F= '
        /^[[:space:]]*keybind[[:space:]]*=/ {
            key = $2; val = $3
            gsub(/[[:space:]]/, "", key); gsub(/[[:space:]]/, "", val)
            if (key == "" || val == "") next
            printf "%s\t%s\n", key, val
        }
    ' "$f"
}

render_alacritty_rows() {
    local f="$REPO_ROOT/alacritty/alacritty.toml"
    [ -f "$f" ] || return 1
    awk '
        /^\[\[keyboard\.bindings\]\]/ { inblock = 1; key = ""; next }
        inblock && /^key[ \t]*=/ {
            key = $0
            sub(/^key[ \t]*=[ \t]*/, "", key); gsub(/"/, "", key); next
        }
        inblock && /^action[ \t]*=/ {
            act = $0
            sub(/^action[ \t]*=[ \t]*/, "", act); gsub(/"/, "", act)
            printf "%s\t%s\n", key, act
            inblock = 0
        }
    ' "$f"
}

render_nvim_rows() {
    local dir="$REPO_ROOT/nvim/lua"
    [ -d "$dir" ] || return 1
    awk '
        function clean(k) {
            gsub(/^[ \t]+|[ \t]+$/, "", k)
            gsub(/"|'"'"'/, "", k)
            gsub(/<leader>/, "SPACE", k)
            return k
        }
        # Call form. `map` and `keymap` are local aliases for vim.keymap.set
        # (customize.lua:5, :64), so both spellings appear. Mode is arg 1, key arg 2.
        /(^|[^.[:alnum:]_])(map|keymap)\(/ || /vim\.keymap\.set\(/ {
            line = $0
            sub(/^[ \t]+/, "", line)
            if (!match(line, /\(/)) next
            rest = substr(line, RSTART + 1)

            key = ""; mode = ""; off = 0
            if (match(rest, /^\{[^{}]*\}[ \t]*,[ \t]*["'"'"']/)) {
                head = substr(rest, 1, RLENGTH)
                gsub(/[{} \t"'"'"']/, "", head); mode = head
                off = RLENGTH
            } else if (match(rest, /^["'"'"'][^"'"'"']*["'"'"'][ \t]*,[ \t]*["'"'"']/)) {
                head = substr(rest, 1, RLENGTH)
                sub(/[ \t]*,.*/, "", head)
                gsub(/["'"'"' \t]/, "", head); mode = head
                off = RLENGTH
            }
            if (off == 0) next
            # Each match clobbers RLENGTH, so capture the length immediately.
            if (!match(substr(rest, off + 1), /^[^,]+/)) next
            key = substr(rest, off + 1, RLENGTH)
            rhs_start = off + 1 + RLENGTH
            # Prefer the human-readable desc wherever it appears on the line, since the
            # rhs may be a Lua long-string or an inline function body.
            act = ""
            if (match(line, /desc[ \t]*=[ \t]*"[^"]*"/)) {
                act = substr(line, RSTART, RLENGTH)
                sub(/.*desc[ \t]*=[ \t]*"/, "", act); sub(/"$/, "", act)
            } else {
                rhs = substr(rest, rhs_start + 1)
                # Lua long string: [[...]]
                if (match(rhs, /\[\[[^]]*\]\]/)) {
                    act = substr(rhs, RSTART, RLENGTH)
                    sub(/^\[\[/, "", act); sub(/\]\]$/, "", act)
                } else {
                    if (match(rhs, /^[^,]+/)) act = substr(rhs, 1, RLENGTH)
                    if (match(act, /[{(]/)) act = substr(act, 1, RSTART - 1)
                    gsub(/^[ \t"'"'"']+|[ \t"'"'"'\\]+$/, "", act)
                    # require("ufo").openAllFolds -> openAllFolds
                    if (match(act, /require\(.*\)\.[A-Za-z_]+$/)) act = substr(act, RSTART)
                }
                if (act == "nil") act = "(opens a menu)"
                if (act ~ /^function/) act = "inline function"
            }
            if (length(act) > 60) act = substr(act, 1, 57) "..."
            if (act == "") act = "-"
            gsub(/,+$/, "", mode); gsub(/,+/, ", ", mode)
            printf "%s\t%s\t%s\n", clean(key), act, (mode == "" ? "n" : mode)
        }
        # Table form used by plugin specs: keys = { { "<key>", ... }, ... }
        /^[[:space:]]*\{[[:space:]]*"/ {
            if (match($0, /"[^"]*<[^"]*"/)) {
                printf "%s\t%s\tplugin\n", clean(substr($0, RSTART + 1, RLENGTH - 2)), "-"
            }
        }
    ' $(find "$dir" -name '*.lua' -type f) 2>/dev/null
}

render_zsh_rows() {
    local dir="$REPO_ROOT/zsh"
    [ -d "$dir" ] || return 1
    grep -rh "^bindkey" "$dir" 2>/dev/null | awk '
        /^bindkey[ \t]+/ {
            key = $2; action = $3
            gsub(/'"'"'/, "", key); gsub(/'"'"'/, "", action)
            printf "%s\t%s\n", key, action
        }
    '
}

# ---------------------------------------------------------------------------
# Region rewriting
# ---------------------------------------------------------------------------

# Replace the text between one pair of fences.
# The body is passed via a file, not -v: awk cannot carry a multi-line value in a -v
# assignment (BSD awk rejects it outright).
# Exit status: 0 rewritten, 1 error, 2 already current, 3 stale (--check only).
replace_region() {
    local begin="$1" end="$2" body="$3" target="$4" tmp bodyfile rc
    mktmp tmp; mktmp bodyfile
    printf '%s\n' "$body" > "$bodyfile" || return 1
    awk -v b="$begin" -v e="$end" -v bf="$bodyfile" '
        $0 == b {
            print
            while ((getline line < bf) > 0) print line
            close(bf)
            skip = 1
            next
        }
        $0 == e { skip = 0; print; next }
        !skip { print }
    ' "$target" > "$tmp" || return 1
    if cmp -s "$tmp" "$target"; then return 2; fi   # 2 = no change
    if [ "$CHECK_ONLY" -eq 1 ]; then return 3; fi   # 3 = stale
    cat "$tmp" > "$target"; rc=$?
    return $rc
}

# Rewrite every row of `output` into the target's home-relative form, so a page
# generated on one machine still passes --check on another.
scrub_paths() {
    sed -e "s|$HOME|~|g"
}

ROWS=""
STATUS=0
SKIPPED=0

#   $1 name, $2 col-2 heading, $3 col-3 heading ("-" to omit), $4 col-3 kind
#   ("source" | "mode" | ""), $5 the render_*_rows function
process() {
    local name="$1" col2="$2" col3="$3" kind="${4:-}" rows_fn="$5"
    local rows body begin end rc

    # Honour the render function's exit status: it returns non-zero when the source
    # cannot be read. Testing only for empty output let --check report "up to date"
    # when every config was missing -- a false all-clear on exactly the drift this
    # gate exists to catch.
    rows="$("$rows_fn" 2>/dev/null)"; rc=$?
    if [ "$rc" -ne 0 ] || [ -z "$rows" ]; then
        warn "skipped $name (unreadable) - its region is untouched"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    ROWS="$rows"
    body="$(group_and_render "$col2" "$col3" "$kind" | scrub_paths)"
    if [ -z "$body" ]; then
        warn "skipped $name (rendered nothing) - its region is untouched"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    begin="<!-- BEGIN GENERATED:$name -->"
    end="<!-- END GENERATED:$name -->"
    # A page may legitimately omit a region (the wiki has no Alacritty panel), so only
    # a region that no page carries is worth a warning.
    local doc where found=0
    for doc in "${DOC_LIST[@]}"; do
        grep -qxF "$begin" "$doc" && grep -qxF "$end" "$doc" || continue
        found=1
        where="$name ($(basename "$doc"))"
        replace_region "$begin" "$end" "$body" "$doc"; rc=$?
        case $rc in
            0) [ "$CHECK_ONLY" -eq 1 ] && warn "$where region is STALE" || echo "  $where: updated" ;;
            2) [ "$CHECK_ONLY" -eq 1 ] || echo "  $where: unchanged" ;;
            3) warn "$where region is STALE"; STATUS=1 ;;
            *) warn "failed to rewrite $where - region untouched"; STATUS=1 ;;
        esac
    done
    [ "$found" -eq 1 ] || warn "skipped $name (no fence pair in any page)"
}

if [ -z "${KEYBINDINGS_TESTING:-}" ]; then
    echo "🔄 Refreshing generated keybinding regions…"
    process aerospace   "Action"        "Mode"   "mode"   render_aerospace_rows
    process tmux        "Command"       "Source" "source" render_tmux_rows
    process ghostty     "Value"         "-"      ""       render_ghostty_rows
    process alacritty   "Action"        "-"      ""       render_alacritty_rows
    process nvim        "Action"        "Mode"   "mode"   render_nvim_rows
    process zsh         "Widget"        "-"      ""       render_zsh_rows

    echo
    if [ "$CHECK_ONLY" -eq 1 ]; then
        # Skipped sources are not a pass. Reporting "up to date" while every config
        # was unreadable is precisely the false all-clear this gate exists to avoid.
        if [ "$SKIPPED" -ne 0 ]; then
            die "$SKIPPED source(s) could not be read - the pages were not verified against them"
        fi
        if [ "$STATUS" -eq 0 ]; then
            ok "site/ pages are up to date"
        else
            die "site/ pages are stale - run ./update-keybindings.sh"
        fi
    else
        # A write that could not complete every region must not report success: a
        # half-regenerated page that says "Done" is worse than one that fails loudly.
        if [ "$STATUS" -ne 0 ]; then
            die "one or more regions could not be rewritten - the page is inconsistent, re-run after fixing the warnings above"
        fi
        if [ "$SKIPPED" -ne 0 ]; then
            die "$SKIPPED source(s) were skipped, so those regions are stale - fix the warnings above and re-run"
        fi
        ok "Done. Review the diff, then commit."
    fi
fi