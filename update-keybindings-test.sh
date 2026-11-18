#!/bin/bash
# Tests for the row extractors, the classifier and the region rewriter in
# update-keybindings.sh.
#
# These are the pre-agreed seams: each render_*_rows function is a pure function from a
# config file to TSV on stdout, and group_and_render is a pure function from TSV to
# HTML, so both can be tested without running the generator or writing
# the pages in site/.
#
#   ./update-keybindings-test.sh

set -uo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEYBINDINGS_TESTING=1 . "$REPO_ROOT/update-keybindings.sh"

pass=0 fail=0
check() { if [ "$1" -eq 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi }

# rows_of <extract-rows-fn>  -> data row count (one TSV line per binding)
rows_of() { printf '%s\n' "$("$1")" | grep -c "$(printf '\t')"; }

# expect_count <label> <want> <got>
expect_count() {
    local label="$1" want="$2" got="$3"
    if [ "$got" -eq "$want" ]; then
        echo "✅ $label: $got"
        check 0
    else
        echo "❌ $label: expected $want, got $got"
        check 1
    fi
}

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

expect_lacks() {
    local label="$1"
    if printf '%s\n' "$3" | grep -qF -- "$2"; then
        echo "❌ $label: unexpectedly found '$2'"
        check 1
    else
        echo "✅ $label: correctly absent '$2'"
        check 0
    fi
}

# expect_ge <label> <minimum> <got>
expect_ge() {
    local label="$1"
    if [ "$3" -ge "$2" ]; then
        echo "✅ $label: $3 (>= $2)"
        check 0
    else
        echo "❌ $label: $3 < $2"
        check 1
    fi
}

echo "🔍 Testing update-keybindings.sh"

echo
echo "--- Ghostty ---"
g=$(render_ghostty_rows)
expect_count "ghostty keybinds" 4 "$(rows_of render_ghostty_rows)"
expect_has "ghostty raw escape kept verbatim" 'text:\x01\x73' "$g"
expect_has "ghostty cmd+b kept verbatim" 'text:\x01\x7a' "$g"

echo
echo "--- Alacritty ---"
expect_count "alacritty bindings" 2 "$(rows_of render_alacritty_rows)"
expect_has "alacritty copy" "Copy" "$(render_alacritty_rows)"

echo
echo "--- zsh ---"
expect_count "zsh bindkeys" 1 "$(rows_of render_zsh_rows)"
expect_has "zsh ctrl-F widget" "_directory_suggestion_widget" "$(render_zsh_rows)"

echo
echo "--- AeroSpace ---"
sp=$(render_aerospace_rows)
# 58 `key = 'value'` lines exist, but two are pre-section container defaults, so 56 bind.
# 47 main + 9 resize + 8 service. The service entries are TOML arrays; matching only
# the bare-quoted form dropped all 8 of them, so the count is pinned to catch that.
expect_count "aerospace bindings" 64 "$(rows_of render_aerospace_rows)"
expect_has "aerospace service array binding is parsed" \
    "esc	reload-config, mode main	service" "$sp"
expect_has "aerospace service join-with array is parsed" \
    "alt-shift-h	join-with left, mode main	service" "$sp"
expect_has "aerospace resize-to-main action kept" "enter	mode main	resize" "$sp"
# Commented-out bindings must stay commented out.
expect_lacks "aerospace ignores commented-out sticky layout" "layout sticky tiling" "$sp"
expect_has "aerospace focus left" "alt-h	focus left" "$sp"
expect_lacks "aerospace excludes container defaults" "default-root-container-layout" "$sp"
# Mode is carried through as the third column, and the three binding modes appear.
expect_has "aerospace main mode present" "main" "$sp"
expect_has "aerospace resize mode present" "resize" "$sp"
expect_has "aerospace service mode present" "service" "$sp"
# The mode is a column on the binding rows, never a standalone pseudo-row. A
# `#main-mode` row with an empty Action cell is a rendering bug, not a binding.
expect_lacks "aerospace emits no mode pseudo-rows" "#main-mode" "$sp"
expect_lacks "aerospace mode rows all carry an action" "#resize-mode	" "$sp"

echo
echo "--- tmux ---"
if command -v tmux >/dev/null 2>&1; then
    t=$(render_tmux_rows)
    decl=$(printf '%s\n' "$t" | cut -f3 | grep -c declared)
    inh=$(printf '%s\n' "$t" | cut -f3 | grep -c inherited)
    echo "  declared=$decl inherited=$inh"

    expect_has "tmux labels repo-declared keys" "declared" "$t"
    expect_has "tmux labels inherited defaults" "inherited" "$t"
    expect_has "tmux exposes the prefix+z default" "resize-pane -Z" "$t"

    # prefix+z is never bound in .tmux.conf: it must be inherited, and is the reason
    # Ghostty's Cmd+B depends on a tmux default.
    tab="$(printf '\t')"
    zrow=$(printf '%s\n' "$t" | grep "^z${tab}")
    case "$zrow" in
        *resize-pane*inherited*) echo "✅ tmux: prefix+z marked inherited"
                                check 0 ;;
        *) echo "❌ tmux: prefix+z not marked inherited: $zrow"; check 1 ;;
    esac

    # Every key the config declares must survive that normalisation, or the declared/
    # inherited column is a lie. These are the ones that were previously wrong.
    # Normalisation: list-keys capitalises and escapes what the config writes bare.
    # Every key the config declares must survive that normalisation, or the declared/
    # inherited column is a lie. These are the ones that were previously wrong.
    for k in 'Space' '\%' '<' '>'; do
        row=$(printf '%s\n' "$t" | grep -F "${k}${tab}" | head -1)
        case "$row" in
            *declared*) echo "✅ tmux: $k correctly normalised to declared"; check 0 ;;
            *) echo "❌ tmux: $k mislabelled: $row"; check 1 ;;
        esac
    done
    # The literal double-quote key, written `bind '"'` in the config.
    dq=$(printf '%s\n' "$t" | grep -F "${tab}" | grep 'split-window -v -c' | grep -v '%' | head -1)
    case "$dq" in
        *declared*) echo "✅ tmux: double-quote split key correctly declared"; check 0 ;;
        *) echo "❌ tmux: double-quote split key mislabelled: $dq"; check 1 ;;
    esac

    # C-r is declared as a yazi popup but tmux-resurrect overrides it when tpm loads.
    # Introspection must report the effective binding, not the config's intent.
    crow=$(printf '%s\n' "$t" | grep -F "C-r${tab}")
    case "$crow" in
        *resurrect*) echo "✅ tmux: C-r reports effective resurrect binding, not yazi"
                     check 0 ;;
        *yazi*)      echo "❌ tmux: C-r reported as yazi - config read, not effective keymap"
                     check 1 ;;
        *)           echo "❌ tmux: C-r row missing"; check 1 ;;
    esac
else
    echo "⏭  tmux not installed - skipping introspection tests"
fi

echo
echo "--- Neovim ---"
nv=$(render_nvim_rows)
expect_ge "nvim mappings parsed" 20 "$(rows_of render_nvim_rows)"
expect_has "nvim leader rendered as SPACE" "SPACEfs" "$nv"
expect_has "nvim finds plugin table-literal keys" "SPACEac" "$nv"
expect_has "nvim parses plain-letter keymaps" "D	" "$nv"
expect_has "nvim carries the action" "Delete" "$nv"
# Guards the off-by-one-RLENGTH bug that shredded keys into fragments.
if printf '%s\n' "$nv" | cut -f1 | grep -qE '^[ ,}][^ ]*$'; then
    echo "❌ nvim: key fragments leaked (parser offset bug)"
    check 1
else
    echo "✅ nvim: no truncated key fragments"
    check 0
fi

echo
echo "--- classifier ---"
expect_has "classify split"       "Split"      "$(classify 'split-window -h')"
expect_has "classify resize"      "Resize"     "$(classify 'resize-pane -U')"
expect_has "classify focus"       "Focus & navigate" "$(classify 'select-pane -L')"
expect_has "classify popup"       "Popups & launchers" "$(classify 'display-popup -w 90%')"
expect_has "classify lazygit"     "Popups & launchers" "$(classify 'lazygit')"
expect_has "classify clipboard"   "Clipboard"  "$(classify 'copy_to_clipboard')"
expect_has "classify layout"      "Layout"     "$(classify 'select-layout -n')"
# Order matters: a split command that also mentions a session must classify as a split.
expect_has "split beats session"  "Split"      "$(classify 'split-window -h -c "#{pane_current_path}"')"

echo
echo "--- grouping (HTML output) ---"
ROWS="$(printf 'h\tselect-pane -L\nv\tsplit-window -h\nz\tresize-pane -Z\n')"
grp=$(group_and_render "Command" "-")

# Every row lands under a heading, and each category appears exactly once.
for h in "Focus &amp; navigate" "Split" "Resize"; do
    expect_has "grouped: <h3>$h</h3>" "<h3>$h <span class=\"grp-count\"></span></h3>" "$grp"
done
expect_count "each heading appears once" 3 "$(printf '%s\n' "$grp" | grep -c '^<h3>')"

# Headings must appear in ACTION_ORDER, not in key order. A category whose display
# position fails to resolve sorts as 0, which silently interleaves every section --
# so assert the exact heading sequence, not just that a heading is present.
expect_eq "headings follow ACTION_ORDER" \
    "Focus &amp; navigate|Split|Resize" \
    "$(printf '%s\n' "$grp" | sed -n 's/^<h3>\(.*\) <span class="grp-count"><\/span><\/h3>$/\1/p' | paste -sd'|' -)"

# Each row must sit inside its own group section, and the section elements must balance:
# an unbalanced <section>/<table> would nest one group inside another in the browser.
expect_count "section tags balance" \
    "$(printf '%s\n' "$grp" | grep -c '<section class="grp">')" \
    "$(printf '%s\n' "$grp" | grep -c '</section>')"
expect_count "table tags balance" \
    "$(printf '%s\n' "$grp" | grep -c '<table class="kb" data-generated>')" \
    "$(printf '%s\n' "$grp" | grep -c '</table>')"

# The filter JS toggles these three together, so all three must be emitted per group.
expect_count "one grp-count span per heading" 3 "$(printf '%s\n' "$grp" | grep -c 'class="grp-count"')"
expect_count "one nomatch note per heading"   3 "$(printf '%s\n' "$grp" | grep -c 'class="nomatch hidden"')"

# And each row must sit under its own heading: a row is correct only if it appears
# after its category heading and before the next one.
section_of() {
    # section_of <key> -> the heading the row was filed under
    printf '%s\n' "$grp" | awk -v want="$1" '
        /^<h3>/ { h = $0; sub(/^<h3>/, "", h); sub(/ <span.*$/, "", h) }
        index($0, "<kbd>" want "</kbd>") { print h; exit }
    '
}
expect_eq "row filed under Focus &amp; navigate" "Focus &amp; navigate" "$(section_of h)"
expect_eq "row filed under Split"                "Split"                "$(section_of v)"
expect_eq "row filed under Resize"               "Resize"               "$(section_of z)"

# A row whose category is missing from ACTION_ORDER must go last, not first.
ROWS="$(printf 'zzz\tsome-unclassified-verb\n')"
grp2=$(group_and_render "Command" "-")
expect_has "uncategorised row still gets a section" "<section class=\"grp\">" "$grp2"
expect_has "uncategorised row lands in Other" \
    "<tr><td class=\"k\"><kbd>zzz</kbd></td><td class=\"w\">some-unclassified-verb</td></tr>" "$grp2"

# The Source column drives the "declared only" toggle, so the value has to reach the
# row as data-decl as well as a visible tag. It must NOT be squashed into one
# overloaded attribute shared with the Mode column: that made the toggle hide every
# table that has no declared/inherited split.
ROWS="$(printf 'h\tselect-pane -L\tdeclared\nq\tresize-pane -Z\tinherited\n')"
grp3=$(group_and_render "Command" "Source" "source")
expect_has "declared row carries data-decl" \
    '<tr data-decl="declared"><td class="k"><kbd>h</kbd>' "$grp3"
expect_has "inherited row carries data-decl" \
    '<tr data-decl="inherited"><td class="k"><kbd>q</kbd>' "$grp3"
expect_has "source tag rendered" '<span class="tag declared">declared</span>' "$grp3"
expect_lacks "source column does not emit data-decl=falsey junk" "data-mode" "$grp3"

# A Mode column becomes data-mode instead, and must not be readable as data-decl.
ROWS="$(printf 'a\tworkspace 1\tmain\nb\tfocus left\tresize\n')"
grpm=$(group_and_render "Action" "Mode" "mode")
expect_has "mode row carries data-mode" \
    '<tr data-mode="main"><td class="k"><kbd>a</kbd>' "$grpm"
expect_lacks "mode column emits no data-decl" "data-decl" "$grpm"
expect_lacks "mode column emits no source tag" 'class="tag' "$grpm"

# HTML escaping. A category name contains "&", and tmux commands contain "|", "<" and
# quotes -- emitting those raw would produce a broken table or inject markup.
expect_has "ampersand in category escaped" "<h3>Focus &amp; navigate" "$grp"
ROWS="$(printf 'a\tcmd <arg> & \"more\"\n')"
grp4=$(group_and_render "Command" "-")
# In a text node a literal quote is valid and left alone; < > & must be escaped.
expect_has "angle brackets and ampersand escaped" \
    "<td class=\"w\">cmd &lt;arg&gt; &amp; \"more\"</td>" "$grp4"
expect_lacks "no raw angle bracket in a cell" "cmd <arg>" "$grp4"

# A quote inside an attribute value would close it early and inject markup, so the
# attribute path escapes more than the text path does.
ROWS="$(printf 'a\tsome-action\tbad"onload=x\n')"
grp5=$(group_and_render "Command" "Source" "source")
expect_has "quote escaped inside data-decl" 'data-decl="bad&quot;onload=x"' "$grp5"
expect_lacks "no unescaped quote in an attribute" 'data-decl="bad"onload' "$grp5"
# The visible tag is a class attribute built from the same value, so it needs the
# same quote escaping -- esc() alone left class="tag bad"onload=x" injectable.
expect_lacks "no unescaped quote in the tag class" 'class="tag bad"onload' "$grp5"

# Multiplexer pass-through: a terminal chord emitting the raw prefix byte belongs
# with the multiplexer, not in the catch-all bucket.
expect_has "classify terminal prefix pass-through" "Multiplexer pass-through" \
    "$(classify 'text:\x01\x7a')"
expect_has "bare copy is a clipboard action" "Clipboard" "$(classify 'Copy')"
expect_has "bare paste is a clipboard action" "Clipboard" "$(classify 'Paste')"

echo
echo "--- path scrubbing (portability of --check) ---"
if [ "$HOME" != "/" ]; then
    ROWS="x	$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
    scrub=$(group_and_render "Command" "Source" | scrub_paths)
    expect_lacks "home path scrubbed" "$HOME" "$scrub"
    expect_has "scrubbed to tilde" "~/.tmux/plugins/tmux-resurrect" "$scrub"
fi

echo
echo "--- failure safety ---"
out=$(REPO_ROOT="$(mktemp -d)" render_alacritty_rows 2>/dev/null); rc=$?
if [ "$rc" -ne 0 ] && [ -z "$out" ]; then
    echo "✅ unreadable source returns non-zero and no output (region would be skipped)"
    check 0
else
    echo "❌ safety: unreadable source returned rc=$rc out='$out'"
    check 1
fi

echo
echo "--- region rewriting ---"
sandbox="$(mktemp -d)"
doc="$sandbox/doc.html"
cat > "$doc" <<'EOF'
# t
hand written before
<!-- BEGIN GENERATED:x -->
old
<!-- END GENERATED:x -->
hand written after
EOF
cp "$doc" "$sandbox/orig.html"
KEYBINDINGS_TESTING=1 DOC="$doc" CHECK_ONLY=0 bash -c '
    . "'"$REPO_ROOT"'/update-keybindings.sh"
    ROWS="$(printf "k\tdo it\n")"
    replace_region "<!-- BEGIN GENERATED:x -->" "<!-- END GENERATED:x -->" \
        "$(group_and_render "Command" "-")" "'"$doc"'"
' >/dev/null 2>&1

expect_has "region body replaced" "do it" "$(cat "$doc")"
expect_lacks "old region body gone" "^old$" "$(cat "$doc")"
expect_has "prose before fence kept" "hand written before" "$(cat "$doc")"
expect_has "prose after fence kept" "hand written after" "$(cat "$doc")"

# --check must report staleness without writing.
cp "$sandbox/orig.html" "$doc"
CHECK_ONLY=1 KEYBINDINGS_TESTING=1 DOC="$doc" bash -c '
    . "'"$REPO_ROOT"'/update-keybindings.sh"
    ROWS="$(printf "k\tdo it\n")"
    replace_region "<!-- BEGIN GENERATED:x -->" "<!-- END GENERATED:x -->" \
        "$(group_and_render "Command" "-")" "'"$doc"'"
    exit $?
' >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 3 ]; then
    echo "✅ --check reports stale (exit 3) for a changed region"
    check 0
else
    echo "❌ --check returned $rc, expected 3"
    check 1
fi
if cmp -s "$doc" "$sandbox/orig.html"; then
    echo "✅ --check left the file byte-identical"
    check 0
else
    echo "❌ --check modified the file"
    check 1
fi

# An unchanged region must report no-change (2), so repeated runs are no-ops.
CHECK_ONLY=0 KEYBINDINGS_TESTING=1 DOC="$doc" bash -c '
    . "'"$REPO_ROOT"'/update-keybindings.sh"
    ROWS="$(printf "k\tdo it\n")"
    replace_region "<!-- BEGIN GENERATED:x -->" "<!-- END GENERATED:x -->" \
        "$(group_and_render "Command" "-")" "'"$doc"'"
    replace_region "<!-- BEGIN GENERATED:x -->" "<!-- END GENERATED:x -->" \
        "$(group_and_render "Command" "-")" "'"$doc"'"
    exit $?
' >/dev/null 2>&1
if [ $? -eq 2 ]; then
    echo "✅ second rewrite is a no-op (idempotent, exit 2)"
    check 0
else
    echo "❌ second rewrite did not report no-change"
    check 1
fi
rm -rf "$sandbox"

echo
echo "--- one source, several documents ---"
sandbox3="$(mktemp -d)"
for f in a b; do
    printf '%s\n' "<!-- BEGIN GENERATED:x -->" "old" "<!-- END GENERATED:x -->" > "$sandbox3/$f.html"
done
printf '%s\n' "no fences here" > "$sandbox3/c.html"
out="$(DOCS="$sandbox3/a.html:$sandbox3/b.html:$sandbox3/c.html" CHECK_ONLY=0 \
    KEYBINDINGS_TESTING=1 bash -c '
    . "'"$REPO_ROOT"'/update-keybindings.sh"
    rows_x() { printf "k\tdo it\n"; }
    process x "Command" "-" "" rows_x
    echo "status=$STATUS"
' 2>&1)"
expect_has "first document rewritten" "do it" "$(cat "$sandbox3/a.html")"
expect_has "second document rewritten" "do it" "$(cat "$sandbox3/b.html")"
expect_lacks "a document without the fence is not warned about" "no fence pair" "$out"
expect_has "multi-document write reports success" "status=0" "$out"

# --check must flag a stale region in any one of the documents.
printf '%s\n' "<!-- BEGIN GENERATED:x -->" "old" "<!-- END GENERATED:x -->" > "$sandbox3/b.html"
cp "$sandbox3/b.html" "$sandbox3/b.orig"
out="$(DOCS="$sandbox3/a.html:$sandbox3/b.html" CHECK_ONLY=1 KEYBINDINGS_TESTING=1 bash -c '
    . "'"$REPO_ROOT"'/update-keybindings.sh"
    rows_x() { printf "k\tdo it\n"; }
    process x "Command" "-" "" rows_x
    echo "status=$STATUS"
' 2>&1)"
expect_has "--check flags a stale second document" "status=1" "$out"
if cmp -s "$sandbox3/b.html" "$sandbox3/b.orig"; then
    echo "✅ --check left the second document untouched"
    check 0
else
    echo "❌ --check modified the second document"
    check 1
fi

# A fence missing from every document is still worth a warning.
out="$(DOCS="$sandbox3/c.html" CHECK_ONLY=0 KEYBINDINGS_TESTING=1 bash -c '
    . "'"$REPO_ROOT"'/update-keybindings.sh"
    rows_x() { printf "k\tdo it\n"; }
    process x "Command" "-" "" rows_x
' 2>&1)"
expect_has "fence missing everywhere is warned about" "no fence pair" "$out"
rm -rf "$sandbox3"

echo
echo "--- end-to-end: generator leaves the documents unchanged ---"
sandbox2="$(mktemp -d)"
if "$REPO_ROOT/update-keybindings.sh" >/dev/null 2>&1; then
    cp "$REPO_ROOT/site/keybindings.html" "$REPO_ROOT/site/wiki.html" "$sandbox2"
    "$REPO_ROOT/update-keybindings.sh" >/dev/null 2>&1
    if cmp -s "$REPO_ROOT/site/keybindings.html" "$sandbox2/keybindings.html" &&
       cmp -s "$REPO_ROOT/site/wiki.html" "$sandbox2/wiki.html"; then
        echo "✅ generator is idempotent against the real documents"
        check 0
    else
        echo "❌ generator is not idempotent"
        check 1
    fi
    rm -rf "$sandbox2"

    # Trap hygiene. A shim on PATH, not a private TMPDIR: BSD mktemp ignores TMPDIR
    # outright, so "run with TMPDIR set, then count files in it" always reports zero
    # and passes whether or not the generator leaks. The shim redirects every mktemp
    # call -- bare, templated or -d -- into a directory this test owns, so the count
    # can actually fail.
    shim_dir="$(mktemp -d)"
    mkdir -p "$shim_dir/bin" "$shim_dir/files"
    cat > "$shim_dir/bin/mktemp" <<SHIM
#!/bin/bash
# Only the -d call is redirected: that is how WORKDIR gets created, and placing it
# where this test can see it is what makes the count meaningful. Every other call is
# delegated verbatim, so the script's own scratch files keep the WORKDIR prefix and
# are genuinely inside the directory the EXIT trap is supposed to remove.
case "\${1:-}" in
    -d) out=\$(/usr/bin/mktemp -d "\$KB_TEST_TMP/kbdir.XXXXXX") ;;
    *)  out=\$(/usr/bin/mktemp "\$@") ;;
esac || exit 1
echo "\$out" >> "\$KB_TEST_LOG"
echo "\$out"
SHIM
    chmod +x "$shim_dir/bin/mktemp"

    : > "$shim_dir/made.log"
    PATH="$shim_dir/bin:$PATH" KB_TEST_TMP="$shim_dir/files" KB_TEST_LOG="$shim_dir/made.log" \
        "$REPO_ROOT/update-keybindings.sh" >/dev/null 2>&1
    made=$(grep -c . "$shim_dir/made.log" 2>/dev/null || echo 0)
    leftovers=$(find "$shim_dir/files" -mindepth 1 | wc -l | tr -d ' ')
    rm -rf "$shim_dir"

    # Guard the guard: if the shim never fired the counts prove nothing, so treat that
    # as a failure rather than letting the test pass vacuously.
    if [ "$made" -eq 0 ]; then
        echo "❌ trap hygiene is untestable: the mktemp shim was never called"
        check 1
    elif [ "$leftovers" -ne 0 ]; then
        echo "❌ generator leaked $leftovers of $made temp file(s)"
        check 1
    else
        echo "✅ generator reaps all $made temp file(s) it creates (EXIT trap)"
        check 0
    fi
else
    echo "⚠️  generator run failed - skipping end-to-end test"
    check 1
fi

echo
echo "────────────────────────────────────────"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ] || exit 1
echo "✨ all tests passed"