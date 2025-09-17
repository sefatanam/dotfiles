# aliases.zsh - All command aliases

# Directory navigation
alias cdd='cd_to_dir ~/Documents/'
alias cds='cd_to_dir'

# Enhanced ls
alias es='eza -alF --color=always --sort=size | grep -v /'

# Applications
alias n='nvim'
alias g='lazygit'

# Zsh management
alias reload-zsh="source ~/.zshrc"
alias edit-zsh="nvim ~/.zshrc"

# Git aliases
alias gs='git status'
alias gp='git pull --rebase'
alias gP='git push'
alias gc='git commit -m'
alias grh='git reset --hard'
alias gts='git stash'
alias gtp='git stash pop'
alias gl='git log --oneline'
alias gcn='git config --local user.name "$GIT_NAME"'
alias gce='git config --local user.email "$GIT_EMAIL"'
alias gcl='gce && gcn'
alias gcll='git config --local --list'
alias grp="git remote prune origin"

# Tmux aliases
alias t='tmux'
alias ta='tmux attach -t'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias ts='tmux switch -t'
alias td='tmux detach'

# NPM aliases
alias ns="npm start"
alias nd="npm run dev"

# Utility aliases
alias cat="glow"
alias c='clear'
alias e='exit'

# GitHub aliases
alias gh-create='gh repo create --private --source=. --remote=origin && git push -u --all && gh browse'

# GitHub Copilot aliases
alias ghca="gh extension install github/gh-copilot"
alias ghcs="gh copilot suggest"
alias ghce="gh copilot explain"
alias ghcup="gh extension upgrade gh-copilot"

# Forticlient VPN connect
alias fvpn="sudo openfortivpn -c ~/.openfortivpn/config"
