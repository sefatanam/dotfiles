# functions.zsh - Custom shell functions

# Enhanced directory navigation with fzf
cd_to_dir() {
    local selected_dir
    selected_dir=$(fd -t d . "$1" | fzf +m --height 50% --preview 'tree -C {}')
    if [[ -n "$selected_dir" ]]; then
        cd "$selected_dir" || return 1
    fi
}

_directory_suggestion_widget() {
    local selected_dir
    
    # Get directories in current location
    selected_dir=$(fd -t d . . 2>/dev/null | fzf \
        --height 40% \
        --layout=reverse \
        --border \
        --prompt="📁 Select directory: " \
        --preview 'ls -la {}' \
        --preview-window=right:50%:wrap \
        +m)
    
    if [[ -n "$selected_dir" ]]; then
        # Insert the selected directory at cursor position
        LBUFFER="${LBUFFER}${selected_dir}"
    fi
    
    # Refresh the prompt
    zle redisplay
}

zle -N _directory_suggestion_widget

# Yazi file manager integration
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Video optimization with ffmpeg
optimize() {
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

# Angular project creation
function ngnew() {
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
