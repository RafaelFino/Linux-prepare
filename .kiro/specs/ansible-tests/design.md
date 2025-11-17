# Design Document: Ansible Testing Framework

## Overview

This document outlines the design for a comprehensive testing framework for Ansible playbooks and roles in the Linux development environment setup project. The framework will validate Ansible configurations across multiple Linux distributions using Docker-based test environments, ensuring feature parity with existing shell script tests.

### Goals

- Provide automated testing for all Ansible roles and playbooks
- Validate compatibility across Ubuntu 24.04, Debian 13, Xubuntu 24.04, and Linux Mint 22
- Ensure idempotency of all Ansible tasks
- Maintain feature parity with existing shell script tests
- Generate clear, actionable test reports
- Enable fast iteration with targeted testing capabilities

### Non-Goals

- Testing on non-Debian-based distributions
- Performance benchmarking
- Security vulnerability scanning
- Testing on physical hardware (Docker-based only)

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Ansible Test Framework                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Test Runner  │  │   Validator  │  │   Reporter   │     │
│  │              │  │              │  │              │     │
│  │ - Orchestrate│  │ - Syntax     │  │ - Results    │     │
│  │ - Provision  │  │ - Components │  │ - Logs       │     │
│  │ - Execute    │  │ - Idempotency│  │ - Summary    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┴──────────────────┘             │
│                            │                                │
└────────────────────────────┼────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
         ┌──────▼──────┐          ┌──────▼──────┐
         │   Docker    │          │   Ansible   │
         │ Containers  │          │  Playbooks  │
         │             │          │   & Roles   │
         └─────────────┘          └─────────────┘
```

### Component Interaction Flow

```
1. Test Runner
   ├─> Reads test configuration
   ├─> Provisions Docker containers
   ├─> Executes Ansible playbooks
   └─> Collects results

2. Validator
   ├─> Validates syntax (ansible-lint)
   ├─> Checks component installation
   ├─> Verifies idempotency
   └─> Reports findings

3. Reporter
   ├─> Aggregates test results
   ├─> Formats output
   └─> Generates summary
```

## Components and Interfaces

### 1. Test Runner (`tests/ansible/run-ansible-tests.sh`)

**Responsibility**: Orchestrate test execution across all distributions

**Interface**:
```bash
# Run all tests
./tests/ansible/run-ansible-tests.sh

# Test specific distribution
./tests/ansible/run-ansible-tests.sh --distro ubuntu-24.04

# Test specific playbook
./tests/ansible/run-ansible-tests.sh --playbook server.yml

# Test specific role
./tests/ansible/run-ansible-tests.sh --role docker

# Quick test (Ubuntu only)
./tests/ansible/run-ansible-tests.sh --quick

# Derivatives only
./tests/ansible/run-ansible-tests.sh --derivatives
```

**Key Functions**:
- Parse command-line arguments
- Validate prerequisites (Docker, Ansible)
- Provision test containers
- Execute playbooks in containers
- Run validation scripts
- Clean up resources
- Generate test reports

### 2. Syntax Checker (`tests/ansible/scripts/syntax-check.sh`)

**Responsibility**: Validate Ansible syntax and best practices

**Interface**:
```bash
# Check all playbooks and roles
./tests/ansible/scripts/syntax-check.sh

# Check specific playbook
./tests/ansible/scripts/syntax-check.sh --playbook site.yml

# Check specific role
./tests/ansible/scripts/syntax-check.sh --role docker
```

**Validations**:
- YAML syntax validation
- Ansible playbook syntax check
- ansible-lint rule compliance
- Variable definition checks
- Task naming conventions

### 3. Role Tester (`tests/ansible/scripts/test-role.sh`)

**Responsibility**: Test individual roles in isolation

**Interface**:
```bash
# Test specific role
./tests/ansible/scripts/test-role.sh docker ubuntu-24.04

# Test role on all distributions
./tests/ansible/scripts/test-role.sh docker --all-distros
```

**Process**:
1. Create isolated test container
2. Apply role to container
3. Verify role tasks complete successfully
4. Run validation checks
5. Clean up container

### 4. Idempotency Validator (`tests/ansible/scripts/idempotency-check.sh`)

**Responsibility**: Verify playbooks are idempotent

**Interface**:
```bash
# Check idempotency for playbook
./tests/ansible/scripts/idempotency-check.sh site.yml ubuntu-24.04

# Check with exclusions
./tests/ansible/scripts/idempotency-check.sh site.yml ubuntu-24.04 --exclude "task1,task2"
```

**Process**:
1. Run playbook first time (capture output)
2. Run playbook second time (capture output)
3. Parse output for "changed" status
4. Report any non-idempotent tasks
5. Exit with appropriate status code

### 5. Component Validator (`tests/ansible/scripts/validate-ansible.sh`)

**Responsibility**: Validate installed components match requirements

**Interface**:
```bash
# Validate all components in container
docker exec <container> /tmp/validate-ansible.sh

# Validate specific component category
docker exec <container> /tmp/validate-ansible.sh --category docker
```

**Validation Categories**:
- Base commands (git, zsh, vim, curl, wget, htop, btop, jq, fzf, eza, micro)
- Modern CLI tools (bat, httpie, yq, glances, gh, tig, screen, k9s)
- Build tools (cmake, gcc, make)
- Database clients (psql, redis-cli)
- Security & network (openssl, ssh, netcat)
- Programming languages (Docker, Golang, Python, .NET)
- Shell configuration (Oh-My-Zsh, Oh-My-Bash, rc files)
- Aliases and environment variables
- Desktop components (when applicable)

### 6. Test Report Generator (`tests/ansible/scripts/generate-report.sh`)

**Responsibility**: Generate comprehensive test reports

**Interface**:
```bash
# Generate report from test results
./tests/ansible/scripts/generate-report.sh <results_dir>
```

**Output Format**:
```
============================================
  Ansible Test Results
============================================

Distribution Tests:
  ✓ Ubuntu 24.04      [PASSED] (15m 23s)
  ✓ Debian 13         [PASSED] (12m 45s)
  ✓ Xubuntu 24.04     [PASSED] (16m 12s)
  ✗ Linux Mint 22     [FAILED] (8m 34s)

Syntax Checks:
  ✓ Playbooks         [PASSED]
  ✓ Roles             [PASSED]
  ✓ ansible-lint      [PASSED]

Idempotency Tests:
  ✓ site.yml          [PASSED]
  ✓ server.yml        [PASSED]
  ✓ desktop.yml       [PASSED]

Component Validation:
  ✓ Base packages     [PASSED] (45/45)
  ✓ Docker            [PASSED]
  ✓ Programming langs [PASSED]
  ✗ Desktop apps      [FAILED] (2/5)

Summary:
  Total Tests: 48
  Passed: 45
  Failed: 3
  Duration: 52m 54s

Failed Tests:
  - Linux Mint 22: Docker installation failed
  - Desktop apps: VSCode not installed
  - Desktop apps: Chrome not installed
```

## Data Models

### Test Configuration

```yaml
# tests/ansible/config/test-config.yml
distributions:
  - name: ubuntu-24.04
    image: ubuntu:24.04
    dockerfile: tests/ansible/docker/Dockerfile.ubuntu-24.04
    desktop: gnome
    
  - name: debian-13
    image: debian:13
    dockerfile: tests/ansible/docker/Dockerfile.debian-13
    desktop: none
    
  - name: xubuntu-24.04
    image: ubuntu:24.04
    dockerfile: tests/ansible/docker/Dockerfile.xubuntu-24.04
    desktop: xfce
    
  - name: mint-22
    image: linuxmintd/mint22-amd64
    dockerfile: tests/ansible/docker/Dockerfile.mint-22
    desktop: cinnamon

playbooks:
  - name: site.yml
    path: ansible/site.yml
    test_all_distros: true
    
  - name: server.yml
    path: ansible/playbooks/server.yml
    test_all_distros: true
    
  - name: desktop.yml
    path: ansible/playbooks/desktop.yml
    test_distros: [ubuntu-24.04, xubuntu-24.04, mint-22]

roles:
  - name: base
    path: ansible/roles/base
    required: true
    
  - name: docker
    path: ansible/roles/docker
    required: true
    
  - name: golang
    path: ansible/roles/golang
    required: true
    
  - name: python
    path: ansible/roles/python
    required: true
    
  - name: kotlin
    path: ansible/roles/kotlin
    required: true
    
  - name: dotnet
    path: ansible/roles/dotnet
    required: true
    
  - name: terminal-tools
    path: ansible/roles/terminal-tools
    required: true
    
  - name: shell-config
    path: ansible/roles/shell-config
    required: true
    
  - name: desktop
    path: ansible/roles/desktop
    required: false
    desktop_only: true
    
  - name: users
    path: ansible/roles/users
    required: true

validation:
  base_commands:
    - git
    - zsh
    - vim
    - curl
    - wget
    - htop
    - btop
    - jq
    - fzf
    - eza
    - micro
  
  cli_tools:
    - bat
    - httpie
    - yq
    - glances
    - gh
    - tig
    - screen
    - k9s
  
  build_tools:
    - cmake
    - gcc
    - make
  
  database_clients:
    - psql
    - redis-cli
  
  security_network:
    - openssl
    - ssh
    - nc
  
  programming:
    - docker
    - go
    - python3
    - pip3
    - dotnet
  
  shell_config:
    directories:
      - ~/.oh-my-zsh
      - ~/.oh-my-bash
      - ~/.vim_runtime
    files:
      - ~/.zshrc
      - ~/.bashrc
    aliases:
      - ls
      - lt
    env_vars:
      - EDITOR
      - VISUAL
  
  desktop_components:
    - code
    - google-chrome

idempotency:
  exclude_tasks:
    - "Download*"
    - "Fetch*"
    - "Get latest*"
```

### Test Result Model

```json
{
  "test_run_id": "20241116-153045",
  "timestamp": "2024-11-16T15:30:45Z",
  "duration_seconds": 3174,
  "distributions": [
    {
      "name": "ubuntu-24.04",
      "status": "passed",
      "duration_seconds": 923,
      "playbook_tests": [
        {
          "playbook": "site.yml",
          "status": "passed",
          "tasks_total": 87,
          "tasks_ok": 87,
          "tasks_changed": 45,
          "tasks_failed": 0
        }
      ],
      "validation": {
        "base_commands": {"passed": 11, "failed": 0},
        "cli_tools": {"passed": 8, "failed": 0},
        "build_tools": {"passed": 3, "failed": 0},
        "database_clients": {"passed": 2, "failed": 0},
        "security_network": {"passed": 3, "failed": 0},
        "programming": {"passed": 5, "failed": 0},
        "shell_config": {"passed": 10, "failed": 0}
      },
      "idempotency": {
        "status": "passed",
        "changed_tasks": 0
      }
    }
  ],
  "syntax_checks": {
    "yaml_syntax": "passed",
    "ansible_syntax": "passed",
    "ansible_lint": "passed"
  },
  "summary": {
    "total_tests": 48,
    "passed": 45,
    "failed": 3,
    "skipped": 0
  }
}
```

## Directory Structure

```
tests/ansible/
├── README.md                           # Ansible testing documentation
├── run-ansible-tests.sh               # Main test runner
├── test-derivatives.sh                # Test Xubuntu and Mint only
├── quick-test.sh                      # Quick test (Ubuntu only)
├── config/
│   └── test-config.yml                # Test configuration
├── docker/
│   ├── Dockerfile.ubuntu-24.04        # Ubuntu test container
│   ├── Dockerfile.debian-13           # Debian test container
│   ├── Dockerfile.xubuntu-24.04       # Xubuntu test container
│   └── Dockerfile.mint-22             # Mint test container
├── scripts/
│   ├── syntax-check.sh                # Syntax validation
│   ├── test-role.sh                   # Role testing
│   ├── idempotency-check.sh           # Idempotency validation
│   ├── validate-ansible.sh            # Component validation
│   └── generate-report.sh             # Report generation
├── fixtures/
│   ├── inventory/
│   │   └── test-hosts                 # Test inventory file
│   └── vars/
│       └── test-vars.yml              # Test variables
└── results/
    └── .gitkeep                       # Test results directory
```

## Error Handling

### Error Categories

1. **Syntax Errors**
   - YAML syntax errors
   - Ansible syntax errors
   - ansible-lint violations
   - **Action**: Report error with file, line number, and description

2. **Provisioning Errors**
   - Docker not available
   - Container creation failed
   - Network issues
   - **Action**: Report error and exit with status code 1

3. **Execution Errors**
   - Playbook execution failed
   - Task failures
   - Connection issues
   - **Action**: Capture logs, report error, continue with other tests

4. **Validation Errors**
   - Component not installed
   - Configuration incorrect
   - File/directory missing
   - **Action**: Report specific validation failure, mark test as failed

5. **Idempotency Errors**
   - Tasks report "changed" on second run
   - **Action**: Report non-idempotent tasks, mark test as failed

### Error Reporting Format

```
[ERROR] Distribution: ubuntu-24.04
[ERROR] Playbook: site.yml
[ERROR] Task: Install Docker
[ERROR] Message: Package 'docker-ce' not found
[ERROR] Details:
  - Repository: https://download.docker.com/linux/ubuntu
  - GPG Key: Failed to fetch
  - Suggestion: Check network connectivity
[ERROR] Logs: /tmp/ansible-test-results/ubuntu-24.04/site.yml.log
```

## Testing Strategy

### Test Levels

1. **Syntax Tests** (Fast, ~30 seconds)
   - YAML syntax validation
   - Ansible syntax check
   - ansible-lint validation
   - Run before all other tests

2. **Role Tests** (Medium, ~5-10 minutes per role)
   - Test each role in isolation
   - Verify role tasks complete
   - Validate role outcomes
   - Run on Ubuntu 24.04 only

3. **Integration Tests** (Slow, ~15 minutes per distribution)
   - Full playbook execution
   - Component validation
   - Configuration verification
   - Run on all distributions

4. **Idempotency Tests** (Slow, ~25 minutes per distribution)
   - Double execution
   - Change detection
   - Run on Ubuntu 24.04 only

### Test Execution Order

```
1. Syntax Tests (all playbooks and roles)
   └─> If failed: Stop and report

2. Role Tests (each role individually)
   └─> If failed: Continue, report at end

3. Integration Tests (each distribution)
   ├─> Ubuntu 24.04
   ├─> Debian 13
   ├─> Xubuntu 24.04
   └─> Linux Mint 22
   └─> If failed: Continue, report at end

4. Idempotency Tests (Ubuntu 24.04)
   └─> If failed: Report

5. Generate Summary Report
```

### Test Parallelization

- Syntax tests: Sequential (fast enough)
- Role tests: Parallel (up to 4 concurrent)
- Integration tests: Parallel (up to 4 distributions)
- Idempotency tests: Sequential (requires double execution)

## Integration with Existing Tests

### Alignment with Script Tests

The Ansible tests will mirror the existing script test structure:

| Script Test | Ansible Test | Validation |
|-------------|--------------|------------|
| `tests/docker/Dockerfile.ubuntu-24.04` | `tests/ansible/docker/Dockerfile.ubuntu-24.04` | Same components |
| `tests/docker/Dockerfile.debian-13` | `tests/ansible/docker/Dockerfile.debian-13` | Same components |
| `tests/docker/Dockerfile.xubuntu-24.04` | `tests/ansible/docker/Dockerfile.xubuntu-24.04` | Same components + desktop |
| `tests/docker/Dockerfile.mint-22` | `tests/ansible/docker/Dockerfile.mint-22` | Same components |
| `tests/scripts/validate.sh` | `tests/ansible/scripts/validate-ansible.sh` | Same validation logic |
| `tests/run-all-tests.sh` | `tests/ansible/run-ansible-tests.sh` | Same test flow |
| `tests/test-derivatives.sh` | `tests/ansible/test-derivatives.sh` | Same distributions |

### Shared Validation Logic

Both script and Ansible tests will use the same validation criteria:
- Same component lists
- Same command checks
- Same file/directory checks
- Same alias verification
- Same environment variable checks

## Documentation Updates

### Files to Update

1. **`ansible/README.md`**
   - Add "Testing" section
   - Document how to run Ansible tests
   - Explain test validation criteria
   - Provide examples of test execution
   - Link to test documentation

2. **`tests/ansible/README.md`** (new file)
   - Comprehensive testing guide
   - Test execution instructions
   - Troubleshooting guide
   - Test development guide

3. **`tests/README.md`**
   - Add reference to Ansible tests
   - Update test matrix to include Ansible
   - Update execution time estimates

4. **`CONTRIBUTING.md`**
   - Add Ansible testing requirements
   - Document test execution before commits
   - Explain how to add new tests

5. **`README.md`** (project root)
   - Mention Ansible testing capabilities
   - Link to Ansible test documentation

### Documentation Structure

```markdown
# Testing Ansible Playbooks

## Quick Start

```bash
# Run all Ansible tests
./tests/ansible/run-ansible-tests.sh

# Quick test (Ubuntu only)
./tests/ansible/quick-test.sh

# Test derivatives only
./tests/ansible/test-derivatives.sh
```

## Test Coverage

The Ansible tests validate:
- ✅ All 10 Ansible roles
- ✅ All 4 playbooks (site, server, desktop, cloud)
- ✅ 4 Linux distributions (Ubuntu, Debian, Xubuntu, Mint)
- ✅ 50+ installed components
- ✅ Shell configuration and aliases
- ✅ Desktop environment detection
- ✅ Idempotency

## Test Execution Time

| Test Type | Duration |
|-----------|----------|
| Syntax checks | ~30 seconds |
| Role tests | ~5-10 minutes per role |
| Integration tests | ~15 minutes per distribution |
| Full test suite | ~80 minutes |

## Validation Criteria

Tests verify the same components as script tests:
- Base commands (git, zsh, vim, curl, wget, htop, btop, jq, fzf, eza, micro)
- Modern CLI tools (bat, httpie, yq, glances, gh, tig, screen, k9s)
- Build tools (cmake, gcc, make)
- Database clients (psql, redis-cli)
- Security & network tools (openssl, ssh, netcat)
- Programming languages (Docker, Golang, Python, .NET)
- Shell configuration (Oh-My-Zsh, Oh-My-Bash, rc files)
- Aliases and environment variables
- Desktop components (when applicable)
```

## Performance Considerations

### Optimization Strategies

1. **Docker Layer Caching**
   - Structure Dockerfiles to maximize cache hits
   - Place frequently changing commands last
   - Use multi-stage builds where appropriate

2. **Parallel Execution**
   - Run distribution tests in parallel
   - Limit concurrent tests to avoid resource exhaustion
   - Use GNU parallel or xargs for parallelization

3. **Incremental Testing**
   - Support testing specific roles/playbooks
   - Skip unchanged components
   - Cache test results when possible

4. **Resource Management**
   - Clean up containers after each test
   - Limit container resource usage
   - Monitor disk space usage

### Expected Performance

- **Syntax checks**: 30 seconds
- **Single role test**: 5-10 minutes
- **Single distribution test**: 15 minutes
- **Full test suite**: 80 minutes
- **Quick test (Ubuntu only)**: 15 minutes
- **Derivatives test**: 30 minutes

## Security Considerations

1. **Container Isolation**
   - Run tests in isolated Docker containers
   - No privileged mode unless required
   - Clean up containers after tests

2. **Secrets Management**
   - No hardcoded credentials in test files
   - Use environment variables for sensitive data
   - Document required secrets

3. **Network Access**
   - Tests require internet access for package downloads
   - Document external dependencies
   - Consider offline testing mode for CI/CD

## Future Enhancements

1. **Additional Distributions**
   - Kubuntu support
   - Lubuntu support
   - Raspberry Pi OS automated testing

2. **Advanced Testing**
   - Performance benchmarking
   - Security scanning
   - Compliance checking

3. **CI/CD Integration**
   - GitHub Actions workflow
   - GitLab CI pipeline
   - Jenkins integration

4. **Test Reporting**
   - HTML report generation
   - JUnit XML output
   - Integration with test reporting tools

5. **Test Coverage**
   - Track test coverage metrics
   - Identify untested components
   - Generate coverage reports
