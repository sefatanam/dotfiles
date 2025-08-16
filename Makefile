# Makefile for Stow-based dotfiles management
# Usage: make help

.PHONY: help install uninstall migrate shell editor terminal desktop development system all update clean scan backup

STOW_DIR = stow-packages
TARGET_DIR = $(HOME)
DOTFILES_DIR = $(HOME)/.dotfiles

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

help: ## Show available commands
	@echo -e "$(BLUE)Dotfiles Management Commands:$(NC)"
	@echo
	@echo -e "$(YELLOW)🚀 Migration & Setup:$(NC)"
	@echo "  make scan        - Scan current symlink setup"
	@echo "  make migrate     - Migrate from manual symlinks to Stow"
	@echo "  make install     - Install all packages with Stow"
	@echo
	@echo -e "$(YELLOW)📦 Package Management:$(NC)"
	@echo "  make shell       - Install shell configuration only"
	@echo "  make editor      - Install editor configuration only"
	@echo "  make terminal    - Install terminal tools only"
	@echo "  make desktop     - Install desktop applications only"
	@echo "  make development - Install development tools only"
	@echo "  make system      - Install system configurations only"
	@echo
	@echo -e "$(YELLOW)🧹 Maintenance:$(NC)"
	@echo "  make uninstall   - Remove all symlinks"
	@echo "  make update      - Update packages and configs"
	@echo "  make clean       - Clean up broken symlinks"
	@echo "  make backup      - Create backup of current configs"
	@echo
	@echo -e "$(YELLOW)ℹ️  Information:$(NC)"
	@echo "  make status      - Show installation status"
	@echo "  make report      - Generate detailed report"

scan: ## Scan current symlink setup
	@echo -e "$(BLUE)🔍 Scanning current dotfiles setup...$(NC)"
	@scripts/helpers/scan-symlinks.sh scan

migrate: ## Migrate from manual symlinks to Stow
	@echo -e "$(BLUE)🚀 Migrating to Stow-based dotfiles...$(NC)"
	@scripts/setup/migrate-to-stow.sh

install: check-stow ## Install all packages with Stow
	@echo -e "$(GREEN)📦 Installing all dotfiles packages with Stow...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) */
	@echo -e "$(GREEN)✅ All dotfiles installed!$(NC)"
	@echo -e "$(YELLOW)💡 Restart your terminal or run 'source ~/.zshrc'$(NC)"

shell: check-stow ## Install shell configuration
	@echo -e "$(GREEN)🐚 Installing shell configuration...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) shell
	@echo -e "$(GREEN)✅ Shell configuration installed!$(NC)"

editor: check-stow ## Install editor configuration
	@echo -e "$(GREEN)📝 Installing editor configuration...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) editor
	@echo -e "$(GREEN)✅ Editor configuration installed!$(NC)"

terminal: check-stow ## Install terminal tools
	@echo -e "$(GREEN)💻 Installing terminal configuration...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) terminal
	@echo -e "$(GREEN)✅ Terminal configuration installed!$(NC)"

desktop: check-stow ## Install desktop applications
	@echo -e "$(GREEN)🖥️  Installing desktop configuration...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) desktop
	@echo -e "$(GREEN)✅ Desktop configuration installed!$(NC)"

development: check-stow ## Install development tools
	@echo -e "$(GREEN)⚒️  Installing development configuration...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) development
	@echo -e "$(GREEN)✅ Development configuration installed!$(NC)"

system: check-stow ## Install system configurations
	@echo -e "$(GREEN)⚙️  Installing system configuration...$(NC)"
	@cd $(STOW_DIR) && stow -v -t $(TARGET_DIR) system
	@echo -e "$(GREEN)✅ System configuration installed!$(NC)"

uninstall: check-stow ## Remove all symlinks
	@echo -e "$(YELLOW)⚠️  Removing all dotfiles symlinks...$(NC)"
	@read -p "Are you sure? [y/N]: " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo; \
		cd $(STOW_DIR) && stow -v -D -t $(TARGET_DIR) */; \
		echo -e "$(GREEN)✅ All symlinks removed!$(NC)"; \
	else \
		echo; \
		echo -e "$(BLUE)Operation cancelled.$(NC)"; \
	fi

check-stow: ## Check if Stow is installed
	@command -v stow >/dev/null 2>&1 || { \
		echo -e "$(YELLOW)GNU Stow is required. Installing...$(NC)"; \
		brew install stow; \
	}

status: check-stow ## Show installation status
	@echo -e "$(BLUE)📊 Dotfiles Installation Status:$(NC)"
	@echo
	@for package in $(STOW_DIR)/*/; do \
		package_name=$$(basename $$package); \
		if stow -n -t $(TARGET_DIR) -d $(STOW_DIR) $$package_name 2>/dev/null; then \
			echo -e "$(GREEN)✅ $$package_name - Ready to install$(NC)"; \
		else \
			echo -e "$(YELLOW)⚠️  $$package_name - Conflicts detected$(NC)"; \
		fi; \
	done

update: ## Update all packages and configurations
	@echo -e "$(BLUE)🔄 Updating packages and configurations...$(NC)"
	@scripts/maintenance/update.sh

clean: ## Clean up broken symlinks
	@echo -e "$(BLUE)🧹 Cleaning up broken symlinks...$(NC)"
	@scripts/helpers/scan-symlinks.sh broken

backup: ## Create backup of current configs
	@echo -e "$(BLUE)💾 Creating backup of current configuration...$(NC)"
	@scripts/helpers/scan-symlinks.sh backup

report: ## Generate detailed report
	@echo -e "$(BLUE)📋 Generating detailed dotfiles report...$(NC)"
	@scripts/helpers/scan-symlinks.sh report

# Advanced operations
restow: check-stow ## Restow all packages (useful after updates)
	@echo -e "$(BLUE)🔄 Restowing all packages...$(NC)"
	@cd $(STOW_DIR) && stow -v -R -t $(TARGET_DIR) */
	@echo -e "$(GREEN)✅ All packages restowed!$(NC)"

packages: ## Install Homebrew packages
	@echo -e "$(BLUE)🍺 Installing Homebrew packages...$(NC)"
	@if [ -f packages/Brewfile ]; then \
		brew bundle --file=packages/Brewfile; \
		echo -e "$(GREEN)✅ Homebrew packages installed!$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠️  No Brewfile found in packages/$(NC)"; \
	fi

# Development helpers
dev-setup: packages install ## Complete development setup
	@echo -e "$(GREEN)🚀 Complete development setup completed!$(NC)"

list-packages: ## List available Stow packages
	@echo -e "$(BLUE)📦 Available Stow packages:$(NC)"
	@for package in $(STOW_DIR)/*/; do \
		package_name=$$(basename $$package); \
		echo "  - $$package_name"; \
	done

# Safety checks
check-conflicts: check-stow ## Check for potential conflicts
	@echo -e "$(BLUE)🔍 Checking for conflicts...$(NC)"
	@for package in $(STOW_DIR)/*/; do \
		package_name=$$(basename $$package); \
		echo -e "$(YELLOW)Checking $$package_name:$(NC)"; \
		stow -n -v -t $(TARGET_DIR) -d $(STOW_DIR) $$package_name || true; \
	done

# Information
info: ## Show system information
	@echo -e "$(BLUE)ℹ️  System Information:$(NC)"
	@echo "Dotfiles directory: $(DOTFILES_DIR)"
	@echo "Stow packages: $(STOW_DIR)"
	@echo "Target directory: $(TARGET_DIR)"
	@echo "Stow version: $$(stow --version | head -1)"
	@echo "Shell: $$SHELL"
	@echo "OS: $$(uname -s) $$(uname -r)"