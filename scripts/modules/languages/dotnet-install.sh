#!/usr/bin/env bash

# ============================================================================
# .NET Installation Module for Linux-prepare
# ============================================================================
# This module handles the installation and configuration of .NET SDK
# Supports Xubuntu 25.10 and other Ubuntu-based distributions

# Exit on any error
set -euo pipefail

# ============================================================================
# Module Configuration
# ============================================================================

# Module name (should match filename without .sh extension)
MODULE_NAME="dotnet-install"

# Module description
MODULE_DESCRIPTION=".NET SDK installation and configuration module"

# Module version
MODULE_VERSION="1.0.0"

# Required dependencies (commands that must be available)
MODULE_DEPENDENCIES=(wget dpkg apt)

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

# Get Microsoft repository URL for current Ubuntu version
get_microsoft_repo_url() {
    local version_id=""
    
    # Get Ubuntu/Debian version
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        version_id="$VERSION_ID"
    else
        log_module_error "$MODULE_NAME" "Cannot detect OS version"
        return 1
    fi
    
    # Map Ubuntu 25.10 to supported version (use 24.04 as fallback)
    case "$version_id" in
        "25.10")
            # Ubuntu 25.10 - use 24.04 repository as fallback
            echo "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb"
            ;;
        "24.04"|"24.10")
            echo "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb"
            ;;
        "22.04"|"22.10")
            echo "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb"
            ;;
        "20.04"|"20.10")
            echo "https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb"
            ;;
        *)
            # Default to 22.04 for unknown versions
            log_module_warning "$MODULE_NAME" "Unknown Ubuntu version $version_id, using 22.04 repository"
            echo "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb"
            ;;
    esac
}

# Install .NET SDK
install_dotnet() {
    log_module_info "$MODULE_NAME" "Installing .NET SDK..."
    
    # Check if already installed
    if check_command_available dotnet; then
        local dotnet_version=$(dotnet --version)
        log_module_skip "$MODULE_NAME" ".NET already installed: $dotnet_version"
        return 0
    fi
    
    # Get Microsoft repository URL
    local pkg_url=$(get_microsoft_repo_url)
    if [ -z "$pkg_url" ]; then
        log_module_error "$MODULE_NAME" "Could not determine Microsoft repository URL"
        return 1
    fi
    
    # Download Microsoft package repository configuration
    log_module_info "$MODULE_NAME" "Adding Microsoft package repository..."
    log_module_info "$MODULE_NAME" "Using repository: $pkg_url"
    
    if wget "$pkg_url" -O /tmp/packages-microsoft-prod.deb 2>/dev/null; then
        if dpkg -i /tmp/packages-microsoft-prod.deb; then
            log_module_success "$MODULE_NAME" "Microsoft repository added successfully"
        else
            log_module_error "$MODULE_NAME" "Failed to install Microsoft repository package"
            rm -f /tmp/packages-microsoft-prod.deb
            return 1
        fi
        rm -f /tmp/packages-microsoft-prod.deb
    else
        log_module_error "$MODULE_NAME" "Failed to download Microsoft repository package"
        return 1
    fi
    
    # Update package list
    log_module_info "$MODULE_NAME" "Updating package list..."
    if ! apt update; then
        log_module_error "$MODULE_NAME" "Failed to update package list"
        return 1
    fi
    
    # Install .NET SDK 8.0
    log_module_info "$MODULE_NAME" "Installing dotnet-sdk-8.0..."
    if install_packages_safe "dotnet-sdk-8.0"; then
        log_module_success "$MODULE_NAME" ".NET SDK installed successfully"
    else
        log_module_error "$MODULE_NAME" "Failed to install .NET SDK"
        return 1
    fi
    
    # Validate installation
    if check_command_available dotnet; then
        local dotnet_version=$(dotnet --version)
        log_module_success "$MODULE_NAME" ".NET installed successfully: $dotnet_version"
    else
        log_module_error "$MODULE_NAME" ".NET installation validation failed"
        return 1
    fi
}

# Main module logic
module_main() {
    log_module_info "$MODULE_NAME" "Running .NET installation module..."
    
    # Install .NET SDK
    if ! install_dotnet; then
        log_module_error "$MODULE_NAME" ".NET installation failed"
        return 1
    fi
    
    log_module_success "$MODULE_NAME" ".NET module completed successfully"
}

# Module cleanup (called on exit)
module_cleanup() {
    # Clean up any temporary files
    rm -f /tmp/packages-microsoft-prod.deb 2>/dev/null || true
}

# Module validation (check if module work was successful)
module_validate() {
    log_module_info "$MODULE_NAME" "Validating .NET installation..."
    
    # Check if dotnet command is available
    if check_command_available dotnet; then
        # Try to get version to ensure it's working
        if dotnet --version &>/dev/null; then
            log_module_success "$MODULE_NAME" ".NET validation successful"
            return 0
        else
            log_module_error "$MODULE_NAME" ".NET command exists but not working properly"
            return 1
        fi
    else
        log_module_error "$MODULE_NAME" ".NET validation failed - dotnet command not found"
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