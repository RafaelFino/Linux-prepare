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
- Ubuntu 22.04 (minimum)
- Debian 13 (recommended)
- Other distributions if applicable

### Automated Testing

```bash
# Run all tests
./tests/run-all-tests.sh

# Test specific distribution
docker build -f tests/docker/Dockerfile.ubuntu-22.04 -t test .
docker run --rm test /tmp/validate.sh
```

### Validation Checklist

- [ ] Script runs without errors
- [ ] All components install correctly
- [ ] Script is idempotent (can run multiple times)
- [ ] Logging is clear and informative
- [ ] Documentation is updated
- [ ] Tests pass

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
- [ ] Tested on Ubuntu 22.04
- [ ] Tested on Debian 13
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
