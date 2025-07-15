#!/bin/bash

sudo apt update -y

#install zsh/vim fonts
git clone --depth=1 https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts
git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
./nerd-fonts/install.sh
rm -rf nerd-fonts

#install ms core fonts
sudo apt install -y ttf-mscorefonts-installer


# install vscode application on desktop
wget https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64 -O vscode.deb
sudo dpkg -i vscode.deb
rm vscode.deb

# Install terminal emulators
sudo apt install -y terminator tilix alacritty tmux kitty

# Install chorme browser
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Check installs
sudo apt install -y -f
sudo apt install -y --fix-broken
sudo apt install -y --fix-missing
