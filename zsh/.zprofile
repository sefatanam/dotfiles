eval "$(/opt/homebrew/bin/brew shellenv)"

# zsh already sources ~/.zshrc on its own right after .zprofile for every
# login+interactive shell — sourcing it here too made it run twice on every
# new terminal/tmux pane (double PATH prepends, plugins sourced twice, etc).
