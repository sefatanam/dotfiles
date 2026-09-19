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
| `shell` | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`, `~/.tmux.conf`, `~/.wezterm.lua`, `~/.tuicrignore`, `~/.config/*` | alacritty, ghostty, aerospace, workmux, herdr, bat, lazygit, [tuicr](tuicr/README.md) |
| `editor` | `~/.config/nvim` | Neovim |
| `git` | `~/.gitconfig`, `~/.gitignore_global` | [git/README.md](git/README.md) |

Each `~/.config/<app>` entry is a symlink back to a folder of the same name in this repo
root, so editing e.g. `tuicr/config.toml` takes effect immediately — no restow.

## Theme

Everything shares one Rosé Pine palette — Ghostty, Neovim, lazygit, and git diffs:

| Tool | Where |
|---|---|
| delta (git pager) | `git/delta-rose-pine.gitconfig` — `rose-pine`, `rose-pine-moon`, `rose-pine-dawn` features, included from `git/gitconfig` |
| syntax highlighting | `bat/themes/*.tmTheme` — delta reads these from bat's cache, so run `bat cache --build` after changing them |
| lazygit | `lazygit/config.yml` — theme colors plus delta as the pager |

Switch variants by pointing `[delta] features` in `git/gitconfig` and `--features`/`--syntax-theme`
in `lazygit/config.yml` at `rose-pine-moon` or `rose-pine-dawn`. `delta --show-themes` and
`delta --show-syntax-themes` preview what is available.

> On macOS lazygit reads `~/Library/Application Support/lazygit`, not `~/.config`; `setup.sh`
> symlinks `lazygit/config.yml` there for you.

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
2. Create `~/.private` for secrets/API keys
3. Configure AeroSpace workspace bindings as needed
