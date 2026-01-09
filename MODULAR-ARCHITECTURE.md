# Arquitetura Modular - Guia do Desenvolvedor

Este documento descreve a nova arquitetura modular do Linux-prepare, incluindo como desenvolver, manter e solucionar problemas com os módulos.

## 🏗️ Visão Geral da Arquitetura

O Linux-prepare foi refatorado de um script monolítico de 2000+ linhas para uma arquitetura modular que oferece:

- **Separação de responsabilidades**: Cada módulo tem uma função específica
- **Testabilidade**: Módulos podem ser testados isoladamente
- **Manutenibilidade**: Código organizado e fácil de modificar
- **Reutilização**: Módulos podem ser executados independentemente
- **Extensibilidade**: Fácil adição de novos módulos

## 📁 Estrutura Modular

```
scripts/
├── prepare.sh                    # Orquestrador principal
├── modules/                      # Módulos independentes
│   ├── system-detection.sh       # Detecção de sistema
│   ├── docker-install.sh         # Instalação Docker
│   ├── desktop-components.sh     # Componentes desktop
│   ├── terminal-config.sh        # Configuração terminal
│   └── languages/                # Linguagens de programação
│       ├── golang-install.sh
│       ├── python-install.sh
│       ├── dotnet-install.sh
│       └── jvm-kotlin-install.sh
└── lib/                          # Utilitários compartilhados
    ├── logging.sh                # Funções de logging
    ├── package-utils.sh          # Utilitários de pacotes
    ├── version-detection.sh      # Detecção de versão
    └── module-framework.sh       # Framework base para módulos
```

## 🔧 Módulos Principais

### 1. system-detection.sh

**Responsabilidade**: Detectar sistema operacional, versão e ambiente desktop

**Funções Principais**:
```bash
detect_distribution()           # Detecta Ubuntu, Debian, etc.
detect_desktop_environment()    # Detecta GNOME, XFCE, KDE, etc.
detect_ubuntu_version()         # Detecta versão específica (22.04, 24.04, 25.10)
set_global_environment_vars()   # Define variáveis globais do sistema
validate_system_compatibility() # Valida se o sistema é suportado
```

**Variáveis Exportadas**:
```bash
DETECTED_OS=""           # ubuntu, debian, mint, popos
DETECTED_VERSION=""      # 22.04, 24.04, 25.10, etc.
DETECTED_CODENAME=""     # jammy, noble, oracular, etc.
DETECTED_DESKTOP=""      # GNOME, XFCE, KDE, Cinnamon
IS_DESKTOP_ENV=""        # true/false
IS_POPOS=""             # true/false
```

**Uso Independente**:
```bash
./scripts/modules/system-detection.sh
echo "OS: $DETECTED_OS, Version: $DETECTED_VERSION, Desktop: $DETECTED_DESKTOP"
```

### 2. docker-install.sh

**Responsabilidade**: Instalação Docker com configuração específica por versão

**Funções Principais**:
```bash
configure_docker_repository()   # Configura repositório baseado na versão
install_docker_engine()         # Instala Docker CE
configure_docker_compose()      # Configura Docker Compose v2
setup_docker_user_permissions() # Adiciona usuários ao grupo docker
handle_popos_docker_conflicts() # Workarounds específicos Pop!_OS
```

**Recursos**:
- Detecção automática de versão Ubuntu/Xubuntu
- Configuração de repositório específica por versão
- Fallback para versões LTS se repositório específico não disponível
- Workarounds para Pop!_OS

**Uso Independente**:
```bash
./scripts/modules/docker-install.sh
```

### 3. desktop-components.sh

**Responsabilidade**: Instalação de aplicações desktop e fontes

**Funções Principais**:
```bash
install_vscode()               # Instala VSCode via snap
install_google_chrome()        # Instala Chrome estável
install_terminal_emulators()   # Instala Terminator e Alacritty
install_fonts_safely()         # Instala fontes com limpeza automática
install_desktop_apps()         # DBeaver, Flameshot, etc.
```

**Melhorias de Segurança**:
- Diretórios temporários específicos por usuário
- Limpeza automática de arquivos temporários
- Instalação segura de fontes sem usar /tmp compartilhado

**Uso Independente**:
```bash
# Apenas se desktop detectado
./scripts/modules/desktop-components.sh
```

### 4. terminal-config.sh

**Responsabilidade**: Configuração de terminal e shell

**Funções Principais**:
```bash
install_zsh_and_ohmyzsh()      # Instala Zsh e Oh-My-Zsh
configure_bash_improvements()   # Configura Oh-My-Bash
setup_terminal_tools()         # Instala eza/exa, bat, fzf, etc.
configure_shell_aliases()      # Configura aliases e variáveis
get_ls_replacement_package()   # Seleciona eza ou exa baseado na versão
```

**Seleção Inteligente de Pacotes**:
```bash
# Lógica automática baseada na versão
Ubuntu 22.04 e derivados → "exa"
Ubuntu 24.04+ e derivados → "eza"
Xubuntu 25.10 → "eza"
```

**Uso Independente**:
```bash
./scripts/modules/terminal-config.sh
```

### 5. Módulos de Linguagens

#### golang-install.sh
```bash
install_golang()               # Instala Go da fonte oficial
configure_go_environment()     # Configura GOPATH e PATH
```

#### python-install.sh
```bash
install_python_and_tools()     # Instala Python, pip, virtualenv
configure_python_aliases()     # Configura aliases python/pip
```

#### dotnet-install.sh
```bash
configure_microsoft_repo()     # Configura repositório Microsoft
install_dotnet_sdk()          # Instala .NET SDK 8.0
```

#### jvm-kotlin-install.sh
```bash
install_sdkman()              # Instala SDKMAN
install_java_via_sdkman()     # Instala Java LTS
install_kotlin_via_sdkman()   # Instala Kotlin
```

## 📚 Utilitários Compartilhados (lib/)

### logging.sh

**Funções de Logging Padronizadas**:
```bash
log_info "Mensagem informativa"
log_success "Operação bem-sucedida"
log_warning "Aviso importante"
log_error "Erro crítico"
log_debug "Informação de debug"
```

**Recursos**:
- Timestamps automáticos
- Cores padronizadas
- Níveis de log configuráveis
- Saída formatada em português

### package-utils.sh

**Funções de Gerenciamento de Pacotes**:
```bash
safe_apt_install "package1 package2"    # Instalação segura com verificação
check_package_availability "package"     # Verifica se pacote existe
install_with_fallback "primary" "fallback" # Instala com fallback automático
update_package_cache_if_needed()        # Atualiza cache apenas se necessário
```

**Recursos**:
- Verificação de disponibilidade antes da instalação
- Fallbacks automáticos
- Cache inteligente de apt update
- Tratamento de erros robusto

### version-detection.sh

**Funções de Detecção de Versão**:
```bash
get_ubuntu_version()                     # Retorna versão Ubuntu (22.04, 24.04, etc.)
get_package_name_by_version "component" # Seleciona pacote baseado na versão
version_compare "v1" "v2" "operator"    # Compara versões (>=, <=, ==)
get_docker_repo_for_version "version"   # Retorna repositório Docker apropriado
```

**Mapeamentos Suportados**:
```bash
# Exemplos de uso
get_package_name_by_version "ls_replacement"  # Retorna "eza" ou "exa"
get_package_name_by_version "docker_repo"     # Retorna URL do repositório
```

### module-framework.sh

**Framework Base para Módulos**:
```bash
module_init "module_name"               # Inicializa módulo com logging
module_check_dependencies "deps"       # Verifica dependências
module_cleanup                         # Limpeza automática
module_error_handler                   # Tratamento de erros padronizado
```

## 🔄 Fluxo de Execução

### 1. Orquestração Principal (prepare.sh)

```bash
#!/usr/bin/env bash
# Carrega utilitários compartilhados
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/module-framework.sh"

# Parse de argumentos (mantém compatibilidade total)
parse_arguments "$@"

# Executa módulos na ordem correta
execute_module "system-detection"
execute_module "docker-install"
execute_module "languages/golang-install"
execute_module "languages/python-install"
execute_module "languages/dotnet-install"
execute_module "languages/jvm-kotlin-install"
execute_module "terminal-config"
[ "$IS_DESKTOP_ENV" = "true" ] && execute_module "desktop-components"
```

### 2. Execução de Módulo

```bash
execute_module() {
    local module_name="$1"
    local module_path="$(dirname "$0")/modules/${module_name}.sh"
    
    log_info "Executando módulo: $module_name"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        if declare -f "module_main" > /dev/null; then
            module_main
        fi
    else
        log_error "Módulo não encontrado: $module_path"
        return 1
    fi
}
```

## 🛠️ Desenvolvendo Novos Módulos

### Template de Módulo

```bash
#!/usr/bin/env bash
# Novo módulo: scripts/modules/meu-modulo.sh

set -euo pipefail

# Carrega utilitários compartilhados
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/package-utils.sh"
source "$SCRIPT_DIR/../lib/version-detection.sh"

MODULE_NAME="meu-modulo"

# Função principal do módulo
module_main() {
    log_info "Iniciando módulo $MODULE_NAME"
    
    # Verifica dependências
    if ! check_dependencies; then
        log_error "Dependências não atendidas"
        return 1
    fi
    
    # Lógica principal do módulo
    install_my_component
    configure_my_component
    
    log_success "Módulo $MODULE_NAME concluído"
}

# Verifica dependências específicas do módulo
check_dependencies() {
    # Exemplo: verifica se é ambiente desktop
    if [[ "$IS_DESKTOP_ENV" != "true" ]]; then
        log_warning "Módulo $MODULE_NAME requer ambiente desktop"
        return 1
    fi
    return 0
}

# Instala componente
install_my_component() {
    log_info "Instalando meu componente"
    
    # Usa utilitários compartilhados
    safe_apt_install "meu-pacote"
    
    # Lógica específica por versão
    local package_name=$(get_package_name_by_version "meu_componente")
    safe_apt_install "$package_name"
}

# Configura componente
configure_my_component() {
    log_info "Configurando meu componente"
    # Lógica de configuração
}

# Tratamento de erros
trap 'log_error "Erro no módulo $MODULE_NAME na linha $LINENO"' ERR

# Executa se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Carrega detecção de sistema se executado independentemente
    if [[ -f "$SCRIPT_DIR/system-detection.sh" ]]; then
        source "$SCRIPT_DIR/system-detection.sh"
    fi
    module_main "$@"
fi
```

### Diretrizes de Desenvolvimento

1. **Responsabilidade Única**: Cada módulo deve ter uma responsabilidade clara
2. **Independência**: Módulos devem poder ser executados independentemente
3. **Reutilização**: Use utilitários compartilhados em `lib/`
4. **Logging Padronizado**: Use funções de log de `logging.sh`
5. **Tratamento de Erros**: Implemente tratamento robusto de erros
6. **Compatibilidade**: Mantenha compatibilidade com versões anteriores
7. **Documentação**: Documente funções e comportamentos especiais

### Adicionando ao Sistema

1. **Criar o módulo** em `scripts/modules/`
2. **Adicionar ao orquestrador** em `prepare.sh`
3. **Criar testes** em `tests/`
4. **Atualizar documentação**
5. **Testar em múltiplas distribuições**

## 🧪 Testando Módulos

### Teste Individual

```bash
# Testar módulo específico
./scripts/modules/docker-install.sh

# Testar com debug
DEBUG=1 ./scripts/modules/terminal-config.sh

# Testar em container
docker run -it --rm -v $(pwd):/workspace ubuntu:24.04 bash
cd /workspace
./scripts/modules/system-detection.sh
```

### Teste de Integração

```bash
# Testar orquestração completa
./scripts/prepare.sh --skip-desktop

# Testar apenas linguagens
./scripts/prepare.sh --skip-docker --skip-desktop
```

### Validação

```bash
# Validar instalação após módulos
./tests/scripts/validate.sh

# Validar módulo específico
./tests/scripts/validate-module.sh docker-install
```

## 🐛 Solução de Problemas

### Problemas Comuns

#### Módulo não encontrado
```bash
# Erro: Módulo não encontrado: scripts/modules/meu-modulo.sh
# Solução: Verificar caminho e permissões
ls -la scripts/modules/
chmod +x scripts/modules/meu-modulo.sh
```

#### Dependências não carregadas
```bash
# Erro: command not found: log_info
# Solução: Verificar se utilitários estão sendo carregados
source "$(dirname "$0")/../lib/logging.sh"
```

#### Variáveis de sistema não definidas
```bash
# Erro: DETECTED_OS not set
# Solução: Executar system-detection primeiro
source scripts/modules/system-detection.sh
```

### Debug de Módulos

```bash
# Habilitar debug verbose
set -x

# Verificar variáveis de ambiente
env | grep DETECTED_

# Testar funções individualmente
source scripts/lib/logging.sh
log_info "Teste de logging"
```

### Logs e Monitoramento

```bash
# Ver logs do sistema
journalctl -xe

# Verificar instalações
dpkg -l | grep docker
which go python3 dotnet

# Validar configurações
echo $SHELL
cat ~/.zshrc | grep alias
```

## 🔄 Migração e Compatibilidade

### Compatibilidade com Versão Anterior

A nova arquitetura mantém **100% de compatibilidade** com a versão anterior:

- ✅ Mesmas flags de linha de comando
- ✅ Mesmo comportamento de instalação
- ✅ Mesma saída e logging
- ✅ Mesmos componentes instalados

### Migração Gradual

Para projetos que estendem o Linux-prepare:

1. **Continue usando** `prepare.sh` normalmente
2. **Adicione módulos** conforme necessário
3. **Teste extensivamente** antes de produção
4. **Monitore logs** para identificar problemas

### Extensões Personalizadas

```bash
# Criar módulo personalizado
cp scripts/modules/template.sh scripts/modules/minha-empresa.sh

# Adicionar ao prepare.sh local
echo 'execute_module "minha-empresa"' >> scripts/prepare.sh

# Manter em repositório separado
git submodule add https://github.com/empresa/linux-prepare-extensions.git extensions
```

## 📈 Performance e Otimizações

### Execução Paralela (Futuro)

```bash
# Módulos que podem executar em paralelo
run_parallel_modules() {
    execute_module "languages/golang-install" &
    execute_module "languages/python-install" &
    execute_module "languages/dotnet-install" &
    wait  # Aguarda todos terminarem
}
```

### Cache e Idempotência

- **Cache de pacotes**: `apt update` executado apenas quando necessário
- **Verificação de instalação**: Módulos verificam se trabalho já foi feito
- **Rollback**: Capacidade de desfazer instalações em caso de erro

### Monitoramento de Recursos

```bash
# Monitorar uso durante execução
htop &
./scripts/prepare.sh
```

## 🚀 Roadmap Futuro

### Próximas Funcionalidades

1. **Execução Paralela**: Módulos independentes em paralelo
2. **Sistema de Plugins**: Carregamento dinâmico de módulos
3. **Configuração Declarativa**: YAML/JSON para configurar instalação
4. **Rollback Automático**: Desfazer instalações em caso de erro
5. **Métricas**: Coleta de métricas de performance e uso

### Melhorias Planejadas

1. **Interface Web**: Dashboard para gerenciar instalações
2. **Profiles**: Perfis pré-definidos (developer, devops, data-science)
3. **Updates**: Sistema de atualização automática de componentes
4. **Backup**: Backup automático de configurações

---

Este documento será atualizado conforme a arquitetura evolui. Para contribuições ou dúvidas, consulte o [CONTRIBUTING.md](CONTRIBUTING.md) ou abra uma issue no GitHub.