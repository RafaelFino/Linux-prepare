# Contributing to Linux Development Environment Setup

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🤝 How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Search existing issues before creating a new one
- Provide detailed information:
  - Distribution and version
  - Steps to reproduce
  - Expected vs actual behavior
  - Error messages or logs

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes**
   - Test on multiple distributions if possible
   - Ensure idempotency (script can run multiple times)
   - Run validation tests
5. **Commit your changes**
   ```bash
   git commit -m "Add: description of your changes"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**

## 📝 Coding Guidelines

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use meaningful variable names
- Add comments for complex logic
- Follow existing code style
- Use functions for reusable code
- Implement idempotency checks

### Ansible

- Follow Ansible best practices
- Use YAML syntax correctly (2 spaces indentation)
- Make roles idempotent
- Document variables in defaults/main.yml
- Use tags appropriately
- Test playbooks before submitting

### Documentation

- Update README.md for new features
- Add examples for new functionality
- Keep documentation clear and concise
- Use proper markdown formatting

## 🧪 Testing

### Manual Testing

Test your changes on:
- Ubuntu 24.04 (recommended)
- Debian 13 (recommended)
- Xubuntu 24.04 (for desktop detection)
- Linux Mint 22 (for derivative compatibility)
- Other distributions if applicable

### Automated Testing

#### Script Tests

```bash
# Run all script tests
./tests/run-all-tests.sh

# Quick test (Ubuntu only)
./tests/quick-test.sh

# Test derivatives only
./tests/test-derivatives.sh

# Test specific distribution
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test .
docker run --rm test /tmp/validate.sh
```

#### Ansible Tests

```bash
# Run all Ansible tests
./tests/ansible/run-ansible-tests.sh

# Quick test (Ubuntu only)
./tests/ansible/quick-test.sh

# Test derivatives only
./tests/ansible/test-derivatives.sh

# Test specific playbook
./tests/ansible/run-ansible-tests.sh --playbook server.yml

# Test specific role
./tests/ansible/run-ansible-tests.sh --role docker
```

📖 **Para documentação completa de testes Ansible**, veja [tests/ansible/README.md](tests/ansible/README.md)

### Validation Checklist

#### Para Mudanças em Scripts

- [ ] Script runs without errors
- [ ] All components install correctly
- [ ] Script is idempotent (can run multiple times)
- [ ] Logging is clear and informative
- [ ] Documentation is updated
- [ ] Script tests pass (`./tests/run-all-tests.sh`)

#### Para Mudanças em Ansible

- [ ] Playbook/role runs without errors
- [ ] All components install correctly
- [ ] Playbook/role is idempotent
- [ ] YAML syntax is correct
- [ ] ansible-lint passes
- [ ] Variables are documented
- [ ] Documentation is updated
- [ ] Ansible tests pass (`./tests/ansible/run-ansible-tests.sh`)

#### Para Ambos

- [ ] Tested on multiple distributions
- [ ] Desktop detection works correctly (if applicable)
- [ ] No breaking changes to existing functionality
- [ ] Commit messages are clear and descriptive

## 🎯 Areas for Contribution

### High Priority

- Support for additional distributions (Fedora, Arch, etc.)
- Additional programming languages
- Performance optimizations
- Better error handling
- More comprehensive tests

### Medium Priority

- Additional terminal emulators
- More shell themes and plugins
- Cloud provider specific optimizations
- CI/CD integration examples

### Low Priority

- Additional desktop applications
- Custom configurations
- Alternative package managers

## 📋 Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Tested on Ubuntu 24.04
- [ ] Tested on Debian 13
- [ ] Tested on Xubuntu 24.04 (if desktop changes)
- [ ] Tested on Linux Mint 22 (if derivative changes)
- [ ] Tested idempotency
- [ ] Automated tests pass

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Commits are clear and descriptive
```

## 🔍 Code Review Process

1. Maintainer reviews PR
2. Feedback provided if needed
3. Changes requested or approved
4. PR merged after approval

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 💬 Questions?

- Open an issue for questions
- Tag maintainers for urgent matters
- Be respectful and patient

Thank you for contributing! 🎉
