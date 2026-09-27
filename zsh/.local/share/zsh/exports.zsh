# exports.zsh - Environment variables and PATH modifications
# OpenJDK 21 (matches Brewfile; avoids JDK 24+ JEP 472 native-access warnings)
# export JAVA_HOME="/opt/homebrew/opt/openjdk"
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

# export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
# export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# Flutter SDK PATH
export PATH="$HOME/.localdev/flutter/bin:$PATH"

# Android SDK / NDK
# Homebrew's android-commandlinetools cask declares this the default SDK root.
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
# NDK version is pinned by Flutter (gradle_utils.dart); AGP derives it from
# ndkVersion + sdk.dir, so ANDROID_NDK_HOME is intentionally not exported.
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

