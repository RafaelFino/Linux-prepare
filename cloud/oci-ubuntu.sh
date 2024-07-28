#!/bin/bash

# To prepare a single instance
#
#update
sudo apt update -y
sudo apt install -y git vim zsh wget unzip jq telnet htop python3 python3-pip micro docker docker-compose

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

#install exa
EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
sudo unzip -qo exa.zip bin/exa -d /usr/local
rm exa.zip

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' .zshrc
echo 'alias ls="exa -hHbmgaFl"' >> ~/.zshrc
echo set nu >> ~/.vim_runtime/my_configs.vim

#open server ports to web
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -F
sudo iptables --flush

sudo chsh -s /bin/zsh

echo 'Done!'
