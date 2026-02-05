# Requirements Document

## Introduction

The Env Prepare system is a collection of shell scripts designed to transform a fresh Ubuntu-based Linux installation into a fully functional development environment. The system provides a modular approach to installing base packages and optional development tools, with comprehensive logging and user management capabilities.

## Glossary

- **System**: The Env Prepare script collection
- **Base_Packages**: Essential packages installed by default on all systems
- **Optional_Modules**: Additional development tools that can be selectively installed
- **Target_User**: Any user account that will receive the development environment setup
- **Log_Entry**: A timestamped message with severity level and module identifier

## Requirements

### Requirement 1: Base Package Installation

**User Story:** As a system administrator, I want to install essential development packages, so that I have a functional baseline environment.

#### Acceptance Criteria

1. THE System SHALL install all base packages using apt package manager when available
2. WHEN base package installation begins, THE System SHALL install zsh, git, curl, wget, jq, batcat, micro, eza, python3, pip, vim, sqlite3, telnet, htop, btop, gpg, zip, unzip, apt-transport-https, zlib1g, ca-certificates, gnupg, httpie, gh, cmake, build-essential, netcat-openbsd, openssl, and openssh-server
3. WHEN a base package installation fails, THE System SHALL log the error and continue with remaining packages
4. THE System SHALL configure oh-my-zsh as the default shell framework for all users
5. THE System SHALL configure oh-my-bash as an alternative shell framework

### Requirement 2: Optional Module Installation

**User Story:** As a developer, I want to selectively install development tools, so that I can customize my environment for specific technologies.

#### Acceptance Criteria

1. WHEN the -docker parameter is provided, THE System SHALL install Docker and configure user permissions
2. WHEN the -golang parameter is provided, THE System SHALL install Go programming language
3. WHEN the -jvm parameter is provided, THE System SHALL install JVM using SDKMAN
4. WHEN the -vscode parameter is provided, THE System SHALL install Visual Studio Code
5. WHEN the -fonts parameter is provided, THE System SHALL install Nerd Fonts and Powerline Fonts
6. WHEN the -terminator parameter is provided, THE System SHALL install Terminator terminal emulator
7. WHEN the -dotnet parameter is provided, THE System SHALL install .NET runtime and SDK

### Requirement 3: User Management

**User Story:** As a system administrator, I want to create multiple users and configure them simultaneously, so that I can efficiently set up multi-user development environments.

#### Acceptance Criteria

1. WHEN the -u parameter is provided with comma-separated usernames, THE System SHALL create each specified user account
2. FOR ALL created users, THE System SHALL configure the development environment with all installed packages
3. FOR ALL users (existing and created), THE System SHALL configure shell aliases and PATH variables in .profile
4. WHEN configuring per-user settings, THE System SHALL ensure each user receives identical development tool configurations

### Requirement 4: Configuration Management

**User Story:** As a user, I want consistent shell aliases and configurations, so that I have a standardized development experience.

#### Acceptance Criteria

1. FOR ALL users, THE System SHALL add eza aliases to .profile: "ls" mapped to "eza -hHbmgalT -L 1 --time-style=long-iso --icons" and "lt" mapped to "eza -hHbmgalT -L 4 --time-style=long-iso --icons"
2. FOR ALL users, THE System SHALL configure awesome vim with custom settings including line numbers
3. FOR ALL users, THE System SHALL set oh-my-zsh theme to "agnoster"
4. THE System SHALL use .profile for all shell configuration to ensure compatibility across shell types

### Requirement 5: Logging and Monitoring

**User Story:** As a system administrator, I want comprehensive logging of all installation activities, so that I can monitor progress and troubleshoot issues.

#### Acceptance Criteria

1. THE System SHALL log all activities with timestamp in format "[YYYY-MM-DD HH:MM:SS]"
2. THE System SHALL include module identifier in each log entry showing which script is executing
3. THE System SHALL use color-coded severity levels: INFO (informational), WARN (warnings), DEBUG (debugging), ERROR (errors)
4. THE System SHALL log execution start time, end time, and total duration for each module
5. WHEN any installation begins, THE System SHALL log "Installing..." message
6. WHEN any installation completes successfully, THE System SHALL log "Successful in X seconds!" message

### Requirement 6: Script Architecture

**User Story:** As a developer, I want a modular and maintainable script structure, so that I can easily understand and modify individual components.

#### Acceptance Criteria

1. THE System SHALL organize scripts in the structure: prepare.sh (main), util/log.sh (logging), and modules/ directory containing individual installers
2. THE System SHALL implement each installer as an independent, idempotent script
3. THE System SHALL provide a common logging function used by all scripts
4. WHEN any script is executed multiple times, THE System SHALL produce the same result without errors (idempotency)
5. THE System SHALL keep individual installer scripts simple and focused on single responsibilities

### Requirement 7: Documentation

**User Story:** As a user, I want clear documentation of all available options, so that I can effectively use the system.

#### Acceptance Criteria

1. THE System SHALL provide a README.md file documenting all command-line parameters
2. THE System SHALL document the -u parameter format for user creation with comma-separated values
3. THE System SHALL document all optional module parameters and their effects
4. THE System SHALL provide usage examples for common installation scenarios
5. THE System SHALL document the logging format and color coding system