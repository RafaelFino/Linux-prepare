#!/usr/bin/env bash

# ============================================================================
# Version Detection Library for Linux-prepare Modular Architecture
# ============================================================================
# This library provides version detection and package mapping utilities
# Handles Ubuntu/Xubuntu version-specific package selection and configuration

# Note: This library assumes logging.sh is already sourced by the calling script

# ============================================================================
# Version Detection Functions
# ============================================================================

# Detect Ubuntu version from /etc/os-release
detect_ubuntu_version() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect Ubuntu version (/etc/os-release not found)"
        return 1
    fi
    
    source /etc/os-release
    echo "$VERSION_ID"
}

# Detect Ubuntu codename from /etc/os-release
detect_ubuntu_codename() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect Ubuntu codename (/etc/os-release not found)"
        return 1
    fi
    
    source /etc/os-release
    
    # Handle case where VERSION_CODENAME might not be set
    if [ -n "${VERSION_CODENAME:-}" ]; then
        echo "$VERSION_CODENAME"
    else
        # Fallback: try to derive codename from VERSION_ID
        case "${VERSION_ID:-}" in
            "20.04")
                echo "focal"
                ;;
            "22.04")
                echo "jammy"
                ;;
            "24.04")
                echo "noble"
                ;;
            "25.10")
                echo "oracular"
                ;;
            *)
                log_warning "Unknown Ubuntu version ${VERSION_ID:-}, cannot determine codename"
                echo "unknown"
                ;;
        esac
    fi
}

# Detect distribution ID
detect_distribution_id() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect distribution ID (/etc/os-release not found)"
        return 1
    fi
    
    source /etc/os-release
    echo "$ID"
}

# Detect full distribution name
detect_distribution_name() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect distribution name (/etc/os-release not found)"
        return 1
    fi
    
    source /etc/os-release
    echo "$PRETTY_NAME"
}

# ============================================================================
# Version Comparison Functions
# ============================================================================

# Compare two version strings
# Usage: version_compare "24.04" "22.04" ">="
# Returns: 0 if comparison is true, 1 if false
version_compare() {
    local version1="$1"
    local version2="$2"
    local operator="$3"
    
    # Convert versions to comparable format (remove dots)
    local v1_num=$(echo "$version1" | tr -d '.')
    local v2_num=$(echo "$version2" | tr -d '.')
    
    # Pad with zeros to ensure same length
    while [ ${#v1_num} -lt ${#v2_num} ]; do
        v1_num="${v1_num}0"
    done
    while [ ${#v2_num} -lt ${#v1_num} ]; do
        v2_num="${v2_num}0"
    done
    
    case "$operator" in
        ">=")
            [ "$v1_num" -ge "$v2_num" ]
            ;;
        "<=")
            [ "$v1_num" -le "$v2_num" ]
            ;;
        ">")
            [ "$v1_num" -gt "$v2_num" ]
            ;;
        "<")
            [ "$v1_num" -lt "$v2_num" ]
            ;;
        "=="|"=")
            [ "$v1_num" -eq "$v2_num" ]
            ;;
        "!=")
            [ "$v1_num" -ne "$v2_num" ]
            ;;
        *)
            log_error "Invalid comparison operator: $operator"
            return 1
            ;;
    esac
}

# ============================================================================
# Package Name Mapping Functions
# ============================================================================

# Get the correct ls replacement package name based on Ubuntu version
# Ubuntu 22.04 and derivatives use "exa"
# Ubuntu 24.04+ and derivatives use "eza"
get_ls_replacement_package() {
    local version=$(detect_ubuntu_version)
    
    if [ -z "$version" ]; then
        log_warning "Could not detect Ubuntu version, defaulting to eza"
        echo "eza"
        return 0
    fi
    
    if version_compare "$version" "24.04" ">="; then
        echo "eza"
    else
        echo "exa"
    fi
}

# Get package name with version-based selection
# Usage: get_package_name_by_version "ls_replacement"
get_package_name_by_version() {
    local component="$1"
    
    case "$component" in
        "ls_replacement")
            get_ls_replacement_package
            ;;
        *)
            log_error "Unknown component for version-based package selection: $component"
            return 1
            ;;
    esac
}

# ============================================================================
# Docker Repository Configuration Functions
# ============================================================================

# Get Docker repository configuration based on Ubuntu version
get_docker_repo_config() {
    local version=$(detect_ubuntu_version)
    local codename=$(detect_ubuntu_codename)
    
    if [ -z "$version" ] || [ -z "$codename" ]; then
        log_warning "Could not detect Ubuntu version/codename for Docker repo config"
        # Fallback to jammy (22.04 LTS)
        echo "jammy"
        return 0
    fi
    
    # Map Ubuntu versions to Docker repository codenames
    case "$version" in
        "20.04")
            echo "focal"
            ;;
        "22.04")
            echo "jammy"
            ;;
        "24.04")
            echo "noble"
            ;;
        "25.10")
            # For 25.10 (oracular), use noble (24.04) as fallback until Docker officially supports it
            log_info "Using Docker repository for Ubuntu 24.04 (noble) as fallback for Ubuntu 25.10 (oracular)"
            echo "noble"
            ;;
        *)
            # For unknown versions, try to use the detected codename
            # If that fails, fallback to latest LTS
            log_warning "Unknown Ubuntu version $version, using codename $codename for Docker repo"
            if [ -n "$codename" ]; then
                echo "$codename"
            else
                log_warning "Falling back to jammy (22.04 LTS) for Docker repository"
                echo "jammy"
            fi
            ;;
    esac
}

# Get full Docker repository configuration string
get_docker_repo_config() {
    local version="$1"
    local codename="$2"
    
    # If no parameters provided, detect them
    if [ -z "$version" ]; then
        version=$(detect_ubuntu_version)
    fi
    if [ -z "$codename" ]; then
        codename=$(detect_ubuntu_codename)
    fi
    
    if [ -z "$version" ] || [ -z "$codename" ]; then
        log_warning "Could not detect Ubuntu version/codename for Docker repo config"
        # Return fallback configuration for Ubuntu 22.04 LTS
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable"
        return 0
    fi
    
    # Get the appropriate Docker repository codename
    local docker_codename
    case "$version" in
        "20.04")
            docker_codename="focal"
            ;;
        "22.04")
            docker_codename="jammy"
            ;;
        "24.04")
            docker_codename="noble"
            ;;
        "25.10")
            # For Ubuntu 25.10 (oracular), use noble (24.04) as fallback
            # This follows Docker's official documentation recommendation
            log_info "Using Docker repository for Ubuntu 24.04 (noble) as fallback for Ubuntu 25.10 (oracular)"
            docker_codename="noble"
            ;;
        *)
            # For unknown versions, try the detected codename first
            # If Docker doesn't support it, this will fail gracefully and allow fallback
            log_warning "Unknown Ubuntu version $version, attempting to use codename $codename for Docker repo"
            docker_codename="$codename"
            ;;
    esac
    
    # Get system architecture
    local arch=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    
    # Return the complete repository configuration
    echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $docker_codename stable"
}

# Get Docker repository codename only (for backward compatibility)
get_docker_repo_codename() {
    local version="$1"
    local codename="$2"
    
    # If no parameters provided, detect them
    if [ -z "$version" ]; then
        version=$(detect_ubuntu_version)
    fi
    if [ -z "$codename" ]; then
        codename=$(detect_ubuntu_codename)
    fi
    
    case "$version" in
        "20.04")
            echo "focal"
            ;;
        "22.04")
            echo "jammy"
            ;;
        "24.04")
            echo "noble"
            ;;
        "25.10")
            echo "noble"  # Fallback to 24.04
            ;;
        *)
            if [ -n "$codename" ] && [ "$codename" != "unknown" ]; then
                echo "$codename"
            else
                echo "jammy"  # Fallback to 22.04 LTS
            fi
            ;;
    esac
}

# Get full Docker repository URL
get_docker_repo_url() {
    echo "https://download.docker.com/linux/ubuntu"
}

# Get Docker GPG key URL
get_docker_gpg_url() {
    echo "https://download.docker.com/linux/ubuntu/gpg"
}

# Check if Docker repository supports the current Ubuntu version
check_docker_repo_support() {
    local version="$1"
    
    if [ -z "$version" ]; then
        version=$(detect_ubuntu_version)
    fi
    
    # List of officially supported Ubuntu versions by Docker
    # Based on https://docs.docker.com/engine/install/ubuntu/
    case "$version" in
        "20.04"|"22.04"|"24.04")
            return 0  # Officially supported
            ;;
        "25.10")
            log_info "Ubuntu 25.10 not yet officially supported by Docker, using Ubuntu 24.04 repository as fallback"
            return 1  # Not officially supported, but fallback available
            ;;
        *)
            log_warning "Ubuntu version $version support unknown, will attempt with fallback"
            return 1  # Unknown support status
            ;;
    esac
}

# ============================================================================
# System Information Functions
# ============================================================================

# Set system-specific environment variables
set_system_environment_vars() {
    local version=$(detect_ubuntu_version)
    local codename=$(detect_ubuntu_codename)
    local id=$(detect_distribution_id)
    
    # Set standard environment variables
    export UBUNTU_VERSION="$version"
    export UBUNTU_CODENAME="$codename"
    export DISTRIBUTION_ID="$id"
    
    # Set version-specific variables
    export LS_REPLACEMENT_PACKAGE=$(get_ls_replacement_package)
    export DOCKER_REPO_CODENAME=$(get_docker_repo_codename "$version" "$codename")
    export DOCKER_REPO_URL=$(get_docker_repo_url)
    export DOCKER_REPO_CONFIG=$(get_docker_repo_config "$version" "$codename")
    
    # Set system type flags
    if is_popos; then
        export IS_POPOS="true"
    else
        export IS_POPOS="false"
    fi
    
    if is_xubuntu; then
        export IS_XUBUNTU="true"
        
        # Xubuntu 25.10 specific environment variables
        if [[ "$version" == "25.10" ]]; then
            export XUBUNTU_25_10="true"
            export EXPECTED_DESKTOP="XFCE"
            log_info "Xubuntu 25.10 environment variables set"
        else
            export XUBUNTU_25_10="false"
        fi
    else
        export IS_XUBUNTU="false"
        export XUBUNTU_25_10="false"
    fi
    
    if is_ubuntu_based; then
        export IS_UBUNTU_BASED="true"
    else
        export IS_UBUNTU_BASED="false"
    fi
    
    if is_debian_based; then
        export IS_DEBIAN_BASED="true"
    else
        export IS_DEBIAN_BASED="false"
    fi
    
    log_info "System environment variables configured"
}

# Check if system is Pop!_OS
is_popos() {
    local id=$(detect_distribution_id)
    local name=$(detect_distribution_name)
    
    [[ "$id" == "pop" ]] || [[ "$name" == *"Pop!_OS"* ]]
}

# Check if system is Xubuntu
is_xubuntu() {
    local name=$(detect_distribution_name)
    [[ "$name" == *"Xubuntu"* ]]
}

# Check if system is Ubuntu-based
is_ubuntu_based() {
    if [ ! -f /etc/os-release ]; then
        return 1
    fi
    
    source /etc/os-release
    [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "pop" ]] || [[ "$ID_LIKE" == *"ubuntu"* ]]
}

# Check if system is Debian-based
is_debian_based() {
    if [ ! -f /etc/os-release ]; then
        return 1
    fi
    
    source /etc/os-release
    [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "pop" ]] || [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID_LIKE" == *"ubuntu"* ]]
}

# ============================================================================
# Validation Functions
# ============================================================================

# Validate Ubuntu 25.10 specific configuration
validate_ubuntu_25_10() {
    local version=$(detect_ubuntu_version)
    local codename=$(detect_ubuntu_codename)
    
    if [[ "$version" != "25.10" ]]; then
        return 0  # Not Ubuntu 25.10, no validation needed
    fi
    
    log_info "Validating Ubuntu 25.10 configuration..."
    
    # Check codename
    if [[ "$codename" == "oracular" ]] || [[ "$codename" == "unknown" ]]; then
        log_success "Ubuntu 25.10 codename validation passed: $codename"
    else
        log_warning "Unexpected codename for Ubuntu 25.10: $codename (expected: oracular)"
    fi
    
    # Validate package availability expectations
    log_info "Ubuntu 25.10 should use 'eza' package for ls replacement"
    local ls_package=$(get_ls_replacement_package)
    if [[ "$ls_package" == "eza" ]]; then
        log_success "Correct ls replacement package selected: $ls_package"
    else
        log_warning "Unexpected ls replacement package: $ls_package (expected: eza)"
    fi
    
    # Validate Docker repository configuration
    local docker_repo_codename=$(get_docker_repo_codename "$version" "$codename")
    if [[ "$docker_repo_codename" == "noble" ]]; then
        log_success "Docker repository fallback configured correctly: $docker_repo_codename"
    else
        log_warning "Unexpected Docker repository configuration: $docker_repo_codename"
    fi
    
    return 0
}

# Validate that we're running on a supported system
validate_system_compatibility() {
    if ! is_debian_based; then
        local name=$(detect_distribution_name)
        log_error "Unsupported distribution: $name"
        log_error "This script only supports Debian-based distributions (Debian, Ubuntu, Mint, Pop!_OS, etc.)"
        return 1
    fi
    
    # Additional validation for Ubuntu 25.10
    local version=$(detect_ubuntu_version)
    if [[ "$version" == "25.10" ]]; then
        validate_ubuntu_25_10
    fi
    
    return 0
}

# Print system information summary
print_system_info() {
    local version=$(detect_ubuntu_version)
    local codename=$(detect_ubuntu_codename)
    local name=$(detect_distribution_name)
    local id=$(detect_distribution_id)
    
    log_info "System Information:"
    log_info "  Distribution: $name"
    log_info "  ID: $id"
    log_info "  Version: $version"
    log_info "  Codename: $codename"
    
    # Show version-specific package selections
    local ls_package=$(get_ls_replacement_package)
    local docker_repo_codename=$(get_docker_repo_codename "$version" "$codename")
    
    log_info "Version-specific configurations:"
    log_info "  LS replacement package: $ls_package"
    log_info "  Docker repository codename: $docker_repo_codename"
    
    # Show system type flags
    if is_popos; then
        log_info "  Pop!_OS detected: Special handling enabled"
    fi
    
    if is_xubuntu; then
        log_info "  Xubuntu detected: XFCE desktop environment expected"
        
        # Special message for Xubuntu 25.10
        if [[ "$version" == "25.10" ]]; then
            log_success "  Xubuntu 25.10 detected: Full support enabled"
            log_info "  Expected desktop: XFCE"
            log_info "  Package selection: Modern packages (eza, noble Docker repo fallback)"
        fi
    fi
    
    # Show Ubuntu 25.10 specific information
    if [[ "$version" == "25.10" ]]; then
        local docker_repo_codename=$(get_docker_repo_codename "$version" "$codename")
        log_info "Ubuntu 25.10 specific configuration:"
        log_info "  Codename: $codename"
        log_info "  Docker repository fallback: $docker_repo_codename (using Ubuntu 24.04 repo)"
        log_info "  Package compatibility: Modern package selection enabled"
    fi
}