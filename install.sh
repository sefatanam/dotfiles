#!/bin/bash
# install.sh - Complete Stow-based dotfiles setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DOTFILES_DIR="$HOME/.dotfiles"

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           DOTFILES INSTALLER                                 ║"
    echo "║                        Stow-based Configuration                              ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Help function
show_help() {
    cat << 'EOF'
USAGE:
    ./install.sh [OPTIONS]

OPTIONS:
    --full          - Complete installation (packages + configs) [default]
    --packages      - Install Homebrew packages only
    --configs       - Install configurations only
    --minimal       - Minimal installation (essential packages + configs)
    --migrate       - Migrate from manual symlinks to Stow
    --scan          - Scan current setup without installing
    --help          - Show this help message

EXAMPLES:
    ./install.sh                      # Complete installation
    ./install.sh --packages           # Install packages only
    ./install.sh --configs             # Install configs only
    ./install.sh --migrate             # Migrate existing setup
    ./install.sh --scan               # Scan current setup

NOTES:
    - Run with --migrate if you have existing manual symlinks
    - Use --scan to check current setup before installation
    - All operations create backups before making changes
EOF
}

# Check if this is a fresh install or migration needed
check_migration_needed() {
    echo -e "${BLUE}🔍 Checking current setup...${NC}"
    
    # Check for existing dotfiles symlinks
    if [[ -L "$HOME/.zshrc" ]] && [[ $(readlink "$HOME/.zshrc" 2>/dev/null) == *"/.dotfiles/"* ]]; then
        echo -e "${YELLOW}⚠️  Existing manual symlinks detected.${NC}"
        echo -e "${YELLOW}   You need to migrate first before using Stow.${NC}"
        echo
        echo -e "${CYAN}Run one of these commands:${NC}"
        echo -e "${GREEN}  ./install.sh --migrate    # Automated migration${NC}"
        echo -e "${GREEN}  make migrate              # Using Makefile${NC}"
        echo
        echo -e "${BLUE}Or scan your setup with:${NC}"
        echo -e "${GREEN}  ./install.sh --scan       # Scan only${NC}"
        exit 1
    fi
}

# Install or check for Stow
install_stow() {
    if ! command -v stow &> /dev/null; then
        echo -e "${YELLOW}📦 Installing GNU Stow...${NC}"
        
        if command -v brew &> /dev/null; then
            brew install stow
            echo -e "${GREEN}✅ GNU Stow installed successfully${NC}"
        else
            echo -e "${RED}❌ Homebrew not found. Please install Homebrew first:${NC}"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    else
        echo -e "${GREEN}✅ GNU Stow is already installed${NC}"
    fi
}

# Install Homebrew packages
install_packages() {
    local brewfile="$DOTFILES_DIR/packages/Brewfile"
    
    if [[ ! -f "$brewfile" ]]; then
        echo -e "${RED}❌ Brewfile not found: $brewfile${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🍺 Installing Homebrew packages...${NC}"
    echo -e "${YELLOW}   This may take several minutes...${NC}"
    
    if brew bundle --file="$brewfile"; then
        echo -e "${GREEN}✅ Homebrew packages installed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Some packages may have failed to install${NC}"
        echo -e "${BLUE}💡 You can run 'brew bundle --file=$brewfile' later to retry${NC}"
    fi
}

# Install minimal packages (essential tools only)
install_minimal_packages() {
    echo -e "${BLUE}📦 Installing minimal package set...${NC}"
    
    local essential_packages=(
        "stow"
        "git"
        "neovim"
        "tmux"
        "fzf"
        "bat"
        "eza"
        "zoxide"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! brew list "$package" &>/dev/null; then
            echo -e "${YELLOW}Installing $package...${NC}"
            brew install "$package"
        else
            echo -e "${GREEN}✓ $package already installed${NC}"
        fi
    done
}

# Setup dotfiles with Stow
setup_dotfiles() {
    local stow_dir="$DOTFILES_DIR/stow-packages"
    
    if [[ ! -d "$stow_dir" ]]; then
        echo -e "${RED}❌ Stow packages directory not found: $stow_dir${NC}"
        echo -e "${BLUE}💡 You may need to run migration first${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔗 Setting up dotfiles with Stow...${NC}"
    
    # Check for conflicts first
    echo -e "${YELLOW}Checking for conflicts...${NC}"
    
    local packages=()
    for package_dir in "$stow_dir"/*; do
        if [[ -d "$package_dir" ]]; then
            packages+=($(basename "$package_dir"))
        fi
    done
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No Stow packages found${NC}"
        return 1
    fi
    
    # Install packages one by one for better error handling
    local installed=0
    local failed=0
    
    for package in "${packages[@]}"; do
        echo -e "${YELLOW}Installing $package package...${NC}"
        
        if (cd "$stow_dir" && stow -t "$HOME" "$package"); then
            echo -e "${GREEN}  ✅ $package installed${NC}"
            ((installed++))
        else
            echo -e "${RED}  ❌ $package failed${NC}"
            ((failed++))
        fi
    done
    
    echo -e "\n${CYAN}📊 Installation Summary:${NC}"
    echo -e "${GREEN}✅ Packages installed: $installed${NC}"
    
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}❌ Packages failed: $failed${NC}"
        echo -e "${YELLOW}💡 You can run 'make status' to check for conflicts${NC}"
    fi
    
    if [[ $installed -gt 0 ]]; then
        echo -e "${GREEN}🎉 Dotfiles setup completed!${NC}"
        return 0
    else
        return 1
    fi
}

# Run migration
run_migration() {
    echo -e "${BLUE}🚀 Running migration to Stow...${NC}"
    
    if [[ -f "$DOTFILES_DIR/scripts/setup/migrate-to-stow.sh" ]]; then
        "$DOTFILES_DIR/scripts/setup/migrate-to-stow.sh"
    else
        echo -e "${RED}❌ Migration script not found${NC}"
        exit 1
    fi
}

# Scan current setup
scan_setup() {
    echo -e "${BLUE}🔍 Scanning current dotfiles setup...${NC}"
    
    if [[ -f "$DOTFILES_DIR/scripts/helpers/scan-symlinks.sh" ]]; then
        "$DOTFILES_DIR/scripts/helpers/scan-symlinks.sh" scan
    else
        echo -e "${RED}❌ Scan script not found${NC}"
        exit 1
    fi
}

# Post-installation tasks
post_install() {
    echo -e "\n${CYAN}🎯 Post-installation tasks...${NC}"
    
    # Create necessary directories
    mkdir -p "$HOME/.local/share/zsh"
    
    # Check if shell needs to be changed
    if [[ "$SHELL" != */zsh ]]; then
        echo -e "${YELLOW}💡 Your current shell is not zsh${NC}"
        echo -e "${BLUE}   Consider changing it with: chsh -s \$(which zsh)${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 Installation completed successfully!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${GREEN}1. Restart your terminal or run 'source ~/.zshrc'${NC}"
    echo -e "${GREEN}2. Test your configuration${NC}"
    echo -e "${GREEN}3. Customize as needed${NC}"
    echo
    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "${GREEN}  make help        # Show all available commands${NC}"
    echo -e "${GREEN}  make status      # Check installation status${NC}"
    echo -e "${GREEN}  make update      # Update packages and configs${NC}"
}

# Main installation logic
main() {
    print_banner
    
    local install_packages=true
    local install_configs=true
    local minimal_install=false
    
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --packages)
            install_configs=false
            ;;
        --configs)
            install_packages=false
            ;;
        --minimal)
            minimal_install=true
            ;;
        --migrate)
            run_migration
            exit $?
            ;;
        --scan)
            scan_setup
            exit $?
            ;;
        --full|"")
            # Default: full installation
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo -e "${BLUE}Run with --help for usage information${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}Starting dotfiles installation...${NC}"
    echo -e "${BLUE}Configuration: packages=$install_packages, configs=$install_configs, minimal=$minimal_install${NC}"
    echo
    
    # Check if migration is needed (only for config installation)
    if [[ "$install_configs" == true ]]; then
        check_migration_needed
    fi
    
    # Install Stow if needed
    if [[ "$install_configs" == true ]]; then
        install_stow
    fi
    
    # Install packages
    if [[ "$install_packages" == true ]]; then
        if [[ "$minimal_install" == true ]]; then
            install_minimal_packages
        else
            install_packages
        fi
    fi
    
    # Setup configurations
    if [[ "$install_configs" == true ]]; then
        if setup_dotfiles; then
            post_install
        else
            echo -e "${RED}❌ Configuration setup failed${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}🎉 Installation process completed!${NC}"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi