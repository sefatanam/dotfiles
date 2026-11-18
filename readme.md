# Dotfiles

My development environment, linked into place by `setup.sh` from per-tool `install.conf` files.

**Wiki:** open [site/wiki.html](site/wiki.html) in a browser — every tool, its config and its keys.

## Dependencies

**Required:**
- Homebrew
- Git

**Auto-installed:**
- Starship prompt
- 80+ CLI tools (see Brewfile)
- All configurations

## Quick Setup

```bash
# Clone repository
git clone https://github.com/sefatanam/dotfiles ~/.dotfiles

# Run automated setup script
cd ~/.dotfiles && ./setup.sh

# Preview what it would do without changing anything
./setup.sh --dry-run
```

Every run ends with a **manual-steps check** — a read-only pass that reports what it
couldn't do on this machine (missing SSH signing keys, an empty ssh-agent, an `includeIf`
pointing at a directory that doesn't exist yet, ungitignored-but-absent local files). It
runs in `--dry-run` too. See [Manual steps on a new machine](#manual-steps-on-a-new-machine).

`setup.sh` refuses to sync Homebrew packages (the slow, external-reaching step) without an
interactive confirmation — a non-interactive invocation (a script, a copy-pasted pipe, an
agent) skips it rather than silently installing/upgrading packages. Pass `--yes` to confirm
non-interactively; everything else (git hooks, `install.conf` links) is idempotent and
guarded against clobbering real files, so it always runs. See `./setup.sh --help`.

## Manual Setup

```bash
# Install dependencies
brew bundle --file=~/.dotfiles/brew/Brewfile

# Link everything (idempotent; --dry-run previews)
~/.dotfiles/setup.sh
```

> `git/install.conf` links `git/gitconfig` as `~/.gitconfig` and `git/gitignore` as
> `~/.gitignore_global`. If you already have a real `~/.gitconfig`, back it up and remove it
> first — `setup.sh` leaves real files alone and warns. See [git/README.md](git/README.md).

## Links

Each tool lists its own links in `<tool>/install.conf` (`LINK <src> -> <dest>`). Most
`~/.config/<app>` entries are `LINK . -> ~/.config/<app>`: a symlink straight back to the
folder of the same name in this repo root, so editing e.g. `tuicr/config.toml` takes effect
immediately — no relink.

## Shell aliases: global, work, local

`zsh/.local/share/zsh/` splits aliases/functions into three tiers instead of one flat file:

| File | Committed? | For |
|---|---|---|
| `aliases.zsh` / `functions.zsh` | Yes | Broadly useful anywhere (tmux, git, npm, media tools, …) |
| `work.zsh` | Yes | Job/project-specific, but nothing secret (assumes a particular project layout) |
| `local.zsh` | **No** (gitignored) | Real network addresses, VPN routes, client/company names — anything that shouldn't be public |

`local.zsh` doesn't exist on a fresh clone; copy the template and fill it in:

```bash
cp zsh/.local/share/zsh/local.zsh.example zsh/.local/share/zsh/local.zsh
```

## Keybindings

Every keybinding this repo configures, grouped by the layer that owns it — window
manager → multiplexer → terminal → editor → shell — is in
[site/keybindings.html](site/keybindings.html), a page you can open straight in a browser
(no build step, filter box included). It shares its look with the wiki through
`site/theme.css` and `site/theme.js`.
[CONTEXT.md](CONTEXT.md) defines the vocabulary it uses (leader, prefix, mode, chord).

Six of its tables are generated from the configs by `./update-keybindings.sh`, so they
can't drift silently:

```bash
./update-keybindings.sh          # regenerate the tables
./update-keybindings.sh --check  # exit 1 if the page is stale (setup-validate.sh runs this)
./update-keybindings-test.sh     # test the extractors
```

## Adding a new tool

Add `<app>/install.conf` and declare each link (and any command to run after linking) there
instead of hand-editing `setup.sh`. One directive per line:

```
PLATFORM darwin              # optional; restricts the whole file to one OS
LINK <src> -> <dest>         # src is relative to the tool's own directory
POST <shell command>         # run with CWD set to the tool's own directory
```

`setup.sh` discovers and applies every `*/install.conf` on each run (`apply_declared_installs`).
`lazygit/install.conf`, `bat/install.conf`, `providers/install.conf`, `omp/install.conf`, and
`claude/install.conf` are the real examples — read those before writing a new one. Run `./setup-validate.sh` after
adding or editing one; it exercises the LINK/POST/PLATFORM machinery against a throwaway
sandbox `$HOME`, not your real one.

## Theme

Everything shares one Rosé Pine palette — Ghostty, Neovim, lazygit, tuicr, and git diffs:

| Tool | Where |
|---|---|
| delta (git pager) | `git/delta-rose-pine.gitconfig` — `rose-pine`, `rose-pine-moon`, `rose-pine-dawn` features, included from `git/gitconfig` |
| syntax highlighting | `bat/themes/*.tmTheme` — delta reads these from bat's cache; `bat/install.conf` runs `bat cache --build` after every `setup.sh`, or run it by hand after changing them |
| lazygit | `lazygit/config.yml` — theme colors plus delta as the pager |
| tuicr (review TUI) | `tuicr/themes/*.toml` — local themes; tuicr bundles no Rosé Pine. The `.tmTheme` files there symlink into `bat/themes/` |

Switch variants by pointing `[delta] features` in `git/gitconfig`, `--features`/`--syntax-theme`
in `lazygit/config.yml`, and `theme_dark` in `tuicr/config.toml` at `rose-pine-moon` or
`rose-pine-dawn`. `delta --show-themes` and `delta --show-syntax-themes` preview what is
available.

> On macOS lazygit reads `~/Library/Application Support/lazygit`, not `~/.config`; that link is
> declared in [`lazygit/install.conf`](lazygit/install.conf) and applied by `setup.sh`.

## Usage

```bash
./setup.sh --dry-run   # preview
./setup.sh             # link / re-link everything
```

## After Setup

1. Add secrets/API keys to `zsh/private` (`export KEY=value` lines) — a pre-commit hook
   scrubs its values before every commit and a post-commit hook restores them, so the
   plaintext never reaches the repo. See [git/README.md §6](git/README.md#6-hooks).
2. Configure AeroSpace workspace bindings as needed
3. Work through whatever the manual-steps check printed (below)

## Manual steps on a new machine

`setup.sh` links every tracked file, so the git identity setup — `git/gitconfig`, the
`includeIf` in it, and `git/gitconfig.gitlab` — lands automatically. What can't be
carried is anything **secret** (SSH keys are deliberately never committed) or anything
tied to **one machine's paths**. `setup.sh` ends by checking for exactly those and
printing only what's actually missing, so a fully set-up box prints a single ✔ line.

| What it checks | Why it can't be automated | Fix |
|---|---|---|
| Every `signingkey` in `git/gitconfig*` exists, with its private half | Private keys must never be committed | Copy from the old machine (mode `600`), or `ssh-keygen -t ed25519 -f ~/.ssh/<name>` and register the `.pub` with GitHub/GitLab |
| `~/.ssh/allowed_signers` | Same — contains public keys tied to your identities | One `email ssh-ed25519 AAAA...` line per signing key |
| ssh-agent has identities loaded | Per-session, per-machine state | `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` (once per key) |
| Each `includeIf "gitdir:…"` directory exists | The paths are `~`-relative so they port across machines, but the directory itself still has to be there | Clone your work repos there, or repoint the `includeIf` in `git/gitconfig` |
| `zsh/.local/share/zsh/local.zsh`, `zsh/private` | Gitignored on purpose (network details, tokens) | Copy from the template / recreate |

The keys matter most: `commit.gpgsign = true` is **global** in `git/gitconfig`, so until the
signing key named there exists on disk, *every* commit fails with `gpg failed to sign the
data` — not just the GitLab ones.

The `includeIf` check is the subtle one. A missing key is loud; a missing `includeIf`
directory is **silent** — git just falls through to the default identity, and you find out
when a work commit shows up under your personal email. Write those paths `~`-relative
(`gitdir:~/Documents/repos/…`, not `gitdir:/Users/<name>/…`) so they don't break on a
machine with a different username. Full SSH-signing background lives in
[git/SIGNING.md](git/SIGNING.md).

## Also in this repo (manual)

These either aren't touched by `setup.sh` at all, or need a manual step it can't automate.
For the secret/machine-specific ones it *does* check and remind you about, see
[Manual steps on a new machine](#manual-steps-on-a-new-machine).

| Path | What it is | Run it |
|---|---|---|
| `macos/system-override` | One-shot `defaults write` tweaks for a fresh Mac (mathiasbynens-style) | `zsh macos/system-override` |
| `zsh-optimize.sh` | Recompiles and cleans the zsh config cache | `./zsh-optimize.sh` (after zsh config changes) |
| `update-keybindings.sh` | Regenerates the generated tables in [site/keybindings.html](site/keybindings.html) and [site/wiki.html](site/wiki.html) | `./update-keybindings.sh` (after changing a keybinding) |
| `update-keybindings-test.sh` | Tests the keybinding extractors | `./update-keybindings-test.sh` |
| `zsh/.local/bin/transparency` | The one switch for transparent mode (see [CONTEXT.md](CONTEXT.md)) across Ghostty, tmux and Neovim; linked onto PATH | `transparency on\|off\|toggle` (restart Ghostty on macOS) |
| `transparency-test.sh` | Tests the `transparency` command and its Neovim module | `./transparency-test.sh` |
| `vscode/*.code-profile.json` | VS Code profile exports | VS Code → Profiles → Import Profile |
| `omp/config.yml` | Snapshot of `~/.omp/agent/config.yml`; `setup.sh` auto-seeds it on a fresh machine but never re-exports it | after changing omp settings: `cp ~/.omp/agent/config.yml omp/config.yml` |
