#!/bin/bash

# update and add keys
sudo apt update -y
sudo apt install wget git zsh gpg -y
sudo apt upgrade -y
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
rm -f packages.microsoft.gpg
sudo apt update -y
sudo apt upgrade -y

# install packages
sudo apt install -y vim unzip jq telnet curl htop terminator docker.io docker-compose python3 python3-pip kate mousepad eza micro btop apt-transport-https gpg zlib1g dotnet-sdk-8.0 dotnet-runtime-8.0 aspnetcore-runtime-8.0 sqlite3 code
sudo apt autoclean -y
sudo apt autoremove -y

# add user to sudo-docker
sudo groupadd docker
sudo usermod -aG docker $USER
# newgrp docker


# install vim awesome
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo set nu >> ~/.vim_runtime/my_configs.vim

#install zsh/vim fonts
git clone --depth=1 https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
./nerd-fonts/install.sh
rm -rf nerd-fonts

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc

#e[x|z]a
echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc
echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc

#golang
echo 'Installing golang'
wget "https://go.dev/dl/$(curl https://go.dev/VERSION\?m=text | head -n 1).linux-$(dpkg --print-architecture).tar.gz" -O golang.tar.gz  
sudo tar -C /usr/local -xzf golang.tar.gz
rm golang.tar.gz
echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc

# jvm
echo 'Install JVM'
curl -s "https://get.sdkman.io" | bash
sdk install java
zsh -c 'source ~/.zshrc; sdk install java'

echo 'Done! '