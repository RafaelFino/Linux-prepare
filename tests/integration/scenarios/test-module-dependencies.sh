#!/usr/bin/env bash

# ============================================================================
# Integration Test: Module Dependencies
# ============================================================================
# Tests module dependency resolution and execution order

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source integration framework
source "$SCRIPT_DIR/../framework/integration-framework.sh"

# ============================================================================
# Test Functions
# ============================================================================

test_system_detection_dependencies() {
    echo "Testing system-detection module dependencies..."
    
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
    container_image=$(create_test_container "module-deps-test" "ubuntu:24.04" "$dockerfile")
    
    # Test that system-detection has no dependencies
    assert_module_dependencies "system-detection should have no dependencies" "$container_image" "system-detection"
    
    # Test that other modules depend on system-detection
    assert_module_dependencies "docker-install should depend on system-detection" "$container_image" "docker-install" "system-detection"
    assert_module_dependencies "terminal-config should depend on system-detection" "$container_image" "terminal-config" "system-detection"
    assert_module_dependencies "desktop-components should depend on system-detection" "$container_image" "desktop-components" "system-detection"
}

test_language_module_dependencies() {
    echo "Testing language module dependencies..."
    
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
    container_image=$(create_test_container "lang-deps-test" "ubuntu:24.04" "$dockerfile")
    
    # Test language module dependencies
    assert_module_dependencies "golang-install should depend on system-detection" "$container_image" "languages/golang-install" "system-detection"
    assert_module_dependencies "python-install should depend on system-detection" "$container_image" "languages/python-install" "system-detection"
    assert_module_dependencies "dotnet-install should depend on system-detection" "$container_image" "languages/dotnet-install" "system-detection"
    assert_module_dependencies "jvm-kotlin-install should depend on system-detection" "$container_image" "languages/jvm-kotlin-install" "system-detection"
}

test_execution_order_resolution() {
    echo "Testing module execution order resolution..."
    
    # Create test container with execution logging
    local dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/prepare.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "exec-order-test" "ubuntu:24.04" "$dockerfile")
    
    # Expected execution order for core modules
    local expected_order=(
        "system-detection"
        "docker-install"
        "languages/golang-install"
        "languages/python-install"
        "terminal-config"
    )
    
    # Test execution order (this is a simplified test)
    # In a real implementation, this would capture actual execution order
    assert_execution_order "Modules should execute in dependency order" "$container_image" "${expected_order[@]}"
}

test_dependency_failure_handling() {
    echo "Testing dependency failure handling..."
    
    # Create test container with broken dependency
    local dockerfile="FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg bc && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
# Break system-detection module
RUN sed -i 's/detect_distribution/broken_function/g' /tmp/scripts/modules/system-detection.sh
RUN chmod +x /tmp/scripts/prepare.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local container_image
    container_image=$(create_test_container "dep-failure-test" "ubuntu:24.04" "$dockerfile")
    
    # Test that dependent modules fail when dependency fails
    local test_script="$INT_TEST_TEMP_DIR/test-dep-failure.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
# Test that modules fail gracefully when dependencies fail
source /tmp/scripts/lib/module-framework.sh

# Try to execute docker-install (depends on system-detection)
if execute_module "docker-install" 2>/dev/null; then
    echo "FAIL: Module should have failed due to dependency failure"
    exit 1
else
    echo "PASS: Module correctly failed due to dependency failure"
    exit 0
fi
EOF

    if run_in_container "$container_image" bash /tmp/test-dep-failure.sh; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} Modules handle dependency failures correctly"
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} Modules do not handle dependency failures correctly"
    fi
    ((INT_TEST_TOTAL++))
}

test_circular_dependency_detection() {
    echo "Testing circular dependency detection..."
    
    # This test would check that the framework detects circular dependencies
    # For now, we'll skip it as it requires more complex setup
    skip_integration_test "Circular dependency detection" "requires framework enhancement"
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo -e "${INT_CYAN}============================================${INT_RESET}"
    echo -e "${INT_CYAN}  Module Dependencies Integration Tests${INT_RESET}"
    echo -e "${INT_CYAN}============================================${INT_RESET}"
    echo ""
    
    # Check prerequisites
    if ! command -v docker &>/dev/null; then
        echo -e "${INT_RED}Error: Docker is required for integration tests${INT_RESET}"
        exit 1
    fi
    
    # Run tests
    run_integration_test "system_detection_dependencies" test_system_detection_dependencies
    run_integration_test "language_module_dependencies" test_language_module_dependencies
    run_integration_test "execution_order_resolution" test_execution_order_resolution
    run_integration_test "dependency_failure_handling" test_dependency_failure_handling
    run_integration_test "circular_dependency_detection" test_circular_dependency_detection
    
    # Print summary
    print_integration_test_summary
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi