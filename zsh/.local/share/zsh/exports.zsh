# exports.zsh - Environment variables and PATH modifications
# OpenJDK 21
# export JAVA_HOME="/opt/homebrew/opt/openjdk"
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

# export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
# export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# Flutter SDK PATH
export PATH="$HOME/.localdev/flutter/bin:$PATH"

# Android SDK / NDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/29.0.13846066"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

