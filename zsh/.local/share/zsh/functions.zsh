# functions.zsh - Custom shell functions

# Lightweight directory navigation (no fzf dependency at startup)
cd_to_dir() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf not found. Install with: brew install fzf"
        return 1
    fi
    local selected_dir
    selected_dir=$(fd -t d . "$1" | fzf +m --height 50% --preview 'tree -C {}')
    [[ -n "$selected_dir" ]] && cd "$selected_dir"
}

# Lazy load directory suggestion widget only when first used
_directory_suggestion_widget() {
    if ! command -v fzf >/dev/null 2>&1 || ! command -v fd >/dev/null 2>&1; then
        echo "Missing dependencies: fzf, fd"
        return 1
    fi
    
    local selected_dir
    selected_dir=$(fd -t d . . 2>/dev/null | fzf \
        --height 40% \
        --layout=reverse \
        --border \
        --prompt="📁 Select directory: " \
        --preview 'ls -la {}' \
        --preview-window=right:50%:wrap \
        +m)
    
    [[ -n "$selected_dir" ]] && LBUFFER="${LBUFFER}${selected_dir}"
    zle redisplay
}

zle -N _directory_suggestion_widget

# Lazy load Yazi function
y() {
    if ! command -v yazi >/dev/null 2>&1; then
        echo "yazi not found. Install with: brew install yazi"
        return 1
    fi
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Lazy load ffmpeg function
optimize() {
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "ffmpeg not found. Install with: brew install ffmpeg"
        return 1
    fi
    
    if [ -z "$1" ]; then
        echo "Usage: optimize /path/to/video"
        return 1
    fi

    local input_video="$1"
    local filename_without_ext="${input_video%.*}"
    local output_video="${filename_without_ext}_optimized.mov"

    ffmpeg -i "$input_video" -vf scale=1280:720 "$output_video"
    echo "✅ Optimized video saved as: $output_video"
}

# Lazy load Angular CLI function
ngnew() {
    if ! command -v npx >/dev/null 2>&1; then
        echo "npx not found. Node.js required."
        return 1
    fi
    
    if [[ $# -eq 1 ]]; then
        local app_name=$1
        npx -p @angular/cli@latest ng new "$app_name" --package-manager=pnpm --skip-install --skip-tests
    elif [[ $# -eq 2 ]]; then
        local version=$1
        local app_name=$2
        npx -p @angular/cli@$version ng new "$app_name" --package-manager=pnpm --skip-install --skip-tests
    else
        echo "Usage: ngnew [app-name] or ngnew [version] [app-name]"
    fi
}

# Ultra-fast zsh performance test
zsh-bench() {
    echo "🚀 Testing zsh startup performance..."
    local total=0
    for i in {1..3}; do
        local time_result=$(TIMEFORMAT='%3R'; { time zsh -lic exit; } 2>&1)
        echo "Run $i: ${time_result}s"
        total=$(echo "$total + $time_result" | bc 2>/dev/null || echo "$total")
    done
    local avg=$(echo "scale=3; $total / 3" | bc 2>/dev/null || echo "calc_error")
    echo "📊 Average: ${avg}s"
}
