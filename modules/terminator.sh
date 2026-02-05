#!/bin/bash

# Terminator Installation Module
# Installs Terminator terminal emulator and provides basic configuration

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="terminator"

# Check if Terminator is installed
is_installed() {
    command -v terminator &>/dev/null
}

# Install Terminator via apt
install_terminator() {
    log_info "$MODULE_NAME" "Installing Terminator via apt..."
    
    if ! apt-get install -y terminator; then
        log_error "$MODULE_NAME" "Failed to install Terminator"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "Terminator installed successfully"
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Create basic Terminator configuration for a user
configure_terminator_for_user() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    local config_dir="$user_home/.config/terminator"
    local config_file="$config_dir/config"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$config_dir" ]]; then
        sudo -u "$username" mkdir -p "$config_dir"
        log_debug "$MODULE_NAME" "Created Terminator config directory for $username"
    fi
    
    # Create basic configuration if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        sudo -u "$username" bash -c "cat > '$config_file' << 'EOF'
[global_config]
  title_transmit_fg_color = "#000000"
  title_transmit_bg_color = "#fce94f"
  title_use_system_font = False
  title_font = mononoki Nerd Font 16
[keybindings]
[profiles]
  [[default]]
    background_darkness = 0.8
    background_type = transparent
    cursor_color = "#aaaaaa"
    font = Cousine for Powerline 16
    use_custom_command = False
    use_system_font = False
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
      size = 2000, 1600
      position = 300:300
    [[[child1]]]
      type = Terminal
      parent = window0
[plugins]
EOF"
        log_debug "$MODULE_NAME" "Created Terminator configuration for $username"
    else
        log_debug "$MODULE_NAME" "Terminator configuration already exists for $username"
    fi
    
    return 0
}

# Configure Terminator for all users
configure_terminator_for_users() {
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_debug "$MODULE_NAME" "Configuring Terminator for user: $user"
        configure_terminator_for_user "$user"
    done
    
    return 0
}

# Verify Terminator installation
verify_terminator() {
    log_info "$MODULE_NAME" "Verifying Terminator installation..."
    
    if ! command -v terminator &>/dev/null; then
        log_error "$MODULE_NAME" "Terminator verification failed"
        return 1
    fi
    
    local terminator_version
    terminator_version=$(terminator --version 2>&1 || echo "unknown")
    log_debug "$MODULE_NAME" "Terminator version: $terminator_version"
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "Terminator is already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        if install_terminator; then
            if verify_terminator; then
                end_timer "$MODULE_NAME"
            else
                log_error "$MODULE_NAME" "Terminator verification failed after installation"
                return 1
            fi
        else
            log_error "$MODULE_NAME" "Terminator installation failed"
            return 1
        fi
    fi
    
    # Configure Terminator for all users
    log_info "$MODULE_NAME" "Configuring Terminator for all users..."
    configure_terminator_for_users
    
    log_info "$MODULE_NAME" "Terminator installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
