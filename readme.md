# Dotfiles

My development environment using GNU Stow.

## Dependencies

**Required:**
- Homebrew
- GNU Stow
- Git

**Auto-installed:**
- Oh My Zsh + Powerlevel10k
- 80+ CLI tools (see Brewfile)
- All configurations

## Quick Setup

```bash
# Clone repository
git clone https://github.com/sefatanam/dotfiles ~/.dotfiles

# Run automated setup script
cd ~/.dotfiles && ./setup.sh
```

## Manual Setup

```bash
# Install dependencies
brew bundle --file=~/.dotfiles/brew/Brewfile

# Install Oh My Zsh + Powerlevel10k
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Setup dotfiles
cd ~/.dotfiles/stow-packages
stow -t ~ shell editor git
```

> `stow -t ~ git` installs `git/gitconfig` as `~/.gitconfig` and `git/gitignore` as
> `~/.gitignore_global`. If you already have a real `~/.gitconfig`, back it up and remove it
> first — stow refuses to overwrite regular files. See [git/README.md](git/README.md).

## Packages

| Package | Links | Notable configs |
|---|---|---|
| `shell` | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`, [`~/.tmux.conf`](tmux/readme.md), `~/.wezterm.lua`, `~/.tuicrignore`, `~/.config/*` | alacritty, ghostty, aerospace, workmux, herdr, bat, lazygit, [tuicr](tuicr/README.md) |
| `editor` | `~/.config/nvim` | Neovim |
| `git` | `~/.gitconfig`, `~/.gitignore_global` | [git/README.md](git/README.md) |

Each `~/.config/<app>` entry is a symlink back to a folder of the same name in this repo
root, so editing e.g. `tuicr/config.toml` takes effect immediately — no restow.

## Adding a new tool

Most tools only need a `~/.config/<app>` stub added under `stow-packages/shell/.config/`
(a symlink back to `<app>/` at the repo root, same pattern as the existing ones) — `stow`
handles the rest.

If a tool needs more than that — a link outside the stowed tree, or a command to run after
linking — declare it in `<app>/install.conf` instead of hand-editing `setup.sh`. One directive
per line:

```
PLATFORM darwin              # optional; restricts the whole file to one OS
LINK <src> -> <dest>         # src is relative to the tool's own directory
POST <shell command>         # run with CWD set to the tool's own directory
```

`setup.sh` discovers and applies every `*/install.conf` on each run (`apply_declared_installs`).
`lazygit/install.conf` and `bat/install.conf` are the two real examples — read those before
writing a new one. Run `./setup-validate.sh` after adding or editing one; it exercises the
LINK/POST/PLATFORM machinery against a throwaway sandbox `$HOME`, not your real one.

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
# Install/update configs
stow -t ~ shell editor git

# Update after changes  
stow -R shell editor git

# Remove configs
stow -D shell editor git
```

## After Setup

1. Run `p10k configure` for prompt customization
2. Add secrets/API keys to `zsh/private` (`export KEY=value` lines) — a pre-commit hook
   scrubs its values before every commit and a post-commit hook restores them, so the
   plaintext never reaches the repo. See [git/README.md §6](git/README.md#6-hooks).
3. Configure AeroSpace workspace bindings as needed

## Also in this repo (manual)

These aren't stowed or run by `setup.sh` — deliberately manual, invoke them yourself:

| Path | What it is | Run it |
|---|---|---|
| `macos/system-override` | One-shot `defaults write` tweaks for a fresh Mac (mathiasbynens-style) | `zsh macos/system-override` |
| `zsh-optimize.sh` | Recompiles and cleans the zsh config cache | `./zsh-optimize.sh` (after zsh config changes) |
| `vscode/*.code-profile.json` | VS Code profile exports | VS Code → Profiles → Import Profile |
| `providers/models.yml` | Model/provider list for an external AI tool config | point that tool's config at this file |
