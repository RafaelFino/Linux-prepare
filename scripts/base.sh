#!/usr/bin/env bash

apt update -y
timedatectl set-timezone America/Sao_Paulo
apt install ntp ntpdate -y
systemctl restart ntp
systemctl status ntp
apt install -y wget git zsh gpg zip vim unzip jq telnet curl htop btop python3 python3-pip eza micro btop apt-transport-https gpg zlib1g sqlite3 fzf sudo
apt install -y 
apt autoclean -y
apt autoremove -y
   
echo "Base packages installed"




