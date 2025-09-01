#!/bin/bash
# Zsh optimization script - run after config changes

echo "🚀 Optimizing zsh configuration..."

# Create cache directories
mkdir -p "$HOME/.cache/zsh-init"

# Clean old cache files
echo "🧹 Cleaning old cache files..."
find "$HOME/.cache" -name "*zsh*" -type f -mtime +7 -delete 2>/dev/null || true

# Pre-compile all zsh files
echo "⚡ Pre-compiling zsh files..."
ZSH_CONFIG_DIR="$HOME/.local/share/zsh"
for file in "$ZSH_CONFIG_DIR"/*.zsh ~/.zshrc; do
    if [[ -f "$file" ]]; then
        echo "  Compiling: $file"
        zcompile "$file" 2>/dev/null || true
    fi
done

# Pre-generate cache files for tools that exist
echo "📦 Pre-generating cache files..."
command -v zoxide >/dev/null 2>&1 && zoxide init zsh > "$HOME/.cache/zsh-init/zoxide-init.zsh"
command -v atuin >/dev/null 2>&1 && atuin init zsh --disable-ctrl-r > "$HOME/.cache/zsh-init/atuin-init.zsh"

# Test startup time
echo "🏁 Testing startup performance..."
echo "Running 3 startup tests..."
total=0
for i in {1..3}; do
    time_result=$(TIMEFORMAT='%3R'; { time zsh -lic exit; } 2>&1)
    echo "  Run $i: ${time_result}s"
    total=$(echo "$total + $time_result" | bc 2>/dev/null || echo "$total")
done
avg=$(echo "scale=3; $total / 3" | bc 2>/dev/null || echo "calc_error")
echo "📊 Average startup time: ${avg}s"

echo "✅ Zsh optimization complete!"
echo "💡 Run 'zsh-bench' anytime to test performance"