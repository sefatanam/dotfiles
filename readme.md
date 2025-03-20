# Dotfiles

## Configurations
1. nvim
2. aerospace

## Prerequisite

1. To install apps via `brew` (https://brew.sh/)[install] homebrew and navigate to the `dotfiles` repo and run :
```shell
brew bundle --file=./Brewfile
```
## How to configure
Have to symlink first after clone this repo. With the following shell command,

```shell
ln -s ~/.dotfiles/.zshrc ~/.zshrc
ln -s ~/.dotfiles/.zprofile ~/.zprofile
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
ln -s ~/.dotfiles/.config/aerospace ~/.config/aerospace
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
```


