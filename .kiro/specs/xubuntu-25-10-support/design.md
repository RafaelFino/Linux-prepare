# Design Document

## Overview

Este documento descreve o design para adicionar suporte completo ao Xubuntu 25.10 no projeto Linux-prepare, incluindo refatoração modular do script principal, melhorias na instalação de componentes específicos por versão, e integração completa de testes automatizados.

O design aborda tanto a adição da nova distribuição quanto melhorias arquiteturais significativas que beneficiarão todo o projeto.

## Architecture

### Current Architecture Issues

O script `prepare.sh` atual tem aproximadamente 2000+ linhas e múltiplas responsabilidades:
- Detecção de sistema e ambiente
- Instalação de pacotes base
- Configuração Docker
- Instalação de linguagens (Go, Python, .NET, Kotlin, JVM)
- Configuração de terminal (Zsh, Oh-My-Zsh)
- Instalação de componentes desktop
- Gerenciamento de usuários

### New Modular Architecture

```
scripts/
├── prepare.sh                    # Main orchestrator (simplified)
├── modules/                      # New modular components
│   ├── system-detection.sh       # OS/Desktop detection
│   ├── base-packages.sh          # Base system packages
│   ├── docker-install.sh         # Docker installation
│   ├── languages/                # Programming languages
│   │   ├── golang-install.sh
│   │   ├── python-install.sh
│   │   ├── dotnet-install.sh
│   │   └── jvm-kotlin-install.sh
│   ├── terminal-config.sh        # Terminal and shell setup
│   ├── desktop-components.sh     # Desktop applications
│   └── user-management.sh        # User creation and configuration
├── lib/                          # Shared utilities
│   ├── logging.sh                # Logging functions
│   ├── package-utils.sh          # Package management utilities
│   └── version-detection.sh      # Version-specific logic
└── add-opt.sh                    # Optional tools (unchanged)
```

### Version-Specific Component Detection

```bash
# New version detection system
detect_ubuntu_version() {
    source /etc/os-release
    echo "$VERSION_ID"
}

get_package_name_by_version() {
    local component="$1"
    local version="$2"
    
    case "$component" in
        "ls_replacement")
            if version_compare "$version" "24.04" ">="; then
                echo "eza"
            else
                echo "exa"
            fi
            ;;
        "docker_repo")
            get_docker_repo_for_version "$version"
            ;;
    esac
}
```

## Components and Interfaces

### 1. Main Orchestrator (prepare.sh)

**Responsibilities:**
- Parse command line arguments
- Load and execute modules in correct order
- Handle global error conditions
- Maintain backward compatibility

**Interface:**
```bash
# Simplified main script structure
#!/usr/bin/env bash
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/version-detection.sh"

# Parse arguments (existing logic)
parse_arguments "$@"

# Execute modules in order
execute_module "system-detection"
execute_module "base-packages"
[ "$INSTALL_DOCKER" = "true" ] && execute_module "docker-install"
[ "$INSTALL_GO" = "true" ] && execute_module "languages/golang-install"
# ... other modules
```

### 2. System Detection Module

**File:** `modules/system-detection.sh`

**Responsibilities:**
- Detect Linux distribution and version
- Detect desktop environment
- Set global environment variables
- Validate system compatibility

**Key Functions:**
```bash
detect_distribution()
detect_desktop_environment()
detect_ubuntu_version()
set_global_environment_vars()
validate_system_compatibility()
```

### 3. Version-Specific Package Management

**File:** `lib/version-detection.sh`

**Responsibilities:**
- Map package names based on Ubuntu/Xubuntu version
- Handle Docker repository selection
- Manage version-specific workarounds

**Key Functions:**
```bash
get_eza_package_name()      # Returns "eza" for 24.04+, "exa" for 22.04
get_docker_repo_config()    # Returns version-specific Docker repo
version_compare()           # Utility for version comparison
```

### 4. Docker Installation Module

**File:** `modules/docker-install.sh`

**Responsibilities:**
- Version-specific Docker installation
- Repository configuration based on Ubuntu version
- Pop!_OS specific workarounds

**Key Functions:**
```bash
configure_docker_repository()
install_docker_engine()
configure_docker_compose()
setup_docker_user_permissions()
```

### 5. Font Management Improvements

**File:** `modules/desktop-components.sh`

**Responsibilities:**
- Create user-specific temporary directories
- Download and install fonts safely
- Clean up temporary files

**Improved Font Installation:**
```bash
install_fonts_for_user() {
    local user="$1"
    local home_dir=$(get_user_home "$user")
    local temp_dir="$home_dir/.tmp-fonts-$$"
    
    # Create temporary directory in user home
    mkdir -p "$temp_dir"
    
    # Download and install fonts
    download_fonts "$temp_dir"
    install_fonts_from_dir "$temp_dir"
    
    # Clean up
    rm -rf "$temp_dir"
}
```

## Data Models

### System Information Structure

```bash
# Global variables set by system-detection module
DETECTED_OS=""           # ubuntu, debian, etc.
DETECTED_VERSION=""      # 24.04, 25.10, etc.
DETECTED_CODENAME=""     # noble, oracular, etc.
DETECTED_DESKTOP=""      # GNOME, XFCE, KDE, etc.
IS_DESKTOP_ENV=""        # true/false
IS_POPOS=""             # true/false for Pop!_OS specific handling
```

### Module Configuration Structure

```bash
# Each module can define its own configuration
declare -A MODULE_CONFIG=(
    ["docker_repo_url"]=""
    ["eza_package_name"]=""
    ["requires_desktop"]=""
    ["supported_versions"]=""
)
```

## Error Handling

### Module-Level Error Handling

Each module will implement consistent error handling:

```bash
# Standard module template
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"

MODULE_NAME="$(basename "$0" .sh)"

module_main() {
    log_info "Starting $MODULE_NAME module"
    
    # Module-specific logic here
    
    log_success "$MODULE_NAME module completed"
}

# Error trap
trap 'log_error "$MODULE_NAME module failed at line $LINENO"' ERR

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    module_main "$@"
fi
```

### Rollback Capabilities

For critical modules like Docker installation:

```bash
rollback_docker_installation() {
    log_warning "Rolling back Docker installation"
    apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/keyrings/docker.gpg
}
```

## Testing Strategy

### 1. Xubuntu 25.10 Test Integration

**New Dockerfile:** `tests/docker/Dockerfile.xubuntu-25.10`

```dockerfile
FROM ubuntu:25.10

ENV DEBIAN_FRONTEND=noninteractive

# Install sudo and basic tools
RUN apt-get update && \
    apt-get install -y sudo curl wget git ca-certificates gnupg && \
    apt-get clean

# Simulate Xubuntu 25.10 environment
RUN apt-get update && \
    apt-get install -y xfce4-session --no-install-recommends && \
    apt-get clean

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set environment variables for Xubuntu 25.10
ENV XDG_CURRENT_DESKTOP=XFCE
ENV UBUNTU_VERSION=25.10

# Copy and run installation script
COPY ./scripts/prepare.sh /tmp/prepare.sh
RUN chmod +x /tmp/prepare.sh
RUN /tmp/prepare.sh -u=testuser

# Copy validation script
COPY ./tests/scripts/validate.sh /tmp/validate.sh
RUN chmod +x /tmp/validate.sh

WORKDIR /home/testuser
CMD ["/bin/bash"]
```

### 2. Module Testing

Each module will be testable independently:

```bash
# Test individual modules
./tests/test-module.sh docker-install
./tests/test-module.sh languages/golang-install
```

### 3. Integration with Existing Test Framework

**Updated test-derivatives.sh:**
```bash
#!/bin/bash
# Test Ubuntu derivatives including Xubuntu 25.10

DISTRIBUTIONS=(
    "xubuntu-24.04"
    "xubuntu-25.10"    # New addition
    "mint-22"
    "popos-22.04"
)
```

### 4. Version-Specific Testing

```bash
# Test version detection logic
test_version_detection() {
    # Mock different Ubuntu versions
    test_eza_package_selection "22.04" "exa"
    test_eza_package_selection "24.04" "eza"
    test_eza_package_selection "25.10" "eza"
}
```

## Implementation Phases

### Phase 1: Modular Refactoring
1. Create module directory structure
2. Extract system detection logic
3. Extract Docker installation logic
4. Update main prepare.sh to use modules
5. Ensure backward compatibility

### Phase 2: Version-Specific Improvements
1. Implement version detection utilities
2. Add eza/exa package selection logic
3. Improve Docker repository configuration
4. Enhance font installation with proper temp directory management

### Phase 3: Xubuntu 25.10 Support
1. Create Dockerfile for Xubuntu 25.10
2. Add to test matrix
3. Update documentation
4. Validate all components work correctly

### Phase 4: Documentation and Integration
1. Update README.md with new architecture
2. Document each module's purpose
3. Update compatibility matrix
4. Create module development guidelines

## Compatibility Considerations

### Backward Compatibility

The refactored `prepare.sh` must maintain 100% backward compatibility:
- All existing command-line flags work unchanged
- Same installation behavior and output
- Same error handling and logging
- No breaking changes for existing users

### Distribution Support Matrix

| Distribution | Version | Status | Notes |
|-------------|---------|--------|-------|
| Ubuntu | 22.04 | ✅ Existing | Uses "exa" package |
| Ubuntu | 24.04 | ✅ Existing | Uses "eza" package |
| Xubuntu | 24.04 | ✅ Existing | XFCE desktop detection |
| Xubuntu | 25.10 | 🆕 New | Target of this spec |
| Debian | 13 | ✅ Existing | Server-focused |
| Linux Mint | 22 | ✅ Existing | Cinnamon desktop |
| Pop!_OS | 22.04 | ✅ Existing | Special workarounds |

## Security Considerations

### Temporary File Management

- Use user-specific temporary directories instead of shared /tmp
- Implement proper cleanup even on script failure
- Set appropriate permissions on temporary directories

### Module Isolation

- Each module runs with minimal required permissions
- Modules cannot interfere with each other's state
- Clear separation of concerns reduces attack surface

## Performance Optimizations

### Parallel Module Execution

Future enhancement possibility:
```bash
# Modules that can run in parallel
run_parallel_modules() {
    execute_module "languages/golang-install" &
    execute_module "languages/python-install" &
    execute_module "languages/dotnet-install" &
    wait  # Wait for all background jobs
}
```

### Caching and Idempotency

- Each module checks if its work is already done
- Skip unnecessary downloads and installations
- Cache package availability checks

This design provides a solid foundation for adding Xubuntu 25.10 support while significantly improving the overall architecture and maintainability of the Linux-prepare project.