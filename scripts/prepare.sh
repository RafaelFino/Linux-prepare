#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Linux Development Environment Setup Script - Modular Architecture
# ============================================================================
# This script prepares a fresh Linux installation for development work.
# By default, it installs ALL development components (Docker, Go, Python, 
# Kotlin, JVM, .NET, terminal tools, shell configurations).
# Desktop components are opt-in via --desktop flag.
# Use --skip-* flags to exclude specific components.
#
# This script now acts as a module orchestrator, delegating specific
# functionality to individual modules while maintaining full backward
# compatibility with all existing command-line options and behavior.
# ============================================================================

# Get script directory for loading libraries and modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared libraries
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/version-detection.sh"
source "$SCRIPT_DIR/lib/package-utils.sh"
source "$SCRIPT_DIR/lib/module-framework.sh"

# ============================================================================
# Help Function (Preserved for Backward Compatibility)
# ============================================================================

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║          Linux Development Environment Setup Script                        ║
║                        Modular Architecture                                ║
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
  
  --desktop         Force desktop components installation (even on servers)
  --skip-desktop    Skip desktop components installation (even on desktops)
  
  --skip-docker     Skip Docker and Docker Compose installation
  --skip-go         Skip Golang installation
  --skip-python     Skip Python installation
  --skip-kotlin     Skip Kotlin installation
  --skip-jvm        Skip JVM (Java) installation
  --skip-dotnet     Skip .NET SDK installation
  
  -h, --help        Show this help message

NOTE: Desktop components (VSCode, Chrome, fonts, terminal emulators) are
      automatically detected and installed. Use --desktop or --skip-desktop
      to override automatic detection.

SUPPORTED DISTRIBUTIONS:
  - Ubuntu (20.04, 22.04, 24.04, 25.10)
  - Xubuntu (24.04, 25.10)
  - Debian (13)
  - Linux Mint
  - Pop!_OS
  - Other Debian-based distributions

EXAMPLES:
  1. Full installation (desktop auto-detected):
     sudo ./prepare.sh

  2. Force desktop on server:
     sudo ./prepare.sh --desktop

  3. Skip desktop on workstation:
     sudo ./prepare.sh --skip-desktop

  4. Server setup without Docker:
     sudo ./prepare.sh --skip-docker --skip-desktop

  5. Minimal setup (only base tools and terminal configuration):
     sudo ./prepare.sh --skip-docker --skip-go --skip-python --skip-kotlin --skip-jvm --skip-dotnet --skip-desktop

  6. Create multiple users with desktop:
     sudo ./prepare.sh -u=developer,devops --desktop

  7. Workstation without .NET and Kotlin:
     sudo ./prepare.sh --skip-dotnet --skip-kotlin

  8. Go and Python only (skip other languages):
     sudo ./prepare.sh --skip-kotlin --skip-jvm --skip-dotnet

  9. Docker and Go development environment:
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
  - Now uses modular architecture for better maintainability

For more information, visit:
  https://github.com/RafaelFino/Linux-prepare

EOF
}

# ============================================================================
# Privilege Check (Preserved for Backward Compatibility)
# ============================================================================

check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        if command -v sudo &> /dev/null; then
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
# Argument Parsing (Preserved for Backward Compatibility)
# ============================================================================

# Default configuration: install everything
INSTALL_DOCKER=true
INSTALL_GO=true
INSTALL_PYTHON=true
INSTALL_KOTLIN=true
INSTALL_JVM=true
INSTALL_DOTNET=true
INSTALL_DESKTOP="auto"  # auto, force, skip

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
            --desktop)
                INSTALL_DESKTOP="force"
                log_info "Desktop components will be FORCED (manual override)"
                ;;
            --skip-desktop)
                INSTALL_DESKTOP="skip"
                log_info "Desktop components will be SKIPPED (manual override)"
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
    
    # Apply desktop installation logic using system-detection module
    if [ "$INSTALL_DESKTOP" == "auto" ]; then
        # Auto-detect desktop environment using system-detection module
        if bash "$SCRIPT_DIR/modules/system-detection.sh" --check-desktop-only; then
            INSTALL_DESKTOP="true"
            log_success "Desktop environment detected - desktop components will be installed automatically"
        else
            INSTALL_DESKTOP="false"
            log_info "No desktop environment detected - desktop components will NOT be installed"
        fi
    elif [ "$INSTALL_DESKTOP" == "force" ]; then
        INSTALL_DESKTOP="true"
        log_success "Desktop components will be installed (forced by --desktop flag)"
    elif [ "$INSTALL_DESKTOP" == "skip" ]; then
        INSTALL_DESKTOP="false"
        log_info "Desktop components will be skipped (forced by --skip-desktop flag)"
    fi
    
    # Show configuration summary
    if [ $# -eq 0 ]; then
        log_info "No arguments provided. Using default configuration:"
        log_info "  - Installing all development components"
        log_info "  - Desktop components: $([ "$INSTALL_DESKTOP" = "true" ] && echo "YES (auto-detected)" || echo "NO (server mode)")"
        log_info "  - Configuring users: root, $(whoami)"
    fi
}

# ============================================================================
# User Management (Simplified - delegates to modules)
# ============================================================================

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

# ============================================================================
# Enhanced Module Execution Functions
# ============================================================================

# Execute module with configuration and enhanced error handling
execute_module_with_config() {
    local module_name="$1"
    shift
    local additional_args=("$@")
    
    log_info "Preparing to execute module: $module_name"
    
    # Check if module exists before execution
    if ! module_exists "$module_name"; then
        log_error "Module '$module_name' not found"
        return 1
    fi
    
    # Check module dependencies
    if ! check_module_dependencies "$module_name"; then
        log_error "Module '$module_name' dependencies not satisfied"
        return 1
    fi
    
    # Prepare environment variables for modules
    export INSTALL_DOCKER
    export INSTALL_GO
    export INSTALL_PYTHON
    export INSTALL_KOTLIN
    export INSTALL_JVM
    export INSTALL_DOTNET
    export INSTALL_DESKTOP
    export ALL_USERS
    
    # Convert ALL_USERS array to comma-separated string for modules
    local users_string=""
    if [ ${#ALL_USERS[@]} -gt 0 ]; then
        users_string=$(IFS=','; echo "${ALL_USERS[*]}")
        export USERS_TO_CONFIGURE_STRING="$users_string"
    fi
    
    # Execute the module using the framework with enhanced error handling
    local module_start_time=$(date +%s)
    
    if execute_module "$module_name" "${additional_args[@]}"; then
        local module_end_time=$(date +%s)
        local module_duration=$((module_end_time - module_start_time))
        log_success "Module '$module_name' completed successfully in ${module_duration}s"
        return 0
    else
        local module_end_time=$(date +%s)
        local module_duration=$((module_end_time - module_start_time))
        log_error "Module '$module_name' failed after ${module_duration}s"
        return 1
    fi
}

# Execute modules with dependency resolution and skip logic
execute_modules_with_config() {
    local requested_modules=("$@")
    
    log_info "Starting module execution with dependency resolution"
    log_info "Requested modules: ${requested_modules[*]}"
    
    # Use the framework's dependency resolution
    if execute_modules_with_dependencies "${requested_modules[@]}"; then
        log_success "All modules executed successfully"
        return 0
    else
        log_error "One or more modules failed execution"
        return 1
    fi
}

# ============================================================================
# Summary Display (Preserved for Backward Compatibility)
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
    
    if [ "$INSTALL_DESKTOP" == "true" ]; then
        echo -e "  ${GREEN}✓${RESET} Desktop components (VSCode, Chrome, fonts, terminal emulators)"
    else
        echo -e "  ${GRAY}⏭${RESET} Desktop components (skipped)"
    fi
    
    echo ""
    echo -e "${BOLD}Users Configured:${RESET}"
    for user in "${ALL_USERS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} $user (zsh, oh-my-zsh, vim, aliases, environment)"
    done
    
    echo ""
    echo -e "${BOLD}System Configuration:${RESET}"
    echo -e "  ${GREEN}✓${RESET} Timezone: America/Sao_Paulo"
    echo -e "  ${GREEN}✓${RESET} Default shell: Zsh"
    echo -e "  ${GREEN}✓${RESET} Default editor: micro"
    echo -e "  ${GREEN}✓${RESET} Package repositories updated"
    echo -e "  ${GREEN}✓${RESET} System cleanup completed"
    
    echo ""
    echo -e "${BOLD}Execution Time:${RESET} ${minutes}m ${seconds}s"
    echo ""
    echo -e "${BOLD}${GREEN}✓ Installation completed successfully!${RESET}"
    echo ""
    echo -e "${BOLD}Next Steps:${RESET}"
    echo -e "  1. ${CYAN}Logout and login again${RESET} to apply shell changes"
    echo -e "  2. ${CYAN}Restart your terminal${RESET} to see the new configuration"
    echo -e "  3. ${CYAN}Run 'source ~/.zshrc'${RESET} to apply changes immediately"
    
    if [ "$INSTALL_DOCKER" == "true" ]; then
        echo -e "  4. ${CYAN}Test Docker${RESET} with: docker run hello-world"
    fi
    
    if [ "$INSTALL_GO" == "true" ]; then
        echo -e "  5. ${CYAN}Test Golang${RESET} with: go version"
    fi
    
    echo ""
    echo -e "${BOLD}${CYAN}Happy coding! 🚀${RESET}"
    echo ""
    
    # Print module execution summary
    print_module_summary
}

# ============================================================================
# Main Function - Modular Orchestration
# ============================================================================

main() {
    # Record start time
    START_TIME=$(date +%s)
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║          Linux Development Environment Setup Script                        ║${RESET}"
    echo -e "${BOLD}${CYAN}║                        Modular Architecture                                ║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # Check privileges
    check_privileges "$@"
    
    # Parse arguments (includes desktop auto-detection)
    parse_arguments "$@"
    
    # Setup users list
    setup_users_list
    
    echo ""
    log_info "Starting installation process using modular architecture..."
    echo ""
    
    # Build list of modules to execute based on configuration
    local modules_to_execute=()
    
    # Core modules (always executed)
    modules_to_execute+=("system-detection")
    
    # Optional modules based on flags
    if [ "$INSTALL_DOCKER" == "true" ]; then
        modules_to_execute+=("docker-install")
    fi
    
    if [ "$INSTALL_GO" == "true" ]; then
        modules_to_execute+=("languages/golang-install")
    fi
    
    if [ "$INSTALL_PYTHON" == "true" ]; then
        modules_to_execute+=("languages/python-install")
    fi
    
    if [ "$INSTALL_DOTNET" == "true" ]; then
        modules_to_execute+=("languages/dotnet-install")
    fi
    
    if [ "$INSTALL_JVM" == "true" ] || [ "$INSTALL_KOTLIN" == "true" ]; then
        modules_to_execute+=("languages/jvm-kotlin-install")
    fi
    
    # Terminal configuration (always executed)
    modules_to_execute+=("terminal-config")
    
    # Desktop components (conditional)
    if [ "$INSTALL_DESKTOP" == "true" ]; then
        modules_to_execute+=("desktop-components")
    fi
    
    # Execute modules using framework with dependency resolution
    log_info "Executing modules with dependency resolution: ${modules_to_execute[*]}"
    
    if ! execute_modules_with_config "${modules_to_execute[@]}"; then
        log_error "Module execution failed - stopping"
        exit 1
    fi
    
    # Display summary
    display_summary
}

# ============================================================================
# Script Entry Point
# ============================================================================

# Run main function
main "$@"