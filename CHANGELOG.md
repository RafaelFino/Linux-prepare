# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-11-15

### Added
- Complete refactor of main script with modern architecture
- Colored logging system in English with timestamps and symbols
- Full idempotency support (safe to run multiple times)
- `--skip-*` arguments for selective component installation
- `--desktop` flag for opt-in desktop components
- Comprehensive help system with detailed examples
- Support for multiple users via `-u=user1,user2`
- Automatic timezone configuration (America/Sao_Paulo)
- Complete Ansible implementation with roles
- Environment-specific scripts (Raspberry Pi, Odroid, OCI, AWS, GitHub, Killercoda)
- Automated testing infrastructure with Docker
- Validation scripts for installation verification
- Comprehensive documentation (README.md, ansible/README.md, CONTRIBUTING.md)

### Changed
- **BREAKING**: Default behavior now installs ALL components (except desktop)
- **BREAKING**: Removed positive installation flags (-docker, -go, etc.)
- **BREAKING**: Desktop components now require explicit `--desktop` flag
- Improved error handling and logging
- Better user management with sudo group assignment
- Enhanced shell configuration with more plugins
- Updated to .NET SDK 8.0
- Modernized aliases using eza instead of exa

### Fixed
- Idempotency issues with multiple script runs
- User creation and group assignment
- Docker group membership
- Shell configuration conflicts
- Font installation on various distributions

### Security
- All downloads use HTTPS
- Proper permission handling
- Secure sudo configuration

## [1.0.0] - 2023-XX-XX

### Added
- Initial release
- Basic installation scripts
- Support for Ubuntu and Debian
- Docker installation
- Golang installation
- Python installation
- JVM installation via SDKMAN
- .NET installation
- Oh-My-Zsh configuration
- Vim configuration
- Desktop components (VSCode, Chrome, fonts)

### Known Issues
- Limited idempotency
- Manual user configuration required
- No automated testing

---

## Version History

- **2.0.0** - Major refactor with modern architecture and full automation
- **1.0.0** - Initial release with basic functionality

## Upgrade Guide

### From 1.x to 2.x

**Breaking Changes:**
1. Command-line arguments changed:
   - Old: `./prepare.sh -docker -go -python`
   - New: `./prepare.sh` (installs everything by default)
   - New: `./prepare.sh --skip-docker --skip-go` (to skip components)

2. Desktop components:
   - Old: Included by default with `-all`
   - New: Requires explicit `--desktop` flag

3. User configuration:
   - Old: Manual configuration
   - New: Automatic with `-u=username`

**Migration Steps:**
1. Review your current usage
2. Update command-line arguments
3. Test in a VM or container first
4. Run new script with appropriate flags

**Benefits of Upgrading:**
- Full idempotency
- Better error handling
- Comprehensive logging
- Ansible support
- Automated testing
- Better documentation
