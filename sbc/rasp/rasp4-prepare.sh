#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Raspberry Pi 4 Development Environment Setup Script
# ============================================================================
# Optimized version for Raspberry Pi 4 with Ubuntu (ARM64 architecture)
# Based on the main prepare.sh script with ARM-specific optimizations
# ============================================================================

# Source the main script functions (if running from repo structure)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/../scripts/prepare.sh"

# If main script exists, we can source common functions
# Otherwise, we'll use a simplified standalone version

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
# Raspberry Pi Specific Configuration
# ============================================================================

detect_raspberry_pi() {
    log_info "Detecting Raspberry Pi hardware..."
    
    if [ -f /proc/device-tree/model ]; then
        local model=$(cat /proc/device-tree/model)
        log_success "Detected: $model"
    else
        log_warning "Could not detect Raspberry Pi model"
    fi
    
    # Detect architecture
    local arch=$(uname -m)
    log_info "Architecture: $arch"
    
    if [[ "$arch" != "aarch64" && "$arch" != "armv7l" ]]; then
        log_warning "This script is optimized for ARM architecture"
    fi
}

# ============================================================================
# Main Installation
# ============================================================================

main() {
    START_TIME=$(date +%s)
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║          Raspberry Pi 4 Development Environment Setup                      ║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Detect Raspberry Pi
    detect_raspberry_pi
    
    # Configure timezone
    log_info "Configuring timezone to America/Sao_Paulo..."
    echo "America/Sao_Paulo" | tee /etc/timezone > /dev/null
    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    if command -v timedatectl &>/dev/null; then
        timedatectl set-timezone America/Sao_Paulo 2>/dev/null || true
    fi
    log_success "Timezone configured"
    
    # Update package list
    log_info "Updating package list..."
    apt update -y
    
    # Install base packages (ARM-compatible)
    log_info "Installing base packages for ARM..."
    apt install -y \
        git vim zsh wget unzip jq telnet curl htop \
        lm-sensors python3 python3-pip python3-venv python3-dev \
        cifs-utils gpg zip btop sqlite3 fzf sudo \
        apt-transport-https zlib1g
    
    # Install eza (if available for ARM, otherwise skip)
    if apt-cache show eza &>/dev/null; then
        log_info "Installing eza..."
        apt install -y eza
    else
        log_warning "eza not available for ARM, will use exa if available"
        if apt-cache show exa &>/dev/null; then
            apt install -y exa
        fi
    fi
    
    # Install micro editor
    log_info "Installing micro editor..."
    if ! command -v micro &>/dev/null; then
        curl https://getmic.ro | bash
        mv micro /usr/bin/
        log_success "Micro editor installed"
    else
        log_skip "Micro already installed"
    fi
    
    # Install Docker (ARM-compatible)
    log_info "Installing Docker for ARM..."
    if ! command -v docker &>/dev/null; then
        apt install -y docker.io docker-compose-v2
        systemctl enable docker
        systemctl start docker
        log_success "Docker installed"
    else
        log_skip "Docker already installed"
    fi
    
    # Install Golang (ARM version)
    log_info "Installing Golang for ARM..."
    if ! command -v go &>/dev/null; then
        local latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
        local arch=$(dpkg --print-architecture)
        wget "https://go.dev/dl/${latest_version}.linux-${arch}.tar.gz" -O /tmp/golang.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf /tmp/golang.tar.gz
        rm /tmp/golang.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        log_success "Golang installed"
    else
        log_skip "Golang already installed"
    fi
    
    # Configure for current user
    local current_user=${SUDO_USER:-$(whoami)}
    if [ "$current_user" == "root" ]; then
        current_user=$(logname 2>/dev/null || echo "pi")
    fi
    
    log_info "Configuring environment for user: $current_user"
    local home_dir=$(eval echo "~$current_user")
    
    # Install Vim configuration
    if [ ! -d "$home_dir/.vim_runtime" ]; then
        log_info "Installing Vim configuration..."
        sudo -u "$current_user" git clone --depth=1 https://github.com/amix/vimrc.git "$home_dir/.vim_runtime"
        sudo -u "$current_user" sh "$home_dir/.vim_runtime/install_awesome_vimrc.sh"
        sudo -u "$current_user" bash -c "echo 'set nu' >> $home_dir/.vim_runtime/my_configs.vim"
        log_success "Vim configured"
    else
        log_skip "Vim already configured"
    fi
    
    # Install Oh-My-Zsh
    if [ ! -d "$home_dir/.oh-my-zsh" ]; then
        log_info "Installing Oh-My-Zsh..."
        sudo -u "$current_user" bash -c 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
        
        # Configure theme and plugins
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="frisk"/' "$home_dir/.zshrc"
        local plugins="git docker python golang colorize command-not-found fzf ssh sudo systemd"
        sed -i "s/^plugins=.*/plugins=($plugins)/" "$home_dir/.zshrc"
        
        log_success "Oh-My-Zsh installed"
    else
        log_skip "Oh-My-Zsh already installed"
    fi
    
    # Configure aliases
    log_info "Configuring shell aliases..."
    
    # Determine which ls replacement is available
    if command -v eza &>/dev/null; then
        local ls_cmd='alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"'
        local lt_cmd='alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"'
    elif command -v exa &>/dev/null; then
        local ls_cmd='alias ls="exa -hHbmgalT -L 1 --time-style=long-iso --icons"'
        local lt_cmd='alias lt="exa -hHbmgalT -L 4 --time-style=long-iso --icons"'
    else
        local ls_cmd='alias ls="ls -lha --color=auto"'
        local lt_cmd='alias lt="ls -lha --color=auto"'
    fi
    
    # Add to .zshrc if not present
    if ! grep -q "alias ls=" "$home_dir/.zshrc"; then
        echo "$ls_cmd" >> "$home_dir/.zshrc"
        echo "$lt_cmd" >> "$home_dir/.zshrc"
    fi
    
    # Add to .bashrc if not present
    if [ -f "$home_dir/.bashrc" ] && ! grep -q "alias ls=" "$home_dir/.bashrc"; then
        echo "$ls_cmd" >> "$home_dir/.bashrc"
        echo "$lt_cmd" >> "$home_dir/.bashrc"
    fi
    
    # Environment variables
    if ! grep -q "EDITOR=micro" "$home_dir/.zshrc"; then
        echo 'export EDITOR=micro' >> "$home_dir/.zshrc"
        echo 'export VISUAL=micro' >> "$home_dir/.zshrc"
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$home_dir/.zshrc"
    fi
    
    if [ -f "$home_dir/.bashrc" ] && ! grep -q "EDITOR=micro" "$home_dir/.bashrc"; then
        echo 'export EDITOR=micro' >> "$home_dir/.bashrc"
        echo 'export VISUAL=micro' >> "$home_dir/.bashrc"
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$home_dir/.bashrc"
    fi
    
    # Change default shell to zsh
    log_info "Changing default shell to zsh..."
    chsh -s /usr/bin/zsh "$current_user"
    
    # Add user to docker group
    if command -v docker &>/dev/null; then
        log_info "Adding user to docker group..."
        usermod -aG docker "$current_user"
    fi
    
    # Add user to sudo group
    log_info "Adding user to sudo group..."
    usermod -aG sudo "$current_user"
    
    # System cleanup
    log_info "Performing system cleanup..."
    apt upgrade -y
    apt autoclean -y
    apt autoremove -y
    
    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Summary
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║                 Installation Completed Successfully!                       ║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}Components Installed:${RESET}"
    echo -e "  ${GREEN}✓${RESET} Base packages (git, vim, zsh, curl, htop, etc.)"
    echo -e "  ${GREEN}✓${RESET} Docker and Docker Compose v2"
    echo -e "  ${GREEN}✓${RESET} Golang (ARM version)"
    echo -e "  ${GREEN}✓${RESET} Python 3 with pip and virtualenv"
    echo -e "  ${GREEN}✓${RESET} Oh-My-Zsh with frisk theme"
    echo -e "  ${GREEN}✓${RESET} Vim with awesome vimrc"
    echo -e "  ${GREEN}✓${RESET} Micro editor"
    echo -e "  ${GREEN}✓${RESET} Shell aliases and environment"
    echo ""
    echo -e "${BOLD}User Configured:${RESET} $current_user"
    echo -e "${BOLD}Timezone:${RESET} America/Sao_Paulo"
    echo -e "${BOLD}Default Shell:${RESET} Zsh"
    echo -e "${BOLD}Execution Time:${RESET} ${minutes}m ${seconds}s"
    echo ""
    echo -e "${YELLOW}NOTE:${RESET} Please log out and log back in for all changes to take effect."
    echo -e "${YELLOW}NOTE:${RESET} Docker group membership requires re-login to take effect."
    echo ""
}

# Run main function
main "$@"
