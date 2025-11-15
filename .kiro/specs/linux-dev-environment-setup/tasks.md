# Plano de Implementação

- [x] 1. Refatorar e melhorar o script principal (scripts/prepare.sh)
  - Implementar sistema de logging colorido em inglês com timestamps e símbolos
  - Implementar sistema de detecção de estado para idempotência completa
  - Implementar verificação de disponibilidade de pacotes antes da instalação
  - Adicionar suporte para argumentos --skip-* (--skip-docker, --skip-go, --skip-jvm, --skip-dotnet)
  - Implementar detecção automática de ambiente desktop
  - Atualizar função show_help() com documentação detalhada de todos os argumentos
  - Implementar configuração de timezone para America/Sao_Paulo
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 13.1, 13.2, 13.3, 13.4, 13.5, 15.1-15.9, 18.1-18.10, 28.1-28.10, 32.1-32.5, 36.1-36.10, 37.1-37.10_

- [x] 2. Implementar instalação de pacotes base
  - Criar função install_base() que instala todos os pacotes essenciais via apt
  - Implementar função check_package_available() para verificar disponibilidade no repositório
  - Implementar função install_packages_safe() que verifica disponibilidade antes de instalar
  - Implementar verificação individual de cada pacote antes da instalação
  - Adicionar validação pós-instalação de pacotes críticos
  - _Requirements: 33.1-33.20, 37.1-37.10_

- [x] 3. Implementar instalação e configuração de Python
  - Criar função install_python() com verificação de estado
  - Instalar python3, python3-pip, python3-venv, python3-dev
  - Configurar aliases python=python3 e pip=pip3
  - Adicionar suporte para argumento -python e --skip-python
  - _Requirements: 1.1-1.5_

- [x] 4. Implementar instalação e configuração de Kotlin
  - Criar função install_kotlin() que usa SDKMAN
  - Verificar e instalar SDKMAN se necessário
  - Instalar Kotlin via sdk install kotlin
  - Validar instalação com kotlin -version
  - Adicionar suporte para argumento -kotlin e --skip-kotlin
  - _Requirements: 2.1-2.4_

- [x] 5. Implementar substituição de ls por eza
  - Verificar se eza está instalado (já incluído nos pacotes base)
  - Adicionar aliases específicos no .bashrc: ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"
  - Adicionar aliases específicos no .zshrc: ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"
  - Adicionar alias lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons" em ambos
  - Implementar verificação para evitar duplicação de aliases
  - _Requirements: 3.1-3.5_

- [x] 6. Configurar Zsh como shell padrão
  - Verificar se Zsh está instalado (já incluído nos pacotes base)
  - Alterar shell padrão para Zsh usando chsh para cada usuário
  - Instalar Oh-My-Zsh para cada usuário
  - Configurar tema frisk no .zshrc
  - Configurar lista completa de plugins no .zshrc
  - Instalar dependências necessárias para plugins via apt
  - _Requirements: 4.1-4.7_

- [x] 7. Configurar Micro Editor como editor padrão
  - Verificar se micro está instalado (já incluído nos pacotes base)
  - Configurar EDITOR=micro no .bashrc
  - Configurar VISUAL=micro no .bashrc
  - Configurar EDITOR=micro no .zshrc
  - Configurar VISUAL=micro no .zshrc
  - _Requirements: 5.1-5.5_

- [x] 8. Implementar instalação de emuladores de terminal
  - Instalar Terminator via apt quando argumento -desktop é fornecido
  - Instalar Alacritty via apt quando argumento -desktop é fornecido
  - Criar arquivo de configuração padrão para Terminator em ~/.config/terminator/config
  - Criar arquivo de configuração padrão para Alacritty em ~/.config/alacritty/alacritty.yml
  - Configurar Nerd Fonts nas configurações dos emuladores
  - _Requirements: 6.1-6.5_

- [x] 9. Implementar instalação de fontes
  - Clonar repositório de Powerline Fonts quando -desktop é fornecido
  - Executar script de instalação de Powerline Fonts
  - Clonar repositório de Nerd Fonts quando -desktop é fornecido
  - Instalar fontes selecionadas (FiraCode, JetBrainsMono, Hack)
  - Atualizar cache de fontes com fc-cache -fv
  - _Requirements: 7.1-7.5_

- [x] 10. Melhorar gerenciamento de usuários
  - Implementar criação de usuários via argumento -u=user1,user2
  - Adicionar prompt de senha para novos usuários
  - Adicionar usuários ao grupo sudo
  - Criar diretório home para novos usuários
  - Aplicar todas as configurações de ambiente para cada usuário
  - Garantir que root e usuário atual sempre recebem configurações
  - _Requirements: 8.1-8.5, 16.1-16.7, 17.1-17.5_

- [x] 11. Atualizar instalação de Docker
  - Instalar docker.io via apt
  - Instalar docker-compose-v2 via apt
  - Criar grupo docker se não existir
  - Adicionar usuários ao grupo docker
  - Habilitar serviço Docker no boot
  - Validar instalação com docker --version e docker compose version
  - Criar alias docker-compose para docker compose
  - _Requirements: 9.1-9.8_

- [x] 12. Configurar Oh-My-Bash
  - Instalar Oh-My-Bash para cada usuário
  - Configurar tema apropriado no .bashrc
  - Habilitar plugins úteis no .bashrc
  - Preservar aliases e configurações personalizadas existentes
  - Configurar histórico de comandos com tamanho aumentado
  - _Requirements: 10.1-10.5_


- [x] 13. Atualizar README.md principal
  - Criar seção de introdução explicando o propósito do projeto
  - Criar seção de pré-requisitos listando dependências
  - Criar tabela de referência rápida de todos os argumentos
  - Criar seção descrevendo cada linguagem de programação suportada
  - Criar seção descrevendo ferramentas de terminal (eza, micro, oh-my-bash, oh-my-zsh)
  - Criar seção descrevendo emuladores de terminal e configurações
  - Criar seção de troubleshooting com problemas comuns
  - Criar pelo menos 5 exemplos práticos de uso
  - Criar seção explicando estrutura de diretórios do projeto
  - Adicionar seção dedicada para cada ambiente (Desktop, Raspberry Pi, Odroid, OCI, GitHub, Killercoda)
  - Adicionar tabela comparativa de componentes por ambiente
  - Adicionar seção comparando Shell Scripts vs Ansible
  - _Requirements: 11.1-11.10, 26.1-26.10_

- [x] 14. Implementar detecção de distribuição Linux
  - Detectar distribuição usando /etc/os-release
  - Verificar se é baseada em Debian/Ubuntu
  - Exibir mensagem de erro clara se não for suportada
  - Adaptar comandos conforme distribuição detectada
  - _Requirements: 14.1-14.5_

- [x] 15. Atualizar scripts específicos para Raspberry Pi
  - Atualizar rasp/rasp4-prepare.sh baseado no script principal
  - Implementar detecção de arquitetura ARM
  - Aplicar otimizações específicas para Raspberry Pi
  - Instalar todos os componentes exceto desktop
  - Adicionar documentação específica no README.md
  - _Requirements: 20.1-20.5_

- [x] 16. Atualizar scripts específicos para Odroid
  - Atualizar odroid/odroid-prepare.sh baseado no script principal
  - Implementar detecção de arquitetura ARM
  - Aplicar configurações específicas para Odroid
  - Instalar todos os componentes exceto desktop
  - Adicionar documentação específica no README.md
  - _Requirements: 21.1-21.5_

- [x] 17. Atualizar scripts específicos para Oracle Cloud (OCI)
  - Atualizar cloud/oci-ubuntu.sh baseado no script principal
  - Configurar regras de firewall (iptables) para permitir tráfego web
  - Aplicar configurações específicas para ambiente cloud OCI
  - Instalar todos os componentes exceto desktop
  - Adicionar documentação específica no README.md incluindo configuração de rede
  - _Requirements: 22.1-22.5_


  - Instalar todos os componentes exceto desktop
  - Adicionar documentação específica no README.md incluindo security groups
  - _Requirements: 23.1-23.5_

- [x] 19. Atualizar scripts específicos para GitHub Codespaces
  - Atualizar cloud/github-workspace.sh baseado no script principal
  - Preservar configurações existentes do Codespaces
  - Configurar Oh-My-Bash e Oh-My-Zsh
  - Instalar todos os componentes exceto desktop
  - Adicionar documentação específica no README.md
  - _Requirements: 24.1-24.5_

- [x] 20. Atualizar scripts específicos para Killercoda
  - Atualizar cloud/killercoda.sh baseado no script principal
  - Garantir que seja executável via curl direto da URL
  - Configurar ambiente para uso imediato após instalação
  - Instalar todos os componentes exceto desktop
  - Adicionar documentação específica no README.md com comando curl completo
  - _Requirements: 25.1-25.5_

- [x] 21. Criar estrutura Ansible
  - Criar diretório ansible/ com estrutura organizada
  - Criar playbook principal ansible/site.yml
  - Criar arquivo ansible/inventory com exemplos de hosts
  - Criar arquivo ansible/group_vars/all.yml com variáveis configuráveis
  - Criar estrutura de diretórios para roles
  - _Requirements: 29.1-29.10_

- [x] 22. Implementar Ansible role: base
  - Criar role ansible/roles/base/
  - Implementar configuração de timezone (America/Sao_Paulo)
  - Implementar instalação de pacotes base via apt
  - Implementar atualização do sistema
  - Criar defaults e handlers apropriados
  - _Requirements: 29.1-29.10_

- [x] 23. Implementar Ansible role: docker
  - Criar role ansible/roles/docker/
  - Implementar instalação de docker.io e docker-compose-v2
  - Implementar criação de grupo docker
  - Implementar adição de usuários ao grupo
  - Implementar habilitação do serviço Docker
  - _Requirements: 29.1-29.10_

- [x] 24. Implementar Ansible role: golang
  - Criar role ansible/roles/golang/
  - Implementar download da versão mais recente do Go
  - Implementar extração para /usr/local
  - Implementar configuração de PATH
  - Implementar validação da instalação
  - _Requirements: 29.1-29.10_

- [x] 25. Implementar Ansible role: python
  - Criar role ansible/roles/python/
  - Implementar instalação de python3, python3-pip, python3-venv
  - Implementar configuração de aliases
  - Implementar validação da instalação
  - _Requirements: 29.1-29.10_

- [x] 26. Implementar Ansible role: kotlin
  - Criar role ansible/roles/kotlin/
  - Implementar instalação de SDKMAN
  - Implementar instalação de Kotlin via SDKMAN
  - Implementar validação da instalação
  - _Requirements: 29.1-29.10_

- [x] 27. Implementar Ansible role: dotnet
  - Criar role ansible/roles/dotnet/
  - Implementar adição de repositório Microsoft
  - Implementar instalação de dotnet-sdk-8.0
  - Implementar validação da instalação
  - _Requirements: 29.1-29.10_

- [x] 28. Implementar Ansible role: terminal-tools
  - Criar role ansible/roles/terminal-tools/
  - Implementar instalação de eza, micro, vim
  - Implementar configuração de vim com awesome vimrc
  - Implementar validação das instalações
  - _Requirements: 29.1-29.10_

- [x] 29. Implementar Ansible role: shell-config
  - Criar role ansible/roles/shell-config/
  - Implementar instalação de Oh-My-Zsh e Oh-My-Bash
  - Implementar configuração de temas e plugins
  - Implementar adição de aliases usando templates Jinja2
  - Implementar configuração de variáveis de ambiente
  - Implementar alteração de shell padrão para zsh
  - _Requirements: 29.1-29.10_

- [x] 30. Implementar Ansible role: desktop
  - Criar role ansible/roles/desktop/
  - Implementar instalação de fontes (Powerline, Nerd Fonts)
  - Implementar instalação de emuladores de terminal
  - Implementar instalação de VSCode e Chrome
  - Implementar configuração de emuladores usando templates
  - _Requirements: 29.1-29.10_

- [x] 31. Implementar Ansible role: users
  - Criar role ansible/roles/users/
  - Implementar criação de usuários
  - Implementar adição ao grupo sudo
  - Implementar adição ao grupo docker
  - Implementar aplicação de configurações de shell
  - _Requirements: 29.1-29.10_

- [x] 32. Criar playbooks específicos por ambiente
  - Criar ansible/playbooks/desktop.yml para ambientes desktop
  - Criar ansible/playbooks/server.yml para servidores
  - Criar ansible/playbooks/raspberry.yml para Raspberry Pi
  - Criar ansible/playbooks/cloud.yml para ambientes cloud
  - _Requirements: 29.1-29.10_

- [x] 33. Criar README.md do Ansible
  - Criar ansible/README.md com documentação completa
  - Adicionar seção de pré-requisitos (Ansible, Python)
  - Adicionar instruções passo-a-passo para SO recém-instalado
  - Adicionar explicação da estrutura de diretórios
  - Adicionar exemplos de execução para cada cenário
  - Adicionar seção sobre customização de variáveis
  - Adicionar exemplos de inventory
  - Adicionar seção de troubleshooting
  - Adicionar comandos de verificação (--check, --diff)
  - Adicionar seção sobre tags para execução seletiva
  - _Requirements: 31.1-31.10_

- [x] 34. Implementar esteira de testes
  - Criar Dockerfile para testes baseado em Ubuntu (tests/docker/Dockerfile.ubuntu)
  - Criar Dockerfile para testes baseado em Debian (tests/docker/Dockerfile.debian)
  - Criar script de validação (tests/scripts/validate.sh)
  - Implementar validação de comandos instalados
  - Implementar validação de usuários criados
  - Implementar validação de configurações (aliases, variáveis de ambiente)
  - Criar script de CI/CD para executar testes em múltiplas distribuições
  - Adicionar documentação sobre como executar testes localmente
  - _Requirements: 19.1-19.10_

- [x] 35. Criar documentação adicional
  - Criar CONTRIBUTING.md com guia de contribuição
  - Criar CHANGELOG.md para rastrear mudanças
  - Adicionar badges de status no README.md
  - Criar diagramas de fluxo de execução
  - _Requirements: 26.9_
