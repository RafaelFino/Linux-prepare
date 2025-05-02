#!/bin/bash

# code-server
wget -qO- https://code-server.dev/install.sh | sh  

mkdir ~/.config
mkdir ~/.config/code-server
echo 'bind-addr: 0.0.0.0:8080' >>  ~/.config/code-server/config.yaml
echo 'auth: password' >>  ~/.config/code-server/config.yaml
echo 'password: p@ssw0rd' >>  ~/.config/code-server/config.yaml