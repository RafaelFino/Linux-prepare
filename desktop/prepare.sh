#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

show_help() {
    echo "Uso: $0 [opções]"
    echo "Opções:"

    echo " |------------|-------------------------------------------------------------------------------------------------|"
    echo " | Argumento  | Descrição                                                                                       |"
    echo " |------------|-------------------------------------------------------------------------------------------------|"
    echo " | -u=USER    | Instala o ambiente. Permite múltiplos usuários, separados por vírgulas. Exemplo: -u=user1,user2 |"
    echo " | -docker    | Instala o Docker e adiciona o(s) usuário(s) ao grupo docker.                                    |"
    echo " | -go        | Instala o Golang.                                                                               |"
    echo " | -jvm       | Instala o SDKMAN! e a versão padrão do Java (atualmente 21).                                    |"
    echo " | -dotnet    | Instala o .NET SDK e Runtime.                                                                   |"
    echo " | -desktop   | Instala aplicações e fontes para ambiente desktop (VSCode, Chrome, fontes Powerline e Nerd).    |"
    echo " | -all       | Instala todas as opções acima.                                                                 |"
    echo " | -h, --help | Mostra esta ajuda.                                                                              |"
    echo " |------------|-------------------------------------------------------------------------------------------------|"
    echo ""
    echo "Exemplos:"
    echo "  Instalar ambiente para o usuário 'developer' com Docker, Go, JVM e .NET:"
    echo ""
    echo "  $0 -u=developer -docker -go -jvm -dotnet"
    echo ""
    echo "  Instalar ambiente para múltiplos usuários 'user1' e 'user2' com Docker:"
    echo ""
    echo "  $0 -u=user1,user2 -docker"
    echo ""
}

cd 
    
BOLD="\033[1m"
RESET="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"

log() {
  local msg="$*"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Timestamp em ciano, mensagem em verde
  echo -e "${BOLD}${CYAN}[${timestamp}]${RESET} ${GREEN}${msg}${RESET}"
}

error_exit() {
  echo "Erro: $*" >&2
  exit 1
}

args=("$@")

# check if no arguments were provided, continue with default user (current user)
if [ "$#" -eq 0 ]; then
    args=("-u=${USER:-$(whoami)}")
else
    # check if script run to show help only
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi

    # Check if -all arg is present to add all options
    if [[ " ${args[@]} " =~ " -all " ]]; then
        log "Option -all detected, adding all options"
        args+=("-docker" "-go" "-jvm" "-dotnet" "-desktop")
    fi

    log "Arguments provided:"
    for arg in "${args[@]}"; do
        log "   Option selected: $arg"
    done
fi

run_as() {
    local user=$1
    shift

    log "Running command as $user -> $*"
    sudo -u "$user" bash -c "$*"
}

install_user_env() {
    local user=$1
    log "Installing user env for $user..."

    # Check if user exists
    if ! id "$user" &>/dev/null; then
        log "Create user"
        log "User $user does not exist. Creating user..."
        sudo adduser --gecos "" $user        
    fi
    
    log "Add user to sudo group"    
    sudo usermod -aG sudo $user
    
    # Check if -docker arg is present to add user to docker group
    if [[ " ${args[@]} " =~ " -docker " ]]; then
        log "Check if docker group exists"
        if ! getent group docker > /dev/null; then
            log "Create docker group"
            sudo groupadd docker                
        fi

        log "Add user to docker group"
        sudo usermod -aG docker $user
    fi

    local HOME_DIR=$(eval echo "~$user")
    log "Home directory for $user is $HOME_DIR"

    cd $HOME_DIR

    if [ -d $HOME_DIR/.vim_runtime ]; then
        log "Vim is already installed"
    else
        log "Installing Vim for $user on $HOME_DIR..."
        run_as $user 'git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime'
                
        if [ -f $HOME_DIR/.vimrc ]; then
            log "Backing up existing .vimrc to .vimrc.backup"
            mv $HOME_DIR/.vimrc $HOME_DIR/.vimrc.backup
        fi

        log "Installing awesome vimrc"
        run_as $user '~/.vim_runtime/install_awesome_vimrc.sh'
        
        log "Setting line numbers in vim"
        run_as $user 'echo set nu | tee -a ~/.vim_runtime/my_configs.vim'
    fi
          
    if [ -d $HOME_DIR/.oh-my-bash ]; then   
        log "Oh My Bash is already installed"
    else
        log "Installing Oh My Bash..."  
        run_as $user 'curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash'

        log "Setting aliases for Oh My Bash"
        if which eza; then
            echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.bashrc
            echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.bashrc
        fi

        if which exa; then
            echo 'alias ls="exa -hHbmgalT -L 1 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.bashrc
            echo 'alias lt="exa -hHbmgalT -L 4 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.bashrc
        fi    
    fi

    # zsh
    if [ -d $HOME_DIR/.oh-my-zsh ]; then
        log "Oh My Zsh is already installed"
    else
        log "Installing Oh My Zsh..." 
        run_as $user 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash'

        sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"frisk\"/g' $HOME_DIR/.zshrc

        log "Setting aliases for Oh My Zsh"
        if which eza; then
            echo 'alias ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.zshrc
            echo 'alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.zshrc
        fi

        if which exa; then
            echo 'alias ls="exa -hHbmgalT -L 1 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.zshrc
            echo 'alias lt="exa -hHbmgalT -L 4 --time-style=long-iso --icons"' | tee -a $HOME_DIR/.zshrc
        fi        
    fi

    log "Changing default shell to zsh for $user"
    sudo chsh -s /usr/bin/zsh $user 

    cd -

    log "User env for $user installed"   
}

install_base() {
    log "Timezone set to America/Sao_Paulo"
    echo "America/Sao_Paulo" | sudo tee /etc/timezone

    log "Installing base packages..."
    sudo apt update -y
    sudo apt install -y wget git zsh gpg zip vim unzip jq telnet curl htop btop python3 python3-pip eza micro btop apt-transport-https gpg zlib1g sqlite3 fzf sudo
    sudo apt install -y 

    log "Base packages installed"    
}

install_docker() {
    # check if docker is installed
    if command -v docker &> /dev/null; then
        log "Docker is already installed"
    else
        log "Installing docker..."
        sudo apt install -y docker.io docker-compose-v2

        if ! getent group docker > /dev/null; then
            log "Create docker group"
            sudo groupadd docker
        fi
    fi
}

install_golang() {
    # check if golang is installed
    if command -v go &> /dev/null; then
        log "Golang is already installed"
    else
        log "Installing golang..."
        wget "https://go.dev/dl/$(curl https://go.dev/VERSION\?m=text | head -n 1).linux-$(dpkg --print-architecture).tar.gz" -O golang.tar.gz
        
        log "Extracting golang tarball to /usr/local"
        sudo tar -C /usr/local -xzf golang.tar.gz
        
        log "Removing golang tarball"
        rm golang.tar.gz

        # check if /etc/environment already contains golang path
        if grep -q "/usr/local/go/bin" /etc/environment; then
            log "Golang path already exists in /etc/environment"
        else
            log "Adding golang to PATH in /etc/profile"
            echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/environment > /dev/null
        fi

        source /etc/environment
    fi
}

install_dotnet() {
    # check if dotnet is installed
    if command -v dotnet &> /dev/null; then
        log ".NET is already installed"
    else
        log "Installing .NET..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg 
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        sudo rm -f packages.microsoft.gpg
        sudo apt update -y
        sudo apt install -y apt-transport-https
        sudo apt install -y dotnet-sdk-8.0 dotnet-runtime-8.0 aspnetcore-runtime-8.0

        log ".NET installed"
    fi    
}

install_jvm() {
    local user=$1
    local HOME_DIR=$(eval echo "~$user")
    
    log "Installing JVM for $user..."

    run_as $user 'curl -s "https://get.sdkman.io" | bash'

    # Inicializar SDKMAN! no shell do usuário
    INIT_SCRIPT="$HOME_DIR/.sdkman/bin/sdkman-init.sh"

    if [[ ! -f "$INIT_SCRIPT" ]]; then
        log "SDKMAN! init script not found for user $user. Skipping JVM installation."
        continue
    fi

    run_as $user 'source ~/.sdkman/bin/sdkman-init.sh && sdk install java'
}

install_dekstop() {
    log "Installing desktop packages..."
    local user=$1
    local HOME_DIR=$(eval echo "~$user")

    log "Installing fonts for desktop..."
    
    if [ -d /tmp/fonts ]; then
        log "Powerline fonts already cloned"
    else
        log "Cloning Powerline fonts"
        git clone --depth=1 https://github.com/powerline/fonts.git /tmp/fonts
    fi

    log "Installing Powerline fonts"
    run_as $user '/tmp/fonts/install.sh'

    if [ -d /tmp/nerd-fonts ]; then
        log "Nerd fonts already cloned"
    else        
        log "Cloning Nerd fonts"
        git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts
    fi

    log "Installing Nerd fonts"
    run_as $user '/tmp/nerd-fonts/install.sh'

    log "Install ms core fonts"
    sudo apt install -y ttf-mscorefonts-installer

    # Check if vscode is installed
    if command -v code &> /dev/null; then
        log "Vscode is already installed"
    else
        log "Install vscode application on desktop"
        echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
        sudo apt install code -y 
        #wget 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' -O vscode.deb
        #sudo dpkg -i /tmp/vscode.deb
        #rm /tmp/vscode.deb
    fi

    log "Install terminal emulators"
    sudo apt install -y terminator alacritty

    if command -v google-chrome &> /dev/null; then
        log "Chrome is already installed"
    else
        log "Install chrome browser"
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        rm google-chrome-stable_current_amd64.deb
    fi

    log "Desktop packages installed"
}

install_base

# Check arg -go for golang
if [[ " ${args[@]} " =~ " -go " ]]; then
    install_golang
fi

# Check arg -dotnet for dotnet
if [[ " ${args[@]} " =~ " -dotnet " ]]; then
    install_dotnet   
fi

# Create an array with users to install user env
users=()
# add root user
users+=("root")  
# add current user
users+=(${USER:-$(whoami)})

# Check arg -u for install
if [[ " ${args[@]} " =~ " -u=" ]]; then
    # Check if are multiple users declared in -u splitted by comma
    users_arg=$(echo "${args[@]}" | grep -oP '(?<=-u=)[^ ]+')    
    IFS=',' read -ra users <<< "$users_arg"
    for user in "${users[@]}"; do
        users+=("$user")
    done
fi

# For each user install user env and jvm
for user in "${users[@]}"; do
    log "Processing user: $user"
    install_user_env "$user"

    if [[ " ${args[@]} " =~ " -jvm " ]]; then
        install_jvm "$user"
    fi

    # Check arg -desktop for desktop packages
    if [[ " ${args[@]} " =~ " -desktop " ]]; then
        install_dekstop "$user"
    fi    

    log "User $user processed"
done

# Check arg -docker for docker install
if [[ " ${args[@]} " =~ " -docker " ]]; then
    install_docker
fi

# Check installs
sudo apt autoclean -y
sudo apt autoremove -y
sudo apt install -y -f
sudo apt install -y --fix-broken
sudo apt install -y --fix-missing

log "Script finished"