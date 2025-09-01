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
stow -t ~ shell editor
```

## Usage

```bash
# Install/update configs
stow -t ~ shell editor

# Update after changes  
stow -R shell editor

# Remove configs
stow -D shell editor
```

## What's Included

**Shell**: Zsh + Oh My Zsh + Powerlevel10k, Git config, Tmux
**Editor**: Neovim (LazyVim)
**WM**: AeroSpace tiling window manager  
**Terminal**: Ghostty
**Tools**: 80+ CLI tools via Homebrew

## Key Features

- **Modular zsh config** with separate files for exports, aliases, functions
- **Tiling window management** with AeroSpace (Alt+hjkl navigation)
- **Modern CLI tools** (bat, eza, ripgrep, fzf, lazygit, etc.)
- **Development ready** (Node.js, Python, Go, Docker alternatives)

## After Setup

1. Run `p10k configure` for prompt customization
2. Create `~/.private` for secrets/API keys
3. Configure AeroSpace workspace bindings as needed
