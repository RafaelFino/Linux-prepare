#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

# check if sdkman is installed
if [ ! -d "$HOME/.sdkman" ]; then
    echo "Installing SDKMAN..."
    curl -s https://get.sdkman.io | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# jvm
sdk install java's