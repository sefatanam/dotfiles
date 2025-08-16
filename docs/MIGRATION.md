# Migration Guide

Guide for safely migrating from manual symlinks to Stow-based dotfiles management.

## Overview

This guide helps you transition from manually created symlinks (`ln -s`) to a clean, Stow-managed dotfiles system.

## Why Migrate to Stow?

### Benefits of Stow-based Management

1. **Cleaner Organization** - Logical grouping of related configs
2. **Granular Control** - Install only what you need
3. **Easy Rollback** - Simple package removal
4. **Conflict Detection** - Warns before overwriting files
5. **Reproducible Setup** - Consistent across machines

### Current Manual Symlink Issues

- Hard to track what's linked where
- Difficult to remove cleanly
- No conflict detection
- All-or-nothing approach
- Manual backup required

## Pre-Migration Assessment

### 1. Scan Your Current Setup

```bash
# Basic scan
./scripts/helpers/scan-symlinks.sh scan

# Or using the installer
./install.sh --scan

# Or using make
make scan
```

This will show you:
- All symlinks pointing to your dotfiles
- Broken symlinks
- Summary of your current setup

### 2. Generate Detailed Report

```bash
# Generate comprehensive report
./scripts/helpers/scan-symlinks.sh report

# Or using make
make report
```

This creates a markdown report with:
- Current directory structure
- Active symlinks table
- System information
- Recommendations

### 3. Understand Your Symlinks

Common symlinks found in manual setups:
```
~/.zshrc -> ~/.dotfiles/zsh/zshrc
~/.tmux.conf -> ~/.dotfiles/tmux/tmux.conf
~/.gitconfig -> ~/.dotfiles/git/gitconfig
~/.config/nvim -> ~/.dotfiles/nvim
~/.config/aerospace -> ~/.dotfiles/aerospace
```

## Migration Process

### Automated Migration (Recommended)

The simplest way to migrate:

```bash
# Single command migration
./install.sh --migrate

# Or using make
make migrate
```

This will:
1. Scan current setup
2. Create backup with timestamp
3. Remove old symlinks  
4. Move configs to Stow packages
5. Create modular configuration files

### Manual Migration (Advanced)

For more control over the process:

#### Step 1: Create Backup
```bash
# Create comprehensive backup
./scripts/helpers/scan-symlinks.sh backup
```

This creates a backup directory with:
- `symlinks.txt` - List of all symlinks and targets
- `restore.sh` - Script to restore the backup
- `scan-results.txt` - Detailed scan results

#### Step 2: Remove Old Symlinks
```bash
# Remove all dotfiles symlinks
./scripts/helpers/scan-symlinks.sh remove
```

#### Step 3: Move Configurations
```bash
# Run the migration script to move files
./scripts/setup/migrate-to-stow.sh
```

#### Step 4: Install with Stow
```bash
# Install using Stow
make install
```

## Post-Migration Tasks

### 1. Verify Installation
```bash
# Check what's installed
make status

# Generate new report
make report
```

### 2. Test Your Setup
```bash
# Restart terminal or source new config
source ~/.zshrc

# Test key functionality
g    # Should open lazygit
n    # Should open neovim  
t    # Should start tmux
```

### 3. Clean Up Broken Links
```bash
# Find and clean up any broken symlinks
make clean
```

## Understanding the New Structure

### Before Migration (Manual Symlinks)
```
~/.dotfiles/
├── zsh/zshrc
├── tmux/tmux.conf
├── git/gitconfig
└── nvim/

Manual symlinks:
~/.zshrc -> ~/.dotfiles/zsh/zshrc
~/.tmux.conf -> ~/.dotfiles/tmux/tmux.conf
```

### After Migration (Stow Packages)
```
~/.dotfiles/
├── stow-packages/
│   ├── shell/
│   │   ├── .zshrc
│   │   └── .local/share/zsh/
│   ├── terminal/
│   │   └── .tmux.conf
│   └── development/
│       └── .gitconfig
└── scripts/

Stow management:
cd stow-packages && stow shell terminal development
```

## Troubleshooting Migration

### Common Migration Issues

#### 1. Existing Files Conflict
```bash
# Check for conflicts
make check-conflicts

# Manual resolution
mv ~/.zshrc ~/.zshrc.bak
make shell
```

#### 2. Broken Symlinks After Migration
```bash
# Find and remove broken links
./scripts/helpers/scan-symlinks.sh broken
```

#### 3. Configuration Not Working
```bash
# Check if files are properly linked
ls -la ~/ | grep -E '\.(zshrc|tmux)'

# Verify Stow installation
make status
```

#### 4. Missing Private Configuration
```bash
# Restore private file from backup
cp ~/dotfiles-backup-*/private ~/.private

# Or create new from template
cp templates/private.template ~/.private
```

### Recovery Options

#### Restore Original Setup
If migration fails, restore from backup:
```bash
# Find your backup
ls ~/dotfiles-backup-*

# Run restore script
~/dotfiles-backup-YYYYMMDD-HHMMSS/restore.sh
```

#### Partial Restoration
```bash
# Restore specific symlinks manually
ln -sf ~/.dotfiles/zsh/zshrc ~/.zshrc
ln -sf ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
```

#### Clean Slate Migration
```bash
# Remove everything and start fresh
make uninstall
./scripts/helpers/scan-symlinks.sh remove
make install
```

## Migration Validation

### Checklist

After migration, verify:

- [ ] **Shell works** - `zsh` loads without errors
- [ ] **Aliases work** - Try `g`, `n`, `t` commands
- [ ] **Functions work** - Try `y` (yazi), `ngnew` commands
- [ ] **Git config** - `git config --list` shows your settings
- [ ] **Tmux config** - `tmux` starts with custom config
- [ ] **Editor config** - `nvim` loads with your setup
- [ ] **Private vars** - Environment variables are set

### Testing Commands

```bash
# Test shell
echo $SHELL
which zsh

# Test aliases
alias | grep -E '^(g|n|t)='

# Test git
git config user.name
git config user.email

# Test tmux
tmux list-keys | head -5

# Test environment
echo $GOPATH
echo $PNPM_HOME
```

## Best Practices After Migration

### 1. Regular Maintenance
```bash
# Weekly maintenance
make update    # Update packages
make clean     # Clean broken links
make status    # Check system health
```

### 2. Backup Strategy
```bash
# Create regular backups before changes
make backup

# Version control your dotfiles
cd ~/.dotfiles
git add -A
git commit -m "Update configurations"
git push
```

### 3. Testing Changes
```bash
# Before making changes
make backup

# Test new configurations
stow -n packagename  # Dry run

# Apply changes
make restow
```

### 4. Documentation
- Document customizations in your dotfiles
- Keep notes about package purposes
- Maintain a changelog of major changes

## Advanced Migration Scenarios

### Multiple Environments
```bash
# Work-specific migration
STOW_PACKAGES="shell terminal development" make migrate

# Personal-specific migration  
STOW_PACKAGES="shell terminal editor desktop" make migrate
```

### Selective Migration
```bash
# Migrate only specific components
./scripts/helpers/scan-symlinks.sh backup
# Manually remove only specific symlinks
# Migrate specific packages only
```

### Cross-Platform Considerations
While this setup is macOS-focused, you can adapt for other platforms:
- Modify Brewfile for different package managers
- Adjust paths in configuration files
- Create platform-specific Stow packages

## Getting Help

If you encounter issues during migration:

1. **Check the scan results** - `make scan`
2. **Review backup contents** - Check backup directory
3. **Test individual components** - Install packages one by one
4. **Consult logs** - Check terminal output for errors
5. **Use recovery options** - Restore from backup if needed

For more help:
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [STOW.md](STOW.md) - GNU Stow usage guide