#!/bin/bash
cd

#update
sudo yum update -y
sudo yum install -y git vim zsh wget unzip jq telnet

#install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &

#install vim
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

#install zsh/vim fonts
git clone https://github.com/powerline/fonts.git
./fonts/install.sh

#install exa (new LS)
wget https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip
unzip exa-linux-x86_64-0.9.0.zip
sudo mv exa-linux-x86_64 /usr/local/bin/exa
rm exa-linux-x86_64-0.9.0.zip

sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
echo 'alias ls="exa -hHBmgaFl --git"' >> ~/.zshrc
echo set nu >> ~/.vim_runtime/my_configs.vim
sudo sed -i 's/ec2-user:\/bin\/bash/ec2-user:\/usr\/bin\/zsh/g' /etc/passwd
echo zsh >> ~/.bashrc

echo 'Done!'

exit
