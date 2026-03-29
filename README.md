# Env Prepare System

A modular shell script collection that transforms fresh Ubuntu-based Linux installations into fully functional development environments. The system provides comprehensive logging, user management, and selective installation of development tools.

## Features

- **Base Package Installation**: Essential development tools and utilities pre-configured
- **Modular Architecture**: Install only the tools you need
- **Multi-User Support**: Configure multiple users simultaneously
- **Automatic Shell Configuration**: zsh as default shell with oh-my-zsh framework
- **Sudo and Docker Access**: Created users automatically configured for sudo and docker
- **Comprehensive Logging**: Timestamped, color-coded logs with module identification
- **Idempotent Operations**: Safe to run multiple times without side effects
- **Error Resilience**: Continues installation even if individual packages fail
- **User Environment Configuration**: Automatically configures invoking user and root

## Prerequisites

- Ubuntu-based Linux distribution (20.04 LTS or later recommended)
- Root or sudo access (for package installation and user creation)
- Internet connection for package downloads
- Note: Configuration can be applied to current user without root privileges

## Installation

Clone the repository and navigate to the directory:

```bash
git clone <repository-url>
cd env-prepare
```

## Usage

### Basic Syntax

```bash
sudo ./prepare.sh [OPTIONS]
```

### Command-Line Parameters

#### User Creation

**`-u=user1,user2,userN`**

Create specified user accounts with development environment configuration. Users are specified as a comma-separated list.

- **Format**: `-u=username1,username2,username3`
- **Valid Characters**: Lowercase letters, digits, hyphens, underscores
- **Username Rules**: Must start with a letter or underscore, maximum 32 characters
- **Example**: `-u=dev,admin,testuser`

When users are created:
- Home directories are automatically created
- Shell is set to `/bin/bash`
- Development environment is configured in `.profile`
- All installed packages and tools are configured for the user

#### Optional Modules

**`-docker`**

Install Docker and configure for non-root access.

- Installs official Docker from Docker's repository
- Adds all target users to the `docker` group
- Enables running Docker commands without `sudo`

**`-golang`**

Install Go programming language.

- Downloads latest stable Go release
- Installs to `/usr/local/go`
- Configures PATH for all users
- Enables `go` command globally

**`-jvm`**

Install Java Virtual Machine using SDKMAN.

- Installs SDKMAN for Java version management
- Installs latest LTS Java version
- Configures `JAVA_HOME` and PATH
- Supports multiple Java versions through SDKMAN

**`-vscode`**

Install Visual Studio Code.

- Adds Microsoft repository and GPG key
- Installs via apt package manager
- Available for all users

**`-fonts`**

Install Nerd Fonts and Powerline Fonts.

- Clones and installs Powerline Fonts
- Clones and installs Nerd Fonts
- Updates system font cache
- Fonts available system-wide

**`-terminator`**

Install Terminator terminal emulator.

- Installs via apt package manager
- Provides advanced terminal features
- Includes basic configuration template

**`-dotnet`**

Install .NET runtime and SDK.

- Adds Microsoft .NET repository
- Installs .NET SDK and runtime
- Configures PATH and environment variables
- Enables `dotnet` command globally

#### Help

**`-h, --help`**

Display usage information and exit.

### Usage Examples

#### Install Base Packages Only

```bash
sudo ./prepare.sh
```

Installs essential development packages on the current system.

#### Create Users with Base Packages

```bash
sudo ./prepare.sh -u=dev,admin
```

Creates users `dev` and `admin`, configures their environments with base packages.

#### Install Base Packages and Docker

```bash
sudo ./prepare.sh -docker
```

Installs base packages and Docker on the current system.

#### Create User and Install Multiple Tools

```bash
sudo ./prepare.sh -u=developer -docker -golang -vscode
```

Creates user `developer` and installs Docker, Go, and VS Code for all users.

#### Full Development Environment

```bash
sudo ./prepare.sh -u=dev,admin -docker -golang -jvm -vscode -fonts -dotnet
```

Creates users `dev` and `admin`, installs all available development tools.

#### Install Only Optional Modules

```bash
sudo ./prepare.sh -golang -dotnet
```

Installs Go and .NET on the current system without creating new users.

## Base Packages

The system installs the following essential packages by default:

### System Tools
- `zsh` - Advanced shell
- `git` - Version control
- `curl` - Data transfer tool
- `wget` - File downloader
- `jq` - JSON processor
- `zip`, `unzip` - Archive utilities

### Development Tools
- `cmake` - Build system
- `build-essential` - Compilation tools
- `python3`, `pip` - Python environment
- `nodejs` - JavaScript runtime (via base installation)

### Editors
- `vim` - Text editor with awesome-vim configuration
- `micro` - Modern terminal editor

### Monitoring & Utilities
- `htop` - Interactive process viewer
- `btop` - Modern resource monitor
- `telnet` - Network utility
- `netcat-openbsd` - Network tool
- `openssh-server` - SSH server

### Security & Certificates
- `gpg` - GNU Privacy Guard
- `ca-certificates` - SSL/TLS certificates
- `gnupg` - GPG utilities
- `openssl` - SSL/TLS toolkit

### Modern Alternatives
- `batcat` - Cat clone with syntax highlighting
- `eza` - Modern ls replacement
- `httpie` - HTTP client
- `gh` - GitHub CLI

### Additional
- `sqlite3` - Database
- `apt-transport-https` - HTTPS support for apt
- `zlib1g` - Compression library

## Configuration

### Shell Configuration

All users receive the following shell configurations:

#### Oh-My-Zsh
- **Theme**: agnoster
- **Framework**: Oh-My-Zsh for advanced shell features
- **Default Shell**: zsh (set during user creation)

#### Oh-My-Bash
- **Alternative Framework**: Available as alternative to zsh
- **Configuration**: Automatically configured for all users

### User Profile Configuration

All users receive the following configurations in their `.profile`:

#### Eza Aliases

Modern replacements for traditional `ls` command:

```bash
alias ls='eza -hHbmgalT -L 1 --time-style=long-iso --icons'
alias lt='eza -hHbmgalT -L 4 --time-style=long-iso --icons'
```

- `ls` - List files with detailed information, one level deep
- `lt` - List files with tree view, up to 4 levels deep

#### Vim Configuration

- **Awesome Vim**: Custom vim configuration with enhanced features
- **Line Numbers**: Enabled by default
- **Syntax Highlighting**: Automatic for supported file types

## Logging

The system provides comprehensive logging of all installation activities.

### Log Format

All log entries follow this standardized format:

```
[YYYY-MM-DD HH:MM:SS] [module_name] [LEVEL] message
```

**Components:**
- `[YYYY-MM-DD HH:MM:SS]` - ISO 8601 timestamp
- `[module_name]` - Name of the script/module generating the log
- `[LEVEL]` - Severity level (see below)
- `message` - Log message content

### Log Levels and Colors

The system uses color-coded severity levels for easy identification:

| Level | Color  | Usage |
|-------|--------|-------|
| INFO  | Green  | Informational messages, successful operations |
| WARN  | Yellow | Warnings, non-critical issues |
| DEBUG | Blue   | Debugging information, detailed operation details |
| ERROR | Red    | Error messages, failed operations |

### Example Log Output

```
[2024-01-15 10:30:45] [prepare] [INFO] Starting Env Prepare System
[2024-01-15 10:30:45] [prepare] [INFO] Parsing command-line parameters
[2024-01-15 10:30:46] [prepare] [INFO] Creating user accounts
[2024-01-15 10:30:47] [prepare] [INFO] Creating user: developer
[2024-01-15 10:30:48] [prepare] [INFO] Successfully created user: developer
[2024-01-15 10:30:48] [base] [INFO] Installing...
[2024-01-15 10:31:15] [base] [INFO] Successful in 27 seconds!
[2024-01-15 10:31:15] [docker] [INFO] Installing...
[2024-01-15 10:31:45] [docker] [INFO] Successful in 30 seconds!
[2024-01-15 10:31:45] [prepare] [INFO] System setup complete
```

### Module Execution Timing

Each module logs its execution time:

- **Start**: `[module_name] [INFO] Installing...`
- **End**: `[module_name] [INFO] Successful in X seconds!`

This allows monitoring of installation progress and identifying slow operations.

## Troubleshooting

### Permission Denied

**Error**: `Permission denied` or `This script must be run as root`

**Solution**: Run the script with `sudo`:
```bash
sudo ./prepare.sh [OPTIONS]
```

### Invalid Username

**Error**: `Invalid username skipped: [username]`

**Cause**: Username doesn't follow Linux naming conventions

**Solution**: Use valid usernames:
- Start with lowercase letter or underscore
- Use only lowercase letters, digits, hyphens, underscores
- Maximum 32 characters

### Module Installation Failed

**Error**: `Module failed: [module_name]`

**Cause**: Network issues, missing dependencies, or system configuration

**Solution**:
1. Check internet connection
2. Verify system has required dependencies
3. Review error messages in log output
4. Run the script again (most operations are idempotent)

### Package Not Found

**Error**: `Unable to locate package [package_name]`

**Cause**: Package repository not available or outdated package list

**Solution**:
```bash
sudo apt update
sudo ./prepare.sh [OPTIONS]
```

## Architecture

The system is organized into modular components:

```
env-prepare/
├── prepare.sh              # Main orchestrator script
├── util/
│   └── log.sh              # Centralized logging utility
├── modules/
│   ├── base.sh             # Base packages installer
│   ├── docker.sh           # Docker installer
│   ├── golang.sh           # Go language installer
│   ├── dotnet.sh           # .NET installer
│   ├── jvm.sh              # JVM installer
│   ├── fonts.sh            # Font installer
│   ├── terminator.sh       # Terminator installer
│   └── vscode.sh           # VS Code installer
└── README.md               # This file
```

The system uses util/log.sh as the centralized logging utility that provides consistent formatting and color coding across all modules.

### Design Principles

- **Modularity**: Each tool is installed by an independent script
- **Idempotency**: Scripts can be run multiple times safely
- **Logging**: All operations are logged with timestamps and severity levels
- **Error Resilience**: Failures in one module don't prevent others from running
- **User Configuration**: All users receive identical configurations

## Contributing

To add a new optional module:

1. Create a new script in `modules/` directory
2. Implement the standard module interface with logging
3. Add the module to `AVAILABLE_MODULES` in `prepare.sh`
4. Update this README with module documentation
5. Add property-based tests for the new module

## License

See LICENSE file for details.

## Support

For issues, questions, or contributions, please refer to the project repository.
