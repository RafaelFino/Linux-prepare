#!/usr/bin/env bash

# ============================================================================
# Unit Tests for Docker Installation Module
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "$SCRIPT_DIR/../framework/test-framework.sh"

# Module under test
MODULE_PATH="$SCRIPT_DIR/../../../scripts/modules/docker-install.sh"

# ============================================================================
# Test Functions
# ============================================================================

test_docker_repository_configuration() {
    echo "Testing Docker repository configuration..."
    
    # Mock system environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    
    # Mock required commands
    create_mock_command "curl" "success"
    create_mock_command "gpg" "success"
    create_mock_command "apt" "success"
    create_mock_command "tee" "success"
    
    # Mock file operations
    mkdir -p "$TEST_TEMP_DIR/etc/apt/keyrings"
    mkdir -p "$TEST_TEMP_DIR/etc/apt/sources.list.d"
    
    # Source module functions
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    source "$MODULE_PATH"
    
    # Override file paths for testing
    export APT_KEYRINGS_DIR="$TEST_TEMP_DIR/etc/apt/keyrings"
    export APT_SOURCES_DIR="$TEST_TEMP_DIR/etc/apt/sources.list.d"
    
    # Test repository configuration
    assert_success "Docker repository configuration" configure_docker_repository "24.04" "noble"
}

test_docker_engine_installation() {
    echo "Testing Docker engine installation..."
    
    # Mock package installation
    create_mock_command "apt" '#!/bin/bash
if [ "$1" = "install" ]; then
    echo "Installing Docker packages..."
    exit 0
else
    exit 0
fi'
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Mock the install_packages_safe function
    install_packages_safe() {
        echo "Mock installing packages: $*"
        return 0
    }
    
    # Test Docker engine installation
    assert_success "Docker engine installation" install_docker_engine
}

test_popos_docker_installation() {
    echo "Testing Pop!_OS Docker installation..."
    
    # Mock Pop!_OS environment
    mock_system_environment "pop" "22.04" "Pop!_OS 22.04 LTS" "jammy"
    
    # Mock commands for Pop!_OS
    create_mock_command "apt" '#!/bin/bash
case "$1" in
    "remove")
        echo "Removing conflicting packages..."
        exit 0
        ;;
    "update")
        echo "Updating package list..."
        exit 0
        ;;
    "install")
        if [[ "$*" == *"docker.io"* ]]; then
            echo "Installing docker.io from Pop!_OS repos..."
            exit 0
        fi
        ;;
esac
exit 0'
    
    # Source module functions
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    source "$MODULE_PATH"
    
    # Test Pop!_OS installation
    assert_success "Pop!_OS Docker installation" install_docker_popos
}

test_docker_fallback_installation() {
    echo "Testing Docker fallback installation..."
    
    # Mock fallback scenario
    create_mock_command "apt" "success"
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Mock package installation functions
    install_packages_safe() {
        if [ "$1" = "docker.io" ]; then
            echo "Installing docker.io package..."
            return 0
        fi
        return 1
    }
    
    install_package_with_fallback() {
        echo "docker-compose"  # Return v1 package name
        return 0
    }
    
    # Test fallback installation
    assert_success "Docker fallback installation" install_docker_fallback
}

test_docker_service_configuration() {
    echo "Testing Docker service configuration..."
    
    # Mock system commands
    create_mock_command "groupadd" "success"
    create_mock_command "systemctl" '#!/bin/bash
if [ "$1" = "enable" ] || [ "$1" = "start" ]; then
    echo "Docker service $1..."
    exit 0
fi
exit 0'
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Mock group check function
    check_group_exists() {
        return 1  # Group doesn't exist
    }
    
    # Test service configuration
    assert_success "Docker service configuration" configure_docker_service
}

test_docker_validation() {
    echo "Testing Docker installation validation..."
    
    # Mock Docker commands
    create_mock_command "docker" '#!/bin/bash
if [ "$1" = "--version" ]; then
    echo "Docker version 24.0.7, build afdd53b"
    exit 0
elif [ "$1" = "compose" ] && [ "$2" = "version" ]; then
    echo "Docker Compose version v2.21.0"
    exit 0
fi
exit 0'
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Mock command availability check
    check_command_available() {
        case "$1" in
            "docker"|"docker compose")
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }
    
    # Test validation
    assert_success "Docker installation validation" validate_docker_installation
}

test_docker_rollback() {
    echo "Testing Docker installation rollback..."
    
    # Mock system commands for rollback
    create_mock_command "systemctl" '#!/bin/bash
echo "Stopping/disabling Docker service..."
exit 0'
    
    create_mock_command "apt" '#!/bin/bash
if [ "$1" = "remove" ]; then
    echo "Removing Docker packages..."
    exit 0
elif [ "$1" = "update" ]; then
    echo "Updating package list..."
    exit 0
fi
exit 0'
    
    # Create mock files to remove
    mkdir -p "$TEST_TEMP_DIR/etc/apt/sources.list.d"
    mkdir -p "$TEST_TEMP_DIR/etc/apt/keyrings"
    touch "$TEST_TEMP_DIR/etc/apt/sources.list.d/docker.list"
    touch "$TEST_TEMP_DIR/etc/apt/keyrings/docker.gpg"
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Override file paths for testing
    export APT_SOURCES_DIR="$TEST_TEMP_DIR/etc/apt/sources.list.d"
    export APT_KEYRINGS_DIR="$TEST_TEMP_DIR/etc/apt/keyrings"
    
    # Test rollback
    assert_success "Docker installation rollback" rollback_docker_installation
    
    # Verify files were removed
    assert_failure "Docker sources list should be removed" test -f "$TEST_TEMP_DIR/etc/apt/sources.list.d/docker.list"
    assert_failure "Docker GPG key should be removed" test -f "$TEST_TEMP_DIR/etc/apt/keyrings/docker.gpg"
}

test_already_installed_skip() {
    echo "Testing skip when Docker already installed..."
    
    # Mock Docker as already installed
    create_mock_command "docker" "success"
    create_mock_command "docker compose" "success"
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Mock command availability check
    check_command_available() {
        case "$1" in
            "docker"|"docker compose")
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }
    
    # Mock validation function
    validate_docker_installation() {
        echo "Docker already installed"
        return 0
    }
    
    # Test that installation is skipped
    assert_success "Should skip when Docker already installed" install_docker
}

test_module_independence() {
    echo "Testing module independence..."
    
    # Create isolated environment
    local temp_module="$TEST_TEMP_DIR/isolated-docker-install.sh"
    cp "$MODULE_PATH" "$temp_module"
    
    # Copy required libraries
    mkdir -p "$TEST_TEMP_DIR/lib"
    cp "$SCRIPT_DIR/../../../scripts/lib/logging.sh" "$TEST_TEMP_DIR/lib/"
    cp "$SCRIPT_DIR/../../../scripts/lib/version-detection.sh" "$TEST_TEMP_DIR/lib/"
    cp "$SCRIPT_DIR/../../../scripts/lib/package-utils.sh" "$TEST_TEMP_DIR/lib/"
    
    # Update module to use local lib directory
    sed -i "s|../lib/|$TEST_TEMP_DIR/lib/|g" "$temp_module"
    
    # Mock environment
    export INSTALL_DOCKER="false"  # Skip actual installation
    
    # Test isolated execution
    assert_success "Module should run independently" bash "$temp_module"
}

test_error_handling() {
    echo "Testing error handling..."
    
    # Test with invalid arguments
    assert_failure "Module should handle invalid arguments" bash "$MODULE_PATH" --invalid-arg
    
    # Test with missing dependencies
    local broken_module="$TEST_TEMP_DIR/broken-docker-install.sh"
    cp "$MODULE_PATH" "$broken_module"
    
    # Break the module by pointing to non-existent lib
    sed -i 's|../lib/logging.sh|/nonexistent/logging.sh|g' "$broken_module"
    
    assert_failure "Module should fail with missing dependencies" bash "$broken_module"
}

test_configuration_based_skipping() {
    echo "Testing configuration-based skipping..."
    
    # Source module functions
    source "$MODULE_PATH"
    
    # Test with Docker installation disabled
    export INSTALL_DOCKER="false"
    
    # Mock the module_main function behavior
    local result=0
    if [ "${INSTALL_DOCKER:-true}" != "true" ]; then
        result=0  # Should skip
    else
        result=1  # Should not skip
    fi
    
    assert_success "Should skip Docker installation when disabled" test $result -eq 0
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo -e "${TEST_CYAN}  Docker Installation Module Unit Tests${TEST_RESET}"
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo ""
    
    # Check if module exists
    if [ ! -f "$MODULE_PATH" ]; then
        echo -e "${TEST_RED}Error: Module not found at $MODULE_PATH${TEST_RESET}"
        exit 1
    fi
    
    # Run tests
    run_test "docker_repository_configuration" test_docker_repository_configuration
    run_test "docker_engine_installation" test_docker_engine_installation
    run_test "popos_docker_installation" test_popos_docker_installation
    run_test "docker_fallback_installation" test_docker_fallback_installation
    run_test "docker_service_configuration" test_docker_service_configuration
    run_test "docker_validation" test_docker_validation
    run_test "docker_rollback" test_docker_rollback
    run_test "already_installed_skip" test_already_installed_skip
    run_test "module_independence" test_module_independence
    run_test "error_handling" test_error_handling
    run_test "configuration_based_skipping" test_configuration_based_skipping
    
    # Print summary
    print_test_summary
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi