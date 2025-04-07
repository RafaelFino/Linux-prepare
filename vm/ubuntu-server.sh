#!/bin/bash

# update and add keys
sudo apt update -y
sudo apt upgrade -y

# install packages
sudo apt install -y wget git zsh gpg vim unzip jq telnet curl htop btop python3-pip eza micro apt-transport-https sqlite3 docker.io docker-compose docker-buildx-plugin docker-compose-plugin bat
sudo apt autoclean -y
sudo apt autoremove -y

# add user to sudo-docker
sudo groupadd docker
sudo usermod -aG docker $USER

# install vim awesome
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo set nu >> ~/.vim_runtime/my_configs.vim

# install oh-my-bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" && \
echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.bashrc && \
echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.bashrc && \
echo 'alias cat="batcat -p"' >> ~/.bashrc && \
echo 'alias bat="batcat"' >> ~/.bashrc

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc && \
echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc && \
echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc && \
echo 'alias cat="batcat -p"' >> ~/.zshrc && \
echo 'alias bat="batcat"' >> ~/.zshrc

#golang
echo 'Installing golang'
wget "https://go.dev/dl/$(curl https://go.dev/VERSION\?m=text | head -n 1).linux-$(dpkg --print-architecture).tar.gz" -O golang.tar.gz  
sudo tar -C /usr/local -xzf golang.tar.gz
rm golang.tar.gz
echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

echo 'Done! '
