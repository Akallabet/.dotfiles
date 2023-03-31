#!/usr/bin/env bash

# Create a backup of .config if exists
if [ -d ~/.config ]
then
	cp ~/.config ~/.config.bak
fi

# Install Homebrew if not exists
if ! command -v brew &> /dev/null
then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install stow if not exists
if ! command -v stow &> /dev/null
then
	brew install stow
fi

stow nvim
stow zsh

# Install oh-my-zsh
git submodule update --init

# Install nvim if not exists
if ! command -v nvim &> /dev/null
then
	brew install neovim
fi

# Install ripgrep if not exists
if ! command -v rg &> /dev/null
then
	brew install ripgrep
fi

brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Install nodenv if not exists
if ! command -v nodenv &> /dev/null
then
	brew install nodenv
fi
