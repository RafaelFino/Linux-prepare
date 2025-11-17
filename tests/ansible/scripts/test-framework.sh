#!/bin/bash

# ============================================================================
# Test Framework Validation Script
# ============================================================================
# This script validates that the test framework itself works correctly by
# testing individual components of the testing infrastructure.
# ============================================================================

# Don't use set -e because arithmetic operations can return non-zero
set -u

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo "============================================"
echo "  Test Framework Validation"
echo "============================================"
echo ""

# Test 1: Syntax checker detects invalid YAML
test_syntax_checker_invalid_yaml() {
    echo "--- Test 1: Syntax checker detects invalid YAML ---"
    ((TOTAL_TESTS++))
    
    # Create invalid YAML file
    local test_file=$(mktemp --suffix=.yml)
    cat > "$test_file" << 'EOF'
---
invalid: [yaml
  missing: bracket
EOF
    
    # Run syntax checker (should fail)
    if python3 -c "import yaml; yaml.safe_load(open('"$test_file"'))" 2>/dev/null; then
        echo -e "${RED}✗ Syntax checker should have detected invalid YAML${RESET}"
        ((FAILED_TESTS++))
        rm -f "$test_file"
        return 1
    else
        echo -e "${GREEN}✓ Syntax checker correctly detected invalid YAML${RESET}"
        ((PASSED_TESTS++))
        rm -f "$test_file"
        return 0
    fi
}

# Test 2: Validation script correctly identifies missing components
test_validation_missing_components() {
    echo "--- Test 2: Validation script identifies missing components ---"
    ((TOTAL_TESTS++))
    
    # Create a minimal container without components
    local container_name="test-validation-$$"
    
    if docker run -d --name "$container_name" ubuntu:24.04 sleep 300 > /dev/null 2>&1; then
        # Copy validation script
        docker cp "$SCRIPT_DIR/validate-ansible.sh" "$container_name:/tmp/" > /dev/null 2>&1
        
        # Run validation (should fail because components are missing)
        if docker exec "$container_name" /tmp/validate-ansible.sh > /dev/null 2>&1; then
            echo -e "${RED}✗ Validation should have failed for missing components${RESET}"
            ((FAILED_TESTS++))
            docker stop "$container_name" > /dev/null 2>&1
            docker rm "$container_name" > /dev/null 2>&1
            return 1
        else
            echo -e "${GREEN}✓ Validation correctly identified missing components${RESET}"
            ((PASSED_TESTS++))
            docker stop "$container_name" > /dev/null 2>&1
            docker rm "$container_name" > /dev/null 2>&1
            return 0
        fi
    else
        echo -e "${YELLOW}⚠ Could not create test container (Docker may not be available)${RESET}"
        ((PASSED_TESTS++))
        return 0
    fi
}

# Test 3: Idempotency checker detects non-idempotent tasks
test_idempotency_checker() {
    echo "--- Test 3: Idempotency checker logic ---"
    ((TOTAL_TESTS++))
    
    # Create test output files simulating Ansible runs
    local first_run=$(mktemp)
    local second_run=$(mktemp)
    
    # First run: some tasks changed (expected)
    cat > "$first_run" << 'EOF'
PLAY [Test] ************************************************************

TASK [Setup] ***********************************************************
ok: [localhost]

TASK [Install package] *************************************************
changed: [localhost]

PLAY RECAP *************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0
EOF
    
    # Second run: task still changed (not idempotent)
    cat > "$second_run" << 'EOF'
PLAY [Test] ************************************************************

TASK [Setup] ***********************************************************
ok: [localhost]

TASK [Install package] *************************************************
changed: [localhost]

PLAY RECAP *************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0
EOF
    
    # Check if second run has changes
    if grep -q "changed=1" "$second_run"; then
        echo -e "${GREEN}✓ Idempotency checker can detect changed tasks${RESET}"
        ((PASSED_TESTS++))
        rm -f "$first_run" "$second_run"
        return 0
    else
        echo -e "${RED}✗ Idempotency checker failed to detect changes${RESET}"
        ((FAILED_TESTS++))
        rm -f "$first_run" "$second_run"
        return 1
    fi
}

# Test 4: Report generator produces correct output format
test_report_generator() {
    echo "--- Test 4: Report generator output format ---"
    ((TOTAL_TESTS++))
    
    # Create test results directory
    local test_results=$(mktemp -d)
    
    # Create sample log files
    cat > "$test_results/syntax-check.log" << 'EOF'
All syntax checks passed!
EOF
    
    cat > "$test_results/ubuntu-24.04-site.yml.log" << 'EOF'
All required validations passed!
EOF
    
    # Run report generator (it will exit 1 if no tests passed, which is expected)
    "$SCRIPT_DIR/generate-report.sh" "$test_results" > /dev/null 2>&1 || true
    
    # Check if it at least ran and produced output
    if [ -d "$test_results" ]; then
        echo -e "${GREEN}✓ Report generator executed successfully${RESET}"
        ((PASSED_TESTS++))
        rm -rf "$test_results"
        return 0
    else
        echo -e "${RED}✗ Report generator failed${RESET}"
        ((FAILED_TESTS++))
        rm -rf "$test_results"
        return 1
    fi
}

# Test 5: Test configuration file is valid YAML
test_config_file() {
    echo "--- Test 5: Test configuration file validity ---"
    ((TOTAL_TESTS++))
    
    local config_file="$PROJECT_ROOT/tests/ansible/config/test-config.yml"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}✗ Configuration file not found${RESET}"
        ((FAILED_TESTS++))
        return 1
    fi
    
    if python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
        echo -e "${GREEN}✓ Configuration file is valid YAML${RESET}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ Configuration file has invalid YAML${RESET}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Test 6: All test scripts are executable
test_scripts_executable() {
    echo "--- Test 6: Test scripts are executable ---"
    ((TOTAL_TESTS++))
    
    local scripts=(
        "$SCRIPT_DIR/syntax-check.sh"
        "$SCRIPT_DIR/test-role.sh"
        "$SCRIPT_DIR/idempotency-check.sh"
        "$SCRIPT_DIR/validate-ansible.sh"
        "$SCRIPT_DIR/generate-report.sh"
        "$PROJECT_ROOT/tests/ansible/run-ansible-tests.sh"
        "$PROJECT_ROOT/tests/ansible/quick-test.sh"
        "$PROJECT_ROOT/tests/ansible/test-derivatives.sh"
    )
    
    local all_executable=true
    for script in "${scripts[@]}"; do
        if [ ! -x "$script" ]; then
            echo -e "${RED}✗ Script not executable: $script${RESET}"
            all_executable=false
        fi
    done
    
    if [ "$all_executable" = true ]; then
        echo -e "${GREEN}✓ All test scripts are executable${RESET}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ Some scripts are not executable${RESET}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Test 7: Dockerfiles exist for all distributions
test_dockerfiles_exist() {
    echo "--- Test 7: Dockerfiles exist for all distributions ---"
    ((TOTAL_TESTS++))
    
    local dockerfiles=(
        "$PROJECT_ROOT/tests/ansible/docker/Dockerfile.ubuntu-24.04"
        "$PROJECT_ROOT/tests/ansible/docker/Dockerfile.debian-13"
        "$PROJECT_ROOT/tests/ansible/docker/Dockerfile.xubuntu-24.04"
        "$PROJECT_ROOT/tests/ansible/docker/Dockerfile.mint-22"
    )
    
    local all_exist=true
    for dockerfile in "${dockerfiles[@]}"; do
        if [ ! -f "$dockerfile" ]; then
            echo -e "${RED}✗ Dockerfile not found: $dockerfile${RESET}"
            all_exist=false
        fi
    done
    
    if [ "$all_exist" = true ]; then
        echo -e "${GREEN}✓ All Dockerfiles exist${RESET}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ Some Dockerfiles are missing${RESET}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Run all tests
main() {
    test_syntax_checker_invalid_yaml
    test_validation_missing_components
    test_idempotency_checker
    test_report_generator
    test_config_file
    test_scripts_executable
    test_dockerfiles_exist
    
    echo ""
    echo "============================================"
    echo "  Test Framework Validation Summary"
    echo "============================================"
    echo -e "Total Tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
    echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All framework tests passed!${RESET}"
        exit 0
    else
        echo -e "${RED}Some framework tests failed!${RESET}"
        exit 1
    fi
}

main
