#!/bin/bash

cd

#update
sudo apt install -y git vim zsh wget unzip jq telnet curl htop

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

#install micro
curl https://getmic.ro | bash
sudo mv micro /usr/bin

#install zsh/vim fonts
git clone https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

#install exa (new LS)
wget https://github.com/ogham/exa/releases/download/v0.10.0/exa-linux-x86_64-v0.10.0.zip
sudo unzip -o -j exa-linux-x86_64-v0.10.0.zip "bin/exa" -d /usr/bin
rm exa-linux-x86_64-v0.10.0.zip

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
echo 'alias ls="exa -hHBmgaFl --git"' >> ~/.zshrc
echo set nu >> ~/.vim_runtime/my_configs.vim
echo zsh >> ~/.bashrc

echo 'Done!'
