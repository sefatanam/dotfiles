#!/bin/bash
# scan-symlinks.sh - Comprehensive symlink scanner for safe dotfiles migration
# This script scans your system for symlinks pointing to dotfiles and provides options for safe cleanup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
SCAN_RESULTS_FILE="/tmp/dotfiles-symlinks-$(date +%Y%m%d-%H%M%S).txt"

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         DOTFILES SYMLINK SCANNER                             ║"
    echo "║                     Safe Migration & Cleanup Tool                            ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Help function
show_help() {
    cat << 'EOF'
USAGE:
    ./scan-symlinks.sh [OPTIONS]

OPTIONS:
    scan              - Scan for all dotfiles symlinks (default)
    backup            - Create backup of all linked configs
    remove            - Remove all dotfiles symlinks (with confirmation)
    migrate           - Full migration: backup + remove + prepare for Stow
    broken            - Find and optionally remove broken symlinks
    report            - Generate detailed report of current setup
    help              - Show this help message

EXAMPLES:
    ./scan-symlinks.sh                    # Scan and show all symlinks
    ./scan-symlinks.sh backup             # Backup all current configs
    ./scan-symlinks.sh migrate            # Full migration to Stow
    ./scan-symlinks.sh broken             # Find broken symlinks
    ./scan-symlinks.sh remove             # Remove all dotfiles symlinks

NOTES:
    - All operations create backups before making changes
    - Scan results are saved to: /tmp/dotfiles-symlinks-*.txt
    - Use 'migrate' for complete transition to Stow-based setup
EOF
}

# Scan for dotfiles symlinks
scan_symlinks() {
    echo -e "${BLUE}🔍 Scanning for dotfiles symlinks...${NC}"
    
    # Common locations to scan
    local scan_paths=(
        "$HOME"
        "$HOME/.config"
        "$HOME/.local"
        "$HOME/.local/share"
        "$HOME/.local/bin"
    )
    
    local symlinks_found=()
    local broken_symlinks=()
    
    echo "# Dotfiles Symlink Scan Report - $(date)" > "$SCAN_RESULTS_FILE"
    echo "# Scan performed from: $DOTFILES_DIR" >> "$SCAN_RESULTS_FILE"
    echo "" >> "$SCAN_RESULTS_FILE"
    
    for scan_path in "${scan_paths[@]}"; do
        if [[ -d "$scan_path" ]]; then
            echo -e "${YELLOW}Scanning: $scan_path${NC}"
            
            # Find symlinks pointing to dotfiles directory
            while IFS= read -r -d '' symlink; do
                if [[ -L "$symlink" ]]; then
                    target=$(readlink "$symlink")
                    
                    # Check if it points to our dotfiles directory
                    if [[ "$target" == *"$DOTFILES_DIR"* ]] || [[ "$target" == *"/.dotfiles/"* ]]; then
                        if [[ -e "$target" ]]; then
                            symlinks_found+=("$symlink -> $target")
                            echo "ACTIVE: $symlink -> $target" >> "$SCAN_RESULTS_FILE"
                            echo -e "${GREEN}  ✓ $symlink -> $target${NC}"
                        else
                            broken_symlinks+=("$symlink -> $target (BROKEN)")
                            echo "BROKEN: $symlink -> $target" >> "$SCAN_RESULTS_FILE"
                            echo -e "${RED}  ✗ $symlink -> $target (BROKEN)${NC}"
                        fi
                    fi
                fi
            done < <(find "$scan_path" -maxdepth 2 -type l -print0 2>/dev/null)
        fi
    done
    
    # Summary
    echo "" >> "$SCAN_RESULTS_FILE"
    echo "# SUMMARY" >> "$SCAN_RESULTS_FILE"
    echo "Active symlinks: ${#symlinks_found[@]}" >> "$SCAN_RESULTS_FILE"
    echo "Broken symlinks: ${#broken_symlinks[@]}" >> "$SCAN_RESULTS_FILE"
    
    echo -e "\n${CYAN}📊 SCAN SUMMARY:${NC}"
    echo -e "${GREEN}Active symlinks found: ${#symlinks_found[@]}${NC}"
    echo -e "${RED}Broken symlinks found: ${#broken_symlinks[@]}${NC}"
    echo -e "${BLUE}Full report saved to: $SCAN_RESULTS_FILE${NC}"
    
    return ${#symlinks_found[@]}
}

# Create backup of current configuration
backup_configs() {
    echo -e "${BLUE}💾 Creating backup of current configuration...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    
    # Scan for symlinks first
    scan_symlinks > /dev/null
    
    local backed_up=0
    
    # Read symlinks from scan results and backup
    while IFS= read -r line; do
        if [[ "$line" =~ ^ACTIVE:\ (.*)\ -\>\ (.*)$ ]]; then
            local symlink_path="${BASH_REMATCH[1]}"
            local target_path="${BASH_REMATCH[2]}"
            
            if [[ -L "$symlink_path" ]]; then
                # Create backup directory structure
                local backup_path="$BACKUP_DIR${symlink_path#$HOME}"
                mkdir -p "$(dirname "$backup_path")"
                
                # Record the symlink for restoration
                echo "$symlink_path -> $target_path" >> "$BACKUP_DIR/symlinks.txt"
                
                echo -e "${GREEN}  ✓ Backed up: $symlink_path${NC}"
                ((backed_up++))
            fi
        fi
    done < "$SCAN_RESULTS_FILE"
    
    # Copy the scan results to backup
    cp "$SCAN_RESULTS_FILE" "$BACKUP_DIR/scan-results.txt"
    
    echo -e "${GREEN}✅ Backup completed!${NC}"
    echo -e "${BLUE}Backup location: $BACKUP_DIR${NC}"
    echo -e "${BLUE}Files backed up: $backed_up${NC}"
    
    # Create restoration script
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# restore.sh - Restore symlinks from backup

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restoring symlinks from: $BACKUP_DIR"

if [[ -f "$BACKUP_DIR/symlinks.txt" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^(.*)\ -\>\ (.*)$ ]]; then
            symlink_path="${BASH_REMATCH[1]}"
            target_path="${BASH_REMATCH[2]}"
            
            if [[ -e "$target_path" ]]; then
                ln -sf "$target_path" "$symlink_path"
                echo "Restored: $symlink_path -> $target_path"
            else
                echo "WARNING: Target not found: $target_path"
            fi
        fi
    done < "$BACKUP_DIR/symlinks.txt"
    echo "Restoration complete!"
else
    echo "ERROR: symlinks.txt not found in backup"
fi
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
    echo -e "${CYAN}💡 To restore this configuration later, run: $BACKUP_DIR/restore.sh${NC}"
}

# Remove dotfiles symlinks
remove_symlinks() {
    echo -e "${YELLOW}⚠️  This will remove all symlinks pointing to your dotfiles directory.${NC}"
    echo -e "${YELLOW}   A backup will be created automatically.${NC}"
    
    read -p "Do you want to continue? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Operation cancelled.${NC}"
        return 0
    fi
    
    # Create backup first
    backup_configs
    
    echo -e "${BLUE}🗑️  Removing dotfiles symlinks...${NC}"
    
    local removed=0
    
    # Read symlinks from scan results and remove
    while IFS= read -r line; do
        if [[ "$line" =~ ^ACTIVE:\ (.*)\ -\>\ (.*)$ ]]; then
            local symlink_path="${BASH_REMATCH[1]}"
            
            if [[ -L "$symlink_path" ]]; then
                rm "$symlink_path"
                echo -e "${GREEN}  ✓ Removed: $symlink_path${NC}"
                ((removed++))
            fi
        fi
    done < "$SCAN_RESULTS_FILE"
    
    echo -e "${GREEN}✅ Removal completed!${NC}"
    echo -e "${BLUE}Symlinks removed: $removed${NC}"
}

# Find and handle broken symlinks
find_broken_symlinks() {
    echo -e "${BLUE}🔍 Scanning for broken symlinks...${NC}"
    
    local broken_found=()
    
    # Scan common locations for broken symlinks
    local scan_paths=("$HOME" "$HOME/.config" "$HOME/.local")
    
    for scan_path in "${scan_paths[@]}"; do
        if [[ -d "$scan_path" ]]; then
            while IFS= read -r -d '' symlink; do
                if [[ -L "$symlink" ]] && [[ ! -e "$symlink" ]]; then
                    local target=$(readlink "$symlink")
                    broken_found+=("$symlink -> $target")
                    echo -e "${RED}  ✗ $symlink -> $target${NC}"
                fi
            done < <(find "$scan_path" -maxdepth 3 -type l -print0 2>/dev/null)
        fi
    done
    
    if [[ ${#broken_found[@]} -eq 0 ]]; then
        echo -e "${GREEN}✅ No broken symlinks found!${NC}"
        return 0
    fi
    
    echo -e "\n${YELLOW}Found ${#broken_found[@]} broken symlinks.${NC}"
    
    read -p "Do you want to remove them? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for broken in "${broken_found[@]}"; do
            local symlink_path="${broken% -> *}"
            rm "$symlink_path"
            echo -e "${GREEN}  ✓ Removed: $symlink_path${NC}"
        done
        echo -e "${GREEN}✅ Broken symlinks cleaned up!${NC}"
    fi
}

# Generate detailed report
generate_report() {
    echo -e "${BLUE}📋 Generating detailed dotfiles report...${NC}"
    
    local report_file="$HOME/dotfiles-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# Dotfiles Configuration Report

Generated on: $(date)
Dotfiles directory: \`$DOTFILES_DIR\`

## Current Structure

\`\`\`
$(tree "$DOTFILES_DIR" -L 2 2>/dev/null || find "$DOTFILES_DIR" -maxdepth 2 -type d | sort)
\`\`\`

## Active Symlinks

EOF
    
    # Scan and add symlinks to report
    scan_symlinks > /dev/null
    
    echo "| Source | Target |" >> "$report_file"
    echo "|--------|--------|" >> "$report_file"
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^ACTIVE:\ (.*)\ -\>\ (.*)$ ]]; then
            local symlink_path="${BASH_REMATCH[1]}"
            local target_path="${BASH_REMATCH[2]}"
            echo "| \`$symlink_path\` | \`$target_path\` |" >> "$report_file"
        fi
    done < "$SCAN_RESULTS_FILE"
    
    cat >> "$report_file" << EOF

## Homebrew Packages

\`\`\`
$(brew list --formula | head -20)
...
\`\`\`

## System Information

- OS: $(uname -s) $(uname -r)
- Shell: $SHELL
- Terminal: $TERM

## Recommendations

$(if [[ -f "$DOTFILES_DIR/packages/Brewfile" ]]; then
    echo "- ✅ Brewfile found - package management ready"
else
    echo "- ❌ No Brewfile found - consider organizing packages"
fi)

$(if [[ -d "$DOTFILES_DIR/stow-packages" ]]; then
    echo "- ✅ Stow packages directory exists"
else
    echo "- ❌ No Stow packages - consider migrating to Stow"
fi)

Generated by dotfiles symlink scanner
EOF
    
    echo -e "${GREEN}✅ Report generated: $report_file${NC}"
    
    # Open report if possible
    if command -v glow &> /dev/null; then
        echo -e "${CYAN}📖 Opening report with glow...${NC}"
        glow "$report_file"
    elif command -v bat &> /dev/null; then
        echo -e "${CYAN}📖 Opening report with bat...${NC}"
        bat "$report_file"
    fi
}

# Full migration workflow
migrate_to_stow() {
    echo -e "${CYAN}🚀 Starting full migration to Stow-based dotfiles...${NC}"
    
    # Check if Stow is installed
    if ! command -v stow &> /dev/null; then
        echo -e "${YELLOW}GNU Stow not found. Installing...${NC}"
        brew install stow
    fi
    
    # Step 1: Scan current setup
    echo -e "\n${BLUE}Step 1: Scanning current setup${NC}"
    scan_symlinks
    
    # Step 2: Create backup
    echo -e "\n${BLUE}Step 2: Creating backup${NC}"
    backup_configs
    
    # Step 3: Remove old symlinks
    echo -e "\n${BLUE}Step 3: Removing old symlinks${NC}"
    remove_symlinks
    
    # Step 4: Clean up broken symlinks
    echo -e "\n${BLUE}Step 4: Cleaning broken symlinks${NC}"
    find_broken_symlinks
    
    echo -e "\n${GREEN}✅ Migration preparation complete!${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "${YELLOW}1. Run 'make install' to setup with Stow${NC}"
    echo -e "${YELLOW}2. Test your configuration${NC}"
    echo -e "${YELLOW}3. If needed, restore with: $BACKUP_DIR/restore.sh${NC}"
}

# Main function
main() {
    print_banner
    
    case "${1:-scan}" in
        scan)
            scan_symlinks
            ;;
        backup)
            backup_configs
            ;;
        remove)
            scan_symlinks > /dev/null
            remove_symlinks
            ;;
        broken)
            find_broken_symlinks
            ;;
        migrate)
            migrate_to_stow
            ;;
        report)
            generate_report
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo -e "${BLUE}Run with 'help' for usage information.${NC}"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"