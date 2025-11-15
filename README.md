# Linux Development Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Ansible](https://img.shields.io/badge/Ansible-2.9+-blue.svg)](https://www.ansible.com/)

Automated scripts to prepare fresh Linux installations as complete development environments with modern tools, multiple programming languages, and optimized terminal configurations.

## 🎯 Overview

This project provides comprehensive automation for setting up Linux development environments across multiple platforms:
- **Desktop workstations** (Ubuntu, Debian, Mint)
- **ARM devices** (Raspberry Pi, Odroid)
- **Cloud instances** (Oracle Cloud, AWS EC2, GitHub Codespaces, Killercoda)

Choose between **Shell Scripts** (fast, standalone) or **Ansible** (scalable, declarative) implementations.

## ✨ Features

### Development Tools
- 🐳 **Docker & Docker Compose v2** - Containerization platform
- 🐹 **Golang** - Latest version with automatic updates
- 🐍 **Python 3** - With pip, virtualenv, and development tools
- ☕ **JVM (Java)** - Via SDKMAN for easy version management
- 🎯 **Kotlin** - Via SDKMAN
- 💜 **. NET SDK 8.0** - Cross-platform development

### Terminal Experience
- 🐚 **Zsh** - Modern shell set as default
- 🎨 **Oh-My-Zsh** - With 'frisk' theme and 30+ plugins
- 🎨 **Oh-My-Bash** - Enhanced Bash configuration
- 📝 **Micro Editor** - Intuitive terminal editor (default)
- 📝 **Vim** - With awesome vimrc configuration
- 📂 **eza** - Modern ls replacement with icons and tree view
- 🔍 **fzf** - Fuzzy finder for command history

### Desktop Components (Optional)
- 💻 **VSCode** - Popular code editor
- 🌐 **Google Chrome** - Web browser
- 🖥️ **Terminal Emulators** - Terminator & Alacritty
- 🔤 **Fonts** - Powerline & Nerd Fonts (FiraCode, JetBrainsMono, Hack)

### System Configuration
- 🌍 **Timezone**: America/Sao_Paulo
- 👤 **User Management**: Automatic sudo group assignment
- 🔄 **Idempotent**: Safe to run multiple times
- 🎨 **Colored Logs**: Clear, timestamped output in English


## 🚀 Quick Start

### Desktop Installation (Full Setup)
```bash
cd scripts
sudo ./prepare.sh --desktop
```

### Server Installation (No Desktop)
```bash
cd scripts
sudo ./prepare.sh
```

### Custom Installation
```bash
# Skip specific components
sudo ./prepare.sh --skip-docker --skip-dotnet

# Create additional users
sudo ./prepare.sh -u=developer,devops --desktop

# Minimal setup (only terminal tools)
sudo ./prepare.sh --skip-docker --skip-go --skip-python --skip-kotlin --skip-jvm --skip-dotnet
```

## 📋 Prerequisites

- **Operating System**: Debian-based Linux (Ubuntu 20.04+, Debian 11+, Linux Mint, etc.)
- **Privileges**: Root or sudo access
- **Network**: Internet connection required
- **Disk Space**: ~5GB for full installation (less without desktop)
- **Time**: 10-30 minutes depending on components

## 📦 Supported Distributions

| Distribution | Version | Status |
|--------------|---------|--------|
| Ubuntu | 22.04, 24.04 | ✅ Fully Supported |
| Debian | 11, 12 | ✅ Fully Supported |
| Linux Mint | 21+  | ✅ Fully Supported |
| Raspberry Pi OS | Latest | ✅ Supported (ARM) |
| Amazon Linux | 2 | ⚠️ Limited (uses yum) |

## 🎮 Usage

### Main Script (scripts/prepare.sh)

```bash
sudo ./prepare.sh [OPTIONS]
```

### 🔍 Smart Desktop Detection

The script automatically detects if you're running a desktop environment:

**Desktop Detected** (GNOME, KDE, XFCE, MATE, Cinnamon, LXDE):
- ✅ Automatically installs desktop components (VSCode, Chrome, fonts, terminal emulators)

**Server/Headless Detected** (Raspberry Pi, Cloud instances, SSH-only):
- ❌ Skips desktop components automatically

**Detection Methods:**
- Checks for running desktop environment processes (gnome-shell, plasmashell, xfce4-session, etc.)
- Detects X11 or Wayland display servers
- Checks systemd graphical target
- Examines environment variables (DISPLAY, XDG_CURRENT_DESKTOP, WAYLAND_DISPLAY)

#### Options

| Option | Description |
|--------|-------------|
| `-u=USER1,USER2` | Create and configure specified users (comma-separated) |
| `--skip-docker` | Skip Docker and Docker Compose installation |
| `--skip-go` | Skip Golang installation |
| `--skip-python` | Skip Python installation |
| `--skip-kotlin` | Skip Kotlin installation |
| `--skip-jvm` | Skip JVM (Java) installation |
| `--skip-dotnet` | Skip .NET SDK installation |
| `-h, --help` | Show detailed help message |

**Note**: Desktop components are automatically installed if a desktop environment is detected.

#### Default Behavior

**Without arguments**, the script installs:
- ✅ All development tools (Docker, Go, Python, Kotlin, JVM, .NET)
- ✅ Terminal tools (zsh, oh-my-zsh, oh-my-bash, eza, micro, vim)
- ✅ Base packages (git, curl, wget, htop, btop, jq, fzf, etc.)
- 🔍 Desktop components (AUTO-DETECTED)
  - ✅ Installed if desktop environment detected (GNOME, KDE, XFCE, etc.)
  - ❌ Skipped on servers/headless systems
  - Use `--desktop` to force installation
  - Use `--no-desktop` to disable

**Users configured**: root + current user (add more with `-u=`)


## 📚 Examples

### Example 1: Full Desktop Workstation
```bash
# Install everything (desktop auto-detected)
sudo ./prepare.sh
```
**Installs**: Docker, Go, Python, Kotlin, JVM, .NET, VSCode, Chrome, fonts, terminal emulators (if desktop detected)

### Example 2: Development Server (No Desktop)
```bash
# All dev tools (desktop auto-skipped on servers)
sudo ./prepare.sh
```
**Installs**: Docker, Go, Python, Kotlin, JVM, .NET, terminal tools (no desktop on servers)

### Example 3: Docker + Go Only
```bash
# Skip everything except Docker and Go
sudo ./prepare.sh --skip-python --skip-kotlin --skip-jvm --skip-dotnet
```
**Installs**: Docker, Go, terminal tools

### Example 4: Multiple Users with Desktop
```bash
# Create users 'developer' and 'devops' with full setup
sudo ./prepare.sh -u=developer,devops --desktop
```
**Configures**: root, current user, developer, devops (all with full environment)

### Example 5: Python Data Science Workstation
```bash
# Python-focused setup (desktop auto-detected)
sudo ./prepare.sh --skip-go --skip-kotlin --skip-jvm --skip-dotnet
```
**Installs**: Docker, Python, VSCode (if desktop), Chrome (if desktop), terminal tools

### Example 6: Go Microservices Server
```bash
# Go and Docker only
sudo ./prepare.sh --skip-python --skip-kotlin --skip-jvm --skip-dotnet
```
**Installs**: Docker, Go, terminal tools

### Example 7: .NET Development Environment
```bash
# .NET with Docker, skip other languages (desktop auto-detected)
sudo ./prepare.sh --skip-go --skip-python --skip-kotlin --skip-jvm
```
**Installs**: Docker, .NET, VSCode (if desktop), Chrome (if desktop), terminal tools

## 🌍 Environment-Specific Scripts

### Desktop (scripts/prepare.sh)
Full-featured script for desktop workstations and servers.

```bash
cd scripts
sudo ./prepare.sh --desktop
```

### Raspberry Pi (rasp/rasp4-prepare.sh)
Optimized for Raspberry Pi 4 with Ubuntu (ARM architecture).

```bash
cd rasp
sudo ./rasp4-prepare.sh
```

### Odroid (odroid/odroid-prepare.sh)
Optimized for Odroid devices with Ubuntu (ARM architecture).

```bash
cd odroid
sudo ./odroid-prepare.sh
```

### Oracle Cloud Infrastructure (cloud/oci-ubuntu.sh)
Configured for OCI VMs with firewall rules.

```bash
cd cloud
sudo ./oci-ubuntu.sh
```

### AWS EC2 (cloud/aws-ec2-prepare.sh)
Configured for Amazon Linux 2 (uses yum instead of apt).

```bash
cd cloud
sudo ./aws-ec2-prepare.sh
```

### GitHub Codespaces (cloud/github-workspace.sh)
Optimized for GitHub Codespaces environment.

```bash
cd cloud
./github-workspace.sh
```

### Killercoda (cloud/killercoda.sh)
Quick setup for Killercoda interactive environments.

```bash
# Run directly from URL
curl https://raw.githubusercontent.com/RafaelFino/Linux-prepare/main/cloud/killercoda.sh | bash
```


## 📊 Component Comparison by Environment

| Component | Desktop | Server | Raspberry Pi | Odroid | OCI | AWS EC2 | GitHub | Killercoda |
|-----------|---------|--------|--------------|--------|-----|---------|--------|------------|
| Base Packages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Docker | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Golang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Python | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Kotlin | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| JVM | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| .NET | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Zsh/Oh-My-Zsh | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Vim/Micro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eza | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| VSCode | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Chrome | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Fonts | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Terminal Emulators | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

*Desktop components require `--desktop` flag

## 🛠️ What Gets Installed

### Base Packages
```
wget, git, zsh, gpg, zip, unzip, vim, jq, telnet, curl, htop, btop,
python3, python3-pip, eza, micro, apt-transport-https, zlib1g,
sqlite3, fzf, sudo
```

### Programming Languages

#### Python
- Python 3.x (latest from repository)
- pip3 (package manager)
- virtualenv (virtual environments)
- python3-dev (development headers)
- Aliases: `python` → `python3`, `pip` → `pip3`

#### Golang
- Latest stable version from official Go website
- Installed to `/usr/local/go`
- Added to system PATH
- `$HOME/go/bin` added to user PATH

#### Kotlin
- Installed via SDKMAN
- Latest stable version
- Includes Kotlin compiler and REPL

#### JVM (Java)
- Installed via SDKMAN
- Latest LTS version
- Managed per-user

#### .NET
- .NET SDK 8.0
- From official Microsoft repository
- Includes runtime and development tools

### Terminal Configuration

#### Zsh
- Set as default shell for all users
- Oh-My-Zsh framework installed
- Theme: `frisk`
- 30+ plugins enabled:
  ```
  git, colorize, command-not-found, compleat, composer, cp, debian,
  dircycle, docker, docker-compose, dotnet, eza, fzf, gh, golang,
  grc, nats, pip, postgres, procs, python, qrcode, redis-cli, repo,
  rust, sdk, ssh, sudo, systemd, themes, ubuntu, vscode,
  zsh-interactive-cd
  ```

#### Bash
- Oh-My-Bash framework installed
- Enhanced configuration
- Same aliases as Zsh

#### Aliases
```bash
ls="eza -hHbmgalT -L 1 --time-style=long-iso --icons"  # Enhanced ls
lt="eza -hHbmgalT -L 4 --time-style=long-iso --icons"  # Tree view (4 levels)
python=python3                                          # Python alias
pip=pip3                                                # Pip alias
```

#### Environment Variables
```bash
EDITOR=micro    # Default editor
VISUAL=micro    # Visual editor
```

#### Vim
- Awesome vimrc configuration
- Line numbers enabled
- Enhanced syntax highlighting
- Multiple plugins

### Desktop Components (--desktop flag)

#### Applications
- **VSCode**: Installed via snap
- **Google Chrome**: Latest stable version

#### Terminal Emulators
- **Terminator**: Configured with transparency and Nerd Font
- **Alacritty**: Configured with transparency and Nerd Font

#### Fonts
- **Powerline Fonts**: For enhanced terminal symbols
- **Nerd Fonts**: FiraCode, JetBrainsMono, Hack
- **MS Core Fonts**: Arial, Times New Roman, etc.


## 🔄 Shell Scripts vs Ansible

### When to Use Shell Scripts

**Advantages:**
- ✅ No dependencies (just bash)
- ✅ Fast execution
- ✅ Simple to understand
- ✅ Perfect for single machines
- ✅ Easy to customize on-the-fly

**Best For:**
- Personal workstations
- One-time setups
- Quick prototyping
- Learning environments
- Single server deployments

**Usage:**
```bash
sudo ./scripts/prepare.sh --desktop
```

### When to Use Ansible

**Advantages:**
- ✅ Declarative configuration
- ✅ Idempotent by design
- ✅ Scalable to hundreds of hosts
- ✅ Role-based organization
- ✅ Easy to version control
- ✅ Dry-run capability
- ✅ Parallel execution

**Best For:**
- Multiple servers
- Infrastructure as Code
- Team environments
- Repeatable deployments
- CI/CD pipelines
- Configuration management

**Usage:**
```bash
ansible-playbook -i inventory ansible/site.yml
```

### Comparison Table

| Feature | Shell Scripts | Ansible |
|---------|---------------|---------|
| Setup Time | Instant | Requires Ansible installation |
| Learning Curve | Low | Medium |
| Scalability | Single host | Multiple hosts |
| Execution Speed | Fast | Moderate |
| Idempotency | Manual implementation | Built-in |
| Dry Run | Not available | `--check` flag |
| Parallel Execution | Limited | Built-in |
| Configuration Management | Script-based | Declarative YAML |
| Best Use Case | Personal machines | Infrastructure fleets |

## 📁 Project Structure

```
linux-prepare/
├── scripts/
│   └── prepare.sh              # Main script for desktops/servers
├── rasp/
│   └── rasp4-prepare.sh        # Raspberry Pi 4 optimized
├── odroid/
│   └── odroid-prepare.sh       # Odroid optimized
├── cloud/
│   ├── oci-ubuntu.sh           # Oracle Cloud Infrastructure
│   ├── aws-ec2-prepare.sh      # AWS EC2 (Amazon Linux)
│   ├── github-workspace.sh     # GitHub Codespaces
│   └── killercoda.sh           # Killercoda environments
├── ansible/
│   ├── README.md               # Ansible documentation
│   ├── site.yml                # Main playbook
│   ├── inventory/              # Host inventories
│   ├── group_vars/             # Global variables
│   ├── roles/                  # Ansible roles
│   │   ├── base/               # Base packages and timezone
│   │   ├── docker/             # Docker installation
│   │   ├── golang/             # Golang installation
│   │   ├── python/             # Python installation
│   │   ├── kotlin/             # Kotlin installation
│   │   ├── dotnet/             # .NET installation
│   │   ├── terminal-tools/     # eza, micro, vim
│   │   ├── shell-config/       # Zsh, Bash configuration
│   │   ├── desktop/            # Desktop components
│   │   └── users/              # User management
│   └── playbooks/              # Environment-specific playbooks
├── tests/
│   ├── docker/                 # Dockerfiles for testing
│   └── scripts/                # Validation scripts
└── README.md                   # This file
```


## 🐛 Troubleshooting

### Common Issues

#### Issue: "apt: command not found"
**Cause**: Not a Debian-based distribution  
**Solution**: This script only supports Debian-based distributions (Ubuntu, Debian, Mint)

#### Issue: "Permission denied"
**Cause**: Script not run with sudo  
**Solution**: Run with `sudo ./prepare.sh`

#### Issue: "Docker command not found after installation"
**Cause**: Need to log out and back in for group membership  
**Solution**: Log out and log back in, or run `newgrp docker`

#### Issue: "SDKMAN installation fails"
**Cause**: Network issues or missing dependencies  
**Solution**: Check internet connection, ensure curl and zip are installed

#### Issue: "Snap not available for VSCode"
**Cause**: Snap not installed or not supported  
**Solution**: Install snapd: `sudo apt install snapd`

#### Issue: "Fonts not showing in terminal"
**Cause**: Terminal not configured to use Nerd Fonts  
**Solution**: Configure terminal to use "FiraCode Nerd Font" or similar

#### Issue: "Oh-My-Zsh plugins not working"
**Cause**: Missing plugin dependencies  
**Solution**: Script installs dependencies automatically, but some plugins may need additional packages

#### Issue: "Script hangs during user creation"
**Cause**: Waiting for password input  
**Solution**: Enter password when prompted, or use existing users only

### Environment-Specific Issues

#### Raspberry Pi / Odroid
- **Issue**: Some packages not available for ARM
- **Solution**: Script automatically detects architecture and uses ARM-compatible packages

#### AWS EC2 (Amazon Linux)
- **Issue**: Different package manager (yum vs apt)
- **Solution**: Use the specific `aws-ec2-prepare.sh` script

#### GitHub Codespaces
- **Issue**: Some configurations conflict with Codespaces defaults
- **Solution**: Script preserves existing Codespaces configurations

#### Cloud Instances (OCI, AWS)
- **Issue**: Firewall blocking connections
- **Solution**: Configure security groups/firewall rules in cloud console

### Getting Help

1. **Check the logs**: Script provides detailed colored output
2. **Run with verbose mode**: Add `set -x` to script for debugging
3. **Check system logs**: `journalctl -xe` for systemd services
4. **Verify installation**: Run validation commands manually
5. **Open an issue**: [GitHub Issues](https://github.com/RafaelFino/Linux-prepare/issues)

### Validation Commands

```bash
# Check installed versions
docker --version
docker compose version
go version
python3 --version
dotnet --version
kotlin -version
java -version

# Check shell
echo $SHELL
zsh --version

# Check aliases
alias ls
alias lt

# Check environment variables
echo $EDITOR
echo $VISUAL

# Check user groups
groups
```

## 🧪 Testing

### Quick Test (5-10 minutes)

```bash
# From project root directory
./tests/quick-test.sh
```

This tests basic installation with Docker, Go, Python, and terminal tools on Ubuntu 24.04.

### Full Automated Testing (15-30 minutes)

```bash
# From project root directory
./tests/run-all-tests.sh
```

This runs comprehensive tests on:
- Ubuntu 24.04
- Debian 12
- Idempotency (script runs twice)

### Individual Distribution Test

```bash
# Test Ubuntu 24.04
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test-ubuntu .
docker run --rm test-ubuntu /tmp/validate.sh

# Test Debian 12
docker build -f tests/docker/Dockerfile.debian-12 -t test-debian .
docker run --rm test-debian /tmp/validate.sh
```

### Manual Testing in Container

```bash
# Interactive test
docker run -it --rm -v $(pwd):/workspace -w /workspace ubuntu:24.04 bash

# Inside container:
apt update && apt install -y sudo
./scripts/prepare.sh --skip-desktop
./tests/scripts/validate.sh
```

### Validation Only

If you've already run the script and want to validate:

```bash
./tests/scripts/validate.sh
```

**See [tests/TESTING.md](tests/TESTING.md) for detailed testing guide.**

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Guidelines

- Follow existing code style
- Test on multiple distributions
- Update documentation
- Add examples for new features
- Ensure idempotency

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Rafael Fino**
- GitHub: [@RafaelFino](https://github.com/RafaelFino)

## 🙏 Acknowledgments

- [Oh-My-Zsh](https://ohmyz.sh/) - Zsh framework
- [Oh-My-Bash](https://ohmybash.nntoan.com/) - Bash framework
- [awesome-vimrc](https://github.com/amix/vimrc) - Vim configuration
- [eza](https://github.com/eza-community/eza) - Modern ls replacement
- [micro](https://micro-editor.github.io/) - Terminal editor
- [SDKMAN](https://sdkman.io/) - SDK manager

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Golang Documentation](https://golang.org/doc/)
- [Python Documentation](https://docs.python.org/)
- [.NET Documentation](https://docs.microsoft.com/dotnet/)
- [Kotlin Documentation](https://kotlinlang.org/docs/)

---

**Note**: This script modifies system configuration. Always review scripts before running with sudo privileges. Test in a VM or container first if unsure.

**Execution Time**: Approximately 10-30 minutes depending on components and internet speed.

**Disk Space**: ~5GB for full installation (less without desktop components).
