#!/bin/bash

#update
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git vim zsh wget unzip jq telnet curl htop terminator tmux docker docker-compose python3 python3-pip exa
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

#Oh-my-tmux
git clone --depth=1 https://github.com/gpakosz/.tmux.git ~/.tmux

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
echo 'alias ls="exa -hHBmgaFl"' >> ~/.zshrc
echo 'alias t="tmux"' >> ~/.zshrc
echo 'alias ta="t a -t"' >> ~/.zshrc
echo 'alias tls="t ls"' >> ~/.zshrc
echo 'alias tn="t new -t"' >> ~/.zshrc

echo set nu >> ~/.vim_runtime/my_configs.vim

echo 'Done!'
