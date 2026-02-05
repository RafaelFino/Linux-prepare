#!/bin/bash

# Fonts Installation Module
# Installs Nerd Fonts and Powerline Fonts for enhanced terminal experience

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="fonts"
readonly FONTS_INSTALL_PATH="$HOME/.local/share/fonts"
readonly POWERLINE_FONTS_REPO="https://github.com/powerline/fonts.git"
readonly NERD_FONTS_REPO="https://github.com/ryanoasis/nerd-fonts.git"

# Check if fonts are already installed
is_installed() {
    # Check if Nerd Fonts or Powerline Fonts directories exist
    if [[ -d "$FONTS_INSTALL_PATH/NerdFonts" ]] || [[ -d "$FONTS_INSTALL_PATH/PowerlineFonts" ]]; then
        return 0
    fi
    
    # Check if font cache has been updated recently
    if [[ -f "$HOME/.cache/fontconfig/CACHEDIR.TAG" ]]; then
        return 0
    fi
    
    return 1
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Install fonts for a specific user
install_fonts_for_user() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    local user_fonts_path="$user_home/.local/share/fonts"
    
    # Create fonts directory if it doesn't exist
    if [[ ! -d "$user_fonts_path" ]]; then
        sudo -u "$username" mkdir -p "$user_fonts_path"
        log_debug "$MODULE_NAME" "Created fonts directory for $username"
    fi
    
    # Install Powerline Fonts
    install_powerline_fonts_for_user "$username" "$user_fonts_path"
    
    # Install Nerd Fonts
    install_nerd_fonts_for_user "$username" "$user_fonts_path"
    
    return 0
}

# Install Powerline Fonts for a user
install_powerline_fonts_for_user() {
    local username="$1"
    local user_fonts_path="$2"
    local temp_dir="/tmp/powerline-fonts-$$"
    
    log_info "$MODULE_NAME" "Installing Powerline Fonts for $username..."
    
    # Clone Powerline Fonts repository
    if ! sudo -u "$username" git clone --depth 1 "$POWERLINE_FONTS_REPO" "$temp_dir" 2>/dev/null; then
        log_error "$MODULE_NAME" "Failed to clone Powerline Fonts repository"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Copy fonts to user's fonts directory
    if [[ -d "$temp_dir/fonts" ]]; then
        sudo -u "$username" cp "$temp_dir/fonts"/*.ttf "$user_fonts_path/" 2>/dev/null || true
        sudo -u "$username" cp "$temp_dir/fonts"/*.otf "$user_fonts_path/" 2>/dev/null || true
        log_debug "$MODULE_NAME" "Copied Powerline Fonts for $username"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    return 0
}

# Install Nerd Fonts for a user
install_nerd_fonts_for_user() {
    local username="$1"
    local user_fonts_path="$2"
    local temp_dir="/tmp/nerd-fonts-$$"
    
    log_info "$MODULE_NAME" "Installing Nerd Fonts for $username..."
    
    # Clone Nerd Fonts repository (shallow clone to save space)
    if ! sudo -u "$username" git clone --depth 1 "$NERD_FONTS_REPO" "$temp_dir" 2>/dev/null; then
        log_error "$MODULE_NAME" "Failed to clone Nerd Fonts repository"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Copy a selection of popular Nerd Fonts to user's fonts directory
    if [[ -d "$temp_dir/patched-fonts" ]]; then
        # Copy popular fonts: FiraCode, JetBrainsMono, Meslo, Ubuntu Mono
        for font_dir in FiraCode JetBrainsMono Meslo UbuntuMono; do
            if [[ -d "$temp_dir/patched-fonts/$font_dir" ]]; then
                sudo -u "$username" find "$temp_dir/patched-fonts/$font_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$user_fonts_path/" \; 2>/dev/null || true
                log_debug "$MODULE_NAME" "Copied $font_dir Nerd Font for $username"
            fi
        done
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    return 0
}

# Update font cache for a user
update_font_cache_for_user() {
    local username="$1"
    
    log_info "$MODULE_NAME" "Updating font cache for $username..."
    
    if command -v fc-cache &>/dev/null; then
        if sudo -u "$username" fc-cache -fv "$HOME/.local/share/fonts" 2>/dev/null; then
            log_debug "$MODULE_NAME" "Font cache updated for $username"
            return 0
        else
            log_warn "$MODULE_NAME" "Failed to update font cache for $username"
            return 1
        fi
    else
        log_warn "$MODULE_NAME" "fc-cache command not found, skipping font cache update"
        return 1
    fi
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "Fonts already installed, skipping installation"
    else
        start_timer "$MODULE_NAME"
        
        local users
        users=$(get_all_users)
        
        if [[ -z "$users" ]]; then
            log_warn "$MODULE_NAME" "No regular users found on the system"
            end_timer "$MODULE_NAME"
            return 0
        fi
        
        # Install fonts for all users
        for user in $users; do
            log_info "$MODULE_NAME" "Installing fonts for user: $user"
            install_fonts_for_user "$user"
        done
        
        # Update font cache for all users
        for user in $users; do
            update_font_cache_for_user "$user"
        done
        
        end_timer "$MODULE_NAME"
    fi
    
    log_info "$MODULE_NAME" "Fonts installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
