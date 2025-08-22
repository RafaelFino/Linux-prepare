#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

# GO
wget "https://go.dev/dl/$(curl https://go.dev/VERSION\?m=text | head -n 1).linux-$(dpkg --print-architecture).tar.gz" -O golang.tar.gz
sudo tar -C /usr/local -xzf golang.tar.gz
rm golang.tar.gz

#check if go path is in /etc/environment
if ! grep -q "PATH" /etc/environment; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/environment
fi
