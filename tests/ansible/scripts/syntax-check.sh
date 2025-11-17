#!/bin/bash

# ============================================================================
# Ansible Syntax Check Script
# ============================================================================
# This script validates Ansible playbooks and roles for syntax errors and
# best practices using YAML validation, ansible-playbook --syntax-check,
# and ansible-lint.
# ============================================================================

# Don't use set -e because arithmetic operations can return non-zero
set -u

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Parse command-line arguments
SPECIFIC_PLAYBOOK=""
SPECIFIC_ROLE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --playbook)
            SPECIFIC_PLAYBOOK="$2"
            shift 2
            ;;
        --role)
            SPECIFIC_ROLE="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "  Ansible Syntax Validation"
echo "============================================"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "--- Checking Prerequisites ---"
    
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}✗ ansible-playbook not found${RESET}"
        echo "  Please install Ansible: sudo apt install ansible"
        exit 1
    fi
    echo -e "${GREEN}✓ ansible-playbook found${RESET}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ python3 not found${RESET}"
        exit 1
    fi
    echo -e "${GREEN}✓ python3 found${RESET}"
    
    # ansible-lint is optional but recommended
    if command -v ansible-lint &> /dev/null; then
        echo -e "${GREEN}✓ ansible-lint found${RESET}"
        LINT_AVAILABLE=true
    else
        echo -e "${YELLOW}⚠ ansible-lint not found (optional)${RESET}"
        echo "  Install with: pip3 install ansible-lint"
        LINT_AVAILABLE=false
    fi
    
    echo ""
}

# Validate YAML syntax
validate_yaml() {
    local file=$1
    
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo -e "${GREEN}✓${RESET} YAML syntax: $file"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} YAML syntax: $file"
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | sed 's/^/  /'
        ((FAILED++))
        return 1
    fi
}

# Validate Ansible playbook syntax
validate_ansible_syntax() {
    local playbook=$1
    
    if ansible-playbook "$playbook" --syntax-check &>/dev/null; then
        echo -e "${GREEN}✓${RESET} Ansible syntax: $playbook"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} Ansible syntax: $playbook"
        ansible-playbook "$playbook" --syntax-check 2>&1 | sed 's/^/  /'
        ((FAILED++))
        return 1
    fi
}

# Run ansible-lint
run_ansible_lint() {
    local target=$1
    local type=$2  # "playbook" or "role"
    
    if [ "$LINT_AVAILABLE" = false ]; then
        return 0
    fi
    
    local output
    output=$(ansible-lint "$target" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓${RESET} ansible-lint: $target"
        ((PASSED++))
        return 0
    else
        # Check if there are only warnings
        if echo "$output" | grep -q "WARNING"; then
            echo -e "${YELLOW}⚠${RESET} ansible-lint warnings: $target"
            echo "$output" | sed 's/^/  /'
            ((WARNINGS++))
            return 0
        else
            echo -e "${RED}✗${RESET} ansible-lint: $target"
            echo "$output" | sed 's/^/  /'
            ((FAILED++))
            return 1
        fi
    fi
}

# Check playbooks
check_playbooks() {
    echo "--- Checking Playbooks ---"
    
    cd "$PROJECT_ROOT/ansible"
    
    if [ -n "$SPECIFIC_PLAYBOOK" ]; then
        # Check specific playbook
        if [ ! -f "$SPECIFIC_PLAYBOOK" ]; then
            echo -e "${RED}✗ Playbook not found: $SPECIFIC_PLAYBOOK${RESET}"
            ((FAILED++))
            return 1
        fi
        
        validate_yaml "$SPECIFIC_PLAYBOOK"
        validate_ansible_syntax "$SPECIFIC_PLAYBOOK"
        run_ansible_lint "$SPECIFIC_PLAYBOOK" "playbook"
    else
        # Check all playbooks
        local playbooks=(
            "site.yml"
            "playbooks/server.yml"
            "playbooks/desktop.yml"
            "playbooks/cloud.yml"
            "playbooks/raspberry.yml"
        )
        
        for playbook in "${playbooks[@]}"; do
            if [ -f "$playbook" ]; then
                validate_yaml "$playbook"
                validate_ansible_syntax "$playbook"
                run_ansible_lint "$playbook" "playbook"
            else
                echo -e "${YELLOW}⚠${RESET} Playbook not found: $playbook (skipping)"
            fi
        done
    fi
    
    echo ""
}

# Check roles
check_roles() {
    echo "--- Checking Roles ---"
    
    cd "$PROJECT_ROOT/ansible"
    
    if [ -n "$SPECIFIC_ROLE" ]; then
        # Check specific role
        if [ ! -d "roles/$SPECIFIC_ROLE" ]; then
            echo -e "${RED}✗ Role not found: $SPECIFIC_ROLE${RESET}"
            ((FAILED++))
            return 1
        fi
        
        # Check role YAML files
        if [ -d "roles/$SPECIFIC_ROLE/tasks" ]; then
            for task_file in roles/$SPECIFIC_ROLE/tasks/*.yml; do
                if [ -f "$task_file" ]; then
                    validate_yaml "$task_file"
                fi
            done
        fi
        
        run_ansible_lint "roles/$SPECIFIC_ROLE" "role"
    else
        # Check all roles
        if [ -d "roles" ]; then
            for role_dir in roles/*/; do
                role_name=$(basename "$role_dir")
                
                # Check tasks
                if [ -d "$role_dir/tasks" ]; then
                    for task_file in "$role_dir/tasks"/*.yml; do
                        if [ -f "$task_file" ]; then
                            validate_yaml "$task_file"
                        fi
                    done
                fi
                
                # Check defaults
                if [ -f "$role_dir/defaults/main.yml" ]; then
                    validate_yaml "$role_dir/defaults/main.yml"
                fi
                
                # Check vars
                if [ -f "$role_dir/vars/main.yml" ]; then
                    validate_yaml "$role_dir/vars/main.yml"
                fi
                
                # Check handlers
                if [ -f "$role_dir/handlers/main.yml" ]; then
                    validate_yaml "$role_dir/handlers/main.yml"
                fi
                
                # Check meta
                if [ -f "$role_dir/meta/main.yml" ]; then
                    validate_yaml "$role_dir/meta/main.yml"
                fi
                
                # Run ansible-lint on role
                run_ansible_lint "roles/$role_name" "role"
            done
        fi
    fi
    
    echo ""
}

# Check group_vars and host_vars
check_vars() {
    echo "--- Checking Variables ---"
    
    cd "$PROJECT_ROOT/ansible"
    
    # Check group_vars
    if [ -d "group_vars" ]; then
        for var_file in group_vars/*.yml; do
            if [ -f "$var_file" ]; then
                validate_yaml "$var_file"
            fi
        done
    fi
    
    # Check host_vars
    if [ -d "host_vars" ]; then
        for var_file in host_vars/*.yml; do
            if [ -f "$var_file" ]; then
                validate_yaml "$var_file"
            fi
        done
    fi
    
    echo ""
}

# Main execution
main() {
    check_prerequisites
    check_playbooks
    check_roles
    check_vars
    
    echo "============================================"
    echo "  Syntax Check Summary"
    echo "============================================"
    echo -e "${GREEN}Passed:${RESET} $PASSED"
    echo -e "${RED}Failed:${RESET} $FAILED"
    echo -e "${YELLOW}Warnings:${RESET} $WARNINGS"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All syntax checks passed!${RESET}"
        exit 0
    else
        echo -e "${RED}Some syntax checks failed!${RESET}"
        exit 1
    fi
}

main
