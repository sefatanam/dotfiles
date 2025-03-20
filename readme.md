# Dotfiles Setup Guide

This guide provides instructions on setting up your development environment using my dotfiles repository.

## Configurations

This repository contains configuration files for the following tools:

1. **nvim (Neovim)** - A modern and highly customizable text editor for coding.
2. **aerospace** - Configuration for the Aerospace tool (or a custom tool).
3. **raycast** - Settings for Raycast, the productivity app for macOS.

## Prerequisite

Before you start, ensure that **Homebrew** is installed on your system. Homebrew is a package manager for macOS and Linux that allows you to easily install software and manage dependencies.

1. If you don’t have Homebrew installed, run the following command to install it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Clone the dotfiles repository to your machine:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
```

3. Navigate to the dotfiles directory and install the required applications via Homebrew by running the following command:

```bash
brew bundle --file=./Brewfile
```

This will install the apps listed in the `Brewfile` (such as Neovim, Raycast, and Aerospace, if applicable).

## How to Configure

After cloning the repository and installing the necessary software, you need to create symlinks for the configuration files. This step ensures that your system uses the dotfiles from the repository rather than the default configuration files. 

To create the symlinks, use the following commands:

```bash
# Link the .zshrc file for Zsh configuration
ln -s ~/.dotfiles/.zshrc ~/.zshrc

# Link the .zprofile file for Zsh profile settings
ln -s ~/.dotfiles/.zprofile ~/.zprofile

# Link the .tmux.conf file for tmux configuration
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf

# Link the .p10k.zsh file for Powerlevel10k prompt configuration
ln -s ~/.dotfiles/.p10k.zsh ~/.p10k.zsh

# Link the aerospace configuration folder
ln -s ~/.dotfiles/.config/aerospace ~/.config/aerospace

# Link the Neovim configuration folder
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
```

These symlinks ensure that your system uses the custom configuration files from this repository.
