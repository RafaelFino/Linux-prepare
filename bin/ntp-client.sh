#!/bin/bash

sudo timedatectl set-timezone America/Sao_Paulo

sudo apt install ntp ntpdate -y

sudo systemctl restart ntp
sudo systemctl status ntp

