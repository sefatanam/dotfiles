eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# zsh already sources ~/.zshrc on its own right after .zprofile for every
# login+interactive shell — sourcing it here too made it run twice on every
# new terminal/tmux pane (double PATH prepends, plugins sourced twice, etc).
