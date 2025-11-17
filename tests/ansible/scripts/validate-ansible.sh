#!/bin/bash

# ============================================================================
# Ansible Component Validation Script
# ============================================================================
# This script validates that all components were installed correctly by
# Ansible playbooks. It mirrors the validation logic from tests/scripts/validate.sh
# ============================================================================

# Colors
GREEN="\033[32m"
RED="\033[31m"
GRAY="\033[90m"
RESET="\033[0m"

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Validation function for commands
validate_command() {
    local cmd=$1
    local description=$2
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${RESET} $description: $cmd is installed"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $description: $cmd is NOT installed"
        ((FAILED++))
        return 1
    fi
}

# Validation function for optional commands
validate_optional_command() {
    local cmd=$1
    local description=$2
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${RESET} $description: $cmd is installed"
        ((PASSED++))
        return 0
    else
        echo -e "${GRAY}⏭${RESET} $description: Not installed (optional)"
        ((SKIPPED++))
        return 0
    fi
}

# Validation function for files
validate_file() {
    local file=$1
    local description=$2
    
    # Expand tilde to home directory
    file="${file/#\~/$HOME}"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${RESET} $description: $file exists"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $description: $file does NOT exist"
        ((FAILED++))
        return 1
    fi
}

# Validation function for directories
validate_directory() {
    local dir=$1
    local description=$2
    
    # Expand tilde to home directory
    dir="${dir/#\~/$HOME}"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${RESET} $description: $dir exists"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $description: $dir does NOT exist"
        ((FAILED++))
        return 1
    fi
}

# Validation function for users
validate_user() {
    local user=$1
    
    if id "$user" &>/dev/null; then
        echo -e "${GREEN}✓${RESET} User $user exists"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} User $user does NOT exist"
        ((FAILED++))
        return 1
    fi
}

# Validation function for aliases
validate_alias() {
    local alias_name=$1
    local shell_rc=$2
    
    # Expand tilde to home directory
    shell_rc="${shell_rc/#\~/$HOME}"
    
    if grep -q "alias $alias_name=" "$shell_rc" 2>/dev/null; then
        echo -e "${GREEN}✓${RESET} Alias $alias_name configured in $shell_rc"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} Alias $alias_name NOT configured in $shell_rc"
        ((FAILED++))
        return 1
    fi
}

# Validation function for environment variables
validate_env_var() {
    local var_name=$1
    local expected_value=$2
    local shell_rc=$3
    
    # Expand tilde to home directory
    shell_rc="${shell_rc/#\~/$HOME}"
    
    if grep -q "$var_name=$expected_value" "$shell_rc" 2>/dev/null; then
        echo -e "${GREEN}✓${RESET} $var_name configured in $shell_rc"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $var_name NOT configured in $shell_rc"
        ((FAILED++))
        return 1
    fi
}

echo "============================================"
echo "  Ansible Component Validation"
echo "============================================"
echo ""

echo "--- Base Commands ---"
validate_command git "Git"
validate_command zsh "Zsh"
validate_command vim "Vim"
validate_command curl "Curl"
validate_command wget "Wget"
validate_command htop "Htop"
validate_command btop "Btop"
validate_command jq "JQ"
validate_command fzf "FZF"
validate_command eza "eza"
validate_command micro "Micro"

echo ""
echo "--- Modern CLI Tools ---"
# bat can be installed as 'bat' or 'batcat' depending on distribution
if command -v bat &> /dev/null; then
    validate_command bat "bat"
elif command -v batcat &> /dev/null; then
    echo -e "${GREEN}✓${RESET} bat: batcat is installed (Ubuntu/Debian naming)"
    ((PASSED++))
else
    echo -e "${RED}✗${RESET} bat: NOT installed"
    ((FAILED++))
fi
validate_command httpie "httpie"
validate_command yq "yq"
validate_command glances "glances"
validate_optional_command dust "dust"
validate_command gh "GitHub CLI"
validate_command tig "tig"
validate_command screen "screen"
validate_command k9s "k9s"
validate_optional_command tldr "tldr"
validate_optional_command neofetch "neofetch"

echo ""
echo "--- Build Tools ---"
validate_command cmake "cmake"
validate_command gcc "gcc (build-essential)"
validate_command make "make (build-essential)"

echo ""
echo "--- Database Clients ---"
validate_command psql "PostgreSQL client"
validate_command redis-cli "Redis CLI"

echo ""
echo "--- Security & Network ---"
validate_command openssl "OpenSSL"
validate_command ssh "OpenSSH"
validate_command nc "netcat"

echo ""
echo "--- Programming Languages ---"
validate_command docker "Docker"
# Go is installed in /usr/local/go/bin, check both locations
if command -v go &> /dev/null; then
    validate_command go "Golang"
elif command -v /usr/local/go/bin/go &> /dev/null; then
    echo -e "${GREEN}✓${RESET} Golang: /usr/local/go/bin/go is installed"
    ((PASSED++))
else
    echo -e "${RED}✗${RESET} Golang: NOT installed"
    ((FAILED++))
fi
validate_command python3 "Python3"
validate_command pip3 "Pip3"
if command -v dotnet &> /dev/null; then
    validate_command dotnet ".NET"
else
    echo -e "${GRAY}⏭${RESET} .NET: Not installed (may have been skipped)"
    ((SKIPPED++))
fi

echo ""
echo "--- Users ---"
validate_user root
validate_user testuser

echo ""
echo "--- Shell Configuration ---"
validate_directory ~/.oh-my-zsh "Oh-My-Zsh"
validate_directory ~/.oh-my-bash "Oh-My-Bash"
validate_file ~/.zshrc ".zshrc"
validate_file ~/.bashrc ".bashrc"
validate_directory ~/.vim_runtime "Vim Runtime"

echo ""
echo "--- Aliases ---"
validate_alias ls ~/.zshrc
validate_alias lt ~/.zshrc
validate_alias ls ~/.bashrc
validate_alias lt ~/.bashrc

echo ""
echo "--- Environment Variables ---"
validate_env_var EDITOR micro ~/.zshrc
validate_env_var VISUAL micro ~/.zshrc

echo ""
echo "--- Desktop Components (if applicable) ---"
# Desktop components are only checked if XDG_CURRENT_DESKTOP is set
if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    echo "Desktop environment detected: $XDG_CURRENT_DESKTOP"
    
    if command -v code &> /dev/null; then
        validate_command code "VSCode"
    else
        echo -e "${GRAY}⏭${RESET} VSCode: Not installed (optional for desktop)"
        ((SKIPPED++))
    fi
    
    if command -v google-chrome &> /dev/null; then
        validate_command google-chrome "Google Chrome"
    else
        echo -e "${GRAY}⏭${RESET} Google Chrome: Not installed (optional for desktop)"
        ((SKIPPED++))
    fi
    
    if command -v terminator &> /dev/null; then
        validate_optional_command terminator "Terminator"
    fi
    
    if command -v alacritty &> /dev/null; then
        validate_optional_command alacritty "Alacritty"
    fi
else
    echo -e "${GRAY}⏭${RESET} No desktop environment detected (server mode)"
    ((SKIPPED++))
fi

echo ""
echo "============================================"
echo "  Validation Summary"
echo "============================================"
echo -e "${GREEN}Passed:${RESET} $PASSED"
echo -e "${RED}Failed:${RESET} $FAILED"
echo -e "${GRAY}Skipped:${RESET} $SKIPPED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All required validations passed!${RESET}"
    exit 0
else
    echo -e "${RED}Some validations failed!${RESET}"
    exit 1
fi
