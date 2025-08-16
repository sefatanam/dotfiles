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

## 🏗️ Hybrid Structure

This dotfiles repository uses a **hybrid approach** that provides both familiar traditional directories AND organized Stow packages, connected through intelligent symlinks.

<details>
<summary><strong>📁 Root Directory Structure</strong></summary>

```
.dotfiles/
├── 📄 README.md                 # This file
├── ⚙️ Makefile                  # Simple management commands
├── 🚀 install.sh               # Main installation script
│
├── 🐚 zsh/                     # Traditional shell configs (→ symlinks to stow)
│   ├── zshrc → ../stow-packages/shell/.zshrc
│   ├── zprofile → ../stow-packages/shell/.zprofile
│   └── private → ../stow-packages/shell/.private
│
├── 🔧 git/                     # Traditional git configs (→ symlinks to stow)
│   ├── gitconfig → ../stow-packages/shell/.gitconfig
│   ├── gitignore → ../stow-packages/shell/.gitignore_global
│   └── hooks → ../stow-packages/development/.local/share/git/hooks
│
├── ✏️ nvim → stow-packages/shell/.config/nvim
├── 🖥️ tmux/ → stow-packages/terminal/.tmux.conf
├── ✨ p10k/ → stow-packages/terminal/.p10k.zsh
├── 👻 ghostty/ → stow-packages/terminal/.config/ghostty
├── 🚀 aerospace/ → stow-packages/shell/.config/aerospace
├── 🔍 raycast/ → stow-packages/desktop/.config/raycast
├── 🍎 macos/ → stow-packages/system/.config/macos
└── 🤖 mcp/ → stow-packages/development/.config/mcp
```
</details>

<details>
<summary><strong>📦 Stow Packages Structure</strong></summary>

```
stow-packages/
├── 🐚 shell/                   # Main package (most configs consolidated here)
│   ├── .config/
│   │   ├── nvim → ../../../nvim                    # ← Points back to root
│   │   ├── aerospace → ../../../aerospace          # ← Points back to root
│   │   └── ghostty/                               # Native ghostty config
│   ├── .local/share/zsh/
│   │   ├── aliases.zsh
│   │   ├── exports.zsh
│   │   ├── functions.zsh
│   │   └── completions.zsh
│   ├── .gitconfig → ../../../git/gitconfig         # ← Points back to root
│   ├── .gitignore_global → ../../../git/gitignore  # ← Points back to root
│   ├── .zshrc                                     # Native zsh config
│   ├── .zprofile                                  # Native zsh config
│   └── .private                                   # Private environment vars
│
├── 🔧 development/             # Development tools
│   ├── .config/mcp/           # MCP configuration
│   └── .local/share/git/hooks/ # Git hooks
│
├── ✏️ editor/                  # Editor configurations
│   └── .config/nvim → ../../../nvim                # ← Points back to root
│
├── 🖥️ terminal/                # Terminal tools
│   ├── .config/ghostty/       # Terminal emulator config
│   ├── .tmux.conf            # Tmux configuration
│   └── .p10k.zsh             # Powerlevel10k theme
│
├── 🖼️ desktop/                 # Desktop applications
│   └── .config/
│       ├── aerospace/         # Window manager
│       └── raycast/          # Productivity launcher
│
└── 🍎 system/                  # System configurations
    └── .config/macos/         # macOS system overrides
```
</details>

<details>
<summary><strong>📚 Legacy Structure (Maintained for Reference)</strong></summary>

```
brew/
├── Brewfile                  # Homebrew packages (organized)

docs/
├── INSTALL.md               # Detailed installation guide
└── MIGRATION.md             # Migration from manual symlinks

scripts/
├── setup/                   # Installation scripts
├── helpers/                 # Utility scripts
└── maintenance/             # Update and cleanup scripts
```
</details>

## 🔄 How the Hybrid System Works

### The Magic of Bidirectional Symlinks

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
stow -t ~ shell development terminal desktop editor system

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

### Migrating from Manual Symlinks

If you already have dotfiles with manual symlinks:

```bash
# Scan your current setup
./install.sh --scan
# or
make scan

# Migrate to Stow-based setup
./install.sh --migrate
# or
make migrate

# Install with Stow
make install
```

## 📋 Available Commands

### Stow Package Management
```bash
# Install packages
cd stow-packages
stow -t ~ shell          # Install shell package
stow -t ~ development    # Install development package  
stow -t ~ terminal       # Install terminal package
stow -t ~ desktop        # Install desktop package
stow -t ~ editor         # Install editor package
stow -t ~ system         # Install system package

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

### Traditional Approach (Legacy Support)
```bash
# These still work with the hybrid structure
make install        # Install all configurations (if Makefile exists)
make shell          # Install shell configs only
make editor         # Install editor configs only  
make terminal       # Install terminal configs only
make desktop        # Install desktop configs only
make development    # Install development configs only
```

### Maintenance & Information
```bash
# Find broken symlinks
find ~ -type l ! -exec test -e {} \; -print 2>/dev/null

# Check stow package status
cd stow-packages && stow -n -v */ 2>&1 | grep -E "(LINK|WARNING|ERROR)"

# Scan current symlink setup (if scan script exists)
./scripts/helpers/scan-symlinks.sh

# Clean up broken symlinks
find ~ -xtype l -delete 2>/dev/null
```

## 🔧 Configuration Details

### Shell Configuration (Modular Zsh)

The zsh configuration is split into focused modules in the **shell package**:

<details>
<summary><strong>🐚 Shell Package Contents</strong></summary>

```
stow-packages/shell/
├── .zshrc                    # Main configuration file (sources others)
├── .zprofile                 # Login shell configuration
├── .private                  # Private environment variables (git-ignored values)
├── .gitconfig               # Git configuration (→ symlinked to git/gitconfig)
├── .gitignore_global        # Global gitignore (→ symlinked to git/gitignore)
└── .local/share/zsh/        # Modular zsh components
    ├── exports.zsh          # Environment variables and PATH
    ├── aliases.zsh          # Command aliases  
    ├── functions.zsh        # Custom shell functions
    └── completions.zsh      # Shell completions and tools
```

**Private Environment Handling:**
- `.private` file contains sensitive environment variables
- Git hooks automatically strip values before commits
- Original values are restored after commits
- Keeps secrets out of version control safely

</details>

### Key Tools Included

<details>
<summary><strong>🔧 Development Tools</strong></summary>

**Version Control:**
- Git with custom configuration and hooks
- GitHub CLI with extensions
- LazyGit for terminal Git interface

**Programming Languages:**
- Go, Python, Node.js, Bun
- Package managers and version managers

**Git Hooks (Automated Secret Management):**
- `pre-commit`: Strips sensitive values from `.private` before commits
- `post-commit`: Restores original values after commits
- Located in: `stow-packages/development/.local/share/git/hooks/`

</details>

<details>
<summary><strong>🖥️ Terminal Enhancement</strong></summary>

**Terminal Multiplexer:**
- Tmux with custom configuration and plugins
- Located in: `stow-packages/terminal/.tmux.conf`

**Editor:**
- Neovim with LazyVim setup
- Located in: `nvim/` (symlinked to shell package)

**Modern CLI Tools:**
- bat, eza, fzf, ripgrep
- File manager integration (yazi)

**Prompt:**
- Powerlevel10k theme configuration
- Located in: `stow-packages/terminal/.p10k.zsh`

</details>

<details>
<summary><strong>🖼️ Desktop Applications</strong></summary>

**Window Management:**
- AeroSpace (tiling window manager)
- Configuration in: `aerospace/` (symlinked to shell package)

**Productivity:**
- Raycast (productivity launcher)
- Configuration in: `stow-packages/desktop/.config/raycast/`

**Terminal Emulator:**
- Ghostty configuration
- Located in: `stow-packages/terminal/.config/ghostty/`

</details>

## 🛠️ Customization

### Adding New Configurations

<details>
<summary><strong>➕ Adding to Existing Packages</strong></summary>

1. **Add to shell package** (recommended for most configs):
   ```bash
   # Add a new config file
   echo "alias mynew='echo hello'" >> stow-packages/shell/.local/share/zsh/aliases.zsh
   
   # Re-stow to apply changes
   cd stow-packages && stow -R shell
   ```

2. **Add to appropriate package**:
   ```bash
   # Add to development package
   mkdir -p stow-packages/development/.config/mytool
   echo "config content" > stow-packages/development/.config/mytool/config.json
   
   # Re-stow the package
   cd stow-packages && stow -R development
   ```

</details>

<details>
<summary><strong>📦 Creating New Packages</strong></summary>

1. **Create package directory**:
   ```bash
   mkdir -p stow-packages/mynewpackage/.config/mytool
   ```

2. **Add configuration files** with correct home directory structure:
   ```bash
   echo "my config" > stow-packages/mynewpackage/.config/mytool/config
   ```

3. **Install the package**:
   ```bash
   cd stow-packages && stow -t ~ mynewpackage
   ```

4. **Create traditional symlink** (optional, for backwards compatibility):
   ```bash
   ln -s stow-packages/mynewpackage/.config/mytool mytool
   ```

</details>

<details>
<summary><strong>🔗 Adding Bidirectional Symlinks</strong></summary>

To integrate with the hybrid system:

1. **Create traditional directory**:
   ```bash
   mkdir mytool
   echo "config content" > mytool/config
   ```

2. **Add symlink in stow package**:
   ```bash
   ln -s ../../../mytool/config stow-packages/shell/.config/mytool
   ```

3. **Re-stow to apply**:
   ```bash
   cd stow-packages && stow -R shell
   ```

</details>

### Modifying Existing Configs

<details>
<summary><strong>✏️ Direct Editing</strong></summary>

1. **Edit files in stow packages**:
   ```bash
   vim stow-packages/shell/.zshrc
   ```

2. **Or edit through traditional symlinks**:
   ```bash
   vim zsh/zshrc  # Same file, different path
   ```

3. **Changes are immediately active** (no re-stowing needed for edits)

</details>

<details>
<summary><strong>🔄 Re-stowing After Changes</strong></summary>

Only needed when **adding/removing files**:

```bash
cd stow-packages
stow -R shell              # Re-stow specific package
stow -R */                 # Re-stow all packages

# Check what would change first (dry run)
stow -n -v shell
```

</details>

## 🔍 Troubleshooting

### Common Issues

<details>
<summary><strong>⚠️ Stow Conflicts</strong></summary>

**Problem**: Stow reports conflicts when trying to create symlinks

```bash
# Check what's causing conflicts
cd stow-packages
stow -n -v shell  # Dry run to see what would happen

# Common solutions:
# 1. Remove existing files/symlinks
rm ~/.zshrc  # Remove conflicting file

# 2. Use --adopt to take over existing files
stow --adopt shell  # Moves existing files into stow package

# 3. Manual conflict resolution
mv ~/.zshrc ~/.zshrc.backup  # Backup existing file
stow shell  # Now stow can create symlinks
```

</details>

<details>
<summary><strong>🔗 Broken Symlinks</strong></summary>

**Find broken symlinks**:
```bash
# Find all broken symlinks in home directory
find ~ -type l ! -exec test -e {} \; -print 2>/dev/null

# Find broken symlinks pointing to dotfiles
find ~ -type l -ls | grep "\.dotfiles" | while read link; do
  target=$(echo "$link" | awk '{print $NF}')
  if [[ ! -e "$target" ]]; then
    echo "Broken: $link"
  fi
done
```

**Clean up broken symlinks**:
```bash
# Remove all broken symlinks (be careful!)
find ~ -xtype l -delete 2>/dev/null

# Or remove specific ones
rm ~/.broken_symlink
```

</details>

<details>
<summary><strong>🔄 Hybrid System Issues</strong></summary>

**Problem**: Traditional directories point to wrong locations

```bash
# Check where symlinks point
ls -la zsh/zshrc  # Should point to ../stow-packages/shell/.zshrc
ls -la stow-packages/shell/.gitconfig  # Should point to ../../../git/gitconfig

# Fix broken bidirectional links
rm zsh/zshrc
ln -s ../stow-packages/shell/.zshrc zsh/zshrc

# Re-create stow package symlinks
rm stow-packages/shell/.gitconfig
ln -s ../../../git/gitconfig stow-packages/shell/.gitconfig
cd stow-packages && stow -R shell
```

</details>

<details>
<summary><strong>📦 Package Management Issues</strong></summary>

**Problem**: New files not appearing after stow

```bash
# Solution: Re-stow the package
cd stow-packages
stow -R shell  # This removes old symlinks and creates new ones

# Check if files were added correctly
stow -n -v shell  # Dry run shows what would be linked
```

**Problem**: Git hooks not working

```bash
# Check if hooks are executable and in the right place
ls -la stow-packages/development/.local/share/git/hooks/
chmod +x stow-packages/development/.local/share/git/hooks/*

# Update git to use the hooks
git config core.hooksPath ~/.local/share/git/hooks
```

</details>

### Getting Help

1. **Check symlink structure**:
   ```bash
   # Show the bidirectional symlink network
   ls -la zsh/ git/ nvim/
   ls -la stow-packages/shell/
   ```

2. **Verify stow package integrity**:
   ```bash
   cd stow-packages
   find . -type l -ls  # Show all symlinks in packages
   ```

3. **Test stow operations**:
   ```bash
   cd stow-packages
   stow -n -v shell  # Dry run to see what would happen
   ```

## 📚 Additional Documentation

- **[INSTALL.md](docs/INSTALL.md)** - Detailed installation guide
- **[STOW.md](docs/STOW.md)** - GNU Stow usage and best practices
- **[MIGRATION.md](docs/MIGRATION.md)** - Migration from manual symlinks
- **[CUSTOMIZATION.md](docs/CUSTOMIZATION.md)** - How to customize configurations
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `make check-conflicts`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **GNU Stow** - For excellent symlink management
- **LazyVim** - For the amazing Neovim configuration
- **Oh My Zsh** - For the zsh framework
- **Homebrew** - For package management on macOS

---

**Happy coding! 🚀**