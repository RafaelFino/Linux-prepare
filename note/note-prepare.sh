#!/bin/bash

#update
sudo apt update -y
sudo apt install -y git vim zsh wget unzip jq telnet curl htop terminator docker.io docker-compose python3 python3-pip kate mousepad exa micro btop batcat apt-transport-https gpg
sudo apt autoclean -y
sudo apt autoremove -y

#add user to sudo-docker
sudo usermod -aG docker $USER

#install vscode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt update -y
sudo apt install code

#change dir to HOME
cd

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

#install zsh/vim fonts
git clone --depth=1 https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
./nerd-fonts/install.sh
rm -rf nerd-fonts

#Install oh-my-tmux
git clone --depth=1 https://github.com/gpakosz/.tmux.git ~/.tmux
cp .tmux.conf.local ~/.tmux
cp start-tmux.sh ~/

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc

echo 'alias ls="eza -hHbmgaFlT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc
echo 'alias lt="eza -hHbmgaFlT -L 4 --time-style=long-iso --icons"' >> ~/.zshrc

echo set nu >> ~/.vim_runtime/my_configs.vim

echo 'Done!'
