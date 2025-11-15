#!/bin/bash

# ============================================================================
# Validation Script for Linux Development Environment Setup
# ============================================================================
# This script validates that all components were installed correctly
# ============================================================================

# Colors
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# Counters
PASSED=0
FAILED=0

# Validation function
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

validate_file() {
    local file=$1
    local description=$2
    
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

validate_directory() {
    local dir=$1
    local description=$2
    
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

validate_alias() {
    local alias_name=$1
    local shell_rc=$2
    
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

echo "============================================"
echo "  Validation Tests"
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
echo "--- Programming Languages ---"
validate_command docker "Docker"
validate_command go "Golang" || validate_command /usr/local/go/bin/go "Golang (alt path)"
validate_command python3 "Python3"
validate_command pip3 "Pip3"
validate_command dotnet ".NET"

echo ""
echo "--- Users ---"
validate_user root
validate_user testuser

echo ""
echo "--- Shell Configuration ---"
validate_directory ~/.oh-my-zsh "Oh-My-Zsh"
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
if grep -q "EDITOR=micro" ~/.zshrc 2>/dev/null; then
    echo -e "${GREEN}✓${RESET} EDITOR configured in .zshrc"
    ((PASSED++))
else
    echo -e "${RED}✗${RESET} EDITOR NOT configured in .zshrc"
    ((FAILED++))
fi

if grep -q "VISUAL=micro" ~/.zshrc 2>/dev/null; then
    echo -e "${GREEN}✓${RESET} VISUAL configured in .zshrc"
    ((PASSED++))
else
    echo -e "${RED}✗${RESET} VISUAL NOT configured in .zshrc"
    ((FAILED++))
fi

echo ""
echo "============================================"
echo "  Summary"
echo "============================================"
echo -e "${GREEN}Passed:${RESET} $PASSED"
echo -e "${RED}Failed:${RESET} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}Some tests failed!${RESET}"
    exit 1
fi
