#!/usr/bin/env bash

# ============================================================================
# Unit Tests for System Detection Module
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "$SCRIPT_DIR/../framework/test-framework.sh"

# Module under test
MODULE_PATH="$SCRIPT_DIR/../../../scripts/modules/system-detection.sh"

# ============================================================================
# Test Functions
# ============================================================================

test_ubuntu_detection() {
    echo "Testing Ubuntu detection..."
    
    # Mock Ubuntu 24.04 environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    
    # Mock required commands
    create_mock_command "apt" "success"
    create_mock_command "pgrep" "exit 1"  # No desktop processes
    create_mock_command "systemctl" "exit 1"  # No graphical target
    
    # Override os-release file in the module
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test detection functions by sourcing and calling them
    source "$MODULE_PATH"
    
    # Test distribution detection
    assert_success "Ubuntu distribution detection" detect_distribution
    assert_equals "Detected OS should be ubuntu" "ubuntu" "$DETECTED_OS"
    assert_equals "Detected version should be 24.04" "24.04" "$DETECTED_VERSION"
    assert_equals "Detected codename should be noble" "noble" "$DETECTED_CODENAME"
    assert_equals "Should not be Pop!_OS" "false" "$IS_POPOS"
    assert_equals "Should not be Xubuntu" "false" "$IS_XUBUNTU"
}

test_xubuntu_25_10_detection() {
    echo "Testing Xubuntu 25.10 detection..."
    
    # Mock Xubuntu 25.10 environment
    mock_system_environment "ubuntu" "25.10" "Xubuntu 25.10" "oracular"
    
    # Mock required commands
    create_mock_command "apt" "success"
    create_mock_command "pgrep" '#!/bin/bash
if [ "$1" = "-x" ] && [ "$2" = "xfce4-session" ]; then
    echo "1234"  # Mock process ID
    exit 0
else
    exit 1
fi'
    
    # Mock environment variables for XFCE
    export XDG_CURRENT_DESKTOP="XFCE"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test detection functions
    source "$MODULE_PATH"
    
    assert_success "Xubuntu distribution detection" detect_distribution
    assert_equals "Detected OS should be ubuntu" "ubuntu" "$DETECTED_OS"
    assert_equals "Detected version should be 25.10" "25.10" "$DETECTED_VERSION"
    assert_equals "Should be Xubuntu" "true" "$IS_XUBUNTU"
    
    assert_success "XFCE desktop detection" detect_desktop_environment
    assert_equals "Should detect desktop environment" "true" "$IS_DESKTOP_ENV"
    assert_equals "Should detect XFCE desktop" "XFCE" "$DETECTED_DESKTOP"
}

test_popos_detection() {
    echo "Testing Pop!_OS detection..."
    
    # Mock Pop!_OS environment
    mock_system_environment "pop" "22.04" "Pop!_OS 22.04 LTS" "jammy"
    
    # Mock required commands
    create_mock_command "apt" "success"
    create_mock_command "pgrep" '#!/bin/bash
if [ "$1" = "-x" ] && [ "$2" = "gnome-shell" ]; then
    echo "1234"
    exit 0
else
    exit 1
fi'
    
    export XDG_CURRENT_DESKTOP="GNOME"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test detection functions
    source "$MODULE_PATH"
    
    assert_success "Pop!_OS distribution detection" detect_distribution
    assert_equals "Should be Pop!_OS" "true" "$IS_POPOS"
    assert_equals "Should not be Xubuntu" "false" "$IS_XUBUNTU"
    
    assert_success "GNOME desktop detection" detect_desktop_environment
    assert_equals "Should detect desktop environment" "true" "$IS_DESKTOP_ENV"
}

test_server_environment_detection() {
    echo "Testing server environment detection..."
    
    # Mock Ubuntu server environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    
    # Mock required commands (no desktop processes)
    create_mock_command "apt" "success"
    create_mock_command "pgrep" "exit 1"  # No desktop processes
    create_mock_command "systemctl" "exit 1"  # No graphical target
    
    # No desktop environment variables
    unset XDG_CURRENT_DESKTOP DISPLAY WAYLAND_DISPLAY
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test detection functions
    source "$MODULE_PATH"
    
    assert_success "Server distribution detection" detect_distribution
    
    # Desktop detection should return false (no desktop)
    if detect_desktop_environment; then
        ((TEST_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} Server desktop detection should return false"
    else
        ((TEST_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} Server desktop detection correctly returns false"
    fi
    ((TEST_TOTAL++))
    
    assert_equals "Should not detect desktop environment" "false" "$IS_DESKTOP_ENV"
    assert_equals "Desktop type should be none" "none" "$DETECTED_DESKTOP"
}

test_unsupported_distribution() {
    echo "Testing unsupported distribution handling..."
    
    # Mock unsupported distribution
    mock_system_environment "fedora" "39" "Fedora Linux 39" "thirty-nine"
    
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test should fail for unsupported distribution
    source "$MODULE_PATH"
    
    assert_failure "Unsupported distribution should fail" detect_distribution
}

test_missing_os_release() {
    echo "Testing missing os-release file handling..."
    
    # Don't create os-release file
    export TEST_OS_RELEASE_OVERRIDE="/nonexistent/os-release"
    
    # Test should fail without os-release
    source "$MODULE_PATH"
    
    assert_failure "Missing os-release should fail" detect_distribution
}

test_environment_variable_export() {
    echo "Testing environment variable export..."
    
    # Mock Ubuntu environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    
    create_mock_command "apt" "success"
    create_mock_command "pgrep" "exit 1"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Source and run detection
    source "$MODULE_PATH"
    detect_distribution
    set_global_environment_vars
    
    # Check that variables are exported
    assert_success "DETECTED_OS should be exported" test -n "$DETECTED_OS"
    assert_success "DETECTED_VERSION should be exported" test -n "$DETECTED_VERSION"
    assert_success "IS_POPOS should be exported" test -n "$IS_POPOS"
    assert_success "IS_XUBUNTU should be exported" test -n "$IS_XUBUNTU"
}

test_module_independence() {
    echo "Testing module independence..."
    
    # Test that module can run without external dependencies
    local temp_module="$TEST_TEMP_DIR/isolated-system-detection.sh"
    
    # Copy module to isolated location
    cp "$MODULE_PATH" "$temp_module"
    
    # Copy required libraries
    mkdir -p "$TEST_TEMP_DIR/lib"
    cp "$SCRIPT_DIR/../../../scripts/lib/logging.sh" "$TEST_TEMP_DIR/lib/"
    cp "$SCRIPT_DIR/../../../scripts/lib/version-detection.sh" "$TEST_TEMP_DIR/lib/"
    
    # Mock Ubuntu environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    create_mock_command "apt" "success"
    
    # Update module to use local lib directory
    sed -i "s|../lib/|$TEST_TEMP_DIR/lib/|g" "$temp_module"
    
    # Override os-release in the copied module
    sed -i "s|/etc/os-release|\$TEST_OS_RELEASE_OVERRIDE|g" "$temp_module"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test isolated execution
    assert_success "Module should run independently" bash "$temp_module"
}

test_error_handling() {
    echo "Testing error handling..."
    
    # Test with invalid arguments
    assert_failure "Module should handle invalid arguments" bash "$MODULE_PATH" --invalid-arg
    
    # Test with missing dependencies (no logging.sh)
    local broken_module="$TEST_TEMP_DIR/broken-system-detection.sh"
    cp "$MODULE_PATH" "$broken_module"
    
    # Break the module by pointing to non-existent lib
    sed -i 's|../lib/logging.sh|/nonexistent/logging.sh|g' "$broken_module"
    
    assert_failure "Module should fail with missing dependencies" bash "$broken_module"
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo -e "${TEST_CYAN}  System Detection Module Unit Tests${TEST_RESET}"
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo ""
    
    # Check if module exists
    if [ ! -f "$MODULE_PATH" ]; then
        echo -e "${TEST_RED}Error: Module not found at $MODULE_PATH${TEST_RESET}"
        exit 1
    fi
    
    # Run tests
    run_test "ubuntu_detection" test_ubuntu_detection
    run_test "xubuntu_25_10_detection" test_xubuntu_25_10_detection
    run_test "popos_detection" test_popos_detection
    run_test "server_environment_detection" test_server_environment_detection
    run_test "unsupported_distribution" test_unsupported_distribution
    run_test "missing_os_release" test_missing_os_release
    run_test "environment_variable_export" test_environment_variable_export
    run_test "module_independence" test_module_independence
    run_test "error_handling" test_error_handling
    
    # Print summary
    print_test_summary
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi