# Documento de Requisitos

## Introdução

Este documento especifica os requisitos para evolução do script `prepare.sh`, transformando-o em uma solução completa e robusta para preparar qualquer distribuição Linux recém-instalada como um ambiente de desenvolvimento profissional. O script deve suportar múltiplas linguagens de programação (Python, Golang, Kotlin, C#), containerização (Docker/Docker Compose), terminais instrumentados (oh-my-bash, oh-my-zsh), emuladores de terminal modernos (Terminator, Alacritty), fontes otimizadas (Powerline, Nerd Fonts), gerenciamento de usuários, substituição de ferramentas padrão (eza no lugar de ls), configuração de shell padrão (zsh) e editor de terminal (micro). Toda a funcionalidade deve ser extensivamente documentada no README.md do projeto.

## Glossário

- **Sistema**: O script `prepare.sh` e seus componentes relacionados
- **Usuário-Alvo**: Usuário do sistema operacional Linux para o qual o ambiente será configurado
- **Ambiente-Base**: Instalação mínima do sistema operacional Linux antes da execução do script
- **Shell-Padrão**: Interpretador de comandos configurado como padrão para login do usuário
- **Terminal-Emulador**: Aplicação gráfica que fornece interface para o shell
- **Micro-Editor**: Editor de texto de terminal moderno e intuitivo
- **Eza**: Substituto moderno do comando `ls` com melhor visualização
- **Oh-My-Bash**: Framework de gerenciamento de configuração para Bash
- **Oh-My-Zsh**: Framework de gerenciamento de configuração para Zsh
- **Powerline-Fonts**: Conjunto de fontes com símbolos especiais para status de terminal
- **Nerd-Fonts**: Fontes com ícones e símbolos para desenvolvedores
- **SDKMAN**: Gerenciador de versões para SDKs da JVM (Java, Kotlin, etc.)
- **Docker-Compose**: Ferramenta para definir e executar aplicações Docker multi-container
- **Kotlin-Runtime**: Ambiente de execução para linguagem Kotlin

## Requisitos

### Requisito 1

**User Story:** Como administrador de sistemas, eu quero que o script instale e configure Python como ambiente de desenvolvimento, para que os Usuários-Alvo possam desenvolver aplicações Python imediatamente.

#### Critérios de Aceitação

1. WHEN o argumento `-python` é fornecido, THE Sistema SHALL instalar a versão mais recente estável do Python 3
2. WHEN o argumento `-python` é fornecido, THE Sistema SHALL instalar pip (gerenciador de pacotes Python)
3. WHEN o argumento `-python` é fornecido, THE Sistema SHALL instalar virtualenv para isolamento de ambientes Python
4. WHEN o argumento `-python` é fornecido, THE Sistema SHALL configurar aliases úteis para Python no shell do Usuário-Alvo
5. WHEN a instalação do Python é concluída, THE Sistema SHALL validar a instalação executando `python3 --version`

### Requisito 2

**User Story:** Como administrador de sistemas, eu quero que o script instale e configure Kotlin como ambiente de desenvolvimento, para que os Usuários-Alvo possam desenvolver aplicações Kotlin imediatamente.

#### Critérios de Aceitação

1. WHEN o argumento `-kotlin` é fornecido, THE Sistema SHALL instalar Kotlin através do SDKMAN
2. WHEN o argumento `-kotlin` é fornecido AND SDKMAN não está instalado, THE Sistema SHALL instalar SDKMAN primeiro
3. WHEN a instalação do Kotlin é concluída, THE Sistema SHALL validar a instalação executando `kotlin -version`
4. WHEN o argumento `-kotlin` é fornecido, THE Sistema SHALL configurar variáveis de ambiente necessárias para Kotlin

### Requisito 3

**User Story:** Como administrador de sistemas, eu quero que o script substitua o comando `ls` padrão pelo `eza`, para que os Usuários-Alvo tenham uma visualização melhorada de diretórios.

#### Critérios de Aceitação

1. THE Sistema SHALL instalar o comando `eza` durante a instalação base
2. WHEN `eza` é instalado, THE Sistema SHALL criar alias `ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"` no arquivo `.bashrc` do Usuário-Alvo
3. WHEN `eza` é instalado, THE Sistema SHALL criar alias `ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"` no arquivo `.zshrc` do Usuário-Alvo
4. WHEN `eza` é instalado, THE Sistema SHALL criar alias `lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"` no arquivo `.bashrc` do Usuário-Alvo
5. WHEN `eza` é instalado, THE Sistema SHALL criar alias `lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"` no arquivo `.zshrc` do Usuário-Alvo

### Requisito 4

**User Story:** Como administrador de sistemas, eu quero que o script configure Zsh como Shell-Padrão para todos os Usuários-Alvo, para que eles tenham uma experiência de terminal moderna e produtiva.

#### Critérios de Aceitação

1. THE Sistema SHALL instalar Zsh durante a instalação base
2. WHEN Zsh é instalado, THE Sistema SHALL alterar o Shell-Padrão de cada Usuário-Alvo para Zsh usando o comando `chsh`
3. WHEN Zsh é configurado como Shell-Padrão, THE Sistema SHALL instalar Oh-My-Zsh para cada Usuário-Alvo
4. WHEN Oh-My-Zsh é instalado, THE Sistema SHALL configurar tema `frisk` no arquivo `.zshrc`
5. WHEN Oh-My-Zsh é instalado, THE Sistema SHALL habilitar os seguintes plugins no arquivo `.zshrc`: git, colorize, command-not-found, compleat, composer, cp, debian, dircycle, docker, docker-compose, dotnet, eza, fzf, gh, golang, grc, nats, pip, postgres, procs, python, qrcode, redis-cli, repo, rust, sdk, ssh, sudo, systemd, themes, ubuntu, vscode, zsh-interactive-cd
6. WHEN plugins Oh-My-Zsh são configurados, THE Sistema SHALL instalar dependências necessárias para cada plugin via apt
7. WHEN plugins Oh-My-Zsh são configurados, THE Sistema SHALL verificar disponibilidade de cada plugin antes de habilitá-lo

### Requisito 5

**User Story:** Como administrador de sistemas, eu quero que o script instale e configure o Micro-Editor como editor padrão, para que os Usuários-Alvo tenham um editor de terminal intuitivo e moderno.

#### Critérios de Aceitação

1. THE Sistema SHALL instalar o Micro-Editor durante a instalação base
2. WHEN Micro-Editor é instalado, THE Sistema SHALL configurar a variável de ambiente `EDITOR` para apontar para `micro` no arquivo `.bashrc` do Usuário-Alvo
3. WHEN Micro-Editor é instalado, THE Sistema SHALL configurar a variável de ambiente `EDITOR` para apontar para `micro` no arquivo `.zshrc` do Usuário-Alvo
4. WHEN Micro-Editor é instalado, THE Sistema SHALL configurar a variável de ambiente `VISUAL` para apontar para `micro` no arquivo `.bashrc` do Usuário-Alvo
5. WHEN Micro-Editor é instalado, THE Sistema SHALL configurar a variável de ambiente `VISUAL` para apontar para `micro` no arquivo `.zshrc` do Usuário-Alvo

### Requisito 6

**User Story:** Como administrador de sistemas, eu quero que o script instale emuladores de terminal modernos automaticamente quando um ambiente desktop for detectado, para que os Usuários-Alvo tenham opções de Terminal-Emulador poderosos e configuráveis.

#### Critérios de Aceitação

1. WHEN ambiente desktop é detectado, THE Sistema SHALL instalar Terminator
2. WHEN ambiente desktop é detectado, THE Sistema SHALL instalar Alacritty
3. WHEN Terminator é instalado, THE Sistema SHALL criar arquivo de configuração padrão em `~/.config/terminator/config` para cada Usuário-Alvo
4. WHEN Alacritty é instalado, THE Sistema SHALL criar arquivo de configuração padrão em `~/.config/alacritty/alacritty.yml` para cada Usuário-Alvo
5. WHEN emuladores de terminal são instalados, THE Sistema SHALL configurar fontes Nerd Fonts como padrão nas configurações
6. WHEN ambiente desktop NÃO é detectado, THE Sistema SHALL pular instalação de emuladores de terminal

### Requisito 7

**User Story:** Como administrador de sistemas, eu quero que o script instale e configure fontes Powerline e Nerd Fonts automaticamente quando um ambiente desktop for detectado, para que os terminais exibam símbolos e ícones corretamente.

#### Critérios de Aceitação

1. WHEN ambiente desktop é detectado, THE Sistema SHALL clonar o repositório de Powerline-Fonts
2. WHEN ambiente desktop é detectado, THE Sistema SHALL executar o script de instalação de Powerline-Fonts para cada Usuário-Alvo
3. WHEN ambiente desktop é detectado, THE Sistema SHALL clonar o repositório de Nerd-Fonts
4. WHEN ambiente desktop é detectado, THE Sistema SHALL instalar fontes selecionadas de Nerd-Fonts (FiraCode, JetBrainsMono, Hack) para cada Usuário-Alvo
5. WHEN fontes são instaladas, THE Sistema SHALL atualizar o cache de fontes do sistema executando `fc-cache -fv`
6. WHEN ambiente desktop NÃO é detectado, THE Sistema SHALL pular instalação de fontes

### Requisito 8

**User Story:** Como administrador de sistemas, eu quero que o script crie e configure novos usuários no sistema, para que múltiplos desenvolvedores possam ter ambientes isolados e configurados.

#### Critérios de Aceitação

1. WHEN o argumento `-u=usuario1,usuario2` é fornecido, THE Sistema SHALL criar cada usuário que não existe no sistema
2. WHEN um novo usuário é criado, THE Sistema SHALL solicitar senha para o usuário de forma interativa
3. WHEN um novo usuário é criado, THE Sistema SHALL adicionar o usuário ao grupo `sudo`
4. WHEN um novo usuário é criado, THE Sistema SHALL criar diretório home para o usuário
5. WHEN um novo usuário é criado, THE Sistema SHALL aplicar todas as configurações de ambiente para esse usuário

### Requisito 9

**User Story:** Como administrador de sistemas, eu quero que o script instale Docker e Docker Compose v2, para que os Usuários-Alvo possam trabalhar com containers facilmente.

#### Critérios de Aceitação

1. WHEN o argumento `-docker` é fornecido, THE Sistema SHALL instalar pacote `docker.io` via apt
2. WHEN o argumento `-docker` é fornecido, THE Sistema SHALL instalar pacote `docker-compose-v2` via apt
3. WHEN Docker é instalado, THE Sistema SHALL criar grupo `docker` se não existir
4. WHEN Docker é instalado, THE Sistema SHALL adicionar Usuários-Alvo ao grupo `docker`
5. WHEN Docker é instalado, THE Sistema SHALL validar instalação executando `docker --version`
6. WHEN Docker Compose é instalado, THE Sistema SHALL validar instalação executando `docker compose version`
7. WHEN Docker Compose é instalado, THE Sistema SHALL criar alias `docker-compose` apontando para `docker compose` para compatibilidade retroativa
8. WHEN Docker é instalado, THE Sistema SHALL habilitar serviço Docker para iniciar automaticamente no boot

### Requisito 10

**User Story:** Como administrador de sistemas, eu quero que o script configure Oh-My-Bash para usuários que preferem Bash, para que eles tenham uma experiência melhorada mesmo sem usar Zsh.

#### Critérios de Aceitação

1. THE Sistema SHALL instalar Oh-My-Bash para cada Usuário-Alvo
2. WHEN Oh-My-Bash é instalado, THE Sistema SHALL configurar um tema apropriado no arquivo `.bashrc`
3. WHEN Oh-My-Bash é instalado, THE Sistema SHALL habilitar plugins úteis no arquivo `.bashrc`
4. WHEN Oh-My-Bash é instalado, THE Sistema SHALL preservar aliases e configurações personalizadas existentes
5. WHEN Oh-My-Bash é instalado, THE Sistema SHALL configurar histórico de comandos com tamanho aumentado

### Requisito 11

**User Story:** Como desenvolvedor, eu quero que o README.md contenha documentação completa e detalhada, para que eu possa entender todas as funcionalidades e opções do script.

#### Critérios de Aceitação

1. THE Sistema SHALL ter um README.md com seção de introdução explicando o propósito do script
2. THE Sistema SHALL ter um README.md com seção de pré-requisitos listando dependências do sistema
3. THE Sistema SHALL ter um README.md com seção de instalação com exemplos de uso para cada argumento
4. THE Sistema SHALL ter um README.md com seção descrevendo cada linguagem de programação suportada
5. THE Sistema SHALL ter um README.md com seção descrevendo ferramentas de terminal instaladas (eza, micro, oh-my-bash, oh-my-zsh)
6. THE Sistema SHALL ter um README.md com seção descrevendo emuladores de terminal e suas configurações
7. THE Sistema SHALL ter um README.md com seção de troubleshooting com problemas comuns e soluções
8. THE Sistema SHALL ter um README.md com seção de exemplos práticos de uso para diferentes cenários
9. THE Sistema SHALL ter um README.md com tabela de referência rápida de todos os argumentos disponíveis
10. THE Sistema SHALL ter um README.md com seção explicando a estrutura de diretórios do projeto

### Requisito 12

**User Story:** Como administrador de sistemas, eu quero que o script seja idempotente, para que eu possa executá-lo múltiplas vezes sem causar erros ou duplicações.

#### Critérios de Aceitação

1. WHEN o script é executado, THE Sistema SHALL verificar se cada componente já está instalado antes de tentar instalá-lo
2. WHEN um componente já está instalado, THE Sistema SHALL registrar mensagem informativa e pular a instalação
3. WHEN configurações já existem, THE Sistema SHALL preservar configurações personalizadas do usuário
4. WHEN aliases já existem nos arquivos de configuração, THE Sistema SHALL evitar duplicação de aliases
5. WHEN o script é executado múltiplas vezes, THE Sistema SHALL completar sem erros

### Requisito 13

**User Story:** Como administrador de sistemas, eu quero que o script tenha logging detalhado e colorido, para que eu possa acompanhar o progresso e identificar problemas facilmente.

#### Critérios de Aceitação

1. THE Sistema SHALL registrar cada operação principal com timestamp
2. THE Sistema SHALL usar cores diferentes para tipos de mensagens (info em verde, erro em vermelho, aviso em amarelo)
3. WHEN ocorre um erro, THE Sistema SHALL registrar mensagem de erro detalhada com contexto
4. WHEN uma operação é bem-sucedida, THE Sistema SHALL registrar mensagem de sucesso
5. THE Sistema SHALL registrar o tempo total de execução ao final do script

### Requisito 14

**User Story:** Como administrador de sistemas, eu quero que o script funcione em qualquer distribuição derivada de Debian, para que eu possa usar em Ubuntu, Linux Mint, Xubuntu, Debian e outras variantes.

#### Critérios de Aceitação

1. WHEN o script é executado, THE Sistema SHALL detectar a distribuição Linux usando `/etc/os-release`
2. WHEN a distribuição é baseada em Debian ou derivadas (Ubuntu, Mint, Xubuntu, etc), THE Sistema SHALL usar comandos `apt` para instalação
3. WHEN a distribuição não é baseada em Debian, THE Sistema SHALL exibir mensagem de erro informando que apenas distribuições Debian são suportadas
4. WHEN comandos `apt` são executados, THE Sistema SHALL usar flags apropriadas (-y, --no-install-recommends quando aplicável)
5. THE Sistema SHALL verificar disponibilidade do comando `apt` antes de prosseguir com instalações

### Requisito 15

**User Story:** Como administrador de sistemas, eu quero poder pular a instalação de componentes específicos usando argumentos `--skip-*`, para que eu possa personalizar a instalação para servidores ou ambientes específicos.

#### Critérios de Aceitação

1. WHEN nenhum argumento é fornecido, THE Sistema SHALL instalar todos os componentes de desenvolvimento por padrão
2. WHEN nenhum argumento é fornecido, THE Sistema SHALL detectar automaticamente se há ambiente desktop e instalar componentes desktop apenas se detectado
3. WHEN o argumento `--skip-docker` é fornecido, THE Sistema SHALL pular a instalação do Docker e Docker Compose
4. WHEN o argumento `--skip-python` é fornecido, THE Sistema SHALL pular a instalação do Python e suas ferramentas
5. WHEN o argumento `--skip-go` é fornecido, THE Sistema SHALL pular a instalação do Golang
6. WHEN o argumento `--skip-jvm` é fornecido, THE Sistema SHALL pular a instalação do SDKMAN e JVM
7. WHEN o argumento `--skip-dotnet` é fornecido, THE Sistema SHALL pular a instalação do .NET SDK
8. WHEN o argumento `--skip-kotlin` é fornecido, THE Sistema SHALL pular a instalação do Kotlin
9. WHEN o argumento `-u=user1,user2` é fornecido, THE Sistema SHALL criar e configurar os usuários especificados além de root e usuário atual

### Requisito 16

**User Story:** Como administrador de sistemas, eu quero que todas as configurações de terminal sejam aplicadas ao usuário root e demais usuários do sistema, para que todos tenham a mesma experiência otimizada.

#### Critérios de Aceitação

1. THE Sistema SHALL aplicar configurações de Oh-My-Bash para o usuário root
2. THE Sistema SHALL aplicar configurações de Oh-My-Zsh para o usuário root
3. THE Sistema SHALL configurar aliases (eza, micro) para o usuário root
4. THE Sistema SHALL configurar variáveis de ambiente (EDITOR, VISUAL) para o usuário root
5. THE Sistema SHALL alterar o Shell-Padrão do usuário root para Zsh
6. WHEN múltiplos usuários são especificados via `-u=`, THE Sistema SHALL aplicar todas as configurações para cada usuário listado
7. THE Sistema SHALL aplicar configurações para o usuário que executou o script (via sudo)

### Requisito 17

**User Story:** Como administrador de sistemas, eu quero que usuários criados pelo script sejam automaticamente adicionados ao arquivo sudoers, para que eles possam executar comandos administrativos.

#### Critérios de Aceitação

1. WHEN um novo usuário é criado, THE Sistema SHALL adicionar o usuário ao grupo `sudo`
2. WHEN um novo usuário é criado, THE Sistema SHALL verificar se o usuário tem permissões sudo executando `sudo -l -U usuario`
3. WHEN um usuário já existe, THE Sistema SHALL verificar se ele está no grupo `sudo` e adicioná-lo se necessário
4. WHEN o grupo `sudo` não existe no sistema, THE Sistema SHALL criar o grupo antes de adicionar usuários
5. WHEN usuários são adicionados ao sudoers, THE Sistema SHALL registrar a operação no log

### Requisito 18

**User Story:** Como usuário do script, eu quero ter acesso a um help detalhado e completo, para que eu possa entender todas as opções disponíveis e como usá-las corretamente.

#### Critérios de Aceitação

1. WHEN o argumento `-h` ou `--help` é fornecido, THE Sistema SHALL exibir mensagem de ajuda completa
2. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL incluir descrição do propósito do script
3. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL listar todos os argumentos de skip (--skip-docker, --skip-go, --skip-jvm, --skip-dotnet, --skip-kotlin, --skip-python, --skip-desktop)
4. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL listar argumento --desktop para instalação de componentes desktop
5. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL listar argumento -u= para criação de usuários
6. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL incluir pelo menos 5 exemplos práticos de uso
7. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL explicar o comportamento padrão (instala todos os componentes de desenvolvimento, desktop é opt-in)
8. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL incluir seção sobre criação de usuários com argumento `-u=`
9. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL usar formatação clara com tabelas ou listas organizadas
10. WHEN a mensagem de ajuda é exibida, THE Sistema SHALL incluir informações sobre distribuições Linux suportadas

### Requisito 19

**User Story:** Como desenvolvedor do script, eu quero ter uma esteira de testes automatizados usando Docker, para que eu possa validar o funcionamento do script em diferentes distribuições Debian sem componentes desktop.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir um Dockerfile para testes baseado em Ubuntu
2. THE Sistema SHALL incluir um Dockerfile para testes baseado em Debian
3. THE Sistema SHALL incluir scripts de teste que validam instalação de cada componente (exceto desktop)
4. WHEN testes são executados, THE Sistema SHALL verificar se comandos instalados estão disponíveis (docker, go, dotnet, kotlin, python3, zsh, micro, eza)
5. WHEN testes são executados, THE Sistema SHALL verificar se usuários criados existem e têm permissões sudo
6. WHEN testes são executados, THE Sistema SHALL verificar se Oh-My-Zsh e Oh-My-Bash foram instalados corretamente
7. WHEN testes são executados, THE Sistema SHALL verificar se aliases foram configurados nos arquivos .bashrc e .zshrc
8. WHEN testes são executados, THE Sistema SHALL verificar se variáveis de ambiente (EDITOR, VISUAL) foram configuradas
9. THE Sistema SHALL incluir script de CI/CD que executa testes em múltiplas distribuições
10. THE Sistema SHALL incluir documentação sobre como executar os testes localmente

### Requisito 20

**User Story:** Como administrador de sistemas, eu quero scripts específicos para Raspberry Pi com Ubuntu, para que eu possa preparar ambientes de desenvolvimento em dispositivos ARM.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir script `rasp/rasp4-prepare.sh` baseado no script principal
2. WHEN o script Raspberry é executado, THE Sistema SHALL instalar todos os componentes exceto desktop
3. WHEN o script Raspberry é executado, THE Sistema SHALL detectar arquitetura ARM e usar pacotes apropriados
4. WHEN o script Raspberry é executado, THE Sistema SHALL aplicar otimizações específicas para Raspberry Pi
5. THE Sistema SHALL documentar no README.md instruções específicas para Raspberry Pi

### Requisito 21

**User Story:** Como administrador de sistemas, eu quero scripts específicos para Odroid com Ubuntu, para que eu possa preparar ambientes de desenvolvimento em dispositivos Odroid.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir script `odroid/odroid-prepare.sh` baseado no script principal
2. WHEN o script Odroid é executado, THE Sistema SHALL instalar todos os componentes exceto desktop
3. WHEN o script Odroid é executado, THE Sistema SHALL detectar arquitetura ARM e usar pacotes apropriados
4. WHEN o script Odroid é executado, THE Sistema SHALL aplicar configurações específicas para Odroid
5. THE Sistema SHALL documentar no README.md instruções específicas para Odroid

### Requisito 22

**User Story:** Como administrador de sistemas, eu quero scripts específicos para Oracle Cloud Infrastructure (OCI) com Ubuntu, para que eu possa preparar VMs na nuvem OCI.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir script `cloud/oci-ubuntu.sh` baseado no script principal
2. WHEN o script OCI é executado, THE Sistema SHALL instalar todos os componentes exceto desktop
3. WHEN o script OCI é executado, THE Sistema SHALL configurar regras de firewall (iptables) para permitir tráfego web
4. WHEN o script OCI é executado, THE Sistema SHALL aplicar configurações específicas para ambiente cloud OCI
5. THE Sistema SHALL documentar no README.md instruções específicas para OCI incluindo configuração de rede

### Requisito 23

**User Story:** Como administrador de sistemas, eu quero scripts específicos para AWS EC2 com Amazon Linux, para que eu possa preparar instâncias EC2 na AWS.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir script `cloud/aws-ec2-prepare.sh` baseado no script principal
2. WHEN o script AWS é executado, THE Sistema SHALL usar gerenciador de pacotes `yum` ao invés de `apt`
3. WHEN o script AWS é executado, THE Sistema SHALL instalar todos os componentes exceto desktop
4. WHEN o script AWS é executado, THE Sistema SHALL configurar usuário padrão `ec2-user`
5. THE Sistema SHALL documentar no README.md instruções específicas para AWS EC2 incluindo configuração de security groups

### Requisito 24

**User Story:** Como desenvolvedor, eu quero scripts específicos para GitHub Codespaces, para que eu possa preparar ambientes de desenvolvimento na nuvem do GitHub.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir script `cloud/github-workspace.sh` baseado no script principal
2. WHEN o script GitHub Codespaces é executado, THE Sistema SHALL instalar todos os componentes exceto desktop
3. WHEN o script GitHub Codespaces é executado, THE Sistema SHALL configurar Oh-My-Bash e Oh-My-Zsh
4. WHEN o script GitHub Codespaces é executado, THE Sistema SHALL preservar configurações existentes do Codespaces
5. THE Sistema SHALL documentar no README.md instruções específicas para GitHub Codespaces

### Requisito 25

**User Story:** Como educador ou estudante, eu quero scripts específicos para Killercoda, para que eu possa preparar ambientes de aprendizado interativos.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir script `cloud/killercoda.sh` baseado no script principal
2. WHEN o script Killercoda é executado, THE Sistema SHALL instalar todos os componentes exceto desktop
3. WHEN o script Killercoda é executado, THE Sistema SHALL ser executável via curl direto da URL do repositório
4. WHEN o script Killercoda é executado, THE Sistema SHALL configurar ambiente para uso imediato após instalação
5. THE Sistema SHALL documentar no README.md instruções específicas para Killercoda com comando curl completo

### Requisito 26

**User Story:** Como usuário do projeto, eu quero um README.md abrangente que documente todos os cenários de uso, para que eu possa escolher e executar o script apropriado para minha situação.

#### Critérios de Aceitação

1. THE Sistema SHALL ter README.md com seção dedicada para cada tipo de ambiente (Desktop, Raspberry Pi, Odroid, OCI, AWS EC2, GitHub Codespaces, Killercoda)
2. WHEN README.md é lido, THE Sistema SHALL incluir tabela comparativa mostrando quais componentes são instalados em cada cenário
3. WHEN README.md é lido, THE Sistema SHALL incluir exemplos de comandos específicos para cada ambiente
4. WHEN README.md é lido, THE Sistema SHALL incluir seção de pré-requisitos específicos para cada ambiente
5. WHEN README.md é lido, THE Sistema SHALL incluir seção de troubleshooting com problemas comuns por ambiente
6. WHEN README.md é lido, THE Sistema SHALL incluir diagrama ou fluxograma mostrando qual script usar em cada situação
7. WHEN README.md é lido, THE Sistema SHALL incluir links para documentação oficial de cada plataforma (AWS, OCI, GitHub, Killercoda)
8. WHEN README.md é lido, THE Sistema SHALL incluir seção sobre a estrutura do projeto explicando organização de pastas (scripts, ansible, rasp, odroid, cloud)
9. WHEN README.md é lido, THE Sistema SHALL incluir badges de status de testes para cada ambiente
10. WHEN README.md é lido, THE Sistema SHALL incluir seção comparando abordagem Shell Scripts vs Ansible

### Requisito 27

**User Story:** Como administrador de sistemas, eu quero que todos os scripts sejam completamente idempotentes, para que eu possa executá-los múltiplas vezes sem causar erros, duplicações ou processos inacabados.

#### Critérios de Aceitação

1. WHEN qualquer script é executado, THE Sistema SHALL verificar estado atual antes de cada operação
2. WHEN um componente já está instalado, THE Sistema SHALL registrar mensagem informativa e pular instalação
3. WHEN uma configuração já existe, THE Sistema SHALL verificar se está correta e atualizar apenas se necessário
4. WHEN um alias já existe em arquivo de configuração, THE Sistema SHALL evitar duplicação
5. WHEN um usuário já existe, THE Sistema SHALL verificar configurações e aplicar apenas o que está faltando
6. WHEN o script é interrompido, THE Sistema SHALL permitir retomada sem deixar processos inacabados
7. WHEN o script é executado múltiplas vezes consecutivas, THE Sistema SHALL completar sem erros em todas as execuções
8. WHEN verificações de estado são feitas, THE Sistema SHALL usar comandos que retornam códigos de saída confiáveis

### Requisito 28

**User Story:** Como operador do script, eu quero logs claros e coloridos em inglês (EN-US), para que eu possa entender facilmente o que está sendo executado e identificar problemas rapidamente.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir todas as mensagens de log em inglês (EN-US)
2. WHEN uma operação é iniciada, THE Sistema SHALL exibir mensagem em cor azul (cyan) com timestamp
3. WHEN uma operação é concluída com sucesso, THE Sistema SHALL exibir mensagem em cor verde
4. WHEN ocorre um erro, THE Sistema SHALL exibir mensagem em cor vermelha
5. WHEN ocorre um aviso, THE Sistema SHALL exibir mensagem em cor amarela
6. WHEN um componente já está instalado, THE Sistema SHALL exibir mensagem em cor cinza ou branco indicando skip
7. THE Sistema SHALL incluir timestamp em formato ISO 8601 em cada mensagem de log
8. THE Sistema SHALL usar símbolos visuais (✓, ✗, ⚠, ℹ) para indicar tipo de mensagem
9. THE Sistema SHALL exibir barra de progresso ou indicador para operações longas
10. THE Sistema SHALL incluir resumo final colorido mostrando o que foi instalado, pulado e tempo total

### Requisito 29

**User Story:** Como administrador de sistemas que prefere Ansible, eu quero uma implementação completa usando Ansible Playbooks, para que eu possa gerenciar configurações de forma declarativa e escalável.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir diretório `ansible/` com estrutura organizada de playbooks
2. THE Sistema SHALL incluir playbook principal `ansible/site.yml` que orquestra toda a instalação
3. THE Sistema SHALL incluir roles separadas para cada componente (docker, golang, python, kotlin, dotnet, zsh, terminal-tools)
4. THE Sistema SHALL incluir playbook específico para cada ambiente (desktop, raspberry, odroid, oci, aws, github, killercoda)
5. WHEN playbooks são executados, THE Sistema SHALL usar módulos Ansible idiomáticos (apt, user, file, template, etc)
6. WHEN playbooks são executados, THE Sistema SHALL ser idempotente por natureza do Ansible
7. THE Sistema SHALL incluir arquivo `ansible/inventory` com exemplos de hosts
8. THE Sistema SHALL incluir arquivo `ansible/group_vars/all.yml` com variáveis configuráveis
9. THE Sistema SHALL incluir templates Jinja2 para arquivos de configuração (.bashrc, .zshrc, etc)
10. THE Sistema SHALL documentar no README.md como executar playbooks Ansible para cada cenário

### Requisito 30

**User Story:** Como administrador de sistemas, eu quero poder escolher entre Shell Scripts e Ansible, para que eu possa usar a ferramenta mais apropriada para minha situação.

#### Critérios de Aceitação

1. THE Sistema SHALL manter paridade funcional entre implementações Shell e Ansible
2. THE Sistema SHALL documentar no README.md vantagens e desvantagens de cada abordagem
3. WHEN Shell Scripts são usados, THE Sistema SHALL ser apropriado para instalações únicas e rápidas
4. WHEN Ansible é usado, THE Sistema SHALL ser apropriado para gerenciar múltiplos hosts
5. THE Sistema SHALL incluir tabela comparativa no README.md mostrando quando usar cada abordagem
6. THE Sistema SHALL incluir exemplos de uso para ambas as abordagens em cada cenário
7. THE Sistema SHALL garantir que ambas as implementações produzam resultado final idêntico

### Requisito 31

**User Story:** Como usuário do Ansible, eu quero um README.md detalhado dentro da pasta ansible/, para que eu possa entender e executar os playbooks em um sistema operacional recém-instalado.

#### Critérios de Aceitação

1. THE Sistema SHALL incluir arquivo `ansible/README.md` com documentação completa
2. WHEN ansible/README.md é lido, THE Sistema SHALL incluir seção de pré-requisitos (instalação do Ansible, Python, etc)
3. WHEN ansible/README.md é lido, THE Sistema SHALL incluir instruções passo-a-passo para instalação do Ansible em SO recém-instalado
4. WHEN ansible/README.md é lido, THE Sistema SHALL incluir explicação da estrutura de diretórios (roles, playbooks, inventory, group_vars)
5. WHEN ansible/README.md é lido, THE Sistema SHALL incluir exemplos de execução para cada cenário (desktop, servidor, cloud)
6. WHEN ansible/README.md é lido, THE Sistema SHALL incluir seção sobre customização de variáveis
7. WHEN ansible/README.md é lido, THE Sistema SHALL incluir exemplos de inventory para diferentes topologias (single host, multiple hosts)
8. WHEN ansible/README.md é lido, THE Sistema SHALL incluir seção de troubleshooting específica para Ansible
9. WHEN ansible/README.md é lido, THE Sistema SHALL incluir comandos para verificar sintaxe e fazer dry-run (--check, --diff)
10. WHEN ansible/README.md é lido, THE Sistema SHALL incluir seção sobre tags para execução seletiva de roles

### Requisito 32

**User Story:** Como administrador de sistemas no Brasil, eu quero que o timezone seja configurado para America/Sao_Paulo, para que o sistema exiba horários corretos para minha região.

#### Critérios de Aceitação

1. THE Sistema SHALL configurar timezone para `America/Sao_Paulo` durante instalação base
2. WHEN timezone é configurado, THE Sistema SHALL atualizar arquivo `/etc/timezone` com valor `America/Sao_Paulo`
3. WHEN timezone é configurado, THE Sistema SHALL executar comando `timedatectl set-timezone America/Sao_Paulo` em sistemas com systemd
4. WHEN timezone é configurado, THE Sistema SHALL criar link simbólico `/etc/localtime` apontando para `/usr/share/zoneinfo/America/Sao_Paulo`
5. WHEN timezone é configurado, THE Sistema SHALL validar configuração executando `date` e verificando timezone correto

### Requisito 33

**User Story:** Como administrador de sistemas, eu quero que pacotes essenciais sejam instalados durante a instalação base, para que o sistema tenha ferramentas fundamentais disponíveis.

#### Critérios de Aceitação

1. THE Sistema SHALL instalar pacote `wget` para download de arquivos
2. THE Sistema SHALL instalar pacote `git` para controle de versão
3. THE Sistema SHALL instalar pacote `zsh` como shell alternativo
4. THE Sistema SHALL instalar pacote `gpg` para criptografia e assinatura
5. THE Sistema SHALL instalar pacotes `zip` e `unzip` para compressão de arquivos
6. THE Sistema SHALL instalar pacote `vim` como editor de texto
7. THE Sistema SHALL instalar pacote `jq` para processamento de JSON
8. THE Sistema SHALL instalar pacote `telnet` para testes de conectividade
9. THE Sistema SHALL instalar pacote `curl` para requisições HTTP
10. THE Sistema SHALL instalar pacotes `htop` e `btop` para monitoramento de sistema
11. THE Sistema SHALL instalar pacotes `python3` e `python3-pip` para Python
12. THE Sistema SHALL instalar pacote `eza` como substituto moderno do ls
13. THE Sistema SHALL instalar pacote `micro` como editor de terminal moderno
14. THE Sistema SHALL instalar pacote `apt-transport-https` para repositórios HTTPS
15. THE Sistema SHALL instalar pacote `zlib1g` como biblioteca de compressão
16. THE Sistema SHALL instalar pacote `sqlite3` para banco de dados leve
17. THE Sistema SHALL instalar pacote `fzf` para busca fuzzy em terminal
18. THE Sistema SHALL instalar pacote `sudo` para execução de comandos privilegiados
19. WHEN pacotes base são instalados, THE Sistema SHALL executar `apt update` antes da instalação
20. WHEN pacotes base são instalados, THE Sistema SHALL usar flag `-y` para instalação não-interativa

### Requisito 36

**User Story:** Como administrador de sistemas, eu quero que o script detecte automaticamente se há um ambiente desktop rodando, para que componentes desktop sejam instalados apenas quando apropriado.

#### Critérios de Aceitação

1. THE Sistema SHALL detectar automaticamente a presença de ambiente desktop antes de instalar componentes
2. WHEN ambiente desktop é detectado, THE Sistema SHALL instalar componentes desktop (VSCode, Chrome, fontes, emuladores de terminal)
3. WHEN ambiente desktop NÃO é detectado, THE Sistema SHALL pular instalação de componentes desktop
4. THE Sistema SHALL detectar os seguintes ambientes desktop: GNOME, KDE Plasma, XFCE, MATE, Cinnamon, LXDE
5. THE Sistema SHALL verificar processos em execução: gnome-shell, plasmashell, xfce4-session, mate-session, cinnamon-session, lxsession
6. THE Sistema SHALL verificar variáveis de ambiente: DISPLAY, XDG_CURRENT_DESKTOP, WAYLAND_DISPLAY
7. THE Sistema SHALL verificar sockets X11: /tmp/.X11-unix/X0
8. THE Sistema SHALL verificar systemd graphical target ativo
9. THE Sistema SHALL registrar no log qual tipo de ambiente foi detectado ou se nenhum foi encontrado
10. THE Sistema SHALL usar sintaxe ${VARIABLE:-} para evitar erros com variáveis não definidas

### Requisito 37

**User Story:** Como administrador de sistemas, eu quero que o script verifique a disponibilidade de pacotes antes de tentar instalá-los, para que erros de instalação sejam evitados e o script seja mais robusto.

#### Critérios de Aceitação

1. WHEN o script tenta instalar um pacote, THE Sistema SHALL verificar se o pacote está disponível no gerenciador de pacotes antes da instalação
2. WHEN o gerenciador de pacotes é apt, THE Sistema SHALL usar comando `apt-cache search` ou `apt-cache policy` para verificar disponibilidade
3. WHEN um pacote não está disponível, THE Sistema SHALL registrar mensagem de aviso informando que o pacote será pulado
4. WHEN um pacote não está disponível, THE Sistema SHALL continuar a execução sem interromper o script
5. WHEN múltiplos pacotes são instalados em um único comando, THE Sistema SHALL verificar disponibilidade de cada pacote individualmente
6. WHEN um pacote está disponível, THE Sistema SHALL prosseguir com a instalação normalmente
7. THE Sistema SHALL registrar no log quais pacotes foram verificados e seu status de disponibilidade
8. WHEN verificação de disponibilidade falha por erro de rede ou cache, THE Sistema SHALL tentar atualizar cache com `apt update` e verificar novamente
9. THE Sistema SHALL usar timeout apropriado para comandos de verificação para evitar travamentos
10. WHEN um pacote tem nome alternativo ou está em repositório diferente, THE Sistema SHALL sugerir alternativas no log se disponível

### Requisito 38

**User Story:** Como administrador de sistemas, eu quero que o script tente pacotes alternativos quando o pacote preferido não estiver disponível, para que a instalação seja bem-sucedida em diferentes distribuições Linux.

#### Critérios de Aceitação

1. WHEN o pacote `docker-compose-v2` não está disponível, THE Sistema SHALL tentar instalar `docker-compose` (v1) como alternativa
2. WHEN o pacote `eza` não está disponível, THE Sistema SHALL tentar instalar `exa` como alternativa
3. WHEN um pacote alternativo é instalado, THE Sistema SHALL registrar no log qual alternativa foi usada
4. WHEN nenhum pacote (preferido ou alternativo) está disponível, THE Sistema SHALL registrar aviso e continuar sem interromper
5. THE Sistema SHALL verificar disponibilidade do pacote preferido primeiro antes de tentar alternativas
6. WHEN um pacote alternativo é instalado com sucesso, THE Sistema SHALL validar sua instalação
7. THE Sistema SHALL configurar aliases e variáveis de ambiente apropriadas para o pacote alternativo instalado
8. WHEN `exa` é instalado no lugar de `eza`, THE Sistema SHALL usar os mesmos aliases configurados para `eza`
9. WHEN `docker-compose` (v1) é instalado no lugar de `docker-compose-v2`, THE Sistema SHALL criar alias `docker compose` apontando para `docker-compose`
10. THE Sistema SHALL registrar no log de resumo final quais pacotes alternativos foram usados
