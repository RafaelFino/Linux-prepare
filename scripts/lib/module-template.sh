#!/usr/bin/env bash

# ============================================================================
# Module Template for Linux-prepare Modular Architecture
# ============================================================================
# This is a template for creating new modules in the Linux-prepare system
# Copy this file and modify it to create new modules

# Exit on any error
set -euo pipefail

# ============================================================================
# Module Configuration
# ============================================================================

# Module name (should match filename without .sh extension)
MODULE_NAME="$(basename "$0" .sh)"

# Module description
MODULE_DESCRIPTION="Template module for Linux-prepare"

# Module version
MODULE_VERSION="1.0.0"

# Required dependencies (commands that must be available)
MODULE_DEPENDENCIES=()

# Optional dependencies (commands that are nice to have)
MODULE_OPTIONAL_DEPS=()

# ============================================================================
# Load Required Libraries
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"

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

# Main module logic (override this function in your module)
module_main() {
    log_module_info "$MODULE_NAME" "Running main module logic..."
    
    # TODO: Implement your module logic here
    # Example:
    # install_module_packages "$MODULE_NAME" package1 package2
    # configure_something
    # validate_installation
    
    log_module_success "$MODULE_NAME" "Module completed successfully"
}

# Module cleanup (called on exit)
module_cleanup() {
    log_module_info "$MODULE_NAME" "Cleaning up module resources..."
    # TODO: Add cleanup logic if needed
}

# Module validation (check if module work was successful)
module_validate() {
    log_module_info "$MODULE_NAME" "Validating module installation..."
    
    # TODO: Add validation logic
    # Example:
    # validate_critical_packages command1 command2
    
    return 0
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