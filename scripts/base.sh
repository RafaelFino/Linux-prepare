#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'



echo "Timezone set to America/Sao_Paulo"
echo "America/Sao_Paulo" | sudo tee /etc/timezone

echo "Installing base packages..."
apt update -y
apt install -y wget git zsh gpg zip vim unzip jq telnet curl htop btop python3 python3-pip eza micro btop apt-transport-https gpg zlib1g sqlite3 fzf sudo
apt install -y 
apt autoclean -y
apt autoremove -y
   
echo "Base packages installed"




