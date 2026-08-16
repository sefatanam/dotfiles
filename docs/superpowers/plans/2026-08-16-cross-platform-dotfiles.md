# Cross-Platform Dotfiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the same committed dotfiles tree on macOS and Ubuntu with no local edits and no commented-out OS blocks.

**Architecture:** Three tiers — `shared` (default home for every setting), `os` (only genuinely divergent content), `local` (gitignored, per-machine). OS-specific content is selected by *which stow package is installed*, never branched on at runtime; the sole runtime detection is `platform.zsh`, which exports `DOTFILES_OS` and `BREW_PREFIX`. Because both platforms use Homebrew, most divergence collapses into `$BREW_PREFIX` rather than into an OS overlay.

**Tech Stack:** zsh, GNU Stow 2.4.1, Homebrew (`/opt/homebrew` on macOS, `/home/linuxbrew/.linuxbrew` on Linux), bash for scripts. No test framework exists in this repo; tests are plain-shell assertion scripts, consistent with the existing `tmux-validate.sh` / `zsh-optimize.sh` style.

**Spec:** `docs/superpowers/specs/2026-08-16-cross-platform-dotfiles-design.md`

## Global Constraints

- Branch: `for-linux`. Do not work on `main`.
- Repo root: `/home/sefat/.dotfiles`. All paths below are relative to it.
- `DOTFILES_OS` is exactly `darwin` or `linux`. No other values.
- `BREW_PREFIX` is exactly `/opt/homebrew` (darwin) or `/home/linuxbrew/.linuxbrew` (linux).
- Only these files may contain a hardcoded Homebrew prefix: `zsh/.local/share/zsh/platform.zsh`, `setup.sh`, `bash-install.sh`, and the two portability-check scripts.
- `os.zsh` sets variables **only**. It must never mutate `PATH`; `exports.zsh` owns PATH construction and its cache.
- No file in `stow-packages/` may contain `/Users/` or a hardcoded brew prefix.
- Shell startup time must not regress. Never add a subprocess to a hot path.
- macOS cannot be tested from the Linux machine. Any macOS-only change must be verified by the user on the Mac before merge.

## Two Pre-existing Hazards This Plan Fixes

Both were found while reading the installers. They are called out here because they are destructive, not merely untidy:

1. **`bash-install.sh:229-230` blanks a tracked repo file.** `create_linux_exports()` runs `cat > ~/.local/share/zsh/exports.zsh` with an *empty* heredoc — immediately after `stow -t ~ shell` (`:259`) has made that path a symlink into the repo. The write follows the symlink and truncates `zsh/.local/share/zsh/exports.zsh` to zero bytes. Fixed in Task 12.
2. **`setup.sh:172-179` writes into tracked config.** It appends `eval "$(... brew shellenv)"` to `~/.zprofile`, which is a stow symlink into the repo. This is the mechanism by which installer cruft entered tracked files. Fixed in Task 10.

## Deliberate Departure From the Spec's Ordering

The spec lists the regression guard as migration step 6 (last). This plan builds it as **Task 1** instead.

The spec's ordering rationale was that the shell must never break mid-migration. Building the guard first does not conflict with that — it only adds files under `scripts/`, and nothing sources them. Moving it first buys a real test cycle: every subsequent task has a concrete failing check to drive to green, and progress is measurable rather than asserted. The rest of the spec's sequence is preserved exactly.

## Note on the Currently Staged Change

`zsh/.local/share/zsh/exports.zsh` has a staged modification that is *itself* the comment/uncomment pattern this project removes (macOS lines commented out, Linux lines active). It is the working Linux state today, so keep it staged until Task 4, which replaces that file's logic wholesale. Task 4's commit supersedes it.

## File Structure

**Created:**

| Path | Responsibility |
|---|---|
| `scripts/test-helpers.sh` | Assertion helpers for all shell tests. No external deps. |
| `scripts/check-portability.sh` | The regression guard. Exits non-zero on any OS-literal leak. |
| `scripts/test-check-portability.sh` | Tests for the guard, using temp-dir fixtures. |
| `scripts/test-shell-config.sh` | Tests `platform.zsh` / `os.zsh` / `exports.zsh` behavior. |
| `zsh/.local/share/zsh/platform.zsh` | The only runtime OS detection. Exports `DOTFILES_OS`, `BREW_PREFIX`. |
| `stow-packages/os-darwin/` | macOS-only package: aerospace, raycast, os.zsh, terminal fragments. |
| `stow-packages/os-linux/` | Linux-only package: os.zsh, terminal fragments. |
| `brew/Brewfile.darwin` | 44 casks + `nikitabobko/tap`. |
| `brew/Brewfile.linux` | Linux-only entries. Near-empty initially. |

**Modified:** `zsh/.zprofile`, `zsh/.zshrc`, `zsh/.local/share/zsh/exports.zsh`, `zsh/.local/share/zsh/completions.zsh`, `ghostty/config`, `alacritty/alacritty.toml`, `stow-packages/shell/.config/alacritty` (symlink → real dir), `brew/Brewfile`, `setup.sh`, `bash-install.sh`, `mcp/config.json`, `.gitignore`, `docs/INSTALL.md`, `docs/MIGRATION.md`.

---

### Task 1: Portability guard and test harness

Build the guard **first** so every later task has a failing check to drive to green. It only adds new files under `scripts/`, so nothing sources it and the shell cannot break.

**Files:**
- Create: `scripts/test-helpers.sh`
- Create: `scripts/test-check-portability.sh`
- Create: `scripts/check-portability.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/check-portability.sh [ROOT]` — scans `ROOT` (default: repo root), prints one line per violation, exits `0` if clean and `1` if any violation. When `ROOT` is passed explicitly, `$HOME` stow checks are skipped so tests can use fixtures. `scripts/test-helpers.sh` exports shell functions `assert_eq`, `assert_exit`, `finish`.

- [ ] **Step 1: Write the assertion helpers**

Create `scripts/test-helpers.sh`:

```bash
#!/usr/bin/env bash
# Minimal assertion helpers for dotfiles tests. Intentionally dependency-free:
# this repo has no test framework and adding one would be a new prerequisite on
# every machine the dotfiles bootstrap.

TESTS_RUN=0
TESTS_FAILED=0

assert_eq() {
    local expected="$1" actual="$2" msg="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        printf '  ok   %s\n' "$msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf '  FAIL %s\n         expected: %s\n         actual:   %s\n' \
            "$msg" "$expected" "$actual"
    fi
}

# assert_exit <expected-code> <message> <command...>
assert_exit() {
    local expected="$1" msg="$2"
    shift 2
    TESTS_RUN=$((TESTS_RUN + 1))
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    if [[ "$expected" == "$actual" ]]; then
        printf '  ok   %s\n' "$msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf '  FAIL %s (expected exit %s, got %s)\n' "$msg" "$expected" "$actual"
    fi
}

finish() {
    printf '\n%d assertions, %d failed\n' "$TESTS_RUN" "$TESTS_FAILED"
    [[ $TESTS_FAILED -eq 0 ]]
}
```

- [ ] **Step 2: Write the failing test for the guard**

Create `scripts/test-check-portability.sh`:

```bash
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
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash scripts/test-check-portability.sh`
Expected: every assertion FAILs — `check-portability.sh` does not exist yet, so every invocation exits 127.

- [ ] **Step 4: Write the guard**

Create `scripts/check-portability.sh`:

```bash
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
#   scripts/*portability* - the guard and its tests contain the patterns literally.
is_exempt_all() {
    case "$1" in
        */docs/superpowers/*)                return 0 ;;
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
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `chmod +x scripts/check-portability.sh scripts/test-check-portability.sh && bash scripts/test-check-portability.sh`
Expected: `9 assertions, 0 failed`

- [ ] **Step 6: Record the red baseline**

Run: `bash scripts/check-portability.sh; echo "exit=$?"`

Expected: exit=1, with violations in exactly these **five** files (this baseline was computed against the current tree, so treat any deviation as a bug in the guard rather than a surprise in the repo):

| File | Rules tripped | Fixed by |
|---|---|---|
| `zsh/.zshrc` | brew prefix, `/Users/`, OS tag | Tasks 3, 5 |
| `zsh/.zprofile` | brew prefix, `/Users/`, OS tag | Task 3 |
| `zsh/.local/share/zsh/exports.zsh` | brew prefix, `/Users/` | Task 4 |
| `zsh/.local/share/zsh/completions.zsh` | `/Users/` | Task 3 |
| `mcp/config.json` | `/Users/` | Task 13 |

`docs/INSTALL.md` and `docs/MIGRATION.md` do **not** appear — they contain the word "macOS" but no `/Users/` paths, brew prefixes, or OS tags. They are corrected in Task 13 for accuracy, not to satisfy the guard.

This is the red state the remaining tasks drive to zero.

- [ ] **Step 7: Commit**

```bash
git add scripts/test-helpers.sh scripts/check-portability.sh scripts/test-check-portability.sh
git commit -m "test: add portability regression guard

Fails on hardcoded brew prefixes, /Users/ paths, and comment/uncomment
OS tags. Currently red; subsequent commits drive it to zero."
```

---

### Task 2: platform.zsh — the single runtime detection

Additive only: creates the file and sources it. No existing behavior changes, so the shell cannot break.

**Files:**
- Create: `zsh/.local/share/zsh/platform.zsh`
- Create: `scripts/test-shell-config.sh`
- Modify: `zsh/.zshrc` (source block, lines 13-20)

**Interfaces:**
- Consumes: nothing.
- Produces: `DOTFILES_OS` (`darwin`|`linux`) and `BREW_PREFIX` (absolute path), both exported. Sourcing twice is a no-op. Every later task depends on these two names.

- [ ] **Step 1: Write the failing test**

Create `scripts/test-shell-config.sh`:

```bash
#!/usr/bin/env bash
# Tests for the zsh platform/OS/exports layer.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/test-helpers.sh"

REPO="$(cd "$HERE/.." && pwd)"
PLATFORM="$REPO/zsh/.local/share/zsh/platform.zsh"

echo "platform.zsh"

expected_os=linux
expected_prefix=/home/linuxbrew/.linuxbrew
if [[ "$(uname -s)" == "Darwin" ]]; then
    expected_os=darwin
    expected_prefix=/opt/homebrew
fi

assert_eq "$expected_os" \
    "$(zsh -c "source '$PLATFORM'; printf '%s' \"\$DOTFILES_OS\"")" \
    "sets DOTFILES_OS for this machine"

assert_eq "$expected_prefix" \
    "$(zsh -c "source '$PLATFORM'; printf '%s' \"\$BREW_PREFIX\"")" \
    "sets BREW_PREFIX for this machine"

assert_eq "sentinel" \
    "$(zsh -c "DOTFILES_OS=sentinel; source '$PLATFORM'; printf '%s' \"\$DOTFILES_OS\"")" \
    "is idempotent: does not overwrite an already-set DOTFILES_OS"

assert_eq "0" \
    "$(zsh -c "source '$PLATFORM'; printf '%s' \$?")" \
    "returns 0 when the idempotence guard is not triggered"

assert_eq "0" \
    "$(zsh -c "DOTFILES_OS=sentinel; source '$PLATFORM'; printf '%s' \$?")" \
    "returns 0 when the idempotence guard IS triggered"

assert_eq "" \
    "$(zsh -c "source '$PLATFORM'" 2>&1)" \
    "produces no output or warnings"

finish
```

The last two assertions matter: a sourced file whose final command is a failed test returns non-zero, which surfaces as a spurious error in a strict caller.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash scripts/test-shell-config.sh`
Expected: FAIL on all assertions — `platform.zsh` does not exist.

- [ ] **Step 3: Write platform.zsh**

Create `zsh/.local/share/zsh/platform.zsh`:

```zsh
# platform.zsh - the single source of truth for platform facts.
#
# Sourced by .zprofile (before the brew shellenv eval, which needs BREW_PREFIX)
# and again by .zshrc, because .zshrc runs alone for non-login shells and cannot
# assume .zprofile ran. The guard below makes the second source a no-op.
#
# Deliberately does NOT call `brew --prefix`. That is a subprocess on every shell
# start, and this repo caches aggressively to keep startup fast. The prefix is a
# fixed constant per platform, so a subprocess buys nothing.
#
# setup.sh and bash-install.sh mirror this logic. Keep all three in sync.

if [[ -z "${DOTFILES_OS:-}" ]]; then
    case "$(uname -s)" in
        Darwin)
            export DOTFILES_OS=darwin
            export BREW_PREFIX=/opt/homebrew
            ;;
        *)
            export DOTFILES_OS=linux
            export BREW_PREFIX=/home/linuxbrew/.linuxbrew
            ;;
    esac
fi

return 0
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash scripts/test-shell-config.sh`
Expected: `6 assertions, 0 failed`

- [ ] **Step 5: Source it from .zshrc**

In `zsh/.zshrc`, replace lines 13-20 (the `_source_if_exists` definition and its four calls) with:

```zsh
_source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# Order matters. platform.zsh sets BREW_PREFIX; os.zsh sets the per-OS values
# that exports.zsh bakes into its PATH cache. exports.zsh must run after both.
_source_if_exists "$ZSH_CONFIG_DIR/platform.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/os.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/exports.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/aliases.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/functions.zsh"
_source_if_exists "$ZSH_CONFIG_DIR/completions.zsh"
```

`os.zsh` does not exist yet; `_source_if_exists` makes that harmless.

- [ ] **Step 6: Verify the shell still starts**

Run: `zsh -i -c 'echo "OS=$DOTFILES_OS PREFIX=$BREW_PREFIX"'`
Expected: `OS=linux PREFIX=/home/linuxbrew/.linuxbrew`, no errors.

- [ ] **Step 7: Commit**

```bash
git add zsh/.local/share/zsh/platform.zsh zsh/.zshrc scripts/test-shell-config.sh
git commit -m "feat(zsh): add platform.zsh for OS detection

Exports DOTFILES_OS and BREW_PREFIX. Idempotent, no subprocess.
Additive: no existing behavior changes yet."
```

---

### Task 3: Replace brew literals with $BREW_PREFIX

The largest single reduction in divergence, and low risk: every change is a literal-for-variable substitution that resolves to the same string on the current machine.

**Files:**
- Modify: `zsh/.zprofile` (full rewrite, 21 lines)
- Modify: `zsh/.zshrc` (lines 27-32, 45-51, 69-84)
- Modify: `zsh/.local/share/zsh/completions.zsh:9`

**Interfaces:**
- Consumes: `BREW_PREFIX` from Task 2.
- Produces: no new names.

- [ ] **Step 1: Rewrite .zprofile**

Replace the entire contents of `zsh/.zprofile` with:

```zsh
# .zprofile - login shell setup. Runs before .zshrc.

# Platform facts first: the brew shellenv eval below needs BREW_PREFIX.
[[ -f "$HOME/.local/share/zsh/platform.zsh" ]] && \
    source "$HOME/.local/share/zsh/platform.zsh"

eval "$("$BREW_PREFIX/bin/brew" shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$BREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \
    \. "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

source ~/.zshrc
```

This fixes three live bugs in the old file: `export NVM DIR=` had a space instead of an underscore (so `NVM_DIR` was never set here), line 11 had a stray trailing `]`, and the JetBrains Toolbox line was a machine-specific leftover (it moves to `~/.zsh.local` in Task 5).

- [ ] **Step 2: Fix the plugin paths in .zshrc**

In `zsh/.zshrc`, replace lines 27-28:

```zsh
## source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh #For MacOS
source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh #For Linux
```

with:

```zsh
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
```

And replace lines 31-32:

```zsh
    ## source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh #For MacOS
    source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh #For Linux
```

with:

```zsh
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
```

- [ ] **Step 3: Remove the JAVA_HOME and duplicate-shellenv blocks from .zshrc**

Delete lines 45-51 entirely (the `# OpenJDK 21` block, including the unconditional macOS `JAVA_HOME` at line 47 and the two commented `openjdk@21` lines). `JAVA_HOME` moves to `os.zsh` in Task 4.

Delete line 84 (`eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`) — `.zprofile` already does this, so it was running twice.

Delete lines 62-67 (the commented-out `# Valdi configuration` block) — dead commented config.

- [ ] **Step 4: Fix the hardcoded bun completion path**

In `zsh/.local/share/zsh/completions.zsh`, replace line 9:

```zsh
        [ -s "/Users/sefat/.bun/_bun" ] && source "/Users/sefat/.bun/_bun"
```

with:

```zsh
        [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
```

- [ ] **Step 5: Verify the shell still starts and plugins load**

```bash
zsh -i -c 'echo ok' 2>&1 | tail -5
zsh -i -c 'typeset -f _zsh_autosuggest_start >/dev/null && echo "autosuggestions loaded"'
```
Expected: `ok` with no "no such file or directory" errors, then `autosuggestions loaded`.

- [ ] **Step 6: Confirm the guard improved**

Run: `bash scripts/check-portability.sh`
Expected: `zsh/.zprofile` and `zsh/.local/share/zsh/completions.zsh` no longer appear. `zsh/.zshrc` still appears (the `/Users/sefat` PATH lines remain until Task 5); `exports.zsh` still appears (Task 4).

- [ ] **Step 7: Commit**

```bash
git add zsh/.zprofile zsh/.zshrc zsh/.local/share/zsh/completions.zsh
git commit -m "refactor(zsh): use \$BREW_PREFIX instead of hardcoded prefixes

Also fixes: NVM_DIR typo (space, not underscore) and stray bracket in
.zprofile, duplicate brew shellenv eval, hardcoded bun completion path,
and removes dead commented-out config blocks."
```

---

### Task 4: OS packages, os.zsh, and the exports.zsh rework

**Files:**
- Create: `stow-packages/os-darwin/.local/share/zsh/os.zsh`
- Create: `stow-packages/os-linux/.local/share/zsh/os.zsh`
- Modify: `zsh/.local/share/zsh/exports.zsh` (full rewrite)
- Modify: `scripts/test-shell-config.sh` (add assertions)

**Interfaces:**
- Consumes: `BREW_PREFIX`, `DOTFILES_OS` from Task 2.
- Produces: `PNPM_HOME`, `JAVA_HOME`, `DYLD_LIBRARY_PATH` (darwin only), and the array `OS_PATH_ENTRIES`. `exports.zsh` reads `OS_PATH_ENTRIES` when assembling the cached PATH. Later tasks add more files to these same two packages.

- [ ] **Step 1: Write the failing tests**

Append to `scripts/test-shell-config.sh`, immediately before the final `finish` call:

```bash
echo
echo "os.zsh"

OS_ZSH="$REPO/stow-packages/os-$expected_os/.local/share/zsh/os.zsh"

assert_exit 0 "os.zsh exists for this platform" test -f "$OS_ZSH"

expected_pnpm="$HOME/.local/share/pnpm"
[[ "$expected_os" == "darwin" ]] && expected_pnpm="$HOME/Library/pnpm"

assert_eq "$expected_pnpm" \
    "$(zsh -c "source '$PLATFORM'; source '$OS_ZSH'; printf '%s' \"\$PNPM_HOME\"")" \
    "sets PNPM_HOME for this platform"

assert_eq "1" \
    "$(zsh -c "source '$PLATFORM'; source '$OS_ZSH'; printf '%s' \"\${#OS_PATH_ENTRIES[@]}\"")" \
    "declares exactly one OS PATH entry"

# os.zsh must not touch PATH: exports.zsh owns it and caches the result.
assert_eq "same" \
    "$(zsh -c "source '$PLATFORM'; before=\$PATH; source '$OS_ZSH'; [[ \$before == \$PATH ]] && printf same || printf changed")" \
    "os.zsh does not mutate PATH"

echo
echo "exports.zsh"

EXPORTS="$REPO/zsh/.local/share/zsh/exports.zsh"

assert_eq "changed" \
    "$(zsh -c "
        export HOME=\$(mktemp -d)
        source '$PLATFORM'; source '$OS_ZSH'
        ZSH_CONFIG_DIR='$REPO/zsh/.local/share/zsh'
        before=\$PATH; source '$EXPORTS'
        [[ \$before == \$PATH ]] && printf same || printf changed")" \
    "exports.zsh builds PATH"

assert_eq "yes" \
    "$(zsh -c "
        export HOME=\$(mktemp -d)
        source '$PLATFORM'; source '$OS_ZSH'
        ZSH_CONFIG_DIR='$REPO/zsh/.local/share/zsh'
        source '$EXPORTS'
        [[ -f \$HOME/.cache/zsh-path.cache ]] && printf yes || printf no")" \
    "exports.zsh writes the PATH cache"

assert_eq "yes" \
    "$(zsh -c "
        export HOME=\$(mktemp -d)
        source '$PLATFORM'; source '$OS_ZSH'
        ZSH_CONFIG_DIR='$REPO/zsh/.local/share/zsh'
        source '$EXPORTS'
        case \$PATH in *\"\$PNPM_HOME\"*) printf yes ;; *) printf no ;; esac")" \
    "OS_PATH_ENTRIES land on PATH"

# The old cache keyed only on exports.zsh's own mtime, so editing os.zsh left a
# stale PATH. Touching os.zsh must invalidate.
assert_eq "yes" \
    "$(zsh -c "
        export HOME=\$(mktemp -d)
        mkdir -p \$HOME/.cache
        printf '#Cached PATH configuration\nexport PATH=/stale\n' > \$HOME/.cache/zsh-path.cache
        touch -t 200001010000 \$HOME/.cache/zsh-path.cache
        source '$PLATFORM'; source '$OS_ZSH'
        ZSH_CONFIG_DIR='$REPO/zsh/.local/share/zsh'
        source '$EXPORTS'
        [[ \$PATH == /stale ]] && printf no || printf yes")" \
    "a cache older than os.zsh is rebuilt"
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash scripts/test-shell-config.sh`
Expected: the `os.zsh` and `exports.zsh` assertions FAIL (`os.zsh` missing; `exports.zsh` does not yet read `OS_PATH_ENTRIES`).

- [ ] **Step 3: Write the two os.zsh files**

Create `stow-packages/os-darwin/.local/share/zsh/os.zsh`:

```zsh
# os.zsh (darwin) - macOS-only values.
#
# Stow-selected: this file reaches ~ only via the os-darwin package, so on Linux
# it is not skipped at runtime, it is simply absent.
#
# Sets variables ONLY. PATH construction belongs to exports.zsh, which caches the
# result; mutating PATH here would be captured in that cache in whatever order
# happened to apply on the run that built it.

export PNPM_HOME="$HOME/Library/pnpm"
export JAVA_HOME="$BREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
export DYLD_LIBRARY_PATH="$BREW_PREFIX/lib:${DYLD_LIBRARY_PATH:-}"

OS_PATH_ENTRIES=( "$PNPM_HOME" )
```

Create `stow-packages/os-linux/.local/share/zsh/os.zsh`:

```zsh
# os.zsh (linux) - Linux-only values.
#
# Stow-selected: this file reaches ~ only via the os-linux package.
#
# Sets variables ONLY. PATH construction belongs to exports.zsh. See the darwin
# counterpart at stow-packages/os-darwin/.local/share/zsh/os.zsh.

export PNPM_HOME="$HOME/.local/share/pnpm"
export JAVA_HOME="$BREW_PREFIX/opt/openjdk"

OS_PATH_ENTRIES=( "$PNPM_HOME" )
```

- [ ] **Step 4: Rewrite exports.zsh**

Replace the entire contents of `zsh/.local/share/zsh/exports.zsh` with:

```zsh
# exports.zsh - environment variables and PATH construction.
#
# Owns the PATH cache. Runs after platform.zsh (for BREW_PREFIX) and os.zsh (for
# OS_PATH_ENTRIES); see the source order in .zshrc.

_zsh_config_dir="${ZSH_CONFIG_DIR:-$HOME/.local/share/zsh}"
_path_cache="$HOME/.cache/zsh-path.cache"

# Invalidate when ANY input changes. The previous version checked only its own
# mtime, so editing os.zsh left a stale PATH until the cache was deleted by hand.
_path_cache_stale=0
if [[ ! -f "$_path_cache" ]]; then
    _path_cache_stale=1
else
    for _input in platform.zsh os.zsh exports.zsh; do
        if [[ -f "$_zsh_config_dir/$_input" && "$_path_cache" -ot "$_zsh_config_dir/$_input" ]]; then
            _path_cache_stale=1
        fi
    done
fi

if (( _path_cache_stale )); then
    mkdir -p "$HOME/.cache"
    {
        echo "#Cached PATH configuration"
        echo "export GOROOT=\"$BREW_PREFIX/opt/go/libexec\""
        echo "export GOPATH=\$HOME/go"
        echo "export BUN_INSTALL=\"\$HOME/.bun\""
        echo "export NVM_DIR=~/.nvm"
        echo "export EDITOR=\"nvim\""

        # Flatten the per-OS entries into a colon-joined prefix.
        _os_entries=""
        for _entry in "${OS_PATH_ENTRIES[@]:-}"; do
            [[ -n "$_entry" ]] && _os_entries="${_os_entries}${_entry}:"
        done

        echo "export PATH=\"$BREW_PREFIX/opt/go/libexec/bin:\$HOME/go/bin:\$HOME/.bun/bin:${_os_entries}\$HOME/bin:\$HOME/.opencode/bin:\$HOME/.local/bin:\$PATH\""
    } > "$_path_cache"
fi
source "$_path_cache"

unset _path_cache _path_cache_stale _input _entry _os_entries _zsh_config_dir

# Ultra-fast lazy loading functions
nvm() {
    unset -f nvm npm node npx
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm "$@"
}

# Single lazy loader for all Node tools
for cmd in npm node npx; do
    eval "$cmd() { nvm > /dev/null; $cmd \"\$@\"; }"
done
```

Note `$HOME/.local/bin` is now folded into the cached PATH; delete the standalone `export PATH="$HOME/.local/bin:$PATH"` line from `zsh/.zshrc` (line 77 in the original numbering).

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash scripts/test-shell-config.sh`
Expected: all assertions pass.

- [ ] **Step 6: Verify the real shell**

```bash
rm -f "$HOME/.cache/zsh-path.cache"
zsh -i -c 'echo "PNPM_HOME=$PNPM_HOME"; echo "JAVA_HOME=$JAVA_HOME"'
```

Expected on Linux: `PNPM_HOME=/home/sefat/.local/share/pnpm`, `JAVA_HOME=/home/linuxbrew/.linuxbrew/opt/openjdk`.

`os.zsh` is not yet stowed into `~`, so this run reads it only if Task 8's stow has happened. Until then, confirm the values by sourcing directly:

```bash
zsh -c 'source zsh/.local/share/zsh/platform.zsh
        source stow-packages/os-linux/.local/share/zsh/os.zsh
        echo "$PNPM_HOME | $JAVA_HOME"'
```

- [ ] **Step 7: Commit**

```bash
git add stow-packages/os-darwin stow-packages/os-linux \
        zsh/.local/share/zsh/exports.zsh zsh/.zshrc scripts/test-shell-config.sh
git commit -m "feat(zsh): add os-darwin/os-linux packages and rework exports

exports.zsh now consumes OS_PATH_ENTRIES from the stow-selected os.zsh
and invalidates its PATH cache when any input changes. Supersedes the
commented-out per-OS blocks."
```

---

### Task 5: Move machine-specific lines to ~/.zsh.local

These four PATH entries are one Mac's leftovers appended by tool installers — not macOS properties. They belong in neither OS overlay.

**Files:**
- Modify: `zsh/.zshrc` (remove the Rancher/LM Studio/Antigravity blocks; source `~/.zsh.local`)
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nothing.
- Produces: `~/.zsh.local` as the documented per-machine escape hatch, sourced last.

- [ ] **Step 1: Delete the machine-specific blocks from .zshrc**

Remove these blocks entirely (original line numbers 69-83):

```zsh
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/sefat/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/sefat/.lmstudio/bin"
# End of LM Studio CLI section

# Added by Antigravity
export PATH="/Users/sefat/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/sefat/.antigravity-ide/antigravity-ide/bin:$PATH"
```

- [ ] **Step 2: Source ~/.zsh.local last**

At the very end of `zsh/.zshrc`, after the starship block, append:

```zsh
# Per-machine overrides. Gitignored, sourced last so it always wins.
# This is where tool installers' "Added by X" PATH lines belong - putting them
# in tracked config is what made this repo machine-specific in the first place.
[[ -f ~/.zsh.local ]] && source ~/.zsh.local

unset -f _source_if_exists
```

Remove the existing standalone `unset -f _source_if_exists` (original line 26) so the helper survives until all sourcing is done.

- [ ] **Step 3: Create the local file on this machine with its Linux equivalents**

```bash
cat > ~/.zsh.local <<'EOF'
# Per-machine PATH entries. Not tracked in git.
# Add tool-installer lines here rather than letting them append to ~/.zshrc.
EOF
```

On the Mac, this file is where the four removed lines get re-added, with their real `/Users/sefat` paths. Record that in the commit message so it is not lost.

- [ ] **Step 4: Ignore it and the Claude local settings**

Append to `.gitignore`:

```
# Per-machine shell overrides (see zsh/.zshrc)
.zsh.local

# Machine-local tool state; the .local.json suffix implies it was never
# meant to be tracked
.claude/settings.local.json
```

Then untrack the settings file without deleting it:

```bash
git rm --cached .claude/settings.local.json
```

- [ ] **Step 5: Verify**

```bash
bash scripts/check-portability.sh
zsh -i -c 'echo ok'
```
Expected: `zsh/.zshrc` no longer appears in the guard output. Shell starts clean.

- [ ] **Step 6: Commit**

```bash
git add zsh/.zshrc .gitignore
git commit -m "refactor(zsh): move machine-specific PATH lines to ~/.zsh.local

Rancher Desktop, LM Studio, and Antigravity entries were one Mac's
installer leftovers, not macOS config. ON THE MAC: re-add these four
PATH lines to ~/.zsh.local after pulling."
```

---

### Task 6: Split the ghostty config

**Files:**
- Modify: `ghostty/config`
- Create: `stow-packages/os-darwin/.config/ghostty/os.conf`
- Create: `stow-packages/os-linux/.config/ghostty/os.conf`

**Interfaces:**
- Consumes: the `os-darwin`/`os-linux` packages created in Task 4.
- Produces: the stable include target `~/.config/ghostty/os.conf`.

- [ ] **Step 1: Verify how ghostty resolves config-file**

The spec flags this as unverified — ghostty is not installed on the Linux machine. Check before relying on a relative path:

```bash
command -v ghostty >/dev/null && ghostty +show-config --help 2>&1 | head -20 \
    || echo "ghostty not installed here - use the absolute path form"
```

If ghostty is unavailable or the relative form is not confirmed, use the absolute form `config-file = ~/.config/ghostty/os.conf` in Step 2. Both are correct; the relative form is merely tidier.

- [ ] **Step 2: Strip macOS-only keys from the base config**

In `ghostty/config`, delete these lines:

- Line 1: `macos-icon = xray`
- Line 54: `macos-titlebar-style = hidden`
- Line 55: `macos-non-native-fullscreen = true`
- Lines 66-67: the `super+c` / `super+v` keybinds
- Line 83: `keybind = cmd+s=text:\x01\x73`
- Line 86: `keybind = cmd+b=text:\x01\x7a`

Then append at the end of the file:

```
# ─── PLATFORM ───
# Whichever of os-darwin/os-linux is stowed provides this file. The installer
# always places one, so the include always resolves.
config-file = os.conf
```

- [ ] **Step 3: Fix the font family typo**

`font-monaspace` installs the family `Monaspace Neon`, but lines 30, 32, 34, and 36 say `"Monsaspace Neon"` — so ghostty has been silently falling back to its default font. Replace all four occurrences of `Monsaspace Neon` with `Monaspace Neon`.

- [ ] **Step 4: Write the darwin fragment**

Create `stow-packages/os-darwin/.config/ghostty/os.conf`:

```
# macOS-only ghostty settings. Reaches ~ only via the os-darwin package.

macos-icon = xray
macos-titlebar-style = hidden
macos-non-native-fullscreen = true

keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard

# tmux integration: prefix + s (save-buffer)
keybind = cmd+s=text:\x01\x73
# tmux integration: prefix + z (toggle zoom)
keybind = cmd+b=text:\x01\x7a
```

- [ ] **Step 5: Write the linux fragment**

Create `stow-packages/os-linux/.config/ghostty/os.conf`:

```
# Linux-only ghostty settings. Reaches ~ only via the os-linux package.
#
# On macOS `super` is Command; on Linux it is the Windows key, which most
# desktop environments already claim. Use ctrl+shift instead - the X11/Wayland
# terminal convention.

keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard

# tmux integration: prefix + s (save-buffer)
keybind = ctrl+shift+s=text:\x01\x73
# tmux integration: prefix + z (toggle zoom)
keybind = ctrl+shift+b=text:\x01\x7a
```

- [ ] **Step 6: Verify no macOS keys remain in the base**

Run: `grep -n "macos\|cmd+\|super+" ghostty/config`
Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add ghostty/config stow-packages/os-darwin/.config/ghostty \
        stow-packages/os-linux/.config/ghostty
git commit -m "refactor(ghostty): split OS-specific settings into os.conf

Base config includes a stable os.conf path; the installer decides which
fragment lands there. Also fixes the Monsaspace/Monaspace font typo that
made ghostty fall back to its default font on macOS."
```

---

### Task 7: Split the alacritty config

This task carries a structural prerequisite the other terminal split did not need.

**Files:**
- Modify: `stow-packages/shell/.config/alacritty` (symlink → real directory)
- Modify: `alacritty/alacritty.toml`
- Create: `stow-packages/os-darwin/.config/alacritty/os.toml`
- Create: `stow-packages/os-linux/.config/alacritty/os.toml`

**Interfaces:**
- Consumes: the OS packages from Task 4.
- Produces: the stable include target `~/.config/alacritty/os.toml`.

- [ ] **Step 1: Understand why the package layout must change first**

`stow-packages/shell/.config/alacritty` is currently a **symlink to a directory** (`-> ../../../alacritty`). Stow treats a symlink as a file and links it whole, so `~/.config/alacritty` becomes a symlink into the repo — and `os-linux` cannot then place `os.toml` *inside* it. Stow would report a conflict.

`ghostty` does not have this problem because it is already a real directory containing individual files, which lets stow unfold it.

Convert alacritty to match:

```bash
cd stow-packages/shell/.config
rm alacritty
mkdir alacritty
ln -s ../../../../alacritty/alacritty.toml alacritty/alacritty.toml
ln -s ../../../../alacritty/themes alacritty/themes
cd -
```

Note the relative depth: entries inside `stow-packages/shell/.config/alacritty/` need four `../` to reach the repo root, not three.

- [ ] **Step 2: Verify the new symlinks resolve**

```bash
/bin/ls -l stow-packages/shell/.config/alacritty/
readlink -f stow-packages/shell/.config/alacritty/alacritty.toml
```
Expected: both entries are symlinks; the second prints `/home/sefat/.dotfiles/alacritty/alacritty.toml`.

- [ ] **Step 3: Strip macOS-only settings from the base config**

In `alacritty/alacritty.toml`:

Replace the `[general]` block (lines 2-5) with:

```toml
[general]
import = [
    "~/.config/alacritty/themes/themes/gruvbox_material_medium_dark.toml",
    # Whichever of os-darwin/os-linux is stowed provides this. Last import wins,
    # so platform values override the theme.
    "~/.config/alacritty/os.toml"
]
```

Delete line 14 (`decorations = "Buttonless"  # macOS: hides titlebar`) from the `[window]` block.

Delete lines 59-67 entirely (both `[[keyboard.bindings]]` blocks using `mods = "Command"`).

- [ ] **Step 4: Write the darwin fragment**

Create `stow-packages/os-darwin/.config/alacritty/os.toml`:

```toml
# macOS-only alacritty settings. Reaches ~ only via the os-darwin package.

[window]
decorations = "Buttonless"  # hides the titlebar, keeps the traffic lights

[[keyboard.bindings]]
key = "C"
mods = "Command"
action = "Copy"

[[keyboard.bindings]]
key = "V"
mods = "Command"
action = "Paste"
```

- [ ] **Step 5: Write the linux fragment**

Create `stow-packages/os-linux/.config/alacritty/os.toml`:

```toml
# Linux-only alacritty settings. Reaches ~ only via the os-linux package.
#
# "Buttonless" is a macOS-only value. "none" is the closest Linux equivalent:
# no window decorations at all.

[window]
decorations = "none"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"

[[keyboard.bindings]]
key = "V"
mods = "Control|Shift"
action = "Paste"
```

- [ ] **Step 6: Note the unverified import semantics**

The spec flags this: alacritty is not installed here, so whether `import` **appends** `[[keyboard.bindings]]` or **replaces** the array is unconfirmed. If, when alacritty is next run, the OS bindings are the *only* ones present and something else was lost, the fallback is to move all bindings into the two fragments. Nothing else in the design depends on the answer.

Record the check in the commit message so it is not forgotten.

- [ ] **Step 7: Commit**

```bash
git add alacritty/alacritty.toml stow-packages/shell/.config/alacritty \
        stow-packages/os-darwin/.config/alacritty stow-packages/os-linux/.config/alacritty
git commit -m "refactor(alacritty): split OS settings into os.toml

Converts the package entry from a directory symlink to a real directory
so stow can unfold it and the OS packages can contribute os.toml.

UNVERIFIED: whether alacritty's import appends or replaces
[[keyboard.bindings]]. If bindings go missing, move all of them into the
os.toml fragments."
```

---

### Task 8: Move macOS-only GUI packages into os-darwin

**Files:**
- Create: `stow-packages/os-darwin/.config/aerospace` (symlink)
- Create: `stow-packages/os-darwin/.config/raycast` (symlink)
- Modify: `stow-packages/shell/.config/aerospace` (remove)

**Interfaces:**
- Consumes: the `os-darwin` package.
- Produces: aerospace and raycast reachable only on macOS.

- [ ] **Step 1: Move aerospace out of the shared shell package**

```bash
rm stow-packages/shell/.config/aerospace
mkdir -p stow-packages/os-darwin/.config
ln -s ../../../aerospace stow-packages/os-darwin/.config/aerospace
```

- [ ] **Step 2: Add raycast, which was not previously stowed at all**

```bash
ln -s ../../../raycast stow-packages/os-darwin/.config/raycast
```

- [ ] **Step 3: Verify the symlinks resolve**

```bash
readlink -f stow-packages/os-darwin/.config/aerospace
readlink -f stow-packages/os-darwin/.config/raycast
```
Expected: `/home/sefat/.dotfiles/aerospace` and `/home/sefat/.dotfiles/raycast`.

- [ ] **Step 4: Remove the stale aerospace symlink from $HOME**

Because `shell` no longer provides it, restow to clear it:

```bash
cd stow-packages && stow -R -t ~ shell && cd ..
[[ -e ~/.config/aerospace ]] && echo "STILL PRESENT - remove by hand" || echo "gone, as expected on Linux"
```

- [ ] **Step 5: Commit**

```bash
git add stow-packages/shell/.config stow-packages/os-darwin/.config
git commit -m "refactor(stow): move aerospace and raycast into os-darwin

They are macOS-only, so on Linux they are now absent rather than skipped."
```

---

### Task 9: Split the Brewfile

**Files:**
- Modify: `brew/Brewfile`
- Create: `brew/Brewfile.darwin`
- Create: `brew/Brewfile.linux`

**Interfaces:**
- Consumes: nothing.
- Produces: `brew/Brewfile.$DOTFILES_OS`, consumed by Task 10.

- [ ] **Step 1: Extract the casks and the macOS-only tap**

```bash
{
    echo "# macOS-only Homebrew entries."
    echo "# Casks do not exist on linuxbrew, so every cask lives here by definition."
    echo
    grep '^tap "nikitabobko/tap"' brew/Brewfile
    echo
    grep '^cask ' brew/Brewfile
} > brew/Brewfile.darwin
```

- [ ] **Step 2: Create the Linux file**

```bash
cat > brew/Brewfile.linux <<'EOF'
# Linux-only Homebrew entries.
#
# Intentionally near-empty: all 68 shared formulae are portable and stay in
# Brewfile. This exists so Linux-only additions have an obvious home rather than
# being commented into the shared file.
EOF
```

- [ ] **Step 3: Remove the extracted lines from the shared Brewfile**

```bash
grep -v '^cask ' brew/Brewfile | grep -v '^tap "nikitabobko/tap"' > brew/Brewfile.tmp
mv brew/Brewfile.tmp brew/Brewfile
```

- [ ] **Step 4: Verify the split is lossless**

```bash
echo "casks moved:  $(grep -c '^cask ' brew/Brewfile.darwin)   (expect 44)"
echo "casks left:   $(grep -c '^cask ' brew/Brewfile)          (expect 0)"
echo "formulae:     $(grep -c '^brew ' brew/Brewfile)          (expect 68)"
echo "taps left:    $(grep -c '^tap ' brew/Brewfile)           (expect 8)"
```

All four must match. If the formula count moved, the `grep -v` was too broad — revert and redo.

- [ ] **Step 5: Commit**

```bash
git add brew/Brewfile brew/Brewfile.darwin brew/Brewfile.linux
git commit -m "refactor(brew): split Brewfile by platform

44 casks and the aerospace tap move to Brewfile.darwin. All 68 formulae
are portable and stay shared."
```

---

### Task 10: Make setup.sh cross-platform

**Files:**
- Modify: `setup.sh` — `check_prerequisites()` (`:77-108`), `setup_homebrew()` (`:145-194`), `setup_brewfile_deps()` (`:304-342`), `setup_dotfiles()` (`:345-385`)

**Interfaces:**
- Consumes: `brew/Brewfile.$DOTFILES_OS` from Task 9; the OS packages from Tasks 4-8.
- Produces: `detect_platform()`, setting `DOTFILES_OS` and `BREW_PREFIX` for the rest of the script.

- [ ] **Step 1: Replace the macOS hard-fail with platform detection**

In `setup.sh`, replace lines 80-86:

```bash
    log_check "Operating System"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script requires macOS"
        exit 1
    fi
    local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    log_success "macOS detected (version: $macos_version)"
```

with:

```bash
    log_check "Operating System"
    detect_platform
    if [[ "$DOTFILES_OS" == "darwin" ]]; then
        local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
        log_success "macOS detected (version: $macos_version)"
    else
        local distro=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo "Linux")
        log_success "Linux detected ($distro)"
    fi
```

Then guard the Xcode check that follows (lines 88-96) so it only runs on macOS — wrap that block in `if [[ "$DOTFILES_OS" == "darwin" ]]; then ... fi`.

- [ ] **Step 2: Add detect_platform above check_prerequisites**

Insert immediately before `check_prerequisites()` (line 77):

```bash
# Mirrors zsh/.local/share/zsh/platform.zsh. Keep the two in sync: the shell and
# the installer must agree on what platform this is and where brew lives.
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            DOTFILES_OS=darwin
            BREW_PREFIX=/opt/homebrew
            ;;
        Linux)
            DOTFILES_OS=linux
            BREW_PREFIX=/home/linuxbrew/.linuxbrew
            ;;
        *)
            log_error "Unsupported OS: $(uname -s). This setup supports macOS and Linux."
            exit 1
            ;;
    esac
    export DOTFILES_OS BREW_PREFIX
}
```

- [ ] **Step 3: Make Homebrew install work on both, and stop writing into tracked config**

Replace lines 165-192 (the body of the `if ask_confirmation ...` branch) with:

```bash
        if ask_confirmation "Do you want to install Homebrew?"; then
            # Homebrew on Linux needs these before its installer will run.
            if [[ "$DOTFILES_OS" == "linux" ]] && command_exists apt-get; then
                log_info "Installing Homebrew's Linux prerequisites..."
                sudo apt-get update -qq
                sudo apt-get install -y build-essential procps curl file git
            fi

            log_info "Installing Homebrew..."
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                # Intel Macs put brew at /usr/local, not /opt/homebrew.
                if [[ "$DOTFILES_OS" == "darwin" && "$(uname -m)" != "arm64" ]]; then
                    BREW_PREFIX=/usr/local
                    export BREW_PREFIX
                    log_warning "Intel Mac detected: brew prefix is /usr/local, but"
                    log_warning "platform.zsh assumes /opt/homebrew. Update it if this is your machine."
                fi

                eval "$("$BREW_PREFIX/bin/brew" shellenv)"

                # Deliberately does NOT append to ~/.zprofile. That file is a stow
                # symlink into the repo, so appending writes into tracked config -
                # which is how installer cruft got committed in the first place.
                # .zprofile already runs the shellenv eval via $BREW_PREFIX.
                log_success "Homebrew installed successfully"
            else
                log_error "Failed to install Homebrew"
                exit 1
            fi
        else
            log_error "Homebrew installation declined. Cannot continue without package manager."
            echo -e "${YELLOW}To proceed manually:${NC}"
            echo "1. Install Homebrew: https://brew.sh"
            echo "2. Run this script again"
            exit 1
        fi
```

Also update the prose at line 160 from "Homebrew is the recommended package manager for macOS." to "Homebrew is the package manager used on both macOS and Linux here."

- [ ] **Step 4: Bundle both Brewfiles**

In `setup_brewfile_deps()`, after the existing shared-Brewfile block completes (after line 341, inside the function), add:

```bash
    local os_brewfile="$HOME/.dotfiles/brew/Brewfile.$DOTFILES_OS"
    log_check "Platform Brewfile ($DOTFILES_OS)"
    if file_exists "$os_brewfile"; then
        log_info "Installing $DOTFILES_OS-specific packages..."
        if brew bundle --file="$os_brewfile"; then
            log_success "Platform packages installed"
        else
            log_warning "Some platform packages failed to install"
        fi
    else
        log_skip "No platform Brewfile for $DOTFILES_OS"
    fi
```

- [ ] **Step 5: Replace package auto-discovery with an explicit list**

This is the change that makes the new layout safe. Replace lines 366-372:

```bash
    log_check "Available stow packages"
    local packages=($(find "$stow_dir" -maxdepth 1 -type d -not -name "." -not -name ".." -exec basename {} \;))
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warning "No stow packages found in $stow_dir"
        return
    fi
    log_info "Found packages: ${packages[*]}"
```

with:

```bash
    # Explicit, NOT auto-discovered. Auto-discovery would stow os-darwin AND
    # os-linux on the same machine, which conflicts at ~/.config/ghostty/os.conf.
    local packages=(shell editor pi "os-$DOTFILES_OS")
    log_info "Stowing packages: ${packages[*]}"

    # Remove the other platform's package if a previous run or another machine
    # left it behind.
    local other_os=darwin
    [[ "$DOTFILES_OS" == "darwin" ]] && other_os=linux
    if [[ -d "$stow_dir/os-$other_os" ]]; then
        (cd "$stow_dir" && stow -D -t ~ "os-$other_os" 2>/dev/null) && \
            log_info "Unstowed os-$other_os"
    fi
```

Leave the `cd "$stow_dir"` and the stow loop that follows (lines 374-384) unchanged — they iterate `${packages[@]}`, which is now the explicit list.

- [ ] **Step 6: Verify the script parses and detection works**

```bash
bash -n setup.sh && echo "syntax ok"
bash -c 'source <(sed -n "/^detect_platform()/,/^}/p" setup.sh); detect_platform; echo "$DOTFILES_OS $BREW_PREFIX"'
```
Expected: `syntax ok`, then `linux /home/linuxbrew/.linuxbrew`.

- [ ] **Step 7: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): make setup.sh cross-platform

Replaces the macOS hard-fail with detect_platform, installs Homebrew on
both platforms, bundles the per-OS Brewfile, and stows an explicit
package list instead of auto-discovering (which would have stowed both
OS packages at once).

Also stops appending brew shellenv to ~/.zprofile, which is a stow
symlink into the repo."
```

---

### Task 11: Install fonts on Linux

The one gap Homebrew-on-both does not close: linuxbrew has no cask support, and the terminal configs name specific families.

**Files:**
- Modify: `setup.sh` (add `setup_fonts()`, call it from `main()`)

**Interfaces:**
- Consumes: `DOTFILES_OS` from Task 10.
- Produces: `setup_fonts()`.

- [ ] **Step 1: Add setup_fonts**

Insert before `verify_installation()` (line 418):

```bash
# On macOS the font casks in Brewfile.darwin handle this. linuxbrew has no cask
# support, so Linux needs a direct download. Scoped to the two families the
# terminal configs actually name, not all eight casks.
setup_fonts() {
    print_section "FONTS"

    if [[ "$DOTFILES_OS" == "darwin" ]]; then
        log_skip "Fonts come from Brewfile.darwin casks on macOS"
        return
    fi

    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"

    local nerd_version="v3.2.1"
    local base="https://github.com/ryanoasis/nerd-fonts/releases/download/$nerd_version"

    # name:archive - the families referenced by ghostty/config and alacritty.toml
    local fonts=(
        "JetBrainsMono:JetBrainsMono.zip"
        "Monaspace:Monaspace.zip"
    )

    for entry in "${fonts[@]}"; do
        local name="${entry%%:*}"
        local archive="${entry##*:}"

        log_check "Font: $name"
        if fc-list 2>/dev/null | grep -qi "$name"; then
            log_skip "$name already installed"
            continue
        fi

        log_info "Downloading $name..."
        local tmp
        tmp="$(mktemp -d)"
        if curl -fsSL "$base/$archive" -o "$tmp/$archive"; then
            unzip -qo "$tmp/$archive" -d "$font_dir/$name" \
                -x '*.txt' '*.md' 2>/dev/null
            log_success "$name installed"
        else
            log_warning "Failed to download $name from $base/$archive"
        fi
        rm -rf "$tmp"
    done

    log_info "Rebuilding font cache..."
    fc-cache -f >/dev/null 2>&1
    log_success "Font cache rebuilt"
}
```

- [ ] **Step 2: Ensure unzip and fontconfig exist on Linux**

In `setup_essential_tools()`, after the existing GNU Stow block (after line 228), add:

```bash
    if [[ "$DOTFILES_OS" == "linux" ]]; then
        log_check "Font tooling (unzip, fontconfig)"
        if command_exists unzip && command_exists fc-cache; then
            log_skip "Font tooling already present"
        elif command_exists apt-get; then
            sudo apt-get install -y unzip fontconfig && \
                log_success "Font tooling installed"
        else
            log_warning "unzip/fontconfig missing and apt-get unavailable - fonts will be skipped"
        fi
    fi
```

- [ ] **Step 3: Call it from main()**

In `main()` (line 486), add `setup_fonts` immediately after the `setup_brewfile_deps` call.

- [ ] **Step 4: Verify syntax, then test the function in isolation**

```bash
bash -n setup.sh && echo "syntax ok"
```

Then run the real thing and confirm the fonts resolve:

```bash
fc-list | grep -ci monaspace
fc-list | grep -ci jetbrains
```
Expected after a run: both greater than 0.

- [ ] **Step 5: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): install nerd fonts on Linux

Casks cover this on macOS; linuxbrew has no cask support. Scoped to the
two families the terminal configs name."
```

---

### Task 12: Fix bash-install.sh

**Files:**
- Modify: `bash-install.sh` — delete `create_linux_exports()` (`:225-232`), rewrite `setup_dotfiles()` (`:249-270`)

**Interfaces:**
- Consumes: the OS packages from Task 4.
- Produces: no new names. Removes `create_linux_exports`.

- [ ] **Step 1: Understand the bug being removed**

`create_linux_exports()` runs `cat > ~/.local/share/zsh/exports.zsh` with an **empty heredoc** (`:229-230`), and it is called at `:260` — immediately after `stow -t ~ shell` at `:259` made that path a symlink into the repo. The write follows the symlink and truncates the tracked `zsh/.local/share/zsh/exports.zsh` to zero bytes.

Beyond being destructive, it is a second, competing definition of exports — exactly what this project exists to eliminate.

- [ ] **Step 2: Delete the function**

Remove lines 225-232 in full:

```bash
create_linux_exports() {
    log_info "Creating Linux-compatible exports..."
    mkdir -p ~/.local/share/zsh
    
    cat > ~/.local/share/zsh/exports.zsh << 'EOF'
EOF
    log_success "Linux exports created"
}
```

- [ ] **Step 3: Rewrite setup_dotfiles to use the shared packages**

Replace lines 249-270:

```bash
setup_dotfiles() {
    log_info "Setting up dotfiles..."

    if [ ! -d "stow-packages" ]; then
        log_error "stow-packages/ not found. Run this from the dotfiles repo root."
        return 1
    fi

    # Containers are always Linux. Matches setup.sh's explicit list rather than
    # auto-discovering, so os-darwin is never stowed here.
    local packages="shell editor pi os-linux"

    cd stow-packages
    for package in $packages; do
        if [ -d "$package" ]; then
            if stow -t ~ "$package" 2>/dev/null || stow -R -t ~ "$package" 2>/dev/null; then
                log_success "Stowed $package"
            else
                log_warning "Failed to stow $package"
            fi
        else
            log_warning "Package not found: $package"
        fi
    done
    cd ..
}
```

The old `else` branch (the "Using direct configuration files..." fallback beginning at `:271`) becomes unreachable dead code once the guard clause above returns early. Delete it through to the end of the original function.

- [ ] **Step 4: Verify no caller of the deleted function remains**

```bash
grep -n "create_linux_exports" bash-install.sh || echo "no references - good"
bash -n bash-install.sh && echo "syntax ok"
```
Expected: `no references - good`, then `syntax ok`.

- [ ] **Step 5: Confirm exports.zsh is intact**

```bash
wc -l zsh/.local/share/zsh/exports.zsh
```
Expected: non-zero. If this ever reads 0, `create_linux_exports` truncated it — restore with `git checkout zsh/.local/share/zsh/exports.zsh`.

- [ ] **Step 6: Commit**

```bash
git add bash-install.sh
git commit -m "fix(bash-install): remove destructive create_linux_exports

It wrote an empty heredoc through a stow symlink, truncating the tracked
exports.zsh to zero bytes. It was also a competing definition of exports.
Now stows the same shared packages as setup.sh."
```

---

### Task 13: Fix remaining hardcoded paths and stale docs

**Files:**
- Modify: `mcp/config.json:8-9`
- Modify: `docs/INSTALL.md:7-8`, `docs/MIGRATION.md:348`
- Modify: `readme.md`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing. This task drives the guard's last violation (`mcp/config.json`) to zero.

- [ ] **Step 1: Fix the MCP filesystem paths**

In `mcp/config.json`, replace lines 8-9:

```json
        "/Users/sefat/Desktop",
        "/Users/sefat/Downloads"
```

with:

```json
        "$HOME/Desktop",
        "$HOME/Downloads"
```

Known limitation, recorded in the spec: MCP clients do not uniformly expand `$HOME` inside `args`. This file is not stowed by any package today, so it is reference material and this does not regress anything. If a client is later pointed at it and passes the strings literally, it will need per-machine generation.

- [ ] **Step 2: Correct the macOS-only claims in the docs**

These are accuracy fixes, not guard violations — neither file contains a `/Users/` path. There are exactly three lines.

In `docs/INSTALL.md`, replace lines 7-8:

```markdown
1. **macOS** - This setup is designed for macOS
2. **Homebrew** - Package manager for macOS
```

with:

```markdown
1. **macOS or Linux** - The same tree runs on both; `setup.sh` detects which
2. **Homebrew** - Package manager on both platforms (`/opt/homebrew` on macOS, `/home/linuxbrew/.linuxbrew` on Linux)
```

In `docs/MIGRATION.md`, replace line 348:

```markdown
While this setup is macOS-focused, you can adapt for other platforms:
```

with:

```markdown
This setup runs on macOS and Linux from the same tree. Platform differences live
in the `os-darwin` / `os-linux` stow packages; only one is ever installed. To add
a third platform, add an `os-<name>` package and a case to `platform.zsh`.
```

- [ ] **Step 3: Update readme.md for the new model**

Replace the "Manual Setup" and "Usage" fenced blocks in `readme.md` with:

````markdown
## Manual Setup

```bash
# Install dependencies (shared + your platform's)
brew bundle --file=~/.dotfiles/brew/Brewfile
brew bundle --file=~/.dotfiles/brew/Brewfile.$(uname -s | tr '[:upper:]' '[:lower:]')

# Setup dotfiles - note the per-OS package
cd ~/.dotfiles/stow-packages
stow -t ~ shell editor pi os-linux    # or os-darwin on macOS
```

## Platform Support

Runs on macOS and Linux from the same tree, with no commented-out blocks.

- Shared config lives in `shell`, `editor`, `pi`.
- Platform config lives in `os-darwin` / `os-linux`. Only one is ever stowed.
- Machine-specific PATH entries go in `~/.zsh.local` (gitignored), never in tracked config.

Run `scripts/check-portability.sh` before committing; it fails if an OS-specific
path leaks into shared config.
````

- [ ] **Step 4: Confirm the guard's allowlist still needs no changes**

No edit to `scripts/check-portability.sh` is expected here. `docs/INSTALL.md` and `docs/MIGRATION.md` were never allowlisted because they never tripped a rule, and `docs/superpowers/*` stays exempt permanently — specs and plans must be able to quote the patterns.

Verify the allowlist has not silently grown:

```bash
grep -c 'return 0' scripts/check-portability.sh
```
Expected: `7` — three in `is_exempt_all`, three in `is_brew_allowed`, one in `is_users_allowed`. A higher number means an entry was added without justification, which is how a guard rots into decoration.

- [ ] **Step 5: Verify**

```bash
bash scripts/check-portability.sh
bash scripts/test-check-portability.sh
```
Expected: guard reports `clean`; tests still pass.

- [ ] **Step 6: Commit**

```bash
git add mcp/config.json docs/INSTALL.md docs/MIGRATION.md readme.md scripts/check-portability.sh
git commit -m "docs: update for cross-platform setup, fix hardcoded paths"
```

---

### Task 14: Full verification

**Files:** none modified unless a check fails.

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Guard is green**

Run: `bash scripts/check-portability.sh; echo "exit=$?"`
Expected: `check-portability: clean`, `exit=0`.

This is the definition of done from the spec.

- [ ] **Step 2: All tests pass**

```bash
bash scripts/test-check-portability.sh
bash scripts/test-shell-config.sh
```
Expected: `0 failed` from both.

- [ ] **Step 3: Restow from scratch and confirm the right packages landed**

```bash
cd stow-packages
stow -D -t ~ shell editor pi 2>/dev/null
stow -t ~ shell editor pi os-linux
cd ..

echo "--- should exist (linux) ---"
readlink -f ~/.config/ghostty/os.conf
readlink -f ~/.local/share/zsh/os.zsh

echo "--- should NOT exist on linux ---"
[[ -e ~/.config/aerospace ]] && echo "FAIL: aerospace present" || echo "ok: aerospace absent"
```

Expected: the two `readlink` calls resolve into `stow-packages/os-linux/`, and aerospace is absent.

- [ ] **Step 4: Shell smoke test**

```bash
zsh -i -c 'echo "OS=$DOTFILES_OS PREFIX=$BREW_PREFIX PNPM=$PNPM_HOME"' 2>&1
```
Expected: `OS=linux PREFIX=/home/linuxbrew/.linuxbrew PNPM=/home/sefat/.local/share/pnpm`, with no errors or warnings on stderr.

- [ ] **Step 5: Startup time did not regress**

```bash
rm -f ~/.cache/zsh-path.cache
time zsh -i -c exit          # cold: rebuilds the cache
for i in 1 2 3; do /usr/bin/time -f "%e" zsh -i -c exit; done   # warm
```

Expected: warm runs comparable to before the change. `platform.zsh` adds one `uname` at login only. If warm startup grew noticeably, the PATH cache is being rebuilt every run — check the staleness comparison in `exports.zsh`.

- [ ] **Step 6: Installer is idempotent**

```bash
bash -n setup.sh && bash -n bash-install.sh && echo "both parse"
```

Then run `./setup.sh` twice. The second run must report skips throughout and change nothing.

- [ ] **Step 7: Hand the macOS half to the user**

The Mac cannot be verified from here. Report to the user that these need checking on the Mac:

1. `./setup.sh` completes and stows `os-darwin`, not `os-linux`.
2. `~/.config/aerospace` and `~/.config/raycast` exist.
3. Ghostty: titlebar hidden, `cmd+c`/`cmd+v` work, and the font is now genuinely Monaspace (it was falling back to the default before the typo fix).
4. Alacritty: titlebar hidden, `cmd+c`/`cmd+v` work — **and confirm no other keybindings were lost**, which settles the unverified `import` question from Task 7.
5. Re-add the four machine PATH lines (Rancher, LM Studio, Antigravity ×2) to `~/.zsh.local` — they were deliberately removed from tracked config in Task 5.
6. `bash scripts/check-portability.sh` reports clean there too.

- [ ] **Step 8: Final commit**

```bash
git add -A
git commit -m "chore: verify cross-platform dotfiles on Linux

Guard clean, tests passing, correct packages stowed, startup time
unchanged. macOS verification pending on that machine."
```

---

## Post-Implementation Notes

**Deferred, recorded in the spec, not addressed here:**

- `.p10k.zsh` is stowed but `.zshrc` initializes starship. One is likely dead config.
- `.zprofile` sources `~/.zshrc` at its end, so interactive login shells source `.zshrc` twice. Pre-existing; `platform.zsh`'s idempotence guard makes it harmless for this work, but it is wasted startup time.
- `mcp/config.json` `$HOME` expansion depends on the consuming MCP client.

**Adding a new setting after this lands:**

1. Does it work identically on both? → shared package. This is the default and should cover most cases.
2. Genuinely different per OS? → both `os.zsh` files, or both terminal fragments. Never one.
3. True of this machine only? → `~/.zsh.local`.

Run `scripts/check-portability.sh` before committing.
