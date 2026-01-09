#!/usr/bin/env bash

# ============================================================================
# Unit Test Framework for Linux-prepare Modular Architecture
# ============================================================================
# Provides utilities for testing individual modules in isolation

set -euo pipefail

# ============================================================================
# Test Framework Configuration
# ============================================================================

# Colors for output
readonly TEST_GREEN="\033[32m"
readonly TEST_RED="\033[31m"
readonly TEST_YELLOW="\033[33m"
readonly TEST_CYAN="\033[36m"
readonly TEST_GRAY="\033[90m"
readonly TEST_RESET="\033[0m"

# Test counters
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0
TEST_TOTAL=0

# Test configuration
TEST_VERBOSE=${TEST_VERBOSE:-false}
TEST_CLEANUP=${TEST_CLEANUP:-true}
TEST_TEMP_DIR=""

# ============================================================================
# Test Utilities
# ============================================================================

# Initialize test environment
test_init() {
    local test_name="$1"
    
    # Create temporary directory for test
    TEST_TEMP_DIR=$(mktemp -d -t "linux-prepare-test-${test_name}-XXXXXX")
    
    # Set up test environment variables
    export TEST_MODE="true"
    export TEST_TEMP_DIR
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_CYAN}Initializing test: $test_name${TEST_RESET}"
        echo -e "${TEST_GRAY}Test temp dir: $TEST_TEMP_DIR${TEST_RESET}"
    fi
}

# Cleanup test environment
test_cleanup() {
    if [ "$TEST_CLEANUP" = "true" ] && [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
        if [ "$TEST_VERBOSE" = "true" ]; then
            echo -e "${TEST_GRAY}Cleaned up test temp dir${TEST_RESET}"
        fi
    fi
    
    # Unset test environment variables
    unset TEST_MODE TEST_TEMP_DIR
}

# ============================================================================
# Assertion Functions
# ============================================================================

# Assert that a command succeeds
assert_success() {
    local description="$1"
    shift
    local command=("$@")
    
    ((TEST_TOTAL++))
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}Testing: $description${TEST_RESET}"
        echo -e "${TEST_GRAY}Command: ${command[*]}${TEST_RESET}"
    fi
    
    if "${command[@]}" &>/dev/null; then
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $description"
        return 0
    else
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $description"
        if [ "$TEST_VERBOSE" = "true" ]; then
            echo -e "${TEST_RED}Command failed: ${command[*]}${TEST_RESET}"
        fi
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    local description="$1"
    shift
    local command=("$@")
    
    ((TEST_TOTAL++))
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}Testing: $description${TEST_RESET}"
        echo -e "${TEST_GRAY}Command (should fail): ${command[*]}${TEST_RESET}"
    fi
    
    if ! "${command[@]}" &>/dev/null; then
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $description"
        return 0
    else
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $description (expected failure but command succeeded)"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local description="$1"
    local file_path="$2"
    
    ((TEST_TOTAL++))
    
    if [ -f "$file_path" ]; then
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $description"
        return 0
    else
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $description (file not found: $file_path)"
        return 1
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local description="$1"
    local dir_path="$2"
    
    ((TEST_TOTAL++))
    
    if [ -d "$dir_path" ]; then
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $description"
        return 0
    else
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $description (directory not found: $dir_path)"
        return 1
    fi
}

# Assert that a string contains another string
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    
    ((TEST_TOTAL++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $description"
        return 0
    else
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $description"
        if [ "$TEST_VERBOSE" = "true" ]; then
            echo -e "${TEST_RED}Expected '$haystack' to contain '$needle'${TEST_RESET}"
        fi
        return 1
    fi
}

# Assert that two strings are equal
assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    ((TEST_TOTAL++))
    
    if [ "$expected" = "$actual" ]; then
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $description"
        return 0
    else
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $description"
        if [ "$TEST_VERBOSE" = "true" ]; then
            echo -e "${TEST_RED}Expected: '$expected'${TEST_RESET}"
            echo -e "${TEST_RED}Actual: '$actual'${TEST_RESET}"
        fi
        return 1
    fi
}

# Skip a test
skip_test() {
    local description="$1"
    local reason="$2"
    
    ((TEST_TOTAL++))
    ((TEST_SKIPPED++))
    
    echo -e "${TEST_YELLOW}⏭${TEST_RESET} $description (skipped: $reason)"
}

# ============================================================================
# Mock Functions
# ============================================================================

# Create a mock command
create_mock_command() {
    local command_name="$1"
    local mock_behavior="$2"  # "success", "failure", or custom script
    
    local mock_script="$TEST_TEMP_DIR/mock-$command_name"
    
    case "$mock_behavior" in
        "success")
            echo '#!/bin/bash' > "$mock_script"
            echo 'exit 0' >> "$mock_script"
            ;;
        "failure")
            echo '#!/bin/bash' > "$mock_script"
            echo 'exit 1' >> "$mock_script"
            ;;
        *)
            echo "$mock_behavior" > "$mock_script"
            ;;
    esac
    
    chmod +x "$mock_script"
    
    # Add to PATH
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}Created mock command: $command_name${TEST_RESET}"
    fi
}

# Create mock file with content
create_mock_file() {
    local file_path="$1"
    local content="$2"
    
    # Create directory if needed
    local dir_path=$(dirname "$file_path")
    mkdir -p "$dir_path"
    
    echo "$content" > "$file_path"
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}Created mock file: $file_path${TEST_RESET}"
    fi
}

# Mock system environment
mock_system_environment() {
    local os_id="$1"
    local version_id="$2"
    local pretty_name="$3"
    local codename="${4:-unknown}"
    
    local os_release_content="ID=$os_id
VERSION_ID=$version_id
PRETTY_NAME=\"$pretty_name\"
VERSION_CODENAME=$codename"
    
    create_mock_file "$TEST_TEMP_DIR/os-release" "$os_release_content"
    
    # Override /etc/os-release for the test
    export TEST_OS_RELEASE_FILE="$TEST_TEMP_DIR/os-release"
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}Mocked system: $pretty_name ($version_id)${TEST_RESET}"
    fi
}

# ============================================================================
# Test Execution Functions
# ============================================================================

# Run a test function with proper setup and cleanup
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${TEST_CYAN}Running test: $test_name${TEST_RESET}"
    
    # Initialize test environment
    test_init "$test_name"
    
    # Set up error handling
    local test_failed=false
    trap 'test_failed=true' ERR
    
    # Run the test function
    if "$test_function"; then
        if [ "$test_failed" = "false" ]; then
            echo -e "${TEST_GREEN}Test completed: $test_name${TEST_RESET}"
        else
            echo -e "${TEST_RED}Test failed with error: $test_name${TEST_RESET}"
        fi
    else
        echo -e "${TEST_RED}Test failed: $test_name${TEST_RESET}"
    fi
    
    # Cleanup
    trap - ERR
    test_cleanup
    
    echo ""
}

# Print test summary
print_test_summary() {
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo -e "${TEST_CYAN}  Test Summary${TEST_RESET}"
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo -e "${TEST_GREEN}Passed: $TEST_PASSED${TEST_RESET}"
    echo -e "${TEST_RED}Failed: $TEST_FAILED${TEST_RESET}"
    echo -e "${TEST_YELLOW}Skipped: $TEST_SKIPPED${TEST_RESET}"
    echo -e "${TEST_CYAN}Total: $TEST_TOTAL${TEST_RESET}"
    echo ""
    
    if [ $TEST_FAILED -eq 0 ]; then
        echo -e "${TEST_GREEN}All tests passed!${TEST_RESET}"
        return 0
    else
        echo -e "${TEST_RED}Some tests failed!${TEST_RESET}"
        return 1
    fi
}

# ============================================================================
# Module Testing Utilities
# ============================================================================

# Test a module in isolation
test_module_isolated() {
    local module_path="$1"
    local test_args=("${@:2}")
    
    # Create isolated environment
    local isolated_env="$TEST_TEMP_DIR/isolated"
    mkdir -p "$isolated_env"
    
    # Copy module and dependencies
    cp "$module_path" "$isolated_env/"
    
    # Copy lib directory if it exists
    local lib_dir="$(dirname "$module_path")/../lib"
    if [ -d "$lib_dir" ]; then
        cp -r "$lib_dir" "$isolated_env/"
    fi
    
    # Run module in isolated environment
    cd "$isolated_env"
    bash "$(basename "$module_path")" "${test_args[@]}"
}

# Check if module has proper error handling
test_module_error_handling() {
    local module_path="$1"
    
    # Test with invalid arguments
    if bash "$module_path" --invalid-argument 2>/dev/null; then
        return 1  # Should have failed
    fi
    
    return 0  # Properly handled error
}

# ============================================================================
# Performance Testing Utilities
# ============================================================================

# Measure execution time
measure_execution_time() {
    local description="$1"
    shift
    local command=("$@")
    
    local start_time=$(date +%s.%N)
    "${command[@]}"
    local end_time=$(date +%s.%N)
    
    local execution_time=$(echo "$end_time - $start_time" | bc -l)
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}$description: ${execution_time}s${TEST_RESET}"
    fi
    
    echo "$execution_time"
}

# Compare execution times
compare_execution_times() {
    local description="$1"
    local time1="$2"
    local time2="$3"
    local threshold="$4"  # Percentage difference threshold
    
    local diff=$(echo "scale=2; ($time2 - $time1) / $time1 * 100" | bc -l)
    local abs_diff=$(echo "$diff" | sed 's/-//')
    
    if [ "$TEST_VERBOSE" = "true" ]; then
        echo -e "${TEST_GRAY}$description: ${diff}% difference${TEST_RESET}"
    fi
    
    # Check if difference exceeds threshold
    if (( $(echo "$abs_diff > $threshold" | bc -l) )); then
        return 1
    fi
    
    return 0
}