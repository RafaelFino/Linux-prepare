#!/usr/bin/env bats

# Unit tests for documentation completeness
# Verifies that README.md contains all required parameter documentation,
# usage examples, and logging format information

setup() {
    # Read the README.md file for testing (handle both project root and tests/unit directory)
    if [[ -f "README.md" ]]; then
        README_FILE="README.md"
    elif [[ -f "../../README.md" ]]; then
        README_FILE="../../README.md"
    else
        skip "README.md not found"
    fi
    README_CONTENT=$(cat "$README_FILE")
}

# Test 1: README.md exists
@test "README.md file exists" {
    [[ -f "README.md" ]] || [[ -f "../../README.md" ]]
}

# Test 2: README contains main title
@test "README contains main title 'Env Prepare System'" {
    echo "$README_CONTENT" | grep -q "# Env Prepare System"
}

# Test 3: README contains Features section
@test "README contains Features section" {
    echo "$README_CONTENT" | grep -q "## Features"
}

# Test 4: README contains Prerequisites section
@test "README contains Prerequisites section" {
    echo "$README_CONTENT" | grep -q "## Prerequisites"
}

# Test 5: README contains Installation section
@test "README contains Installation section" {
    echo "$README_CONTENT" | grep -q "## Installation"
}

# Test 6: README contains Usage section
@test "README contains Usage section" {
    echo "$README_CONTENT" | grep -q "## Usage"
}

# Test 7: README contains Basic Syntax documentation
@test "README documents basic syntax with sudo" {
    echo "$README_CONTENT" | grep -q "sudo ./prepare.sh"
}

# Test 8: README documents -u parameter
@test "README documents -u parameter for user creation" {
    echo "$README_CONTENT" | grep -q "\-u=user1,user2,userN"
}

# Test 9: README documents -u parameter format
@test "README documents -u parameter format with comma-separated list" {
    echo "$README_CONTENT" | grep -q "comma-separated list"
}

# Test 10: README documents -u parameter valid characters
@test "README documents valid characters for usernames" {
    echo "$README_CONTENT" | grep -q "Lowercase letters, digits, hyphens, underscores"
}

# Test 11: README documents -u parameter username rules
@test "README documents username rules" {
    echo "$README_CONTENT" | grep -q "Must start with a letter or underscore"
}

# Test 12: README documents -u parameter example
@test "README provides -u parameter example" {
    echo "$README_CONTENT" | grep -q "\-u=dev,admin,testuser"
}

# Test 13: README documents -docker parameter
@test "README documents -docker parameter" {
    echo "$README_CONTENT" | grep -q "\-docker"
}

# Test 14: README documents -docker parameter description
@test "README describes -docker parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install Docker and configure for non-root access"
}

# Test 15: README documents -golang parameter
@test "README documents -golang parameter" {
    echo "$README_CONTENT" | grep -q "\-golang"
}

# Test 16: README documents -golang parameter description
@test "README describes -golang parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install Go programming language"
}

# Test 17: README documents -jvm parameter
@test "README documents -jvm parameter" {
    echo "$README_CONTENT" | grep -q "\-jvm"
}

# Test 18: README documents -jvm parameter description
@test "README describes -jvm parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install Java Virtual Machine using SDKMAN"
}

# Test 19: README documents -vscode parameter
@test "README documents -vscode parameter" {
    echo "$README_CONTENT" | grep -q "\-vscode"
}

# Test 20: README documents -vscode parameter description
@test "README describes -vscode parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install Visual Studio Code"
}

# Test 21: README documents -fonts parameter
@test "README documents -fonts parameter" {
    echo "$README_CONTENT" | grep -q "\-fonts"
}

# Test 22: README documents -fonts parameter description
@test "README describes -fonts parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install Nerd Fonts and Powerline Fonts"
}

# Test 23: README documents -terminator parameter
@test "README documents -terminator parameter" {
    echo "$README_CONTENT" | grep -q "\-terminator"
}

# Test 24: README documents -terminator parameter description
@test "README describes -terminator parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install Terminator terminal emulator"
}

# Test 25: README documents -dotnet parameter
@test "README documents -dotnet parameter" {
    echo "$README_CONTENT" | grep -q "\-dotnet"
}

# Test 26: README documents -dotnet parameter description
@test "README describes -dotnet parameter functionality" {
    echo "$README_CONTENT" | grep -q "Install .NET runtime and SDK"
}

# Test 27: README documents -h/--help parameter
@test "README documents -h and --help parameters" {
    echo "$README_CONTENT" | grep -q "\-h, --help"
}

# Test 28: README contains Usage Examples section
@test "README contains Usage Examples section" {
    echo "$README_CONTENT" | grep -q "### Usage Examples"
}

# Test 29: README provides example for base packages only
@test "README provides example for base packages installation" {
    echo "$README_CONTENT" | grep -q "Install Base Packages Only"
}

# Test 30: README provides example for user creation
@test "README provides example for user creation with base packages" {
    echo "$README_CONTENT" | grep -q "Create Users with Base Packages"
}

# Test 31: README provides example for Docker installation
@test "README provides example for Docker installation" {
    echo "$README_CONTENT" | grep -q "Install Base Packages and Docker"
}

# Test 32: README provides example for multiple tools
@test "README provides example for multiple tools installation" {
    echo "$README_CONTENT" | grep -q "Create User and Install Multiple Tools"
}

# Test 33: README provides example for full environment
@test "README provides example for full development environment" {
    echo "$README_CONTENT" | grep -q "Full Development Environment"
}

# Test 34: README provides example for optional modules only
@test "README provides example for optional modules only" {
    echo "$README_CONTENT" | grep -q "Install Only Optional Modules"
}

# Test 35: README contains Base Packages section
@test "README contains Base Packages section" {
    echo "$README_CONTENT" | grep -q "## Base Packages"
}

# Test 36: README lists system tools
@test "README lists system tools in base packages" {
    echo "$README_CONTENT" | grep -q "### System Tools"
}

# Test 37: README lists development tools
@test "README lists development tools in base packages" {
    echo "$README_CONTENT" | grep -q "### Development Tools"
}

# Test 38: README lists editors
@test "README lists editors in base packages" {
    echo "$README_CONTENT" | grep -q "### Editors"
}

# Test 39: README lists monitoring utilities
@test "README lists monitoring utilities in base packages" {
    echo "$README_CONTENT" | grep -q "### Monitoring & Utilities"
}

# Test 40: README lists security tools
@test "README lists security tools in base packages" {
    echo "$README_CONTENT" | grep -q "### Security & Certificates"
}

# Test 41: README lists modern alternatives
@test "README lists modern alternatives in base packages" {
    echo "$README_CONTENT" | grep -q "### Modern Alternatives"
}

# Test 42: README contains Configuration section
@test "README contains Configuration section" {
    echo "$README_CONTENT" | grep -q "## Configuration"
}

# Test 43: README documents shell configuration
@test "README documents shell configuration" {
    echo "$README_CONTENT" | grep -q "### Shell Configuration"
}

# Test 44: README documents Oh-My-Zsh configuration
@test "README documents Oh-My-Zsh configuration" {
    echo "$README_CONTENT" | grep -q "#### Oh-My-Zsh"
}

# Test 45: README documents agnoster theme
@test "README documents agnoster theme for zsh" {
    echo "$README_CONTENT" | grep -q "agnoster"
}

# Test 46: README documents Oh-My-Bash configuration
@test "README documents Oh-My-Bash configuration" {
    echo "$README_CONTENT" | grep -q "#### Oh-My-Bash"
}

# Test 47: README documents user profile configuration
@test "README documents user profile configuration" {
    echo "$README_CONTENT" | grep -q "### User Profile Configuration"
}

# Test 48: README documents eza aliases
@test "README documents eza aliases" {
    echo "$README_CONTENT" | grep -q "#### Eza Aliases"
}

# Test 49: README documents ls alias
@test "README documents ls alias configuration" {
    echo "$README_CONTENT" | grep -q "alias ls="
}

# Test 50: README documents lt alias
@test "README documents lt alias configuration" {
    echo "$README_CONTENT" | grep -q "alias lt="
}

# Test 51: README documents vim configuration
@test "README documents vim configuration" {
    echo "$README_CONTENT" | grep -q "#### Vim Configuration"
}

# Test 52: README documents awesome vim
@test "README documents awesome vim configuration" {
    echo "$README_CONTENT" | grep -q "Awesome Vim"
}

# Test 53: README documents vim line numbers
@test "README documents vim line numbers" {
    echo "$README_CONTENT" | grep -q "Line Numbers"
}

# Test 54: README contains Logging section
@test "README contains Logging section" {
    echo "$README_CONTENT" | grep -q "## Logging"
}

# Test 55: README documents log format
@test "README documents log format" {
    echo "$README_CONTENT" | grep -q "### Log Format"
}

# Test 56: README documents ISO 8601 timestamp format
@test "README documents ISO 8601 timestamp format" {
    echo "$README_CONTENT" | grep -q "YYYY-MM-DD HH:MM:SS"
}

# Test 57: README documents log format components
@test "README documents log format components" {
    echo "$README_CONTENT" | grep -q "module_name"
}

# Test 58: README documents log levels and colors
@test "README documents log levels and colors" {
    echo "$README_CONTENT" | grep -q "### Log Levels and Colors"
}

# Test 59: README documents INFO level
@test "README documents INFO log level" {
    echo "$README_CONTENT" | grep -q "INFO"
}

# Test 60: README documents WARN level
@test "README documents WARN log level" {
    echo "$README_CONTENT" | grep -q "WARN"
}

# Test 61: README documents DEBUG level
@test "README documents DEBUG log level" {
    echo "$README_CONTENT" | grep -q "DEBUG"
}

# Test 62: README documents ERROR level
@test "README documents ERROR log level" {
    echo "$README_CONTENT" | grep -q "ERROR"
}

# Test 63: README documents color coding
@test "README documents color coding for log levels" {
    echo "$README_CONTENT" | grep -q "Color"
}

# Test 64: README documents INFO color as green
@test "README documents INFO color as green" {
    echo "$README_CONTENT" | grep -q "Green"
}

# Test 65: README documents WARN color as yellow
@test "README documents WARN color as yellow" {
    echo "$README_CONTENT" | grep -q "Yellow"
}

# Test 66: README documents DEBUG color as blue
@test "README documents DEBUG color as blue" {
    echo "$README_CONTENT" | grep -q "Blue"
}

# Test 67: README documents ERROR color as red
@test "README documents ERROR color as red" {
    echo "$README_CONTENT" | grep -q "Red"
}

# Test 68: README provides example log output
@test "README provides example log output" {
    echo "$README_CONTENT" | grep -q "### Example Log Output"
}

# Test 69: README documents module execution timing
@test "README documents module execution timing" {
    echo "$README_CONTENT" | grep -q "### Module Execution Timing"
}

# Test 70: README documents "Installing..." message
@test "README documents Installing message" {
    echo "$README_CONTENT" | grep -q "Installing..."
}

# Test 71: README documents "Successful in X seconds!" message
@test "README documents Successful message with timing" {
    echo "$README_CONTENT" | grep -q "Successful in X seconds!"
}

# Test 72: README contains Troubleshooting section
@test "README contains Troubleshooting section" {
    echo "$README_CONTENT" | grep -q "## Troubleshooting"
}

# Test 73: README documents permission denied error
@test "README documents permission denied error" {
    echo "$README_CONTENT" | grep -q "Permission Denied"
}

# Test 74: README documents invalid username error
@test "README documents invalid username error" {
    echo "$README_CONTENT" | grep -q "Invalid Username"
}

# Test 75: README documents module installation failed error
@test "README documents module installation failed error" {
    echo "$README_CONTENT" | grep -q "Module Installation Failed"
}

# Test 76: README documents package not found error
@test "README documents package not found error" {
    echo "$README_CONTENT" | grep -q "Package Not Found"
}

# Test 77: README contains Architecture section
@test "README contains Architecture section" {
    echo "$README_CONTENT" | grep -q "## Architecture"
}

# Test 78: README documents directory structure
@test "README documents directory structure" {
    echo "$README_CONTENT" | grep -q "prepare.sh"
}

# Test 79: README documents util/log.sh
@test "README documents util/log.sh in architecture" {
    echo "$README_CONTENT" | grep -q "util/log.sh"
}

# Test 80: README documents modules directory
@test "README documents modules directory in architecture" {
    echo "$README_CONTENT" | grep -q "modules/"
}

# Test 81: README contains Contributing section
@test "README contains Contributing section" {
    echo "$README_CONTENT" | grep -q "## Contributing"
}

# Test 82: README contains License section
@test "README contains License section" {
    echo "$README_CONTENT" | grep -q "## License"
}

# Test 83: README contains Support section
@test "README contains Support section" {
    echo "$README_CONTENT" | grep -q "## Support"
}

# Test 84: README has reasonable length (not empty)
@test "README has substantial content" {
    local line_count
    line_count=$(echo "$README_CONTENT" | wc -l)
    [ "$line_count" -gt 100 ]
}

# Test 85: README uses proper markdown formatting
@test "README uses proper markdown headers" {
    echo "$README_CONTENT" | grep -q "^# "
    echo "$README_CONTENT" | grep -q "^## "
}

# Test 86: README contains code blocks
@test "README contains code examples" {
    echo "$README_CONTENT" | grep -q '```bash'
}

# Test 87: README documents all 7 optional modules
@test "README documents all 7 optional modules" {
    local module_count=0
    if echo "$README_CONTENT" | grep -q "\-docker"; then
        module_count=$((module_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "\-golang"; then
        module_count=$((module_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "\-jvm"; then
        module_count=$((module_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "\-vscode"; then
        module_count=$((module_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "\-fonts"; then
        module_count=$((module_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "\-terminator"; then
        module_count=$((module_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "\-dotnet"; then
        module_count=$((module_count + 1))
    fi
    [ "$module_count" -eq 7 ]
}

# Test 88: README documents all base package categories
@test "README documents all base package categories" {
    local category_count=0
    if echo "$README_CONTENT" | grep -q "### System Tools"; then
        category_count=$((category_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "### Development Tools"; then
        category_count=$((category_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "### Editors"; then
        category_count=$((category_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "### Monitoring & Utilities"; then
        category_count=$((category_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "### Security & Certificates"; then
        category_count=$((category_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "### Modern Alternatives"; then
        category_count=$((category_count + 1))
    fi
    [ "$category_count" -eq 6 ]
}

# Test 89: README documents all log levels
@test "README documents all 4 log levels" {
    local level_count=0
    if echo "$README_CONTENT" | grep -q "| INFO"; then
        level_count=$((level_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "| WARN"; then
        level_count=$((level_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "| DEBUG"; then
        level_count=$((level_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "| ERROR"; then
        level_count=$((level_count + 1))
    fi
    [ "$level_count" -eq 4 ]
}

# Test 90: README contains at least 6 usage examples
@test "README contains multiple usage examples" {
    local example_count=0
    if echo "$README_CONTENT" | grep -q "sudo ./prepare.sh$"; then
        example_count=$((example_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "sudo ./prepare.sh -u="; then
        example_count=$((example_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "sudo ./prepare.sh -docker"; then
        example_count=$((example_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "sudo ./prepare.sh -u=developer"; then
        example_count=$((example_count + 1))
    fi
    if echo "$README_CONTENT" | grep -q "sudo ./prepare.sh -u=dev,admin"; then
        example_count=$((example_count + 1))
    fi
    [ "$example_count" -ge 5 ]
}
