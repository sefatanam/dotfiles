# Cross-Platform Dotfiles: macOS + Ubuntu Without Comment/Uncomment

**Date:** 2026-08-16
**Status:** Approved design, ready for implementation planning
**Branch:** `for-linux`

## Problem

The repo was built for macOS. Running it on an Ubuntu desktop requires hand-editing
paths and commenting/uncommenting blocks in place. That work is destructive: making
Linux work breaks the Mac, and the diff cannot be committed without breaking the other
machine. There is no way to have both machines correct at the same time.

Grep hits for `/opt/homebrew`, `/Users/sefat`, `/home/linuxbrew`, `darwin`, or `macos`
across tracked files. Not every hit is a defect — `setup.sh`'s brew paths are legitimate,
and `ghostty`'s `macos-*` are real option names — but the distribution shows where the
work is:

| File | Hits | Nature |
|---|---|---|
| `zsh/.zshrc` | 14 | defects |
| `zsh/.local/share/zsh/exports.zsh` | 12 | defects |
| `zsh/.zprofile` | 10 | defects |
| `setup.sh` | 9 | legitimate, but macOS-only logic |
| `ghostty/config` | 3 | real option names, need relocating |
| `macos/system-override` | 3 | legitimately macOS-only |
| `.claude/settings.local.json` | 3 | stale machine paths |
| `mcp/config.json` | 2 | defects — see below |
| `docs/INSTALL.md`, `docs/MIGRATION.md` | 3 | stale documentation |
| `zsh/.local/share/zsh/completions.zsh` | 1 | defect |
| `alacritty/alacritty.toml` | 1 | needs relocating |
| `wezterm/.wezterm.lua` | 1 | commented-out, inert |
| `aerospace/aerospace.toml` | 1 | prose comment, inert |

Two distinct problems are tangled together in those lines:

- **OS-specific**: the Homebrew prefix, `macos-titlebar-style`, `decorations = "Buttonless"`.
- **Machine-specific**: `/Users/sefat/.rd/bin`, LM Studio, Antigravity, JetBrains Toolbox.
  These are one Mac's leftovers appended by tool installers, not properties of macOS.

Conflating the two is part of why this became painful. The design separates them.

## Goals

1. Both machines run from the same committed tree with no local edits.
2. No commented-out OS blocks anywhere.
3. Adding a setting has one obvious home.
4. Regression into the old pattern is caught automatically, not by discipline.
5. Shell startup time does not regress.

## Non-Goals

Explicitly out of scope. These were considered and rejected:

- **A per-host layer.** Two machines, one axis (OS). Not needed.
- **Linux WM configs** (sway/i3/hyprland mirroring aerospace).
- **Templating or chezmoi.** Every tool involved supports includes; generated configs
  would mean edits to files in `~` silently evaporate.
- **Changes to nvim or tmux.** Already portable (see Decisions).
- **Refactoring `functions.zsh`** (627 lines). Its problems are not portability problems.

## Decisions

### D1 — Homebrew is the package manager on both platforms

Ubuntu keeps using linuxbrew at `/home/linuxbrew/.linuxbrew`.

**Consequence:** most divergence collapses into a single variable. `brew --prefix`
resolves to `/opt/homebrew` or `/home/linuxbrew/.linuxbrew`, so paths for
zsh-autosuggestions, zsh-syntax-highlighting, nvm, go, and openjdk become one shared
line each instead of two variants. This decision alone resolves roughly 25 of the 37
divergent lines without introducing any conditional.

### D2 — One axis: OS. No host layer.

One Mac, one Ubuntu desktop. Machine-specific content goes to a gitignored local file
rather than a third structural tier.

### D3 — macOS-only GUI configs are absent on Linux, not skipped

`aerospace`, `raycast`, and `macos/` move into a macOS-only stow package. On Linux they
are never stowed. No Linux counterparts are added.

### D4 — `bash-install.sh` is retained as a container bootstrap, stripped of config generation

It targets Docker containers and devpods where installing Homebrew is slow and awkward —
a legitimately different target from the Ubuntu desktop. But its `create_linux_exports()`
(`bash-install.sh:225`) generates a second, competing definition of exports and PATH.
That function is deleted; the script stows the shared packages instead.

### D5 — OS-specific content is selected by the installer, never branched on at runtime

Considered and rejected: using runtime `if [[ $OS == darwin ]]` for zsh (which supports
conditionals) and stow-selection only for ghostty/alacritty (which do not). Two
mechanisms means two mental models.

Instead, everything OS-specific is chosen by **which package got stowed**. On Linux the
macOS config is not skipped at runtime — it is physically not present in `~`. This is
what makes regression into comment/uncomment structurally impossible rather than merely
discouraged.

The single exception is computing the platform *facts* themselves, which is inherently
a runtime operation (see `platform.zsh`).

## Architecture

### Three tiers

| Tier | Holds | Location |
|---|---|---|
| `shared` | Anything working on both. The **default** home for every setting. | `stow-packages/{shell,editor,pi}` |
| `os` | Only genuinely divergent content. Never a copy of a shared setting. | `stow-packages/os-{darwin,linux}` |
| `local` | Per-machine: installer-appended PATH lines, secrets. Gitignored. | `~/.zsh.local`, existing `~/.private` |

### `platform.zsh` — the only runtime detection

New file: `zsh/.local/share/zsh/platform.zsh`

```zsh
case "$(uname -s)" in
  Darwin) DOTFILES_OS=darwin; BREW_PREFIX=/opt/homebrew ;;
  *)      DOTFILES_OS=linux;  BREW_PREFIX=/home/linuxbrew/.linuxbrew ;;
esac
```

It does **not** shell out to `brew --prefix`. The repo has been aggressively optimized
for startup (cached PATH, cached starship/zoxide/atuin init, lazy-loaded node), and a
subprocess per shell start would cut against that. A static per-OS constant costs
nothing and feeds the existing PATH cache identically.

Sourced first by `.zprofile` — it must exist before the `brew shellenv` eval, which
currently hardcodes the prefix — and again, idempotently, by `.zshrc`, because `.zshrc`
runs alone for non-login shells and cannot assume `.zprofile` ran. Idempotence is
achieved by a guard on `$DOTFILES_OS` already being set.

`setup.sh` and `bash-install.sh` must mirror this exact detection logic.

### Load order

`exports.zsh` builds a **cached** PATH, so it must run after OS values exist:

```
platform.zsh    facts only          DOTFILES_OS, BREW_PREFIX
os.zsh          OS values only      PNPM_HOME, JAVA_HOME, DYLD_*, OS_PATH_ENTRIES   [stow-selected]
exports.zsh     builds + caches PATH from the above
aliases.zsh
functions.zsh
completions.zsh
~/.zsh.local    per-machine, gitignored, has the last word
```

`os.zsh` sets variables only and **must not mutate `PATH`**. `exports.zsh` owns PATH
construction, so that the cache it writes remains the single source of truth.

Where a platform needs extra PATH entries, `os.zsh` declares them in an array:

```zsh
OS_PATH_ENTRIES=( "$HOME/Library/pnpm" )   # darwin
```

`exports.zsh` reads `$OS_PATH_ENTRIES` when assembling the cached PATH. This keeps
ordering deterministic and cacheable, which direct `PATH=` mutation in `os.zsh` would
not — the cache is written once and would capture whatever order happened to apply.

### Repo layout

New entries marked `[new]`:

```
stow-packages/
  shell/       .zshrc .zprofile .tmux.conf .p10k.zsh
               .config/{ghostty,alacritty,herdr}          base configs
               .local/share/zsh/{platform[new],exports,aliases,functions,completions}.zsh
  editor/      .config/nvim
  pi/          .pi/
  os-darwin/   [new]  .config/aerospace  .config/raycast
                      .config/ghostty/os.conf
                      .config/alacritty/os.toml
                      .local/share/zsh/os.zsh
  os-linux/    [new]  .config/ghostty/os.conf
                      .config/alacritty/os.toml
                      .local/share/zsh/os.zsh
```

Install becomes `stow -t ~ shell editor pi os-$DOTFILES_OS`.

The new OS packages follow the existing convention: symlink into a top-level source
directory where one already exists (`aerospace/`, `raycast/`), real files where one
does not.

This relies on GNU Stow's tree unfolding: when two packages both contribute
`.config/ghostty`, stow creates a real directory containing per-file symlinks rather
than one directory symlink. This is standard documented stow behavior.

## Detailed Changes

### zsh

| Today | Becomes |
|---|---|
| `.zprofile` brew shellenv, 2 variants | `eval "$($BREW_PREFIX/bin/brew shellenv)"` — shared |
| `.zprofile` nvm blocks, 2 variants | `$BREW_PREFIX/opt/nvm/nvm.sh` — shared |
| `.zshrc:27-28` autosuggestions, 2 variants | `$BREW_PREFIX/share/...` — shared |
| `.zshrc:31-32` syntax-highlighting, 2 variants | `$BREW_PREFIX/share/...` — shared |
| `exports.zsh:15` GOROOT, 2 variants | `$BREW_PREFIX/opt/go/libexec` — shared |
| `exports.zsh:25,27` `/Users/sefat/bin`, `.opencode/bin` | `$HOME/bin`, `$HOME/.opencode/bin` — shared |
| `completions.zsh:9` `/Users/sefat/.bun/_bun` | `$HOME/.bun/_bun` — shared |
| `PNPM_HOME` (`~/Library/pnpm` vs `~/.local/share/pnpm`) | `os.zsh` — genuinely divergent |
| `JAVA_HOME` (macOS needs `libexec/openjdk.jdk/Contents/Home`) | `os.zsh` — genuinely divergent |
| `DYLD_LIBRARY_PATH` | `os.zsh`, darwin only |
| `.zshrc:70,74,80,83` Rancher, LM Studio, Antigravity | `~/.zsh.local` — machine, not OS |
| `.zprofile:2` JetBrains Toolbox | `~/.zsh.local` — machine, not OS |

Note the shape: most divergence disappears into `$BREW_PREFIX` rather than into an OS
overlay. `os.zsh` ends up holding roughly four entries per platform. That is the payoff
of D1.

### Incidental bug fixes

These are live bugs found while reading, fixed as part of the work:

1. `zsh/.zprofile:10` — `export NVM DIR=` has a space instead of an underscore, so
   `NVM_DIR` is never set here.
2. `zsh/.zprofile:11` — stray trailing `]` after the nvm source line.
3. `zsh/.zshrc:84` — duplicate `brew shellenv` eval; `.zprofile:16` already does it.
4. `zsh/.zshrc:47` — `JAVA_HOME` set to a macOS path unconditionally.
5. `zsh/.local/share/zsh/completions.zsh:9` — hardcoded `/Users/sefat/.bun/_bun`.
6. `exports.zsh:4` — the PATH cache invalidates on `$0`'s mtime only, so editing
   `os.zsh` or `platform.zsh` would leave a stale cache. The check becomes the newest
   mtime among `platform.zsh`, `os.zsh`, and `exports.zsh`.
7. `ghostty/config:30,32,34,36` — font family is `"Monsaspace Neon"`, but the
   `font-monaspace` cask installs `Monaspace Neon`. The typo means ghostty has been
   silently falling back to its default font on macOS. Not a portability bug; fixed
   because it is in the lines being touched.

### ghostty and alacritty

Base configs keep everything portable and include a **fixed path**; the installer
decides what content is there. Because the installer always places an OS fragment, the
include always resolves — the design does not depend on optional-include support.

- `ghostty/config` — remove `macos-icon`, `macos-titlebar-style`,
  `macos-non-native-fullscreen`, and the `super+c` / `super+v` / `cmd+s` / `cmd+b`
  binds. Add `config-file = os.conf`.
- `os-darwin/.config/ghostty/os.conf` — those macOS keys and `cmd`-based binds, verbatim.
- `os-linux/.config/ghostty/os.conf` — `ctrl+shift+c` / `ctrl+shift+v`, and the two tmux
  passthrough binds remapped off `cmd`.
- `alacritty/alacritty.toml` — remove `decorations = "Buttonless"` and the two
  `mods = "Command"` bindings. Append `os.toml` to the existing `general.import` list,
  after the theme import so it wins.
- `os-{darwin,linux}/.config/alacritty/os.toml` — the removed values, per platform.

### mcp/config.json

`mcp/config.json:8-9` passes `/Users/sefat/Desktop` and `/Users/sefat/Downloads` to the
filesystem MCP server. These are broken on Linux, where `$HOME` is `/home/sefat`.

This file is **not stowed by any package** — no `stow-packages/*` entry references it, so
it is currently reference material rather than deployed config. Scoped fix: replace both
with `$HOME/Desktop` and `$HOME/Downloads`.

Caveat, deferred and non-blocking: MCP clients do not uniformly expand `$HOME` inside
`args`. If the consuming client passes them literally, the file needs per-machine
generation instead. That is not solved here, because the file is not deployed today and
solving it would pull templating (a non-goal) into scope. Recorded so it is not
rediscovered as a surprise.

### tmux, nvim — no changes

Both already converged on OSC 52 in commit `b485833` (`set -g set-clipboard on`,
`vim.g.clipboard` with `vim.ui.clipboard.osc52`). That approach is genuinely portable.
Checked for remaining macOS-only content; none found.

### setup.sh

Structure and logging are kept; changes are surgical.

- `check_prerequisites()` (`:77`) — the Darwin hard-fail at `:81` becomes
  `detect_platform()`, exporting `DOTFILES_OS` and `BREW_PREFIX`, mirroring
  `platform.zsh` exactly.
- `setup_homebrew()` (`:145`) — same official installer both ways. Linux additionally
  requires `build-essential procps curl file git` via apt first (Homebrew-on-Linux's
  documented prerequisite) and uses the linuxbrew shellenv prefix.
- `setup_brewfile_deps()` (`:304`) — run `brew bundle` on `brew/Brewfile`, then on
  `brew/Brewfile.$DOTFILES_OS` if it exists.
- `setup_dotfiles()` (`:345`) — **must change or the new layout breaks.** Line 367
  auto-discovers every directory under `stow-packages/` and stows all of them. Under the
  new layout that would stow `os-darwin` *and* `os-linux` on the same machine,
  conflicting at `~/.config/ghostty/os.conf`. Replace with an explicit list:
  `shell editor pi os-$DOTFILES_OS`.
- `setup_fonts()` — new; see Fonts below.
- `verify_installation()` (`:418`) — extend the tool list with OS-aware expectations.

### Brewfile split

| File | Contents |
|---|---|
| `brew/Brewfile` | 68 formulae + 8 portable taps |
| `brew/Brewfile.darwin` | 44 casks + `nikitabobko/tap` (aerospace) |
| `brew/Brewfile.linux` | initially near-empty; the honest home for future Linux-only entries |

Verified: none of the 68 formulae are macOS-only, so the split line is exactly the
cask boundary plus the one aerospace tap.

### Fonts

The one thing D1 does not solve. Casks carry the 8 fonts on macOS; linuxbrew has no cask
support. `setup_fonts()` runs on Linux only, fetching Nerd Fonts releases into
`~/.local/share/fonts` and running `fc-cache -f`. Scoped to the families the configs
actually reference — Monaspace and JetBrainsMono Nerd Font Propo — not all eight casks.

### bash-install.sh

Per D4: delete `create_linux_exports()` (`:225`). Replace its `setup_dotfiles()` stow
calls (`:249-266`) with the same explicit package list used by `setup.sh`, including
`os-linux`. Its apt-based essentials install is retained unchanged.

## Regression Guard

New: `scripts/check-portability.sh`. Roughly 40 lines of grep, exiting non-zero on:

1. `/opt/homebrew` or `/home/linuxbrew` outside the sanctioned set: `platform.zsh`,
   `setup.sh`, `bash-install.sh`.
2. `/Users/` in any tracked file outside the allowlist below.
3. Commented-out lines tagged `#For MacOS` / `#For Linux` / `# For Ubuntu`.
4. Both `os-darwin` and `os-linux` stowed into `~` simultaneously.

**Scope of rule 2.** It applies to shell config, scripts, and tool configs. Three
categories of existing `/Users/` hits are not portability defects in stowed config and
must be handled explicitly rather than silently tripping the guard:

| Location | Disposition |
|---|---|
| `mcp/config.json` | Fixed (see above); then subject to the rule |
| `docs/INSTALL.md`, `docs/MIGRATION.md` | Stale docs — updated as part of step 5, then subject to the rule |
| `.claude/settings.local.json` | Machine-local tool state, not dotfile config. Added to the allowlist; should also be gitignored, as `.local.json` implies it was never meant to be tracked |
| `macos/system-override` | Legitimately macOS-only; lives under `os-darwin` and is exempt |

The guard's allowlist is part of its source and must be justified inline — an unexplained
allowlist entry is how a guard rots into decoration.

**The project is done when it reports zero.** The current violation count is whatever the
script reports on first run; it is deliberately not asserted here, since the count depends
on the exact rules above and would be a fabricated precision. This check is what makes the
design hold over time rather than only on the day it ships.

## Migration Sequence

Ordered so the shell never breaks mid-way. Steps 1-3 are additive and reversible with
`git checkout`.

1. Add `platform.zsh` and `os.zsh`; source them; change nothing else. Verify the shell
   still starts.
2. Replace brew literals with `$BREW_PREFIX`. Largest win, lowest risk.
3. Move Rancher / LM Studio / Antigravity / Toolbox lines into `~/.zsh.local`.
4. Restructure stow packages: create `os-darwin` / `os-linux`, split the terminal
   configs. This is the only step touching symlinks in `~`; `stow -D` restores it.
5. Update `setup.sh` (including the auto-discovery fix), `bash-install.sh`, the Brewfile
   split, and fonts.
6. Add the lint guard and drive it to zero.

Prerequisite: the staged change in `zsh/.local/share/zsh/exports.zsh` must be committed
or stashed before starting. Work continues on branch `for-linux`.

## Verification Plan

| Check | How |
|---|---|
| Shell starts clean | `zsh -i -c exit` with no errors |
| Startup not regressed | Time `zsh -i -c exit` before and after; `platform.zsh` adds one `uname` at login only |
| No OS literals leaked | `scripts/check-portability.sh` exits 0 |
| Correct packages stowed | `os-linux` present in `~`, `os-darwin` absent (and inverse on Mac) |
| Installer is idempotent | Run `setup.sh` twice; second run reports skips, changes nothing |
| Fonts resolve | `fc-list \| grep -i monaspace` on Linux |

The full Linux path is testable directly on the Ubuntu machine.

**The macOS path cannot be verified from the Linux machine** and must be checked on the
Mac by the user. The structure limits the risk: because the OS layers are physically
separate packages, a mistake in `os-darwin` cannot break Linux, and vice versa. The
blast radius of the untestable half is confined to itself.

## Assumptions To Verify During Implementation

Neither ghostty nor alacritty is installed on the Linux machine, so these were not
confirmed empirically:

1. **ghostty resolves `config-file` relative to the including config's directory.**
   If it requires an absolute path, use `config-file = ~/.config/ghostty/os.conf`.
2. **alacritty's `import` appends `[[keyboard.bindings]]` rather than replacing the
   array.** If it replaces, the fallback is to move *all* keybindings into the OS
   fragments. Cheap either way.

## Open Observation (not in scope)

`.p10k.zsh` is stowed, but `.zshrc:53-60` initializes **starship**. One of the two is
likely dead configuration. Flagged, not addressed.
