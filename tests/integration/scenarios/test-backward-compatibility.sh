#!/usr/bin/env bash

# ============================================================================
# Integration Test: Backward Compatibility
# ============================================================================
# Tests that modular architecture maintains backward compatibility

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source integration framework
source "$SCRIPT_DIR/../framework/integration-framework.sh"

# ============================================================================
# Test Functions
# ============================================================================

test_command_line_flag_compatibility() {
    echo "Testing command-line flag compatibility..."
    
    # Create test container
    local dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/prepare.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "flag-compat-test" "ubuntu:24.04" "$dockerfile")
    
    # Test various flags
    assert_flag_compatibility "Skip Docker flag should work" "$container_image" "--skip-docker" "skip"
    assert_flag_compatibility "Skip Go flag should work" "$container_image" "--skip-go" "skip"
    assert_flag_compatibility "Skip Python flag should work" "$container_image" "--skip-python" "skip"
    assert_flag_compatibility "Skip .NET flag should work" "$container_image" "--skip-dotnet" "skip"
    assert_flag_compatibility "Skip JVM flag should work" "$container_image" "--skip-jvm" "skip"
    assert_flag_compatibility "Skip Kotlin flag should work" "$container_image" "--skip-kotlin" "skip"
    assert_flag_compatibility "Skip desktop flag should work" "$container_image" "--skip-desktop" "skip"
    
    # Test user flag
    local user_test_script="$INT_TEST_TEMP_DIR/test-user-flag.sh"
    cat > "$user_test_script" << 'EOF'
#!/bin/bash
# Test user flag functionality
output=$(/tmp/scripts/prepare.sh -u=testuser --dry-run 2>&1)
if [[ "$output" == *"testuser"* ]]; then
    echo "PASS: User flag works correctly"
    exit 0
else
    echo "FAIL: User flag not working"
    exit 1
fi
EOF

    if run_in_container "$container_image" bash /tmp/test-user-flag.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} User flag compatibility"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} User flag compatibility"
    fi
    ((INT_TEST_TOTAL++))
}

test_output_format_consistency() {
    echo "Testing output format consistency..."
    
    # Create test containers for both versions
    local modular_dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/prepare.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "output-test" "ubuntu:24.04" "$modular_dockerfile")
    
    # Test that output contains expected patterns
    local output_test_script="$INT_TEST_TEMP_DIR/test-output-format.sh"
    cat > "$output_test_script" << 'EOF'
#!/bin/bash
# Test output format consistency
output=$(/tmp/scripts/prepare.sh --dry-run 2>&1)

# Check for expected output patterns
patterns=(
    "Linux Development Environment Setup"
    "Detected"
    "Installing"
    "Configuring"
    "Setup completed"
)

for pattern in "${patterns[@]}"; do
    if [[ "$output" != *"$pattern"* ]]; then
        echo "FAIL: Missing expected pattern: $pattern"
        exit 1
    fi
done

echo "PASS: Output format is consistent"
exit 0
EOF

    if run_in_container "$container_image" bash /tmp/test-output-format.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} Output format consistency"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} Output format consistency"
    fi
    ((INT_TEST_TOTAL++))
}

test_installation_result_compatibility() {
    echo "Testing installation result compatibility..."
    
    # Create test container
    local dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
COPY ./tests/scripts/validate.sh /tmp/validate.sh
RUN chmod +x /tmp/scripts/prepare.sh /tmp/validate.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "install-result-test" "ubuntu:24.04" "$dockerfile")
    
    # Run installation and validation
    local install_test_script="$INT_TEST_TEMP_DIR/test-install-results.sh"
    cat > "$install_test_script" << 'EOF'
#!/bin/bash
# Test that installation results are compatible

# Run modular installation (minimal components for speed)
/tmp/scripts/prepare.sh -u=testuser --skip-desktop --skip-dotnet --skip-jvm --skip-kotlin

# Run validation
if /tmp/validate.sh; then
    echo "PASS: Installation results are valid"
    exit 0
else
    echo "FAIL: Installation results validation failed"
    exit 1
fi
EOF

    if run_in_container_timed "$container_image" "install-result-test" bash /tmp/test-install-results.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} Installation result compatibility"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} Installation result compatibility"
    fi
    ((INT_TEST_TOTAL++))
}

test_error_handling_compatibility() {
    echo "Testing error handling compatibility..."
    
    # Create test container with intentional errors
    local dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/prepare.sh
# Simulate network issues by blocking external connections
RUN echo '127.0.0.1 download.docker.com' >> /etc/hosts
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "error-handling-test" "ubuntu:24.04" "$dockerfile")
    
    # Test error handling
    local error_test_script="$INT_TEST_TEMP_DIR/test-error-handling.sh"
    cat > "$error_test_script" << 'EOF'
#!/bin/bash
# Test error handling compatibility

# Run with Docker installation (should fail due to blocked network)
output=$(/tmp/scripts/prepare.sh -u=testuser --skip-desktop --skip-go --skip-python --skip-dotnet --skip-jvm --skip-kotlin 2>&1 || true)

# Check that errors are handled gracefully
if [[ "$output" == *"error"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"failed"* ]]; then
    echo "PASS: Errors are reported correctly"
    exit 0
else
    echo "FAIL: Error handling not working correctly"
    echo "Output: $output"
    exit 1
fi
EOF

    if run_in_container "$container_image" bash /tmp/test-error-handling.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} Error handling compatibility"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} Error handling compatibility"
    fi
    ((INT_TEST_TOTAL++))
}

test_environment_variable_compatibility() {
    echo "Testing environment variable compatibility..."
    
    # Create test container
    local dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/prepare.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "env-var-test" "ubuntu:24.04" "$dockerfile")
    
    # Test environment variable handling
    local env_test_script="$INT_TEST_TEMP_DIR/test-env-vars.sh"
    cat > "$env_test_script" << 'EOF'
#!/bin/bash
# Test environment variable compatibility

# Set environment variables that should affect behavior
export INSTALL_DOCKER=false
export INSTALL_GO=false

# Run script
output=$(/tmp/scripts/prepare.sh -u=testuser --dry-run 2>&1)

# Check that environment variables are respected
if [[ "$output" == *"skip"* ]] || [[ "$output" == *"Skip"* ]]; then
    echo "PASS: Environment variables are respected"
    exit 0
else
    echo "FAIL: Environment variables not working"
    echo "Output: $output"
    exit 1
fi
EOF

    if run_in_container "$container_image" bash /tmp/test-env-vars.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} Environment variable compatibility"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} Environment variable compatibility"
    fi
    ((INT_TEST_TOTAL++))
}

test_xubuntu_25_10_compatibility() {
    echo "Testing Xubuntu 25.10 specific compatibility..."
    
    # Create Xubuntu 25.10 test container
    local dockerfile="FROM ubuntu:25.10
ENV DEBIAN_FRONTEND=noninteractive
ENV XDG_CURRENT_DESKTOP=XFCE
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc xfce4-session --no-install-recommends && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
# Simulate Xubuntu environment
RUN echo 'ID=ubuntu' > /etc/os-release
RUN echo 'VERSION_ID=\"25.10\"' >> /etc/os-release
RUN echo 'PRETTY_NAME=\"Xubuntu 25.10\"' >> /etc/os-release
RUN echo 'VERSION_CODENAME=oracular' >> /etc/os-release
COPY ./scripts/ /tmp/scripts/
COPY ./tests/scripts/validate.sh /tmp/validate.sh
RUN chmod +x /tmp/scripts/prepare.sh /tmp/validate.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "xubuntu-25-10-test" "ubuntu:25.10" "$dockerfile")
    
    # Test Xubuntu 25.10 specific functionality
    local xubuntu_test_script="$INT_TEST_TEMP_DIR/test-xubuntu-25-10.sh"
    cat > "$xubuntu_test_script" << 'EOF'
#!/bin/bash
# Test Xubuntu 25.10 compatibility

# Run installation with minimal components
/tmp/scripts/prepare.sh -u=testuser --skip-desktop --skip-dotnet --skip-jvm --skip-kotlin

# Check Xubuntu 25.10 specific features
echo "Checking Xubuntu 25.10 specific features..."

# Check eza package (should be installed for Ubuntu 25.10)
if command -v eza &>/dev/null; then
    echo "PASS: eza package installed correctly for Ubuntu 25.10"
else
    echo "FAIL: eza package not installed"
    exit 1
fi

# Check ls alias configuration
if grep -q "eza" ~/.zshrc 2>/dev/null; then
    echo "PASS: ls alias configured for eza"
else
    echo "FAIL: ls alias not configured for eza"
    exit 1
fi

# Run validation
if /tmp/validate.sh; then
    echo "PASS: Xubuntu 25.10 validation successful"
    exit 0
else
    echo "FAIL: Xubuntu 25.10 validation failed"
    exit 1
fi
EOF

    if run_in_container_timed "$container_image" "xubuntu-25-10-test" bash /tmp/test-xubuntu-25-10.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} Xubuntu 25.10 compatibility"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} Xubuntu 25.10 compatibility"
    fi
    ((INT_TEST_TOTAL++))
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo -e "${INT_CYAN}============================================${INT_RESET}"
    echo -e "${INT_CYAN}  Backward Compatibility Integration Tests${INT_RESET}"
    echo -e "${INT_CYAN}============================================${INT_RESET}"
    echo ""
    
    # Check prerequisites
    if ! command -v docker &>/dev/null; then
        echo -e "${INT_RED}Error: Docker is required for integration tests${INT_RESET}"
        exit 1
    fi
    
    # Run tests
    run_integration_test "command_line_flag_compatibility" test_command_line_flag_compatibility
    run_integration_test "output_format_consistency" test_output_format_consistency
    run_integration_test "installation_result_compatibility" test_installation_result_compatibility
    run_integration_test "error_handling_compatibility" test_error_handling_compatibility
    run_integration_test "environment_variable_compatibility" test_environment_variable_compatibility
    run_integration_test "xubuntu_25_10_compatibility" test_xubuntu_25_10_compatibility
    
    # Print summary
    print_integration_test_summary
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi