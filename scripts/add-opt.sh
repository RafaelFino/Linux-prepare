#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Optional Tools Installation Script
# ============================================================================
# This script installs optional development tools based on user selection.
# Use flags like --nodejs, --rust, --postman to install specific tools.
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
# Helper Functions
# ============================================================================

check_command_available() {
    command -v "$1" &> /dev/null
}

check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        if check_command_available sudo; then
            log_info "Re-running script with sudo privileges..."
            exec sudo -E bash "$0" "$@"
        else
            log_error "This script must be run as root or with sudo privileges"
            exit 1
        fi
    fi
}

# ============================================================================
# Installation Flags
# ============================================================================

INSTALL_NODEJS=false
INSTALL_RUST=false
INSTALL_RUBY=false
INSTALL_TERRAFORM=false
INSTALL_KUBECTL=false
INSTALL_HELM=false
INSTALL_LAZYGIT=false
INSTALL_LAZYDOCKER=false
INSTALL_STARSHIP=false
INSTALL_ZOXIDE=false
INSTALL_RIPGREP_ALL=false
INSTALL_DELTA=false
INSTALL_NEOVIM=false
INSTALL_TMUX_PLUGINS=false
INSTALL_POSTMAN=false
INSTALL_INSOMNIA=false
INSTALL_OBSIDIAN=false
INSTALL_MONGODB_TOOLS=false
INSTALL_POETRY=false
INSTALL_PIPX=false

# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║          Optional Development Tools Installation Script                    ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  sudo ./add-opcionais.sh [OPTIONS]

PROGRAMMING LANGUAGES:
  --nodejs          Install Node.js LTS + npm
  --rust            Install Rust + Cargo
  --ruby            Install Ruby + Gems

INFRASTRUCTURE & CLOUD:
  --terraform       Install Terraform
  --kubectl         Install kubectl (Kubernetes CLI)
  --helm            Install Helm (Kubernetes package manager)

GIT TOOLS:
  --lazygit         Install lazygit (Git TUI)
  --delta           Install delta (better git diff)

CONTAINER TOOLS:
  --lazydocker      Install lazydocker (Docker TUI)

SHELL ENHANCEMENTS:
  --starship        Install Starship prompt
  --zoxide          Install zoxide (smart cd)
  --tmux-plugins    Install TPM (Tmux Plugin Manager)

EDITORS:
  --neovim          Install Neovim

SEARCH TOOLS:
  --ripgrep-all     Install ripgrep-all (rg with PDF, Office support)

DESKTOP APPLICATIONS:
  --postman         Install Postman (API testing)
  --insomnia        Install Insomnia (API testing)
  --obsidian        Install Obsidian (note taking)

DATABASE TOOLS:
  --mongodb-tools   Install MongoDB tools (mongosh, etc)

PYTHON TOOLS:
  --poetry          Install Poetry (Python dependency management)
  --pipx            Install pipx (Python app installer)

SPECIAL FLAGS:
  --all             Install all optional tools
  -h, --help        Show this help message

EXAMPLES:
  # Install Node.js and Rust
  sudo ./add-opcionais.sh --nodejs --rust

  # Install all Git tools
  sudo ./add-opcionais.sh --lazygit --delta

  # Install everything
  sudo ./add-opcionais.sh --all

EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_arguments() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    for arg in "$@"; do
        case $arg in
            -h|--help)
                show_help
                exit 0
                ;;
            --nodejs)
                INSTALL_NODEJS=true
                ;;
            --rust)
                INSTALL_RUST=true
                ;;
            --ruby)
                INSTALL_RUBY=true
                ;;
            --terraform)
                INSTALL_TERRAFORM=true
                ;;
            --kubectl)
                INSTALL_KUBECTL=true
                ;;
            --helm)
                INSTALL_HELM=true
                ;;
            --lazygit)
                INSTALL_LAZYGIT=true
                ;;
            --lazydocker)
                INSTALL_LAZYDOCKER=true
                ;;
            --starship)
                INSTALL_STARSHIP=true
                ;;
            --zoxide)
                INSTALL_ZOXIDE=true
                ;;
            --ripgrep-all)
                INSTALL_RIPGREP_ALL=true
                ;;
            --delta)
                INSTALL_DELTA=true
                ;;
            --neovim)
                INSTALL_NEOVIM=true
                ;;
            --tmux-plugins)
                INSTALL_TMUX_PLUGINS=true
                ;;
            --postman)
                INSTALL_POSTMAN=true
                ;;
            --insomnia)
                INSTALL_INSOMNIA=true
                ;;
            --obsidian)
                INSTALL_OBSIDIAN=true
                ;;
            --mongodb-tools)
                INSTALL_MONGODB_TOOLS=true
                ;;
            --poetry)
                INSTALL_POETRY=true
                ;;
            --pipx)
                INSTALL_PIPX=true
                ;;
            --all)
                INSTALL_NODEJS=true
                INSTALL_RUST=true
                INSTALL_RUBY=true
                INSTALL_TERRAFORM=true
                INSTALL_KUBECTL=true
                INSTALL_HELM=true
                INSTALL_LAZYGIT=true
                INSTALL_LAZYDOCKER=true
                INSTALL_STARSHIP=true
                INSTALL_ZOXIDE=true
                INSTALL_RIPGREP_ALL=true
                INSTALL_DELTA=true
                INSTALL_NEOVIM=true
                INSTALL_TMUX_PLUGINS=true
                INSTALL_POSTMAN=true
                INSTALL_INSOMNIA=true
                INSTALL_OBSIDIAN=true
                INSTALL_MONGODB_TOOLS=true
                INSTALL_POETRY=true
                INSTALL_PIPX=true
                ;;
            *)
                log_error "Unknown argument: $arg"
                log_error "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Installation Functions
# ============================================================================

install_nodejs() {
    if [ "$INSTALL_NODEJS" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Node.js LTS..."
    
    if check_command_available node; then
        log_skip "Node.js already installed: $(node --version)"
        return 0
    fi
    
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt install -y nodejs
    
    log_success "Node.js installed: $(node --version)"
    log_success "npm installed: $(npm --version)"
}

install_rust() {
    if [ "$INSTALL_RUST" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Rust..."
    
    if check_command_available rustc; then
        log_skip "Rust already installed: $(rustc --version)"
        return 0
    fi
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    log_success "Rust installed: $(rustc --version)"
}

install_ruby() {
    if [ "$INSTALL_RUBY" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Ruby..."
    
    if check_command_available ruby; then
        log_skip "Ruby already installed: $(ruby --version)"
        return 0
    fi
    
    apt install -y ruby-full
    
    log_success "Ruby installed: $(ruby --version)"
}

install_terraform() {
    if [ "$INSTALL_TERRAFORM" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Terraform..."
    
    if check_command_available terraform; then
        log_skip "Terraform already installed: $(terraform version | head -1)"
        return 0
    fi
    
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
    apt update && apt install -y terraform
    
    log_success "Terraform installed: $(terraform version | head -1)"
}

install_kubectl() {
    if [ "$INSTALL_KUBECTL" != "true" ]; then
        return 0
    fi
    
    log_info "Installing kubectl..."
    
    if check_command_available kubectl; then
        log_skip "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
        return 0
    fi
    
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    log_success "kubectl installed"
}

install_helm() {
    if [ "$INSTALL_HELM" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Helm..."
    
    if check_command_available helm; then
        log_skip "Helm already installed: $(helm version --short)"
        return 0
    fi
    
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    log_success "Helm installed: $(helm version --short)"
}

install_lazygit() {
    if [ "$INSTALL_LAZYGIT" != "true" ]; then
        return 0
    fi
    
    log_info "Installing lazygit..."
    
    if check_command_available lazygit; then
        log_skip "lazygit already installed"
        return 0
    fi
    
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
    
    log_success "lazygit installed"
}

install_lazydocker() {
    if [ "$INSTALL_LAZYDOCKER" != "true" ]; then
        return 0
    fi
    
    log_info "Installing lazydocker..."
    
    if check_command_available lazydocker; then
        log_skip "lazydocker already installed"
        return 0
    fi
    
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    
    log_success "lazydocker installed"
}

install_starship() {
    if [ "$INSTALL_STARSHIP" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Starship prompt..."
    
    if check_command_available starship; then
        log_skip "Starship already installed"
        return 0
    fi
    
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    log_success "Starship installed"
    log_info "Add to ~/.zshrc: eval \"\$(starship init zsh)\""
}

install_zoxide() {
    if [ "$INSTALL_ZOXIDE" != "true" ]; then
        return 0
    fi
    
    log_info "Installing zoxide..."
    
    if check_command_available zoxide; then
        log_skip "zoxide already installed"
        return 0
    fi
    
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    
    log_success "zoxide installed"
    log_info "Add to ~/.zshrc: eval \"\$(zoxide init zsh)\""
}

install_ripgrep_all() {
    if [ "$INSTALL_RIPGREP_ALL" != "true" ]; then
        return 0
    fi
    
    log_info "Installing ripgrep-all..."
    
    if check_command_available rga; then
        log_skip "ripgrep-all already installed"
        return 0
    fi
    
    local arch=$(dpkg --print-architecture)
    local version="v0.10.6"
    wget "https://github.com/phiresky/ripgrep-all/releases/download/${version}/ripgrep_all-${version}-${arch}-unknown-linux-musl.tar.gz"
    tar xzf ripgrep_all-*.tar.gz
    cd ripgrep_all-*/
    cp rga rga-* /usr/local/bin/
    cd ..
    rm -rf ripgrep_all-*
    
    log_success "ripgrep-all installed"
}

install_delta() {
    if [ "$INSTALL_DELTA" != "true" ]; then
        return 0
    fi
    
    log_info "Installing delta (git diff tool)..."
    
    if check_command_available delta; then
        log_skip "delta already installed"
        return 0
    fi
    
    local version="0.16.5"
    wget "https://github.com/dandavison/delta/releases/download/${version}/git-delta_${version}_amd64.deb"
    dpkg -i git-delta_*.deb || apt install -f -y
    rm git-delta_*.deb
    
    log_success "delta installed"
}

install_neovim() {
    if [ "$INSTALL_NEOVIM" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Neovim..."
    
    if check_command_available nvim; then
        log_skip "Neovim already installed"
        return 0
    fi
    
    apt install -y neovim
    
    log_success "Neovim installed"
}

install_tmux_plugins() {
    if [ "$INSTALL_TMUX_PLUGINS" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Tmux Plugin Manager..."
    
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_skip "TPM already installed"
        return 0
    fi
    
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    
    log_success "TPM installed"
    log_info "Add to ~/.tmux.conf: run '~/.tmux/plugins/tpm/tpm'"
}

install_postman() {
    if [ "$INSTALL_POSTMAN" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Postman..."
    
    if check_command_available postman; then
        log_skip "Postman already installed"
        return 0
    fi
    
    snap install postman
    
    log_success "Postman installed"
}

install_insomnia() {
    if [ "$INSTALL_INSOMNIA" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Insomnia..."
    
    if check_command_available insomnia; then
        log_skip "Insomnia already installed"
        return 0
    fi
    
    snap install insomnia
    
    log_success "Insomnia installed"
}

install_obsidian() {
    if [ "$INSTALL_OBSIDIAN" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Obsidian..."
    
    if check_command_available obsidian; then
        log_skip "Obsidian already installed"
        return 0
    fi
    
    snap install obsidian --classic
    
    log_success "Obsidian installed"
}

install_mongodb_tools() {
    if [ "$INSTALL_MONGODB_TOOLS" != "true" ]; then
        return 0
    fi
    
    log_info "Installing MongoDB tools..."
    
    if check_command_available mongosh; then
        log_skip "MongoDB tools already installed"
        return 0
    fi
    
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    apt update
    apt install -y mongodb-mongosh mongodb-database-tools
    
    log_success "MongoDB tools installed"
}

install_poetry() {
    if [ "$INSTALL_POETRY" != "true" ]; then
        return 0
    fi
    
    log_info "Installing Poetry..."
    
    if check_command_available poetry; then
        log_skip "Poetry already installed"
        return 0
    fi
    
    curl -sSL https://install.python-poetry.org | python3 -
    
    log_success "Poetry installed"
    log_info "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
}

install_pipx() {
    if [ "$INSTALL_PIPX" != "true" ]; then
        return 0
    fi
    
    log_info "Installing pipx..."
    
    if check_command_available pipx; then
        log_skip "pipx already installed"
        return 0
    fi
    
    apt install -y pipx
    pipx ensurepath
    
    log_success "pipx installed"
}

# ============================================================================
# Main Function
# ============================================================================

main() {
    START_TIME=$(date +%s)
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║          Optional Development Tools Installation                           ║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    check_privileges "$@"
    parse_arguments "$@"
    
    log_info "Starting installation of optional tools..."
    echo ""
    
    # Programming Languages
    install_nodejs
    install_rust
    install_ruby
    
    # Infrastructure & Cloud
    install_terraform
    install_kubectl
    install_helm
    
    # Git Tools
    install_lazygit
    install_delta
    
    # Container Tools
    install_lazydocker
    
    # Shell Enhancements
    install_starship
    install_zoxide
    install_tmux_plugins
    
    # Editors
    install_neovim
    
    # Search Tools
    install_ripgrep_all
    
    # Desktop Applications
    install_postman
    install_insomnia
    install_obsidian
    
    # Database Tools
    install_mongodb_tools
    
    # Python Tools
    install_poetry
    install_pipx
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║                 Installation Completed Successfully!                       ║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}Execution Time:${RESET} ${DURATION}s"
    echo ""
}

# ============================================================================
# Script Entry Point
# ============================================================================

main "$@"
