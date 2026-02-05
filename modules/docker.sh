#!/bin/bash

# Docker Installation Module
# Installs Docker and configures user permissions for non-root access

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="docker"

# Check if Docker is installed
is_installed() {
    command -v docker &>/dev/null
}

# Install Docker using official installation script
install_docker() {
    log_info "$MODULE_NAME" "Downloading official Docker installation script..."
    
    if ! curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; then
        log_error "$MODULE_NAME" "Failed to download Docker installation script"
        return 1
    fi
    
    log_info "$MODULE_NAME" "Running Docker installation script..."
    
    if ! bash /tmp/get-docker.sh; then
        log_error "$MODULE_NAME" "Docker installation script failed"
        rm -f /tmp/get-docker.sh
        return 1
    fi
    
    rm -f /tmp/get-docker.sh
    
    # Verify installation
    if ! command -v docker &>/dev/null; then
        log_error "$MODULE_NAME" "Docker installation verification failed"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "Docker installed successfully"
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Add user to docker group for non-root access
add_user_to_docker_group() {
    local username="$1"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_warn "$MODULE_NAME" "User $username does not exist, skipping docker group configuration"
        return 1
    fi
    
    # Check if user is already in docker group
    if id -nG "$username" | grep -qw docker; then
        log_debug "$MODULE_NAME" "User $username is already in docker group"
        return 0
    fi
    
    # Add user to docker group
    if usermod -aG docker "$username"; then
        log_debug "$MODULE_NAME" "Added user $username to docker group"
        return 0
    else
        log_error "$MODULE_NAME" "Failed to add user $username to docker group"
        return 1
    fi
}

# Configure Docker for all users
configure_docker_for_users() {
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_debug "$MODULE_NAME" "Configuring Docker for user: $user"
        add_user_to_docker_group "$user"
    done
    
    return 0
}

# Verify Docker installation
verify_docker() {
    log_info "$MODULE_NAME" "Verifying Docker installation..."
    
    if ! docker --version &>/dev/null; then
        log_error "$MODULE_NAME" "Docker verification failed"
        return 1
    fi
    
    local docker_version
    docker_version=$(docker --version)
    log_debug "$MODULE_NAME" "Docker version: $docker_version"
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "Docker is already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        if install_docker; then
            if verify_docker; then
                end_timer "$MODULE_NAME"
            else
                log_error "$MODULE_NAME" "Docker verification failed after installation"
                return 1
            fi
        else
            log_error "$MODULE_NAME" "Docker installation failed"
            return 1
        fi
    fi
    
    # Configure Docker for all users
    log_info "$MODULE_NAME" "Configuring Docker for all users..."
    configure_docker_for_users
    
    log_info "$MODULE_NAME" "Docker installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
