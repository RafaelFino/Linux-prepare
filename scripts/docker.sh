#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'



sudo apt install -y docker.io docker-compose-v2

if ! getent group docker > /dev/null; then
    # Create docker group
    sudo groupadd docker
fi
