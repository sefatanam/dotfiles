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
| `shell` | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`, `~/.tmux.conf`, `~/.wezterm.lua`, `~/.config/*` | alacritty, ghostty, aerospace, workmux, herdr, [tuicr](tuicr/README.md) |
| `editor` | `~/.config/nvim` | Neovim |
| `git` | `~/.gitconfig`, `~/.gitignore_global` | [git/README.md](git/README.md) |

Each `~/.config/<app>` entry is a symlink back to a folder of the same name in this repo
root, so editing e.g. `tuicr/config.toml` takes effect immediately — no restow.

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
