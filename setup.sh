#!/bin/bash

# Smart installation script for macOS development environment with skip functionality

set -e  # Exit on any error

# Enable debug mode if DEBUG=1 is set
[[ "${DEBUG:-0}" == "1" ]] && set -x

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global counters
INSTALLED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

# Verbose mode flag
VERBOSE=${VERBOSE:-1}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
}

log_skip() {
    echo -e "${CYAN}[SKIP]${NC} $1"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    FAILED_COUNT=$((FAILED_COUNT + 1))
}

log_check() {
    echo -e "${MAGENTA}[CHECK]${NC} $1"
}

# Print section headers
print_section() {
    echo
    echo -e "${BLUE}==== $1 ====${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Comprehensive system check
check_prerequisites() {
    print_section "CHECKING PREREQUISITES"
    
    log_check "Operating System"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script requires macOS"
        exit 1
    fi
    local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    log_success "macOS detected (version: $macos_version)"
    
    log_check "Command Line Tools"
    # Check without hanging - use a simpler approach
    local xcode_path=""
    xcode_path=$(xcode-select -p 2>/dev/null) || true
    if [[ -n "$xcode_path" && -d "$xcode_path" ]]; then
        log_skip "Xcode Command Line Tools already installed ($xcode_path)"
    else
        log_warning "Xcode Command Line Tools not found - will be installed with Homebrew"
    fi
    
    log_check "Internet connection"
    # Use a more reliable ping with count limit
    if ping -c 1 -W 3000 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connection verified"
    elif ping -c 1 -W 3000 1.1.1.1 >/dev/null 2>&1; then
        log_success "Internet connection verified (via Cloudflare DNS)"
    else
        log_error "No internet connection detected - please check your network"
        exit 1
    fi
}

# User confirmation function
ask_confirmation() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$message [Y/n]: "
    else
        prompt="$message [y/N]: "
    fi
    
    while true; do
        echo -e "${YELLOW}[CONFIRM]${NC} $prompt" >&2
        read -r response
        
        # Use default if empty response
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo -e "${RED}Please answer yes (y) or no (n)${NC}" >&2
                ;;
        esac
    done
}

# Check and install Homebrew
setup_homebrew() {
    print_section "HOMEBREW SETUP"
    
    if command_exists brew; then
        log_skip "Homebrew already installed ($(brew --version | head -n1))"
        
        log_check "Updating Homebrew"
        if brew update &> /dev/null; then
            log_success "Homebrew updated"
        else
            log_warning "Failed to update Homebrew"
        fi
    else
        log_warning "Homebrew is not installed"
        echo
        echo -e "${BLUE}Homebrew is the recommended package manager for macOS.${NC}"
        echo -e "${BLUE}It will install essential development tools and CLI utilities.${NC}"
        echo -e "${BLUE}This will also install Xcode Command Line Tools if needed.${NC}"
        echo
        
        if ask_confirmation "Do you want to install Homebrew?"; then
            log_info "Installing Homebrew..."
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                # Add Homebrew to PATH for current session
                if [[ $(uname -m) == "arm64" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                    # Add to profile if not already there
                    if ! grep -q "/opt/homebrew/bin/brew shellenv" ~/.zprofile 2>/dev/null; then
                        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                    fi
                else
                    eval "$(/usr/local/bin/brew shellenv)"
                    if ! grep -q "/usr/local/bin/brew shellenv" ~/.zprofile 2>/dev/null; then
                        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
                    fi
                fi
                log_success "Homebrew installed successfully"
            else
                log_error "Failed to install Homebrew"
                exit 1
            fi
        else
            log_error "Homebrew installation declined. Cannot continue without package manager."
            echo -e "${YELLOW}To proceed manually:${NC}"
            echo "1. Install Homebrew: https://brew.sh"
            echo "2. Run this script again"
            exit 1
        fi
    fi
}

# Check and install essential tools
setup_essential_tools() {
    print_section "ESSENTIAL TOOLS"
    
    # GNU Stow
    log_check "GNU Stow"
    if command_exists stow; then
        log_skip "GNU Stow already installed ($(stow --version | head -n1))"
    else
        log_info "Installing GNU Stow..."
        if brew install stow; then
            log_success "GNU Stow installed"
        else
            log_error "Failed to install GNU Stow"
            exit 1
        fi
    fi
    
    # Git
    log_check "Git"
    if command_exists git; then
        log_skip "Git already installed ($(git --version))"
    else
        log_info "Installing Git..."
        if brew install git; then
            log_success "Git installed"
        else
            log_error "Failed to install Git"
            exit 1
        fi
    fi
}

# Check and install Oh My Zsh
setup_oh_my_zsh() {
    print_section "OH MY ZSH SETUP"
    
    local omz_dir="$HOME/.oh-my-zsh"
    log_check "Oh My Zsh installation"
    
    if dir_exists "$omz_dir"; then
        log_skip "Oh My Zsh already installed"
        
        # Check for updates
        log_check "Checking for Oh My Zsh updates"
        if [[ -d "$omz_dir/.git" ]]; then
            cd "$omz_dir"
            if git fetch &> /dev/null && [[ $(git rev-list HEAD...origin/master --count) -gt 0 ]]; then
                log_info "Updating Oh My Zsh..."
                if git pull &> /dev/null; then
                    log_success "Oh My Zsh updated"
                else
                    log_warning "Failed to update Oh My Zsh"
                fi
            else
                log_skip "Oh My Zsh is up to date"
            fi
            cd - > /dev/null
        fi
    else
        log_info "Installing Oh My Zsh..."
        if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_success "Oh My Zsh installed"
        else
            log_error "Failed to install Oh My Zsh"
            exit 1
        fi
    fi
}

# Check and install Powerlevel10k
setup_powerlevel10k() {
    print_section "POWERLEVEL10K SETUP"
    
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    log_check "Powerlevel10k theme"
    
    if dir_exists "$p10k_dir"; then
        log_skip "Powerlevel10k already installed"
        
        # Check for updates
        log_check "Checking for Powerlevel10k updates"
        if [[ -d "$p10k_dir/.git" ]]; then
            cd "$p10k_dir"
            if git fetch &> /dev/null && [[ $(git rev-list HEAD...origin/master --count) -gt 0 ]]; then
                log_info "Updating Powerlevel10k..."
                if git pull &> /dev/null; then
                    log_success "Powerlevel10k updated"
                else
                    log_warning "Failed to update Powerlevel10k"
                fi
            else
                log_skip "Powerlevel10k is up to date"
            fi
            cd - > /dev/null
        fi
    else
        log_info "Installing Powerlevel10k theme..."
        if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"; then
            log_success "Powerlevel10k installed"
        else
            log_error "Failed to install Powerlevel10k"
            exit 1
        fi
    fi
}

# Check and install Brewfile dependencies
setup_brewfile_deps() {
    print_section "BREWFILE DEPENDENCIES"
    
    local brewfile="$HOME/.dotfiles/brew/Brewfile"
    log_check "Brewfile location"
    
    if file_exists "$brewfile"; then
        log_success "Brewfile found at $brewfile"
        
        log_info "Checking Brewfile dependencies..."
        if brew bundle check --file="$brewfile" &> /dev/null; then
            log_skip "All Brewfile dependencies already installed"
        else
            log_warning "Some Brewfile dependencies are missing"
            echo
            echo -e "${BLUE}The Brewfile contains 80+ CLI tools and applications including:${NC}"
            echo -e "${BLUE}- Development tools (Node.js, Python, Go, Docker alternatives)${NC}"
            echo -e "${BLUE}- CLI utilities (bat, eza, ripgrep, fzf, lazygit, etc.)${NC}"
            echo -e "${BLUE}- Applications (Ghostty, AeroSpace, Cursor, etc.)${NC}"
            echo
            echo -e "${YELLOW}This may take several minutes and download significant data.${NC}"
            echo
            
            if ask_confirmation "Do you want to install the missing Brewfile dependencies?" "y"; then
                log_info "Installing missing Brewfile dependencies..."
                if brew bundle --file="$brewfile"; then
                    log_success "Brewfile dependencies installed"
                else
                    log_warning "Some Brewfile dependencies failed to install"
                fi
            else
                log_skip "Brewfile dependencies installation declined"
                echo -e "${YELLOW}Note: Some dotfiles features may not work without these tools.${NC}"
            fi
        fi
    else
        log_warning "Brewfile not found at $brewfile - skipping"
    fi
}

# Check and setup dotfiles with Stow
setup_dotfiles() {
    print_section "DOTFILES CONFIGURATION"
    
    local dotfiles_dir="$HOME/.dotfiles"
    local stow_dir="$dotfiles_dir/stow-packages"
    
    log_check "Dotfiles directory"
    if ! dir_exists "$dotfiles_dir"; then
        log_error "Dotfiles directory not found at $dotfiles_dir"
        log_error "Please clone your dotfiles repository first"
        exit 1
    fi
    log_success "Dotfiles directory found"
    
    log_check "Stow packages directory"
    if ! dir_exists "$stow_dir"; then
        log_error "Stow packages directory not found at $stow_dir"
        exit 1
    fi
    log_success "Stow packages directory found"
    
    log_check "Available stow packages"
    local packages=($(find "$stow_dir" -maxdepth 1 -type d -not -name "." -not -name ".." -exec basename {} \;))
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warning "No stow packages found in $stow_dir"
        return
    fi
    log_info "Found packages: ${packages[*]}"
    
    cd "$stow_dir"
    for package in "${packages[@]}"; do
        log_check "Stowing package: $package"
        # pi needs --no-folding: ~/.pi/agent also holds pi's own real dirs (auth, sessions)
        local stow_opts=()
        [[ "$package" == "pi" ]] && stow_opts=(--no-folding)
        if stow "${stow_opts[@]}" -t ~ "$package" 2>/dev/null; then
            log_success "Package '$package' stowed successfully"
        elif stow "${stow_opts[@]}" -R -t ~ "$package" 2>/dev/null; then
            log_success "Package '$package' re-stowed successfully"
        else
            log_warning "Failed to stow package '$package'"
        fi
    done
}

# Check and create private file
setup_private_file() {
    print_section "PRIVATE CONFIGURATION"
    
    local private_file="$HOME/.private"
    log_check "Private file for secrets"
    
    if file_exists "$private_file"; then
        log_skip "Private file already exists at $private_file"
    else
        log_info "Creating private file for secrets..."
        cat > "$private_file" << 'EOF'
# Private environment variables and secrets
# Add your API keys, tokens, and other sensitive data here
# This file is sourced by .zshrc

# Example entries:
# export OPENAI_API_KEY="your-key-here"
# export GITHUB_TOKEN="your-token-here"
# export AWS_ACCESS_KEY_ID="your-key-here"
# export AWS_SECRET_ACCESS_KEY="your-secret-here"

# Custom aliases and functions can also go here
# alias myserver="ssh user@myserver.com"
EOF
        chmod 600 "$private_file"
        log_success "Private file created at $private_file (permissions: 600)"
    fi
}

# Final verification
verify_installation() {
    print_section "INSTALLATION VERIFICATION"
    
    local tools=("brew" "stow" "git" "zsh")
    local all_good=true
    
    for tool in "${tools[@]}"; do
        log_check "Verifying $tool"
        if command_exists "$tool"; then
            log_success "$tool is available"
        else
            log_error "$tool is not available"
            all_good=false
        fi
    done
    
    log_check "Oh My Zsh installation"
    if dir_exists "$HOME/.oh-my-zsh"; then
        log_success "Oh My Zsh is installed"
    else
        log_error "Oh My Zsh is not installed"
        all_good=false
    fi
    
    log_check "Powerlevel10k theme"
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if dir_exists "$p10k_dir"; then
        log_success "Powerlevel10k is installed"
    else
        log_error "Powerlevel10k is not installed"
        all_good=false
    fi
    
    if $all_good; then
        log_success "All components verified successfully"
    else
        log_warning "Some components failed verification"
    fi
}

# Print summary
print_summary() {
    print_section "SETUP SUMMARY"
    
    echo -e "${GREEN}✓ Installed/Updated:${NC} $INSTALLED_COUNT items"
    echo -e "${CYAN}⊘ Skipped:${NC} $SKIPPED_COUNT items"
    
    if [[ $FAILED_COUNT -gt 0 ]]; then
        echo -e "${RED}✗ Failed:${NC} $FAILED_COUNT items"
    fi
    
    echo
    log_info "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Run: p10k configure (for prompt customization)"
    echo "3. Edit ~/.private to add your secrets/API keys"
    echo "4. Configure AeroSpace workspace bindings as needed"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo
        log_success "🎉 Setup completed successfully!"
    else
        echo
        log_warning "⚠️  Setup completed with some issues. Check the output above."
    fi
}

# Main function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    DOTFILES SETUP SCRIPT                     ║${NC}"
    echo -e "${BLUE}║              Smart Installation with Skip Logic              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Run all setup functions
    check_prerequisites
    setup_homebrew
    setup_essential_tools
    setup_oh_my_zsh
    setup_powerlevel10k
    setup_brewfile_deps
    setup_dotfiles
    setup_private_file
    verify_installation
    print_summary
}

# Handle script interruption
trap 'echo -e "\n${RED}[INTERRUPTED]${NC} Setup interrupted by user"; exit 130' INT

# Run main function
main "$@"
