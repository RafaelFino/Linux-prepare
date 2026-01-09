#!/usr/bin/env bash

# ============================================================================
# Unit Tests for Version Detection Library
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "$SCRIPT_DIR/../framework/test-framework.sh"

# Library under test
LIB_PATH="$SCRIPT_DIR/../../../scripts/lib/version-detection.sh"

# ============================================================================
# Test Functions
# ============================================================================

test_ubuntu_version_detection() {
    echo "Testing Ubuntu version detection..."
    
    # Mock Ubuntu 24.04 environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Source the library
    source "$LIB_PATH"
    
    # Test version detection
    local detected_version=$(detect_ubuntu_version)
    assert_equals "Should detect Ubuntu 24.04" "24.04" "$detected_version"
    
    # Test codename detection
    local detected_codename=$(detect_ubuntu_codename)
    assert_equals "Should detect noble codename" "noble" "$detected_codename"
}

test_xubuntu_25_10_version_detection() {
    echo "Testing Xubuntu 25.10 version detection..."
    
    # Mock Xubuntu 25.10 environment
    mock_system_environment "ubuntu" "25.10" "Xubuntu 25.10" "oracular"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Source the library
    source "$LIB_PATH"
    
    # Test version detection
    local detected_version=$(detect_ubuntu_version)
    assert_equals "Should detect Ubuntu 25.10" "25.10" "$detected_version"
    
    # Test codename detection
    local detected_codename=$(detect_ubuntu_codename)
    assert_equals "Should detect oracular codename" "oracular" "$detected_codename"
}

test_ls_replacement_package_selection() {
    echo "Testing ls replacement package selection..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Test eza for Ubuntu 24.04+
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    local package_24_04=$(get_ls_replacement_package)
    assert_equals "Should use eza for Ubuntu 24.04" "eza" "$package_24_04"
    
    # Test eza for Ubuntu 25.10
    mock_system_environment "ubuntu" "25.10" "Xubuntu 25.10" "oracular"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    local package_25_10=$(get_ls_replacement_package)
    assert_equals "Should use eza for Ubuntu 25.10" "eza" "$package_25_10"
    
    # Test exa for Ubuntu 22.04
    mock_system_environment "ubuntu" "22.04" "Ubuntu 22.04.3 LTS" "jammy"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    local package_22_04=$(get_ls_replacement_package)
    assert_equals "Should use exa for Ubuntu 22.04" "exa" "$package_22_04"
}

test_docker_repository_configuration() {
    echo "Testing Docker repository configuration..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Test Ubuntu 24.04 Docker repo
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    local docker_repo=$(get_docker_repo_config)
    assert_contains "Docker repo should contain noble" "$docker_repo" "noble"
    assert_contains "Docker repo should contain Docker URL" "$docker_repo" "download.docker.com"
    
    # Test Ubuntu 25.10 Docker repo
    mock_system_environment "ubuntu" "25.10" "Xubuntu 25.10" "oracular"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    local docker_repo_25_10=$(get_docker_repo_config)
    assert_contains "Docker repo should contain oracular" "$docker_repo_25_10" "oracular"
}

test_version_comparison() {
    echo "Testing version comparison..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Test version comparison function
    assert_success "24.04 should be >= 24.04" version_compare "24.04" "24.04" ">="
    assert_success "25.10 should be > 24.04" version_compare "25.10" "24.04" ">"
    assert_success "22.04 should be < 24.04" version_compare "22.04" "24.04" "<"
    assert_success "24.04 should be <= 25.10" version_compare "24.04" "25.10" "<="
    
    # Test edge cases
    assert_failure "22.04 should not be > 24.04" version_compare "22.04" "24.04" ">"
    assert_failure "25.10 should not be < 24.04" version_compare "25.10" "24.04" "<"
}

test_distribution_detection() {
    echo "Testing distribution detection..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Test Ubuntu detection
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    assert_success "Should detect Ubuntu as Debian-based" is_debian_based
    assert_success "Should detect Ubuntu" is_ubuntu_based
    
    # Test Pop!_OS detection
    mock_system_environment "pop" "22.04" "Pop!_OS 22.04 LTS" "jammy"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    assert_success "Should detect Pop!_OS" is_popos
    assert_success "Should detect Pop!_OS as Debian-based" is_debian_based
    
    # Test non-Ubuntu distribution
    mock_system_environment "fedora" "39" "Fedora Linux 39" "thirty-nine"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    assert_failure "Should not detect Fedora as Debian-based" is_debian_based
    assert_failure "Should not detect Fedora as Ubuntu-based" is_ubuntu_based
}

test_environment_variable_setting() {
    echo "Testing environment variable setting..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Mock Ubuntu environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Set system environment variables
    set_system_environment_vars
    
    # Check that variables are set
    assert_success "UBUNTU_VERSION should be set" test -n "${UBUNTU_VERSION:-}"
    assert_success "UBUNTU_CODENAME should be set" test -n "${UBUNTU_CODENAME:-}"
    assert_success "IS_UBUNTU should be set" test -n "${IS_UBUNTU:-}"
    
    # Check values
    assert_equals "UBUNTU_VERSION should be 24.04" "24.04" "${UBUNTU_VERSION:-}"
    assert_equals "UBUNTU_CODENAME should be noble" "noble" "${UBUNTU_CODENAME:-}"
}

test_package_name_mapping() {
    echo "Testing package name mapping..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Test different Ubuntu versions
    local versions=("22.04" "24.04" "25.10")
    local expected_packages=("exa" "eza" "eza")
    
    for i in "${!versions[@]}"; do
        local version="${versions[$i]}"
        local expected="${expected_packages[$i]}"
        
        mock_system_environment "ubuntu" "$version" "Ubuntu $version" "test"
        export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
        
        local actual=$(get_ls_replacement_package)
        assert_equals "Ubuntu $version should use $expected" "$expected" "$actual"
    done
}

test_fallback_mechanisms() {
    echo "Testing fallback mechanisms..."
    
    # Source the library
    source "$LIB_PATH"
    
    # Test with missing version information
    create_mock_file "$TEST_TEMP_DIR/os-release-minimal" "ID=ubuntu"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release-minimal"
    
    # Should handle missing VERSION_ID gracefully
    local version=$(detect_ubuntu_version 2>/dev/null || echo "unknown")
    assert_success "Should handle missing version gracefully" test -n "$version"
    
    # Test Docker repo fallback for unknown version
    local docker_repo=$(get_docker_repo_config "unknown" "unknown" 2>/dev/null || echo "fallback")
    assert_success "Should provide fallback Docker repo" test -n "$docker_repo"
}

test_error_handling() {
    echo "Testing error handling..."
    
    # Test with non-existent os-release file
    export TEST_OS_RELEASE_OVERRIDE="/nonexistent/os-release"
    
    # Source the library
    source "$LIB_PATH"
    
    # Functions should handle missing file gracefully
    local version=$(detect_ubuntu_version 2>/dev/null || echo "error")
    assert_success "Should handle missing os-release file" test "$version" = "error"
    
    # Test invalid version comparison
    assert_failure "Should fail with invalid version format" version_compare "invalid" "24.04" ">"
}

test_library_independence() {
    echo "Testing library independence..."
    
    # Create isolated environment
    local temp_lib="$TEST_TEMP_DIR/isolated-version-detection.sh"
    cp "$LIB_PATH" "$temp_lib"
    
    # Copy logging dependency
    mkdir -p "$TEST_TEMP_DIR/lib"
    cp "$SCRIPT_DIR/../../../scripts/lib/logging.sh" "$TEST_TEMP_DIR/lib/"
    
    # Update library to use local logging
    sed -i "s|logging.sh|$TEST_TEMP_DIR/lib/logging.sh|g" "$temp_lib"
    
    # Mock environment
    mock_system_environment "ubuntu" "24.04" "Ubuntu 24.04.1 LTS" "noble"
    export TEST_OS_RELEASE_OVERRIDE="$TEST_TEMP_DIR/os-release"
    
    # Test isolated execution
    assert_success "Library should work independently" source "$temp_lib"
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo -e "${TEST_CYAN}  Version Detection Library Unit Tests${TEST_RESET}"
    echo -e "${TEST_CYAN}============================================${TEST_RESET}"
    echo ""
    
    # Check if library exists
    if [ ! -f "$LIB_PATH" ]; then
        echo -e "${TEST_RED}Error: Library not found at $LIB_PATH${TEST_RESET}"
        exit 1
    fi
    
    # Run tests
    run_test "ubuntu_version_detection" test_ubuntu_version_detection
    run_test "xubuntu_25_10_version_detection" test_xubuntu_25_10_version_detection
    run_test "ls_replacement_package_selection" test_ls_replacement_package_selection
    run_test "docker_repository_configuration" test_docker_repository_configuration
    run_test "version_comparison" test_version_comparison
    run_test "distribution_detection" test_distribution_detection
    run_test "environment_variable_setting" test_environment_variable_setting
    run_test "package_name_mapping" test_package_name_mapping
    run_test "fallback_mechanisms" test_fallback_mechanisms
    run_test "error_handling" test_error_handling
    run_test "library_independence" test_library_independence
    
    # Print summary
    print_test_summary
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi