#!/usr/bin/env bash

# ============================================================================
# Terminal Configuration Module for Linux-prepare
# ============================================================================
# This module handles terminal and shell configuration including:
# - Zsh installation and configuration
# - Oh-My-Zsh setup with themes and plugins
# - Oh-My-Bash configuration
# - Shell aliases and environment variables
# - Vim configuration
# - Version-specific package selection (eza/exa)

set -euo pipefail

# Get script directory and source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/version-detection.sh"
source "$SCRIPT_DIR/../lib/package-utils.sh"

MODULE_NAME="terminal-config"

# ============================================================================
# Helper Functions
# ============================================================================

# Run command as specific user
run_as() {
    local user=$1
    shift
    log_info "Running command as $user: $*"
    sudo -u "$user" bash -c "$*"
}

# Get user home directory
get_user_home() {
    local user=$1
    eval echo "~$user"
}

# Check if command is available
check_command_available() {
    command -v "$1" &> /dev/null
}

# Check if directory exists
check_directory_exists() {
    [ -d "$1" ]
}

# Check if alias exists in file
check_alias_exists() {
    local alias_name="$1"
    local file="$2"
    [ -f "$file" ] && grep -q "alias $alias_name=" "$file"
}

# Add alias to file if it doesn't exist
add_alias_if_not_exists() {
    local file=$1
    local alias_line=$2
    local alias_name=$(echo "$alias_line" | cut -d'=' -f1 | sed 's/alias //')
    
    if check_alias_exists "$alias_name" "$file"; then
        return 0
    fi
    
    echo "$alias_line" >> "$file"
}

# ============================================================================
# LS Replacement Installation (eza/exa with version detection)
# ============================================================================

install_ls_replacement() {
    log_info "Installing modern ls replacement (eza/exa with version detection)..."
    
    # Get the correct package name based on Ubuntu version
    local ls_package=$(get_ls_replacement_package)
    log_info "Selected ls replacement package: $ls_package (based on Ubuntu version)"
    
    # Check if either eza or exa is already installed
    if check_command_available eza; then
        log_skip "eza already installed"
        return 0
    fi
    
    if check_command_available exa; then
        log_skip "exa already installed (alternative to eza)"
        return 0
    fi
    
    # Special handling for Pop!_OS
    if is_popos; then
        log_info "Pop!_OS detected - using alternative installation method for $ls_package"
        
        # Try cargo install for eza if that's the preferred package
        if [[ "$ls_package" == "eza" ]]; then
            # Ensure cargo is available
            if ! check_command_available cargo; then
                log_info "Installing cargo for eza installation..."
                if install_packages_safe cargo; then
                    log_success "cargo installed"
                else
                    log_warning "Failed to install cargo"
                fi
            fi
            
            # Try cargo install first
            if check_command_available cargo; then
                log_info "Installing eza via cargo to /usr/local/bin..."
                # Install to temporary location first
                if CARGO_HOME=/tmp/cargo-install cargo install eza --root /usr/local 2>/dev/null; then
                    log_success "eza installed via cargo to /usr/local/bin (accessible to all users)"
                    # Clean up temporary cargo home
                    rm -rf /tmp/cargo-install
                    return 0
                else
                    log_warning "cargo install failed, trying fallback"
                    rm -rf /tmp/cargo-install
                fi
            fi
        fi
        
        # Fallback to package installation with fallback logic
        local installed_package=$(install_package_with_fallback "$ls_package" "$(get_fallback_ls_package "$ls_package")")
        if [ -n "$installed_package" ]; then
            # Create symlink if we installed exa but wanted eza
            if [[ "$ls_package" == "eza" ]] && [[ "$installed_package" == "exa" ]]; then
                ln -sf $(which exa) /usr/local/bin/eza 2>/dev/null || true
                log_success "exa installed and linked to eza command"
            fi
            return 0
        fi
        
        log_warning "Could not install $ls_package or fallback on Pop!_OS, will use standard ls"
        return 1
    fi
    
    # Standard installation method
    if [[ "$ls_package" == "eza" ]]; then
        # Try to add eza repository and install
        log_info "Adding eza repository..."
        if mkdir -p /etc/apt/keyrings && \
           wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null && \
           echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list >/dev/null && \
           chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null; then
            
            apt update
            
            # Try to install eza with fallback to exa
            local installed_package=$(install_package_with_fallback "eza" "exa")
            if [ -n "$installed_package" ]; then
                log_success "Installed $installed_package successfully"
                return 0
            fi
        else
            log_warning "Failed to add eza repository, trying fallback to exa"
            
            # Try exa from default repositories
            if install_packages_safe "exa"; then
                log_success "Installed exa successfully (fallback)"
                return 0
            fi
        fi
    else
        # For Ubuntu 22.04 and derivatives, install exa directly
        local installed_package=$(install_package_with_fallback "exa" "eza")
        if [ -n "$installed_package" ]; then
            log_success "Installed $installed_package successfully"
            return 0
        fi
    fi
    
    log_error "Failed to install $ls_package or fallback"
    return 1
}

# Get fallback package name for ls replacement
get_fallback_ls_package() {
    local primary="$1"
    
    case "$primary" in
        "eza")
            echo "exa"
            ;;
        "exa")
            echo "eza"
            ;;
        *)
            echo "exa"  # Default fallback
            ;;
    esac
}

# Test eza/exa version detection logic
test_eza_package_selection() {
    local test_version="$1"
    local expected_package="$2"
    
    log_info "Testing eza/exa package selection for Ubuntu $test_version..."
    
    # Test the version comparison logic directly
    local selected_package
    if version_compare "$test_version" "24.04" ">="; then
        selected_package="eza"
    else
        selected_package="exa"
    fi
    
    # Validate result
    if [[ "$selected_package" == "$expected_package" ]]; then
        log_success "✓ Ubuntu $test_version correctly selects '$selected_package' package"
        return 0
    else
        log_error "✗ Ubuntu $test_version selected '$selected_package', expected '$expected_package'"
        return 1
    fi
}

# Run version detection tests
run_version_detection_tests() {
    log_info "Running eza/exa version detection tests..."
    
    local test_results=0
    
    # Test Ubuntu 22.04 should select exa
    if ! test_eza_package_selection "22.04" "exa"; then
        test_results=1
    fi
    
    # Test Ubuntu 24.04 should select eza
    if ! test_eza_package_selection "24.04" "eza"; then
        test_results=1
    fi
    
    # Test Ubuntu 25.10 should select eza
    if ! test_eza_package_selection "25.10" "eza"; then
        test_results=1
    fi
    
    if [ $test_results -eq 0 ]; then
        log_success "All eza/exa version detection tests passed"
    else
        log_error "Some eza/exa version detection tests failed"
    fi
    
    return $test_results
}

# ============================================================================
# Vim Configuration
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

# ============================================================================
# Shell Aliases and Environment Configuration
# ============================================================================

configure_shell_aliases_and_env() {
    local user=$1
    local home_dir=$(get_user_home "$user")
    
    log_info "Configuring shell aliases and environment for user $user..."
    
    # Get the correct ls replacement command based on what's installed
    local ls_command="ls"
    if check_command_available eza; then
        ls_command="eza"
    elif check_command_available exa; then
        ls_command="exa"
    fi
    
    # Aliases for modern ls replacement
    local ls_alias="alias ls=\"$ls_command -hHbmgalT -L 1 --time-style=long-iso --icons\""
    local lt_alias="alias lt=\"$ls_command -hHbmgalT -L 4 --time-style=long-iso --icons\""
    
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
        
        # Add Python aliases if Python is being installed
        if [ "${INSTALL_PYTHON:-true}" == "true" ]; then
            add_alias_if_not_exists "$home_dir/.bashrc" "$python_alias"
            add_alias_if_not_exists "$home_dir/.bashrc" "$pip_alias"
        fi
        
        # Add environment variables if not present
        if ! grep -q "EDITOR=micro" "$home_dir/.bashrc"; then
            echo "$editor_var" >> "$home_dir/.bashrc"
            echo "$visual_var" >> "$home_dir/.bashrc"
        fi
        
        # Add Go PATH if Go is being installed
        if [ "${INSTALL_GO:-true}" == "true" ] && ! grep -q "/usr/local/go/bin" "$home_dir/.bashrc"; then
            echo "$go_path" >> "$home_dir/.bashrc"
        fi
    fi
    
    # Configure .zshrc (will be created by oh-my-zsh)
    if [ -f "$home_dir/.zshrc" ]; then
        add_alias_if_not_exists "$home_dir/.zshrc" "$ls_alias"
        add_alias_if_not_exists "$home_dir/.zshrc" "$lt_alias"
        
        # Add Python aliases if Python is being installed
        if [ "${INSTALL_PYTHON:-true}" == "true" ]; then
            add_alias_if_not_exists "$home_dir/.zshrc" "$python_alias"
            add_alias_if_not_exists "$home_dir/.zshrc" "$pip_alias"
        fi
        
        # Add environment variables if not present
        if ! grep -q "EDITOR=micro" "$home_dir/.zshrc"; then
            echo "$editor_var" >> "$home_dir/.zshrc"
            echo "$visual_var" >> "$home_dir/.zshrc"
        fi
        
        # Add Go PATH if Go is being installed
        if [ "${INSTALL_GO:-true}" == "true" ] && ! grep -q "/usr/local/go/bin" "$home_dir/.zshrc"; then
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
    
    # Configure plugins - include eza plugin if eza is available
    log_info "Configuring Oh-My-Zsh plugins for user $user..."
    local plugins="git colorize command-not-found compleat composer cp debian dircycle docker docker-compose dotnet fzf gh golang grc nats pip postgres procs python qrcode redis-cli repo rust sdk ssh sudo systemd themes ubuntu vscode zsh-interactive-cd"
    
    # Add eza plugin if eza is available
    if check_command_available eza; then
        plugins="$plugins eza"
    fi
    
    if [ -f "$home_dir/.zshrc" ]; then
        sed -i "s/^plugins=.*/plugins=($plugins)/" "$home_dir/.zshrc"
        log_success "Oh-My-Zsh configured for user $user"
    fi
}

# ============================================================================
# Default Shell Configuration
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
# Main Module Functions
# ============================================================================

# Configure terminal for a single user
configure_terminal_for_user() {
    local user=$1
    
    log_info "Configuring terminal environment for user $user..."
    
    # Configure Vim
    configure_vim_for_user "$user"
    
    # Configure Oh-My-Bash
    configure_ohmybash_for_user "$user"
    
    # Configure Oh-My-Zsh
    configure_ohmyzsh_for_user "$user"
    
    # Configure shell aliases and environment
    configure_shell_aliases_and_env "$user"
    
    # Change default shell to zsh
    change_default_shell_to_zsh "$user"
    
    log_success "Terminal configuration completed for user $user"
}

# Main module execution function
module_main() {
    log_info "Starting $MODULE_NAME module"
    
    # Install ls replacement (eza/exa) with version detection
    install_ls_replacement
    
    # Configure terminal for all specified users
    if [ ${#ALL_USERS[@]} -gt 0 ]; then
        for user in "${ALL_USERS[@]}"; do
            configure_terminal_for_user "$user"
        done
    else
        log_warning "No users specified for terminal configuration"
        log_info "Configuring terminal for current user and root..."
        
        # Fallback: configure for current user and root
        local current_user=$(whoami)
        if [ "$current_user" == "root" ]; then
            current_user=$(logname 2>/dev/null || echo "root")
        fi
        
        configure_terminal_for_user "root"
        if [ "$current_user" != "root" ]; then
            configure_terminal_for_user "$current_user"
        fi
    fi
    
    log_success "$MODULE_NAME module completed"
}

# Error trap
trap 'log_error "$MODULE_NAME module failed at line $LINENO"' ERR

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check for test mode
    if [[ "${1:-}" == "--test" ]]; then
        log_info "Running terminal-config module in test mode"
        run_version_detection_tests
        exit $?
    fi
    
    # Set default users if not provided
    if [ -z "${ALL_USERS:-}" ]; then
        ALL_USERS=("root")
        local current_user=$(whoami)
        if [ "$current_user" == "root" ]; then
            current_user=$(logname 2>/dev/null || echo "root")
        fi
        if [ "$current_user" != "root" ]; then
            ALL_USERS+=("$current_user")
        fi
    fi
    
    module_main "$@"
fi