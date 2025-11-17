#!/bin/bash

# ============================================================================
# Ansible Role Test Script
# ============================================================================
# This script tests individual Ansible roles in isolation by creating a
# minimal test container and applying only the specified role.
# ============================================================================

set -e

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/tests/ansible/config/test-config.yml"

# Parse command-line arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <role_name> [distribution] [--all-distros]"
    echo ""
    echo "Examples:"
    echo "  $0 docker ubuntu-24.04"
    echo "  $0 docker --all-distros"
    exit 1
fi

ROLE_NAME="$1"
DISTRIBUTION=""
ALL_DISTROS=false

shift

while [[ $# -gt 0 ]]; do
    case $1 in
        --all-distros)
            ALL_DISTROS=true
            shift
            ;;
        *)
            DISTRIBUTION="$1"
            shift
            ;;
    esac
done

# Default to ubuntu-24.04 if no distribution specified
if [ -z "$DISTRIBUTION" ] && [ "$ALL_DISTROS" = false ]; then
    DISTRIBUTION="ubuntu-24.04"
fi

echo "============================================"
echo "  Ansible Role Test"
echo "============================================"
echo "Role: $ROLE_NAME"
if [ "$ALL_DISTROS" = true ]; then
    echo "Testing on: All distributions"
else
    echo "Distribution: $DISTRIBUTION"
fi
echo ""

# Check if role exists
cd "$PROJECT_ROOT/ansible"
if [ ! -d "roles/$ROLE_NAME" ]; then
    echo -e "${RED}✗ Role not found: $ROLE_NAME${RESET}"
    echo "Available roles:"
    ls -1 roles/
    exit 1
fi

# Function to test role on a specific distribution
test_role_on_distro() {
    local distro=$1
    local container_name="ansible-test-role-${ROLE_NAME}-${distro}"
    local dockerfile="$PROJECT_ROOT/tests/ansible/docker/Dockerfile.${distro}"
    local image_name="ansible-test-${distro}"
    
    echo "--- Testing on $distro ---"
    
    # Check if Dockerfile exists
    if [ ! -f "$dockerfile" ]; then
        echo -e "${RED}✗ Dockerfile not found: $dockerfile${RESET}"
        return 1
    fi
    
    # Build Docker image
    echo "Building test image..."
    if ! docker build -f "$dockerfile" -t "$image_name" "$PROJECT_ROOT" > /dev/null 2>&1; then
        echo -e "${RED}✗ Failed to build Docker image${RESET}"
        return 1
    fi
    echo -e "${GREEN}✓${RESET} Docker image built"
    
    # Create test container
    echo "Creating test container..."
    if ! docker run -d --name "$container_name" "$image_name" > /dev/null 2>&1; then
        echo -e "${RED}✗ Failed to create container${RESET}"
        return 1
    fi
    echo -e "${GREEN}✓${RESET} Container created"
    
    # Wait for container to be ready
    sleep 2
    
    # Create minimal test playbook
    local test_playbook=$(mktemp)
    cat > "$test_playbook" << EOF
---
- name: Test Role $ROLE_NAME
  hosts: localhost
  connection: local
  become: yes
  
  roles:
    - role: $ROLE_NAME
EOF
    
    # Copy playbook to container
    docker cp "$test_playbook" "$container_name:/tmp/test-role.yml" > /dev/null 2>&1
    
    # Copy ansible directory to container
    docker cp "$PROJECT_ROOT/ansible/roles" "$container_name:/tmp/roles" > /dev/null 2>&1
    docker cp "$PROJECT_ROOT/ansible/group_vars" "$container_name:/tmp/group_vars" > /dev/null 2>&1
    
    # Run playbook in container
    echo "Executing role..."
    if docker exec "$container_name" ansible-playbook /tmp/test-role.yml -i "localhost," -c local > /tmp/role-test-output.log 2>&1; then
        echo -e "${GREEN}✓${RESET} Role executed successfully"
        
        # Run validation if available
        if docker exec "$container_name" test -f /tmp/validate-ansible.sh; then
            echo "Running validation..."
            if docker exec "$container_name" /tmp/validate-ansible.sh > /tmp/role-validation.log 2>&1; then
                echo -e "${GREEN}✓${RESET} Validation passed"
            else
                echo -e "${YELLOW}⚠${RESET} Validation had warnings (see /tmp/role-validation.log)"
            fi
        fi
        
        RESULT=0
    else
        echo -e "${RED}✗${RESET} Role execution failed"
        echo "Output:"
        cat /tmp/role-test-output.log | tail -20
        RESULT=1
    fi
    
    # Cleanup
    echo "Cleaning up..."
    docker stop "$container_name" > /dev/null 2>&1
    docker rm "$container_name" > /dev/null 2>&1
    rm -f "$test_playbook"
    
    echo ""
    return $RESULT
}

# Main execution
if [ "$ALL_DISTROS" = true ]; then
    # Test on all distributions
    DISTROS=("ubuntu-24.04" "debian-13" "xubuntu-24.04" "mint-22")
    FAILED=0
    PASSED=0
    
    for distro in "${DISTROS[@]}"; do
        if test_role_on_distro "$distro"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    done
    
    echo "============================================"
    echo "  Role Test Summary"
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
else
    # Test on single distribution
    if test_role_on_distro "$DISTRIBUTION"; then
        echo -e "${GREEN}Role test passed!${RESET}"
        exit 0
    else
        echo -e "${RED}Role test failed!${RESET}"
        exit 1
    fi
fi
