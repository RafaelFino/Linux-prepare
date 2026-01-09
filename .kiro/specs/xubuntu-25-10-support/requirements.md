# Requirements Document

## Introduction

Este documento especifica os requisitos para adicionar suporte completo ao Xubuntu 25.10 no projeto Linux-prepare, incluindo testes automatizados e atualização da documentação. O projeto já suporta Xubuntu 24.04, e esta funcionalidade estende o suporte para a versão mais recente.

## Glossary

- **Linux-prepare**: Sistema de automação para configurar ambientes de desenvolvimento Linux
- **Xubuntu**: Distribuição Ubuntu com ambiente desktop XFCE
- **Test Framework**: Sistema de testes Docker que valida instalações em diferentes distribuições
- **Documentation System**: Conjunto de arquivos markdown que documentam distribuições suportadas
- **Compatibility Matrix**: Tabela que mostra quais recursos funcionam em cada distribuição

## Requirements

### Requirement 1

**User Story:** Como desenvolvedor, quero que o Linux-prepare funcione no Xubuntu 25.10, para que eu possa configurar meu ambiente de desenvolvimento nesta distribuição mais recente.

#### Acceptance Criteria

1. WHEN the prepare.sh script is executed on Xubuntu 25.10, THE Linux-prepare System SHALL install all core components successfully
2. WHEN desktop detection runs on Xubuntu 25.10, THE Linux-prepare System SHALL correctly identify the XFCE desktop environment
3. WHEN all installation steps complete on Xubuntu 25.10, THE Linux-prepare System SHALL provide the same functionality as other supported Ubuntu derivatives
4. WHERE desktop components are being installed, THE Linux-prepare System SHALL install VSCode, Chrome, fonts and terminal emulators on Xubuntu 25.10
5. WHILE validating the installation, THE Linux-prepare System SHALL pass all validation checks on Xubuntu 25.10

### Requirement 2

**User Story:** Como mantenedor do projeto, quero testes automatizados para Xubuntu 25.10, para que eu possa garantir que futuras mudanças não quebrem a compatibilidade.

#### Acceptance Criteria

1. WHEN automated tests are executed, THE Test Framework SHALL include Xubuntu 25.10 in the test matrix
2. WHEN the Dockerfile for Xubuntu 25.10 is built, THE Test Framework SHALL create a valid test environment
3. WHEN validation scripts run in the Xubuntu 25.10 container, THE Test Framework SHALL verify all installed components
4. WHERE test derivatives are executed, THE Test Framework SHALL include Xubuntu 25.10 alongside other derivative distributions
5. IF any component fails validation on Xubuntu 25.10, THEN THE Test Framework SHALL report the specific failure

### Requirement 3

**User Story:** Como usuário da documentação, quero ver Xubuntu 25.10 listado nas distribuições suportadas, para que eu saiba que posso usar o Linux-prepare nesta versão.

#### Acceptance Criteria

1. WHEN users read the main README, THE Documentation System SHALL list Xubuntu 25.10 as a supported distribution
2. WHEN users check the compatibility matrix, THE Documentation System SHALL show Xubuntu 25.10 with all supported features marked
3. WHEN users review distribution-specific documentation, THE Documentation System SHALL include Xubuntu 25.10 in all relevant tables and lists
4. WHERE version information is displayed, THE Documentation System SHALL show Xubuntu 25.10 with tested status
5. WHILE browsing test documentation, THE Documentation System SHALL reference Xubuntu 25.10 in test procedures

### Requirement 4

**User Story:** Como usuário do sistema, quero que o Linux-prepare detecte corretamente o nome do pacote eza/exa baseado na versão do Ubuntu, para que a ferramenta seja instalada corretamente independente da versão.

#### Acceptance Criteria

1. WHEN the script runs on Ubuntu 22.04 or derivatives, THE Linux-prepare System SHALL attempt to install the package named "exa"
2. WHEN the script runs on Ubuntu 24.04 or newer derivatives, THE Linux-prepare System SHALL attempt to install the package named "eza"
3. WHEN Xubuntu 25.10 is detected, THE Linux-prepare System SHALL use the correct package name "eza" for the modern ls replacement
4. IF the preferred package name is not available, THEN THE Linux-prepare System SHALL attempt the alternative name as fallback
5. WHILE validating the installation, THE Linux-prepare System SHALL verify that the ls alias works correctly regardless of the installed package name

### Requirement 5

**User Story:** Como usuário do sistema, quero que os arquivos temporários de fontes sejam gerenciados de forma mais segura e limpa, para que não ocupem espaço desnecessário e não usem diretórios compartilhados.

#### Acceptance Criteria

1. WHEN desktop fonts are being installed, THE Linux-prepare System SHALL create a temporary directory in the user's home directory instead of using /tmp
2. WHEN font installation completes successfully, THE Linux-prepare System SHALL remove all temporary font files from the home temporary directory
3. WHEN font installation fails, THE Linux-prepare System SHALL still attempt to clean up temporary font files
4. WHERE multiple users are being configured, THE Linux-prepare System SHALL use separate temporary directories for each user's font installation
5. WHILE installing fonts, THE Linux-prepare System SHALL only keep necessary font files and remove downloaded archives after extraction

### Requirement 6

**User Story:** Como usuário do sistema, quero que o Docker seja instalado corretamente baseado na versão específica do Ubuntu/Xubuntu, para que eu tenha a versão mais adequada e estável para minha distribuição.

#### Acceptance Criteria

1. WHEN Docker installation begins, THE Linux-prepare System SHALL detect the specific Ubuntu/Xubuntu version and codename
2. WHEN configuring Docker repositories, THE Linux-prepare System SHALL use the version-specific repository as documented in https://docs.docker.com/engine/install/ubuntu/
3. WHEN Xubuntu 25.10 is detected, THE Linux-prepare System SHALL use the appropriate Ubuntu repository configuration for that version
4. WHERE Docker installation documentation is referenced, THE Linux-prepare System SHALL point users to the official Docker documentation at https://docs.docker.com/engine/install/ubuntu/
5. IF the specific version repository is not available, THEN THE Linux-prepare System SHALL use the closest compatible Ubuntu LTS version repository

### Requirement 7

**User Story:** Como desenvolvedor e mantenedor, quero que o script prepare.sh seja refatorado em módulos menores e independentes, para que cada componente possa ser mantido, testado e executado separadamente.

#### Acceptance Criteria

1. WHEN the prepare.sh script is executed, THE Linux-prepare System SHALL act as an orchestrator calling individual module scripts
2. WHEN individual installation modules are created, THE Linux-prepare System SHALL allow each module to be executed independently
3. WHEN module scripts are developed, THE Linux-prepare System SHALL ensure each module has a single, clear responsibility
4. WHERE documentation is updated, THE Linux-prepare System SHALL explain the new modular architecture and what each script does
5. WHILE maintaining backward compatibility, THE Linux-prepare System SHALL preserve all existing command-line options and behavior in the main prepare.sh script

### Requirement 8

**User Story:** Como desenvolvedor de CI/CD, quero que os testes do Xubuntu 25.10 sejam integrados aos pipelines existentes, para que a compatibilidade seja verificada automaticamente.

#### Acceptance Criteria

1. WHEN derivative tests are executed, THE Test Framework SHALL include Xubuntu 25.10 in the test-derivatives.sh script
2. WHEN full test suites run, THE Test Framework SHALL include Xubuntu 25.10 in the run-all-tests.sh script
3. WHEN test results are generated, THE Test Framework SHALL report Xubuntu 25.10 results alongside other distributions
4. WHERE test execution time is calculated, THE Test Framework SHALL account for Xubuntu 25.10 testing time
5. IF Xubuntu 25.10 tests fail, THEN THE Test Framework SHALL provide clear error reporting