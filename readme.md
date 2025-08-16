# Dotfiles - Modern Development Environment

A comprehensive, Stow-based dotfiles repository for macOS development environments. This setup provides a modern, organized, and maintainable way to manage your development configurations.

## ✨ Features

- **🔧 Stow-based Management** - Use GNU Stow for clean, reversible symlink management
- **📦 Modular Organization** - Logical grouping of configurations by purpose
- **🚀 Automated Setup** - One-command installation and migration
- **🔍 Smart Migration** - Safe transition from manual symlinks
- **🧹 Maintenance Tools** - Built-in cleanup and update utilities
- **📊 Comprehensive Scanning** - Detailed analysis of your current setup

## 🏗️ Structure

```
.dotfiles/
├── README.md                 # This file
├── Makefile                  # Simple management commands
├── install.sh               # Main installation script
│
├── stow-packages/           # Stow packages (configurations)
│   ├── shell/               # Shell configurations (zsh, starship)
│   ├── editor/              # Editor configs (neovim)
│   ├── terminal/            # Terminal tools (tmux, ghostty, p10k)
│   ├── desktop/             # Desktop apps (aerospace, raycast)
│   ├── development/         # Dev tools (git, mcp)
│   └── system/              # System configurations
│
├── packages/                # Package management
│   └── Brewfile            # Homebrew packages (organized)
│
├── scripts/                 # Automation scripts
│   ├── setup/               # Installation scripts
│   ├── maintenance/         # Update and cleanup scripts
│   └── helpers/             # Utility scripts
│
├── docs/                    # Documentation
└── templates/               # Configuration templates
```

## 🚀 Quick Start

### New Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
./install.sh

# Or use make
make install
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

### Installation & Setup
```bash
make install        # Install all configurations
make shell          # Install shell configs only
make editor         # Install editor configs only  
make terminal       # Install terminal configs only
make desktop        # Install desktop configs only
make development    # Install development configs only
```

### Maintenance
```bash
make update         # Update all packages and configs
make clean          # Clean up broken symlinks
make backup         # Create backup of current configs
make uninstall      # Remove all symlinks
```

### Information & Scanning
```bash
make scan           # Scan current symlink setup
make status         # Show installation status
make report         # Generate detailed report
make help           # Show all commands
```

### Package Management
```bash
make packages       # Install Homebrew packages only
./install.sh --packages  # Alternative way
```

## 🔧 Configuration Details

### Shell Configuration (Modular Zsh)

The zsh configuration is split into focused modules:

- **`.zshrc`** - Main configuration file (sources others)
- **`exports.zsh`** - Environment variables and PATH
- **`aliases.zsh`** - Command aliases  
- **`functions.zsh`** - Custom shell functions
- **`completions.zsh`** - Shell completions and tools

### Key Tools Included

**Development:**
- Git with custom configuration and hooks
- GitHub CLI with extensions
- LazyGit for terminal Git interface
- Multiple programming languages (Go, Python, Node.js, Bun)

**Terminal Enhancement:**
- Tmux with custom configuration and plugins
- Neovim with LazyVim setup
- Modern CLI tools (bat, eza, fzf, ripgrep)
- File manager integration (yazi)

**Desktop Applications:**
- AeroSpace (tiling window manager)
- Raycast (productivity launcher)
- Ghostty (terminal emulator)

## 🛠️ Customization

### Adding New Configurations

1. Create a new directory in `stow-packages/`:
   ```bash
   mkdir -p stow-packages/mynewpackage/.config/mytool
   ```

2. Add your configuration files with the correct home directory structure

3. Install the package:
   ```bash
   cd stow-packages && stow -t ~ mynewpackage
   ```

### Modifying Existing Configs

1. Edit files in `stow-packages/` directories
2. Restow the package:
   ```bash
   make restow
   # or
   cd stow-packages && stow -R -t ~ packagename
   ```

## 🔍 Troubleshooting

### Common Issues

**Stow conflicts:**
```bash
make check-conflicts  # Check for conflicts
make status           # Show installation status
```

**Broken symlinks:**
```bash
make clean            # Clean up broken links
./scripts/helpers/scan-symlinks.sh broken
```

**Migration issues:**
```bash
./scripts/helpers/scan-symlinks.sh scan    # Detailed scan
./scripts/helpers/scan-symlinks.sh backup  # Create backup
```

### Getting Help

1. **Check the documentation:** See `docs/` directory for detailed guides
2. **Scan your setup:** Use `make scan` to understand current state
3. **Generate a report:** Use `make report` for comprehensive analysis
4. **Check status:** Use `make status` to see what's installed

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