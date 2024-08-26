#!/bin/bash

# update and add keys
sudo apt update -y
sudo apt upgrade -y

# install packages
sudo apt install -y wget git zsh gpg vim unzip jq telnet curl htop btop python3-pip exa micro apt-transport-https sqlite3 docker.io docker-compose apparmor apparmor-utils
sudo apt autoclean -y
sudo apt autoremove -y

# add user to sudo-docker
sudo groupadd docker
sudo usermod -aG docker $USER
echo 'http_proxy=http://192.168.1.10:3128' | sudo tee -a /etc/default/docker
echo 'https_proxy=http://192.168.1.10:3128' | sudo tee -a /etc/default/docker

# install vim awesome
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo set nu >> ~/.vim_runtime/my_configs.vim

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' .zshrc

#e[x|z]a
echo 'alias ls="exa -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc
echo 'alias lt="exa -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc

#golang
echo 'Installing golang'
wget "https://go.dev/dl/$(curl https://go.dev/VERSION\?m=text | head -n 1).linux-$(dpkg --print-architecture).tar.gz" -O golang.tar.gz  
sudo tar -C /usr/local -xzf golang.tar.gz
rm golang.tar.gz
echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc

# get keys
echo "Get-keys"
curl -sS https://raw.githubusercontent.com/RafaelFino/Linux-prepare/main/vm/get-keys | sudo tee -a /usr/local/bin/get-keys
sudo chmod +x /usr/local/bin/get-keys
get-keys

echo 'Done! '
