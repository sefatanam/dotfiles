# aliases.zsh - All command aliases

alias c="clear"

# Directory navigation
alias cdd='cd_to_dir ~/Documents/'
alias cds='cd_to_dir'
alias cd="z"

# Enhanced ls
alias es='eza -alF --color=always --sort=size | grep -v /'
alias ls="eza --icons=always"

# Applications
alias n='nvim'
alias g='nvm use 24.4 && lazygit'

# Zsh management
alias reload-zsh="source ~/.zshrc"
alias edit-zsh="nvim ~/.zshrc"

# Git aliases
# alias gs='git status'
alias gp='git stash && git pull --rebase && git stash pop'
# alias gP='git push'
# alias gc='git commit -m'
# alias grh='git reset --hard'
# alias gts='git stash'
# alias gtp='git stash pop'
# alias gl='git log --oneline'
alias gcn='git config --local user.name "$GIT_NAME"'
alias gce='git config --local user.email "$GIT_EMAIL"'
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
alias nf="npm run format"
alias nl="npm run lint"
alias nlf="nl && nf"

# Utility aliases
alias cat="glow"

# GitHub aliases
alias gh-create='gh repo create --private --source=. --remote=origin && git push -u --all && gh browse'

# GitHub Copilot aliases
alias ghca="gh extension install github/gh-copilot"
alias ghcs="gh copilot suggest"
alias ghce="gh copilot explain"
alias ghcup="gh extension upgrade gh-copilot"

# Forticlient VPN connect
alias fvpn="sudo openfortivpn -c ~/.openfortivpn/config"

# Video conversion aliases
alias v2g='vid2gif'
alias ff='ffwd' # @REVIEW

# YouTube download aliases
alias ytd-audio='_ytd_audio'
alias ytd-playlist='_ytd_playlist'
alias ytd-fast='_ytd_fast'
alias ytd-best='_ytd_best'

# homebrew
# alias bru="brew upgrade --greedy"
alias bru="brew upgrade --greedy"
alias brc="brew cleanup --prune=all"

# MISC - Project Specific
alias rca="mvn spring-boot:run '-Dspring-boot.run.jvmArguments=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005'"
alias fabric='fabric-ai'
alias tovpn="sudo route add host 10.100.206.11 gateway ppp0 && sudo route add -host 10.100.207.8 -interface ppp0"

alias roa="npx ng serve --port 4200 --ssl true --ssl-key ssl/localhost-key.pem --ssl-cert ssl/localhost.pem"

# Office Add-in dev cert: (re)install office-addin-dev-certs and trust the CA root
# for SSL so Chrome stops throwing ERR_CERT_AUTHORITY_INVALID on localhost.
# Certs expire ~30 days; re-run when the add-in icons/pane fail to load.
office-cert-fix() {
  npx --yes office-addin-dev-certs install || return 1
  security add-trusted-cert -r trustRoot -p ssl -k "$HOME/Library/Keychains/login.keychain-db" "$HOME/.office-addin-dev-certs/ca.crt" && echo "Office CA trusted for SSL - fully quit Chrome (Cmd+Q) and reopen."
}
alias fix-office-cert='office-cert-fix'
