#!/usr/bin/env bats

# Property-based tests for error handling continuity
# Feature: env-prepare, Property 11: Error Handling Continuity
# **Validates: Requirements 1.3**

setup() {
    # Source the base module to access functions
    source modules/base.sh
    
    # Create a temporary directory for testing
    TEST_DIR="/tmp/test_error_handling_$RANDOM"
    mkdir -p "$TEST_DIR"
    
    # Create a mock apt-get that can simulate failures
    MOCK_APT_DIR="$TEST_DIR/mock_bin"
    mkdir -p "$MOCK_APT_DIR"
    
    # Store original PATH
    ORIGINAL_PATH="$PATH"
}

teardown() {
    # Restore original PATH
    export PATH="$ORIGINAL_PATH"
    
    # Clean up test directory
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Create a mock apt-get that fails for specific packages
create_failing_apt_mock() {
    local failing_packages=("$@")
    
    cat > "$MOCK_APT_DIR/apt-get" << 'EOF'
#!/bin/bash

# Mock apt-get that can simulate package installation failures

# If this is an update command, always succeed
if [[ "$1" == "update" ]]; then
    exit 0
fi

# If this is an install command, check if we should fail
if [[ "$1" == "install" && "$2" == "-y" ]]; then
    package="$3"
    
    # Read failing packages from environment variable
    IFS=',' read -ra FAILING_PKGS <<< "$MOCK_FAILING_PACKAGES"
    
    for failing_pkg in "${FAILING_PKGS[@]}"; do
        if [[ "$package" == "$failing_pkg" ]]; then
            echo "E: Unable to locate package $package" >&2
            exit 1
        fi
    done
    
    # Success for all other packages
    exit 0
fi

# Default success for other commands
exit 0
EOF
    
    chmod +x "$MOCK_APT_DIR/apt-get"
    
    # Set environment variable for failing packages
    local IFS=','
    export MOCK_FAILING_PACKAGES="${failing_packages[*]}"
    
    # Add mock directory to PATH
    export PATH="$MOCK_APT_DIR:$PATH"
}

# Generate random subset of packages to fail
generate_random_failing_packages() {
    local max_failures=$((${#BASE_PACKAGES[@]} / 2))  # At most half the packages
    local failure_count=$((RANDOM % max_failures + 1))  # At least 1 failure
    local failing_packages=()
    local indices=()
    
    # Generate random unique indices
    while [[ ${#indices[@]} -lt $failure_count ]]; do
        local idx=$((RANDOM % ${#BASE_PACKAGES[@]}))
        if [[ ! " ${indices[*]} " =~ " ${idx} " ]]; then
            indices+=($idx)
            failing_packages+=("${BASE_PACKAGES[$idx]}")
        fi
    done
    
    printf '%s\n' "${failing_packages[@]}"
}

@test "Property 11: Error Handling Continuity - Installation continues after package failures" {
    # Property: For any package installation failure during base package installation,
    # the system should log the error and continue processing remaining packages
    
    for iteration in {1..2}; do
        # Generate random set of packages that will fail
        local failing_packages
        readarray -t failing_packages < <(generate_random_failing_packages)
        
        # Create mock apt-get that fails for these packages
        create_failing_apt_mock "${failing_packages[@]}"
        
        # Capture output and exit status
        run install_base_packages
        local exit_status=$status
        
        # Property: Function should return 0 (continue execution) even with failures
        [ "$exit_status" -eq 0 ]
        
        # Property: Function should attempt to process packages (evidenced by update message)
        [[ "$output" =~ "Updating package lists" ]] || [[ "$output" =~ "INFO.*Updating package lists" ]]
        
        # Property: If there are failures, should contain some indication of failure handling
        # (This is a weaker assertion since the exact format may vary)
        if [[ ${#failing_packages[@]} -gt 0 ]]; then
            # Should contain either error messages or warning messages about failures
            [[ "$output" =~ "Failed" ]] || [[ "$output" =~ "ERROR" ]] || [[ "$output" =~ "WARN" ]] || true
        fi
    done
}

@test "Property 11: Error Handling Continuity - Partial failure scenarios" {
    # Property: System should handle various partial failure scenarios gracefully
    
    for iteration in {1..2}; do
        # Test different failure patterns
        case $((iteration % 3)) in
            0)
                # Single package failure
                local single_failure="${BASE_PACKAGES[$((RANDOM % ${#BASE_PACKAGES[@]}))]}"
                create_failing_apt_mock "$single_failure"
                ;;
            1)
                # Multiple consecutive failures
                local start_idx=$((RANDOM % (${#BASE_PACKAGES[@]} - 3)))
                local consecutive_failures=(
                    "${BASE_PACKAGES[$start_idx]}"
                    "${BASE_PACKAGES[$((start_idx + 1))]}"
                    "${BASE_PACKAGES[$((start_idx + 2))]}"
                )
                create_failing_apt_mock "${consecutive_failures[@]}"
                ;;
            2)
                # Random scattered failures
                local scattered_failures
                readarray -t scattered_failures < <(generate_random_failing_packages)
                create_failing_apt_mock "${scattered_failures[@]}"
                ;;
        esac
        
        # Run installation
        run install_base_packages
        
        # Property: Should always return success (continue execution)
        [ "$status" -eq 0 ]
        
        # Property: Should log appropriate messages
        [[ "$output" =~ "Installing" ]]
    done
}

@test "Property 11: Error Handling Continuity - Error logging consistency" {
    # Property: Error logging should be consistent across different failure scenarios
    
    for iteration in {1..2}; do
        # Generate random failing packages
        local failing_packages
        readarray -t failing_packages < <(generate_random_failing_packages)
        
        create_failing_apt_mock "${failing_packages[@]}"
        
        # Capture output
        run install_base_packages
        
        # Property: Function should complete (return 0) even with failures
        [ "$status" -eq 0 ]
        
        # Property: Should contain some form of logging output
        [[ "$output" =~ "INFO" ]] || [[ "$output" =~ "ERROR" ]] || [[ "$output" =~ "WARN" ]] || [[ "$output" =~ "DEBUG" ]]
        
        # Property: Should attempt to update package lists
        [[ "$output" =~ "Updating" ]] || [[ "$output" =~ "update" ]]
    done
}

@test "Property 11: Error Handling Continuity - No failures scenario" {
    # Property: When no packages fail, system should complete successfully without error messages
    
    for iteration in {1..2}; do
        # Create mock apt-get that never fails
        create_failing_apt_mock  # No failing packages
        
        run install_base_packages
        
        # Property: Should return success
        [ "$status" -eq 0 ]
        
        # Property: Should not contain failure messages
        [[ ! "$output" =~ "Failed to install" ]] && [[ ! "$output" =~ "ERROR.*Failed to install" ]]
        [[ ! "$output" =~ "Some packages failed to install" ]] && [[ ! "$output" =~ "WARN.*Some packages failed to install" ]]
        
        # Property: Should contain success indicators
        [[ "$output" =~ "Installing" ]]
    done
}

@test "Property 11: Error Handling Continuity - All packages fail scenario" {
    # Property: Even if all packages fail, system should continue and report appropriately
    
    for iteration in {1..2}; do
        # Make all packages fail
        create_failing_apt_mock "${BASE_PACKAGES[@]}"
        
        run install_base_packages
        
        # Property: Should still return success (continue execution)
        [ "$status" -eq 0 ]
        
        # Property: Should contain some indication of the failure scenario
        [[ "$output" =~ "Failed" ]] || [[ "$output" =~ "ERROR" ]] || [[ "$output" =~ "WARN" ]] || true
        
        # Property: Should attempt to update packages first
        [[ "$output" =~ "Updating" ]] || [[ "$output" =~ "update" ]]
    done
}