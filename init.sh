#!/usr/bin/env bash

# Create a backup of .config if it already exists
if [ -d ~/.config ]
then
	cp ~/.config ~/.config.bak
fi

# Install Homebrew if not exists
if ! command -v brew &> /dev/null
then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# Install stow if it doesn't exist
if ! command -v stow &> /dev/null
then
	brew install stow
fi

cd ~/.dotfiles
stow nvim
stow zsh

# Install oh-my-zsh
git submodule update --init

# Install nvim if it doesn't exist
if ! command -v nvim &> /dev/null
then
	brew install neovim
fi

# Install ripgrep if it doesn't exist
if ! command -v rg &> /dev/null
then
	brew install ripgrep
fi

# Install nodenv if it doesn't exist
if ! command -v nodenv &> /dev/null
then
	brew install nodenv
fi
