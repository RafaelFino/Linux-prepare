#!/usr/bin/env bash

# ============================================================================
# Python Installation Module for Linux-prepare
# ============================================================================
# This module handles the installation and configuration of Python
# Supports Xubuntu 25.10 and other Ubuntu-based distributions

# Exit on any error
set -euo pipefail

# ============================================================================
# Module Configuration
# ============================================================================

# Module name (should match filename without .sh extension)
MODULE_NAME="python-install"

# Module description
MODULE_DESCRIPTION="Python installation and configuration module"

# Module version
MODULE_VERSION="1.0.0"

# Required dependencies (commands that must be available)
MODULE_DEPENDENCIES=(apt)

# Optional dependencies (commands that are nice to have)
MODULE_OPTIONAL_DEPS=()

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

# Install Python development tools
install_python() {
    log_module_info "$MODULE_NAME" "Installing Python development tools..."
    
    # Python3 and pip are already in base packages, but let's verify
    if check_command_available python3 && check_command_available pip3; then
        local python_version=$(python3 --version)
        local pip_version=$(pip3 --version)
        log_module_info "$MODULE_NAME" "Python already available: $python_version"
        log_module_info "$MODULE_NAME" "Pip already available: $pip_version"
    else
        log_module_error "$MODULE_NAME" "Python3 or pip3 not available - base packages may not be installed"
        return 1
    fi
    
    # Install additional Python development tools
    local python_packages=(python3-venv python3-dev)
    local to_install=()
    
    for pkg in "${python_packages[@]}"; do
        if check_package_installed "$pkg"; then
            log_module_skip "$MODULE_NAME" "Package $pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log_module_info "$MODULE_NAME" "Installing Python packages: ${to_install[*]}"
        if install_packages_safe "${to_install[@]}"; then
            log_module_success "$MODULE_NAME" "Python development packages installed"
        else
            log_module_error "$MODULE_NAME" "Failed to install Python development packages"
            return 1
        fi
    else
        log_module_skip "$MODULE_NAME" "All Python development packages already installed"
    fi
    
    # Validate installation
    if check_command_available python3 && check_command_available pip3; then
        local python_version=$(python3 --version)
        local pip_version=$(pip3 --version)
        log_module_success "$MODULE_NAME" "Python installed successfully: $python_version"
        log_module_success "$MODULE_NAME" "Pip installed successfully: $pip_version"
    else
        log_module_error "$MODULE_NAME" "Python installation validation failed"
        return 1
    fi
}

# Configure Python aliases for users
configure_python_aliases_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    log_module_info "$MODULE_NAME" "Configuring Python aliases for user $user..."
    
    # Python and pip aliases
    local python_alias="alias python='python3'"
    local pip_alias="alias pip='pip3'"
    
    # Add aliases to .bashrc if it exists
    if [ -f "$home_dir/.bashrc" ]; then
        if ! grep -q "alias python=" "$home_dir/.bashrc"; then
            echo "$python_alias" >> "$home_dir/.bashrc"
            log_module_info "$MODULE_NAME" "Added python alias to .bashrc for $user"
        fi
        
        if ! grep -q "alias pip=" "$home_dir/.bashrc"; then
            echo "$pip_alias" >> "$home_dir/.bashrc"
            log_module_info "$MODULE_NAME" "Added pip alias to .bashrc for $user"
        fi
    fi
    
    # Add aliases to .zshrc if it exists
    if [ -f "$home_dir/.zshrc" ]; then
        if ! grep -q "alias python=" "$home_dir/.zshrc"; then
            echo "$python_alias" >> "$home_dir/.zshrc"
            log_module_info "$MODULE_NAME" "Added python alias to .zshrc for $user"
        fi
        
        if ! grep -q "alias pip=" "$home_dir/.zshrc"; then
            echo "$pip_alias" >> "$home_dir/.zshrc"
            log_module_info "$MODULE_NAME" "Added pip alias to .zshrc for $user"
        fi
    fi
    
    log_module_success "$MODULE_NAME" "Python aliases configured for user $user"
}

# Configure Python aliases for all users
configure_python_aliases() {
    log_module_info "$MODULE_NAME" "Configuring Python aliases for all users..."
    
    # Get list of users to configure (from environment or default to root)
    local users_to_configure=("root")
    
    # Add current user if not root
    local current_user=$(whoami)
    if [ "$current_user" != "root" ]; then
        users_to_configure+=("$current_user")
    fi
    
    # Configure aliases for each user
    for user in "${users_to_configure[@]}"; do
        if check_user_exists "$user"; then
            configure_python_aliases_for_user "$user"
        else
            log_module_warning "$MODULE_NAME" "User $user does not exist, skipping alias configuration"
        fi
    done
}

# Main module logic
module_main() {
    log_module_info "$MODULE_NAME" "Running Python installation module..."
    
    # Install Python development tools
    if ! install_python; then
        log_module_error "$MODULE_NAME" "Python installation failed"
        return 1
    fi
    
    # Configure Python aliases
    if ! configure_python_aliases; then
        log_module_warning "$MODULE_NAME" "Python alias configuration failed (non-critical)"
    fi
    
    log_module_success "$MODULE_NAME" "Python module completed successfully"
}

# Module cleanup (called on exit)
module_cleanup() {
    # No specific cleanup needed for Python module
    :
}

# Module validation (check if module work was successful)
module_validate() {
    log_module_info "$MODULE_NAME" "Validating Python installation..."
    
    # Check if python3 and pip3 commands are available
    if check_command_available python3 && check_command_available pip3; then
        # Check if venv module is available
        if python3 -c "import venv" 2>/dev/null; then
            log_module_success "$MODULE_NAME" "Python validation successful"
            return 0
        else
            log_module_error "$MODULE_NAME" "Python venv module not available"
            return 1
        fi
    else
        log_module_error "$MODULE_NAME" "Python validation failed - python3 or pip3 not found"
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