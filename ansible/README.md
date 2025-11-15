# Ansible Implementation for Linux Development Environment Setup

This directory contains Ansible playbooks and roles for automated setup of Linux development environments. Use Ansible when you need to manage multiple hosts or want declarative, idempotent configuration management.

## 📋 Prerequisites

### On Control Machine (where you run Ansible)
- **Ansible**: 2.9 or higher
- **Python**: 3.8 or higher
- **SSH access** to target hosts

### On Target Hosts
- **Debian-based Linux**: Ubuntu 20.04+, Debian 11+, Linux Mint
- **Python 3**: Usually pre-installed
- **SSH server**: Running and accessible
- **Sudo privileges**: For the connecting user

## 🚀 Quick Start

### Install Ansible on Fresh Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install Ansible
sudo apt install -y ansible python3-pip

# Verify installation
ansible --version
```

### Run Locally (Single Machine)

```bash
# Navigate to ansible directory
cd ansible

# Run on localhost
ansible-playbook -i "localhost," -c local site.yml

# With desktop components
ansible-playbook -i "localhost," -c local site.yml -e "install_desktop=true"
```

### Run on Remote Hosts

```bash
# Edit inventory file
nano inventory/hosts

# Run on all hosts
ansible-playbook -i inventory/hosts site.yml

# Run on specific group
ansible-playbook -i inventory/hosts site.yml --limit desktops

# Dry run (check mode)
ansible-playbook -i inventory/hosts site.yml --check --diff
```

## 📁 Directory Structure

```
ansible/
├── README.md                   # This file
├── site.yml                    # Main playbook
├── inventory/
│   └── hosts                   # Inventory file (define your hosts here)
├── group_vars/
│   └── all.yml                 # Global variables
├── host_vars/                  # Host-specific variables (optional)
├── roles/                      # Ansible roles (to be implemented)
│   ├── base/                   # Base packages and timezone
│   ├── docker/                 # Docker installation
│   ├── golang/                 # Golang installation
│   ├── python/                 # Python installation
│   ├── kotlin/                 # Kotlin installation
│   ├── dotnet/                 # .NET installation
│   ├── terminal-tools/         # eza, micro, vim
│   ├── shell-config/           # Zsh, Bash configuration
│   ├── desktop/                # Desktop components
│   └── users/                  # User management
└── playbooks/                  # Environment-specific playbooks
    ├── desktop.yml             # Desktop workstation setup
    ├── server.yml              # Server setup
    ├── raspberry.yml           # Raspberry Pi setup
    └── cloud.yml               # Cloud instance setup
```

## ⚙️ Configuration

### Customize Variables

Edit `group_vars/all.yml` to customize the installation:

```yaml
# Enable/disable components
install_docker: true
install_golang: true
install_python: true
install_kotlin: true
install_jvm: true
install_dotnet: true
install_desktop: false  # Set to true for desktop components

# Configure users
dev_users:
  - username: developer
    groups: ['sudo', 'docker']
    shell: /usr/bin/zsh

# Customize shell
zsh_theme: frisk
zsh_plugins:
  - git
  - docker
  - golang
  - python
  # ... add more plugins
```

### Host-Specific Configuration

Create `host_vars/hostname.yml` for host-specific settings:

```yaml
# host_vars/my-desktop.yml
install_desktop: true
install_kotlin: false

dev_users:
  - username: myuser
    groups: ['sudo', 'docker']
```

## 🎯 Usage Examples

### Example 1: Setup Desktop Workstation

```bash
# Edit inventory
cat >> inventory/hosts << EOF
[desktops]
my-desktop ansible_host=192.168.1.100 ansible_user=myuser
EOF

# Run desktop playbook
ansible-playbook -i inventory/hosts playbooks/desktop.yml
```

### Example 2: Setup Multiple Servers

```bash
# Edit inventory
cat >> inventory/hosts << EOF
[servers]
dev-server-1 ansible_host=192.168.1.101 ansible_user=developer
dev-server-2 ansible_host=192.168.1.102 ansible_user=developer
EOF

# Run server playbook
ansible-playbook -i inventory/hosts playbooks/server.yml
```

### Example 3: Install Only Docker and Go

```bash
# Use tags to run specific roles
ansible-playbook -i inventory/hosts site.yml --tags "docker,golang"
```

### Example 4: Skip Desktop Components

```bash
# Skip desktop role
ansible-playbook -i inventory/hosts site.yml --skip-tags "desktop"
```

### Example 5: Raspberry Pi Setup

```bash
# Edit inventory
cat >> inventory/hosts << EOF
[raspberry]
rasp-pi-1 ansible_host=192.168.1.201 ansible_user=pi
EOF

# Run Raspberry Pi playbook
ansible-playbook -i inventory/hosts playbooks/raspberry.yml
```

### Example 6: Cloud Instance Setup

```bash
# Edit inventory
cat >> inventory/hosts << EOF
[cloud]
oci-vm-1 ansible_host=xxx.xxx.xxx.xxx ansible_user=ubuntu
EOF

# Run cloud playbook
ansible-playbook -i inventory/hosts playbooks/cloud.yml
```

## 🏷️ Available Tags

Use tags to run specific parts of the playbook:

| Tag | Description |
|-----|-------------|
| `base` | Base packages and timezone |
| `docker` | Docker installation |
| `golang`, `go` | Golang installation |
| `python` | Python installation |
| `kotlin` | Kotlin installation |
| `dotnet` | .NET installation |
| `terminal`, `tools` | Terminal tools (eza, micro, vim) |
| `shell`, `zsh`, `bash` | Shell configuration |
| `desktop` | Desktop components (never runs by default) |
| `users` | User management |
| `always` | Always runs (base role) |

### Tag Usage Examples

```bash
# Install only Docker
ansible-playbook site.yml --tags "docker"

# Install Docker and Golang
ansible-playbook site.yml --tags "docker,golang"

# Install everything except .NET
ansible-playbook site.yml --skip-tags "dotnet"

# Install desktop components
ansible-playbook site.yml --tags "desktop"
```

## 🔍 Validation and Testing

### Dry Run (Check Mode)

```bash
# See what would change without making changes
ansible-playbook -i inventory/hosts site.yml --check

# Show differences
ansible-playbook -i inventory/hosts site.yml --check --diff
```

### Syntax Check

```bash
# Verify playbook syntax
ansible-playbook site.yml --syntax-check
```

### List Tasks

```bash
# List all tasks that would be executed
ansible-playbook -i inventory/hosts site.yml --list-tasks

# List tasks for specific tags
ansible-playbook -i inventory/hosts site.yml --tags "docker" --list-tasks
```

### List Hosts

```bash
# List all hosts in inventory
ansible-playbook -i inventory/hosts site.yml --list-hosts

# List hosts in specific group
ansible-playbook -i inventory/hosts site.yml --limit servers --list-hosts
```

## 🐛 Troubleshooting

### Common Issues

#### Issue: "ansible: command not found"
**Solution**: Install Ansible
```bash
sudo apt update
sudo apt install -y ansible
```

#### Issue: "Permission denied (publickey)"
**Solution**: Setup SSH keys or use password authentication
```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096

# Copy to target host
ssh-copy-id user@hostname

# Or use password (add to inventory)
ansible_ssh_pass=yourpassword
```

#### Issue: "sudo: a password is required"
**Solution**: Configure passwordless sudo or provide sudo password
```bash
# Option 1: Run with --ask-become-pass
ansible-playbook site.yml --ask-become-pass

# Option 2: Add to inventory
ansible_become_pass=yoursudopassword
```

#### Issue: "Module not found"
**Solution**: Ensure Python 3 is installed on target hosts
```bash
# On target host
sudo apt install -y python3
```

#### Issue: "Host key verification failed"
**Solution**: Add host to known_hosts or disable host key checking
```bash
# Option 1: Connect manually first
ssh user@hostname

# Option 2: Disable checking (not recommended for production)
export ANSIBLE_HOST_KEY_CHECKING=False
```

### Debug Mode

```bash
# Run with verbose output
ansible-playbook site.yml -v    # verbose
ansible-playbook site.yml -vv   # more verbose
ansible-playbook site.yml -vvv  # very verbose
ansible-playbook site.yml -vvvv # connection debugging
```

### Test Connection

```bash
# Test if Ansible can connect to hosts
ansible -i inventory/hosts all -m ping

# Test specific group
ansible -i inventory/hosts desktops -m ping
```

## 🔐 Security Best Practices

### Use Ansible Vault for Secrets

```bash
# Create encrypted file
ansible-vault create group_vars/secrets.yml

# Edit encrypted file
ansible-vault edit group_vars/secrets.yml

# Run playbook with vault
ansible-playbook site.yml --ask-vault-pass
```

### SSH Key Authentication

Always use SSH keys instead of passwords:

```bash
# Generate key
ssh-keygen -t ed25519 -C "ansible@mycompany"

# Copy to all hosts
for host in host1 host2 host3; do
    ssh-copy-id user@$host
done
```

## 📊 Performance Optimization

### Parallel Execution

Edit `ansible.cfg`:

```ini
[defaults]
forks = 10  # Run on 10 hosts simultaneously
```

### Fact Caching

```ini
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
```

### Pipelining

```ini
[ssh_connection]
pipelining = True
```

## 🔄 Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy Development Environment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Ansible
        run: |
          sudo apt update
          sudo apt install -y ansible
      
      - name: Run Ansible Playbook
        run: |
          cd ansible
          ansible-playbook -i inventory/hosts site.yml
        env:
          ANSIBLE_HOST_KEY_CHECKING: False
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Galaxy](https://galaxy.ansible.com/) - Community roles
- [Ansible Lint](https://ansible-lint.readthedocs.io/) - Linting tool

## 🤝 Contributing

When adding new roles or playbooks:

1. Follow the existing structure
2. Document all variables
3. Test on multiple distributions
4. Ensure idempotency
5. Add examples to this README

## 📝 Notes

- **Idempotency**: All roles are designed to be idempotent (safe to run multiple times)
- **Distribution Support**: Currently supports Debian-based distributions only
- **Execution Time**: 10-30 minutes depending on components and number of hosts
- **Network**: Requires internet connection for package downloads

---

**For shell script alternative**, see the main [README.md](../README.md) in the project root.
