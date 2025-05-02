#!/bin/bash

# change directory to home
cd ~

# install env
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo set nu >> ~/.vim_runtime/my_configs.vim

# bash 
if [ -d ~/.oh-my-bash ]; then
    echo "Oh My Bash is already installed"
else
    echo "Installing Oh My Bash..."  
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.bashrc
    echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.bashrc
    echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi

# zsh
if [ -d ~/.oh-my-zsh ]; then
    echo "Oh My Zsh is already installed"
else
    echo "Installing Oh My Zsh..."  
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' ~/.zshrc
    echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc
    echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc
    echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
fi

cd -