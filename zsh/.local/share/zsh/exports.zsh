# exports.zsh - Environment variables and PATH modifications

# Cache PATH modifications for ultra-fast startup
# if [[ ! -f "$HOME/.cache/zsh-path.cache" ]] || [[ "$HOME/.cache/zsh-path.cache" -ot "$0" ]]; then
#     mkdir -p "$HOME/.cache"
#     {
#         echo "#Cached PATH configuration"
#         echo "export DYLD_LIBRARY_PATH=\"/opt/homebrew/lib:\$DYLD_LIBRARY_PATH\""
#         echo "export GOROOT=\"/opt/homebrew/opt/go/libexec\""
#         echo "export GOPATH=\$HOME/go"
#         echo "export BUN_INSTALL=\"\$HOME/.bun\""
#         echo "export PNPM_HOME=\"\$HOME/Library/pnpm\""
#         echo "export EDITOR=\"nvim\""
#
#         # Build optimized PATH
#         local NEW_PATH="/opt/homebrew/opt/go/libexec/bin:\$HOME/go/bin:\$HOME/.bun/bin:\$HOME/.volta/bin:\$HOME/Library/pnpm:\$HOME/bin:\$HOME/.opencode/bin:\$PATH"
#         echo "export PATH=\"$NEW_PATH\""
#     } > "$HOME/.cache/zsh-path.cache"
# fi
# source "$HOME/.cache/zsh-path.cache"

# OpenJDK 21
# export JAVA_HOME="/opt/homebrew/opt/openjdk"
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

# export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
# export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"
#

# Flutter SDK PATH
export PATH="$HOME/.localdev/flutter/bin:$PATH"

# Android SDK / NDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/29.0.13846066"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

