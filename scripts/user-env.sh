#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

# change directory to home

# install vim
# check if vim is installed
if [ -d ~/.vim_runtime ]; then
    echo "Vim is already installed"
else
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
    echo set nu >> ~/.vim_runtime/my_configs.vim
fi

# bash 
if [ -d ~/.oh-my-bash ]; then
    echo "Oh My Bash is already installed"
else
    echo "Installing Oh My Bash..."  
    curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash
    if which eza; then
        echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.bashrc
        echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.bashrc    
    fi

    if which exa; then
        echo 'alias ls="exa -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.bashrc
        echo 'alias lt="exa -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.bashrc    
    fi    
fi

# zsh
if [ -d ~/.oh-my-zsh ]; then
    echo "Oh My Zsh is already installed"
else
    echo "Installing Oh My Zsh..."  
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
    sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' ~/.zshrc

    if which eza; then
        echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc
        echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc   
    fi

    if which exa; then
        echo 'alias ls="exa -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc
        echo 'alias lt="exa -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc   
    fi
    
    chsh -s /usr/bin/zsh 
fi