# Registro de Alterações

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/spec/v2.0.0.html).

## [Não Lançado]

### Adicionado
- **Suporte ao Pop!_OS**: Compatibilidade completa com Pop!_OS 22.04 incluindo workarounds específicos para EZA, Docker e VSCode
- **Flags de Controle Desktop**: `--desktop` para forçar instalação e `--skip-desktop` para pular instalação
- **Guia de Início Rápido**: Guia amigável para iniciantes do git clone até execução no README
- **Cenários de Uso**: 5 exemplos práticos mostrando casos de uso comuns
- **Ferramentas CLI Modernas**: bat, httpie, yq, glances, neofetch, dust, gh, tig, screen, k9s, tldr
- **Ferramentas de Build**: cmake, build-essential
- **Clientes de Banco de Dados**: postgresql-client, redis-tools
- **Ferramentas de Segurança**: openssl, openssh-server, netcat-openbsd
- **Ferramentas Desktop**: Flameshot (capturas de tela), DBeaver CE (GUI de banco de dados)
- **Script de Ferramentas Opcionais** (`add-opt.sh`): Instala Node.js, Rust, Ruby, Terraform, kubectl, Helm, lazygit, lazydocker, Starship, zoxide, Neovim, Postman, Insomnia, Obsidian, ferramentas MongoDB, Poetry, pipx
- Suporte ao Xubuntu 24.04 com testes de detecção de ambiente desktop XFCE
- Suporte ao Linux Mint 22 com testes completos de compatibilidade
- Container de teste e validação para Pop!_OS 22.04
- Testes abrangentes de distribuições (Ubuntu, Debian, Xubuntu, Mint, Pop!_OS)
- Script `test-derivatives.sh` para testes rápidos de Xubuntu/Mint
- Guia de testes de distribuição (tests/DISTRIBUTIONS.md)
- Testes automatizados CI/CD para todas as distribuições suportadas

### Alterado
- **Detecção de Desktop**: Agora claramente documentada com detecção automática e opções de override manual
- **Estrutura da Documentação**: README reorganizado com Início Rápido no topo e seção dedicada de Componentes Desktop
- **Simplificação da Documentação**: Todos os docs reduzidos em 60-90% para clareza (amigável para estudantes)
- **Tabela de Distribuições**: Atualizada para incluir Pop!_OS com indicador de suporte desktop
- **Instalação do VSCode**: Usa método de repositório apt no Pop!_OS ao invés de snap
- **Instalação do Docker**: Usa repositórios do Pop!_OS com workarounds específicos
- **Instalação do EZA**: Fallback para cargo ou exa no Pop!_OS quando repositório falha
- **Binários do Cargo**: Agora instalados em `/usr/local/bin` para acesso de todos os usuários
- **Dependências Snap/Cargo**: Auto-instaladas quando necessário
- Atualizadas todas as referências do Debian da versão 11/12 para versão 13
- Documentação de testes aprimorada com notas específicas de distribuição
- Matriz de suporte de distribuições melhorada no README
- Pacotes base expandidos com ferramentas CLI modernas
- Componentes desktop agora incluem ferramentas de produtividade
- **Oh-My-Bash** e **Oh-My-Zsh** agora são instalações obrigatórias para todos os usuários
- Testes de validação agora verificam instalação do Oh-My-Bash

### Removido
- **Suporte ao Amazon Linux**: Removido suporte AWS EC2/Amazon Linux para focar em distribuições baseadas em Debian
- Removido script `cloud/aws-ec2-prepare.sh`
- Removido Amazon Linux da documentação e tabelas de comparação

## [2.0.0] - 2024-11-15

### Adicionado
- Refatoração completa do script principal com arquitetura moderna
- Sistema de logging colorido em português com timestamps e símbolos
- Suporte completo a idempotência (seguro executar múltiplas vezes)
- Argumentos `--skip-*` para instalação seletiva de componentes
- Flag `--desktop` para componentes desktop opcionais
- Sistema de ajuda abrangente com exemplos detalhados
- Suporte para múltiplos usuários via `-u=user1,user2`
- Configuração automática de fuso horário (America/Sao_Paulo)
- Implementação completa do Ansible com roles
- Scripts específicos por ambiente (Raspberry Pi, Odroid, OCI, GitHub, Killercoda)
- Infraestrutura de testes automatizados com Docker
- Scripts de validação para verificação de instalação
- Documentação abrangente (README.md, ansible/README.md, CONTRIBUTING.md)

### Alterado
- **BREAKING**: Comportamento padrão agora instala TODOS os componentes (exceto desktop)
- **BREAKING**: Removidas flags positivas de instalação (-docker, -go, etc.)
- **BREAKING**: Componentes desktop agora requerem flag explícita `--desktop`
- Tratamento de erros e logging melhorados
- Melhor gerenciamento de usuários com atribuição ao grupo sudo
- Configuração de shell aprimorada com mais plugins
- Atualizado para .NET SDK 8.0
- Aliases modernizados usando eza ao invés de exa

### Corrigido
- Problemas de idempotência com múltiplas execuções do script
- Criação de usuários e atribuição de grupos
- Associação ao grupo docker
- Conflitos de configuração de shell
- Instalação de fontes em várias distribuições

### Segurança
- Todos os downloads usam HTTPS
- Tratamento adequado de permissões
- Configuração segura de sudo

## [1.0.0] - 2023-XX-XX

### Adicionado
- Lançamento inicial
- Scripts básicos de instalação
- Suporte para Ubuntu e Debian
- Instalação do Docker
- Instalação do Golang
- Instalação do Python
- Instalação do JVM via SDKMAN
- Instalação do .NET
- Configuração do Oh-My-Zsh
- Configuração do Vim
- Componentes desktop (VSCode, Chrome, fontes)

### Problemas Conhecidos
- Idempotência limitada
- Configuração manual de usuário necessária
- Sem testes automatizados

---

## Histórico de Versões

- **2.0.0** - Refatoração maior com arquitetura moderna e automação completa
- **1.0.0** - Lançamento inicial com funcionalidade básica

## Guia de Atualização

### De 1.x para 2.x

**Mudanças que Quebram Compatibilidade:**
1. Argumentos de linha de comando mudaram:
   - Antigo: `./prepare.sh -docker -go -python`
   - Novo: `./prepare.sh` (instala tudo por padrão)
   - Novo: `./prepare.sh --skip-docker --skip-go` (para pular componentes)

2. Componentes desktop:
   - Antigo: Incluídos por padrão com `-all`
   - Novo: Requer flag explícita `--desktop`

3. Configuração de usuário:
   - Antigo: Configuração manual
   - Novo: Automática com `-u=nomedousuario`

**Passos de Migração:**
1. Revise seu uso atual
2. Atualize argumentos de linha de comando
3. Teste em uma VM ou container primeiro
4. Execute o novo script com as flags apropriadas

**Benefícios da Atualização:**
- Idempotência completa
- Melhor tratamento de erros
- Logging abrangente
- Suporte ao Ansible
- Testes automatizados
- Melhor documentação
