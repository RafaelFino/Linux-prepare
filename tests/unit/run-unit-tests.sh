#!/usr/bin/env bash

# ============================================================================
# Unit Test Runner for Linux-prepare Modular Architecture
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
readonly GREEN="\033[32m"
readonly RED="\033[31m"
readonly YELLOW="\033[33m"
readonly CYAN="\033[36m"
readonly RESET="\033[0m"

# Configuration
VERBOSE=${VERBOSE:-false}
CLEANUP=${CLEANUP:-true}
SPECIFIC_TEST=""

# Test results
TOTAL_TEST_FILES=0
PASSED_TEST_FILES=0
FAILED_TEST_FILES=0

# ============================================================================
# Usage and Help
# ============================================================================

show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_NAME]"
    echo ""
    echo "Run unit tests for Linux-prepare modular architecture"
    echo ""
    echo "OPTIONS:"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -h, --help        Show this help message"
    echo "  --no-cleanup      Don't clean up temporary files"
    echo ""
    echo "TEST_NAME:"
    echo "  Specific test to run (e.g., system-detection, docker-install)"
    echo "  If not specified, all tests will be run"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 system-detection          # Run only system-detection tests"
    echo "  $0 --verbose docker-install  # Run docker-install tests with verbose output"
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                export TEST_VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --no-cleanup)
                CLEANUP=false
                export TEST_CLEANUP=false
                shift
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${RESET}"
                show_usage
                exit 1
                ;;
            *)
                SPECIFIC_TEST="$1"
                shift
                ;;
        esac
    done
}

# ============================================================================
# Test Discovery
# ============================================================================

# Find all test files
find_test_files() {
    local test_files=()
    
    if [ -n "$SPECIFIC_TEST" ]; then
        # Look for specific test
        local test_file="$SCRIPT_DIR/modules/test-${SPECIFIC_TEST}.sh"
        if [ -f "$test_file" ]; then
            test_files+=("$test_file")
        fi
        
        # Also check lib tests
        test_file="$SCRIPT_DIR/lib/test-${SPECIFIC_TEST}.sh"
        if [ -f "$test_file" ]; then
            test_files+=("$test_file")
        fi
        
        if [ ${#test_files[@]} -eq 0 ]; then
            echo -e "${RED}Error: Test '$SPECIFIC_TEST' not found${RESET}"
            echo "Available tests:"
            list_available_tests
            exit 1
        fi
    else
        # Find all test files
        while IFS= read -r -d '' file; do
            test_files+=("$file")
        done < <(find "$SCRIPT_DIR" -name "test-*.sh" -type f -print0 | sort -z)
    fi
    
    printf '%s\n' "${test_files[@]}"
}

# List available tests
list_available_tests() {
    echo "Module tests:"
    find "$SCRIPT_DIR/modules" -name "test-*.sh" -type f -exec basename {} .sh \; | sed 's/test-/  - /' | sort
    
    echo "Library tests:"
    find "$SCRIPT_DIR/lib" -name "test-*.sh" -type f -exec basename {} .sh \; | sed 's/test-/  - /' | sort
}

# ============================================================================
# Test Execution
# ============================================================================

# Run a single test file
run_test_file() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${CYAN}  Running: $test_name${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    
    ((TOTAL_TEST_FILES++))
    
    # Check if test file is executable
    if [ ! -x "$test_file" ]; then
        chmod +x "$test_file"
    fi
    
    # Run the test
    local start_time=$(date +%s)
    if bash "$test_file"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        ((PASSED_TEST_FILES++))
        echo -e "${GREEN}✓ $test_name completed successfully (${duration}s)${RESET}"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        ((FAILED_TEST_FILES++))
        echo -e "${RED}✗ $test_name failed (${duration}s)${RESET}"
        return 1
    fi
}

# ============================================================================
# Prerequisites Check
# ============================================================================

check_prerequisites() {
    echo -e "${CYAN}Checking prerequisites...${RESET}"
    
    # Check if we're in the right directory
    if [ ! -f "$SCRIPT_DIR/../../scripts/prepare.sh" ]; then
        echo -e "${RED}Error: Must run from project root or tests/unit directory${RESET}"
        echo "Current directory: $(pwd)"
        echo "Expected to find: scripts/prepare.sh"
        exit 1
    fi
    
    # Check required commands
    local missing_commands=()
    
    for cmd in bash mktemp bc; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required commands: ${missing_commands[*]}${RESET}"
        exit 1
    fi
    
    # Check if modules exist
    if [ ! -d "$SCRIPT_DIR/../../scripts/modules" ]; then
        echo -e "${RED}Error: Modules directory not found${RESET}"
        echo "Expected: scripts/modules/"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Prerequisites check passed${RESET}"
    echo ""
}

# ============================================================================
# Performance Benchmarking
# ============================================================================

run_performance_benchmark() {
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${CYAN}  Performance Benchmark${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    
    # This is a placeholder for performance testing
    # In a real implementation, this would compare modular vs monolithic execution times
    
    echo "Performance benchmarking is not yet implemented in this test suite."
    echo "This would compare:"
    echo "  - Modular architecture execution time"
    echo "  - Monolithic script execution time"
    echo "  - Memory usage comparison"
    echo "  - Module loading overhead"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${CYAN}  Linux-prepare Unit Test Runner${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check prerequisites
    check_prerequisites
    
    # Find test files
    local test_files
    mapfile -t test_files < <(find_test_files)
    
    if [ ${#test_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No test files found${RESET}"
        exit 0
    fi
    
    echo -e "${CYAN}Found ${#test_files[@]} test file(s) to run${RESET}"
    if [ "$VERBOSE" = "true" ]; then
        printf '  - %s\n' "${test_files[@]}"
    fi
    echo ""
    
    # Run tests
    local overall_start_time=$(date +%s)
    local failed_tests=()
    
    for test_file in "${test_files[@]}"; do
        if ! run_test_file "$test_file"; then
            failed_tests+=("$(basename "$test_file" .sh)")
        fi
        echo ""
    done
    
    local overall_end_time=$(date +%s)
    local total_duration=$((overall_end_time - overall_start_time))
    
    # Run performance benchmark if requested
    if [ "$VERBOSE" = "true" ] && [ -z "$SPECIFIC_TEST" ]; then
        run_performance_benchmark
    fi
    
    # Print summary
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${CYAN}  Test Summary${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${GREEN}Passed: $PASSED_TEST_FILES${RESET}"
    echo -e "${RED}Failed: $FAILED_TEST_FILES${RESET}"
    echo -e "${CYAN}Total: $TOTAL_TEST_FILES${RESET}"
    echo -e "${CYAN}Duration: ${total_duration}s${RESET}"
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed tests:${RESET}"
        printf '  - %s\n' "${failed_tests[@]}"
    fi
    
    echo ""
    
    # Exit with appropriate code
    if [ $FAILED_TEST_FILES -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${RESET}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${RESET}"
        exit 1
    fi
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi