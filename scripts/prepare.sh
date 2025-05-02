#!/bin/bash

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

# Check if the script is being run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check arg -base for base packages
if [[ " ${args[@]} " =~ " -base " ]]; then
    bash ./base.sh
fi

# Check arg -docker for docker
if [[ " ${args[@]} " =~ " -docker " ]]; then
    # check if docker is installed
    if command -v docker &> /dev/null; then
        echo "Docker is already installed"
    else
        echo "Installing docker..."
        bash ./docker.sh
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
        echo "User name is empty"
        exit 1
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
    sudo -H -u $user bash ./user-env.sh $user
    rm /home/$user/user-env.sh
    cd -
fi

# Check arg -go for golang
if [[ " ${args[@]} " =~ " -go " ]]; then
    # check if golang is installed
    if command -v go &> /dev/null; then
        echo "Golang is already installed"
    else
        echo "Installing golang..."
        bash ./golang.sh
    fi
fi

# Check arg -jvm for jvm
if [[ " ${args[@]} " =~ " -jvm " ]]; then
    # check if jvm is installed
    if command -v sdk &> /dev/null; then
        echo "JVM is already installed"
    else
        echo "Installing jvm..."
        bash ./jvm.sh
    fi
fi

# Check arg -dotnet for dotnet
if [[ " ${args[@]} " =~ " -dotnet " ]]; then
    # check if dotnet is installed
    if command -v dotnet &> /dev/null; then
        echo "Dotnet is already installed"
    else
        echo "Installing dotnet..."
        bash ./dotnet.sh
    fi    
fi

# Check arg -code-server for code-server
if [[ " ${args[@]} " =~ " -code-server " ]]; then
    # check if code-server is installed
    if command -v code-server &> /dev/null; then
        echo "Code-server is already installed"
    else
        echo "Installing code-server..."
        bash ./code-server.sh
    fi
fi

# Check args -desktop for desktop
if [[ " ${args[@]} " =~ " -desktop " ]]; then
    echo "Installing desktop..."
    bash ./desktop.sh
fi