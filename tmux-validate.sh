#!/bin/bash
# @REVIEW: Tmux configuration validation script

echo "🔍 Validating tmux configuration..."

# Check if tmux config is valid
if tmux -f ~/.tmux.conf list-sessions -F '' 2>/dev/null; then
    echo "✅ Tmux configuration syntax is valid"
else
    echo "❌ Tmux configuration has syntax errors"
    exit 1
fi

# Check if plugins directory exists
if [ -d ~/.tmux/plugins ]; then
    echo "✅ Tmux plugins directory exists"
    
    # Count installed plugins
    plugin_count=$(find ~/.tmux/plugins -maxdepth 1 -type d | wc -l)
    echo "📦 Found $((plugin_count - 1)) installed plugins"
else
    echo "⚠️  Tmux plugins directory not found - will be created on first use"
fi

# Check for required commands
commands=("fzf" "lazygit" "yazi" "nvim")
missing_commands=()

for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd is available"
    else
        echo "⚠️  $cmd is missing (optional for popups)"
        missing_commands+=("$cmd")
    fi
done

# Show configuration stats
echo ""
echo "📊 Configuration Statistics:"
echo "   Lines: $(wc -l < ~/.tmux.conf)"
echo "   Key bindings: $(grep -c '^bind' ~/.tmux.conf)"
echo "   Plugins: $(grep -c '@plugin' ~/.tmux.conf)"
echo "   Status components: $(grep -c 'status-right' ~/.tmux.conf)"

if [ ${#missing_commands[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All checks passed! Your tmux configuration is ready to use."
    echo "💡 Reload with: tmux source-file ~/.tmux.conf"
else
    echo ""
    echo "⚠️  Some optional commands are missing. Install with:"
    echo "   brew install fzf lazygit yazi neovim"
fi