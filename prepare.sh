#!/bin/bash

# Env Prepare System - Main Orchestrator Script
# Transforms Ubuntu-based Linux installations into development environments

set -euo pipefail

# Source the logging utility
source util/log.sh

SCRIPT_NAME="prepare"

# Global variables for configuration
TARGET_USERS=()
SELECTED_MODULES=()
INSTALL_BASE_PACKAGES=true

# Available optional modules
declare -A AVAILABLE_MODULES=(
    ["docker"]="modules/docker.sh"
    ["golang"]="modules/golang.sh"
    ["jvm"]="modules/jvm.sh"
    ["vscode"]="modules/vscode.sh"
    ["fonts"]="modules/fonts.sh"
    ["terminator"]="modules/terminator.sh"
    ["dotnet"]="modules/dotnet.sh"
)

# Display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -u=user1,user2,userN    Create specified users (comma-separated list)
    -docker                 Install Docker
    -golang                 Install Go programming language
    -jvm                    Install JVM using SDKMAN
    -vscode                 Install Visual Studio Code
    -fonts                  Install Nerd Fonts and Powerline Fonts
    -terminator             Install Terminator terminal emulator
    -dotnet                 Install .NET runtime and SDK
    -h, --help              Show this help message

Examples:
    $0                      Install base packages only
    $0 -u=dev,admin         Create users 'dev' and 'admin' with base packages
    $0 -docker -golang      Install base packages, Docker, and Go
    $0 -u=developer -docker -vscode    Create 'developer' user and install Docker and VS Code

EOF
}

# Parse command-line parameters
parse_parameters() {
    log_info "$SCRIPT_NAME" "Parsing command-line parameters"
    
    for arg in "$@"; do
        case $arg in
            -u=*)
                local user_list="${arg#*=}"
                parse_user_list "$user_list"
                ;;
            -docker)
                SELECTED_MODULES+=("docker")
                ;;
            -golang)
                SELECTED_MODULES+=("golang")
                ;;
            -jvm)
                SELECTED_MODULES+=("jvm")
                ;;
            -vscode)
                SELECTED_MODULES+=("vscode")
                ;;
            -fonts)
                SELECTED_MODULES+=("fonts")
                ;;
            -terminator)
                SELECTED_MODULES+=("terminator")
                ;;
            -dotnet)
                SELECTED_MODULES+=("dotnet")
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_warn "$SCRIPT_NAME" "Unknown parameter: $arg"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_info "$SCRIPT_NAME" "Parameters parsed successfully"
    if [[ ${#TARGET_USERS[@]} -gt 0 ]]; then
        log_info "$SCRIPT_NAME" "Target users: ${TARGET_USERS[*]}"
    fi
    if [[ ${#SELECTED_MODULES[@]} -gt 0 ]]; then
        log_info "$SCRIPT_NAME" "Selected modules: ${SELECTED_MODULES[*]}"
    fi
}

# Parse and validate comma-separated user list
parse_user_list() {
    local user_list="$1"
    
    if [[ -z "$user_list" ]]; then
        log_warn "$SCRIPT_NAME" "Empty user list provided"
        return 0
    fi
    
    # Split comma-separated list and validate each username
    IFS=',' read -ra users <<< "$user_list"
    for user in "${users[@]}"; do
        # Trim whitespace
        user=$(echo "$user" | xargs)
        
        if validate_username "$user"; then
            TARGET_USERS+=("$user")
            log_debug "$SCRIPT_NAME" "Added user to target list: $user"
        else
            log_warn "$SCRIPT_NAME" "Invalid username skipped: $user"
        fi
    done
    
    if [[ ${#TARGET_USERS[@]} -eq 0 ]]; then
        log_warn "$SCRIPT_NAME" "No valid users found in list: $user_list"
    fi
}

# Validate username according to Linux standards
validate_username() {
    local username="$1"
    
    # Check if username is empty
    if [[ -z "$username" ]]; then
        return 1
    fi
    
    # Check username length (typically 1-32 characters)
    if [[ ${#username} -gt 32 ]]; then
        return 1
    fi
    
    # Check if username contains only valid characters
    # Valid: lowercase letters, digits, hyphens, underscores
    # Must start with a letter or underscore
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        return 1
    fi
    
    return 0
}

# Create user accounts as specified
create_users() {
    if [[ ${#TARGET_USERS[@]} -eq 0 ]]; then
        log_info "$SCRIPT_NAME" "No users to create"
        return 0
    fi
    
    log_info "$SCRIPT_NAME" "Creating user accounts"
    
    for username in "${TARGET_USERS[@]}"; do
        if id "$username" &>/dev/null; then
            log_info "$SCRIPT_NAME" "User already exists: $username"
        else
            log_info "$SCRIPT_NAME" "Creating user: $username"
            
            # Create user with zsh as default shell
            if useradd -m -s /bin/zsh "$username"; then
                log_info "$SCRIPT_NAME" "Successfully created user: $username"
                
                # Set up basic home directory structure
                local home_dir="/home/$username"
                if [[ -d "$home_dir" ]]; then
                    # Ensure proper ownership
                    chown -R "$username:$username" "$home_dir"
                    log_debug "$SCRIPT_NAME" "Set ownership for $home_dir"
                fi
                
                # Add user to sudoers group for sudo access without password
                if usermod -aG sudo "$username"; then
                    log_info "$SCRIPT_NAME" "Added $username to sudoers group"
                else
                    log_warn "$SCRIPT_NAME" "Failed to add $username to sudoers group"
                fi
                
                # Add user to docker group for docker access without sudo
                if getent group docker &>/dev/null; then
                    if usermod -aG docker "$username"; then
                        log_info "$SCRIPT_NAME" "Added $username to docker group"
                    else
                        log_warn "$SCRIPT_NAME" "Failed to add $username to docker group"
                    fi
                else
                    log_debug "$SCRIPT_NAME" "Docker group not found, will be created during docker installation"
                fi
            else
                log_error "$SCRIPT_NAME" "Failed to create user: $username"
            fi
        fi
    done
}

# Get all users that should receive configuration (existing + created + invoking user + root)
get_all_target_users() {
    local all_users=()
    local seen_users=()
    
    # Add created/specified users
    for user in "${TARGET_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            all_users+=("$user")
            seen_users+=("$user")
        fi
    done
    
    # Add the invoking user (if not root and not already in list)
    if [[ "$EUID" -ne 0 ]]; then
        local invoking_user
        invoking_user=$(whoami)
        if [[ ! " ${seen_users[@]} " =~ " ${invoking_user} " ]]; then
            all_users+=("$invoking_user")
            seen_users+=("$invoking_user")
            log_debug "$SCRIPT_NAME" "Added invoking user to configuration list: $invoking_user"
        fi
    fi
    
    # Add root user (if not already in list)
    if [[ ! " ${seen_users[@]} " =~ " root " ]]; then
        all_users+=("root")
        log_debug "$SCRIPT_NAME" "Added root user to configuration list"
    fi
    
    printf '%s\n' "${all_users[@]}"
}

# Execute base packages installation
execute_base_installation() {
    log_info "$SCRIPT_NAME" "Executing base packages installation"
    
    local base_module="modules/base.sh"
    if [[ -f "$base_module" ]]; then
        log_info "$SCRIPT_NAME" "Running base packages installer"
        if bash "$base_module"; then
            log_info "$SCRIPT_NAME" "Base packages installation completed"
        else
            log_error "$SCRIPT_NAME" "Base packages installation failed"
            return 1
        fi
    else
        log_warn "$SCRIPT_NAME" "Base packages module not found: $base_module"
    fi
}

# Execute selected optional modules
execute_optional_modules() {
    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        log_info "$SCRIPT_NAME" "No optional modules selected"
        return 0
    fi
    
    log_info "$SCRIPT_NAME" "Executing optional modules"
    
    for module_name in "${SELECTED_MODULES[@]}"; do
        local module_path="${AVAILABLE_MODULES[$module_name]}"
        
        if [[ -f "$module_path" ]]; then
            log_info "$SCRIPT_NAME" "Running module: $module_name"
            if bash "$module_path"; then
                log_info "$SCRIPT_NAME" "Module completed successfully: $module_name"
            else
                log_error "$SCRIPT_NAME" "Module failed: $module_name"
                # Continue with other modules even if one fails
            fi
        else
            log_warn "$SCRIPT_NAME" "Module file not found: $module_path"
        fi
    done
}

# Configure environment for all target users
configure_user_environments() {
    local users
    mapfile -t users < <(get_all_target_users)
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_info "$SCRIPT_NAME" "No users to configure"
        return 0
    fi
    
    log_info "$SCRIPT_NAME" "Configuring user environments"
    
    for username in "${users[@]}"; do
        log_info "$SCRIPT_NAME" "Configuring environment for user: $username"
        configure_user_profile "$username"
    done
}

# Configure individual user profile
configure_user_profile() {
    local username="$1"
    local home_dir
    local profile_file
    
    # Determine home directory based on username
    if [[ "$username" == "root" ]]; then
        home_dir="/root"
    else
        home_dir="/home/$username"
    fi
    
    profile_file="$home_dir/.profile"
    
    if [[ ! -d "$home_dir" ]]; then
        log_warn "$SCRIPT_NAME" "Home directory not found for user: $username"
        return 1
    fi
    
    # Create .profile if it doesn't exist
    if [[ ! -f "$profile_file" ]]; then
        touch "$profile_file"
        if [[ "$username" != "root" ]]; then
            chown "$username:$username" "$profile_file"
        fi
    fi
    
    # Add basic environment configuration
    # This will be expanded by individual modules
    log_debug "$SCRIPT_NAME" "Basic profile configuration completed for: $username"
}

# Main execution function
main() {
    log_info "$SCRIPT_NAME" "Starting Env Prepare System"
    
    # Check if running as root (required for user creation and package installation)
    # Note: Some operations require root, but configuration can be done for current user
    if [[ "$EUID" -ne 0 ]]; then
        log_warn "$SCRIPT_NAME" "Some operations require root privileges (user creation, package installation)"
        log_info "$SCRIPT_NAME" "Proceeding with configuration for current user only"
    fi
    
    # Parse command-line parameters
    parse_parameters "$@"
    
    # Create users if specified (requires root)
    if [[ "$EUID" -eq 0 ]]; then
        create_users
    else
        if [[ ${#TARGET_USERS[@]} -gt 0 ]]; then
            log_error "$SCRIPT_NAME" "User creation requires root privileges"
            exit 1
        fi
    fi
    
    # Execute base packages installation (requires root)
    if [[ "$EUID" -eq 0 && "$INSTALL_BASE_PACKAGES" == true ]]; then
        execute_base_installation
    fi
    
    # Execute optional modules (requires root)
    if [[ "$EUID" -eq 0 ]]; then
        execute_optional_modules
    fi
    
    # Configure user environments (can be done for current user)
    configure_user_environments
    
    log_info "$SCRIPT_NAME" "System setup complete"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi