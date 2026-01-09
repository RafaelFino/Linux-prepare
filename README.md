# Configuração de Ambiente de Desenvolvimento Linux

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Ansible](https://img.shields.io/badge/Ansible-2.9+-blue.svg)](https://www.ansible.com/)

Scripts automatizados para preparar instalações Linux novas como ambientes de desenvolvimento completos com ferramentas modernas, múltiplas linguagens de programação e configurações de terminal otimizadas.

## 🎯 Visão Geral

Este projeto fornece automação abrangente para configurar ambientes de desenvolvimento Linux em múltiplas plataformas:
- **Estações de trabalho desktop** (Ubuntu, Debian, Mint, Pop!_OS)
- **Dispositivos ARM** (Raspberry Pi, Odroid)
- **Instâncias na nuvem** (Oracle Cloud, GitHub Codespaces, Killercoda)

Escolha entre implementações com **Shell Scripts** (rápido, standalone) ou **Ansible** (escalável, declarativo).

## 🚀 Início Rápido

```bash
git clone https://github.com/RafaelFino/Linux-prepare.git
cd Linux-prepare
sudo ./scripts/prepare.sh
```

**Tempo**: 15-30 min | **Instala**: Docker, Go, Python, Kotlin, .NET, ferramentas de terminal, apps desktop (se detectado)

## ✨ Funcionalidades

### Ferramentas de Desenvolvimento
- 🐳 **Docker & Docker Compose v2** - Plataforma de containerização
- 🐹 **Golang** - Versão mais recente com atualizações automáticas
- 🐍 **Python 3** - Com pip, virtualenv e ferramentas de desenvolvimento
- ☕ **JVM (Java)** - Via SDKMAN para gerenciamento fácil de versões
- 🎯 **Kotlin** - Via SDKMAN
- 💜 **.NET SDK 8.0** - Desenvolvimento multiplataforma
- 🔨 **Build Tools** - cmake, build-essential
- 🗄️ **Clientes de Banco de Dados** - PostgreSQL, MySQL, Redis

### Ferramentas CLI Modernas
- 📂 **eza** - Substituto moderno do ls com ícones e visualização em árvore
- 🔍 **fzf** - Localizador fuzzy para histórico de comandos
- 🦇 **bat** - Cat com destaque de sintaxe (instalado como `batcat` no Ubuntu, com alias para `bat`)
- 🌐 **httpie** - Cliente HTTP amigável
- 📋 **yq** - Processador YAML (como jq para YAML)
- 📊 **glances** - Monitor de sistema avançado
- 🎨 **neofetch** - Ferramenta de informações do sistema (opcional)
- 💨 **dust** - Analisador de uso de disco intuitivo (opcional)
- 🐙 **gh** - GitHub CLI
- 🌳 **tig** - Interface em modo texto para Git
- 🖥️ **screen** - Multiplexador de terminal
- ☸️ **k9s** - TUI para Kubernetes
- 📚 **tldr** - Páginas man simplificadas (opcional, instalado via pip3 se não estiver nos repositórios)

### Experiência de Terminal
- 🐚 **Zsh** - Shell moderno definido como padrão
- 🎨 **Oh-My-Zsh** - Com tema 'frisk' e mais de 30 plugins
- 🎨 **Oh-My-Bash** - Configuração aprimorada do Bash
- 📝 **Micro Editor** - Editor de terminal intuitivo (padrão)
- 📝 **Vim** - Com configuração awesome vimrc

### Componentes Desktop (Auto-detectados)
- 💻 **VSCode** - Editor de código popular
- 🌐 **Google Chrome** - Navegador web
- 📸 **Flameshot** - Ferramenta de captura de tela
- 🗄️ **DBeaver CE** - Ferramenta universal de banco de dados
- 🖥️ **Emuladores de Terminal** - Terminator & Alacritty
- 🔤 **Fontes** - Powerline & Nerd Fonts (FiraCode, JetBrainsMono, Hack)

### Ferramentas de Segurança e Rede
- 🔐 **OpenSSL** - Kit de ferramentas de criptografia
- 🔌 **OpenSSH Server** - Acesso remoto
- 🌐 **netcat** - Utilitário de rede

### Configuração do Sistema
- 🌍 **Fuso Horário**: America/Sao_Paulo
- 👤 **Gerenciamento de Usuários**: Atribuição automática ao grupo sudo
- 🔄 **Idempotente**: Seguro para executar múltiplas vezes
- 🎨 **Logs Coloridos**: Saída clara e com timestamp em português

## 📋 Usos Comuns

```bash
# Instalação completa (auto-detecta desktop)
sudo ./scripts/prepare.sh

# Servidor (sem desktop)
sudo ./scripts/prepare.sh --skip-desktop

# Apenas Go
sudo ./scripts/prepare.sh --skip-python --skip-kotlin --skip-jvm --skip-dotnet

# Apenas Python
sudo ./scripts/prepare.sh --skip-go --skip-kotlin --skip-jvm --skip-dotnet

# Múltiplos usuários
sudo ./scripts/prepare.sh -u=dev1,dev2
```

### Instalação de Ferramentas Opcionais
Após executar o script principal, você pode instalar ferramentas opcionais adicionais:

```bash
cd scripts

# Instalar Node.js e Rust
sudo ./add-opt.sh --nodejs --rust

# Instalar ferramentas Kubernetes
sudo ./add-opt.sh --kubectl --helm

# Instalar ferramentas Git TUI
sudo ./add-opt.sh --lazygit --delta

# Instalar tudo opcional
sudo ./add-opt.sh --all

# Ver todas as opções
sudo ./add-opt.sh --help
```

**Ferramentas Opcionais Disponíveis:**
- **Linguagens**: Node.js, Rust, Ruby
- **Infraestrutura**: Terraform, kubectl, Helm
- **Ferramentas Git**: lazygit, delta
- **Ferramentas de Container**: lazydocker
- **Shell**: Starship, zoxide, plugins tmux
- **Editores**: Neovim
- **Apps Desktop**: Postman, Insomnia, Obsidian
- **Banco de Dados**: Ferramentas MongoDB
- **Python**: Poetry, pipx

## 📋 Pré-requisitos

- **Sistema Operacional**: Linux baseado em Debian (Ubuntu 20.04+, Debian 13+, Linux Mint, etc.)
- **Privilégios**: Acesso root ou sudo
- **Rede**: Conexão com a internet necessária
- **Espaço em Disco**: ~5GB para instalação completa (menos sem desktop)
- **Tempo**: 10-30 minutos dependendo dos componentes

## 📦 Distribuições Suportadas

| Distribuição | Versão | Status |
|-------------|---------|--------|
| Ubuntu | 22.04, 24.04 | ✅ Testado |
| Debian | 13 | ✅ Testado |
| Linux Mint | 22+ | ✅ Testado |
| Pop!_OS | 22.04 | ✅ Testado |
| Xubuntu | 24.04, 25.10 | ✅ Testado |
| Raspberry Pi OS | Mais recente | ✅ ARM |

**Nota Pop!_OS**: Usa workarounds especiais para EZA, Docker, VSCode  
**Nota Xubuntu 25.10**: Suporte completo com detecção automática de versão para pacotes eza/exa

## 🎮 Uso

### Script Principal (scripts/prepare.sh)

```bash
sudo ./prepare.sh [OPÇÕES]
```

## 🖥️ Componentes Desktop

**Auto-detectado**: Desktop → Instala VSCode, Chrome, fontes | Servidor → Pula

**Controle manual**:
```bash
sudo ./scripts/prepare.sh --desktop        # Força instalação
sudo ./scripts/prepare.sh --skip-desktop   # Pula instalação
```

**Inclui**: VSCode, Chrome, Terminator, Alacritty, Nerd Fonts, Flameshot, DBeaver

#### Opções

| Flag | O que faz |
|------|-----------|
| `-u=USER1,USER2` | Adiciona usuários |
| `--desktop` | Força instalação desktop |
| `--skip-desktop` | Pula instalação desktop |
| `--skip-docker` | Pula Docker |
| `--skip-go` | Pula Go |
| `--skip-python` | Pula Python |
| `--skip-kotlin` | Pula Kotlin |
| `--skip-jvm` | Pula Java |
| `--skip-dotnet` | Pula .NET |

**Padrão**: Instala tudo, auto-detecta desktop

## 📚 Mais Exemplos

Veja a seção [Usos Comuns](#-usos-comuns) acima para cenários típicos.

## 🌍 Scripts Específicos por Ambiente

### Desktop (scripts/prepare.sh)
Script completo para estações de trabalho desktop e servidores.

```bash
cd scripts
sudo ./prepare.sh --desktop
```

### Raspberry Pi (rasp/rasp4-prepare.sh)
Otimizado para Raspberry Pi 4 com Ubuntu (arquitetura ARM).

```bash
cd rasp
sudo ./rasp4-prepare.sh
```

### Odroid (odroid/odroid-prepare.sh)
Otimizado para dispositivos Odroid com Ubuntu (arquitetura ARM).

```bash
cd odroid
sudo ./odroid-prepare.sh
```

### Oracle Cloud Infrastructure (cloud/oci-ubuntu.sh)
Configurado para VMs OCI com regras de firewall.

```bash
cd cloud
sudo ./oci-ubuntu.sh
```

### GitHub Codespaces (cloud/github-workspace.sh)
Otimizado para ambiente GitHub Codespaces.

```bash
cd cloud
./github-workspace.sh
```

### Killercoda (cloud/killercoda.sh)
Configuração rápida para ambientes interativos Killercoda.

```bash
# Executar diretamente da URL
curl https://raw.githubusercontent.com/RafaelFino/Linux-prepare/main/cloud/killercoda.sh | bash
```


## 📊 Comparação de Componentes por Ambiente

| Componente | Desktop | Servidor | Raspberry Pi | Odroid | OCI | GitHub | Killercoda |
|-----------|---------|----------|--------------|--------|-----|--------|------------|
| Pacotes Base | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Docker | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Golang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Python | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Kotlin | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| JVM | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| .NET | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Zsh/Oh-My-Zsh | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Vim/Micro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eza/exa** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| VSCode | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Chrome | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Fontes | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Emuladores de Terminal | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

*Componentes desktop auto-detectados  
**Seleção automática: "exa" para Ubuntu 22.04, "eza" para Ubuntu 24.04+/Xubuntu 25.10

## 🛠️ O Que é Instalado

### Pacotes Base
```
wget, git, zsh, gpg, zip, unzip, vim, jq, telnet, curl, htop, btop,
python3, python3-pip, micro, apt-transport-https, zlib1g, sqlite3,
fzf, sudo, ca-certificates, gnupg
```

### Ferramentas CLI Modernas
```
eza         - Substituto moderno do ls com ícones
bat         - Cat com destaque de sintaxe
httpie      - Cliente HTTP amigável
yq          - Processador YAML (como jq)
glances     - Monitor de sistema avançado
neofetch    - Exibição de informações do sistema
dust        - Analisador de uso de disco intuitivo
gh          - GitHub CLI
tig         - Interface em modo texto para Git
screen      - Multiplexador de terminal
k9s         - TUI para Kubernetes
tldr        - Páginas man simplificadas
```

### Ferramentas de Build e Desenvolvimento
```
cmake               - Sistema de build multiplataforma
build-essential     - Ferramentas de compilação (gcc, g++, make)
```

### Clientes de Banco de Dados
```
postgresql-client   - Ferramentas cliente PostgreSQL
redis-tools         - CLI e ferramentas Redis
```

### Segurança e Rede
```
openssl            - Kit de ferramentas de criptografia
openssh-server     - Servidor SSH
netcat-openbsd     - Utilitário de rede
```

### Linguagens de Programação

#### Python
- Python 3.x (versão mais recente do repositório)
- pip3 (gerenciador de pacotes)
- virtualenv (ambientes virtuais)
- python3-dev (headers de desenvolvimento)
- Aliases: `python` → `python3`, `pip` → `pip3`

#### Golang
- Versão estável mais recente do site oficial do Go
- Instalado em `/usr/local/go`
- Adicionado ao PATH do sistema
- `$HOME/go/bin` adicionado ao PATH do usuário

#### Kotlin
- Instalado via SDKMAN
- Versão estável mais recente
- Inclui compilador Kotlin e REPL

#### JVM (Java)
- Instalado via SDKMAN
- Versão LTS mais recente
- Gerenciado por usuário

#### .NET
- .NET SDK 8.0
- Do repositório oficial da Microsoft
- Inclui runtime e ferramentas de desenvolvimento

### Configuração de Terminal

#### Zsh
- Definido como shell padrão para todos os usuários
- Framework Oh-My-Zsh instalado
- Tema: `frisk`
- Mais de 30 plugins habilitados:
  ```
  git, colorize, command-not-found, compleat, composer, cp, debian,
  dircycle, docker, docker-compose, dotnet, eza, fzf, gh, golang,
  grc, nats, pip, postgres, procs, python, qrcode, redis-cli, repo,
  rust, sdk, ssh, sudo, systemd, themes, ubuntu, vscode,
  zsh-interactive-cd
  ```

#### Bash
- Framework Oh-My-Bash instalado
- Configuração aprimorada
- Mesmos aliases do Zsh

#### Aliases
```bash
ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"  # ls aprimorado
lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"  # Visualização em árvore (4 níveis)
python=python3                                          # Alias Python
pip=pip3                                                # Alias Pip
```

#### Variáveis de Ambiente
```bash
EDITOR=micro    # Editor padrão
VISUAL=micro    # Editor visual
```

#### Vim
- Configuração awesome vimrc
- Números de linha habilitados
- Destaque de sintaxe aprimorado
- Múltiplos plugins

### Componentes Desktop (Auto-detectados)

#### Aplicações
- **VSCode**: Instalado via snap
- **Google Chrome**: Versão estável mais recente
- **Flameshot**: Ferramenta de captura de tela com anotação
- **DBeaver CE**: Ferramenta GUI universal de banco de dados

#### Emuladores de Terminal
- **Terminator**: Configurado com transparência e Nerd Font
- **Alacritty**: Configurado com transparência e Nerd Font

#### Fontes
- **Powerline Fonts**: Para símbolos aprimorados de terminal
- **Nerd Fonts**: FiraCode, JetBrainsMono, Hack
- **MS Core Fonts**: Arial, Times New Roman, etc.

## 🔄 Shell Scripts vs Ansible

### Quando Usar Shell Scripts

**Vantagens:**
- ✅ Sem dependências (apenas bash)
- ✅ Execução rápida
- ✅ Simples de entender
- ✅ Perfeito para máquinas únicas
- ✅ Fácil de customizar em tempo real

**Melhor Para:**
- Estações de trabalho pessoais
- Configurações únicas
- Prototipagem rápida
- Ambientes de aprendizado
- Implantações de servidor único

**Uso:**
```bash
sudo ./scripts/prepare.sh --desktop
```

### Quando Usar Ansible

**Vantagens:**
- ✅ Configuração declarativa
- ✅ Idempotente por design
- ✅ Escalável para centenas de hosts
- ✅ Organização baseada em roles
- ✅ Fácil de versionar
- ✅ Capacidade de dry-run
- ✅ Execução paralela

**Melhor Para:**
- Múltiplos servidores
- Infraestrutura como Código
- Ambientes de equipe
- Implantações repetíveis
- Pipelines CI/CD
- Gerenciamento de configuração

**Uso:**
```bash
ansible-playbook -i inventory ansible/site.yml
```

### Tabela de Comparação

| Funcionalidade | Shell Scripts | Ansible |
|----------------|---------------|---------|
| Tempo de Configuração | Instantâneo | Requer instalação do Ansible |
| Curva de Aprendizado | Baixa | Média |
| Escalabilidade | Host único | Múltiplos hosts |
| Velocidade de Execução | Rápida | Moderada |
| Idempotência | Implementação manual | Integrada |
| Dry Run | Não disponível | Flag `--check` |
| Execução Paralela | Limitada | Integrada |
| Gerenciamento de Configuração | Baseado em script | YAML declarativo |
| Melhor Caso de Uso | Máquinas pessoais | Frotas de infraestrutura |

## 📁 Estrutura do Projeto

```
linux-prepare/
├── scripts/
│   ├── prepare.sh              # Script principal (orquestrador modular)
│   ├── add-opt.sh              # Instalação de ferramentas opcionais
│   ├── modules/                # Módulos independentes (Nova Arquitetura)
│   │   ├── system-detection.sh       # Detecção de OS/Desktop
│   │   ├── docker-install.sh         # Instalação Docker
│   │   ├── desktop-components.sh     # Componentes desktop
│   │   ├── terminal-config.sh        # Configuração de terminal
│   │   └── languages/                # Linguagens de programação
│   │       ├── golang-install.sh     # Instalação Golang
│   │       ├── python-install.sh     # Instalação Python
│   │       ├── dotnet-install.sh     # Instalação .NET
│   │       └── jvm-kotlin-install.sh # Instalação JVM/Kotlin
│   └── lib/                    # Utilitários compartilhados (Nova Arquitetura)
│       ├── logging.sh                 # Funções de logging
│       ├── package-utils.sh           # Utilitários de pacotes
│       └── version-detection.sh       # Lógica específica por versão
├── rasp/
│   └── rasp4-prepare.sh        # Otimizado para Raspberry Pi 4
├── odroid/
│   └── odroid-prepare.sh       # Otimizado para Odroid
├── cloud/
│   ├── oci-ubuntu.sh           # Oracle Cloud Infrastructure
│   ├── github-workspace.sh     # GitHub Codespaces
│   └── killercoda.sh           # Ambientes Killercoda
├── ansible/
│   ├── README.md               # Documentação Ansible
│   ├── site.yml                # Playbook principal
│   ├── inventory/              # Inventários de hosts
│   ├── group_vars/             # Variáveis globais
│   ├── roles/                  # Roles Ansible
│   │   ├── base/               # Pacotes base e fuso horário
│   │   ├── docker/             # Instalação Docker
│   │   ├── golang/             # Instalação Golang
│   │   ├── python/             # Instalação Python
│   │   ├── kotlin/             # Instalação Kotlin
│   │   ├── dotnet/             # Instalação .NET
│   │   ├── terminal-tools/     # eza, micro, vim
│   │   ├── shell-config/       # Configuração Zsh, Bash
│   │   ├── desktop/            # Componentes desktop
│   │   └── users/              # Gerenciamento de usuários
│   └── playbooks/              # Playbooks específicos por ambiente
├── tests/
│   ├── docker/                 # Dockerfiles para testes
│   └── scripts/                # Scripts de validação
└── README.md                   # Este arquivo
```

## 🏗️ Arquitetura Modular (Nova)

O projeto foi refatorado para usar uma **arquitetura modular** que oferece melhor manutenibilidade, testabilidade e flexibilidade:

### Benefícios da Nova Arquitetura

- **🔧 Modularidade**: Cada componente é um módulo independente
- **🧪 Testabilidade**: Módulos podem ser testados isoladamente
- **🔄 Reutilização**: Módulos podem ser executados independentemente
- **📝 Manutenibilidade**: Código organizado por responsabilidade
- **🎯 Flexibilidade**: Fácil adição de novos módulos
- **⚡ Performance**: Execução otimizada com detecção de versão

### Módulos Principais

| Módulo | Responsabilidade | Localização |
|--------|------------------|-------------|
| **system-detection** | Detecta OS, versão, desktop | `scripts/modules/system-detection.sh` |
| **docker-install** | Instalação Docker com repositórios específicos por versão | `scripts/modules/docker-install.sh` |
| **desktop-components** | VSCode, Chrome, fontes, emuladores de terminal | `scripts/modules/desktop-components.sh` |
| **terminal-config** | Zsh, Oh-My-Zsh, eza/exa baseado na versão | `scripts/modules/terminal-config.sh` |
| **golang-install** | Instalação e configuração Golang | `scripts/modules/languages/golang-install.sh` |
| **python-install** | Instalação Python com pip e virtualenv | `scripts/modules/languages/python-install.sh` |
| **dotnet-install** | Instalação .NET SDK | `scripts/modules/languages/dotnet-install.sh` |
| **jvm-kotlin-install** | SDKMAN, Java e Kotlin | `scripts/modules/languages/jvm-kotlin-install.sh` |

### Utilitários Compartilhados

| Utilitário | Função | Localização |
|------------|--------|-------------|
| **logging.sh** | Funções de log padronizadas | `scripts/lib/logging.sh` |
| **package-utils.sh** | Instalação segura de pacotes com fallbacks | `scripts/lib/package-utils.sh` |
| **version-detection.sh** | Detecção de versão e seleção de pacotes | `scripts/lib/version-detection.sh` |

### Detecção Inteligente de Versão

A nova arquitetura inclui **detecção automática de versão** para selecionar pacotes apropriados:

```bash
# Exemplo: Seleção automática eza/exa baseada na versão Ubuntu
Ubuntu 22.04 e derivados → usa "exa"
Ubuntu 24.04+ e derivados → usa "eza"
Xubuntu 25.10 → usa "eza" (detecção automática)
```

### Execução Modular

O script principal (`prepare.sh`) agora atua como **orquestrador**:

```bash
# Execução tradicional (compatibilidade total)
sudo ./scripts/prepare.sh

# Os módulos são executados automaticamente na ordem correta:
# 1. system-detection → 2. docker-install → 3. languages/* → 4. terminal-config → 5. desktop-components
```

### Compatibilidade

- ✅ **100% compatível** com versões anteriores
- ✅ Mesmas flags e opções de linha de comando
- ✅ Mesmo comportamento e saída
- ✅ Nenhuma mudança para usuários finais

## 🐛 Solução de Problemas

### Problemas Comuns

#### Problema: "apt: command not found"
**Causa**: Não é uma distribuição baseada em Debian  
**Solução**: Este script suporta apenas distribuições baseadas em Debian (Ubuntu, Debian, Mint)

#### Problema: "Permission denied"
**Causa**: Script não executado com sudo  
**Solução**: Execute com `sudo ./prepare.sh`

#### Problema: "Docker command not found after installation"
**Causa**: Necessário fazer logout e login novamente para associação ao grupo  
**Solução**: Faça logout e login novamente, ou execute `newgrp docker`

#### Problema: "SDKMAN installation fails"
**Causa**: Problemas de rede ou dependências faltando  
**Solução**: Verifique a conexão com a internet, garanta que curl e zip estão instalados

#### Problema: "Snap not available for VSCode"
**Causa**: Snap não instalado ou não suportado  
**Solução**: Instale snapd: `sudo apt install snapd`

#### Problema: "Fonts not showing in terminal"
**Causa**: Terminal não configurado para usar Nerd Fonts  
**Solução**: Configure o terminal para usar "FiraCode Nerd Font" ou similar

#### Problema: "Oh-My-Zsh plugins not working"
**Causa**: Dependências de plugin faltando  
**Solução**: O script instala dependências automaticamente, mas alguns plugins podem precisar de pacotes adicionais

#### Problema: "Script hangs during user creation"
**Causa**: Aguardando entrada de senha  
**Solução**: Digite a senha quando solicitado, ou use apenas usuários existentes

### Problemas Específicos por Ambiente

#### Raspberry Pi / Odroid
- **Problema**: Alguns pacotes não disponíveis para ARM
- **Solução**: O script detecta automaticamente a arquitetura e usa pacotes compatíveis com ARM

#### GitHub Codespaces
- **Problema**: Algumas configurações conflitam com padrões do Codespaces
- **Solução**: O script preserva configurações existentes do Codespaces

#### Instâncias na Nuvem (OCI)
- **Problema**: Firewall bloqueando conexões
- **Solução**: Configure regras de firewall no console da nuvem

### Obtendo Ajuda

1. **Verifique os logs**: O script fornece saída colorida detalhada
2. **Execute com modo verbose**: Adicione `set -x` ao script para debugging
3. **Verifique logs do sistema**: `journalctl -xe` para serviços systemd
4. **Verifique a instalação**: Execute comandos de validação manualmente
5. **Abra uma issue**: [GitHub Issues](https://github.com/RafaelFino/Linux-prepare/issues)

### Comandos de Validação

```bash
# Verificar versões instaladas
docker --version
docker compose version
go version
python3 --version
dotnet --version
kotlin -version
java -version

# Verificar shell
echo $SHELL
zsh --version

# Verificar aliases
alias ls
alias lt

# Verificar variáveis de ambiente
echo $EDITOR
echo $VISUAL

# Verificar grupos de usuário
groups
```

## 🧪 Testes

> **Referência Rápida**: Veja [tests/QUICK-REFERENCE.md](tests/QUICK-REFERENCE.md) para todos os comandos de teste

Este projeto inclui dois frameworks de teste completos:
- **Testes de Scripts**: Validam instalação via scripts Bash
- **Testes Ansible**: Validam instalação via playbooks Ansible

Ambos testam os mesmos componentes e distribuições.

### Testes de Scripts

#### Teste Rápido (15 minutos)

```bash
# Do diretório raiz do projeto
./tests/quick-test.sh
```

Testa instalação básica com Docker, Go, Python e ferramentas de terminal no Ubuntu 24.04.

#### Testar Apenas Derivados (30 minutos)

```bash
# Testar Xubuntu e Linux Mint
./tests/test-derivatives.sh
```

Testa Xubuntu 24.04 (XFCE) e Linux Mint 22 especificamente.

#### Testes Automatizados Completos (80 minutos)

```bash
# Do diretório raiz do projeto
./tests/run-all-tests.sh
```

Executa testes completos em:
- Ubuntu 24.04
- Debian 13
- Xubuntu 24.04
- Linux Mint 22
- Idempotência (script executa duas vezes)

### Testes Ansible

#### Teste Rápido (15 minutos)

```bash
./tests/ansible/quick-test.sh
```

Testa playbooks Ansible no Ubuntu 24.04 apenas.

#### Testar Apenas Derivados (30 minutos)

```bash
./tests/ansible/test-derivatives.sh
```

Testa playbooks Ansible no Xubuntu e Mint.

#### Testes Ansible Completos (80 minutos)

```bash
./tests/ansible/run-ansible-tests.sh
```

Executa testes completos de Ansible em todas as distribuições.

#### Testar Componentes Específicos

```bash
# Testar playbook específico
./tests/ansible/run-ansible-tests.sh --playbook server.yml

# Testar role específica
./tests/ansible/run-ansible-tests.sh --role docker

# Testar distribuição específica
./tests/ansible/run-ansible-tests.sh --distro ubuntu-24.04
```

### Teste Individual de Distribuição (Scripts)

```bash
# Testar Ubuntu 24.04
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test-ubuntu .
docker run --rm test-ubuntu /tmp/validate.sh

# Testar Debian 13
docker build -f tests/docker/Dockerfile.debian-13 -t test-debian .
docker run --rm test-debian /tmp/validate.sh

# Testar Xubuntu 24.04
docker build -f tests/docker/Dockerfile.xubuntu-24.04 -t test-xubuntu .
docker run --rm test-xubuntu /tmp/validate.sh

# Testar Linux Mint 22
docker build -f tests/docker/Dockerfile.mint-22 -t test-mint .
docker run --rm test-mint /tmp/validate.sh
```

### Testes Manuais em Container

```bash
# Teste interativo
docker run -it --rm -v $(pwd):/workspace -w /workspace ubuntu:24.04 bash

# Dentro do container:
apt update && apt install -y sudo
./scripts/prepare.sh --skip-desktop
./tests/scripts/validate.sh
```

### Apenas Validação

Se você já executou o script e quer validar:

```bash
./tests/scripts/validate.sh
```

### Documentação de Testes

- **[tests/TESTING.md](tests/TESTING.md)** - Guia detalhado de testes de scripts
- **[tests/ansible/README.md](tests/ansible/README.md)** - Guia completo de testes Ansible
- **[tests/QUICK-REFERENCE.md](tests/QUICK-REFERENCE.md)** - Referência rápida de comandos

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para enviar um Pull Request.

### Como Contribuir

1. Faça um fork do repositório
2. Crie sua branch de funcionalidade (`git checkout -b feature/FuncionalidadeIncrivel`)
3. Faça commit das suas mudanças (`git commit -m 'Add: alguma funcionalidade incrível'`)
4. Faça push para a branch (`git push origin feature/FuncionalidadeIncrivel`)
5. Abra um Pull Request

### Diretrizes

- Siga o estilo de código existente
- Teste em múltiplas distribuições
- Atualize a documentação
- Adicione exemplos para novas funcionalidades
- Garanta idempotência

## 📝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👤 Autor

**Rafael Fino**
- GitHub: [@RafaelFino](https://github.com/RafaelFino)

## 🙏 Agradecimentos

- [Oh-My-Zsh](https://ohmyz.sh/) - Framework Zsh
- [Oh-My-Bash](https://ohmybash.nntoan.com/) - Framework Bash
- [awesome-vimrc](https://github.com/amix/vimrc) - Configuração Vim
- [eza](https://github.com/eza-community/eza) - Substituto moderno do ls
- [micro](https://micro-editor.github.io/) - Editor de terminal
- [SDKMAN](https://sdkman.io/) - Gerenciador de SDK

## 📚 Recursos Adicionais

### Documentação do Projeto
- **[📚 Índice de Documentação](DOCS-INDEX.md)** - Guia completo de toda a documentação
- [🆕 Guia de Ferramentas Opcionais](OPTIONAL-TOOLS.md) - Guia para 43 novas ferramentas adicionadas
- [Guia de Testes de Distribuição](tests/DISTRIBUTIONS.md) - Informações detalhadas sobre distribuições testadas
- [Guia de Testes](tests/TESTING.md) - Como executar testes
- [Qual Teste Executar?](tests/WHICH-TEST.md) - Guia de decisão para testes

### Documentação Externa
- [Documentação Ansible](https://docs.ansible.com/)
- [Documentação Docker](https://docs.docker.com/)
- [Documentação Golang](https://golang.org/doc/)
- [Documentação Python](https://docs.python.org/)
- [Documentação .NET](https://docs.microsoft.com/dotnet/)
- [Documentação Kotlin](https://kotlinlang.org/docs/)

---

**Nota**: Este script modifica a configuração do sistema. Sempre revise os scripts antes de executar com privilégios sudo. Teste em uma VM ou container primeiro se não tiver certeza.

**Tempo de Execução**: Aproximadamente 10-30 minutos dependendo dos componentes e velocidade da internet.

**Espaço em Disco**: ~5GB para instalação completa (menos sem componentes desktop).
