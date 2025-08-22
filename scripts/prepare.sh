#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

# check if script run to show help only
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -base           Install base packages"
    echo "  -docker         Install docker"
    echo "  -u=<user>       Install user env for user plus root"
    echo "  -go             Install golang"
    echo "  -jvm            Install jvm"
    echo "  -dotnet         Install dotnet"
    echo "  -code-server    Install code-server"
    echo "  -desktop        Install desktop applications"
    echo "  -h, --help      Show this help message"
    exit 0
fi

args=("$@")

# Check arg -base for base packages
if [[ " ${args[@]} " =~ " -base " ]]; then
    sudo -H -u root bash ./base.sh
fi

# Check arg -docker for docker
if [[ " ${args[@]} " =~ " -docker " ]]; then
    # check if docker is installed
    if command -v docker &> /dev/null; then
        echo "Docker is already installed"
    else
        echo "Installing docker..."
        sudo -H -u root bash ./docker.sh
    fi
fi

echo "Installing user env for root..."
sudo -H -u root bash ./user-env.sh root

# Check arg -u for user env
if [[ " ${args[@]} " =~ " -u=" ]]; then
    # Get the index of -u
    index=$(echo "${args[@]}" | grep -oP '(?<=-u=)[^ ]*')
    # Get the user name
    user=${index#*=}

    # Check if user is empty
    if [ -z "$user" ]; then
        echo "User name is empty, getting user from environment variable USER"
        user=${USER:-$(whoami)}
    fi

    # Check if user exists
    if ! id "$user" &>/dev/null; then
        echo "User $user does not exist. Creating user..."
        sudo adduser --gecos "" $user
        # Add user to sudo group
        sudo usermod -aG sudo $user
        # Check if docker group exists
        if ! getent group docker > /dev/null; then
            # Create docker group
            sudo groupadd docker
            # Add user to docker group        
            sudo usermod -aG docker $user    
        fi                        
    fi 

    cp ./user-env.sh /home/$user/
    cd /home/$user
    sudo -H -u $user bash /home/$user/user-env.sh $user
    rm /home/$user/user-env.sh

    cd -

    # Check args -desktop for desktop
    if [[ " ${args[@]} " =~ " -desktop " ]]; then
        echo "Installing desktop applications..."
        sudo -H -u $user bash ./desktop.sh
    fi
fi

# Check arg -go for golang
if [[ " ${args[@]} " =~ " -go " ]]; then
    # check if golang is installed
    if command -v go &> /dev/null; then
        echo "Golang is already installed"
    else
        echo "Installing golang..."
        sudo -H -u root ./golang.sh
    fi
fi

# Check arg -jvm for jvm
if [[ " ${args[@]} " =~ " -jvm " ]]; then
    # check if jvm is installed
    if command -v sdk &> /dev/null; then
        echo "JVM is already installed"
    else
        echo "Installing jvm..."
        sudo -H -u root ./jvm.sh
    fi
fi

# Check arg -dotnet for dotnet
if [[ " ${args[@]} " =~ " -dotnet " ]]; then
    # check if dotnet is installed
    if command -v dotnet &> /dev/null; then
        echo "Dotnet is already installed"
    else
        echo "Installing dotnet..."
        sudo -H -u root ./dotnet.sh
    fi    
fi

# Check arg -code-server for code-server
if [[ " ${args[@]} " =~ " -code-server " ]]; then
    # check if code-server is installed
    if command -v code-server &> /dev/null; then
        echo "Code-server is already installed"
    else
        echo "Installing code-server..."
        sudo -H -u root ./code-server.sh
    fi
fi