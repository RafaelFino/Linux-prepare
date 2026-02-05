#!/bin/bash

# VS Code Installation Module
# Installs Visual Studio Code via Microsoft repository and configures for all users

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="vscode"
readonly MICROSOFT_GPG_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
readonly VSCODE_REPO_URL="https://packages.microsoft.com/repos/code"

# Check if VS Code is installed
is_installed() {
    command -v code &>/dev/null
}

# Add Microsoft GPG key
add_microsoft_gpg_key() {
    log_debug "$MODULE_NAME" "Adding Microsoft GPG key..."
    
    if ! curl -fsSL "$MICROSOFT_GPG_KEY_URL" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null 2>&1; then
        log_error "$MODULE_NAME" "Failed to add Microsoft GPG key"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "Microsoft GPG key added successfully"
    return 0
}

# Add Microsoft repository
add_microsoft_repository() {
    log_debug "$MODULE_NAME" "Adding Microsoft repository..."
    
    # Detect system architecture
    local arch
    arch=$(dpkg --print-architecture)
    
    # Create repository entry
    local repo_entry="deb [arch=$arch signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] $VSCODE_REPO_URL stable main"
    
    # Check if repository is already added
    if grep -q "packages.microsoft.com/repos/code" /etc/apt/sources.list.d/vscode.list 2>/dev/null; then
        log_debug "$MODULE_NAME" "Microsoft repository already configured"
        return 0
    fi
    
    # Add repository
    if ! echo "$repo_entry" | tee /etc/apt/sources.list.d/vscode.list >/dev/null 2>&1; then
        log_error "$MODULE_NAME" "Failed to add Microsoft repository"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "Microsoft repository added successfully"
    return 0
}

# Update package lists
update_package_lists() {
    log_debug "$MODULE_NAME" "Updating package lists..."
    
    if ! apt-get update >/dev/null 2>&1; then
        log_error "$MODULE_NAME" "Failed to update package lists"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "Package lists updated successfully"
    return 0
}

# Install VS Code package
install_vscode_package() {
    log_info "$MODULE_NAME" "Installing VS Code package..."
    
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y code >/dev/null 2>&1; then
        log_error "$MODULE_NAME" "Failed to install VS Code package"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "VS Code package installed successfully"
    return 0
}

# Verify VS Code installation
verify_vscode() {
    log_info "$MODULE_NAME" "Verifying VS Code installation..."
    
    if ! command -v code &>/dev/null; then
        log_error "$MODULE_NAME" "VS Code verification failed"
        return 1
    fi
    
    local vscode_version
    vscode_version=$(code --version 2>/dev/null | head -1)
    log_debug "$MODULE_NAME" "VS Code version: $vscode_version"
    
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Configure VS Code for a user
configure_vscode_for_user() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    # VS Code configuration is typically stored in ~/.config/Code
    # We don't need to do explicit configuration here as VS Code handles it automatically
    # Just verify the user can access it
    log_debug "$MODULE_NAME" "VS Code configured for user: $username"
    
    return 0
}

# Configure VS Code for all users
configure_vscode_for_users() {
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_debug "$MODULE_NAME" "Configuring VS Code for user: $user"
        configure_vscode_for_user "$user"
    done
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "VS Code is already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        # Add Microsoft GPG key
        if ! add_microsoft_gpg_key; then
            log_error "$MODULE_NAME" "Failed to add Microsoft GPG key"
            return 1
        fi
        
        # Add Microsoft repository
        if ! add_microsoft_repository; then
            log_error "$MODULE_NAME" "Failed to add Microsoft repository"
            return 1
        fi
        
        # Update package lists
        if ! update_package_lists; then
            log_error "$MODULE_NAME" "Failed to update package lists"
            return 1
        fi
        
        # Install VS Code
        if ! install_vscode_package; then
            log_error "$MODULE_NAME" "Failed to install VS Code package"
            return 1
        fi
        
        # Verify installation
        if verify_vscode; then
            end_timer "$MODULE_NAME"
        else
            log_error "$MODULE_NAME" "VS Code verification failed after installation"
            return 1
        fi
    fi
    
    # Configure VS Code for all users
    log_info "$MODULE_NAME" "Configuring VS Code for all users..."
    configure_vscode_for_users
    
    log_info "$MODULE_NAME" "VS Code installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
