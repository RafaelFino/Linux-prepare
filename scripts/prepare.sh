#!/usr/bin/env bash
# =============================================================================
# Script de Configuração de Ambiente de Desenvolvimento — Ubuntu 25+
# =============================================================================
#
# Uso       : sudo ./prepare.sh [OPÇÕES]
#             Execute --help para informações completas de uso.
#
# Grupos    : --base, --desktop, --docker, --golang, --java, --dotnet, --full
# Usuários  : --users user1 user2 ...
#
# Log       : /var/log/dev-setup-*.log
#
# Notas     : - Executar como root (via sudo)
#             - Senhas solicitadas interativamente (nada hardcoded)
#             - Idempotente: pode ser executado múltiplas vezes
#
# =============================================================================

set -euo pipefail

# =============================================================================
# VARIÁVEIS GLOBAIS
# =============================================================================

INSTALLED_COMPONENTS=()
SKIPPED_COMPONENTS=()
FAILED_COMPONENTS=()

INSTALL_BASE=1
INSTALL_DESKTOP=0
INSTALL_DOCKER=0
INSTALL_GOLANG=0
INSTALL_JAVA=0
INSTALL_DOTNET=0

FLAG_USERS=()
TARGET_USERS=()
CURRENT_USER="${SUDO_USER:-$(whoami)}"

LOG_FILE=""
SCRIPT_START_TIME=$(date +%s)

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [INFO]  $1"
    echo "${line}"
    [[ -n "${LOG_FILE}" ]] && echo "${line}" >> "${LOG_FILE}"
}

log_ok() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [OK]    $1"
    echo "${line}"
    [[ -n "${LOG_FILE}" ]] && echo "${line}" >> "${LOG_FILE}"
}

log_err() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [ERROR] $1"
    echo "${line}" >&2
    [[ -n "${LOG_FILE}" ]] && echo "${line}" >> "${LOG_FILE}"
}

init_logging() {
    LOG_FILE="/var/log/dev-setup-$(date +%Y-%m-%d-%H-%M-%S).log"
    touch "${LOG_FILE}"
    log "Logging inicializado. Arquivo de log: ${LOG_FILE}"
}

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

# Se check_command não for passado, usa package_name como fallback
install_apt_package() {
    local package_name="$1"
    local check_command="${2:-$1}"

    if command -v "$check_command" &>/dev/null || dpkg -s "$package_name" &>/dev/null 2>&1; then
        log "  $package_name já instalado. Pulando."
        SKIPPED_COMPONENTS+=("$package_name")
        return 0
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get install -y "$package_name"; then
        log_ok "  $package_name instalado com sucesso."
        INSTALLED_COMPONENTS+=("$package_name")
    else
        log_err "  Falha ao instalar $package_name."
        FAILED_COMPONENTS+=("$package_name")
    fi
}

# Verifica cada pacote individualmente, instala apenas os faltantes de uma vez
install_apt_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null 2>&1; then
            log "  $pkg já instalado. Pulando."
            SKIPPED_COMPONENTS+=("$pkg")
        else
            to_install+=("$pkg")
        fi
    done

    [[ ${#to_install[@]} -eq 0 ]] && return 0

    if DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"; then
        for pkg in "${to_install[@]}"; do
            log_ok "  $pkg instalado com sucesso."
            INSTALLED_COMPONENTS+=("$pkg")
        done
    else
        for pkg in "${to_install[@]}"; do
            FAILED_COMPONENTS+=("$pkg")
        done
        log_err "  Falha ao instalar: ${to_install[*]}"
    fi
}

# Se check_command não for passado, usa component_name como fallback
install_deb_from_url() {
    local component_name="$1"
    local deb_url="$2"
    local check_command="${3:-$1}"

    if command -v "$check_command" &>/dev/null || dpkg -s "$component_name" &>/dev/null 2>&1; then
        log "  $component_name já instalado. Pulando."
        SKIPPED_COMPONENTS+=("$component_name")
        return 0
    fi

    local temp_deb="/tmp/${component_name}.deb"

    if wget -q "$deb_url" -O "$temp_deb" && \
       dpkg -i "$temp_deb" || DEBIAN_FRONTEND=noninteractive apt-get install -f -y; then
        log_ok "  $component_name instalado com sucesso via .deb."
        INSTALLED_COMPONENTS+=("$component_name")
    else
        log_err "  Falha ao instalar $component_name via .deb."
        FAILED_COMPONENTS+=("$component_name")
    fi

    rm -f "$temp_deb"
}

# Se apt-get update falhar após adicionar a chave, reverte automaticamente
# removendo o .gpg e o .list adicionados
add_apt_key_with_validation() {
    local repo_name="$1"
    local key_url="$2"
    local key_path="$3"
    local list_content="$4"
    local list_path="$5"

    if [[ -f "$key_path" ]] && [[ -f "$list_path" ]]; then
        log "  Repositório $repo_name já configurado. Pulando."
        return 0
    fi

    log "  Adicionando repositório $repo_name..."

    mkdir -p "$(dirname "$key_path")"
    if ! curl -fsSL "$key_url" | gpg --dearmor -o "$key_path"; then
        log_err "  Falha ao baixar chave GPG para $repo_name."
        return 1
    fi

    echo "$list_content" > "$list_path"

    if ! DEBIAN_FRONTEND=noninteractive apt-get update -y; then
        log_err "  apt-get update falhou após adicionar $repo_name. Revertendo..."
        rm -f "$key_path" "$list_path"
        DEBIAN_FRONTEND=noninteractive apt-get update -y || true
        log_err "  Repositório $repo_name revertido: chave e lista removidos."
        return 1
    fi

    log_ok "  Repositório $repo_name adicionado e validado com sucesso."
}

# =============================================================================
# VALIDAÇÕES DE PRÉ-REQUISITO
# =============================================================================

check_running_as_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "ERRO: Este script deve ser executado como root (use sudo)." >&2
        exit 1
    fi
}

check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        echo "ERRO: /etc/os-release não encontrado. Sistema não suportado." >&2
        exit 1
    fi

    local os_id os_version
    os_id=$(. /etc/os-release && echo "${ID:-}")
    os_version=$(. /etc/os-release && echo "${VERSION_ID:-}")

    if [[ "$os_id" != "ubuntu" ]]; then
        echo "ERRO: Sistema não suportado: '$os_id'. Apenas Ubuntu." >&2
        exit 1
    fi

    local major_version
    major_version=$(echo "$os_version" | cut -d'.' -f1)

    if [[ -z "$major_version" ]] || [[ "$major_version" -lt 25 ]]; then
        echo "ERRO: Ubuntu $os_version detectado. Mínimo: 25." >&2
        exit 1
    fi
}

check_minimum_ram() {
    local min_ram_kb=2097152  # 2 GB

    local total_ram_kb
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')

    if [[ -z "$total_ram_kb" ]]; then
        echo "ERRO: Não foi possível determinar a RAM do sistema." >&2
        exit 1
    fi

    if [[ "$total_ram_kb" -lt "$min_ram_kb" ]]; then
        local total_ram_gb
        total_ram_gb=$(awk "BEGIN {printf \"%.1f\", $total_ram_kb / 1048576}")
        echo "ERRO: RAM insuficiente: ${total_ram_gb} GB. Mínimo: 2 GB." >&2
        exit 1
    fi
}

# =============================================================================
# PARSE DE ARGUMENTOS CLI
# =============================================================================

show_help() {
    cat <<'EOF'
Uso: sudo ./prepare.sh [OPÇÕES]

Automatiza a instalação e configuração de um ambiente completo de
desenvolvimento em Ubuntu 25 ou superior.

GRUPOS DE COMPONENTES:
  --base       Ferramentas de terminal (tmux, htop, jq, bat, ripgrep, fzf...),
               ferramentas de build (build-essential, git, protobuf-compiler),
               Python (python3-venv, pipx), shells (zsh, oh-my-bash, oh-my-zsh),
               editores de terminal (vim, micro) e utilitários (yq, eza, httpie)
  --desktop    Fontes (Nerd Fonts, FiraCode, Cascadia Code, JetBrains Mono),
               VS Code, Ghostty, Terminator, Google Chrome
  --docker     Docker Engine e K3S (Kubernetes leve para desenvolvimento)
  --golang     Go (via tarball oficial) e golangci-lint
  --java       SDKMAN, JDK, Kotlin e Gradle
  --dotnet     .NET SDK
  --full       Habilita todos os grupos acima

USUÁRIOS:
  --users user1 user2 ...
               Cria os usuários especificados e os adiciona ao grupo sudo.
               A senha de cada usuário é solicitada interativamente durante
               a execução. Configurações de shell, aliases e ferramentas
               são aplicadas a todos os usuários criados, ao usuário corrente
               e ao root.

OUTRAS OPÇÕES:
  --help       Exibe esta mensagem de ajuda

COMPORTAMENTO PADRÃO:
  - Se nenhuma flag de grupo for passada, apenas --base é instalado
  - Se qualquer flag de grupo for passada explicitamente, apenas os grupos
    especificados são instalados
  - Se --users não for passado, configurações são aplicadas apenas ao
    usuário corrente (quem executou sudo) e ao root

EXEMPLOS:
  sudo ./prepare.sh                          # Instala apenas o grupo BASE
  sudo ./prepare.sh --full                   # Instala todos os grupos
  sudo ./prepare.sh --base --docker          # Instala BASE e DOCKER
  sudo ./prepare.sh --full --users ana bob   # Instala tudo, cria usuários
                                             # ana e bob com senha interativa
  sudo ./prepare.sh --help                   # Exibe esta ajuda

LOG:
  Todas as operações são registradas em /var/log/dev-setup-YYYY-MM-DD-HH-MM-SS.log
EOF
}

# Se qualquer flag de grupo for passada, desabilita o padrão (apenas --base).
# --users consome argumentos seguintes até encontrar outra flag (--*).
parse_arguments() {
    [[ $# -eq 0 ]] && return 0

    local has_group_flag=false
    for arg in "$@"; do
        case "$arg" in
            --base|--desktop|--docker|--golang|--java|--dotnet|--full)
                has_group_flag=true
                break
                ;;
        esac
    done

    if [[ "$has_group_flag" == true ]]; then
        INSTALL_BASE=0
        INSTALL_DESKTOP=0
        INSTALL_DOCKER=0
        INSTALL_GOLANG=0
        INSTALL_JAVA=0
        INSTALL_DOTNET=0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --base)    INSTALL_BASE=1;    shift ;;
            --desktop) INSTALL_DESKTOP=1; shift ;;
            --docker)  INSTALL_DOCKER=1;  shift ;;
            --golang)  INSTALL_GOLANG=1;  shift ;;
            --java)    INSTALL_JAVA=1;    shift ;;
            --dotnet)  INSTALL_DOTNET=1;  shift ;;
            --full)
                INSTALL_BASE=1; INSTALL_DESKTOP=1; INSTALL_DOCKER=1
                INSTALL_GOLANG=1; INSTALL_JAVA=1; INSTALL_DOTNET=1
                shift
                ;;
            --users)
                shift
                while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                    FLAG_USERS+=("$1")
                    shift
                done
                ;;
            --help) show_help; exit 0 ;;
            *)
                echo "ERRO: Flag desconhecida: '$1'" >&2
                echo "Execute './prepare.sh --help' para ver as opções." >&2
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# ATUALIZAÇÃO DO SISTEMA
# =============================================================================

update_system() {
    log "Atualizando índices de pacotes..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y \
        && log_ok "Índices atualizados." \
        || log_err "Falha ao atualizar índices."

    log "Aplicando atualizações do sistema..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && log_ok "Sistema atualizado." \
        || log_err "Falha ao atualizar o sistema."
}

# =============================================================================
# GERENCIAMENTO DE USUÁRIOS
# =============================================================================

# Constrói TARGET_USERS = current_user + root + flag_users, sem duplicatas
build_target_users() {
    TARGET_USERS=("$CURRENT_USER")

    [[ "$CURRENT_USER" != "root" ]] && TARGET_USERS+=("root")

    for user in "${FLAG_USERS[@]}"; do
        local already_present=false
        for existing in "${TARGET_USERS[@]}"; do
            [[ "$existing" == "$user" ]] && already_present=true && break
        done
        [[ "$already_present" == false ]] && TARGET_USERS+=("$user")
    done

    log "TARGET_USERS: ${TARGET_USERS[*]}"
}

ensure_user_in_sudo_group() {
    local username="$1"

    if groups "$username" 2>/dev/null | grep -q '\bsudo\b'; then
        log "  '$username' já pertence ao grupo sudo."
        return 0
    fi

    usermod -aG sudo "$username" \
        && log_ok "  '$username' adicionado ao grupo sudo." \
        || log_err "  Falha ao adicionar '$username' ao grupo sudo."
}

# Solicita senha interativamente para cada usuário de FLAG_USERS
create_users_from_flag() {
    [[ ${#FLAG_USERS[@]} -eq 0 ]] && return 0

    log "Criando usuários via --users..."

    for username in "${FLAG_USERS[@]}"; do
        if id "$username" &>/dev/null; then
            log "  '$username' já existe. Pulando criação."
        else
            local password=""
            read -s -p "Digite a senha para '$username': " password
            echo

            if useradd -m -s /bin/bash "$username"; then
                echo "$username:$password" | chpasswd
                log_ok "  '$username' criado."
            else
                log_err "  Falha ao criar '$username'."
                continue
            fi
        fi

        ensure_user_in_sudo_group "$username"
    done
}

# =============================================================================
# GRUPO BASE
# =============================================================================

install_base_terminal_tools() {
    log "Instalando ferramentas de terminal..."
    install_apt_packages tmux htop jq tree bat ripgrep fd-find fzf \
                         httpie net-tools dnsutils sqlite3
}

# yq não está disponível via apt — binário oficial do GitHub
install_yq() {
    log "Instalando yq..."

    if command -v yq &>/dev/null; then
        log "  yq já instalado. Pulando."
        SKIPPED_COMPONENTS+=("yq")
        return 0
    fi

    local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"

    if wget -q "$yq_url" -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq; then
        log_ok "  yq instalado."
        INSTALLED_COMPONENTS+=("yq")
    else
        log_err "  Falha ao instalar yq."
        FAILED_COMPONENTS+=("yq")
    fi
}

install_base_build_tools() {
    log "Instalando ferramentas de build..."
    install_apt_packages build-essential git protobuf-compiler
}

install_base_python_tools() {
    log "Instalando ferramentas Python..."
    install_apt_packages python3-venv pipx
}

# micro não está no apt — instalador oficial via getmic.ro
install_micro() {
    log "Instalando micro..."

    if command -v micro &>/dev/null; then
        log "  micro já instalado. Pulando."
        SKIPPED_COMPONENTS+=("micro")
        return 0
    fi

    cd

    if curl -fsSL https://getmic.ro | bash; then
        mv micro /usr/local/bin/micro
        chmod +x /usr/local/bin/micro
        log_ok "  micro instalado."
        INSTALLED_COMPONENTS+=("micro")
    else
        log_err "  Falha ao instalar micro."
        FAILED_COMPONENTS+=("micro")
    fi
}

install_oh_my_bash() {
    log "Instalando Oh My Bash..."

    if [[ -d "${HOME}/.oh-my-bash" ]]; then
        log "  Oh My Bash já instalado. Pulando."
        SKIPPED_COMPONENTS+=("oh-my-bash")
        return 0
    fi

    if bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended; then
        log_ok "  Oh My Bash instalado."
        INSTALLED_COMPONENTS+=("oh-my-bash")
    else
        log_err "  Falha ao instalar Oh My Bash."
        FAILED_COMPONENTS+=("oh-my-bash")
    fi
}

# RUNZSH=no evita iniciar zsh após instalação; CHSH=no evita trocar shell
install_oh_my_zsh() {
    log "Instalando Oh My Zsh..."

    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        log "  Oh My Zsh já instalado. Pulando."
        SKIPPED_COMPONENTS+=("oh-my-zsh")
        return 0
    fi

    if RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
        log_ok "  Oh My Zsh instalado."
        INSTALLED_COMPONENTS+=("oh-my-zsh")
    else
        log_err "  Falha ao instalar Oh My Zsh."
        FAILED_COMPONENTS+=("oh-my-zsh")
    fi
}

# Awesome vimrc: https://github.com/amix/vimrc
install_awesome_vim() {
    log "Instalando awesome vimrc (amix/vimrc)..."

    local vimrc_dir="${HOME}/.vim_runtime"

    if [[ -d "$vimrc_dir" ]]; then
        log "  awesome-vim já instalado. Pulando."
        SKIPPED_COMPONENTS+=("awesome-vim")
        return 0
    fi

    if git clone --depth=1 https://github.com/amix/vimrc.git "$vimrc_dir"; then
        if bash "$vimrc_dir/install_awesome_vimrc.sh"; then
            log_ok "  awesome-vim instalado."
            INSTALLED_COMPONENTS+=("awesome-vim")
        else
            log_err "  Falha ao executar install_awesome_vimrc.sh."
            FAILED_COMPONENTS+=("awesome-vim")
        fi
    else
        log_err "  Falha ao clonar amix/vimrc."
        FAILED_COMPONENTS+=("awesome-vim")
    fi
}

install_group_base() {
    log "=============================================="
    log "Instalando Grupo BASE..."
    log "=============================================="

    install_apt_package curl
    install_apt_package wget
    install_apt_package unzip
    install_apt_package zip

    install_base_build_tools

    install_apt_package zsh
    install_apt_package vim
    install_apt_package eza

    install_micro
    install_base_terminal_tools
    install_yq
    install_base_python_tools
    install_oh_my_bash
    install_oh_my_zsh
    install_awesome_vim

    log "=============================================="
    log "Grupo BASE concluído."
    log "=============================================="
}

# =============================================================================
# GRUPO DESKTOP
# =============================================================================

# Clone com --depth=1 para evitar baixar o histórico completo (~2 GB)
install_nerd_fonts() {
    log "Instalando Nerd Fonts..."

    if fc-list | grep -qi "Nerd"; then
        log "  Nerd Fonts já instaladas. Pulando."
        SKIPPED_COMPONENTS+=("nerd-fonts")
        return 0
    fi

    local temp_dir="~/nerd-fonts-clone"
    rm -rf "$temp_dir"

    if ! git clone --depth=1 https://github.com/ryanoasis/nerd-fonts "$temp_dir"; then
        log_err "  Falha ao clonar nerd-fonts."
        FAILED_COMPONENTS+=("nerd-fonts")
        return 1
    fi

    if "$temp_dir/install.sh"; then
        log_ok "  Nerd Fonts instaladas."
        INSTALLED_COMPONENTS+=("nerd-fonts")
    else
        log_err "  Falha ao executar install.sh das Nerd Fonts."
        FAILED_COMPONENTS+=("nerd-fonts")
    fi

    rm -rf "$temp_dir"
}

install_desktop_fonts() {
    log "Instalando fontes de programação..."
    install_apt_packages fonts-firacode fonts-cascadia-code fonts-jetbrains-mono
}

install_powerline_fonts() {
    log "Instalando Powerline Fonts..."

    if fc-list | grep -qi "Powerline"; then
        log "  Powerline Fonts já instaladas. Pulando."
        SKIPPED_COMPONENTS+=("powerline-fonts")
        return 0
    fi

    local temp_dir="~/powerline-fonts-clone"
    rm -rf "$temp_dir"

    if ! git clone --depth=1 https://github.com/powerline/fonts.git "$temp_dir"; then
        log_err "  Falha ao clonar powerline-fonts."
        FAILED_COMPONENTS+=("powerline-fonts")
        return 1
    fi

    if "$temp_dir/install.sh"; then
        log_ok "  Powerline Fonts instaladas."
        INSTALLED_COMPONENTS+=("powerline-fonts")
    else
        log_err "  Falha ao executar install.sh das Powerline Fonts."
        FAILED_COMPONENTS+=("powerline-fonts")
    fi

    rm -rf "$temp_dir"
}

# .deb do GitHub — evita adicionar PPA/chave APT
install_ghostty() {
    log "Instalando Ghostty..."
    install_deb_from_url "ghostty" \
        "https://github.com/mkasberg/ghostty-ubuntu/releases/latest/download/ghostty_latest_amd64_ubuntu24.04.deb" \
        "ghostty"
}

# .deb oficial — evita adicionar repositório APT do Google
install_chrome() {
    log "Instalando Google Chrome..."
    install_deb_from_url "google-chrome-stable" \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
        "google-chrome-stable"
}

# VS Code requer chave APT — usa add_apt_key_with_validation para rollback automático
install_vscode() {
    log "Instalando Visual Studio Code..."

    if command -v code &>/dev/null; then
        log "  VS Code já instalado. Pulando."
        SKIPPED_COMPONENTS+=("code")
        return 0
    fi

    if ! add_apt_key_with_validation \
        "vscode" \
        "https://packages.microsoft.com/keys/microsoft.asc" \
        "/etc/apt/keyrings/microsoft.gpg" \
        "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        "/etc/apt/sources.list.d/vscode.list"; then
        log_err "  Falha ao configurar repositório do VS Code."
        FAILED_COMPONENTS+=("code")
        return 1
    fi

    install_apt_package code
}

install_terminator() {
    log "Instalando Terminator..."
    install_apt_package terminator
}

install_group_desktop() {
    log "=============================================="
    log "Instalando Grupo DESKTOP..."
    log "=============================================="

    install_vscode
    install_nerd_fonts
    install_desktop_fonts
    install_powerline_fonts
    install_ghostty
    install_terminator
    install_chrome

    log "=============================================="
    log "Grupo DESKTOP concluído."
    log "=============================================="
}

# =============================================================================
# GRUPO DOCKER
# =============================================================================

# Docker requer chave APT — usa add_apt_key_with_validation para rollback automático
install_docker() {
    log "Instalando Docker Engine..."

    if command -v docker &>/dev/null; then
        log "  Docker já instalado. Pulando."
        SKIPPED_COMPONENTS+=("docker")
        return 0
    fi

    local arch codename
    arch=$(dpkg --print-architecture)
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

    if ! add_apt_key_with_validation \
        "docker" \
        "https://download.docker.com/linux/ubuntu/gpg" \
        "/etc/apt/keyrings/docker.gpg" \
        "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
        "/etc/apt/sources.list.d/docker.list"; then
        log_err "  Falha ao configurar repositório do Docker."
        FAILED_COMPONENTS+=("docker")
        return 1
    fi

    install_apt_packages docker-ce docker-ce-cli containerd.io \
                         docker-buildx-plugin docker-compose-plugin
}

# K3S inclui kubectl integrado (acessível via 'k3s kubectl')
install_k3s() {
    log "Instalando K3S..."

    if command -v k3s &>/dev/null; then
        log "  K3S já instalado. Pulando."
        SKIPPED_COMPONENTS+=("k3s")
        return 0
    fi

    if curl -sfL https://get.k3s.io | sh -; then
        log_ok "  K3S instalado (kubectl via 'k3s kubectl')."
        INSTALLED_COMPONENTS+=("k3s")
    else
        log_err "  Falha ao instalar K3S."
        FAILED_COMPONENTS+=("k3s")
    fi
}

install_group_docker() {
    log "=============================================="
    log "Instalando Grupo DOCKER..."
    log "=============================================="

    install_docker
    install_k3s

    log "=============================================="
    log "Grupo DOCKER concluído."
    log "=============================================="
}

# =============================================================================
# GRUPO GOLANG
# =============================================================================

install_golang() {
    log "Instalando Go..."

    if command -v go &>/dev/null; then
        log "  Go já instalado ($(go version)). Pulando."
        SKIPPED_COMPONENTS+=("golang")
        return 0
    fi

    local go_version
    go_version=$(curl -sSfL "https://go.dev/VERSION?m=text" | head -1)

    if [[ -z "$go_version" ]]; then
        log_err "  Falha ao obter versão do Go."
        FAILED_COMPONENTS+=("golang")
        return 1
    fi

    local temp_tarball="/tmp/go.tar.gz"

    log "  Baixando ${go_version}..."
    if ! curl -sSfL "https://go.dev/dl/${go_version}.linux-amd64.tar.gz" -o "$temp_tarball"; then
        log_err "  Falha ao baixar Go."
        FAILED_COMPONENTS+=("golang")
        rm -f "$temp_tarball"
        return 1
    fi

    rm -rf /usr/local/go
    if tar -C /usr/local -xzf "$temp_tarball"; then
        log_ok "  Go ${go_version} instalado."
        INSTALLED_COMPONENTS+=("golang")
    else
        log_err "  Falha ao extrair Go."
        FAILED_COMPONENTS+=("golang")
        rm -f "$temp_tarball"
        return 1
    fi

    rm -f "$temp_tarball"

    if [[ ! -f /etc/profile.d/golang.sh ]]; then
        cat > /etc/profile.d/golang.sh <<'EOF'
export PATH="/usr/local/go/bin:$PATH"
EOF
        chmod +x /etc/profile.d/golang.sh
    fi

    export PATH="/usr/local/go/bin:$PATH"
}

install_golangci_lint() {
    log "Instalando golangci-lint..."

    if command -v golangci-lint &>/dev/null; then
        log "  golangci-lint já instalado. Pulando."
        SKIPPED_COMPONENTS+=("golangci-lint")
        return 0
    fi

    if curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
       sh -s -- -b /usr/local/bin; then
        log_ok "  golangci-lint instalado."
        INSTALLED_COMPONENTS+=("golangci-lint")
    else
        log_err "  Falha ao instalar golangci-lint."
        FAILED_COMPONENTS+=("golangci-lint")
    fi
}

install_group_golang() {
    log "=============================================="
    log "Instalando Grupo GOLANG..."
    log "=============================================="

    install_golang
    install_golangci_lint

    log "=============================================="
    log "Grupo GOLANG concluído."
    log "=============================================="
}

# =============================================================================
# GRUPO JAVA
# =============================================================================

install_sdkman() {
    log "Instalando SDKMAN..."

    export SDKMAN_DIR="/usr/local/sdkman"

    if [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
        log "  SDKMAN já instalado. Pulando."
        SKIPPED_COMPONENTS+=("sdkman")
        return 0
    fi

    if curl -sSfL "https://get.sdkman.io" | bash; then
        log_ok "  SDKMAN instalado."
        INSTALLED_COMPONENTS+=("sdkman")
    else
        log_err "  Falha ao instalar SDKMAN."
        FAILED_COMPONENTS+=("sdkman")
        return 1
    fi

    if [[ ! -f /etc/profile.d/sdkman.sh ]]; then
        cat > /etc/profile.d/sdkman.sh <<'EOF'
export SDKMAN_DIR="/usr/local/sdkman"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
EOF
        chmod +x /etc/profile.d/sdkman.sh
    fi
}

install_jdk() {
    log "Instalando JDK via SDKMAN..."

    export SDKMAN_DIR="/usr/local/sdkman"

    if [[ ! -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
        log_err "  SDKMAN não encontrado. JDK não será instalado."
        FAILED_COMPONENTS+=("jdk")
        return 1
    fi

    # SDKMAN usa variáveis não definidas internamente — requer set +u
    set +u
    source "${SDKMAN_DIR}/bin/sdkman-init.sh"

    if command -v java &>/dev/null; then
        log "  JDK já instalado. Pulando."
        SKIPPED_COMPONENTS+=("jdk")
        set -u
        return 0
    fi

    if sdk install java; then
        log_ok "  JDK instalado via SDKMAN."
        INSTALLED_COMPONENTS+=("jdk")
    else
        log_err "  Falha ao instalar JDK."
        FAILED_COMPONENTS+=("jdk")
    fi

    set -u
}

install_kotlin_and_gradle() {
    log "Instalando Kotlin e Gradle via SDKMAN..."

    export SDKMAN_DIR="/usr/local/sdkman"

    if [[ ! -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
        log_err "  SDKMAN não encontrado. Kotlin e Gradle não serão instalados."
        FAILED_COMPONENTS+=("kotlin" "gradle")
        return 1
    fi

    # SDKMAN usa variáveis não definidas internamente — requer set +u
    set +u
    source "${SDKMAN_DIR}/bin/sdkman-init.sh"

    if command -v kotlin &>/dev/null; then
        log "  Kotlin já instalado. Pulando."
        SKIPPED_COMPONENTS+=("kotlin")
    elif sdk install kotlin; then
        log_ok "  Kotlin instalado."
        INSTALLED_COMPONENTS+=("kotlin")
    else
        log_err "  Falha ao instalar Kotlin."
        FAILED_COMPONENTS+=("kotlin")
    fi

    if command -v gradle &>/dev/null; then
        log "  Gradle já instalado. Pulando."
        SKIPPED_COMPONENTS+=("gradle")
    elif sdk install gradle; then
        log_ok "  Gradle instalado."
        INSTALLED_COMPONENTS+=("gradle")
    else
        log_err "  Falha ao instalar Gradle."
        FAILED_COMPONENTS+=("gradle")
    fi

    set -u
}

install_group_java() {
    log "=============================================="
    log "Instalando Grupo JAVA..."
    log "=============================================="

    install_sdkman
    install_jdk
    install_kotlin_and_gradle

    log "=============================================="
    log "Grupo JAVA concluído."
    log "=============================================="
}

# =============================================================================
# GRUPO DOTNET
# =============================================================================

# Usa o .deb packages-microsoft-prod para configurar o repositório Microsoft
install_dotnet() {
    log "Instalando .NET SDK..."

    if command -v dotnet &>/dev/null; then
        log "  .NET SDK já instalado. Pulando."
        SKIPPED_COMPONENTS+=("dotnet-sdk")
        return 0
    fi

    local ms_deb_url="https://packages.microsoft.com/config/ubuntu/$(. /etc/os-release && echo "$VERSION_ID")/packages-microsoft-prod.deb"
    local temp_deb="/tmp/packages-microsoft-prod.deb"

    if ! wget -q "$ms_deb_url" -O "$temp_deb"; then
        log_err "  Falha ao baixar pacote Microsoft."
        FAILED_COMPONENTS+=("dotnet-sdk")
        rm -f "$temp_deb"
        return 1
    fi

    dpkg -i "$temp_deb" || true
    rm -f "$temp_deb"
    DEBIAN_FRONTEND=noninteractive apt-get update -y || true

    install_apt_package dotnet-sdk-8.0 dotnet
}

install_group_dotnet() {
    log "=============================================="
    log "Instalando Grupo DOTNET..."
    log "=============================================="

    install_dotnet

    log "=============================================="
    log "Grupo DOTNET concluído."
    log "=============================================="
}

# =============================================================================
# CONFIGURAÇÕES PER-USER
# =============================================================================

configure_shell_for_user() {
    local username="$1"
    local homedir="$2"

    log "  Configurando shell para '$username'..."

    local current_shell
    current_shell=$(getent passwd "$username" | cut -d: -f7)

    if [[ "$current_shell" != */zsh ]]; then
        chsh -s "$(command -v zsh)" "$username" 2>/dev/null \
            && log_ok "    Shell alterado para zsh." \
            || log_err "    Falha ao alterar shell para zsh."
    fi

    local omz_dir="${homedir}/.oh-my-zsh"

    if [[ ! -d "$omz_dir" ]]; then
        if sudo -u "$username" env HOME="$homedir" \
            RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null; then
            log_ok "    Oh My Zsh instalado para '$username'."
        else
            log_err "    Falha ao instalar Oh My Zsh para '$username'."
        fi
    fi

    local zshrc="${homedir}/.zshrc"

    if [[ -f "$zshrc" ]]; then
        if ! grep -q '^ZSH_THEME="frisk"' "$zshrc" 2>/dev/null; then
            if grep -q '^ZSH_THEME=' "$zshrc" 2>/dev/null; then
                sed -i 's/^ZSH_THEME=.*/ZSH_THEME="frisk"/' "$zshrc"
            else
                echo 'ZSH_THEME="frisk"' >> "$zshrc"
            fi
            chown "$username":"$(id -gn "$username" 2>/dev/null || echo "$username")" "$zshrc" 2>/dev/null || true
            log_ok "    Tema frisk configurado."
        fi
    fi
}

configure_git_editor() {
    local username="$1"
    local homedir="$2"

    local current_editor
    current_editor=$(sudo -u "$username" env HOME="$homedir" git config --global core.editor 2>/dev/null || echo "")

    if [[ "$current_editor" == "micro" ]]; then
        return 0
    fi

    sudo -u "$username" env HOME="$homedir" git config --global core.editor micro 2>/dev/null \
        && log_ok "  Git editor → micro para '$username'." \
        || log_err "  Falha ao configurar git editor para '$username'."
}

# Usa marcador para evitar duplicação em execuções repetidas
configure_aliases_for_user() {
    local username="$1"
    local homedir="$2"

    local -a eza_aliases=(
        'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"'
        'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"'
    )

    local marker="# Aliases eza — adicionado por prepare.sh"

    local rc_file
    for rc_file in "${homedir}/.bashrc" "${homedir}/.zshrc"; do
        [[ ! -f "$rc_file" ]] && touch "$rc_file" && \
            chown "$username":"$(id -gn "$username" 2>/dev/null || echo "$username")" "$rc_file" 2>/dev/null || true

        if grep -qF "$marker" "$rc_file" 2>/dev/null; then
            continue
        fi

        {
            echo ""
            echo "$marker"
            for alias_line in "${eza_aliases[@]}"; do
                echo "$alias_line"
            done
        } >> "$rc_file"

        chown "$username":"$(id -gn "$username" 2>/dev/null || echo "$username")" "$rc_file" 2>/dev/null || true
        log_ok "    Aliases eza adicionados em $(basename "$rc_file") para '$username'."
    done
}

# Aplica configurações apenas aos TARGET_USERS (não itera /etc/passwd)
apply_user_configurations() {
    log "=============================================="
    log "Aplicando configurações per-user..."
    log "=============================================="

    for username in "${TARGET_USERS[@]}"; do
        local homedir
        homedir=$(eval echo "~${username}")

        if [[ ! -d "$homedir" ]]; then
            log_err "  Home '$homedir' não encontrado para '$username'. Pulando."
            continue
        fi

        log "--- $username ---"
        configure_shell_for_user "$username" "$homedir"
        configure_git_editor "$username" "$homedir"
        configure_aliases_for_user "$username" "$homedir"
    done

    log "=============================================="
    log "Configurações per-user concluídas."
    log "=============================================="
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

print_final_report() {
    local end_time
    end_time=$(date +%s)
    local elapsed=$(( end_time - SCRIPT_START_TIME ))
    local minutes=$(( elapsed / 60 ))
    local seconds=$(( elapsed % 60 ))

    declare -A component_status
    for c in "${INSTALLED_COMPONENTS[@]}"; do component_status["$c"]="✓ Instalado"; done
    for c in "${SKIPPED_COMPONENTS[@]}"; do component_status["$c"]="⊘ Pulado"; done
    for c in "${FAILED_COMPONENTS[@]}"; do component_status["$c"]="✗ Falha"; done

    local max_name_len=10
    for name in "${!component_status[@]}"; do
        [[ ${#name} -gt $max_name_len ]] && max_name_len=${#name}
    done
    max_name_len=$(( max_name_len + 2 ))

    local status_col_width=14

    local h_line_top h_line_mid h_line_bot
    h_line_top=$(printf "╔"; printf '═%.0s' $(seq 1 $((max_name_len + 2))); printf "╦"; printf '═%.0s' $(seq 1 $((status_col_width + 2))); printf "╗")
    h_line_mid=$(printf "╠"; printf '═%.0s' $(seq 1 $((max_name_len + 2))); printf "╬"; printf '═%.0s' $(seq 1 $((status_col_width + 2))); printf "╣")
    h_line_bot=$(printf "╚"; printf '═%.0s' $(seq 1 $((max_name_len + 2))); printf "╩"; printf '═%.0s' $(seq 1 $((status_col_width + 2))); printf "╝")

    local output=""
    output+="\n"
    output+="$h_line_top\n"
    output+="$(printf "║ %-${max_name_len}s ║ %-${status_col_width}s ║" "Componente" "Status")\n"
    output+="$h_line_mid\n"

    local sorted_names
    sorted_names=$(for name in "${!component_status[@]}"; do echo "$name"; done | sort)

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local status="${component_status[$name]}"
        output+="$(printf "║ %-${max_name_len}s ║ %-${status_col_width}s ║" "$name" "$status")\n"
    done <<< "$sorted_names"

    output+="$h_line_bot\n"
    output+="\n"
    output+="Instalados: ${#INSTALLED_COMPONENTS[@]}  |  Pulados: ${#SKIPPED_COMPONENTS[@]}  |  Falhas: ${#FAILED_COMPONENTS[@]}\n"
    output+="Tempo total: ${minutes}m ${seconds}s\n"
    output+="Log: ${LOG_FILE}\n"

    echo -e "$output"
    [[ -n "${LOG_FILE}" ]] && echo -e "$output" >> "${LOG_FILE}"

    if [[ ${#FAILED_COMPONENTS[@]} -gt 0 ]]; then
        log_err "Execução concluída com ${#FAILED_COMPONENTS[@]} falha(s)."
        return 1
    else
        log_ok "Execução concluída com sucesso!"
        return 0
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    check_running_as_root
    check_ubuntu_version
    check_minimum_ram

    parse_arguments "$@"
    init_logging

    log "=============================================="
    log "Início da configuração do ambiente"
    log "=============================================="
    log "Usuário corrente: ${CURRENT_USER}"
    log "Grupos: BASE=${INSTALL_BASE} DESKTOP=${INSTALL_DESKTOP} DOCKER=${INSTALL_DOCKER} GOLANG=${INSTALL_GOLANG} JAVA=${INSTALL_JAVA} DOTNET=${INSTALL_DOTNET}"
    [[ ${#FLAG_USERS[@]} -gt 0 ]] && log "Usuários a criar: ${FLAG_USERS[*]}"

    create_users_from_flag
    build_target_users

    DEBIAN_FRONTEND=noninteractive apt-get update -y || log_err "Falha no apt-get update."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || log_err "Falha no apt-get upgrade."

    [[ "${INSTALL_BASE}"    -eq 1 ]] && install_group_base
    [[ "${INSTALL_DESKTOP}" -eq 1 ]] && install_group_desktop
    [[ "${INSTALL_DOCKER}"  -eq 1 ]] && install_group_docker
    [[ "${INSTALL_GOLANG}"  -eq 1 ]] && install_group_golang
    [[ "${INSTALL_JAVA}"    -eq 1 ]] && install_group_java
    [[ "${INSTALL_DOTNET}"  -eq 1 ]] && install_group_dotnet

    apply_user_configurations
    print_final_report
}

main "$@"

