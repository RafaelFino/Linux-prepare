#!/bin/bash

#update
sudo apt update -y
sudo apt install -y git vim zsh wget unzip jq telnet curl htop terminator tmux docker docker-compose python3 python3-pip
sudo apt autoclean -y
sudo apt autoremove -y

#add user to sudo-docker
sudo usermod -aG docker $USER

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

#install micro
curl https://getmic.ro | bash
sudo mv micro /usr/bin

#install zsh/vim fonts
git clone --depth=1 https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
./nerd-fonts/install.sh
rm -rf nerd-fonts

#install exa (new LS)
wget https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip
sudo unzip -o -j exa-linux-x86_64-v0.10.1.zip "bin/exa" -d /usr/bin
rm exa-linux-x86_64-v0.10.1.zip

#Install oh-my-tmux
git clone --depth=1 https://github.com/gpakosz/.tmux.git ~/.tmux
cp .tmux.conf.local ~/.tmux
cp start-tmux.sh ~/

#config fstab
sudo echo '#Fogo na Pamonha Router Share' >> /etc/fstab
sudo echo '//c7-router/sda1        /media/c7-router        cifs    rw,relatime,vers=1.0,sec=none,file_mode=0777,dir_mode=0777      0       0' >> /etc/fstab

sudo echo 'Rasp 3 SMB Share - Open Media Vault' >> /etc/fstab
sudo echo '//rasp3/share-a /media/rasp3-share-a cifs    guest,rw,relatime,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm 0   0'
sudo echo '//rasp3/share-b /media/rasp3-share-b cifs    guest,rw,relatime,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm 0   0'

sudo echo 'Rasp4 SMB Share' >> /etc/fstab
sudo echo '//rasp4/share /media/rasp4-share cifs    guest,rw,relatime,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm  0   0'

sudo mkdir /media/rasp4-share /media/rasp3-share-a /media/rasp3-share-b
sudo chown nobody:nogroup /media/rasp4-share /media/rasp3-share-a /media/rasp3-share-b
sudo chmod 0775 /media/rasp4-share /media/rasp3-share-a /media/rasp3-share-b
sudo mount -a

#include itens to hosts
sudo cat hosts /etc/hosts | sort -urf > /etc/hosts

#change dir to HOME
cd

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
echo 'alias ls="exa -hHBmgaFl --git"' >> ~/.zshrc
echo 'alias t="tmux"' >> ~/.zshrc
echo 'alias ta="t a -t"' >> ~/.zshrc
echo 'alias tls="t ls"' >> ~/.zshrc
echo 'alias tn="t new -t"' >> ~/.zshrc

echo set nu >> ~/.vim_runtime/my_configs.vim
echo zsh >> ~/.bashrc

#copy terminator config
mv terminator-config .config/terminator/config

echo 'Done!'
