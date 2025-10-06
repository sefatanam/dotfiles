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


# Video to GIF conversion
vid2gif() {
    if [ $# -eq 0 ]; then
        echo "Usage: vid2gif <video_path> [fps] [scale]"
        echo "Example: vid2gif video.mp4 30"
        echo "         vid2gif video.mp4 30 original  # Force original resolution"
        echo "         vid2gif video.mp4 30 1080      # Scale to 1080p"
        return 1
    fi
    
    local input_video="$1"
    local fps="${2:-30}"  # Default to 30fps if not specified
    local scale_option="${3:-auto}"  # auto, original, or specific height (720, 1080, etc.)
    
    if [ ! -f "$input_video" ]; then
        echo "Error: Video file '$input_video' not found"
        return 1
    fi
    
    # Get video height to determine if scaling is needed
    local video_height=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 "$input_video")
    
    # Determine scale filter
    local scale_filter=""
    if [ "$scale_option" = "original" ]; then
        scale_filter=""
        echo "Using original resolution (${video_height}p)"
    elif [ "$scale_option" = "auto" ]; then
        if [ "$video_height" -gt 720 ]; then
            scale_filter="scale=-1:720:flags=lanczos,"
            echo "Scaling down to 720p (original: ${video_height}p)"
        else
            scale_filter=""
            echo "Using original resolution (${video_height}p)"
        fi
    else
        # Custom height specified
        scale_filter="scale=-1:${scale_option}:flags=lanczos,"
        echo "Scaling to ${scale_option}p (original: ${video_height}p)"
    fi
    
    # Get filename without extension and add .gif
    local output_gif="${input_video%.*}.gif"
    local palette_file="/tmp/palette_$(date +%s).png"
    
    echo "Converting '$input_video' to '$output_gif' at ${fps}fps..."
    
    # Generate palette
    ffmpeg -i "$input_video" -vf "${scale_filter}fps=${fps},palettegen" -y "$palette_file"
    
    # Create GIF with palette
    ffmpeg -i "$input_video" -i "$palette_file" -filter_complex "${scale_filter}fps=${fps}[x];[x][1:v]paletteuse" -y "$output_gif"
    
    # Clean up palette file
    rm -f "$palette_file"
    
    echo "GIF created: $output_gif"
}

# YouTube video downloader with yt-dlp
ytd() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "❌ yt-dlp not found. Install with: brew install yt-dlp"
        return 1
    fi

    if [ $# -eq 0 ]; then
        echo "🎥 YouTube Video Downloader"
        echo "Usage: ytd <youtube_url> [resolution] [output_dir]"
        echo ""
        echo "Supported resolutions:"
        echo "  720p   - 1280x720"
        echo "  1080p  - 1920x1080 (default fallback)"
        echo "  2k     - 2560x1440"
        echo "  4k     - 3840x2160 (default)"
        echo ""
        echo "Default download location: ~/Downloads/"
        echo ""
        echo "Examples:"
        echo "  ytd https://youtube.com/watch?v=..."
        echo "  ytd https://youtube.com/watch?v=... 1080p"
        echo "  ytd https://youtube.com/watch?v=... 720p ~/Videos/"
        return 1
    fi

    local url="$1"
    local resolution="${2:-4k}"  # Default to 4k
    local download_dir="${3:-$HOME/Downloads}"  # Default to ~/Downloads

    # Create download directory if it doesn't exist
    mkdir -p "$download_dir"

    # Map resolution to height for yt-dlp format selection
    local height
    case "$resolution" in
        "720p"|"720") height="720" ;;
        "1080p"|"1080") height="1080" ;;
        "2k"|"1440p"|"1440") height="1440" ;;
        "4k"|"2160p"|"2160") height="2160" ;;
        *)
            echo "❌ Unsupported resolution: $resolution"
            echo "Supported: 720p, 1080p, 2k, 4k"
            return 1
            ;;
    esac

    echo "🎥 Downloading YouTube video in ${resolution}..."
    echo "📁 Output directory: $download_dir"

    # Format selection with fallbacks
    # Try exact resolution first, then fall back to lower resolutions
    local format_selector=""
    case "$height" in
        "2160")  # 4k
            format_selector="bestvideo[height<=2160]+bestaudio/bestvideo[height<=1080]+bestaudio/bestvideo[height<=720]+bestaudio/best"
            ;;
        "1440")  # 2k
            format_selector="bestvideo[height<=1440]+bestaudio/bestvideo[height<=1080]+bestaudio/bestvideo[height<=720]+bestaudio/best"
            ;;
        "1080")  # 1080p
            format_selector="bestvideo[height<=1080]+bestaudio/bestvideo[height<=720]+bestaudio/best"
            ;;
        "720")   # 720p
            format_selector="bestvideo[height<=720]+bestaudio/best"
            ;;
    esac

    # Output filename template with quality info
    local output_template="$download_dir/[%(height)sp] %(title)s.%(ext)s"
    local expected_file="$download_dir/[*] *.mp4"

    # Download with yt-dlp
    yt-dlp \
        --format "$format_selector" \
        --output "$output_template" \
        --embed-chapters \
        --embed-metadata \
        --write-description \
        --write-info-json \
        --merge-output-format mp4 \
        "$url"

    if [ $? -eq 0 ]; then
        echo "✅ Download completed successfully!"
        # Find and show the actual downloaded file
        local downloaded_file=$(ls -t "$download_dir"/[*]*.mp4 2>/dev/null | head -1)
        if [ -n "$downloaded_file" ]; then
            echo "📁 File saved: $downloaded_file"
        else
            echo "📂 Files saved to: $download_dir"
        fi
    else
        echo "❌ Download failed. Please check the URL and try again."
        return 1
    fi
}

# YouTube audio-only downloader
_ytd_audio() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "❌ yt-dlp not found. Install with: brew install yt-dlp"
        return 1
    fi

    if [ $# -eq 0 ]; then
        echo "🎵 YouTube Audio Downloader"
        echo "Usage: ytd-audio <youtube_url> [output_dir]"
        echo "Downloads best quality audio (usually 128-320kbps)"
        echo "Default download location: ~/Downloads/"
        return 1
    fi

    local url="$1"
    local download_dir="${2:-$HOME/Downloads}"

    mkdir -p "$download_dir"

    echo "🎵 Downloading audio from YouTube..."
    echo "📁 Output directory: $download_dir"

    yt-dlp \
        --extract-audio \
        --audio-format mp3 \
        --audio-quality 0 \
        --output "$download_dir/%(title)s.%(ext)s" \
        --embed-metadata \
        "$url"

    if [ $? -eq 0 ]; then
        echo "✅ Audio download completed!"
        # Find and show the actual downloaded file
        local downloaded_file=$(ls -t "$download_dir"/*.mp3 2>/dev/null | head -1)
        if [ -n "$downloaded_file" ]; then
            echo "📁 File saved: $downloaded_file"
        else
            echo "📂 Files saved to: $download_dir"
        fi
    else
        echo "❌ Audio download failed."
        return 1
    fi
}

# YouTube playlist downloader
_ytd_playlist() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "❌ yt-dlp not found. Install with: brew install yt-dlp"
        return 1
    fi

    if [ $# -eq 0 ]; then
        echo "📋 YouTube Playlist Downloader"
        echo "Usage: ytd-playlist <playlist_url> [resolution] [output_dir]"
        echo "Resolution defaults to 1080p for playlists"
        echo "Default download location: ~/Downloads/Playlists/"
        return 1
    fi

    local url="$1"
    local resolution="${2:-1080p}"
    local base_dir="${3:-$HOME/Downloads}"
    local playlist_dir="$base_dir/Playlists"

    mkdir -p "$playlist_dir"

    echo "📋 Downloading playlist in ${resolution}..."
    echo "📁 Output directory: $playlist_dir"

    # Get playlist title for subdirectory
    local playlist_title=$(yt-dlp --get-title --playlist-items 1 "$url" 2>/dev/null | head -1)
    if [ -n "$playlist_title" ]; then
        playlist_dir="$playlist_dir/$(echo "$playlist_title" | tr '/' '_')"
        mkdir -p "$playlist_dir"
    fi

    local height
    case "$resolution" in
        "720p"|"720") height="720" ;;
        "1080p"|"1080") height="1080" ;;
        "2k"|"1440p"|"1440") height="1440" ;;
        "4k"|"2160p"|"2160") height="2160" ;;
        *)
            echo "❌ Unsupported resolution: $resolution"
            echo "Supported: 720p, 1080p, 2k, 4k"
            return 1
            ;;
    esac

    local format_selector="bestvideo[height<=${height}]+bestaudio/best"

    yt-dlp \
        --format "$format_selector" \
        --output "$playlist_dir/%(playlist_index)02d - %(title)s.%(ext)s" \
        --embed-chapters \
        --embed-metadata \
        --merge-output-format mp4 \
        "$url"

    if [ $? -eq 0 ]; then
        echo "✅ Playlist download completed!"
        echo "📂 Playlist saved to: $playlist_dir"
        local file_count=$(ls "$playlist_dir"/*.mp4 2>/dev/null | wc -l)
        echo "📁 Downloaded $file_count videos"
    else
        echo "❌ Playlist download failed."
        return 1
    fi
}

# Fast YouTube downloader (good quality, minimal processing)
_ytd_fast() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "❌ yt-dlp not found. Install with: brew install yt-dlp"
        return 1
    fi

    if [ $# -eq 0 ]; then
        echo "⚡ Fast YouTube Downloader"
        echo "Usage: ytd-fast <youtube_url> [output_dir]"
        echo "Downloads quickly with good quality (usually 720p-1080p)"
        echo "Default download location: ~/Downloads/"
        return 1
    fi

    local url="$1"
    local download_dir="${2:-$HOME/Downloads}"

    mkdir -p "$download_dir"

    echo "⚡ Fast downloading from YouTube..."
    echo "📁 Output directory: $download_dir"

    yt-dlp \
        --format "best[height<=1080]" \
        --output "$download_dir/[FAST] %(title)s.%(ext)s" \
        "$url"

    if [ $? -eq 0 ]; then
        echo "✅ Fast download completed!"
        # Find and show the actual downloaded file
        local downloaded_file=$(ls -t "$download_dir"/[FAST]*.* 2>/dev/null | head -1)
        if [ -n "$downloaded_file" ]; then
            echo "📁 File saved: $downloaded_file"
        else
            echo "📂 Files saved to: $download_dir"
        fi
    else
        echo "❌ Fast download failed."
        return 1
    fi
}

# Best quality YouTube downloader (no size limits)
_ytd_best() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "❌ yt-dlp not found. Install with: brew install yt-dlp"
        return 1
    fi

    if [ $# -eq 0 ]; then
        echo "🏆 Best Quality YouTube Downloader"
        echo "Usage: ytd-best <youtube_url> [output_dir]"
        echo "Downloads the absolute best quality available"
        echo "Default download location: ~/Downloads/"
        return 1
    fi

    local url="$1"
    local download_dir="${2:-$HOME/Downloads}"

    mkdir -p "$download_dir"

    echo "🏆 Downloading best quality from YouTube..."
    echo "📁 Output directory: $download_dir"

    yt-dlp \
        --format "bestvideo+bestaudio/best" \
        --output "$download_dir/[BEST] %(title)s.%(ext)s" \
        --embed-chapters \
        --embed-metadata \
        --write-description \
        --write-info-json \
        --write-thumbnail \
        --merge-output-format mkv \
        "$url"

    if [ $? -eq 0 ]; then
        echo "✅ Best quality download completed!"
        # Find and show the actual downloaded file
        local downloaded_file=$(ls -t "$download_dir"/[BEST]*.* 2>/dev/null | head -1)
        if [ -n "$downloaded_file" ]; then
            echo "📁 File saved: $downloaded_file"
        else
            echo "📂 Files saved to: $download_dir"
        fi
    else
        echo "❌ Best quality download failed."
        return 1
    fi
}
