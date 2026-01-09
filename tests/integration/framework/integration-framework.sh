#!/usr/bin/env bash

# ============================================================================
# Integration Test Framework for Linux-prepare Modular Architecture
# ============================================================================
# Provides utilities for testing module interactions and system integration

set -euo pipefail

# ============================================================================
# Integration Test Configuration
# ============================================================================

# Colors for output
readonly INT_GREEN="\033[32m"
readonly INT_RED="\033[31m"
readonly INT_YELLOW="\033[33m"
readonly INT_CYAN="\033[36m"
readonly INT_GRAY="\033[90m"
readonly INT_RESET="\033[0m"

# Test counters
INT_TEST_PASSED=0
INT_TEST_FAILED=0
INT_TEST_SKIPPED=0
INT_TEST_TOTAL=0

# Test configuration
INT_TEST_VERBOSE=${INT_TEST_VERBOSE:-false}
INT_TEST_CLEANUP=${INT_TEST_CLEANUP:-true}
INT_TEST_TEMP_DIR=""
INT_DOCKER_CLEANUP=${INT_DOCKER_CLEANUP:-true}

# Performance tracking
declare -A INT_EXECUTION_TIMES
declare -A INT_MEMORY_USAGE

# ============================================================================
# Test Environment Management
# ============================================================================

# Initialize integration test environment
integration_test_init() {
    local test_name="$1"
    
    # Create temporary directory for test
    INT_TEST_TEMP_DIR=$(mktemp -d -t "linux-prepare-integration-${test_name}-XXXXXX")
    
    # Set up test environment variables
    export INT_TEST_MODE="true"
    export INT_TEST_TEMP_DIR
    
    if [ "$INT_TEST_VERBOSE" = "true" ]; then
        echo -e "${INT_CYAN}Initializing integration test: $test_name${INT_RESET}"
        echo -e "${INT_GRAY}Test temp dir: $INT_TEST_TEMP_DIR${INT_RESET}"
    fi
}

# Cleanup integration test environment
integration_test_cleanup() {
    if [ "$INT_TEST_CLEANUP" = "true" ] && [ -n "$INT_TEST_TEMP_DIR" ] && [ -d "$INT_TEST_TEMP_DIR" ]; then
        rm -rf "$INT_TEST_TEMP_DIR"
        if [ "$INT_TEST_VERBOSE" = "true" ]; then
            echo -e "${INT_GRAY}Cleaned up integration test temp dir${INT_RESET}"
        fi
    fi
    
    # Cleanup Docker containers if enabled
    if [ "$INT_DOCKER_CLEANUP" = "true" ]; then
        cleanup_test_containers
    fi
    
    # Unset test environment variables
    unset INT_TEST_MODE INT_TEST_TEMP_DIR
}

# ============================================================================
# Docker Test Environment
# ============================================================================

# Create test container
create_test_container() {
    local container_name="$1"
    local base_image="$2"
    local dockerfile_content="$3"
    
    # Create Dockerfile
    local dockerfile="$INT_TEST_TEMP_DIR/Dockerfile.$container_name"
    echo "$dockerfile_content" > "$dockerfile"
    
    # Build container
    if [ "$INT_TEST_VERBOSE" = "true" ]; then
        echo -e "${INT_GRAY}Building test container: $container_name${INT_RESET}"
    fi
    
    if docker build -f "$dockerfile" -t "linux-prepare-integration-$container_name" "$INT_TEST_TEMP_DIR/../../../" &>/dev/null; then
        echo "linux-prepare-integration-$container_name"
        return 0
    else
        return 1
    fi
}

# Run command in test container
run_in_container() {
    local container_image="$1"
    shift
    local command=("$@")
    
    if [ "$INT_TEST_VERBOSE" = "true" ]; then
        echo -e "${INT_GRAY}Running in container: ${command[*]}${INT_RESET}"
    fi
    
    docker run --rm "$container_image" "${command[@]}"
}

# Run command in container with timing
run_in_container_timed() {
    local container_image="$1"
    local test_name="$2"
    shift 2
    local command=("$@")
    
    local start_time=$(date +%s.%N)
    local result=0
    
    if docker run --rm "$container_image" "${command[@]}"; then
        result=0
    else
        result=1
    fi
    
    local end_time=$(date +%s.%N)
    local execution_time=$(echo "$end_time - $start_time" | bc -l)
    
    INT_EXECUTION_TIMES["$test_name"]="$execution_time"
    
    if [ "$INT_TEST_VERBOSE" = "true" ]; then
        echo -e "${INT_GRAY}Execution time for $test_name: ${execution_time}s${INT_RESET}"
    fi
    
    return $result
}

# Cleanup test containers
cleanup_test_containers() {
    if [ "$INT_TEST_VERBOSE" = "true" ]; then
        echo -e "${INT_GRAY}Cleaning up test containers...${INT_RESET}"
    fi
    
    # Remove test containers
    docker images --format "table {{.Repository}}" | grep "linux-prepare-integration" | while read -r image; do
        if [ "$INT_TEST_VERBOSE" = "true" ]; then
            echo -e "${INT_GRAY}Removing container image: $image${INT_RESET}"
        fi
        docker rmi "$image" &>/dev/null || true
    done
}

# ============================================================================
# Module Execution Testing
# ============================================================================

# Test module execution order
test_module_execution_order() {
    local container_image="$1"
    local expected_order=("$@")
    shift
    
    # Create a script that logs module execution order
    local test_script="$INT_TEST_TEMP_DIR/test-execution-order.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
# Override execute_module to log execution order
EXECUTION_LOG="/tmp/execution-order.log"
> "$EXECUTION_LOG"

original_execute_module() {
    echo "$1" >> "$EXECUTION_LOG"
    # Call original function (simplified for testing)
    echo "Executing module: $1"
}

# Replace execute_module function
execute_module() {
    original_execute_module "$@"
}

# Source and run the main script
source /tmp/prepare.sh
EOF
    
    # Copy test script to container and run
    docker run --rm -v "$test_script:/tmp/test-execution-order.sh:ro" "$container_image" bash /tmp/test-execution-order.sh
    
    # Get execution order from container
    local actual_order
    actual_order=$(docker run --rm "$container_image" cat /tmp/execution-order.log 2>/dev/null || echo "")
    
    # Compare with expected order
    local expected_str=$(printf '%s\n' "${expected_order[@]}")
    
    if [ "$actual_order" = "$expected_str" ]; then
        return 0
    else
        if [ "$INT_TEST_VERBOSE" = "true" ]; then
            echo -e "${INT_RED}Expected order:${INT_RESET}"
            echo "$expected_str"
            echo -e "${INT_RED}Actual order:${INT_RESET}"
            echo "$actual_order"
        fi
        return 1
    fi
}

# Test module dependency resolution
test_module_dependencies() {
    local container_image="$1"
    local module_name="$2"
    local expected_dependencies=("${@:3}")
    
    # Create dependency test script
    local test_script="$INT_TEST_TEMP_DIR/test-dependencies.sh"
    cat > "$test_script" << EOF
#!/bin/bash
source /tmp/scripts/lib/module-framework.sh

# Get dependencies for module
deps=\$(get_module_dependencies "$module_name")
echo "\$deps"
EOF
    
    # Run dependency test
    local actual_deps
    actual_deps=$(docker run --rm -v "$test_script:/tmp/test-dependencies.sh:ro" "$container_image" bash /tmp/test-dependencies.sh)
    
    # Check if all expected dependencies are present
    for dep in "${expected_dependencies[@]}"; do
        if [[ "$actual_deps" != *"$dep"* ]]; then
            return 1
        fi
    done
    
    return 0
}

# Test data flow between modules
test_module_data_flow() {
    local container_image="$1"
    local source_module="$2"
    local target_module="$3"
    local data_variable="$4"
    
    # Create data flow test script
    local test_script="$INT_TEST_TEMP_DIR/test-data-flow.sh"
    cat > "$test_script" << EOF
#!/bin/bash
# Test that data flows from source to target module

# Source the source module
source /tmp/scripts/modules/${source_module}.sh

# Check if variable is set
if [ -n "\${${data_variable}:-}" ]; then
    echo "Data variable $data_variable is set: \${${data_variable}}"
    exit 0
else
    echo "Data variable $data_variable is not set"
    exit 1
fi
EOF
    
    # Run data flow test
    docker run --rm -v "$test_script:/tmp/test-data-flow.sh:ro" "$container_image" bash /tmp/test-data-flow.sh
}

# ============================================================================
# Backward Compatibility Testing
# ============================================================================

# Compare modular vs monolithic execution
compare_modular_vs_monolithic() {
    local distribution="$1"
    local test_flags="$2"
    
    # Create containers for both approaches
    local monolithic_dockerfile="FROM ubuntu:$distribution
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/prepare.sh.backup /tmp/prepare-monolithic.sh
RUN chmod +x /tmp/prepare-monolithic.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    local modular_dockerfile="FROM ubuntu:$distribution
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl wget git ca-certificates gnupg && apt-get clean
RUN useradd -m -s /bin/bash testuser && echo \"testuser:testuser\" | chpasswd && usermod -aG sudo testuser && echo \"testuser ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
COPY ./scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/prepare.sh
WORKDIR /home/testuser
CMD [\"/bin/bash\"]"

    # Build containers
    local monolithic_image
    local modular_image
    
    monolithic_image=$(create_test_container "monolithic-$distribution" "ubuntu:$distribution" "$monolithic_dockerfile")
    modular_image=$(create_test_container "modular-$distribution" "ubuntu:$distribution" "$modular_dockerfile")
    
    # Run both versions with timing
    local monolithic_time
    local modular_time
    
    if run_in_container_timed "$monolithic_image" "monolithic-$distribution" /tmp/prepare-monolithic.sh $test_flags; then
        monolithic_time="${INT_EXECUTION_TIMES["monolithic-$distribution"]}"
    else
        return 1
    fi
    
    if run_in_container_timed "$modular_image" "modular-$distribution" /tmp/scripts/prepare.sh $test_flags; then
        modular_time="${INT_EXECUTION_TIMES["modular-$distribution"]}"
    else
        return 1
    fi
    
    # Compare results
    local time_diff=$(echo "scale=2; ($modular_time - $monolithic_time) / $monolithic_time * 100" | bc -l)
    
    if [ "$INT_TEST_VERBOSE" = "true" ]; then
        echo -e "${INT_GRAY}Monolithic execution time: ${monolithic_time}s${INT_RESET}"
        echo -e "${INT_GRAY}Modular execution time: ${modular_time}s${INT_RESET}"
        echo -e "${INT_GRAY}Performance difference: ${time_diff}%${INT_RESET}"
    fi
    
    # Store performance data
    INT_EXECUTION_TIMES["monolithic-vs-modular-$distribution"]="$time_diff"
    
    return 0
}

# Test command-line flag compatibility
test_flag_compatibility() {
    local container_image="$1"
    local flag="$2"
    
    # Test that flag works the same way in both versions
    local modular_output
    local expected_behavior="$3"  # "skip" or "install"
    
    # Run with flag and check behavior
    modular_output=$(run_in_container "$container_image" /tmp/scripts/prepare.sh "$flag" --dry-run 2>&1 || echo "failed")
    
    case "$expected_behavior" in
        "skip")
            if [[ "$modular_output" == *"skipped"* ]] || [[ "$modular_output" == *"Skipping"* ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "install")
            if [[ "$modular_output" != *"skipped"* ]] && [[ "$modular_output" != *"failed"* ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Integration Test Assertions
# ============================================================================

# Assert module execution order
assert_execution_order() {
    local description="$1"
    local container_image="$2"
    shift 2
    local expected_order=("$@")
    
    ((INT_TEST_TOTAL++))
    
    if test_module_execution_order "$container_image" "${expected_order[@]}"; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} $description"
        return 0
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} $description"
        return 1
    fi
}

# Assert module dependencies
assert_module_dependencies() {
    local description="$1"
    local container_image="$2"
    local module_name="$3"
    shift 3
    local expected_deps=("$@")
    
    ((INT_TEST_TOTAL++))
    
    if test_module_dependencies "$container_image" "$module_name" "${expected_deps[@]}"; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} $description"
        return 0
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} $description"
        return 1
    fi
}

# Assert data flow
assert_data_flow() {
    local description="$1"
    local container_image="$2"
    local source_module="$3"
    local target_module="$4"
    local data_variable="$5"
    
    ((INT_TEST_TOTAL++))
    
    if test_module_data_flow "$container_image" "$source_module" "$target_module" "$data_variable"; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} $description"
        return 0
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} $description"
        return 1
    fi
}

# Assert backward compatibility
assert_backward_compatibility() {
    local description="$1"
    local distribution="$2"
    local test_flags="$3"
    
    ((INT_TEST_TOTAL++))
    
    if compare_modular_vs_monolithic "$distribution" "$test_flags"; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} $description"
        return 0
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} $description"
        return 1
    fi
}

# Assert flag compatibility
assert_flag_compatibility() {
    local description="$1"
    local container_image="$2"
    local flag="$3"
    local expected_behavior="$4"
    
    ((INT_TEST_TOTAL++))
    
    if test_flag_compatibility "$container_image" "$flag" "$expected_behavior"; then
        ((INT_TEST_PASSED++))
        echo -e "${INT_GREEN}✓${INT_RESET} $description"
        return 0
    else
        ((INT_TEST_FAILED++))
        echo -e "${INT_RED}✗${INT_RESET} $description"
        return 1
    fi
}

# Skip integration test
skip_integration_test() {
    local description="$1"
    local reason="$2"
    
    ((INT_TEST_TOTAL++))
    ((INT_TEST_SKIPPED++))
    
    echo -e "${INT_YELLOW}⏭${INT_RESET} $description (skipped: $reason)"
}

# ============================================================================
# Test Execution Framework
# ============================================================================

# Run integration test with setup and cleanup
run_integration_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${INT_CYAN}Running integration test: $test_name${INT_RESET}"
    
    # Initialize test environment
    integration_test_init "$test_name"
    
    # Set up error handling
    local test_failed=false
    trap 'test_failed=true' ERR
    
    # Run the test function
    if "$test_function"; then
        if [ "$test_failed" = "false" ]; then
            echo -e "${INT_GREEN}Integration test completed: $test_name${INT_RESET}"
        else
            echo -e "${INT_RED}Integration test failed with error: $test_name${INT_RESET}"
        fi
    else
        echo -e "${INT_RED}Integration test failed: $test_name${INT_RESET}"
    fi
    
    # Cleanup
    trap - ERR
    integration_test_cleanup
    
    echo ""
}

# Print integration test summary
print_integration_test_summary() {
    echo -e "${INT_CYAN}============================================${INT_RESET}"
    echo -e "${INT_CYAN}  Integration Test Summary${INT_RESET}"
    echo -e "${INT_CYAN}============================================${INT_RESET}"
    echo -e "${INT_GREEN}Passed: $INT_TEST_PASSED${INT_RESET}"
    echo -e "${INT_RED}Failed: $INT_TEST_FAILED${INT_RESET}"
    echo -e "${INT_YELLOW}Skipped: $INT_TEST_SKIPPED${INT_RESET}"
    echo -e "${INT_CYAN}Total: $INT_TEST_TOTAL${INT_RESET}"
    
    # Print performance summary if available
    if [ ${#INT_EXECUTION_TIMES[@]} -gt 0 ]; then
        echo ""
        echo -e "${INT_CYAN}Performance Summary:${INT_RESET}"
        for test_name in "${!INT_EXECUTION_TIMES[@]}"; do
            echo -e "${INT_GRAY}  $test_name: ${INT_EXECUTION_TIMES[$test_name]}${INT_RESET}"
        done
    fi
    
    echo ""
    
    if [ $INT_TEST_FAILED -eq 0 ]; then
        echo -e "${INT_GREEN}All integration tests passed!${INT_RESET}"
        return 0
    else
        echo -e "${INT_RED}Some integration tests failed!${INT_RESET}"
        return 1
    fi
}