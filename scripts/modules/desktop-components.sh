#!/usr/bin/env bash

# ============================================================================
# Desktop Components Module for Linux-prepare
# ============================================================================
# This module handles installation of desktop applications, fonts, and 
# terminal emulators with improved font management using home directory
# temporary folders and proper cleanup.

# Exit on any error
set -euo pipefail

# ============================================================================
# Module Configuration
# ============================================================================

# Module name (should match filename without .sh extension)
MODULE_NAME="$(basename "$0" .sh)"

# Module description
MODULE_DESCRIPTION="Desktop components installation with improved font management"

# Module version
MODULE_VERSION="1.0.0"

# Required dependencies (commands that must be available)
MODULE_DEPENDENCIES=(wget git curl apt)

# Optional dependencies (commands that are nice to have)
MODULE_OPTIONAL_DEPS=(snap fc-cache)

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

# Detect if we're in a desktop environment
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
        log_module_info "$MODULE_NAME" "XFCE desktop detected (Xubuntu compatible)"
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
    
    # Return result
    if [ "$has_desktop" = true ]; then
        log_module_success "$MODULE_NAME" "Desktop environment detected: $desktop_type"
        return 0
    else
        log_module_info "$MODULE_NAME" "No desktop environment detected (server/headless mode)"
        return 1
    fi
}

# Detect Pop!_OS for special handling
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
# Font Installation Functions with Improved Management
# ============================================================================

# Create user-specific temporary directory for fonts
create_user_font_temp_dir() {
    local user="$1"
    local home_dir=$(get_user_home "$user")
    local temp_dir="$home_dir/.tmp-fonts-$$"
    
    log_module_info "$MODULE_NAME" "Creating temporary font directory for user $user: $temp_dir"
    
    # Create directory with proper permissions
    if sudo -u "$user" mkdir -p "$temp_dir"; then
        echo "$temp_dir"
        return 0
    else
        log_module_error "$MODULE_NAME" "Failed to create temporary directory for user $user"
        return 1
    fi
}

# Clean up temporary font directory
cleanup_font_temp_dir() {
    local temp_dir="$1"
    local user="$2"
    
    if [ -d "$temp_dir" ]; then
        log_module_info "$MODULE_NAME" "Cleaning up temporary font directory: $temp_dir"
        sudo -u "$user" rm -rf "$temp_dir" || {
            log_module_warning "$MODULE_NAME" "Failed to clean up temporary directory: $temp_dir"
        }
    fi
}

# Install fonts for a specific user with improved temp directory management
install_fonts_for_user() {
    local user="$1"
    local home_dir=$(get_user_home "$user")
    local temp_dir=""
    
    # Skip root for font installation
    if [ "$user" == "root" ]; then
        log_module_skip "$MODULE_NAME" "Skipping font installation for root user"
        return 0
    fi
    
    log_module_info "$MODULE_NAME" "Installing fonts for user $user..."
    
    # Create user-specific temporary directory
    temp_dir=$(create_user_font_temp_dir "$user")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Set up cleanup trap for this function
    trap "cleanup_font_temp_dir '$temp_dir' '$user'" EXIT ERR
    
    # Install Powerline Fonts
    if [ ! -d "$home_dir/.local/share/fonts/powerline-fonts" ]; then
        log_module_info "$MODULE_NAME" "Installing Powerline fonts for user $user..."
        
        sudo -u "$user" git clone --depth=1 https://github.com/powerline/fonts.git "$temp_dir/powerline-fonts"
        
        # Run install script as user
        (cd "$temp_dir/powerline-fonts" && sudo -u "$user" ./install.sh)
        
        log_module_success "$MODULE_NAME" "Powerline fonts installed for user $user"
    else
        log_module_skip "$MODULE_NAME" "Powerline fonts already installed for user $user"
    fi
    
    # Install Nerd Fonts (selected)
    if [ ! -d "$home_dir/.local/share/fonts/NerdFonts" ]; then
        log_module_info "$MODULE_NAME" "Installing Nerd Fonts (FiraCode, JetBrainsMono, Hack) for user $user..."
        
        sudo -u "$user" git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git "$temp_dir/nerd-fonts"
        
        # Run install script as user for selected fonts
        (cd "$temp_dir/nerd-fonts" && sudo -u "$user" ./install.sh FiraCode JetBrainsMono Hack)
        
        log_module_success "$MODULE_NAME" "Nerd Fonts installed for user $user"
    else
        log_module_skip "$MODULE_NAME" "Nerd Fonts already installed for user $user"
    fi
    
    # Update font cache for user
    log_module_info "$MODULE_NAME" "Updating font cache for user $user..."
    sudo -u "$user" fc-cache -fv > /dev/null 2>&1 || {
        log_module_warning "$MODULE_NAME" "Failed to update font cache for user $user"
    }
    
    # Clean up temporary directory
    cleanup_font_temp_dir "$temp_dir" "$user"
    
    # Remove the trap since we've cleaned up successfully
    trap - EXIT ERR
    
    log_module_success "$MODULE_NAME" "Font installation completed for user $user"
}

# Install system-wide MS Core Fonts
install_ms_core_fonts() {
    log_module_info "$MODULE_NAME" "Installing MS Core Fonts..."
    
    if ! check_package_installed ttf-mscorefonts-installer; then
        # Pre-accept EULA
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
        
        if install_packages_safe ttf-mscorefonts-installer; then
            log_module_success "$MODULE_NAME" "MS Core Fonts installed"
        else
            log_module_warning "$MODULE_NAME" "Failed to install MS Core Fonts"
            return 1
        fi
    else
        log_module_skip "$MODULE_NAME" "MS Core Fonts already installed"
    fi
    
    return 0
}

# ============================================================================
# Terminal Emulator Installation
# ============================================================================

install_terminal_emulators() {
    log_module_info "$MODULE_NAME" "Installing terminal emulators..."
    
    local emulators=(terminator alacritty)
    local to_install=()
    
    for emu in "${emulators[@]}"; do
        if check_package_installed "$emu"; then
            log_module_skip "$MODULE_NAME" "Terminal emulator $emu already installed"
        else
            to_install+=("$emu")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log_module_info "$MODULE_NAME" "Installing terminal emulators: ${to_install[*]}"
        if install_packages_safe "${to_install[@]}"; then
            log_module_success "$MODULE_NAME" "Terminal emulators installed"
        else
            log_module_warning "$MODULE_NAME" "Some terminal emulators failed to install"
            return 1
        fi
    else
        log_module_skip "$MODULE_NAME" "All terminal emulators already installed"
    fi
    
    return 0
}

# Configure terminal emulators for a specific user
configure_terminal_emulators_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    # Skip root for desktop configuration
    if [ "$user" == "root" ]; then
        return 0
    fi
    
    log_module_info "$MODULE_NAME" "Configuring terminal emulators for user $user..."
    
    # Configure Terminator
    local terminator_config_dir="$home_dir/.config/terminator"
    sudo -u "$user" mkdir -p "$terminator_config_dir"
    
    if [ ! -f "$terminator_config_dir/config" ]; then
        sudo -u "$user" cat > "$terminator_config_dir/config" << 'EOF'
[global_config]
  title_hide_sizetext = True
[profiles]
  [[default]]
    background_darkness = 0.9
    background_type = transparent
    font = FiraCode Nerd Font Mono 11
    use_system_font = False
    scrollback_infinite = True
EOF
        log_module_success "$MODULE_NAME" "Terminator configured for user $user"
    else
        log_module_skip "$MODULE_NAME" "Terminator already configured for user $user"
    fi
    
    # Configure Alacritty
    local alacritty_config_dir="$home_dir/.config/alacritty"
    sudo -u "$user" mkdir -p "$alacritty_config_dir"
    
    if [ ! -f "$alacritty_config_dir/alacritty.yml" ]; then
        sudo -u "$user" cat > "$alacritty_config_dir/alacritty.yml" << 'EOF'
font:
  normal:
    family: FiraCode Nerd Font
    style: Regular
  size: 11.0

window:
  opacity: 0.9
  padding:
    x: 10
    y: 10

scrolling:
  history: 10000
EOF
        log_module_success "$MODULE_NAME" "Alacritty configured for user $user"
    else
        log_module_skip "$MODULE_NAME" "Alacritty already configured for user $user"
    fi
}

# ============================================================================
# Desktop Application Installation
# ============================================================================

install_vscode() {
    log_module_info "$MODULE_NAME" "Installing VSCode..."
    
    if check_command_available code; then
        log_module_skip "$MODULE_NAME" "VSCode already installed"
        return 0
    fi
    
    # Pop!_OS specific handling (snap may not work well)
    if detect_popos; then
        log_module_info "$MODULE_NAME" "Pop!_OS detected - using apt repository method for VSCode"
        
        # Add Microsoft GPG key
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        
        # Add VSCode repository
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
        
        # Install
        apt update
        if apt install -y code; then
            rm /tmp/packages.microsoft.gpg
            log_module_success "$MODULE_NAME" "VSCode installed on Pop!_OS via apt"
        else
            rm /tmp/packages.microsoft.gpg
            log_module_error "$MODULE_NAME" "Failed to install VSCode on Pop!_OS"
            return 1
        fi
    else
        # Ensure snap is available for other distros
        if ! check_command_available snap; then
            log_module_info "$MODULE_NAME" "Installing snapd for VSCode..."
            if install_packages_safe snapd; then
                systemctl enable snapd 2>/dev/null || true
                systemctl start snapd 2>/dev/null || true
                # Wait for snap to be ready
                sleep 2
            else
                log_module_error "$MODULE_NAME" "Failed to install snapd"
                return 1
            fi
        fi
        
        # Use snap for other distros
        if snap install code --classic; then
            log_module_success "$MODULE_NAME" "VSCode installed via snap"
        else
            log_module_error "$MODULE_NAME" "Failed to install VSCode via snap"
            return 1
        fi
    fi
    
    return 0
}

install_google_chrome() {
    log_module_info "$MODULE_NAME" "Installing Google Chrome..."
    
    if check_command_available google-chrome; then
        log_module_skip "$MODULE_NAME" "Google Chrome already installed"
        return 0
    fi
    
    # Download and install Chrome
    local chrome_deb="/tmp/google-chrome-stable_current_amd64.deb"
    
    if wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O "$chrome_deb"; then
        if dpkg -i "$chrome_deb" || apt install -f -y; then
            rm "$chrome_deb"
            log_module_success "$MODULE_NAME" "Google Chrome installed"
        else
            rm "$chrome_deb"
            log_module_error "$MODULE_NAME" "Failed to install Google Chrome"
            return 1
        fi
    else
        log_module_error "$MODULE_NAME" "Failed to download Google Chrome"
        return 1
    fi
    
    return 0
}

install_additional_desktop_apps() {
    log_module_info "$MODULE_NAME" "Installing additional desktop applications..."
    
    local apps=(flameshot)
    local to_install=()
    
    for app in "${apps[@]}"; do
        if check_package_installed "$app"; then
            log_module_skip "$MODULE_NAME" "Application $app already installed"
        else
            to_install+=("$app")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log_module_info "$MODULE_NAME" "Installing applications: ${to_install[*]}"
        if install_packages_safe "${to_install[@]}"; then
            log_module_success "$MODULE_NAME" "Additional desktop applications installed"
        else
            log_module_warning "$MODULE_NAME" "Some applications failed to install"
            return 1
        fi
    else
        log_module_skip "$MODULE_NAME" "All additional applications already installed"
    fi
    
    return 0
}

install_desktop_applications() {
    log_module_info "$MODULE_NAME" "Installing desktop applications..."
    
    # Install VSCode
    install_vscode
    
    # Install Google Chrome
    install_google_chrome
    
    # Install additional desktop apps
    install_additional_desktop_apps
    
    log_module_success "$MODULE_NAME" "Desktop applications installation completed"
}

# ============================================================================
# Module Main Logic
# ============================================================================

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

# Main module logic
module_main() {
    log_module_info "$MODULE_NAME" "Running desktop components installation..."
    
    # Check if we should install desktop components
    if [ "${INSTALL_DESKTOP:-auto}" == "false" ] || [ "${INSTALL_DESKTOP:-auto}" == "skip" ]; then
        log_module_skip "$MODULE_NAME" "Desktop components installation skipped (INSTALL_DESKTOP=false)"
        return 0
    fi
    
    # Auto-detect desktop environment if not forced
    if [ "${INSTALL_DESKTOP:-auto}" == "auto" ]; then
        if ! detect_desktop_environment; then
            log_module_skip "$MODULE_NAME" "No desktop environment detected, skipping desktop components"
            return 0
        fi
    fi
    
    log_module_info "$MODULE_NAME" "Installing desktop components..."
    
    # Install system-wide MS Core Fonts
    install_ms_core_fonts
    
    # Install terminal emulators
    install_terminal_emulators
    
    # Install desktop applications
    install_desktop_applications
    
    # Install fonts for users (if users are specified)
    if [ -n "${ALL_USERS:-}" ]; then
        for user in "${ALL_USERS[@]}"; do
            install_fonts_for_user "$user"
            configure_terminal_emulators_for_user "$user"
        done
    else
        log_module_warning "$MODULE_NAME" "No users specified for font installation"
    fi
    
    log_module_success "$MODULE_NAME" "Desktop components installation completed"
}

# Module cleanup (called on exit)
module_cleanup() {
    log_module_info "$MODULE_NAME" "Cleaning up module resources..."
    # Cleanup is handled by individual functions with traps
}

# Module validation (check if module work was successful)
module_validate() {
    log_module_info "$MODULE_NAME" "Validating desktop components installation..."
    
    local validation_failed=false
    
    # Validate desktop applications if they should be installed
    if [ "${INSTALL_DESKTOP:-auto}" != "false" ] && [ "${INSTALL_DESKTOP:-auto}" != "skip" ]; then
        # Check VSCode
        if ! check_command_available code; then
            log_module_warning "$MODULE_NAME" "VSCode validation failed - command not available"
            validation_failed=true
        fi
        
        # Check Google Chrome
        if ! check_command_available google-chrome; then
            log_module_warning "$MODULE_NAME" "Google Chrome validation failed - command not available"
            validation_failed=true
        fi
        
        # Check terminal emulators
        if ! check_command_available terminator && ! check_command_available alacritty; then
            log_module_warning "$MODULE_NAME" "No terminal emulators available"
            validation_failed=true
        fi
    fi
    
    if [ "$validation_failed" = true ]; then
        log_module_warning "$MODULE_NAME" "Some validations failed, but module completed"
        return 0  # Don't fail the module for validation warnings
    fi
    
    log_module_success "$MODULE_NAME" "Desktop components validation completed"
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