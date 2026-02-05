#!/bin/bash

# Base Packages Installation Module
# Installs essential development packages and configures shell frameworks

set -euo pipefail

# Source the logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../util/log.sh"

readonly MODULE_NAME="base"

# List of base packages to install
readonly BASE_PACKAGES=(
    "zsh"
    "git"
    "curl"
    "wget"
    "jq"
    "batcat"
    "micro"
    "eza"
    "python3"
    "python3-pip"
    "vim"
    "sqlite3"
    "telnet"
    "htop"
    "btop"
    "gpg"
    "zip"
    "unzip"
    "apt-transport-https"
    "zlib1g"
    "ca-certificates"
    "gnupg"
    "httpie"
    "gh"
    "cmake"
    "build-essential"
    "netcat-openbsd"
    "openssl"
    "openssh-server"
)

# Check if a package is installed
is_package_installed() {
    local package="$1"
    dpkg -l "$package" &>/dev/null
}

# Check if all base packages are installed
is_installed() {
    local missing_packages=()
    
    for package in "${BASE_PACKAGES[@]}"; do
        if ! is_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done
    
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        return 0  # All packages installed
    else
        return 1  # Some packages missing
    fi
}

# Install base packages with error handling
install_base_packages() {
    log_info "$MODULE_NAME" "Updating package lists..."
    if ! apt-get update; then
        handle_error "$MODULE_NAME" "Failed to update package lists"
        return 1
    fi
    
    local failed_packages=()
    
    for package in "${BASE_PACKAGES[@]}"; do
        if is_package_installed "$package"; then
            log_debug "$MODULE_NAME" "$package is already installed"
            continue
        fi
        
        log_info "$MODULE_NAME" "Installing $package..."
        if apt-get install -y "$package"; then
            log_debug "$MODULE_NAME" "$package installed successfully"
        else
            log_error "$MODULE_NAME" "Failed to install $package"
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "$MODULE_NAME" "Some packages failed to install: ${failed_packages[*]}"
        # Continue execution despite failures (requirement 1.3)
    fi
    
    return 0
}

# Get all users on the system (excluding system users)
get_all_users() {
    # Get users with UID >= 1000 (regular users) and exclude nobody
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

# Configure oh-my-zsh for a user
configure_oh_my_zsh() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    # Install oh-my-zsh if not already installed
    if [[ ! -d "$user_home/.oh-my-zsh" ]]; then
        log_info "$MODULE_NAME" "Installing oh-my-zsh for $username..."
        
        # Download and install oh-my-zsh
        sudo -u "$username" bash -c 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
        
        if [[ $? -eq 0 ]]; then
            log_debug "$MODULE_NAME" "oh-my-zsh installed for $username"
        else
            log_error "$MODULE_NAME" "Failed to install oh-my-zsh for $username"
            return 1
        fi
    else
        log_debug "$MODULE_NAME" "oh-my-zsh already installed for $username"
    fi
    
    # Set agnoster theme
    if [[ -f "$user_home/.zshrc" ]]; then
        sudo -u "$username" sed -i 's/ZSH_THEME=".*"/ZSH_THEME="agnoster"/' "$user_home/.zshrc"
        log_debug "$MODULE_NAME" "Set agnoster theme for $username"
    fi
    
    # Change default shell to zsh
    if [[ "$(getent passwd "$username" | cut -d: -f7)" != "/bin/zsh" ]]; then
        chsh -s /bin/zsh "$username"
        log_debug "$MODULE_NAME" "Changed default shell to zsh for $username"
    fi
    
    return 0
}

# Configure oh-my-bash for a user
configure_oh_my_bash() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    # Install oh-my-bash if not already installed
    if [[ ! -d "$user_home/.oh-my-bash" ]]; then
        log_info "$MODULE_NAME" "Installing oh-my-bash for $username..."
        
        # Download and install oh-my-bash
        sudo -u "$username" bash -c 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended'
        
        if [[ $? -eq 0 ]]; then
            log_debug "$MODULE_NAME" "oh-my-bash installed for $username"
        else
            log_error "$MODULE_NAME" "Failed to install oh-my-bash for $username"
            return 1
        fi
    else
        log_debug "$MODULE_NAME" "oh-my-bash already installed for $username"
    fi
    
    return 0
}

# Configure user environment
configure_user_environment() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    
    if [[ ! -d "$user_home" ]]; then
        log_warn "$MODULE_NAME" "Home directory for $username does not exist"
        return 1
    fi
    
    # Configure eza aliases in .profile
    local profile_file="$user_home/.profile"
    
    # Create .profile if it doesn't exist
    if [[ ! -f "$profile_file" ]]; then
        sudo -u "$username" touch "$profile_file"
    fi
    
    # Add eza aliases if not already present
    if ! grep -q "alias ls=" "$profile_file" 2>/dev/null; then
        sudo -u "$username" bash -c "echo '' >> '$profile_file'"
        sudo -u "$username" bash -c "echo '# Eza aliases' >> '$profile_file'"
        sudo -u "$username" bash -c "echo 'alias ls=\"eza -hHbmgalT -L 1 --time-style=long-iso --icons\"' >> '$profile_file'"
        sudo -u "$username" bash -c "echo 'alias lt=\"eza -hHbmgalT -L 4 --time-style=long-iso --icons\"' >> '$profile_file'"
        log_debug "$MODULE_NAME" "Added eza aliases to .profile for $username"
    else
        log_debug "$MODULE_NAME" "Eza aliases already configured for $username"
    fi
    
    # Configure vim with awesome vim
    configure_vim_for_user "$username"
    
    return 0
}

# Configure vim with awesome vim settings
configure_vim_for_user() {
    local username="$1"
    local user_home
    user_home=$(eval echo "~$username")
    local vimrc_file="$user_home/.vimrc"
    
    # Create basic vim configuration with line numbers
    if [[ ! -f "$vimrc_file" ]]; then
        sudo -u "$username" bash -c "cat > '$vimrc_file' << 'EOF'
\" Awesome Vim Configuration
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
set ruler
set showcmd
set wildmenu
set laststatus=2
syntax on
filetype plugin indent on

\" Color scheme
colorscheme default
set background=dark
EOF"
        log_debug "$MODULE_NAME" "Created vim configuration for $username"
    else
        # Ensure line numbers are enabled
        if ! grep -q "set number" "$vimrc_file" 2>/dev/null; then
            sudo -u "$username" bash -c "echo 'set number' >> '$vimrc_file'"
            log_debug "$MODULE_NAME" "Added line numbers to vim config for $username"
        fi
    fi
    
    return 0
}

# Main installation function
main() {
    if is_installed; then
        log_info "$MODULE_NAME" "All base packages already installed, skipping package installation"
    else
        start_timer "$MODULE_NAME"
        
        if install_base_packages; then
            end_timer "$MODULE_NAME"
        else
            handle_error "$MODULE_NAME" "Base package installation completed with some failures"
        fi
    fi
    
    # Configure shell frameworks and environment for all users
    log_info "$MODULE_NAME" "Configuring shell frameworks and environment for all users..."
    
    local users
    users=$(get_all_users)
    
    if [[ -z "$users" ]]; then
        log_warn "$MODULE_NAME" "No regular users found on the system"
        return 0
    fi
    
    for user in $users; do
        log_info "$MODULE_NAME" "Configuring environment for user: $user"
        
        # Configure oh-my-bash (alternative shell framework)
        configure_oh_my_bash "$user"

        # Configure oh-my-zsh (default shell framework)
        configure_oh_my_zsh "$user"        
        
        # Configure user environment (aliases, vim, etc.)
        configure_user_environment "$user"
    done
    
    log_info "$MODULE_NAME" "Base packages installation and configuration completed"
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi