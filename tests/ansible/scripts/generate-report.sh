#!/bin/bash

# ============================================================================
# Ansible Test Report Generator
# ============================================================================
# This script generates comprehensive test reports from test results.
# ============================================================================

set -e

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# Parse command-line arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <results_directory>"
    echo ""
    echo "Example:"
    echo "  $0 tests/ansible/results/20241116-153045"
    exit 1
fi

RESULTS_DIR="$1"

if [ ! -d "$RESULTS_DIR" ]; then
    echo -e "${RED}Error: Results directory not found: $RESULTS_DIR${RESET}"
    exit 1
fi

echo "============================================"
echo "  Ansible Test Report"
echo "============================================"
echo "Results Directory: $RESULTS_DIR"
echo ""

# Parse test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Function to analyze log file
analyze_log() {
    local log_file=$1
    local test_name=$2
    
    if [ ! -f "$log_file" ]; then
        return
    fi
    
    ((TOTAL_TESTS++))
    
    # Check for success indicators
    if grep -q "All tests passed\|All syntax checks passed\|All required validations passed\|Role test passed" "$log_file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $test_name"
        ((PASSED_TESTS++))
    elif grep -q "failed\|FAILED\|Error\|ERROR" "$log_file" 2>/dev/null; then
        echo -e "  ${RED}✗${RESET} $test_name"
        ((FAILED_TESTS++))
        
        # Show error excerpt
        echo -e "    ${RED}Error:${RESET}"
        grep -A 3 "failed\|FAILED\|Error\|ERROR" "$log_file" | head -10 | sed 's/^/      /'
    else
        echo -e "  ${YELLOW}⚠${RESET} $test_name (unknown status)"
        ((WARNINGS++))
    fi
}

# Analyze syntax check
echo -e "${CYAN}Syntax Checks:${RESET}"
if [ -f "$RESULTS_DIR/syntax-check.log" ]; then
    analyze_log "$RESULTS_DIR/syntax-check.log" "Syntax validation"
else
    echo -e "  ${GRAY}No syntax check results${RESET}"
fi
echo ""

# Analyze role tests
echo -e "${CYAN}Role Tests:${RESET}"
ROLE_TESTS_FOUND=false
for log_file in "$RESULTS_DIR"/role-*.log; do
    if [ -f "$log_file" ]; then
        ROLE_TESTS_FOUND=true
        role_name=$(basename "$log_file" .log | sed 's/role-//')
        analyze_log "$log_file" "Role: $role_name"
    fi
done
if [ "$ROLE_TESTS_FOUND" = false ]; then
    echo -e "  ${GRAY}No role test results${RESET}"
fi
echo ""

# Analyze distribution tests
echo -e "${CYAN}Distribution Tests:${RESET}"
DISTRO_TESTS_FOUND=false
for distro in ubuntu-24.04 debian-13 xubuntu-24.04 mint-22; do
    for log_file in "$RESULTS_DIR"/$distro-*.log; do
        if [ -f "$log_file" ]; then
            DISTRO_TESTS_FOUND=true
            playbook=$(basename "$log_file" .log | sed "s/$distro-//")
            analyze_log "$log_file" "$distro ($playbook)"
        fi
    done
done
if [ "$DISTRO_TESTS_FOUND" = false ]; then
    echo -e "  ${GRAY}No distribution test results${RESET}"
fi
echo ""

# Analyze idempotency tests
echo -e "${CYAN}Idempotency Tests:${RESET}"
if [ -f "$RESULTS_DIR/idempotency.log" ]; then
    analyze_log "$RESULTS_DIR/idempotency.log" "Idempotency check"
else
    echo -e "  ${GRAY}No idempotency test results${RESET}"
fi
echo ""

# Calculate execution time
START_TIME=$(stat -c %Y "$RESULTS_DIR" 2>/dev/null || stat -f %B "$RESULTS_DIR" 2>/dev/null || echo "0")
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Format duration
if [ $DURATION -ge 3600 ]; then
    DURATION_STR="$((DURATION / 3600))h $((DURATION % 3600 / 60))m"
elif [ $DURATION -ge 60 ]; then
    DURATION_STR="$((DURATION / 60))m $((DURATION % 60))s"
else
    DURATION_STR="${DURATION}s"
fi

# Generate summary
echo "============================================"
echo "  Summary"
echo "============================================"
echo -e "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
echo -e "${YELLOW}Warnings:     $WARNINGS${RESET}"
echo -e "Duration:     $DURATION_STR"
echo ""

# List failed tests
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed Tests:${RESET}"
    for log_file in "$RESULTS_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            if grep -q "failed\|FAILED\|Error\|ERROR" "$log_file" 2>/dev/null; then
                test_name=$(basename "$log_file" .log)
                echo -e "  - $test_name"
                echo -e "    Log: $log_file"
            fi
        fi
    done
    echo ""
fi

# Overall result
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${RESET}"
    exit 1
fi
