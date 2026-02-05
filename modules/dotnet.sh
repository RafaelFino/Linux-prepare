#!/bin/bash

# .NET Installation Module
# Installs .NET SDK and runtime, configures PATH and environment variables for all users

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="dotnet"
readonly DOTNET_INSTALL_PATH="/usr/local/dotnet"

# Check if .NET is installed
is_installed() {
    command -v dotnet &>/dev/null
}

# Add Microsoft repository and GPG key
add_microsoft_repository() {
    log_info "$MODULE_NAME" "Adding Microsoft package repository..."
    
    # Get Ubuntu version
    local ubuntu_version
    ubuntu_version=$(lsb_release -rs)
    
    # Add Microsoft GPG key
    if ! curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg 2>/dev/null; then
        log_warn "$MODULE_NAME" "Failed to add Microsoft GPG key, attempting alternative method"
        # Try alternative method
        if ! wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg 2>/dev/null; then
            log_error "$MODULE_NAME" "Failed to add Microsoft GPG key"
            return 1
        fi
    fi
    
    # Add Microsoft repository
    local repo_file="/etc/apt/sources.list.d/microsoft-prod.list"
    
    if [[ ! -f "$repo_file" ]]; then
        echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/ubuntu/$ubuntu_version/prod jammy main" | tee "$repo_file" > /dev/null
        
        log_debug "$MODULE_NAME" "Microsoft repository added"
    else
        log_debug "$MODULE_NAME" "Microsoft repository already configured"
    fi
    
    return 0
}

# Update package lists
update_package_lists() {
    log_info "$MODULE_NAME" "Updating package lists..."
    
    if ! apt-get update -qq 2>/dev/null; then
        log_warn "$MODULE_NAME" "Failed to update package lists, continuing anyway"
        return 0
    fi
    
    return 0
}

# Install .NET SDK and runtime
install_dotnet() {
    log_info "$MODULE_NAME" "Installing .NET SDK and runtime..."
    
    # Add repository first
    if ! add_microsoft_repository; then
        log_error "$MODULE_NAME" "Failed to add Microsoft repository"
        return 1
    fi
    
    # Update package lists
    if ! update_package_lists; then
        log_warn "$MODULE_NAME" "Package list update failed, attempting installation anyway"
    fi
    
    # Install dotnet-sdk (includes runtime)
    if ! apt-get install -y dotnet-sdk-8.0 2>/dev/null; then
        log_warn "$MODULE_NAME" "Failed to install dotnet-sdk-8.0, trying dotnet-sdk"
        
        if ! apt-get install -y dotnet-sdk 2>/dev/null; then
            log_error "$MODULE_NAME" "Failed to install .NET SDK"
            return 1
        fi
    fi
    
    log_debug "$MODULE_NAME" ".NET SDK installed successfully"
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Configure .NET PATH for a user
configure_dotnet_path_for_user() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    local profile_file="$user_home/.profile"
    
    # Create .profile if it doesn't exist
    if [[ ! -f "$profile_file" ]]; then
        sudo -u "$username" touch "$profile_file"
    fi
    
    # Add .NET PATH configuration if not already present
    if ! grep -q "dotnet" "$profile_file" 2>/dev/null; then
        sudo -u "$username" bash -c "echo '' >> '$profile_file'"
        sudo -u "$username" bash -c "echo '# .NET configuration' >> '$profile_file'"
        sudo -u "$username" bash -c "echo 'export PATH=\$PATH:/usr/bin/dotnet' >> '$profile_file'"
        sudo -u "$username" bash -c "echo 'export DOTNET_ROOT=/usr/lib/dotnet' >> '$profile_file'"
        log_debug "$MODULE_NAME" "Added .NET PATH configuration to .profile for $username"
    else
        log_debug "$MODULE_NAME" ".NET PATH already configured for $username"
    fi
    
    return 0
}

# Configure .NET for all users
configure_dotnet_for_users() {
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_debug "$MODULE_NAME" "Configuring .NET for user: $user"
        configure_dotnet_path_for_user "$user"
    done
    
    return 0
}

# Verify .NET installation
verify_dotnet() {
    log_info "$MODULE_NAME" "Verifying .NET installation..."
    
    if ! command -v dotnet &>/dev/null; then
        log_error "$MODULE_NAME" ".NET verification failed"
        return 1
    fi
    
    local dotnet_version
    dotnet_version=$(dotnet --version)
    log_debug "$MODULE_NAME" ".NET version: $dotnet_version"
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" ".NET is already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        if install_dotnet; then
            if verify_dotnet; then
                end_timer "$MODULE_NAME"
            else
                log_error "$MODULE_NAME" ".NET verification failed after installation"
                return 1
            fi
        else
            log_error "$MODULE_NAME" ".NET installation failed"
            return 1
        fi
    fi
    
    # Configure .NET for all users
    log_info "$MODULE_NAME" "Configuring .NET for all users..."
    configure_dotnet_for_users
    
    log_info "$MODULE_NAME" ".NET installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
