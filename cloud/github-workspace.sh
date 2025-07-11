#!/bin/bash

#update
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update -y
sudo apt install -y git vim zsh wget unzip jq telnet htop python3 python3-pip eza  micro gpg eza

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo set nu >> ~/.vim_runtime/my_configs.vim

#install oh-my-zsh
if [ -d ~/.oh-my-zshex ]; then
    rm -rf ~/.oh-my-zsh
    rm ~/.zshrc
fi

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' .zshrc
echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.zshrc

#install oh-my-bash
if [ -d ~/.oh-my-bash ]; then
    rm -rf ~/.oh-my-bash
    rm ~/.bashrc
fi
curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash
echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' >> ~/.bashrc
echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' >> ~/.bashrc    

echo 'Done!'