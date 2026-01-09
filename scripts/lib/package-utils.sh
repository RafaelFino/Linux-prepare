#!/usr/bin/env bash

# ============================================================================
# Package Management Utilities for Linux-prepare Modular Architecture
# ============================================================================
# This library provides safe package installation and management utilities
# Extracted from prepare.sh to ensure consistent package handling across modules

# Note: This library assumes logging.sh is already sourced by the calling script

# ============================================================================
# Package Availability and Installation Check Functions
# ============================================================================

# Check if a package is installed
check_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Check if a package is available in repositories
check_package_available() {
    local package="$1"
    
    # Check if package is available in apt cache
    local policy_output=$(apt-cache policy "$package" 2>/dev/null)
    
    if echo "$policy_output" | grep -q "Candidate:"; then
        local version=$(echo "$policy_output" | grep "Candidate:" | awk '{print $2}')
        if [ -n "$version" ] && [ "$version" != "(none)" ]; then
            return 0  # Package available
        fi
    fi
    
    return 1  # Package not available
}

# Check if a command is available in the system
check_command_available() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Safe Package Installation Functions
# ============================================================================

# Install packages safely, checking availability first
# Usage: install_packages_safe package1 package2 package3
install_packages_safe() {
    local packages=("$@")
    local available_packages=()
    
    log_info "Checking package availability..."
    
    for pkg in "${packages[@]}"; do
        if check_package_available "$pkg"; then
            log_success "Package '$pkg' is available"
            available_packages+=("$pkg")
        else
            log_warning "Package '$pkg' not available in repositories, skipping"
        fi
    done
    
    if [ ${#available_packages[@]} -gt 0 ]; then
        log_info "Installing available packages: ${available_packages[*]}"
        apt install -y "${available_packages[@]}"
        return 0
    else
        log_warning "No packages available to install"
        return 1
    fi
}

# Install package with fallback option
# Usage: install_package_with_fallback primary_package fallback_package
install_package_with_fallback() {
    local primary="$1"
    local fallback="$2"
    local installed_package=""
    
    log_info "Attempting to install '$primary' (fallback: '$fallback')..."
    
    if check_package_available "$primary"; then
        log_success "Package '$primary' is available"
        if apt install -y "$primary"; then
            log_success "Installed '$primary'"
            installed_package="$primary"
        else
            log_error "Failed to install '$primary'"
        fi
    elif check_package_available "$fallback"; then
        log_warning "Package '$primary' not available, trying fallback '$fallback'"
        if apt install -y "$fallback"; then
            log_success "Installed fallback package '$fallback'"
            installed_package="$fallback"
        else
            log_error "Failed to install fallback package '$fallback'"
        fi
    else
        log_error "Neither '$primary' nor '$fallback' packages are available"
        return 1
    fi
    
    # Return the name of the installed package
    echo "$installed_package"
    return 0
}

# Install packages only if not already installed
# Usage: install_packages_if_missing package1 package2 package3
install_packages_if_missing() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if check_package_installed "$pkg"; then
            log_skip "Package $pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log_info "Installing missing packages: ${to_install[*]}"
        if apt install -y "${to_install[@]}"; then
            log_success "Packages installed successfully"
            return 0
        else
            log_error "Failed to install some packages"
            return 1
        fi
    else
        log_info "All packages already installed"
        return 0
    fi
}

# ============================================================================
# Repository Management Functions
# ============================================================================

# Add GPG key for repository
# Usage: add_repository_gpg_key url keyring_path
add_repository_gpg_key() {
    local gpg_url="$1"
    local keyring_path="$2"
    
    log_info "Adding GPG key from $gpg_url"
    
    # Create keyrings directory if it doesn't exist
    mkdir -p "$(dirname "$keyring_path")"
    
    # Download and add GPG key
    if wget -qO- "$gpg_url" | gpg --dearmor -o "$keyring_path" 2>/dev/null; then
        chmod 644 "$keyring_path"
        log_success "GPG key added successfully"
        return 0
    else
        log_error "Failed to add GPG key from $gpg_url"
        return 1
    fi
}

# Add apt repository
# Usage: add_apt_repository "deb [signed-by=/path/to/key] url codename component" list_file_path
add_apt_repository() {
    local repo_line="$1"
    local list_file="$2"
    
    log_info "Adding repository: $repo_line"
    
    # Create sources.list.d directory if it doesn't exist
    mkdir -p "$(dirname "$list_file")"
    
    # Add repository
    if echo "$repo_line" | tee "$list_file" >/dev/null; then
        chmod 644 "$list_file"
        log_success "Repository added successfully"
        return 0
    else
        log_error "Failed to add repository"
        return 1
    fi
}

# Update package cache
update_package_cache() {
    log_info "Updating package cache..."
    if apt update; then
        log_success "Package cache updated"
        return 0
    else
        log_error "Failed to update package cache"
        return 1
    fi
}

# ============================================================================
# System Maintenance Functions
# ============================================================================

# Clean up package system
cleanup_packages() {
    log_info "Cleaning up package system..."
    
    # Clean package cache
    apt autoclean -y
    
    # Remove unnecessary packages
    apt autoremove -y
    
    # Fix broken packages
    apt install -y -f
    apt install -y --fix-broken
    apt install -y --fix-missing
    
    log_success "Package system cleanup completed"
}

# Fix broken packages
fix_broken_packages() {
    log_info "Fixing broken packages..."
    
    # Configure any unconfigured packages
    dpkg --configure -a
    
    # Fix broken dependencies
    apt install -y -f
    apt install -y --fix-broken
    apt install -y --fix-missing
    
    log_success "Broken packages fixed"
}

# ============================================================================
# Snap Package Management Functions
# ============================================================================

# Install snapd if not available
ensure_snapd_available() {
    if ! check_command_available snap; then
        log_info "Installing snapd..."
        if apt install -y snapd; then
            # Enable and start snapd service
            systemctl enable snapd 2>/dev/null || true
            systemctl start snapd 2>/dev/null || true
            log_success "snapd installed and started"
            return 0
        else
            log_error "Failed to install snapd"
            return 1
        fi
    else
        log_info "snapd already available"
        return 0
    fi
}

# Install snap package
# Usage: install_snap_package package_name [--classic]
install_snap_package() {
    local package="$1"
    local flags="$2"
    
    # Ensure snapd is available
    if ! ensure_snapd_available; then
        return 1
    fi
    
    log_info "Installing snap package: $package $flags"
    
    if snap install $flags "$package"; then
        log_success "Snap package '$package' installed"
        return 0
    else
        log_error "Failed to install snap package '$package'"
        return 1
    fi
}

# ============================================================================
# Debian Package (.deb) Management Functions
# ============================================================================

# Install .deb package from URL
# Usage: install_deb_from_url url [temp_filename]
install_deb_from_url() {
    local url="$1"
    local temp_file="${2:-/tmp/package.deb}"
    
    log_info "Downloading and installing .deb package from $url"
    
    # Download the package
    if wget "$url" -O "$temp_file"; then
        log_success "Package downloaded"
        
        # Install the package
        if dpkg -i "$temp_file" || apt install -f -y; then
            log_success "Package installed successfully"
            rm -f "$temp_file"
            return 0
        else
            log_error "Failed to install package"
            rm -f "$temp_file"
            return 1
        fi
    else
        log_error "Failed to download package from $url"
        return 1
    fi
}

# ============================================================================
# Package Information Functions
# ============================================================================

# Get installed package version
get_package_version() {
    local package="$1"
    
    if check_package_installed "$package"; then
        dpkg -l "$package" 2>/dev/null | grep "^ii" | awk '{print $3}'
    else
        return 1
    fi
}

# List installed packages matching pattern
list_installed_packages() {
    local pattern="$1"
    
    if [ -n "$pattern" ]; then
        dpkg -l | grep "^ii" | grep "$pattern" | awk '{print $2}'
    else
        dpkg -l | grep "^ii" | awk '{print $2}'
    fi
}

# Check if package repository is configured
check_repository_configured() {
    local repo_identifier="$1"
    
    # Check in sources.list and sources.list.d
    if grep -r "$repo_identifier" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -v "^#" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Validation Functions
# ============================================================================

# Validate critical packages are installed
validate_critical_packages() {
    local packages=("$@")
    local missing_packages=()
    
    log_info "Validating critical packages..."
    
    for pkg in "${packages[@]}"; do
        if check_command_available "$pkg"; then
            log_success "✓ $pkg is available"
        else
            log_error "✗ $pkg is missing"
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        log_success "All critical packages are available"
        return 0
    else
        log_error "Missing critical packages: ${missing_packages[*]}"
        return 1
    fi
}

# ============================================================================
# User Management Helper Functions
# ============================================================================

# Get user home directory
get_user_home() {
    local user=$1
    eval echo "~$user"
}

# Check if user exists
check_user_exists() {
    id "$1" &>/dev/null
}

# Check if group exists
check_group_exists() {
    getent group "$1" > /dev/null
}

# ============================================================================
# Module Helper Functions
# ============================================================================

# Install packages for a specific module with logging
# Usage: install_module_packages module_name package1 package2 package3
install_module_packages() {
    local module_name="$1"
    shift
    local packages=("$@")
    
    log_info "[$module_name] Installing packages: ${packages[*]}"
    
    if install_packages_if_missing "${packages[@]}"; then
        log_success "[$module_name] All packages installed successfully"
        return 0
    else
        log_error "[$module_name] Failed to install some packages"
        return 1
    fi
}