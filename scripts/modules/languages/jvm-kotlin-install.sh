#!/usr/bin/env bash

# ============================================================================
# JVM and Kotlin Installation Module for Linux-prepare
# ============================================================================
# This module handles the installation and configuration of JVM (Java) and Kotlin via SDKMAN
# Supports Xubuntu 25.10 and other Ubuntu-based distributions

# Exit on any error
set -euo pipefail

# ============================================================================
# Module Configuration
# ============================================================================

# Module name (should match filename without .sh extension)
MODULE_NAME="jvm-kotlin-install"

# Module description
MODULE_DESCRIPTION="JVM (Java) and Kotlin installation via SDKMAN module"

# Module version
MODULE_VERSION="1.0.0"

# Required dependencies (commands that must be available)
MODULE_DEPENDENCIES=(curl bash)

# Optional dependencies (commands that are nice to have)
MODULE_OPTIONAL_DEPS=(zip unzip)

# ============================================================================
# Load Required Libraries
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"

# Source required libraries
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/version-detection.sh"
source "$LIB_DIR/package-utils.sh"

# ============================================================================
# Module Functions
# ============================================================================

# Check if module can run (dependencies available)
check_module_dependencies() {
    local missing_deps=()
    
    for dep in "${MODULE_DEPENDENCIES[@]}"; do
        if ! check_command_available "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_module_error "$MODULE_NAME" "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Check optional dependencies
check_optional_dependencies() {
    for dep in "${MODULE_OPTIONAL_DEPS[@]}"; do
        if ! check_command_available "$dep"; then
            log_module_warning "$MODULE_NAME" "Optional dependency '$dep' not available"
        fi
    done
}

# Module initialization
module_init() {
    log_module_info "$MODULE_NAME" "Initializing module: $MODULE_DESCRIPTION"
    log_module_info "$MODULE_NAME" "Version: $MODULE_VERSION"
    
    # Check dependencies
    if ! check_module_dependencies; then
        return 1
    fi
    
    # Check optional dependencies
    check_optional_dependencies
    
    # Validate system compatibility
    if ! validate_system_compatibility; then
        log_module_error "$MODULE_NAME" "System not compatible with this module"
        return 1
    fi
    
    return 0
}

# Install SDKMAN for a specific user
install_sdkman_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
    
    if [ -f "$sdkman_init" ]; then
        log_module_skip "$MODULE_NAME" "SDKMAN already installed for user $user"
        return 0
    fi
    
    log_module_info "$MODULE_NAME" "Installing SDKMAN for user $user..."
    
    # Install SDKMAN
    if run_as "$user" 'curl -s "https://get.sdkman.io" | bash'; then
        if [ -f "$sdkman_init" ]; then
            log_module_success "$MODULE_NAME" "SDKMAN installed for user $user"
            return 0
        else
            log_module_error "$MODULE_NAME" "SDKMAN installation completed but init script not found for user $user"
            return 1
        fi
    else
        log_module_error "$MODULE_NAME" "SDKMAN installation failed for user $user"
        return 1
    fi
}

# Install JVM for a specific user
install_jvm_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
    
    log_module_info "$MODULE_NAME" "Installing Java for user $user..."
    
    # Ensure SDKMAN is installed
    if ! install_sdkman_for_user "$user"; then
        log_module_error "$MODULE_NAME" "Cannot install Java - SDKMAN installation failed for user $user"
        return 1
    fi
    
    # Check if Java is already installed
    if run_as "$user" "source $sdkman_init && java -version" &>/dev/null; then
        local java_version=$(run_as "$user" "source $sdkman_init && java -version 2>&1 | head -n 1")
        log_module_skip "$MODULE_NAME" "Java already installed for user $user: $java_version"
        return 0
    fi
    
    # Install Java using SDKMAN
    log_module_info "$MODULE_NAME" "Installing Java via SDKMAN for user $user..."
    if run_as "$user" "source $sdkman_init && sdk install java < /dev/null" 2>/dev/null; then
        # Validate installation
        if run_as "$user" "source $sdkman_init && java -version" &>/dev/null; then
            local java_version=$(run_as "$user" "source $sdkman_init && java -version 2>&1 | head -n 1")
            log_module_success "$MODULE_NAME" "Java installed for user $user: $java_version"
            return 0
        else
            log_module_warning "$MODULE_NAME" "Java installation may have failed for user $user"
            return 1
        fi
    else
        log_module_warning "$MODULE_NAME" "Java installation via SDKMAN failed for user $user"
        return 1
    fi
}

# Install Kotlin for a specific user
install_kotlin_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
    
    log_module_info "$MODULE_NAME" "Installing Kotlin for user $user..."
    
    # Ensure SDKMAN is installed
    if ! install_sdkman_for_user "$user"; then
        log_module_error "$MODULE_NAME" "Cannot install Kotlin - SDKMAN installation failed for user $user"
        return 1
    fi
    
    # Check if Kotlin is already installed
    if run_as "$user" "source $sdkman_init && kotlin -version" &>/dev/null; then
        local kotlin_version=$(run_as "$user" "source $sdkman_init && kotlin -version 2>&1")
        log_module_skip "$MODULE_NAME" "Kotlin already installed for user $user: $kotlin_version"
        return 0
    fi
    
    # Install Kotlin using SDKMAN
    log_module_info "$MODULE_NAME" "Installing Kotlin via SDKMAN for user $user..."
    if run_as "$user" "source $sdkman_init && sdk install kotlin < /dev/null" 2>/dev/null; then
        # Validate installation
        if run_as "$user" "source $sdkman_init && kotlin -version" &>/dev/null; then
            local kotlin_version=$(run_as "$user" "source $sdkman_init && kotlin -version 2>&1")
            log_module_success "$MODULE_NAME" "Kotlin installed for user $user: $kotlin_version"
            return 0
        else
            log_module_warning "$MODULE_NAME" "Kotlin installation may have failed for user $user"
            return 1
        fi
    else
        log_module_warning "$MODULE_NAME" "Kotlin installation via SDKMAN failed for user $user"
        return 1
    fi
}

# Install JVM and Kotlin for all configured users
install_jvm_kotlin_for_users() {
    log_module_info "$MODULE_NAME" "Installing JVM and Kotlin for configured users..."
    
    # Get list of users to configure (from environment or default to root)
    local users_to_configure=("root")
    
    # Add current user if not root
    local current_user=$(whoami)
    if [ "$current_user" != "root" ]; then
        users_to_configure+=("$current_user")
    fi
    
    # Install for each user
    local success_count=0
    local total_users=${#users_to_configure[@]}
    
    for user in "${users_to_configure[@]}"; do
        if check_user_exists "$user"; then
            log_module_info "$MODULE_NAME" "Processing user: $user"
            
            # Install JVM
            if install_jvm_for_user "$user"; then
                log_module_success "$MODULE_NAME" "JVM installation successful for user $user"
            else
                log_module_warning "$MODULE_NAME" "JVM installation failed for user $user"
            fi
            
            # Install Kotlin
            if install_kotlin_for_user "$user"; then
                log_module_success "$MODULE_NAME" "Kotlin installation successful for user $user"
                ((success_count++))
            else
                log_module_warning "$MODULE_NAME" "Kotlin installation failed for user $user"
            fi
        else
            log_module_warning "$MODULE_NAME" "User $user does not exist, skipping"
        fi
    done
    
    if [ $success_count -gt 0 ]; then
        log_module_success "$MODULE_NAME" "JVM and Kotlin installed for $success_count/$total_users users"
        return 0
    else
        log_module_error "$MODULE_NAME" "JVM and Kotlin installation failed for all users"
        return 1
    fi
}

# Main module logic
module_main() {
    log_module_info "$MODULE_NAME" "Running JVM and Kotlin installation module..."
    
    # Install JVM and Kotlin for all users
    if ! install_jvm_kotlin_for_users; then
        log_module_error "$MODULE_NAME" "JVM and Kotlin installation failed"
        return 1
    fi
    
    log_module_success "$MODULE_NAME" "JVM and Kotlin module completed successfully"
}

# Module cleanup (called on exit)
module_cleanup() {
    # No specific cleanup needed for JVM/Kotlin module
    :
}

# Module validation (check if module work was successful)
module_validate() {
    log_module_info "$MODULE_NAME" "Validating JVM and Kotlin installation..."
    
    # Get list of users to validate
    local users_to_validate=("root")
    local current_user=$(whoami)
    if [ "$current_user" != "root" ]; then
        users_to_validate+=("$current_user")
    fi
    
    local validation_success=false
    
    # Check if at least one user has working JVM and Kotlin
    for user in "${users_to_validate[@]}"; do
        if check_user_exists "$user"; then
            local home_dir=$(get_user_home "$user")
            local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
            
            if [ -f "$sdkman_init" ]; then
                # Check Java
                if run_as "$user" "source $sdkman_init && java -version" &>/dev/null; then
                    # Check Kotlin
                    if run_as "$user" "source $sdkman_init && kotlin -version" &>/dev/null; then
                        log_module_success "$MODULE_NAME" "JVM and Kotlin validation successful for user $user"
                        validation_success=true
                        break
                    fi
                fi
            fi
        fi
    done
    
    if [ "$validation_success" = true ]; then
        log_module_success "$MODULE_NAME" "JVM and Kotlin validation successful"
        return 0
    else
        log_module_error "$MODULE_NAME" "JVM and Kotlin validation failed - no working installation found"
        return 1
    fi
}

# ============================================================================
# Error Handling
# ============================================================================

# Error trap function
module_error_handler() {
    local exit_code=$?
    local line_number=$1
    
    log_module_error "$MODULE_NAME" "Module failed at line $line_number with exit code $exit_code"
    module_cleanup
    exit $exit_code
}

# Set error trap
trap 'module_error_handler $LINENO' ERR

# Cleanup trap
trap 'module_cleanup' EXIT

# ============================================================================
# Module Execution
# ============================================================================

# Main execution function
execute_module() {
    # Initialize module
    if ! module_init; then
        log_module_error "$MODULE_NAME" "Module initialization failed"
        return 1
    fi
    
    # Run main module logic
    if ! module_main; then
        log_module_error "$MODULE_NAME" "Module execution failed"
        return 1
    fi
    
    # Validate module work
    if ! module_validate; then
        log_module_error "$MODULE_NAME" "Module validation failed"
        return 1
    fi
    
    log_module_success "$MODULE_NAME" "Module completed successfully"
    return 0
}

# ============================================================================
# Script Entry Point
# ============================================================================

# Execute module if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "$@"
fi