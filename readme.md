# Dotfiles - Modern Development Environment

A comprehensive, hybrid dotfiles repository for macOS development environments. This setup provides both traditional directory structure AND modern Stow-based management through clever symlink integration.

## ✨ Features

- **🔄 Hybrid Structure** - Best of both worlds: traditional directories + modern Stow packages
- **🔗 Smart Symlinks** - Seamless integration between traditional and Stow approaches
- **🔧 Stow-based Management** - Use GNU Stow for clean, reversible symlink management
- **📦 Modular Organization** - Logical grouping of configurations by purpose
- **🚀 Automated Setup** - One-command installation and migration
- **🔄 Backwards Compatibility** - Existing scripts and workflows continue to work
- **🔍 Smart Migration** - Safe transition from manual symlinks
- **🧹 Maintenance Tools** - Built-in cleanup and update utilities
- **📊 Comprehensive Scanning** - Detailed analysis of your current setup


### Bidirectional Symlinks

This setup uses **bidirectional symlinks** to maintain both traditional and modern structures:

#### **Traditional → Stow** (Forward Links)
```bash
zsh/zshrc → stow-packages/shell/.zshrc
git/gitconfig → stow-packages/shell/.gitconfig
nvim → stow-packages/shell/.config/nvim
```

#### **Stow → Traditional** (Reverse Links)
```bash
stow-packages/shell/.config/nvim → ../../../nvim
stow-packages/shell/.gitconfig → ../../../git/gitconfig
stow-packages/editor/.config/nvim → ../../../nvim
```

### Why This Approach?

🎯 **Backwards Compatibility** - Existing scripts using `~/.dotfiles/zsh/` continue to work  
🎯 **Modern Organization** - Stow packages provide clean, logical grouping  
🎯 **Flexibility** - Choose traditional OR stow approach based on your needs  
🎯 **Easy Migration** - Gradual transition without breaking existing workflows  
🎯 **Single Source of Truth** - All configurations ultimately point to the same files

## 🚀 Quick Start

### New Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install using stow (recommended)
cd stow-packages
stow -t ~ shell editor

# Or use traditional approach (if you prefer)
# Your existing scripts will work with the traditional directories
```

### Using the Hybrid System

**For Stow users:**
```bash
cd ~/.dotfiles/stow-packages
stow -t ~ shell          # Install shell package
stow -R shell            # Re-stow after adding files
stow -D shell            # Remove shell package
```

**For Traditional users:**
```bash
# Your existing scripts work unchanged
ls ~/.dotfiles/zsh/      # Traditional structure
cat ~/.dotfiles/git/gitconfig  # Still works
```

### Using Stow

```bash
cd ~/.dotfiles/stow-packages
stow -t ~ shell          # Install shell package
stow -R shell            # Re-stow after adding files
stow -D shell            # Remove shell package
```

## 📋 Available Commands

### Stow Package Management
```bash
# Install packages
cd stow-packages
stow -t ~ shell          # Install shell package
# Only shell package exists currently
# stow -t ~ development    # Install development package (not available)
# stow -t ~ terminal       # Install terminal package (not available) 
# stow -t ~ desktop        # Install desktop package (not available)
# stow -t ~ system         # Install system package (not available)

# Install all packages at once
stow -t ~ */

# Update packages (after adding new files)
stow -R shell            # Re-stow shell package
stow -R */               # Re-stow all packages

# Remove packages
stow -D shell            # Remove shell package
stow -D */               # Remove all packages

# Check what would be stowed (dry run)
stow -n -v shell         # Preview shell package changes
```

### Available Commands
```bash
# Install packages
cd stow-packages
stow -t ~ shell          # Install shell package

# Update packages (after adding new files)
stow -R shell            # Re-stow shell package

# Remove packages
stow -D shell            # Remove shell package

# Check what would be stowed (dry run)
stow -n -v shell         # Preview shell package changes
```


<details>

<summary> Old Way to configure (Deprecated) </summary>

```bash
After cloning the repository and installing the necessary software, you need to create symlinks for the configuration files. This step ensures that your system uses the dotfiles from the repository rather than the default configuration files.

To create the symlinks, use the following commands:

# Link the .zshrc file for Zsh configuration and Secret Variables
ln -s ~/.dotfiles/zsh/zshrc ~/.zshrc
ln -s ~/.dotfiles/zsh/zprofile ~/.zprofile
ln -s ~/.dotfiles/zsh/private ~/.private

# Link the .tmux.conf file for tmux configuration
ln -s ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf

# Link the .p10k.zsh file for Powerlevel10k prompt configuration
ln -s ~/.dotfiles/p10k/p10k.zsh ~/.p10k.zsh

# Link the aerospace configuration folder
ln -s ~/.dotfiles/aerospace ~/.config/aerospace

# Link the Neovim configuration folder
ln -s ~/.dotfiles/nvim ~/.config/nvim

# Link to Git essentials
ln -s ~/.dotfiles/git/gitconfig ~/.gitconfig
ln -s ~/.dotfiles/git/gitconfig ~/.gitconfig

ln -s ~/.dotfiles/git/hooks/post-commit .git/hooks // should run in ~/.dotfiles directory
ln -s ~/.dotfiles/git/hooks/pre-commit .git/hooks  // should run in ~/.dotfiles directory

# Link Starship configuration
ln -s ~/.dotfiles/starship/starship.toml ~/.config/starship.toml
```

</details>

## 📚 Additional Documentation

- **[INSTALL.md](docs/INSTALL.md)** - Detailed installation guide
- **[STOW.md](docs/STOW.md)** - GNU Stow usage and best practices
- **[MIGRATION.md](docs/MIGRATION.md)** - Migration from manual symlinks
- **[CUSTOMIZATION.md](docs/CUSTOMIZATION.md)** - How to customize configurations
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
 

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
 
**Happy coding! 🚀**