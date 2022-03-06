#!/bin/bash

sudo bash -c 'cat hosts >> /etc/hosts'

cd

#update
sudo apt install -y git vim zsh wget unzip jq telnet curl htop lm-sensors python3 python3-pip cifs-utils

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

#install micro
curl https://getmic.ro | bash
sudo mv micro /usr/bin

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' .zshrc
echo 'alias ls="ls -lha --color"' >> ~/.zshrc
echo set nu >> ~/.vim_runtime/my_configs.vim
echo zsh >> ~/.bashrc

echo 'Done!'
