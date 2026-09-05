#!/bin/bash

# Supports Docker containers, Linux distributions, and Ubuntu for devpods

set -euo pipefail

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

# Detect OS and environment
detect_environment() {
    if [ -f /.dockerenv ]; then
        ENVIRONMENT="docker"
        log_info "Docker environment detected"
    elif command -v systemctl &> /dev/null; then
        ENVIRONMENT="systemd"
        log_info "Systemd-based Linux detected"
    else
        ENVIRONMENT="linux"
        log_info "Generic Linux environment detected"
    fi

    # Detect distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
        log_info "Distribution: $PRETTY_NAME"
    else
        DISTRO="unknown"
        VERSION="unknown"
        log_warning "Unable to detect Linux distribution"
    fi
}

# Install essential packages
install_essentials() {
    log_info "Installing essential packages..."
    
    case $DISTRO in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y \
                curl \
                git \
                wget \
                zsh \
                tmux \
                stow \
                build-essential \
                software-properties-common \
                apt-transport-https \
                ca-certificates \
                gnupg \
                lsb-release \
                unzip \
                tree \
                htop \
                vim \
                nano
            ;;
        fedora|centos|rhel)
            if command -v dnf &> /dev/null; then
                dnf update -y
                dnf install -y \
                    curl \
                    git \
                    wget \
                    zsh \
                    tmux \
                    stow \
                    gcc \
                    gcc-c++ \
                    make \
                    unzip \
                    tree \
                    htop \
                    vim \
                    nano
            else
                yum update -y
                yum install -y \
                    curl \
                    git \
                    wget \
                    zsh \
                    tmux \
                    stow \
                    gcc \
                    gcc-c++ \
                    make \
                    unzip \
                    tree \
                    htop \
                    vim \
                    nano
            fi
            ;;
        alpine)
            apk update
            apk add \
                curl \
                git \
                wget \
                zsh \
                tmux \
                stow \
                build-base \
                unzip \
                tree \
                htop \
                vim \
                nano
            ;;
        *)
            log_warning "Unknown distribution. Attempting to install with common package managers..."
            if command -v apt-get &> /dev/null; then
                apt-get update && apt-get install -y curl git zsh tmux stow
            elif command -v yum &> /dev/null; then
                yum install -y curl git zsh tmux stow
            elif command -v apk &> /dev/null; then
                apk add curl git zsh tmux stow
            else
                log_error "No supported package manager found"
                exit 1
            fi
            ;;
    esac
    
    log_success "Essential packages installed"
}

# Setup user environment
setup_user_environment() {
    log_info "Setting up user environment..."
    
    # Create necessary directories
    mkdir -p ~/.local/share/zsh
    mkdir -p ~/.config
    
    # Set zsh as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        if [ "$ENVIRONMENT" = "docker" ]; then
            log_info "Setting zsh as default shell for container"
            export SHELL=$(which zsh)
            echo 'export SHELL=$(which zsh)' >> ~/.bashrc
        else
            log_info "Changing default shell to zsh"
            chsh -s $(which zsh) || log_warning "Failed to change shell. You may need to do this manually."
        fi
    fi
    
    log_success "User environment setup complete"
}

# Install development tools
install_dev_tools() {
    log_info "Installing development tools..."
    
    # Install Node.js via NodeSource
    if ! command -v node &> /dev/null; then
        log_info "Installing Node.js..."
        case $DISTRO in
            ubuntu|debian)
                curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh && bash /tmp/nodesource_setup.sh
                apt-get install -y nodejs
                ;;
            fedora|centos|rhel)
                curl -fsSL https://rpm.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh && bash /tmp/nodesource_setup.sh
                if command -v dnf &> /dev/null; then
                    dnf install -y nodejs npm
                else
                    yum install -y nodejs npm
                fi
                ;;
            alpine)
                apk add nodejs npm
                ;;
        esac
        log_success "Node.js installed"
    else
        log_info "Node.js already installed"
    fi
    
    # Install Docker if not in Docker environment
    if [ "$ENVIRONMENT" != "docker" ] && ! command -v docker &> /dev/null; then
        log_info "Installing Docker..."
        case $DISTRO in
            ubuntu|debian)
                curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt-get update
                apt-get install -y docker-ce docker-ce-cli containerd.io
                ;;
            fedora)
                dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                dnf install -y docker-ce docker-ce-cli containerd.io
                ;;
        esac
        log_success "Docker installed"
    fi
}

create_linux_exports() {
    log_info "Creating Linux-compatible exports..."
    mkdir -p ~/.local/share/zsh
    
    cat > ~/.local/share/zsh/exports.zsh << 'EOF'
EOF
    log_success "Linux exports created"
}

setup_private_env() {
    log_info "Setting up private environment variables..."
    
    # Create template private file if it doesn't exist
    if [ ! -f ~/.config/private ]; then
        cat > ~/.config/private << 'EOF'
EOF
        log_warning "Created template private file at ~/.config/private"
        log_warning "Please edit ~/.config/private with your actual API keys and secrets"
    fi
    
    log_success "Private environment setup complete"
}

# Setup dotfiles
setup_dotfiles() {
    log_info "Setting up dotfiles..."
    
    # Use stow to symlink configurations
    if [ -d "stow-packages" ]; then
        log_info "Using stow packages..."
        cd stow-packages
        
        # Setup shell configuration
        if [ -d "shell" ]; then
            stow -t ~ shell
            create_linux_exports
            log_success "Shell configuration linked with Linux exports"
        fi
        
        # Setup editor configuration
        if [ -d "editor" ]; then
            stow -t ~ editor
            log_success "Editor configuration linked"
        fi
        
        cd ..
    else
        log_info "Using direct configuration files..."
        
        # Link zsh configuration
        if [ -f "zsh/.zshrc" ]; then
            ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
        fi
        
        if [ -f "zsh/.zprofile" ]; then
            ln -sf "$PWD/zsh/.zprofile" ~/.zprofile
        fi
        
        create_linux_exports
        
        # Link tmux configuration
        if [ -f "tmux/.tmux.conf" ]; then
            ln -sf "$PWD/tmux/.tmux.conf" ~/.tmux.conf
        fi
        
        # Link git configuration
        if [ -f "git/gitconfig" ]; then
            ln -sf "$PWD/git/gitconfig" ~/.gitconfig
        fi
        
        if [ -f "git/gitignore" ]; then
            ln -sf "$PWD/git/gitignore" ~/.gitignore_global
        fi
    fi
    
    setup_private_env
    
    log_success "Dotfiles setup complete with Linux environment variables"
}

# Setup devpod environment
setup_devpod() {
    log_info "Setting up devpod environment..."
    
    if [ ! -z "${DEVPOD:-}" ] || [ ! -z "${CODESPACES:-}" ]; then
        log_info "Devpod/Codespaces environment detected"
        
        # Install additional tools for development
        case $DISTRO in
            ubuntu|debian)
                apt-get install -y \
                    python3 \
                    python3-pip \
                    golang-go \
                    rustc \
                    openjdk-11-jdk
                ;;
            fedora|centos|rhel)
                if command -v dnf &> /dev/null; then
                    dnf install -y python3 python3-pip go rust java-11-openjdk-devel
                else
                    yum install -y python3 python3-pip golang rust java-11-openjdk-devel
                fi
                ;;
            alpine)
                apk add python3 py3-pip go rust openjdk11
                ;;
        esac
        
        # Setup VS Code extensions if code command exists
        if command -v code &> /dev/null; then
            log_info "Installing VS Code extensions..."
            code --install-extension ms-vscode.vscode-typescript-next
            code --install-extension bradlc.vscode-tailwindcss
            code --install-extension esbenp.prettier-vscode
        fi
        
        log_success "Devpod environment setup complete"
    fi
}

# Main execution
main() {
    log_info "Starting dotfiles installation for Docker/Linux environment"
    
    # Check if running as root in Docker
    if [ "$ENVIRONMENT" = "docker" ] && [ "$EUID" -ne 0 ]; then
        log_error "This script needs to run as root in Docker environment"
        exit 1
    fi
    
    # Check if running as non-root in regular Linux
    if [ "$ENVIRONMENT" != "docker" ] && [ "$EUID" -eq 0 ]; then
        log_warning "Running as root in non-Docker environment. This is not recommended."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    detect_environment
    install_essentials
    setup_user_environment
    install_dev_tools
    setup_dotfiles
    setup_devpod
    
    log_success "Installation complete!"
    log_info "Please restart your shell or run 'source ~/.zshrc' to apply changes"
    
    if [ "$ENVIRONMENT" = "docker" ]; then
        log_info "For Docker environments, you may need to set SHELL environment variable"
        log_info "Add 'ENV SHELL=/bin/zsh' to your Dockerfile"
    fi
}

# Run main function
main "$@"
