#!/bin/bash

# Golang Installation Module
# Installs Go programming language and configures PATH for all users

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="golang"
readonly GO_INSTALL_PATH="/usr/local/go"
readonly GO_VERSION_URL="https://go.dev/dl/?mode=json"

# Check if Go is installed
is_installed() {
    command -v go &>/dev/null
}

# Get the latest stable Go version
get_latest_go_version() {
    log_debug "$MODULE_NAME" "Fetching latest Go version..."
    
    local version_info
    version_info=$(curl -fsSL "$GO_VERSION_URL" 2>/dev/null | head -1 | grep -oP '"version":"go\K[^"]+' || echo "")
    
    if [[ -z "$version_info" ]]; then
        log_warn "$MODULE_NAME" "Could not fetch latest Go version, using fallback method"
        # Fallback: try to get from releases page
        version_info=$(curl -fsSL "https://api.github.com/repos/golang/go/releases/latest" 2>/dev/null | grep -oP '"tag_name":"go\K[^"]+' | head -1 || echo "")
    fi
    
    if [[ -z "$version_info" ]]; then
        log_error "$MODULE_NAME" "Failed to determine latest Go version"
        return 1
    fi
    
    echo "$version_info"
}

# Detect system architecture
get_system_arch() {
    local arch
    arch=$(uname -m)
    
    case "$arch" in
        x86_64)
            echo "amd64"
            ;;
        aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv6l"
            ;;
        *)
            log_error "$MODULE_NAME" "Unsupported architecture: $arch"
            return 1
            ;;
    esac
}

# Download and install Go
install_golang() {
    local go_version
    go_version=$(get_latest_go_version) || return 1
    
    local system_arch
    system_arch=$(get_system_arch) || return 1
    
    local download_url="https://go.dev/dl/go${go_version}.linux-${system_arch}.tar.gz"
    local temp_file="/tmp/go${go_version}.linux-${system_arch}.tar.gz"
    
    log_info "$MODULE_NAME" "Downloading Go $go_version for $system_arch..."
    
    if ! curl -fsSL "$download_url" -o "$temp_file"; then
        log_error "$MODULE_NAME" "Failed to download Go from $download_url"
        rm -f "$temp_file"
        return 1
    fi
    
    log_info "$MODULE_NAME" "Extracting Go to $GO_INSTALL_PATH..."
    
    # Remove existing Go installation if present
    if [[ -d "$GO_INSTALL_PATH" ]]; then
        log_debug "$MODULE_NAME" "Removing existing Go installation"
        rm -rf "$GO_INSTALL_PATH"
    fi
    
    # Extract to /usr/local
    if ! tar -C /usr/local -xzf "$temp_file"; then
        log_error "$MODULE_NAME" "Failed to extract Go archive"
        rm -f "$temp_file"
        return 1
    fi
    
    rm -f "$temp_file"
    
    log_debug "$MODULE_NAME" "Go extracted successfully"
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Configure Go PATH for a user
configure_go_path_for_user() {
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
    
    # Add Go PATH configuration if not already present
    if ! grep -q "export PATH.*go/bin" "$profile_file" 2>/dev/null; then
        sudo -u "$username" bash -c "echo '' >> '$profile_file'"
        sudo -u "$username" bash -c "echo '# Go language configuration' >> '$profile_file'"
        sudo -u "$username" bash -c "echo 'export PATH=\$PATH:/usr/local/go/bin' >> '$profile_file'"
        log_debug "$MODULE_NAME" "Added Go PATH configuration to .profile for $username"
    else
        log_debug "$MODULE_NAME" "Go PATH already configured for $username"
    fi
    
    return 0
}

# Configure Go for all users
configure_golang_for_users() {
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_debug "$MODULE_NAME" "Configuring Go PATH for user: $user"
        configure_go_path_for_user "$user"
    done
    
    return 0
}

# Verify Go installation
verify_golang() {
    log_info "$MODULE_NAME" "Verifying Go installation..."
    
    if ! "$GO_INSTALL_PATH/bin/go" version &>/dev/null; then
        log_error "$MODULE_NAME" "Go verification failed"
        return 1
    fi
    
    local go_version
    go_version=$("$GO_INSTALL_PATH/bin/go" version)
    log_debug "$MODULE_NAME" "Go version: $go_version"
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "Go is already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        if install_golang; then
            if verify_golang; then
                end_timer "$MODULE_NAME"
            else
                log_error "$MODULE_NAME" "Go verification failed after installation"
                return 1
            fi
        else
            log_error "$MODULE_NAME" "Go installation failed"
            return 1
        fi
    fi
    
    # Configure Go PATH for all users
    log_info "$MODULE_NAME" "Configuring Go for all users..."
    configure_golang_for_users
    
    log_info "$MODULE_NAME" "Go installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
