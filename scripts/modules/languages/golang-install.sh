#!/usr/bin/env bash

# ============================================================================
# Golang Installation Module for Linux-prepare
# ============================================================================
# This module handles the installation and configuration of Golang
# Supports Xubuntu 25.10 and other Ubuntu-based distributions

# Exit on any error
set -euo pipefail

# ============================================================================
# Module Configuration
# ============================================================================

# Module name (should match filename without .sh extension)
MODULE_NAME="golang-install"

# Module description
MODULE_DESCRIPTION="Golang installation and configuration module"

# Module version
MODULE_VERSION="1.0.0"

# Required dependencies (commands that must be available)
MODULE_DEPENDENCIES=(curl wget tar)

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

# Install Golang
install_golang() {
    log_module_info "$MODULE_NAME" "Installing Golang..."
    
    # Check if already installed
    if check_command_available go; then
        local go_version=$(go version)
        log_module_skip "$MODULE_NAME" "Golang already installed: $go_version"
        return 0
    fi
    
    # Get latest version
    log_module_info "$MODULE_NAME" "Fetching latest Golang version..."
    local latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
    local arch=$(dpkg --print-architecture)
    local download_url="https://go.dev/dl/${latest_version}.linux-${arch}.tar.gz"
    
    log_module_info "$MODULE_NAME" "Downloading Golang ${latest_version} for ${arch}..."
    if wget "$download_url" -O /tmp/golang.tar.gz; then
        log_module_success "$MODULE_NAME" "Golang downloaded"
    else
        log_module_error "$MODULE_NAME" "Failed to download Golang"
        return 1
    fi
    
    # Extract to /usr/local
    log_module_info "$MODULE_NAME" "Extracting Golang to /usr/local..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/golang.tar.gz
    rm /tmp/golang.tar.gz
    
    # Add to PATH in /etc/profile
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        log_module_info "$MODULE_NAME" "Adding Golang to system PATH..."
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    # Validate installation
    if /usr/local/go/bin/go version &>/dev/null; then
        local installed_version=$(/usr/local/go/bin/go version)
        log_module_success "$MODULE_NAME" "Golang installed successfully: $installed_version"
    else
        log_module_error "$MODULE_NAME" "Golang installation failed"
        return 1
    fi
}

# Main module logic
module_main() {
    log_module_info "$MODULE_NAME" "Running Golang installation module..."
    
    # Install Golang
    if ! install_golang; then
        log_module_error "$MODULE_NAME" "Golang installation failed"
        return 1
    fi
    
    log_module_success "$MODULE_NAME" "Golang module completed successfully"
}

# Module cleanup (called on exit)
module_cleanup() {
    # Clean up any temporary files
    rm -f /tmp/golang.tar.gz 2>/dev/null || true
}

# Module validation (check if module work was successful)
module_validate() {
    log_module_info "$MODULE_NAME" "Validating Golang installation..."
    
    # Check if go command is available
    if check_command_available go || [ -x "/usr/local/go/bin/go" ]; then
        log_module_success "$MODULE_NAME" "Golang validation successful"
        return 0
    else
        log_module_error "$MODULE_NAME" "Golang validation failed - go command not found"
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