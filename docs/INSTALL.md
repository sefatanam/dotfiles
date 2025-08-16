# Installation Guide

Complete guide for installing and setting up the Stow-based dotfiles system.

## Prerequisites

1. **macOS** - This setup is designed for macOS
2. **Homebrew** - Package manager for macOS
3. **Command Line Tools** - Xcode command line tools

### Install Prerequisites

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Xcode command line tools
xcode-select --install
```

## Installation Methods

### Method 1: Fresh Installation

For new setups without existing dotfiles:

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Complete installation (packages + configs)
./install.sh

# Or step by step
./install.sh --packages  # Install packages first
./install.sh --configs   # Then install configs
```

### Method 2: Migration from Manual Symlinks

If you have existing dotfiles with manual symlinks:

```bash
# 1. Scan current setup
./install.sh --scan

# 2. Run migration (creates backup + removes old symlinks)
./install.sh --migrate

# 3. Install with Stow
./install.sh --configs
```

### Method 3: Using Makefile

```bash
# Check current setup
make scan

# Migrate existing setup
make migrate

# Install everything
make install

# Or install specific components
make shell terminal editor
```

## Installation Options

### Full Installation
```bash
./install.sh --full        # Complete setup (default)
make install               # Same using Makefile
```

### Partial Installation
```bash
./install.sh --packages    # Only Homebrew packages
./install.sh --configs     # Only configurations
make packages              # Only packages via Makefile
```

### Minimal Installation
```bash
./install.sh --minimal     # Essential tools only
```

### Component-Specific Installation
```bash
make shell                 # Shell configurations only
make editor                # Editor configurations only
make terminal              # Terminal tools only
make desktop               # Desktop applications only
make development           # Development tools only
```

## Post-Installation

### 1. Restart Terminal
```bash
# Restart your terminal application or source the new config
source ~/.zshrc
```

### 2. Verify Installation
```bash
make status                # Check what's installed
make report                # Generate detailed report
```

### 3. Test Key Components
```bash
# Test shell setup
which zsh
echo $SHELL

# Test aliases
g                          # Should open lazygit
n                          # Should open neovim

# Test functions
y                          # Should open yazi file manager
```

### 4. Configure Private Settings
```bash
# Copy and edit private configuration template
cp templates/private.template ~/.private
nvim ~/.private
```

## Troubleshooting Installation

### Common Issues

#### Stow Conflicts
```bash
# Check for conflicts before installing
make check-conflicts

# See detailed status
make status

# Install components individually to isolate issues
make shell
make terminal
make editor
```

#### Permission Issues
```bash
# Ensure correct ownership
sudo chown -R $(whoami) ~/.dotfiles

# Fix permissions
find ~/.dotfiles -type f -exec chmod 644 {} \;
find ~/.dotfiles -type d -exec chmod 755 {} \;
find ~/.dotfiles/scripts -name "*.sh" -exec chmod +x {} \;
```

#### Homebrew Package Failures
```bash
# Update Homebrew
brew update

# Retry failed packages
brew bundle --file=packages/Brewfile

# Check for issues
brew doctor
```

#### Git Hook Issues
```bash
# Set up git hooks manually if needed
cd ~/.dotfiles
ln -sf ../../scripts/git/hooks/pre-commit .git/hooks/
ln -sf ../../scripts/git/hooks/post-commit .git/hooks/
chmod +x .git/hooks/*
```

### Recovery Options

#### Restore from Backup
If something goes wrong, you can restore from the automatic backup:
```bash
# Find your backup directory
ls ~/dotfiles-backup-*

# Run the restore script
~/dotfiles-backup-YYYYMMDD-HHMMSS/restore.sh
```

#### Clean Installation
```bash
# Remove all symlinks
make uninstall

# Clean up broken links
make clean

# Reinstall
make install
```

#### Reset to Manual Symlinks
```bash
# Uninstall Stow packages
make uninstall

# Restore from backup
~/dotfiles-backup-YYYYMMDD-HHMMSS/restore.sh
```

## Customization After Installation

### Adding New Tools
1. Add packages to `packages/Brewfile`
2. Create configuration in appropriate `stow-packages/` directory
3. Install: `make packages && make restow`

### Modifying Existing Configs
1. Edit files in `stow-packages/` directories
2. Restow: `make restow` or `stow -R -t ~ packagename`

### Creating Custom Packages
```bash
# Create new package directory
mkdir -p stow-packages/mypackage/.config/mytool

# Add configuration files
echo "config content" > stow-packages/mypackage/.config/mytool/config.yml

# Install the package
cd stow-packages && stow -t ~ mypackage
```

## Advanced Installation

### Development Setup
```bash
# Complete development environment
make dev-setup

# This includes:
# - All packages
# - All configurations  
# - Development-specific setup
```

### Custom Brewfile
```bash
# Use a different Brewfile
BREWFILE=packages/Brewfile.work make packages

# Or specify directly
brew bundle --file=packages/Brewfile.personal
```

### Environment-Specific Installation
```bash
# Work environment
./install.sh --packages && \
STOW_PACKAGES="shell terminal development" make install

# Personal environment  
./install.sh --packages && \
STOW_PACKAGES="shell terminal editor desktop" make install
```

## Verification Checklist

After installation, verify these components work:

- [ ] **Shell**: `zsh` with custom prompt and aliases
- [ ] **Terminal**: `tmux` with custom configuration
- [ ] **Editor**: `nvim` with LazyVim setup
- [ ] **Git**: Custom configuration and aliases work
- [ ] **Package Manager**: `brew`, `pnpm`, `bun` available
- [ ] **CLI Tools**: `bat`, `eza`, `fzf`, `ripgrep` work
- [ ] **Desktop**: AeroSpace window management active
- [ ] **File Manager**: `yazi` integration works

## Getting Help

1. **Check installation status**: `make status`
2. **Generate report**: `make report`  
3. **Scan for issues**: `make scan`
4. **View logs**: Check terminal output during installation
5. **Manual verification**: Test individual components

For more help, see:
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [STOW.md](STOW.md) - GNU Stow usage
- [CUSTOMIZATION.md](CUSTOMIZATION.md) - Customization guide