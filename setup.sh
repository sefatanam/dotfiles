#!/bin/bash

# @REVIEW: Dotfiles setup script for prerequisites
# Comprehensive installation script for macOS development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    log_success "Running on macOS"
}

# Install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        log_success "Homebrew installed"
    else
        log_success "Homebrew already installed"
    fi
}

# Install GNU Stow
install_stow() {
    if ! command -v stow &> /dev/null; then
        log_info "Installing GNU Stow..."
        brew install stow
        log_success "GNU Stow installed"
    else
        log_success "GNU Stow already installed"
    fi
}

# Install Git if not present
install_git() {
    if ! command -v git &> /dev/null; then
        log_info "Installing Git..."
        brew install git
        log_success "Git installed"
    else
        log_success "Git already installed"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    else
        log_success "Oh My Zsh already installed"
    fi
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        log_success "Powerlevel10k installed"
    else
        log_success "Powerlevel10k already installed"
    fi
}

# Install Brewfile dependencies
install_brewfile_deps() {
    local brewfile="$HOME/.dotfiles/brew/Brewfile"
    if [[ -f "$brewfile" ]]; then
        log_info "Installing Brewfile dependencies..."
        brew bundle --file="$brewfile"
        log_success "Brewfile dependencies installed"
    else
        log_warning "Brewfile not found at $brewfile"
    fi
}

# Setup dotfiles with Stow
setup_dotfiles() {
    local dotfiles_dir="$HOME/.dotfiles"
    local stow_dir="$dotfiles_dir/stow-packages"
    
    if [[ -d "$stow_dir" ]]; then
        log_info "Setting up dotfiles with Stow..."
        cd "$stow_dir"
        stow -t ~ shell editor 2>/dev/null || {
            log_warning "Some symlinks may already exist. Re-stowing..."
            stow -R -t ~ shell editor
        }
        log_success "Dotfiles configured with Stow"
    else
        log_error "Dotfiles directory not found. Please clone the repository first."
        exit 1
    fi
}

# Create private file for secrets
setup_private_file() {
    local private_file="$HOME/.private"
    if [[ ! -f "$private_file" ]]; then
        log_info "Creating private file for secrets..."
        cat > "$private_file" << 'EOF'
# Private environment variables and secrets
# Add your API keys, tokens, and other sensitive data here

# Example:
# export OPENAI_API_KEY="your-key-here"
# export GITHUB_TOKEN="your-token-here"
EOF
        chmod 600 "$private_file"
        log_success "Private file created at $private_file"
    else
        log_success "Private file already exists"
    fi
}

# Main setup function
main() {
    log_info "Starting dotfiles setup..."
    
    check_macos
    install_homebrew
    install_stow
    install_git
    install_oh_my_zsh
    install_powerlevel10k
    install_brewfile_deps
    setup_dotfiles
    setup_private_file
    
    log_success "Setup complete!"
    echo
    log_info "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Run: p10k configure (for prompt customization)"
    echo "3. Edit ~/.private to add your secrets/API keys"
    echo "4. Configure AeroSpace workspace bindings as needed"
}

# Run main function
main "$@"