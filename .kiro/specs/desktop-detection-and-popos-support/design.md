# Design Document

## Overview

Este design implementa melhorias na documentação e suporte para Pop!_OS, focando em clareza, objetividade e experiência do usuário iniciante. As mudanças incluem:

1. **Documentação simplificada e direta** - Seções concisas com informação acionável
2. **Quick Start para iniciantes** - Guia completo desde git clone até execução
3. **Controle manual de desktop** - Flags --desktop e --skip-desktop
4. **Suporte completo para Pop!_OS** - Correções para EZA e Docker
5. **Testes automatizados** - Validação contínua de Pop!_OS

## Architecture

### Documentation Structure

```
README.md (Principal)
├── Quick Start (Topo - para iniciantes)
│   ├── 1. Clone do repositório
│   ├── 2. Navegação para o diretório
│   ├── 3. Execução do script
│   └── 4. Tempo estimado e o que será instalado
│
├── Desktop Components (Seção dedicada)
│   ├── Detecção automática (3-5 bullets)
│   ├── Controle manual (--desktop / --skip-desktop)
│   └── Tabela de ambientes suportados
│
├── Usage Scenarios (Exemplos práticos)
│   ├── Cenário 1: Instalação completa (desktop)
│   ├── Cenário 2: Servidor (sem desktop)
│   ├── Cenário 3: Desenvolvimento específico
│   └── Cenário 4: Instalação mínima
│
└── Supported Distributions (Tabela)
    └── Pop!_OS incluído com status de teste
```

### Script Changes

```
scripts/prepare.sh
├── parse_arguments()
│   ├── Adicionar --desktop flag
│   ├── Adicionar --skip-desktop flag
│   └── Precedência: manual flags > auto-detection
│
├── detect_desktop_environment()
│   └── Mantém lógica atual (sem mudanças)
│
├── install_eza()
│   ├── Detectar Pop!_OS
│   ├── Aplicar workaround específico
│   └── Fallback para exa se necessário
│
└── install_docker()
    ├── Detectar Pop!_OS
    └── Aplicar workaround específico
```

### Test Framework Changes

```
tests/ansible/
├── config/test-config.yml
│   └── Adicionar Pop!_OS à lista de distribuições
│
├── docker/
│   └── Dockerfile.popos-22.04 (novo)
│
└── scripts/
    └── Validar EZA e Docker no Pop!_OS
```

## Components and Interfaces

### 1. Documentation Components

#### Quick Start Section
```markdown
## 🚀 Quick Start

Para configurar seu ambiente Linux em uma instalação limpa:

```bash
# 1. Clone o repositório
git clone https://github.com/RafaelFino/Linux-prepare.git

# 2. Entre no diretório
cd Linux-prepare

# 3. Execute o script
sudo ./scripts/prepare.sh
```

⏱️ **Tempo estimado**: 15-30 minutos  
📦 **O que será instalado**: Git, Docker, Go, Python, Kotlin, .NET, ferramentas de terminal, e componentes desktop (se detectado)
```

#### Desktop Components Section
```markdown
## 🖥️ Desktop Components

**Detecção Automática**:
- ✓ Instalado automaticamente se desktop detectado (GNOME, KDE, XFCE, etc.)
- ✗ Pulado automaticamente em servidores/headless

**Controle Manual**:
```bash
sudo ./scripts/prepare.sh --desktop        # Força instalação
sudo ./scripts/prepare.sh --skip-desktop   # Pula instalação
```

**Componentes**: VSCode, Chrome, Terminator, Alacritty, Fonts
```

#### Usage Scenarios Section
```markdown
## 📋 Usage Scenarios

### 🖥️ Full Desktop Workstation
```bash
sudo ./scripts/prepare.sh
```
- Todas as linguagens (Go, Python, Kotlin, .NET)
- Docker
- Desktop apps (auto-detected)

### 🖧 Server Setup
```bash
sudo ./scripts/prepare.sh --skip-desktop
```
- Todas as linguagens
- Docker
- Sem componentes desktop

### 🐹 Go Development Only
```bash
sudo ./scripts/prepare.sh --skip-python --skip-kotlin --skip-jvm --skip-dotnet
```
- Docker + Go
- Ferramentas de terminal
```

#### Supported Distributions Table
```markdown
## 🐧 Supported Distributions

| Distribution | Version | Desktop | Status |
|-------------|---------|---------|--------|
| Ubuntu | 20.04, 22.04, 24.04 | ✓ | ✅ Tested |
| Debian | 13 | ✓ | ✅ Tested |
| Linux Mint | 22 | ✓ | ✅ Tested |
| Pop!_OS | 22.04 | ✓ | ✅ Tested |
| Xubuntu | 24.04 | ✓ | ✅ Tested |
```

### 2. Script Components

#### Flag Parsing Logic
```bash
# In parse_arguments()
INSTALL_DESKTOP="auto"  # Default: auto-detect

for arg in "$@"; do
    case $arg in
        --desktop)
            INSTALL_DESKTOP="force"
            log_info "Desktop components will be FORCED"
            ;;
        --skip-desktop)
            INSTALL_DESKTOP="skip"
            log_info "Desktop components will be SKIPPED"
            ;;
        # ... other flags
    esac
done

# Apply logic after parsing
if [ "$INSTALL_DESKTOP" == "auto" ]; then
    if detect_desktop_environment; then
        INSTALL_DESKTOP="true"
    else
        INSTALL_DESKTOP="false"
    fi
elif [ "$INSTALL_DESKTOP" == "force" ]; then
    INSTALL_DESKTOP="true"
elif [ "$INSTALL_DESKTOP" == "skip" ]; then
    INSTALL_DESKTOP="false"
fi
```

#### Pop!_OS Detection
```bash
detect_popos() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "pop" ]] || [[ "$NAME" == *"Pop!_OS"* ]]; then
            return 0
        fi
    fi
    return 1
}
```

#### EZA Installation with Pop!_OS Support
```bash
install_eza() {
    log_info "Installing eza (modern ls replacement)..."
    
    if check_command_available eza || check_command_available exa; then
        log_skip "eza/exa already installed"
        return 0
    fi
    
    # Pop!_OS specific handling
    if detect_popos; then
        log_info "Pop!_OS detected - using alternative installation method"
        
        # Ensure cargo is available
        if ! check_command_available cargo; then
            log_info "Installing cargo for eza installation..."
            apt install -y cargo
        fi
        
        # Try cargo install first - install to /usr/local/bin for global access
        if check_command_available cargo; then
            CARGO_HOME=/tmp/cargo-install cargo install eza --root /usr/local
            rm -rf /tmp/cargo-install
            return 0
        fi
        
        # Fallback to exa from repos
        if check_package_available exa; then
            apt install -y exa
            ln -sf $(which exa) /usr/local/bin/eza
            return 0
        fi
    fi
    
    # Standard installation for other distros
    # ... existing code ...
}
```

**Important**: Cargo installs to `/usr/local/bin` using `--root /usr/local` flag, making binaries accessible to all users system-wide, not just the user who ran the script.

#### Docker Installation with Pop!_OS Support
```bash
install_docker() {
    if [ "$INSTALL_DOCKER" != "true" ]; then
        log_skip "Docker installation skipped"
        return 0
    fi
    
    log_info "Installing Docker..."
    
    # Pop!_OS specific handling
    if detect_popos; then
        log_info "Pop!_OS detected - using System76 recommended method"
        
        # Remove conflicting packages
        apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Install from Pop!_OS repos (they maintain docker.io)
        apt update
        apt install -y docker.io docker-compose
        
        # Enable and start
        systemctl enable docker
        systemctl start docker
        
        log_success "Docker installed for Pop!_OS"
        return 0
    fi
    
    # Standard installation for other distros
    # ... existing code ...
}
```

#### VSCode Installation with Pop!_OS Support
```bash
install_desktop_applications() {
    log_info "Installing desktop applications..."
    
    # Install VSCode
    if check_command_available code; then
        log_skip "VSCode already installed"
    else
        log_info "Installing VSCode..."
        
        # Pop!_OS specific handling (snap may not work well)
        if detect_popos; then
            log_info "Pop!_OS detected - using apt repository method"
            
            # Add Microsoft GPG key
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
            install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            
            # Add VSCode repository
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
            
            # Install
            apt update
            apt install -y code
            
            rm /tmp/packages.microsoft.gpg
            log_success "VSCode installed for Pop!_OS"
        else
            # Ensure snap is available for other distros
            if ! check_command_available snap; then
                log_info "Installing snapd for VSCode..."
                apt install -y snapd
                systemctl enable snapd
                systemctl start snapd
            fi
            
            # Use snap for other distros
            snap install code --classic
            log_success "VSCode installed"
        fi
    fi
    
    # ... rest of desktop applications ...
}
```

### 3. Test Components

#### Pop!_OS Test Configuration
```yaml
# In tests/ansible/config/test-config.yml
distributions:
  # ... existing distributions ...
  
  - name: popos-22.04
    image: pop-os/pop:22.04
    dockerfile: tests/ansible/docker/Dockerfile.popos-22.04
    desktop: gnome
    description: "Pop!_OS 22.04 - System76 Ubuntu derivative"
```

#### Pop!_OS Dockerfile
```dockerfile
# tests/ansible/docker/Dockerfile.popos-22.04
FROM pop-os/pop:22.04

# Install systemd and basic requirements
RUN apt-get update && \
    apt-get install -y \
    systemd \
    systemd-sysv \
    sudo \
    python3 \
    python3-apt \
    && apt-get clean

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up systemd
CMD ["/lib/systemd/systemd"]
```

## Data Models

### Desktop Detection State
```
INSTALL_DESKTOP values:
- "auto"  : Not yet determined (initial state)
- "force" : User explicitly requested (--desktop)
- "skip"  : User explicitly skipped (--skip-desktop)
- "true"  : Will install (after auto-detection or force)
- "false" : Will not install (after auto-detection or skip)
```

### Distribution Detection
```
Distribution Info:
- id: string (ubuntu, debian, pop, mint)
- name: string (full name)
- version: string (22.04, 24.04, etc.)
- is_popos: boolean
- desktop_env: string | null
```

## Error Handling

### Documentation Errors
- **Missing sections**: Validation script checks for required sections
- **Inconsistent information**: Cross-reference validation
- **Broken links**: Link checker in CI

### Script Errors
- **Pop!_OS detection failure**: Fallback to Ubuntu methods
- **EZA installation failure**: Fallback to exa, then to standard ls
- **Docker installation failure**: Clear error message with troubleshooting link
- **VSCode installation failure**: Try snap if apt fails, provide clear error if both fail
- **Flag conflicts**: --desktop and --skip-desktop together = error with clear message

### Test Errors
- **Pop!_OS image unavailable**: Skip Pop!_OS tests with warning
- **Test timeout**: Increase timeout for Pop!_OS (may be slower)
- **Package installation failure**: Detailed logs for debugging

## Testing Strategy

### Documentation Testing
1. **Readability check**: Ensure Quick Start is under 10 lines
2. **Command validation**: All commands are copy-paste ready
3. **Link validation**: All internal links work
4. **Consistency check**: Desktop detection info is consistent across files

### Script Testing
1. **Unit tests**: Test flag parsing logic
2. **Integration tests**: Test full script on Pop!_OS container
3. **Idempotency tests**: Run script twice, verify no errors
4. **Manual override tests**: Verify --desktop and --skip-desktop work

### Distribution Testing
1. **Pop!_OS container**: Full playbook execution
2. **EZA validation**: Verify eza/exa command works
3. **Docker validation**: Verify docker and docker-compose work
4. **Desktop detection**: Verify correct detection on Pop!_OS

### Test Matrix
```
| Distribution | Base | Desktop | Server | Cloud |
|-------------|------|---------|--------|-------|
| Ubuntu 24.04 | ✓ | ✓ | ✓ | ✓ |
| Debian 13 | ✓ | ✗ | ✓ | ✓ |
| Mint 22 | ✓ | ✓ | ✗ | ✗ |
| Pop!_OS 22.04 | ✓ | ✓ | ✓ | ✓ |
| Xubuntu 24.04 | ✓ | ✓ | ✗ | ✗ |
```

## Implementation Notes

### Documentation Priority
1. Quick Start (highest priority - must be perfect)
2. Desktop Components section
3. Usage Scenarios
4. Supported Distributions table
5. Other sections (lower priority)

### Documentation Simplification Rules
1. **Maximum 10 lines per section** - Keep it short
2. **Bullet points only** - No long paragraphs
3. **Remove redundancy** - Say it once
4. **Simple language** - Avoid jargon
5. **Actionable only** - Focus on what to do, not theory

### Script Changes Priority
1. Flag parsing (--desktop, --skip-desktop)
2. Pop!_OS detection function
3. EZA installation workaround
4. Docker installation workaround
5. Help text updates

### Testing Priority
1. Pop!_OS Dockerfile creation
2. Test configuration update
3. EZA validation on Pop!_OS
4. Docker validation on Pop!_OS
5. Full playbook tests

### Backward Compatibility
- Existing behavior preserved when no flags provided
- Auto-detection still works by default
- No breaking changes to existing scripts
- All existing documentation remains valid

### Performance Considerations
- Pop!_OS detection adds <1 second overhead
- Documentation changes have no runtime impact
- Test suite adds ~5 minutes for Pop!_OS tests
- Overall script execution time unchanged
