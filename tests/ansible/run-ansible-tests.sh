#!/bin/bash

# ============================================================================
# Ansible Test Runner
# ============================================================================
# This script orchestrates the execution of all Ansible tests across multiple
# distributions, including syntax checks, role tests, integration tests, and
# idempotency validation.
# ============================================================================

set -e

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
CONFIG_FILE="$SCRIPT_DIR/config/test-config.yml"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Parse command-line arguments
SPECIFIC_DISTRO=""
SPECIFIC_PLAYBOOK=""
SPECIFIC_ROLE=""
QUICK_MODE=false
DERIVATIVES_ONLY=false
SKIP_SYNTAX=false
SKIP_IDEMPOTENCY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --distro)
            SPECIFIC_DISTRO="$2"
            shift 2
            ;;
        --playbook)
            SPECIFIC_PLAYBOOK="$2"
            shift 2
            ;;
        --role)
            SPECIFIC_ROLE="$2"
            shift 2
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --derivatives)
            DERIVATIVES_ONLY=true
            shift
            ;;
        --skip-syntax)
            SKIP_SYNTAX=true
            shift
            ;;
        --skip-idempotency)
            SKIP_IDEMPOTENCY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --distro <name>        Test specific distribution only"
            echo "  --playbook <name>      Test specific playbook only"
            echo "  --role <name>          Test specific role only"
            echo "  --quick                Quick test (Ubuntu only, no idempotency)"
            echo "  --derivatives          Test derivatives only (Xubuntu, Mint)"
            echo "  --skip-syntax          Skip syntax checks"
            echo "  --skip-idempotency     Skip idempotency tests"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Run all tests"
            echo "  $0 --quick                            # Quick test"
            echo "  $0 --distro ubuntu-24.04              # Test Ubuntu only"
            echo "  $0 --playbook server.yml              # Test server playbook"
            echo "  $0 --role docker                      # Test docker role"
            echo "  $0 --derivatives                      # Test Xubuntu and Mint"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Create results directory
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEST_RUN_DIR="$RESULTS_DIR/$TIMESTAMP"
mkdir -p "$TEST_RUN_DIR"

echo "============================================"
echo "  Ansible Test Suite"
echo "============================================"
echo "Timestamp: $TIMESTAMP"
echo "Results: $TEST_RUN_DIR"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${CYAN}--- Checking Prerequisites ---${RESET}"
    
    local prereq_failed=false
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker not found${RESET}"
        echo "  Please install Docker: https://docs.docker.com/get-docker/"
        prereq_failed=true
    else
        echo -e "${GREEN}✓ Docker found${RESET}"
    fi
    
    if ! docker ps &> /dev/null; then
        echo -e "${RED}✗ Docker daemon not running${RESET}"
        echo "  Please start Docker service"
        prereq_failed=true
    else
        echo -e "${GREEN}✓ Docker daemon running${RESET}"
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}✗ Ansible not found${RESET}"
        echo "  Please install Ansible: sudo apt install ansible"
        prereq_failed=true
    else
        echo -e "${GREEN}✓ Ansible found${RESET}"
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ Python 3 not found${RESET}"
        prereq_failed=true
    else
        echo -e "${GREEN}✓ Python 3 found${RESET}"
    fi
    
    if [ "$prereq_failed" = true ]; then
        echo ""
        echo -e "${RED}Prerequisites check failed. Please install missing dependencies.${RESET}"
        exit 1
    fi
    
    echo ""
}

# Run syntax checks
run_syntax_checks() {
    if [ "$SKIP_SYNTAX" = true ]; then
        echo -e "${YELLOW}Skipping syntax checks${RESET}"
        return 0
    fi
    
    echo -e "${CYAN}--- Running Syntax Checks ---${RESET}"
    ((TOTAL_TESTS++))
    
    local syntax_log="$TEST_RUN_DIR/syntax-check.log"
    
    if [ -n "$SPECIFIC_PLAYBOOK" ]; then
        if "$SCRIPT_DIR/scripts/syntax-check.sh" --playbook "$SPECIFIC_PLAYBOOK" > "$syntax_log" 2>&1; then
            echo -e "${GREEN}✓ Syntax checks passed${RESET}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}✗ Syntax checks failed${RESET}"
            echo "  Log: $syntax_log"
            ((FAILED_TESTS++))
            return 1
        fi
    elif [ -n "$SPECIFIC_ROLE" ]; then
        if "$SCRIPT_DIR/scripts/syntax-check.sh" --role "$SPECIFIC_ROLE" > "$syntax_log" 2>&1; then
            echo -e "${GREEN}✓ Syntax checks passed${RESET}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}✗ Syntax checks failed${RESET}"
            echo "  Log: $syntax_log"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        if "$SCRIPT_DIR/scripts/syntax-check.sh" > "$syntax_log" 2>&1; then
            echo -e "${GREEN}✓ Syntax checks passed${RESET}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}✗ Syntax checks failed${RESET}"
            echo "  Log: $syntax_log"
            ((FAILED_TESTS++))
            # Don't return 1 here - continue with other tests
            return 0
        fi
    fi
    
    echo ""
}

# Test specific role
test_role() {
    local role=$1
    
    echo -e "${CYAN}--- Testing Role: $role ---${RESET}"
    ((TOTAL_TESTS++))
    
    local role_log="$TEST_RUN_DIR/role-$role.log"
    
    if [ -n "$SPECIFIC_DISTRO" ]; then
        if "$SCRIPT_DIR/scripts/test-role.sh" "$role" "$SPECIFIC_DISTRO" > "$role_log" 2>&1; then
            echo -e "${GREEN}✓ Role $role passed${RESET}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}✗ Role $role failed${RESET}"
            echo "  Log: $role_log"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        if "$SCRIPT_DIR/scripts/test-role.sh" "$role" ubuntu-24.04 > "$role_log" 2>&1; then
            echo -e "${GREEN}✓ Role $role passed${RESET}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}✗ Role $role failed${RESET}"
            echo "  Log: $role_log"
            ((FAILED_TESTS++))
            return 1
        fi
    fi
}

# Test distribution
test_distribution() {
    local distro=$1
    local playbook=${2:-"site.yml"}
    
    echo -e "${CYAN}--- Testing $distro ---${RESET}"
    ((TOTAL_TESTS++))
    
    local distro_log="$TEST_RUN_DIR/$distro-$playbook.log"
    local container_name="ansible-test-$distro-$$"
    local dockerfile="$SCRIPT_DIR/docker/Dockerfile.$distro"
    local image_name="ansible-test-$distro"
    
    # Check if Dockerfile exists
    if [ ! -f "$dockerfile" ]; then
        echo -e "${RED}✗ Dockerfile not found: $dockerfile${RESET}"
        ((FAILED_TESTS++))
        return 1
    fi
    
    # Build Docker image
    echo "  Building image..."
    if ! docker build -f "$dockerfile" -t "$image_name" "$PROJECT_ROOT" > "$distro_log" 2>&1; then
        echo -e "${RED}✗ Failed to build image${RESET}"
        echo "  Log: $distro_log"
        ((FAILED_TESTS++))
        return 1
    fi
    
    # Run container
    echo "  Starting container..."
    if ! docker run -d --name "$container_name" "$image_name" >> "$distro_log" 2>&1; then
        echo -e "${RED}✗ Failed to start container${RESET}"
        echo "  Log: $distro_log"
        ((FAILED_TESTS++))
        return 1
    fi
    
    # Wait for container
    sleep 3
    
    # Copy ansible directory
    echo "  Copying Ansible files..."
    docker cp "$PROJECT_ROOT/ansible" "$container_name:/tmp/ansible" >> "$distro_log" 2>&1
    
    # Run playbook
    echo "  Running playbook..."
    if docker exec "$container_name" bash -c "cd /tmp/ansible && ansible-playbook $playbook -i 'localhost,' -c local" >> "$distro_log" 2>&1; then
        echo "  Playbook executed successfully"
        
        # Run validation
        echo "  Running validation..."
        if docker exec "$container_name" /tmp/validate-ansible.sh >> "$distro_log" 2>&1; then
            echo -e "${GREEN}✓ $distro passed${RESET}"
            ((PASSED_TESTS++))
            RESULT=0
        else
            echo -e "${RED}✗ $distro validation failed${RESET}"
            echo "  Log: $distro_log"
            ((FAILED_TESTS++))
            RESULT=1
        fi
    else
        echo -e "${RED}✗ $distro playbook failed${RESET}"
        echo "  Log: $distro_log"
        ((FAILED_TESTS++))
        RESULT=1
    fi
    
    # Cleanup
    echo "  Cleaning up..."
    docker stop "$container_name" >> "$distro_log" 2>&1
    docker rm "$container_name" >> "$distro_log" 2>&1
    
    echo ""
    return $RESULT
}

# Run idempotency tests
run_idempotency_tests() {
    if [ "$SKIP_IDEMPOTENCY" = true ] || [ "$QUICK_MODE" = true ]; then
        echo -e "${YELLOW}Skipping idempotency tests${RESET}"
        return 0
    fi
    
    echo -e "${CYAN}--- Running Idempotency Tests ---${RESET}"
    echo -e "${YELLOW}Note: Idempotency tests are currently placeholder${RESET}"
    echo -e "${YELLOW}Full implementation requires running playbook twice in container${RESET}"
    echo ""
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    check_prerequisites
    
    # Handle specific role testing
    if [ -n "$SPECIFIC_ROLE" ]; then
        run_syntax_checks
        test_role "$SPECIFIC_ROLE"
    # Handle specific playbook testing
    elif [ -n "$SPECIFIC_PLAYBOOK" ]; then
        run_syntax_checks
        
        if [ -n "$SPECIFIC_DISTRO" ]; then
            test_distribution "$SPECIFIC_DISTRO" "$SPECIFIC_PLAYBOOK"
        else
            test_distribution "ubuntu-24.04" "$SPECIFIC_PLAYBOOK"
        fi
    # Handle specific distribution testing
    elif [ -n "$SPECIFIC_DISTRO" ]; then
        run_syntax_checks
        test_distribution "$SPECIFIC_DISTRO"
    # Handle quick mode
    elif [ "$QUICK_MODE" = true ]; then
        run_syntax_checks
        test_distribution "ubuntu-24.04"
    # Handle derivatives only
    elif [ "$DERIVATIVES_ONLY" = true ]; then
        run_syntax_checks
        test_distribution "xubuntu-24.04"
        test_distribution "mint-22"
    # Run all tests
    else
        run_syntax_checks
        
        echo -e "${CYAN}--- Running Integration Tests ---${RESET}"
        test_distribution "ubuntu-24.04"
        test_distribution "debian-13"
        test_distribution "xubuntu-24.04"
        test_distribution "mint-22"
        
        run_idempotency_tests
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Generate summary
    echo "============================================"
    echo "  Test Summary"
    echo "============================================"
    echo -e "Total Tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
    echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
    echo -e "Duration:     ${duration}s"
    echo -e "Results:      $TEST_RUN_DIR"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${RESET}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${RESET}"
        exit 1
    fi
}

main
