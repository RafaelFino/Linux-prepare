#!/bin/bash

sudo apt update -y

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

# Install brave browser
wget -qO - https://brave-browser-archive.s3.brave.com/brave-core.asc | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-archive.s3.brave.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null
sudo apt update
sudo apt install -y brave-browser
rm brave-browser.gpg

# Check installs
sudo apt install -y -f
sudo apt install -y --fix-broken
sudo apt install -y --fix-missing
