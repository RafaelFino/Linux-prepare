#!/usr/bin/env bash

# ============================================================================
# System Detection Module for Linux-prepare
# ============================================================================
# This module handles distribution and desktop environment detection
# Extracted from prepare.sh to support modular architecture
# Includes specific support for Xubuntu 25.10 detection

set -euo pipefail

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_NAME="system-detection"

# Source required libraries
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/version-detection.sh"

# ============================================================================
# Global Variables (set by this module)
# ============================================================================

# These variables will be set by the detection functions and used by other modules
DETECTED_OS=""           # ubuntu, debian, pop, etc.
DETECTED_VERSION=""      # 24.04, 25.10, etc.
DETECTED_CODENAME=""     # noble, oracular, etc.
DETECTED_DESKTOP=""      # GNOME, XFCE, KDE, etc.
IS_DESKTOP_ENV=""        # true/false
IS_POPOS=""             # true/false for Pop!_OS specific handling
IS_XUBUNTU=""           # true/false for Xubuntu specific handling

# ============================================================================
# Utility Functions
# ============================================================================

check_command_available() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# Pop!_OS Detection
# ============================================================================

detect_popos() {
    if [ ! -f /etc/os-release ]; then
        return 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" == "pop" ]] || [[ "$NAME" == *"Pop!_OS"* ]]; then
        return 0
    fi
    
    return 1
}

# ============================================================================
# Distribution Detection
# ============================================================================

detect_distribution() {
    log_module_info "$MODULE_NAME" "Detecting Linux distribution..."
    
    if [ ! -f /etc/os-release ]; then
        log_module_error "$MODULE_NAME" "Cannot detect Linux distribution (/etc/os-release not found)"
        exit 1
    fi
    
    source /etc/os-release
    
    # Set global variables
    DETECTED_OS="$ID"
    DETECTED_VERSION="${VERSION_ID:-unknown}"
    DETECTED_CODENAME="${VERSION_CODENAME:-unknown}"
    
    # Check if it's Debian-based (including Pop!_OS)
    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "pop" ]] || [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID_LIKE" == *"ubuntu"* ]]; then
        log_module_success "$MODULE_NAME" "Detected Debian-based distribution: $PRETTY_NAME"
        
        # Special handling for Pop!_OS
        if detect_popos; then
            IS_POPOS="true"
            log_module_info "$MODULE_NAME" "Pop!_OS detected - using optimized installation methods"
        else
            IS_POPOS="false"
        fi
        
        # Special handling for Xubuntu
        if [[ "$PRETTY_NAME" == *"Xubuntu"* ]] || [[ "$NAME" == *"Xubuntu"* ]]; then
            IS_XUBUNTU="true"
            log_module_info "$MODULE_NAME" "Xubuntu detected - XFCE desktop environment expected"
            
            # Specific Xubuntu 25.10 detection
            if [[ "$VERSION_ID" == "25.10" ]]; then
                log_module_success "$MODULE_NAME" "Xubuntu 25.10 detected - full support enabled"
                # Set codename for 25.10 if not detected
                if [[ "$DETECTED_CODENAME" == "unknown" ]]; then
                    DETECTED_CODENAME="oracular"
                    log_module_info "$MODULE_NAME" "Set codename to 'oracular' for Ubuntu 25.10"
                fi
            fi
        else
            IS_XUBUNTU="false"
        fi
        
        # Verify apt is available
        if ! check_command_available apt; then
            log_module_error "$MODULE_NAME" "apt command not found. This script requires a Debian-based distribution."
            exit 1
        fi
        
        return 0
    else
        log_module_error "$MODULE_NAME" "Unsupported distribution: $PRETTY_NAME"
        log_module_error "$MODULE_NAME" "This script only supports Debian-based distributions (Debian, Ubuntu, Mint, Pop!_OS, etc.)"
        exit 1
    fi
}

# ============================================================================
# Desktop Environment Detection
# ============================================================================

detect_desktop_environment() {
    log_module_info "$MODULE_NAME" "Detecting desktop environment..."
    
    # Check if running in a graphical environment
    local has_desktop=false
    local desktop_type="none"
    
    # Method 1: Check if DISPLAY is set (X11)
    if [ -n "${DISPLAY:-}" ]; then
        has_desktop=true
        log_module_info "$MODULE_NAME" "X11 display detected: $DISPLAY"
    fi
    
    # Method 2: Check if XDG_CURRENT_DESKTOP is set
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        has_desktop=true
        desktop_type="$XDG_CURRENT_DESKTOP"
        log_module_info "$MODULE_NAME" "Desktop environment detected: $desktop_type"
    fi
    
    # Method 3: Check for common desktop environment processes
    if pgrep -x "gnome-shell" > /dev/null; then
        has_desktop=true
        desktop_type="GNOME"
        log_module_info "$MODULE_NAME" "GNOME desktop detected"
    elif pgrep -x "plasmashell" > /dev/null; then
        has_desktop=true
        desktop_type="KDE Plasma"
        log_module_info "$MODULE_NAME" "KDE Plasma desktop detected"
    elif pgrep -x "xfce4-session" > /dev/null; then
        has_desktop=true
        desktop_type="XFCE"
        log_module_info "$MODULE_NAME" "XFCE desktop detected"
        
        # Special validation for Xubuntu
        if [[ "$IS_XUBUNTU" == "true" ]]; then
            log_module_success "$MODULE_NAME" "XFCE desktop confirmed for Xubuntu system"
        fi
    elif pgrep -x "mate-session" > /dev/null; then
        has_desktop=true
        desktop_type="MATE"
        log_module_info "$MODULE_NAME" "MATE desktop detected"
    elif pgrep -x "cinnamon-session" > /dev/null; then
        has_desktop=true
        desktop_type="Cinnamon"
        log_module_info "$MODULE_NAME" "Cinnamon desktop detected"
    elif pgrep -x "lxsession" > /dev/null; then
        has_desktop=true
        desktop_type="LXDE"
        log_module_info "$MODULE_NAME" "LXDE desktop detected"
    fi
    
    # Method 4: Check if systemd graphical target is active
    if systemctl is-active graphical.target &>/dev/null; then
        has_desktop=true
        log_module_info "$MODULE_NAME" "Systemd graphical target is active"
    fi
    
    # Method 5: Check for X11 or Wayland
    if [ -S /tmp/.X11-unix/X0 ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        has_desktop=true
        if [ -n "${WAYLAND_DISPLAY:-}" ]; then
            log_module_info "$MODULE_NAME" "Wayland display detected: $WAYLAND_DISPLAY"
        fi
    fi
    
    # Set global variables
    DETECTED_DESKTOP="$desktop_type"
    
    # Return result
    if [ "$has_desktop" = true ]; then
        IS_DESKTOP_ENV="true"
        log_module_success "$MODULE_NAME" "Desktop environment detected: $desktop_type"
        return 0
    else
        IS_DESKTOP_ENV="false"
        log_module_info "$MODULE_NAME" "No desktop environment detected (server/headless mode)"
        return 1
    fi
}

# ============================================================================
# System Configuration and Validation
# ============================================================================

set_global_environment_vars() {
    log_module_info "$MODULE_NAME" "Setting global environment variables..."
    
    # Use the enhanced function from version-detection.sh
    set_system_environment_vars
    
    # Export variables for use by other modules (these are set by detection functions)
    export DETECTED_OS
    export DETECTED_VERSION
    export DETECTED_CODENAME
    export DETECTED_DESKTOP
    export IS_DESKTOP_ENV
    export IS_POPOS
    export IS_XUBUNTU
    
    log_module_success "$MODULE_NAME" "Global environment variables set"
}

validate_system_compatibility() {
    log_module_info "$MODULE_NAME" "Validating system compatibility..."
    
    # Use the validation function from version-detection.sh but avoid recursion
    if ! is_debian_based; then
        local name=$(detect_distribution_name)
        log_module_error "$MODULE_NAME" "Unsupported distribution: $name"
        log_module_error "$MODULE_NAME" "This script only supports Debian-based distributions (Debian, Ubuntu, Mint, Pop!_OS, etc.)"
        return 1
    fi
    
    # Additional validation for Xubuntu 25.10
    if [[ "$IS_XUBUNTU" == "true" ]] && [[ "$DETECTED_VERSION" == "25.10" ]]; then
        log_module_info "$MODULE_NAME" "Performing Xubuntu 25.10 specific validation..."
        
        # Check if we can detect the correct codename
        if [[ "$DETECTED_CODENAME" == "oracular" ]] || [[ "$DETECTED_CODENAME" == "unknown" ]]; then
            log_module_success "$MODULE_NAME" "Xubuntu 25.10 validation passed"
        else
            log_module_warning "$MODULE_NAME" "Unexpected codename for Ubuntu 25.10: $DETECTED_CODENAME"
        fi
    fi
    
    log_module_success "$MODULE_NAME" "System compatibility validated"
    return 0
}

print_system_summary() {
    log_module_info "$MODULE_NAME" "System Detection Summary:"
    log_module_info "$MODULE_NAME" "  Distribution: $DETECTED_OS"
    log_module_info "$MODULE_NAME" "  Version: $DETECTED_VERSION"
    log_module_info "$MODULE_NAME" "  Codename: $DETECTED_CODENAME"
    log_module_info "$MODULE_NAME" "  Desktop Environment: $DETECTED_DESKTOP"
    log_module_info "$MODULE_NAME" "  Has Desktop: $IS_DESKTOP_ENV"
    log_module_info "$MODULE_NAME" "  Is Pop!_OS: $IS_POPOS"
    log_module_info "$MODULE_NAME" "  Is Xubuntu: $IS_XUBUNTU"
    
    # Show version-specific configurations
    if command -v get_ls_replacement_package &>/dev/null; then
        local ls_package=$(get_ls_replacement_package)
        log_module_info "$MODULE_NAME" "  LS replacement package: $ls_package"
    fi
    
    if command -v get_docker_repo_config &>/dev/null; then
        local docker_repo=$(get_docker_repo_config)
        log_module_info "$MODULE_NAME" "  Docker repository: $docker_repo"
    fi
}

# ============================================================================
# Main Module Function
# ============================================================================

module_main() {
    log_module_info "$MODULE_NAME" "Starting system detection module"
    
    # Run detection functions
    detect_distribution
    detect_desktop_environment
    
    # Set environment variables
    set_global_environment_vars
    
    # Validate system compatibility
    validate_system_compatibility
    
    # Print summary
    print_system_summary
    
    log_module_success "$MODULE_NAME" "System detection module completed"
}

# ============================================================================
# Error Handling
# ============================================================================

# Error trap
trap 'log_module_error "$MODULE_NAME" "System detection module failed at line $LINENO"' ERR

# ============================================================================
# Module Execution
# ============================================================================

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    module_main "$@"
fi