# Ubuntu Development Environment Setup Script

## Overview

This repository provides a shell script (`prepare.sh`) to provision a development environment on Ubuntu systems in a consistent and repeatable way.

The script is designed to be:

- Idempotent (safe to run multiple times)
- Non-interactive
- Modular (components are grouped and optional)
- Fully logged
- Suitable for local machines or ephemeral environments

It installs a set of base tools by default and allows optional installation of additional development stacks.

---

## Supported Environment

- Ubuntu 25.x or newer
- Minimum 4 GB RAM
- Root privileges (`sudo`)
- Internet access

---

## Execution

Run the script with:

```bash
sudo ./prepare.sh [options]
````

If no options are provided, only the base components are installed.

---

## Component Groups

### Base (always installed)

Includes essential tools and shell configuration:

* zsh
* vim
* micro editor
* eza
* unzip / zip
* curl / wget
* python3 and pip3
* oh-my-bash
* oh-my-zsh
* vim configuration (Vundle-based setup)
* global shell aliases
* shell configuration applied to all users

---

### Desktop

Installs tools typically used in a graphical environment:

* Visual Studio Code
* Nerd Fonts (FiraCode)
* Powerline fonts
* Terminator terminal
* Google Chrome

---

### Docker

Installs Docker Engine from the official repository, including:

* docker-ce
* docker CLI
* containerd
* buildx plugin
* compose plugin

---

### Golang

Installs the latest version of Go from the official distribution.

---

### Java

Installs:

* SDKMAN
* Latest available Java version via SDKMAN

---

### Dotnet

Installs the latest stable .NET SDK from Microsoft repositories.

---

## Command Line Options

| Option      | Description                       |
| ----------- | --------------------------------- |
| `--base`    | Install base components (default) |
| `--desktop` | Install desktop tools             |
| `--docker`  | Install Docker                    |
| `--golang`  | Install Golang                    |
| `--java`    | Install Java via SDKMAN           |
| `--dotnet`  | Install .NET SDK                  |
| `--full`    | Install all component groups      |
| `--users`   | Create additional users           |
| `--help`    | Display usage information         |

---

## Usage Examples

### 1. Base installation only

```bash
sudo ./prepare.sh
```

Installs only the base toolchain and shell configuration.

---

### 2. Full environment setup

```bash
sudo ./prepare.sh --full
```

Installs all available component groups.

---

### 3. Selective installation

```bash
sudo ./prepare.sh --docker --golang
```

Installs base tools plus Docker and Golang.

---

### 4. Creating additional users

```bash
sudo ./prepare.sh --users alice bob
```

Creates users `alice` and `bob` in addition to the default user. Passwords will be requested during execution.

---

## Logging

Each execution generates a log file:

```
/var/log/dev-setup-<timestamp>.log
```

The log includes:

* Execution steps
* Success and failure messages
* Installed, skipped, and failed components
* Start and end timestamps

---

## Idempotency Model

Before performing any installation, the script checks whether the component is already present.

Examples:

* Binary existence (`command -v`)
* Installed packages (`dpkg`)
* Existing directories or configuration files

This allows the script to:

* Be safely re-executed
* Resume partially completed setups
* Avoid unnecessary operations

---

## System Update Behavior

At the beginning of execution, the script performs:

```bash
apt-get update
apt-get upgrade -y
```

This is done non-interactively and does not require user confirmation.

Failures during system update are logged but do not stop execution.

---

## Shell Configuration

The script configures all users with:

* Zsh as default shell
* Oh My Zsh installed per user
* A predefined theme (`frisk`)
* Global aliases replacing `ls` with `eza`

Configuration is applied idempotently.

---

## Java Installation Notes

Java is installed via SDKMAN.

Because the script uses strict Bash settings (`set -euo pipefail`), SDKMAN execution requires temporarily disabling `nounset`:

```bash
set +u
source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -u
```

This behavior is handled internally in the script.

---

## Failure Handling

The script tracks three categories:

* Installed components
* Skipped components (already present)
* Failed components

At the end of execution, a summary is printed.

If any component fails, the script exits with a non-zero status.

---

## Extending the Script

To add a new component:

1. Implement an installation function:

   ```bash
   install_example() { ... }
   ```

2. Add it to a group function:

   ```bash
   install_example_group() { ... }
   ```

3. Register the group in the CLI argument parser

---

## Common Issues

### Script stops during Java installation

Cause: SDKMAN incompatibility with `set -u`

Resolution: already handled in the script by temporarily disabling `nounset`.

---

### Permission errors

Ensure the script is executable:

```bash
chmod +x prepare.sh
```

---

### Partial installation

Re-run the script. Previously installed components will be skipped.

---

## Security Considerations

* The script must be executed as root
* Default passwords are weak and must be changed
* External installation scripts are executed (SDKMAN, Oh My Zsh, etc.)

---

## Final Notes

This script provides a lightweight alternative to configuration management tools for local or disposable environments, while maintaining structure and predictability.

It is particularly useful for:

* Developer workstation provisioning
* Reproducible environments
* VM or container bootstrap scenarios
