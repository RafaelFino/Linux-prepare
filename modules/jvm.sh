#!/bin/bash

# JVM Installation Module
# Installs SDKMAN and latest LTS Java version, configures JAVA_HOME and PATH for all users

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="jvm"
readonly SDKMAN_INIT_SCRIPT="$HOME/.sdkman/bin/sdkman-init.sh"

# Check if Java is installed
is_installed() {
    command -v java &>/dev/null
}

# Check if SDKMAN is installed
is_sdkman_installed() {
    [[ -d "$HOME/.sdkman" ]]
}

# Install SDKMAN
install_sdkman() {
    log_info "$MODULE_NAME" "Downloading SDKMAN installation script..."
    
    if ! curl -fsSL "https://get.sdkman.io" -o /tmp/install-sdkman.sh; then
        log_error "$MODULE_NAME" "Failed to download SDKMAN installation script"
        return 1
    fi
    
    log_info "$MODULE_NAME" "Running SDKMAN installation script..."
    
    if ! bash /tmp/install-sdkman.sh; then
        log_error "$MODULE_NAME" "SDKMAN installation script failed"
        rm -f /tmp/install-sdkman.sh
        return 1
    fi
    
    rm -f /tmp/install-sdkman.sh
    
    log_debug "$MODULE_NAME" "SDKMAN installed successfully"
    return 0
}

# Get latest LTS Java version
get_latest_lts_java_version() {
    log_debug "$MODULE_NAME" "Fetching latest LTS Java version..."
    
    # Source SDKMAN to use its commands
    if [[ -f "$SDKMAN_INIT_SCRIPT" ]]; then
        # shellcheck source=/dev/null
        source "$SDKMAN_INIT_SCRIPT" 2>/dev/null || true
        
        # Get the latest LTS version (usually 21, 17, 11, 8)
        # We'll use sdk list java to find LTS versions
        local lts_version
        lts_version=$(sdk list java 2>/dev/null | grep -i "lts" | head -1 | awk '{print $1}' || echo "")
        
        if [[ -n "$lts_version" ]]; then
            echo "$lts_version"
            return 0
        fi
    fi
    
    # Fallback to a known LTS version if we can't query
    log_warn "$MODULE_NAME" "Could not determine latest LTS version, using Java 21"
    echo "21.0.1-open"
}

# Install Java using SDKMAN
install_java() {
    # Source SDKMAN
    if [[ ! -f "$SDKMAN_INIT_SCRIPT" ]]; then
        log_error "$MODULE_NAME" "SDKMAN initialization script not found"
        return 1
    fi
    
    # shellcheck source=/dev/null
    source "$SDKMAN_INIT_SCRIPT" 2>/dev/null || true
    
    local java_version
    java_version=$(get_latest_lts_java_version)
    
    log_info "$MODULE_NAME" "Installing Java $java_version using SDKMAN..."
    
    # Install Java
    if ! sdk install java "$java_version" --default 2>/dev/null; then
        log_error "$MODULE_NAME" "Failed to install Java $java_version"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "Java $java_version installed successfully"
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Install SDKMAN for a specific user
install_sdkman_for_user() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    # Check if SDKMAN is already installed for this user
    if [[ -d "$user_home/.sdkman" ]]; then
        log_debug "$MODULE_NAME" "SDKMAN already installed for user $username"
        return 0
    fi
    
    log_debug "$MODULE_NAME" "Installing SDKMAN for user $username..."
    
    # Download and run SDKMAN installer as the user
    if ! sudo -u "$username" bash -c 'curl -fsSL "https://get.sdkman.io" | bash' 2>/dev/null; then
        log_warn "$MODULE_NAME" "Failed to install SDKMAN for user $username"
        return 1
    fi
    
    log_debug "$MODULE_NAME" "SDKMAN installed for user $username"
    return 0
}

# Configure JAVA_HOME and PATH for a user
configure_java_for_user() {
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
    
    # Add SDKMAN initialization if not already present
    if ! grep -q "sdkman-init.sh" "$profile_file" 2>/dev/null; then
        sudo -u "$username" bash -c "echo '' >> '$profile_file'"
        sudo -u "$username" bash -c "echo '# SDKMAN initialization' >> '$profile_file'"
        sudo -u "$username" bash -c "echo 'export SDKMAN_DIR=\"\$HOME/.sdkman\"' >> '$profile_file'"
        sudo -u "$username" bash -c "echo '[[ -s \"\$HOME/.sdkman/bin/sdkman-init.sh\" ]] && source \"\$HOME/.sdkman/bin/sdkman-init.sh\"' >> '$profile_file'"
        log_debug "$MODULE_NAME" "Added SDKMAN initialization to .profile for $username"
    else
        log_debug "$MODULE_NAME" "SDKMAN initialization already configured for $username"
    fi
    
    return 0
}

# Configure Java for all users
configure_java_for_users() {
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_debug "$MODULE_NAME" "Configuring Java for user: $user"
        install_sdkman_for_user "$user"
        configure_java_for_user "$user"
    done
    
    return 0
}

# Verify Java installation
verify_java() {
    log_info "$MODULE_NAME" "Verifying Java installation..."
    
    if ! command -v java &>/dev/null; then
        log_error "$MODULE_NAME" "Java verification failed"
        return 1
    fi
    
    local java_version
    java_version=$(java -version 2>&1 | head -1)
    log_debug "$MODULE_NAME" "Java version: $java_version"
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "Java is already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        # Install SDKMAN first if not already installed
        if ! is_sdkman_installed; then
            if ! install_sdkman; then
                log_error "$MODULE_NAME" "SDKMAN installation failed"
                return 1
            fi
        fi
        
        # Install Java
        if install_java; then
            if verify_java; then
                end_timer "$MODULE_NAME"
            else
                log_error "$MODULE_NAME" "Java verification failed after installation"
                return 1
            fi
        else
            log_error "$MODULE_NAME" "Java installation failed"
            return 1
        fi
    fi
    
    # Configure Java for all users
    log_info "$MODULE_NAME" "Configuring Java for all users..."
    configure_java_for_users
    
    log_info "$MODULE_NAME" "Java installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
