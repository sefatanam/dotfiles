# exports.zsh - Environment variables and PATH modifications

export LANG=en_US.UTF-8

# Homebrew
export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"

# Go configuration
export GOROOT=$(ls -d /opt/homebrew/Cellar/go/*/libexec | tail -n 1)
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PNPM
export PNPM_HOME="/Users/sefat/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# NVM setup
export NVM_DIR=~/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [[ $- == *i* ]]; then
  nvm use default > /dev/null
fi

# Bit
case ":$PATH:" in
  *":/Users/sefat/bin:"*) ;;
  *) export PATH="$PATH:/Users/sefat/bin" ;;
esac

# OpenCode
export PATH=/Users/sefat/.opencode/bin:$PATH
export EDITOR="nvim"