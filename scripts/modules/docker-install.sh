#!/usr/bin/env bash

# ============================================================================
# Docker Installation Module
# ============================================================================
# This module handles Docker and Docker Compose installation with version-
# specific repository configuration and proper error handling.
# ============================================================================

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/version-detection.sh"
source "$SCRIPT_DIR/../lib/package-utils.sh"

MODULE_NAME="docker-install"

# ============================================================================
# Docker Repository Configuration
# ============================================================================

configure_docker_repository() {
    local ubuntu_version="$1"
    local ubuntu_codename="$2"
    
    log_info "Configuring Docker repository for Ubuntu $ubuntu_version ($ubuntu_codename)"
    
    # Get Docker repository configuration based on version
    local docker_repo_config=$(get_docker_repo_config "$ubuntu_version" "$ubuntu_codename")
    
    if [ -z "$docker_repo_config" ]; then
        log_error "No Docker repository configuration available for Ubuntu $ubuntu_version"
        return 1
    fi
    
    # Remove any existing Docker repository configuration
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/keyrings/docker.gpg
    
    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    mkdir -p /etc/apt/keyrings
    if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        chmod a+r /etc/apt/keyrings/docker.gpg
        log_success "Docker GPG key added"
    else
        log_error "Failed to add Docker GPG key"
        return 1
    fi
    
    # Add Docker repository
    log_info "Adding Docker repository: $docker_repo_config"
    echo "$docker_repo_config" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list
    log_info "Updating package list with Docker repository..."
    if apt update; then
        log_success "Package list updated with Docker repository"
        return 0
    else
        log_error "Failed to update package list with Docker repository"
        return 1
    fi
}

# ============================================================================
# Docker Installation Functions
# ============================================================================

install_docker_engine() {
    log_info "Installing Docker Engine and related packages..."
    
    # Docker packages to install
    local docker_packages=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-buildx-plugin"
        "docker-compose-plugin"
    )
    
    # Install Docker packages
    if install_packages_safe "${docker_packages[@]}"; then
        log_success "Docker packages installed successfully"
        return 0
    else
        log_error "Failed to install Docker packages"
        return 1
    fi
}

install_docker_popos() {
    log_info "Pop!_OS detected - using System76 recommended Docker installation method"
    
    # Remove conflicting packages
    log_info "Removing conflicting Docker packages..."
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Update package list
    apt update
    
    # Install from Pop!_OS repos (they maintain docker.io)
    log_info "Installing docker.io and docker-compose from Pop!_OS repositories..."
    if apt install -y docker.io docker-compose; then
        log_success "Docker and Docker Compose installed from Pop!_OS repos"
        return 0
    else
        log_error "Failed to install Docker on Pop!_OS"
        return 1
    fi
}

install_docker_fallback() {
    log_info "Using fallback Docker installation method..."
    
    # Install docker.io package as fallback
    log_info "Installing docker.io package..."
    if ! install_packages_safe docker.io; then
        log_error "Failed to install docker.io"
        return 1
    fi
    
    # Install docker-compose with fallback to v1
    local compose_package=$(install_package_with_fallback "docker-compose-v2" "docker-compose")
    if [ -n "$compose_package" ]; then
        log_success "Docker Compose installed: $compose_package"
        
        # If v1 was installed, create alias for v2 syntax
        if [ "$compose_package" = "docker-compose" ]; then
            log_info "Creating 'docker compose' alias for docker-compose v1"
            # This will be handled in shell configuration
        fi
    else
        log_warning "Docker Compose not available in this distribution"
    fi
    
    return 0
}

configure_docker_service() {
    log_info "Configuring Docker service..."
    
    # Create docker group if it doesn't exist
    if ! check_group_exists docker; then
        log_info "Creating docker group"
        groupadd docker
    fi
    
    # Enable and start Docker service
    log_info "Enabling Docker service..."
    if systemctl enable docker && systemctl start docker; then
        log_success "Docker service enabled and started"
        return 0
    else
        log_error "Failed to enable/start Docker service"
        return 1
    fi
}

validate_docker_installation() {
    log_info "Validating Docker installation..."
    
    # Check if docker command is available
    if ! check_command_available docker; then
        log_error "Docker command not found after installation"
        return 1
    fi
    
    # Show Docker version
    local docker_version=$(docker --version)
    log_success "Docker installed: $docker_version"
    
    # Check Docker Compose
    if docker compose version &>/dev/null; then
        local compose_version=$(docker compose version)
        log_success "Docker Compose installed: $compose_version"
    else
        log_warning "Docker Compose v2 not available"
        
        # Check for docker-compose v1
        if check_command_available docker-compose; then
            local compose_v1_version=$(docker-compose --version)
            log_info "Docker Compose v1 available: $compose_v1_version"
        fi
    fi
    
    return 0
}

# ============================================================================
# Rollback Functions
# ============================================================================

rollback_docker_installation() {
    log_warning "Rolling back Docker installation..."
    
    # Stop Docker service
    systemctl stop docker 2>/dev/null || true
    systemctl disable docker 2>/dev/null || true
    
    # Remove Docker packages
    apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt remove -y docker.io docker-compose docker-compose-v2 2>/dev/null || true
    
    # Remove repository configuration
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/keyrings/docker.gpg
    
    # Update package list
    apt update
    
    log_info "Docker installation rollback completed"
}

# ============================================================================
# Main Installation Function
# ============================================================================

install_docker() {
    log_info "Starting Docker installation..."
    
    # Check if already installed
    if check_command_available docker && check_command_available "docker compose"; then
        log_skip "Docker and Docker Compose already installed"
        validate_docker_installation
        return 0
    fi
    
    # Detect system information
    local ubuntu_version=$(detect_ubuntu_version)
    local ubuntu_codename=$(detect_ubuntu_codename)
    
    log_info "Detected Ubuntu version: $ubuntu_version ($ubuntu_codename)"
    
    # Set up error handling with rollback
    trap 'rollback_docker_installation' ERR
    
    # Pop!_OS specific handling
    if detect_popos; then
        if install_docker_popos; then
            configure_docker_service
            validate_docker_installation
            trap - ERR  # Remove error trap on success
            return 0
        else
            log_error "Pop!_OS Docker installation failed"
            return 1
        fi
    fi
    
    # Try official Docker repository first
    if configure_docker_repository "$ubuntu_version" "$ubuntu_codename"; then
        if install_docker_engine; then
            configure_docker_service
            validate_docker_installation
            trap - ERR  # Remove error trap on success
            return 0
        else
            log_warning "Official Docker repository installation failed, trying fallback"
        fi
    else
        log_warning "Docker repository configuration failed, trying fallback"
    fi
    
    # Fallback to distribution packages
    if install_docker_fallback; then
        configure_docker_service
        validate_docker_installation
        trap - ERR  # Remove error trap on success
        return 0
    else
        log_error "All Docker installation methods failed"
        return 1
    fi
}

# ============================================================================
# Module Entry Point
# ============================================================================

module_main() {
    log_info "Starting $MODULE_NAME module"
    
    # Check if Docker installation is enabled
    if [ "${INSTALL_DOCKER:-true}" != "true" ]; then
        log_skip "Docker installation skipped (--skip-docker)"
        return 0
    fi
    
    # Install Docker
    if install_docker; then
        log_success "$MODULE_NAME module completed successfully"
        return 0
    else
        log_error "$MODULE_NAME module failed"
        return 1
    fi
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    module_main "$@"
fi