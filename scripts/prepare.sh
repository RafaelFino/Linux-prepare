#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Linux Development Environment Setup Script
# ============================================================================
# This script prepares a fresh Linux installation for development work.
# By default, it installs ALL development components (Docker, Go, Python, 
# Kotlin, JVM, .NET, terminal tools, shell configurations).
# Desktop components are opt-in via --desktop flag.
# Use --skip-* flags to exclude specific components.
# ============================================================================

# ANSI Color Codes
BOLD="\033[1m"
RESET="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
GRAY="\033[90m"

# Symbols
SYMBOL_INFO="ℹ"
SYMBOL_SUCCESS="✓"
SYMBOL_ERROR="✗"
SYMBOL_WARNING="⚠"
SYMBOL_SKIP="⏭"

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${CYAN}[${timestamp}] ${SYMBOL_INFO}${RESET} ${msg}"
}

log_success() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${GREEN}[${timestamp}] ${SYMBOL_SUCCESS}${RESET} ${msg}"
}

log_error() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${RED}[${timestamp}] ${SYMBOL_ERROR}${RESET} ${msg}" >&2
}

log_warning() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${YELLOW}[${timestamp}] ${SYMBOL_WARNING}${RESET} ${msg}"
}

log_skip() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${GRAY}[${timestamp}] ${SYMBOL_SKIP}${RESET} ${msg}"
}


# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║          Linux Development Environment Setup Script                        ║
╚════════════════════════════════════════════════════════════════════════════╝

PURPOSE:
  Prepares a fresh Linux installation (Debian/Ubuntu-based) as a complete
  development environment with modern tools, multiple programming languages,
  and optimized terminal configurations.

DEFAULT BEHAVIOR:
  By default, installs ALL development components:
  - Docker & Docker Compose v2
  - Golang (latest version)
  - Python 3 with pip and virtualenv
  - Kotlin via SDKMAN
  - JVM (Java) via SDKMAN
  - .NET SDK 8.0
  - Modern terminal tools (eza, micro, zsh, oh-my-zsh, oh-my-bash)
  - Vim with awesome vimrc
  
  Desktop components (VSCode, Chrome, fonts, terminal emulators):
  - AUTO-DETECTED: Installed automatically if desktop environment is detected
  - Detects: GNOME, KDE, XFCE, MATE, Cinnamon, LXDE, X11, Wayland
  - Skipped automatically on servers/headless systems

USAGE:
  sudo ./prepare.sh [OPTIONS]

OPTIONS:
  -u=USER1,USER2    Create and configure specified users (comma-separated)
                    Note: root and current user are always configured
  
  --skip-docker     Skip Docker and Docker Compose installation
  --skip-go         Skip Golang installation
  --skip-python     Skip Python installation
  --skip-kotlin     Skip Kotlin installation
  --skip-jvm        Skip JVM (Java) installation
  --skip-dotnet     Skip .NET SDK installation
  
  -h, --help        Show this help message

NOTE: Desktop components (VSCode, Chrome, fonts, terminal emulators) are
      automatically installed if a desktop environment is detected.

SUPPORTED DISTRIBUTIONS:
  - Ubuntu (20.04, 22.04, 24.04)
  - Debian (11, 12)
  - Linux Mint
  - Other Debian-based distributions

EXAMPLES:
  1. Full installation (desktop auto-detected):
     sudo ./prepare.sh

  2. Server setup without Docker:
     sudo ./prepare.sh --skip-docker

  3. Minimal setup (only base tools and terminal configuration):
     sudo ./prepare.sh --skip-docker --skip-go --skip-python --skip-kotlin --skip-jvm --skip-dotnet

  4. Create multiple users:
     sudo ./prepare.sh -u=developer,devops

  5. Workstation without .NET and Kotlin:
     sudo ./prepare.sh --skip-dotnet --skip-kotlin

  6. Go and Python only (skip other languages):
     sudo ./prepare.sh --skip-kotlin --skip-jvm --skip-dotnet

  7. Docker and Go development environment:
     sudo ./prepare.sh --skip-python --skip-kotlin --skip-jvm --skip-dotnet

WHAT GETS INSTALLED:
  Base Packages:
    wget, git, zsh, gpg, zip, unzip, vim, jq, telnet, curl, htop, btop,
    python3, python3-pip, eza, micro, apt-transport-https, zlib1g,
    sqlite3, fzf, sudo

  Terminal Configuration:
    - Zsh set as default shell
    - Oh-My-Zsh with 'frisk' theme and extensive plugins
    - Oh-My-Bash with optimized configuration
    - Vim with awesome vimrc
    - Micro editor as default EDITOR
    - eza aliases replacing ls (with icons and tree view)

  Desktop Components (--desktop flag):
    - VSCode (via snap)
    - Google Chrome
    - Terminator terminal emulator
    - Alacritty terminal emulator
    - Powerline fonts
    - Nerd Fonts (FiraCode, JetBrainsMono, Hack)
    - MS Core Fonts

SYSTEM CONFIGURATION:
  - Timezone: America/Sao_Paulo
  - Default shell: Zsh
  - Default editor: micro
  - All users added to sudo group
  - Docker users added to docker group

NOTES:
  - Script is idempotent (can be run multiple times safely)
  - Requires root/sudo privileges
  - Requires internet connection
  - Execution time: 10-30 minutes depending on components

For more information, visit:
  https://github.com/RafaelFino/Linux-prepare

EOF
}


# ============================================================================
# State Detection Functions (for Idempotency)
# ============================================================================

check_command_available() {
    command -v "$1" &> /dev/null
}

check_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

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
            log_error "Failed to install fallback '$fallback'"
        fi
    else
        log_warning "Neither '$primary' nor '$fallback' are available"
        return 1
    fi
    
    echo "$installed_package"
    return 0
}

check_user_exists() {
    id "$1" &>/dev/null
}

check_group_exists() {
    getent group "$1" > /dev/null
}

check_file_exists() {
    [ -f "$1" ]
}

check_directory_exists() {
    [ -d "$1" ]
}

check_alias_exists() {
    local alias_name="$1"
    local file="$2"
    [ -f "$file" ] && grep -q "alias $alias_name=" "$file"
}

check_service_enabled() {
    systemctl is-enabled "$1" &>/dev/null
}

# ============================================================================
# Distribution Detection
# ============================================================================

detect_distribution() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect Linux distribution (/etc/os-release not found)"
        exit 1
    fi
    
    source /etc/os-release
    
    # Check if it's Debian-based
    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID_LIKE" == *"ubuntu"* ]]; then
        log_success "Detected Debian-based distribution: $PRETTY_NAME"
        
        # Verify apt is available
        if ! check_command_available apt; then
            log_error "apt command not found. This script requires a Debian-based distribution."
            exit 1
        fi
        
        return 0
    else
        log_error "Unsupported distribution: $PRETTY_NAME"
        log_error "This script only supports Debian-based distributions (Debian, Ubuntu, Mint, etc.)"
        exit 1
    fi
}

# ============================================================================
# Desktop Environment Detection
# ============================================================================

detect_desktop_environment() {
    log_info "Detecting desktop environment..."
    
    # Check if running in a graphical environment
    local has_desktop=false
    local desktop_type="none"
    
    # Method 1: Check if DISPLAY is set (X11)
    if [ -n "${DISPLAY:-}" ]; then
        has_desktop=true
        log_info "X11 display detected: $DISPLAY"
    fi
    
    # Method 2: Check if XDG_CURRENT_DESKTOP is set
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        has_desktop=true
        desktop_type="$XDG_CURRENT_DESKTOP"
        log_info "Desktop environment detected: $desktop_type"
    fi
    
    # Method 3: Check for common desktop environment processes
    if pgrep -x "gnome-shell" > /dev/null; then
        has_desktop=true
        desktop_type="GNOME"
        log_info "GNOME desktop detected"
    elif pgrep -x "plasmashell" > /dev/null; then
        has_desktop=true
        desktop_type="KDE Plasma"
        log_info "KDE Plasma desktop detected"
    elif pgrep -x "xfce4-session" > /dev/null; then
        has_desktop=true
        desktop_type="XFCE"
        log_info "XFCE desktop detected"
    elif pgrep -x "mate-session" > /dev/null; then
        has_desktop=true
        desktop_type="MATE"
        log_info "MATE desktop detected"
    elif pgrep -x "cinnamon-session" > /dev/null; then
        has_desktop=true
        desktop_type="Cinnamon"
        log_info "Cinnamon desktop detected"
    elif pgrep -x "lxsession" > /dev/null; then
        has_desktop=true
        desktop_type="LXDE"
        log_info "LXDE desktop detected"
    fi
    
    # Method 4: Check if systemd graphical target is active
    if systemctl is-active graphical.target &>/dev/null; then
        has_desktop=true
        log_info "Systemd graphical target is active"
    fi
    
    # Method 5: Check for X11 or Wayland
    if [ -S /tmp/.X11-unix/X0 ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        has_desktop=true
        if [ -n "${WAYLAND_DISPLAY:-}" ]; then
            log_info "Wayland display detected: $WAYLAND_DISPLAY"
        fi
    fi
    
    # Return result
    if [ "$has_desktop" = true ]; then
        log_success "Desktop environment detected: $desktop_type"
        return 0
    else
        log_info "No desktop environment detected (server/headless mode)"
        return 1
    fi
}

# ============================================================================
# Privilege Check
# ============================================================================

check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        if check_command_available sudo; then
            log_info "Re-running script with sudo privileges..."
            exec sudo -E bash "$0" "$@"
        else
            log_error "This script must be run as root or with sudo privileges"
            log_error "sudo is not installed. Please run as root or install sudo first"
            exit 1
        fi
    fi
}


# ============================================================================
# Argument Parsing
# ============================================================================

# Default configuration: install everything except desktop
INSTALL_DOCKER=true
INSTALL_GO=true
INSTALL_PYTHON=true
INSTALL_KOTLIN=true
INSTALL_JVM=true
INSTALL_DOTNET=true
INSTALL_DESKTOP=false

# Users to configure
USERS_TO_CONFIGURE=()

parse_arguments() {
    # Parse arguments first
    for arg in "$@"; do
        case $arg in
            -h|--help)
                show_help
                exit 0
                ;;
            -u=*|--users=*)
                local users_arg="${arg#*=}"
                IFS=',' read -ra extra_users <<< "$users_arg"
                USERS_TO_CONFIGURE+=("${extra_users[@]}")
                log_info "Will configure additional users: ${extra_users[*]}"
                ;;
            --skip-docker)
                INSTALL_DOCKER=false
                log_warning "Skipping Docker installation"
                ;;
            --skip-go)
                INSTALL_GO=false
                log_warning "Skipping Golang installation"
                ;;
            --skip-python)
                INSTALL_PYTHON=false
                log_warning "Skipping Python installation"
                ;;
            --skip-kotlin)
                INSTALL_KOTLIN=false
                log_warning "Skipping Kotlin installation"
                ;;
            --skip-jvm)
                INSTALL_JVM=false
                log_warning "Skipping JVM installation"
                ;;
            --skip-dotnet)
                INSTALL_DOTNET=false
                log_warning "Skipping .NET installation"
                ;;
            *)
                log_error "Unknown argument: $arg"
                log_error "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Auto-detect desktop environment (always)
    if detect_desktop_environment; then
        INSTALL_DESKTOP=true
        log_success "Desktop environment detected - desktop components will be installed automatically"
    else
        INSTALL_DESKTOP=false
        log_info "No desktop environment detected - desktop components will NOT be installed"
    fi
    
    # Show configuration summary
    if [ $# -eq 0 ]; then
        log_info "No arguments provided. Using default configuration:"
        log_info "  - Installing all development components"
        log_info "  - Desktop components: $([ "$INSTALL_DESKTOP" = true ] && echo "YES (auto-detected)" || echo "NO (server mode)")"
        log_info "  - Configuring users: root, $(whoami)"
    fi
}

# ============================================================================
# User Management
# ============================================================================

run_as() {
    local user=$1
    shift
    log_info "Running command as $user: $*"
    sudo -u "$user" bash -c "$*"
}

get_user_home() {
    local user=$1
    eval echo "~$user"
}

setup_users_list() {
    # Always configure root and current user
    local current_user=$(whoami)
    if [ "$current_user" == "root" ]; then
        current_user=$(logname 2>/dev/null || echo "root")
    fi
    
    ALL_USERS=("root")
    
    # Add current user if not root
    if [ "$current_user" != "root" ]; then
        ALL_USERS+=("$current_user")
    fi
    
    # Add users from -u= argument
    for user in "${USERS_TO_CONFIGURE[@]}"; do
        if [[ ! " ${ALL_USERS[@]} " =~ " ${user} " ]]; then
            ALL_USERS+=("$user")
        fi
    done
    
    log_info "Users to be configured: ${ALL_USERS[*]}"
}


create_user_if_needed() {
    local user=$1
    
    if check_user_exists "$user"; then
        log_skip "User $user already exists"
        return 0
    fi
    
    log_info "Creating user: $user"
    
    # Create user with interactive password prompt
    if adduser --gecos "" "$user"; then
        log_success "User $user created successfully"
    else
        log_error "Failed to create user $user"
        return 1
    fi
}

add_user_to_sudo() {
    local user=$1
    
    # Skip root
    if [ "$user" == "root" ]; then
        return 0
    fi
    
    # Check if user is already in sudo group
    if groups "$user" | grep -q "\bsudo\b"; then
        log_skip "User $user already in sudo group"
        return 0
    fi
    
    log_info "Adding user $user to sudo group"
    
    # Create sudo group if it doesn't exist
    if ! check_group_exists sudo; then
        log_info "Creating sudo group"
        groupadd sudo
    fi
    
    if usermod -aG sudo "$user"; then
        log_success "User $user added to sudo group"
    else
        log_error "Failed to add user $user to sudo group"
        return 1
    fi
}

add_user_to_docker() {
    local user=$1
    
    # Only add if Docker is being installed
    if [ "$INSTALL_DOCKER" != "true" ]; then
        return 0
    fi
    
    # Check if user is already in docker group
    if groups "$user" 2>/dev/null | grep -q "\bdocker\b"; then
        log_skip "User $user already in docker group"
        return 0
    fi
    
    log_info "Adding user $user to docker group"
    
    # Create docker group if it doesn't exist
    if ! check_group_exists docker; then
        log_info "Creating docker group"
        groupadd docker
    fi
    
    if usermod -aG docker "$user"; then
        log_success "User $user added to docker group"
    else
        log_warning "Failed to add user $user to docker group"
        return 1
    fi
}


# ============================================================================
# Base Installation
# ============================================================================

configure_timezone() {
    log_info "Configuring timezone to America/Sao_Paulo"
    
    # Method 1: Update /etc/timezone
    echo "America/Sao_Paulo" | tee /etc/timezone > /dev/null
    
    # Method 2: Use timedatectl if available (systemd)
    if check_command_available timedatectl; then
        timedatectl set-timezone America/Sao_Paulo 2>/dev/null || true
    fi
    
    # Method 3: Create symlink
    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    
    # Validate
    local current_tz=$(date +%Z)
    log_success "Timezone configured: $current_tz ($(date))"
}

install_eza() {
    log_info "Installing eza (modern ls replacement)..."
    
    # Check if eza or exa is already installed
    if check_command_available eza; then
        log_skip "eza already installed"
        return 0
    fi
    
    if check_command_available exa; then
        log_skip "exa already installed (alternative to eza)"
        return 0
    fi
    
    # Try to add eza repository and install
    log_info "Adding eza repository..."
    if mkdir -p /etc/apt/keyrings && \
       wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null && \
       echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list >/dev/null && \
       chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null; then
        
        apt update
        
        # Try to install eza with fallback to exa
        local ls_package=$(install_package_with_fallback "eza" "exa")
        if [ -n "$ls_package" ]; then
            log_success "Installed $ls_package successfully"
            return 0
        fi
    else
        log_warning "Failed to add eza repository, trying to install exa from default repos"
        
        # Try exa from default repositories
        if check_package_available "exa"; then
            if apt install -y exa; then
                log_success "Installed exa successfully (fallback)"
                return 0
            fi
        fi
    fi
    
    log_error "Failed to install eza or exa"
    return 1
}

install_base_packages() {
    log_info "Installing base packages..."
    
    # Update package list
    log_info "Updating package list..."
    apt update -y
    
    # List of base packages (without eza - will be installed separately)
    local packages=(
        wget git zsh gpg zip unzip vim jq telnet curl htop btop
        python3 python3-pip micro apt-transport-https zlib1g
        sqlite3 fzf sudo ca-certificates gnupg
    )
    
    # Check which packages need to be installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if check_package_installed "$pkg"; then
            log_skip "Package $pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done
    
    # Install missing packages
    if [ ${#to_install[@]} -gt 0 ]; then
        log_info "Installing packages: ${to_install[*]}"
        if apt install -y "${to_install[@]}"; then
            log_success "Base packages installed successfully"
        else
            log_error "Failed to install some base packages"
            return 1
        fi
    else
        log_skip "All base packages already installed"
    fi
    
    # Install eza separately (requires special repository)
    install_eza
    
    # Validate critical packages
    local critical_commands=(git zsh vim curl wget python3 eza micro)
    for cmd in "${critical_commands[@]}"; do
        if check_command_available "$cmd"; then
            log_success "Validated: $cmd is available"
        else
            log_error "Critical command not available: $cmd"
            return 1
        fi
    done
}


# ============================================================================
# Docker Installation
# ============================================================================

install_docker() {
    if [ "$INSTALL_DOCKER" != "true" ]; then
        log_skip "Docker installation skipped (--skip-docker)"
        return 0
    fi
    
    log_info "Installing Docker and Docker Compose..."
    
    # Check if already installed
    if check_command_available docker && check_command_available "docker compose"; then
        log_skip "Docker and Docker Compose already installed"
        docker --version
        docker compose version
        return 0
    fi
    
    # Install docker.io
    log_info "Installing docker.io package..."
    if ! install_packages_safe docker.io; then
        log_error "Failed to install docker.io"
        log_error "Docker installation failed"
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
    
    # Create docker group if it doesn't exist
    if ! check_group_exists docker; then
        log_info "Creating docker group"
        groupadd docker
    fi
    
    # Enable and start Docker service
    log_info "Enabling Docker service..."
    systemctl enable docker
    systemctl start docker
    
    # Validate installation
    if check_command_available docker; then
        docker --version
        log_success "Docker installed successfully"
    else
        log_error "Docker installation failed"
        return 1
    fi
    
    if docker compose version &>/dev/null; then
        docker compose version
        log_success "Docker Compose v2 installed successfully"
    else
        log_warning "Docker Compose v2 not available (package may not exist in this distribution)"
        log_info "Docker is installed and functional. You can install docker-compose separately if needed."
    fi
}

# ============================================================================
# Golang Installation
# ============================================================================

install_golang() {
    if [ "$INSTALL_GO" != "true" ]; then
        log_skip "Golang installation skipped (--skip-go)"
        return 0
    fi
    
    log_info "Installing Golang..."
    
    # Check if already installed
    if check_command_available go; then
        local go_version=$(go version)
        log_skip "Golang already installed: $go_version"
        return 0
    fi
    
    # Get latest version
    log_info "Fetching latest Golang version..."
    local latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
    local arch=$(dpkg --print-architecture)
    local download_url="https://go.dev/dl/${latest_version}.linux-${arch}.tar.gz"
    
    log_info "Downloading Golang ${latest_version} for ${arch}..."
    if wget "$download_url" -O /tmp/golang.tar.gz; then
        log_success "Golang downloaded"
    else
        log_error "Failed to download Golang"
        return 1
    fi
    
    # Extract to /usr/local
    log_info "Extracting Golang to /usr/local..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/golang.tar.gz
    rm /tmp/golang.tar.gz
    
    # Add to PATH in /etc/profile
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        log_info "Adding Golang to system PATH..."
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    # Validate installation
    if /usr/local/go/bin/go version &>/dev/null; then
        /usr/local/go/bin/go version
        log_success "Golang installed successfully"
    else
        log_error "Golang installation failed"
        return 1
    fi
}


# ============================================================================
# Python Installation
# ============================================================================

install_python() {
    if [ "$INSTALL_PYTHON" != "true" ]; then
        log_skip "Python installation skipped (--skip-python)"
        return 0
    fi
    
    log_info "Installing Python development tools..."
    
    # Python3 and pip are already in base packages
    # Install additional tools
    local python_packages=(python3-venv python3-dev)
    local to_install=()
    
    for pkg in "${python_packages[@]}"; do
        if check_package_installed "$pkg"; then
            log_skip "Package $pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log_info "Installing Python packages: ${to_install[*]}"
        apt install -y "${to_install[@]}"
    fi
    
    # Validate
    if check_command_available python3 && check_command_available pip3; then
        python3 --version
        pip3 --version
        log_success "Python installed successfully"
    else
        log_error "Python installation failed"
        return 1
    fi
}

# ============================================================================
# .NET Installation
# ============================================================================

install_dotnet() {
    if [ "$INSTALL_DOTNET" != "true" ]; then
        log_skip ".NET installation skipped (--skip-dotnet)"
        return 0
    fi
    
    log_info "Installing .NET SDK..."
    
    # Check if already installed
    if check_command_available dotnet; then
        local dotnet_version=$(dotnet --version)
        log_skip ".NET already installed: $dotnet_version"
        return 0
    fi
    
    # Get Ubuntu/Debian version
    source /etc/os-release
    local version_id=$VERSION_ID
    
    # Download Microsoft package repository configuration
    log_info "Adding Microsoft package repository..."
    local pkg_url="https://packages.microsoft.com/config/ubuntu/${version_id}/packages-microsoft-prod.deb"
    
    if wget "$pkg_url" -O /tmp/packages-microsoft-prod.deb 2>/dev/null; then
        dpkg -i /tmp/packages-microsoft-prod.deb
        rm /tmp/packages-microsoft-prod.deb
    else
        log_warning "Could not add Microsoft repository for version ${version_id}, trying generic..."
        wget "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
        dpkg -i /tmp/packages-microsoft-prod.deb
        rm /tmp/packages-microsoft-prod.deb
    fi
    
    # Update and install
    apt update
    log_info "Installing dotnet-sdk-8.0..."
    if apt install -y dotnet-sdk-8.0; then
        log_success ".NET SDK installed"
    else
        log_error "Failed to install .NET SDK"
        return 1
    fi
    
    # Validate
    if check_command_available dotnet; then
        dotnet --version
        log_success ".NET installed successfully"
    else
        log_error ".NET installation failed"
        return 1
    fi
}


# ============================================================================
# SDKMAN, JVM, and Kotlin Installation
# ============================================================================

install_sdkman_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
    
    if [ -f "$sdkman_init" ]; then
        log_skip "SDKMAN already installed for user $user"
        return 0
    fi
    
    log_info "Installing SDKMAN for user $user..."
    
    # Install SDKMAN
    run_as "$user" 'curl -s "https://get.sdkman.io" | bash'
    
    if [ -f "$sdkman_init" ]; then
        log_success "SDKMAN installed for user $user"
        return 0
    else
        log_error "SDKMAN installation failed for user $user"
        return 1
    fi
}

install_jvm_for_user() {
    local user=$1
    
    if [ "$INSTALL_JVM" != "true" ]; then
        return 0
    fi
    
    local home_dir=$(get_user_home "$user")
    local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
    
    # Ensure SDKMAN is installed
    install_sdkman_for_user "$user"
    
    log_info "Installing Java for user $user..."
    
    # Install Java using SDKMAN
    run_as "$user" "source $sdkman_init && sdk install java < /dev/null" || true
    
    # Validate
    if run_as "$user" "source $sdkman_init && java -version" &>/dev/null; then
        log_success "Java installed for user $user"
    else
        log_warning "Java installation may have failed for user $user"
    fi
}

install_kotlin_for_user() {
    local user=$1
    
    if [ "$INSTALL_KOTLIN" != "true" ]; then
        return 0
    fi
    
    local home_dir=$(get_user_home "$user")
    local sdkman_init="$home_dir/.sdkman/bin/sdkman-init.sh"
    
    # Ensure SDKMAN is installed
    install_sdkman_for_user "$user"
    
    log_info "Installing Kotlin for user $user..."
    
    # Install Kotlin using SDKMAN
    run_as "$user" "source $sdkman_init && sdk install kotlin < /dev/null" || true
    
    # Validate
    if run_as "$user" "source $sdkman_init && kotlin -version" &>/dev/null; then
        log_success "Kotlin installed for user $user"
    else
        log_warning "Kotlin installation may have failed for user $user"
    fi
}


# ============================================================================
# Terminal Tools Configuration
# ============================================================================

configure_vim_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    if check_directory_exists "$home_dir/.vim_runtime"; then
        log_skip "Vim already configured for user $user"
        return 0
    fi
    
    log_info "Configuring Vim for user $user..."
    
    # Clone awesome vimrc
    run_as "$user" "git clone --depth=1 https://github.com/amix/vimrc.git $home_dir/.vim_runtime"
    
    # Backup existing .vimrc if it exists
    if [ -f "$home_dir/.vimrc" ]; then
        mv "$home_dir/.vimrc" "$home_dir/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Install awesome vimrc
    run_as "$user" "sh $home_dir/.vim_runtime/install_awesome_vimrc.sh"
    
    # Enable line numbers
    run_as "$user" "echo 'set nu' >> $home_dir/.vim_runtime/my_configs.vim"
    
    log_success "Vim configured for user $user"
}

add_alias_if_not_exists() {
    local file=$1
    local alias_line=$2
    local alias_name=$(echo "$alias_line" | cut -d'=' -f1 | sed 's/alias //')
    
    if check_alias_exists "$alias_name" "$file"; then
        return 0
    fi
    
    echo "$alias_line" >> "$file"
}

configure_shell_aliases_and_env() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    log_info "Configuring shell aliases and environment for user $user..."
    
    # Aliases for eza
    local ls_alias='alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"'
    local lt_alias='alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"'
    
    # Environment variables
    local editor_var='export EDITOR=micro'
    local visual_var='export VISUAL=micro'
    
    # Add Go to PATH
    local go_path='export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin'
    
    # Python aliases
    local python_alias='alias python=python3'
    local pip_alias='alias pip=pip3'
    
    # Configure .bashrc
    if [ -f "$home_dir/.bashrc" ]; then
        add_alias_if_not_exists "$home_dir/.bashrc" "$ls_alias"
        add_alias_if_not_exists "$home_dir/.bashrc" "$lt_alias"
        
        if [ "$INSTALL_PYTHON" == "true" ]; then
            add_alias_if_not_exists "$home_dir/.bashrc" "$python_alias"
            add_alias_if_not_exists "$home_dir/.bashrc" "$pip_alias"
        fi
        
        # Add environment variables if not present
        if ! grep -q "EDITOR=micro" "$home_dir/.bashrc"; then
            echo "$editor_var" >> "$home_dir/.bashrc"
            echo "$visual_var" >> "$home_dir/.bashrc"
        fi
        
        if [ "$INSTALL_GO" == "true" ] && ! grep -q "/usr/local/go/bin" "$home_dir/.bashrc"; then
            echo "$go_path" >> "$home_dir/.bashrc"
        fi
    fi
    
    # Configure .zshrc (will be created by oh-my-zsh)
    if [ -f "$home_dir/.zshrc" ]; then
        add_alias_if_not_exists "$home_dir/.zshrc" "$ls_alias"
        add_alias_if_not_exists "$home_dir/.zshrc" "$lt_alias"
        
        if [ "$INSTALL_PYTHON" == "true" ]; then
            add_alias_if_not_exists "$home_dir/.zshrc" "$python_alias"
            add_alias_if_not_exists "$home_dir/.zshrc" "$pip_alias"
        fi
        
        # Add environment variables if not present
        if ! grep -q "EDITOR=micro" "$home_dir/.zshrc"; then
            echo "$editor_var" >> "$home_dir/.zshrc"
            echo "$visual_var" >> "$home_dir/.zshrc"
        fi
        
        if [ "$INSTALL_GO" == "true" ] && ! grep -q "/usr/local/go/bin" "$home_dir/.zshrc"; then
            echo "$go_path" >> "$home_dir/.zshrc"
        fi
    fi
    
    log_success "Shell aliases and environment configured for user $user"
}


# ============================================================================
# Oh-My-Bash Configuration
# ============================================================================

configure_ohmybash_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    if check_directory_exists "$home_dir/.oh-my-bash"; then
        log_skip "Oh-My-Bash already installed for user $user"
        return 0
    fi
    
    log_info "Installing Oh-My-Bash for user $user..."
    
    # Install Oh-My-Bash
    run_as "$user" 'curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash'
    
    if check_directory_exists "$home_dir/.oh-my-bash"; then
        log_success "Oh-My-Bash installed for user $user"
    else
        log_warning "Oh-My-Bash installation may have failed for user $user"
    fi
}

# ============================================================================
# Oh-My-Zsh Configuration
# ============================================================================

configure_ohmyzsh_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    if check_directory_exists "$home_dir/.oh-my-zsh"; then
        log_skip "Oh-My-Zsh already installed for user $user"
    else
        log_info "Installing Oh-My-Zsh for user $user..."
        
        # Install Oh-My-Zsh (non-interactive)
        run_as "$user" 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
        
        if check_directory_exists "$home_dir/.oh-my-zsh"; then
            log_success "Oh-My-Zsh installed for user $user"
        else
            log_warning "Oh-My-Zsh installation may have failed for user $user"
            return 1
        fi
    fi
    
    # Configure theme
    log_info "Configuring Oh-My-Zsh theme for user $user..."
    if [ -f "$home_dir/.zshrc" ]; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="frisk"/' "$home_dir/.zshrc"
    fi
    
    # Configure plugins
    log_info "Configuring Oh-My-Zsh plugins for user $user..."
    local plugins="git colorize command-not-found compleat composer cp debian dircycle docker docker-compose dotnet eza fzf gh golang grc nats pip postgres procs python qrcode redis-cli repo rust sdk ssh sudo systemd themes ubuntu vscode zsh-interactive-cd"
    
    if [ -f "$home_dir/.zshrc" ]; then
        sed -i "s/^plugins=.*/plugins=($plugins)/" "$home_dir/.zshrc"
        log_success "Oh-My-Zsh configured for user $user"
    fi
}

# ============================================================================
# Change Default Shell
# ============================================================================

change_default_shell_to_zsh() {
    local user=$1
    
    # Check current shell
    local current_shell=$(getent passwd "$user" | cut -d: -f7)
    
    if [ "$current_shell" == "/usr/bin/zsh" ] || [ "$current_shell" == "/bin/zsh" ]; then
        log_skip "Default shell already set to zsh for user $user"
        return 0
    fi
    
    log_info "Changing default shell to zsh for user $user..."
    
    if chsh -s /usr/bin/zsh "$user"; then
        log_success "Default shell changed to zsh for user $user"
    else
        log_warning "Failed to change default shell for user $user"
        return 1
    fi
}


# ============================================================================
# Desktop Components Installation
# ============================================================================

install_fonts() {
    log_info "Installing fonts..."
    
    local fonts_dir="/tmp/fonts-install"
    mkdir -p "$fonts_dir"
    
    # Install Powerline Fonts
    if [ ! -d "$fonts_dir/powerline-fonts" ]; then
        log_info "Installing Powerline fonts..."
        git clone --depth=1 https://github.com/powerline/fonts.git "$fonts_dir/powerline-fonts"
        cd "$fonts_dir/powerline-fonts"
        ./install.sh
        cd -
        log_success "Powerline fonts installed"
    else
        log_skip "Powerline fonts already downloaded"
    fi
    
    # Install Nerd Fonts (selected)
    if [ ! -d "$fonts_dir/nerd-fonts" ]; then
        log_info "Installing Nerd Fonts (FiraCode, JetBrainsMono, Hack)..."
        git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git "$fonts_dir/nerd-fonts"
        cd "$fonts_dir/nerd-fonts"
        ./install.sh FiraCode JetBrainsMono Hack
        cd -
        log_success "Nerd Fonts installed"
    else
        log_skip "Nerd Fonts already downloaded"
    fi
    
    # Install MS Core Fonts
    if ! check_package_installed ttf-mscorefonts-installer; then
        log_info "Installing MS Core Fonts..."
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
        apt install -y ttf-mscorefonts-installer
        log_success "MS Core Fonts installed"
    else
        log_skip "MS Core Fonts already installed"
    fi
    
    # Update font cache
    log_info "Updating font cache..."
    fc-cache -fv > /dev/null 2>&1
    log_success "Font cache updated"
}

install_terminal_emulators() {
    log_info "Installing terminal emulators..."
    
    local emulators=(terminator alacritty)
    local to_install=()
    
    for emu in "${emulators[@]}"; do
        if check_package_installed "$emu"; then
            log_skip "Terminal emulator $emu already installed"
        else
            to_install+=("$emu")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log_info "Installing terminal emulators: ${to_install[*]}"
        apt install -y "${to_install[@]}"
        log_success "Terminal emulators installed"
    fi
}

configure_terminal_emulators_for_user() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    # Skip root for desktop configuration
    if [ "$user" == "root" ]; then
        return 0
    fi
    
    log_info "Configuring terminal emulators for user $user..."
    
    # Configure Terminator
    local terminator_config_dir="$home_dir/.config/terminator"
    mkdir -p "$terminator_config_dir"
    
    if [ ! -f "$terminator_config_dir/config" ]; then
        cat > "$terminator_config_dir/config" << 'EOF'
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
        chown -R "$user:$user" "$terminator_config_dir"
        log_success "Terminator configured for user $user"
    else
        log_skip "Terminator already configured for user $user"
    fi
    
    # Configure Alacritty
    local alacritty_config_dir="$home_dir/.config/alacritty"
    mkdir -p "$alacritty_config_dir"
    
    if [ ! -f "$alacritty_config_dir/alacritty.yml" ]; then
        cat > "$alacritty_config_dir/alacritty.yml" << 'EOF'
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
        chown -R "$user:$user" "$alacritty_config_dir"
        log_success "Alacritty configured for user $user"
    else
        log_skip "Alacritty already configured for user $user"
    fi
}

install_desktop_applications() {
    log_info "Installing desktop applications..."
    
    # Install VSCode
    if check_command_available code; then
        log_skip "VSCode already installed"
    else
        log_info "Installing VSCode..."
        snap install code --classic
        log_success "VSCode installed"
    fi
    
    # Install Google Chrome
    if check_command_available google-chrome; then
        log_skip "Google Chrome already installed"
    else
        log_info "Installing Google Chrome..."
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
        dpkg -i /tmp/chrome.deb || apt install -f -y
        rm /tmp/chrome.deb
        log_success "Google Chrome installed"
    fi
}

install_desktop_components() {
    if [ "$INSTALL_DESKTOP" != "true" ]; then
        log_skip "Desktop components installation skipped (use --desktop to enable)"
        return 0
    fi
    
    log_info "Installing desktop components..."
    
    install_fonts
    install_terminal_emulators
    install_desktop_applications
    
    log_success "Desktop components installed"
}


# ============================================================================
# User Environment Configuration
# ============================================================================

configure_user_environment() {
    local user=$1
    
    log_info "=========================================="
    log_info "Configuring environment for user: $user"
    log_info "=========================================="
    
    # Create user if needed
    create_user_if_needed "$user"
    
    # Add to sudo group
    add_user_to_sudo "$user"
    
    # Add to docker group if Docker is installed
    if [ "$INSTALL_DOCKER" == "true" ]; then
        add_user_to_docker "$user"
    fi
    
    # Configure Vim
    configure_vim_for_user "$user"
    
    # Configure Oh-My-Bash
    configure_ohmybash_for_user "$user"
    
    # Configure Oh-My-Zsh
    configure_ohmyzsh_for_user "$user"
    
    # Configure shell aliases and environment variables
    configure_shell_aliases_and_env "$user"
    
    # Change default shell to zsh
    change_default_shell_to_zsh "$user"
    
    # Install JVM if enabled
    if [ "$INSTALL_JVM" == "true" ]; then
        install_jvm_for_user "$user"
    fi
    
    # Install Kotlin if enabled
    if [ "$INSTALL_KOTLIN" == "true" ]; then
        install_kotlin_for_user "$user"
    fi
    
    # Configure desktop components if enabled
    if [ "$INSTALL_DESKTOP" == "true" ]; then
        configure_terminal_emulators_for_user "$user"
    fi
    
    log_success "User $user configured successfully"
}

# ============================================================================
# System Cleanup
# ============================================================================

cleanup_system() {
    log_info "Performing system cleanup..."
    
    apt upgrade -y
    apt autoclean -y
    apt autoremove -y
    apt install -y -f
    apt install -y --fix-broken
    apt install -y --fix-missing
    
    log_success "System cleanup completed"
}

# ============================================================================
# Summary Display
# ============================================================================

display_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║                    Installation Summary                                    ║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    echo -e "${BOLD}Components Installed:${RESET}"
    echo -e "  ${GREEN}✓${RESET} Base packages (git, zsh, vim, curl, htop, btop, eza, micro, etc.)"
    
    if [ "$INSTALL_DOCKER" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} Docker and Docker Compose v2"
    else
        echo -e "  ${GRAY}⏭${RESET} Docker (skipped)"
    fi
    
    if [ "$INSTALL_GO" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} Golang"
    else
        echo -e "  ${GRAY}⏭${RESET} Golang (skipped)"
    fi
    
    if [ "$INSTALL_PYTHON" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} Python 3 with pip and virtualenv"
    else
        echo -e "  ${GRAY}⏭${RESET} Python (skipped)"
    fi
    
    if [ "$INSTALL_KOTLIN" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} Kotlin via SDKMAN"
    else
        echo -e "  ${GRAY}⏭${RESET} Kotlin (skipped)"
    fi
    
    if [ "$INSTALL_JVM" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} JVM (Java) via SDKMAN"
    else
        echo -e "  ${GRAY}⏭${RESET} JVM (skipped)"
    fi
    
    if [ "$INSTALL_DOTNET" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} .NET SDK 8.0"
    else
        echo -e "  ${GRAY}⏭${RESET} .NET (skipped)"
    fi
    
    echo -e "  ${GREEN}✓${RESET} Oh-My-Zsh with frisk theme and plugins"
    echo -e "  ${GREEN}✓${RESET} Oh-My-Bash"
    echo -e "  ${GREEN}✓${RESET} Vim with awesome vimrc"
    echo -e "  ${GREEN}✓${RESET} Shell aliases (ls → eza, lt → eza tree)"
    echo -e "  ${GREEN}✓${RESET} Default shell: Zsh"
    echo -e "  ${GREEN}✓${RESET} Default editor: micro"
    
    if [ "$INSTALL_DESKTOP" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} Desktop components (VSCode, Chrome, fonts, terminal emulators)"
    else
        echo -e "  ${GRAY}⏭${RESET} Desktop components (use --desktop to enable)"
    fi
    
    echo ""
    echo -e "${BOLD}Users Configured:${RESET}"
    for user in "${ALL_USERS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} $user"
    done
    
    echo ""
    echo -e "${BOLD}System Configuration:${RESET}"
    echo -e "  ${GREEN}✓${RESET} Timezone: America/Sao_Paulo"
    echo -e "  ${GREEN}✓${RESET} All users added to sudo group"
    if [ "$INSTALL_DOCKER" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} All users added to docker group"
    fi
    
    echo ""
    echo -e "${BOLD}Execution Time:${RESET} ${minutes}m ${seconds}s"
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║                 Installation Completed Successfully!                       ║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}NOTE:${RESET} Please log out and log back in for all changes to take effect."
    echo -e "${YELLOW}NOTE:${RESET} Docker group membership requires re-login to take effect."
    echo ""
}


# ============================================================================
# Main Function
# ============================================================================

main() {
    # Record start time
    START_TIME=$(date +%s)
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║          Linux Development Environment Setup Script                        ║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # Check privileges
    check_privileges "$@"
    
    # Detect distribution
    detect_distribution || { log_error "Distribution detection failed"; exit 1; }
    
    # Parse arguments (includes desktop auto-detection)
    parse_arguments "$@"
    
    # Setup users list
    setup_users_list
    
    echo ""
    log_info "Starting installation process..."
    echo ""
    
    # Configure timezone
    configure_timezone || { log_error "Timezone configuration failed"; exit 1; }
    
    # Install base packages
    install_base_packages || { log_error "Base packages installation failed"; exit 1; }
    
    # Install Docker
    if [ "$INSTALL_DOCKER" == "true" ]; then
        install_docker || { log_error "Docker installation failed"; exit 1; }
    fi
    
    # Install Golang
    if [ "$INSTALL_GO" == "true" ]; then
        install_golang || { log_error "Golang installation failed"; exit 1; }
    fi
    
    # Install Python
    if [ "$INSTALL_PYTHON" == "true" ]; then
        install_python || { log_error "Python installation failed"; exit 1; }
    fi
    
    # Install .NET
    if [ "$INSTALL_DOTNET" == "true" ]; then
        install_dotnet || { log_error ".NET installation failed"; exit 1; }
    fi
    
    # Install desktop components (if enabled)
    if [ "$INSTALL_DESKTOP" == "true" ]; then
        install_desktop_components || { log_error "Desktop installation failed"; exit 1; }
    fi
    
    # Configure each user
    echo ""
    log_info "Configuring user environments..."
    echo ""
    
    for user in "${ALL_USERS[@]}"; do
        configure_user_environment "$user" || { log_warning "Failed to configure user $user, continuing..."; }
        echo ""
    done
    
    # System cleanup
    cleanup_system || { log_warning "System cleanup had issues, continuing..."; }
    
    # Display summary
    display_summary
}

# ============================================================================
# Script Entry Point
# ============================================================================

# Run main function
main "$@"
