#!/usr/bin/env bash
# =============================================================================
# Ubuntu Development Environment Setup Script
# =============================================================================
# Description : Automates installation and configuration of a complete
#               development environment on Ubuntu 25.x or later.
# Usage       : sudo ./setup.sh [OPTIONS]
# Run --help for full usage information.
# =============================================================================

set -euo pipefail

# =============================================================================
# GLOBAL STATE VARIABLES
# =============================================================================

# Tracking arrays — populated during installation
INSTALLED_COMPONENTS=()   # Components successfully installed this run
SKIPPED_COMPONENTS=()     # Components already present (skipped)
FAILED_COMPONENTS=()      # Components that failed to install

# Component group flags (0 = disabled, 1 = enabled)
INSTALL_BASE=1
INSTALL_DESKTOP=0
INSTALL_DOCKER=0
INSTALL_GOLANG=0
INSTALL_JAVA=0
INSTALL_DOTNET=0

# Additional users to create beyond the default "dev" user
EXTRA_USERS=()

# Timing and logging
SCRIPT_START_TIME=$(date +%s)
LOG_FILE=""

# =============================================================================
# LOGGING SYSTEM
# =============================================================================

# log() — Write an [INFO] level message to stdout and the log file.
# Usage: log "message"
log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [INFO]  ${message}"
    echo "${line}"
    if [[ -n "${LOG_FILE}" ]]; then
        echo "${line}" >> "${LOG_FILE}"
    fi
}

# log_ok() — Write an [OK] level message to stdout and the log file.
# Usage: log_ok "message"
log_ok() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [OK]    ${message}"
    echo "${line}"
    if [[ -n "${LOG_FILE}" ]]; then
        echo "${line}" >> "${LOG_FILE}"
    fi
}

# log_err() — Write an [ERROR] level message to stdout and the log file.
# Usage: log_err "message"
log_err() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [ERROR] ${message}"
    echo "${line}" >&2
    if [[ -n "${LOG_FILE}" ]]; then
        echo "${line}" >> "${LOG_FILE}"
    fi
}

# =============================================================================
# LOGGING INITIALISATION
# =============================================================================

# init_logging() — Create the timestamped log file and record the start time.
# Must be called after prerequisite checks pass (requires write access to /var/log).
init_logging() {
    LOG_FILE="/var/log/dev-setup-$(date +%Y-%m-%d-%H-%M-%S).log"
    touch "${LOG_FILE}"
    log "Logging initialised. Log file: ${LOG_FILE}"
    log "Script started at: $(date '+%Y-%m-%d %H:%M:%S')"
}

# =============================================================================
# PREREQUISITE VALIDATION
# =============================================================================

# validate_root() — Ensure the script is running as root (EUID == 0).
# Must be the FIRST check called in main(). Uses plain echo to stderr
# because the log system is not yet initialised at this point.
validate_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: This script must be run as root. Use: sudo ./setup.sh" >&2
        exit 1
    fi
}

# validate_ubuntu() — Ensure the OS is Ubuntu 25 or later.
# Sources /etc/os-release and checks ID and VERSION_ID.
validate_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        echo "ERROR: /etc/os-release not found. Cannot determine OS." >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    if [[ "${ID}" != "ubuntu" ]]; then
        echo "ERROR: This script requires Ubuntu. Detected OS: ${ID}" >&2
        exit 1
    fi

    local major_version
    major_version=$(echo "${VERSION_ID}" | cut -d'.' -f1)

    if [[ "${major_version}" -lt 25 ]]; then
        echo "ERROR: Ubuntu 25 or later is required. Detected: ${VERSION_ID}" >&2
        exit 1
    fi
}

# validate_ram() — Ensure the system has at least 4096 MB of total RAM.
# Reads MemTotal from /proc/meminfo (in kB) and converts to MB.
validate_ram() {
    local mem_kb
    mem_kb=$(grep -m1 '^MemTotal:' /proc/meminfo | awk '{print $2}')

    local ram_mb
    ram_mb=$(( mem_kb / 1024 ))

    if [[ "${ram_mb}" -lt 4096 ]]; then
        echo "ERROR: Minimum 4096 MB RAM required. Detected: ${ram_mb} MB" >&2
        exit 1
    fi
}

# =============================================================================
# CLI ARGUMENT PARSING
# =============================================================================

# show_help() — Print usage information to stdout.
show_help() {
    cat <<'EOF'
Usage: sudo ./setup.sh [OPTIONS]

Component Groups:
  --base          Install BASE group (default): zsh, vim, micro, eza, unzip, curl, wget,
                  awesome-vim, oh-my-bash, oh-my-zsh, python3+pip3
  --desktop       Install DESKTOP group: VS Code, nerd-fonts, powerline-fonts, Terminator, Chrome
  --docker        Install DOCKER group: Docker Engine (open source)
  --golang        Install GOLANG group: Golang Builder
  --java          Install JAVA group: SDKMAN + latest JDK
  --dotnet        Install DOTNET group: dotnet core SDK (latest)
  --full          Install ALL component groups

User Management:
  --users USER1 [USER2 ...]   Create additional users (default user 'dev' always created)

Other:
  --help, -h      Display this help message

Examples:
  sudo ./setup.sh                        # Install BASE group only
  sudo ./setup.sh --full                 # Install all groups
  sudo ./setup.sh --base --docker        # Install BASE + Docker
  sudo ./setup.sh --java --golang        # Install BASE + Java + Golang
  sudo ./setup.sh --users alice bob      # Install BASE + create users alice and bob
  ./run-in-docker.sh --full              # Run full install inside Docker
EOF
}

# parse_args() — Parse command-line arguments and set group flags / EXTRA_USERS.
# Usage: parse_args "$@"
parse_args() {
    local collecting_users=0

    for arg in "$@"; do
        # If we're collecting usernames and hit a new flag, stop collecting
        if [[ "${collecting_users}" -eq 1 && "${arg}" == --* ]]; then
            collecting_users=0
        fi

        if [[ "${collecting_users}" -eq 1 ]]; then
            EXTRA_USERS+=("${arg}")
            continue
        fi

        case "${arg}" in
            --base)
                INSTALL_BASE=1
                ;;
            --desktop)
                INSTALL_DESKTOP=1
                ;;
            --docker)
                INSTALL_DOCKER=1
                ;;
            --golang)
                INSTALL_GOLANG=1
                ;;
            --java)
                INSTALL_JAVA=1
                ;;
            --dotnet)
                INSTALL_DOTNET=1
                ;;
            --full)
                INSTALL_BASE=1
                INSTALL_DESKTOP=1
                INSTALL_DOCKER=1
                INSTALL_GOLANG=1
                INSTALL_JAVA=1
                INSTALL_DOTNET=1
                ;;
            --users)
                collecting_users=1
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "ERROR: Unknown parameter: ${arg}" >&2
                show_help
                exit 1
                ;;
        esac
    done

    # Default to BASE group when no group flag was set
    if [[ "${INSTALL_BASE}" -eq 0 && \
          "${INSTALL_DESKTOP}" -eq 0 && \
          "${INSTALL_DOCKER}" -eq 0 && \
          "${INSTALL_GOLANG}" -eq 0 && \
          "${INSTALL_JAVA}" -eq 0 && \
          "${INSTALL_DOTNET}" -eq 0 ]]; then
        INSTALL_BASE=1
    fi
}

# =============================================================================
# SYSTEM UPDATE
# =============================================================================

# update_system() — Run apt-get update and apt-get upgrade non-interactively.
# Logs progress and errors. Non-fatal: failures are logged but do not exit.
update_system() {
    log "Updating system package list..."
    if ! DEBIAN_FRONTEND=noninteractive apt-get update -y; then
        log_err "System update failed."
        return 0
    fi

    log "Upgrading installed packages..."
    if ! DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; then
        log_err "System update failed."
        return 0
    fi

    log_ok "System update completed successfully."
}

# =============================================================================
# USER MANAGEMENT
# =============================================================================

# create_user() — Create a system user with the given username and password.
# Usage: create_user "username" "password"
create_user() {
    local username="$1"
    local password="$2"

    log "Checking if user '${username}' exists..."

    if id "${username}" &>/dev/null; then
        log_ok "User '${username}' already exists. Skipping."
        return 0
    fi

    if useradd -m -s /bin/bash "${username}"; then
        echo "${username}:${password}" | chpasswd
        log_ok "User '${username}' created successfully."
    else
        log_err "Failed to create user '${username}'."
    fi
}

# create_default_user() — Create the default development user 'dev'.
create_default_user() {
    log "Creating default development user 'dev'..."
    create_user "dev" "dev123"
}

# create_extra_users() — Create any additional users specified via --users flag.
create_extra_users() {
    if [[ "${#EXTRA_USERS[@]}" -eq 0 ]]; then
        return
    fi

    log "Creating additional users: ${EXTRA_USERS[*]}"

    for user in "${EXTRA_USERS[@]}"; do
        create_user "${user}" "changeme123"
    done

    log "Note: Additional users created with default password 'changeme123'. Please change it."
}

# =============================================================================
# BASE GROUP - INSTALL FUNCTIONS
# =============================================================================

# install_zsh() — Install the Z shell via apt.
install_zsh() {
    log "Installing zsh..."
    if command -v zsh &>/dev/null; then
        log_ok "zsh already installed. Skipping."
        SKIPPED_COMPONENTS+=("zsh")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y zsh; then
        log_ok "zsh installed successfully."
        INSTALLED_COMPONENTS+=("zsh")
    else
        log_err "Failed to install zsh."
        FAILED_COMPONENTS+=("zsh")
        return 1
    fi
}

# install_vim() — Install Vim via apt.
install_vim() {
    log "Installing vim..."
    if command -v vim &>/dev/null; then
        log_ok "vim already installed. Skipping."
        SKIPPED_COMPONENTS+=("vim")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y vim; then
        log_ok "vim installed successfully."
        INSTALLED_COMPONENTS+=("vim")
    else
        log_err "Failed to install vim."
        FAILED_COMPONENTS+=("vim")
        return 1
    fi
}

# install_micro() — Install the Micro editor via the official install script.
install_micro() {
    log "Installing micro..."
    if command -v micro &>/dev/null; then
        log_ok "micro already installed. Skipping."
        SKIPPED_COMPONENTS+=("micro")
        return 0
    fi
    if curl https://getmic.ro | bash && mv micro /usr/local/bin/micro; then
        log_ok "micro installed successfully."
        INSTALLED_COMPONENTS+=("micro")
    else
        log_err "Failed to install micro."
        FAILED_COMPONENTS+=("micro")
        return 1
    fi
}

# install_eza() — Install eza (modern ls replacement) via apt.
install_eza() {
    log "Installing eza..."
    if command -v eza &>/dev/null; then
        log_ok "eza already installed. Skipping."
        SKIPPED_COMPONENTS+=("eza")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y eza; then
        log_ok "eza installed successfully."
        INSTALLED_COMPONENTS+=("eza")
    else
        log_err "Failed to install eza."
        FAILED_COMPONENTS+=("eza")
        return 1
    fi
}

# install_unzip() — Install unzip via apt.
install_unzip() {
    log "Installing unzip..."
    if command -v unzip &>/dev/null; then
        log_ok "unzip already installed. Skipping."
        SKIPPED_COMPONENTS+=("unzip")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y unzip zip; then
        log_ok "unzip installed successfully."
        INSTALLED_COMPONENTS+=("unzip")
    else
        log_err "Failed to install unzip."
        FAILED_COMPONENTS+=("unzip")
        return 1
    fi
}

# install_curl() — Install curl via apt.
install_curl() {
    log "Installing curl..."
    if command -v curl &>/dev/null; then
        log_ok "curl already installed. Skipping."
        SKIPPED_COMPONENTS+=("curl")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y curl; then
        log_ok "curl installed successfully."
        INSTALLED_COMPONENTS+=("curl")
    else
        log_err "Failed to install curl."
        FAILED_COMPONENTS+=("curl")
        return 1
    fi
}

# install_wget() — Install wget via apt.
install_wget() {
    log "Installing wget..."
    if command -v wget &>/dev/null; then
        log_ok "wget already installed. Skipping."
        SKIPPED_COMPONENTS+=("wget")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y wget; then
        log_ok "wget installed successfully."
        INSTALLED_COMPONENTS+=("wget")
    else
        log_err "Failed to install wget."
        FAILED_COMPONENTS+=("wget")
        return 1
    fi
}

# install_awesome_vim() — Install Vundle and the vim-awesome plugin set.
install_awesome_vim() {
    log "Installing awesome-vim..."
    if [[ -d "${HOME}/.vim/bundle/Vundle.vim" ]]; then
        log_ok "awesome-vim already installed. Skipping."
        SKIPPED_COMPONENTS+=("awesome-vim")
        return 0
    fi

    # Ensure git is available
    if ! command -v git &>/dev/null; then
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y git; then
            log_err "Failed to install awesome-vim (git dependency failed)."
            FAILED_COMPONENTS+=("awesome-vim")
            return 1
        fi
    fi

    # Clone Vundle
    if ! git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"; then
        log_err "Failed to install awesome-vim (Vundle clone failed)."
        FAILED_COMPONENTS+=("awesome-vim")
        return 1
    fi

    # Write a minimal ~/.vimrc with Vundle config and vim-awesome plugin
    cat > "${HOME}/.vimrc" <<'VIMRC'
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-awesome/vim-awesome'

call vundle#end()
filetype plugin indent on
VIMRC

    # Install plugins non-interactively
    if vim +PluginInstall +qall; then
        log_ok "awesome-vim installed successfully."
        INSTALLED_COMPONENTS+=("awesome-vim")
    else
        log_err "Failed to install awesome-vim (PluginInstall failed)."
        FAILED_COMPONENTS+=("awesome-vim")
        return 1
    fi
}

# install_oh_my_bash() — Install Oh My Bash framework.
install_oh_my_bash() {
    log "Installing oh-my-bash..."
    if [[ -d "${HOME}/.oh-my-bash" ]]; then
        log_ok "oh-my-bash already installed. Skipping."
        SKIPPED_COMPONENTS+=("oh-my-bash")
        return 0
    fi
    if bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended; then
        log_ok "oh-my-bash installed successfully."
        INSTALLED_COMPONENTS+=("oh-my-bash")
    else
        log_err "Failed to install oh-my-bash."
        FAILED_COMPONENTS+=("oh-my-bash")
        return 1
    fi
}

# install_oh_my_zsh() — Install Oh My Zsh framework.
install_oh_my_zsh() {
    log "Installing oh-my-zsh..."
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        log_ok "oh-my-zsh already installed. Skipping."
        SKIPPED_COMPONENTS+=("oh-my-zsh")
        return 0
    fi
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        log_ok "oh-my-zsh installed successfully."
        INSTALLED_COMPONENTS+=("oh-my-zsh")
    else
        log_err "Failed to install oh-my-zsh."
        FAILED_COMPONENTS+=("oh-my-zsh")
        return 1
    fi
}

# install_python3() — Install Python 3 and pip3 via apt.
install_python3() {
    log "Installing python3..."
    if command -v python3 &>/dev/null; then
        log_ok "python3 already installed. Skipping."
        SKIPPED_COMPONENTS+=("python3")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip; then
        log_ok "python3 installed successfully."
        INSTALLED_COMPONENTS+=("python3")
    else
        log_err "Failed to install python3."
        FAILED_COMPONENTS+=("python3")
        return 1
    fi
}

# =============================================================================
# SHELL AND ALIAS CONFIGURATION
# =============================================================================

# configure_shell_for_user() — Set zsh as default shell, install oh-my-zsh,
# and set the frisk theme for a single user. All steps are idempotent.
# Usage: configure_shell_for_user "username" "homedir"
configure_shell_for_user() {
    local username="$1"
    local homedir="$2"
    local zsh_path
    zsh_path=$(which zsh)

    # Step 1: Set zsh as default shell (idempotent)
    local current_shell
    current_shell=$(getent passwd "$username" | cut -d: -f7)
    if [[ "$current_shell" == "$zsh_path" ]]; then
        log "Default shell already zsh for $username. Skipping."
    else
        if chsh -s "$zsh_path" "$username"; then
            log_ok "Default shell set to zsh for $username."
        else
            log_err "Failed to set default shell for $username."
        fi
    fi

    # Step 2: Install oh-my-zsh for this user (idempotent)
    if [[ -d "$homedir/.oh-my-zsh" ]]; then
        log "oh-my-zsh already installed for $username. Skipping."
    else
        if sudo -u "$username" env HOME="$homedir" \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended; then
            log_ok "oh-my-zsh installed for $username."
        else
            log_err "Failed to install oh-my-zsh for $username."
        fi
    fi

    # Step 3: Set frisk theme in ~/.zshrc (idempotent)
    local zshrc="$homedir/.zshrc"
    if [[ -f "$zshrc" ]] && grep -q 'ZSH_THEME="frisk"' "$zshrc"; then
        log "oh-my-zsh theme already set to frisk for $username. Skipping."
    else
        if [[ -f "$zshrc" ]]; then
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="frisk"/' "$zshrc"
            log_ok "oh-my-zsh theme set to frisk for $username."
        else
            log_err "~/.zshrc not found for $username. Cannot set theme."
        fi
    fi
}

# configure_shell_for_all_users() — Iterate /etc/passwd and apply
# configure_shell_for_user() for every user with a home under /root or /home/*.
configure_shell_for_all_users() {
    log "Configuring zsh + oh-my-zsh for all system users..."
    while IFS=: read -r username _ _ _ _ homedir _; do
        [[ "$homedir" == /root || "$homedir" == /home/* ]] || continue
        [[ -d "$homedir" ]] || continue
        log "Configuring shell for user: $username (home: $homedir)"
        configure_shell_for_user "$username" "$homedir"
    done < /etc/passwd
    log_ok "Shell configuration completed for all users."
}

# configure_global_aliases() — Append eza ls/lt aliases to /etc/bash.bashrc
# and /etc/zsh/zshenv if not already present. Idempotent.
configure_global_aliases() {
    log "Configuring global eza aliases..."
    local alias_ls='alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"'
    local alias_lt='alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"'
    local targets=("/etc/bash.bashrc" "/etc/zsh/zshenv")

    for target in "${targets[@]}"; do
        # Ensure target file exists
        [[ -f "$target" ]] || touch "$target"

        if grep -qF "$alias_ls" "$target" && grep -qF "$alias_lt" "$target"; then
            log "Global aliases already present in $target. Skipping."
        else
            {
                echo ""
                echo "# eza aliases (added by dev-setup)"
                echo "$alias_ls"
                echo "$alias_lt"
            } >> "$target" && log_ok "Global aliases added to $target." \
                || log_err "Failed to write global aliases to $target."
        fi
    done
}

# =============================================================================
# GROUP ORCHESTRATORS
# =============================================================================

# install_base_group() — Run all BASE group installers in dependency order.
# curl and wget are installed first since other installers depend on them.
install_base_group() {
    log "=== Installing BASE group ==="
    install_curl
    install_wget
    install_unzip
    install_zsh
    install_vim
    install_micro
    install_eza
    install_python3
    install_oh_my_bash
    install_oh_my_zsh
    install_awesome_vim
    configure_shell_for_all_users
    configure_global_aliases
    log_ok "=== BASE group installation complete ==="
}

# =============================================================================
# DESKTOP GROUP - INSTALL FUNCTIONS
# =============================================================================

# install_vscode() — Install Visual Studio Code via Microsoft apt repository.
install_vscode() {
    log "Installing VS Code..."
    if command -v code &>/dev/null; then
        log_ok "VS Code already installed. Skipping."
        SKIPPED_COMPONENTS+=("vscode")
        return 0
    fi
    if wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg && \
       echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
       DEBIAN_FRONTEND=noninteractive apt-get update -y && \
       DEBIAN_FRONTEND=noninteractive apt-get install -y code; then
        log_ok "VS Code installed successfully."
        INSTALLED_COMPONENTS+=("vscode")
    else
        log_err "Failed to install VS Code."
        FAILED_COMPONENTS+=("vscode")
        return 1
    fi
}

# install_nerd_fonts() — Download and install FiraCode Nerd Font to /usr/local/share/fonts/NerdFonts/.
install_nerd_fonts() {
    log "Installing Nerd Fonts (FiraCode)..."
    if [[ -d "/usr/local/share/fonts/NerdFonts" ]]; then
        log_ok "Nerd Fonts already installed. Skipping."
        SKIPPED_COMPONENTS+=("nerd-fonts")
        return 0
    fi
    if mkdir -p /usr/local/share/fonts/NerdFonts && \
       wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -O /tmp/FiraCode.zip && \
       unzip -q /tmp/FiraCode.zip -d /usr/local/share/fonts/NerdFonts/ && \
       fc-cache -fv && \
       rm /tmp/FiraCode.zip; then
        log_ok "Nerd Fonts installed successfully."
        INSTALLED_COMPONENTS+=("nerd-fonts")
    else
        log_err "Failed to install Nerd Fonts."
        FAILED_COMPONENTS+=("nerd-fonts")
        return 1
    fi
}

# install_powerline_fonts() — Clone and install Powerline fonts.
install_powerline_fonts() {
    log "Installing Powerline fonts..."
    if fc-list | grep -qi "powerline"; then
        log_ok "Powerline fonts already installed. Skipping."
        SKIPPED_COMPONENTS+=("powerline-fonts")
        return 0
    fi
    if git clone https://github.com/powerline/fonts.git /tmp/powerline-fonts --depth=1 && \
       /tmp/powerline-fonts/install.sh && \
       rm -rf /tmp/powerline-fonts; then
        log_ok "Powerline fonts installed successfully."
        INSTALLED_COMPONENTS+=("powerline-fonts")
    else
        log_err "Failed to install Powerline fonts."
        FAILED_COMPONENTS+=("powerline-fonts")
        return 1
    fi
}

# install_terminator() — Install Terminator terminal emulator via apt.
install_terminator() {
    log "Installing Terminator..."
    if command -v terminator &>/dev/null; then
        log_ok "Terminator already installed. Skipping."
        SKIPPED_COMPONENTS+=("terminator")
        return 0
    fi
    if DEBIAN_FRONTEND=noninteractive apt-get install -y terminator; then
        log_ok "Terminator installed successfully."
        INSTALLED_COMPONENTS+=("terminator")
    else
        log_err "Failed to install Terminator."
        FAILED_COMPONENTS+=("terminator")
        return 1
    fi
}

# install_google_chrome() — Download and install Google Chrome stable .deb package.
install_google_chrome() {
    log "Installing Google Chrome..."
    if dpkg -s google-chrome-stable &>/dev/null 2>&1; then
        log_ok "Google Chrome already installed. Skipping."
        SKIPPED_COMPONENTS+=("google-chrome")
        return 0
    fi
    if wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O /tmp/chrome.deb && \
       (dpkg -i /tmp/chrome.deb || DEBIAN_FRONTEND=noninteractive apt-get install -f -y) && \
       rm /tmp/chrome.deb; then
        log_ok "Google Chrome installed successfully."
        INSTALLED_COMPONENTS+=("google-chrome")
    else
        log_err "Failed to install Google Chrome."
        FAILED_COMPONENTS+=("google-chrome")
        return 1
    fi
}

# install_desktop_group() — Run all DESKTOP group installers.
install_desktop_group() {
    log "=== Installing DESKTOP group ==="
    install_vscode
    install_nerd_fonts
    install_powerline_fonts
    install_terminator
    install_google_chrome
    log_ok "=== DESKTOP group installation complete ==="
}

# =============================================================================
# DOCKER GROUP - INSTALL FUNCTIONS
# =============================================================================

install_docker() {
    log "Installing Docker Engine..."
    if command -v docker &>/dev/null; then
        log_ok "Docker already installed. Skipping."
        SKIPPED_COMPONENTS+=("docker")
        return 0
    fi
    # Install prerequisites
    DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates gnupg lsb-release
    # Add Docker GPG key and repo
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    if DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        log_ok "Docker installed successfully."
        INSTALLED_COMPONENTS+=("docker")
    else
        log_err "Failed to install Docker."
        FAILED_COMPONENTS+=("docker")
        return 1
    fi
}

install_docker_group() {
    log "=== Installing DOCKER group ==="
    install_docker
    log_ok "=== DOCKER group installation complete ==="
}

# =============================================================================
# GOLANG GROUP - INSTALL FUNCTIONS
# =============================================================================

install_golang() {
    log "Installing Golang..."
    if command -v go &>/dev/null; then
        log_ok "Golang already installed. Skipping."
        SKIPPED_COMPONENTS+=("golang")
        return 0
    fi
    local go_version
    go_version=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
    local go_tarball="${go_version}.linux-amd64.tar.gz"
    wget -q "https://go.dev/dl/${go_tarball}" -O "/tmp/${go_tarball}"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "/tmp/${go_tarball}"
    rm "/tmp/${go_tarball}"
    # Add to system PATH
    cat > /etc/profile.d/golang.sh <<'GOPATH'
export PATH=$PATH:/usr/local/go/bin
GOPATH
    chmod +x /etc/profile.d/golang.sh
    if /usr/local/go/bin/go version &>/dev/null; then
        log_ok "Golang installed successfully."
        INSTALLED_COMPONENTS+=("golang")
    else
        log_err "Failed to install Golang."
        FAILED_COMPONENTS+=("golang")
        return 1
    fi
}

install_golang_group() {
    log "=== Installing GOLANG group ==="
    install_golang
    log_ok "=== GOLANG group installation complete ==="
}

# =============================================================================
# JAVA GROUP - INSTALL FUNCTIONS
# =============================================================================

install_sdkman() {
    log "Installing SDKMAN..."
    sudo apt install -y zip unzip curl
    if [[ -d "${HOME}/.sdkman" ]]; then
        log_ok "SDKMAN already installed. Skipping."
        SKIPPED_COMPONENTS+=("sdkman")
        return 0
    fi
    if curl -s "https://get.sdkman.io" | bash; then
        log_ok "SDKMAN installed successfully."
        INSTALLED_COMPONENTS+=("sdkman")
    else
        log_err "Failed to install SDKMAN."
        FAILED_COMPONENTS+=("sdkman")
        return 1
    fi
}

install_java_latest() {
    log "Installing latest Java via SDKMAN..."

    export SDKMAN_DIR="${HOME}/.sdkman"

    if [[ ! -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
        log_err "SDKMAN init script not found."
        FAILED_COMPONENTS+=("java")
        return 1
    fi

    # 🔥 FIX: disable nounset temporarily
    set +u
    source "${SDKMAN_DIR}/bin/sdkman-init.sh"

    if command -v sdk &>/dev/null; then
        if sdk install java; then
            log_ok "Java (latest) installed successfully."
            INSTALLED_COMPONENTS+=("java")
        else
            log_err "Failed to install Java via SDKMAN."
            FAILED_COMPONENTS+=("java")
            set -u
            return 1
        fi
    else
        log_err "SDKMAN not available. Cannot install Java."
        FAILED_COMPONENTS+=("java")
        set -u
        return 1
    fi

    # 🔥 restore safety
    set -u
}

install_java_group() {
    log "=== Installing JAVA group ==="
    install_sdkman
    install_java_latest
    log_ok "=== JAVA group installation complete ==="
}

# =============================================================================
# DOTNET GROUP - INSTALL FUNCTIONS
# =============================================================================

install_dotnet() {
    log "Installing dotnet core SDK..."
    if command -v dotnet &>/dev/null; then
        log_ok "dotnet already installed. Skipping."
        SKIPPED_COMPONENTS+=("dotnet")
        return 0
    fi
    # Add Microsoft package feed
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
    dpkg -i /tmp/packages-microsoft-prod.deb
    rm /tmp/packages-microsoft-prod.deb
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    if DEBIAN_FRONTEND=noninteractive apt-get install -y dotnet-sdk-8.0; then
        log_ok "dotnet core SDK installed successfully."
        INSTALLED_COMPONENTS+=("dotnet")
    else
        log_err "Failed to install dotnet core SDK."
        FAILED_COMPONENTS+=("dotnet")
        return 1
    fi
}

install_dotnet_group() {
    log "=== Installing DOTNET group ==="
    install_dotnet
    log_ok "=== DOTNET group installation complete ==="
}

# =============================================================================
# SUMMARY REPORT
# =============================================================================

print_summary() {
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - SCRIPT_START_TIME ))
    local minutes=$(( duration / 60 ))
    local seconds=$(( duration % 60 ))
    local end_ts
    end_ts=$(date '+%Y-%m-%d %H:%M:%S')

    local installed_str="none"
    local skipped_str="none"
    local failed_str="none"

    [[ "${#INSTALLED_COMPONENTS[@]}" -gt 0 ]] && installed_str="${INSTALLED_COMPONENTS[*]}"
    [[ "${#SKIPPED_COMPONENTS[@]}" -gt 0 ]]  && skipped_str="${SKIPPED_COMPONENTS[*]}"
    [[ "${#FAILED_COMPONENTS[@]}" -gt 0 ]]   && failed_str="${FAILED_COMPONENTS[*]}"

    log "========================================"
    log "  INSTALLATION SUMMARY"
    log "========================================"
    log "Start time : $(date -d @${SCRIPT_START_TIME} '+%Y-%m-%d %H:%M:%S')"
    log "End time   : ${end_ts}"
    log "Duration   : ${minutes}m ${seconds}s"
    log ""
    log "Installed  (${#INSTALLED_COMPONENTS[@]}): ${installed_str}"
    log "Skipped    (${#SKIPPED_COMPONENTS[@]}): ${skipped_str}"
    log "Failed     (${#FAILED_COMPONENTS[@]}): ${failed_str}"
    log ""
    log "Log file   : ${LOG_FILE}"
    log "========================================"
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

main() {
    # 1. Prerequisite checks (order matters: root first)
    validate_root
    validate_ubuntu
    validate_ram

    # 2. Parse CLI arguments
    parse_args "$@"

    # 3. Initialise logging (after root check, before any installs)
    init_logging
    log "Ubuntu Dev Setup Script starting..."

    # 4. System update
    update_system

    # 5. User management
    create_default_user
    create_extra_users

    # 6. Install selected component groups
    [[ "${INSTALL_BASE}"    -eq 1 ]] && install_base_group
    [[ "${INSTALL_DESKTOP}" -eq 1 ]] && install_desktop_group
    [[ "${INSTALL_DOCKER}"  -eq 1 ]] && install_docker_group
    [[ "${INSTALL_GOLANG}"  -eq 1 ]] && install_golang_group
    [[ "${INSTALL_JAVA}"    -eq 1 ]] && install_java_group
    [[ "${INSTALL_DOTNET}"  -eq 1 ]] && install_dotnet_group

    # 7. Print summary
    print_summary

    # 8. Exit with error if any component failed
    if [[ "${#FAILED_COMPONENTS[@]}" -gt 0 ]]; then
        log_err "Some components failed to install. Check the log for details."
        exit 1
    fi

    log_ok "Setup completed successfully."
}

main "$@"
