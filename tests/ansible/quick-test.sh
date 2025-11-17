#!/bin/bash

# ============================================================================
# Ansible Quick Test Script
# ============================================================================
# This script runs a quick test on Ubuntu 24.04 only, skipping idempotency
# tests for faster feedback during development.
# ============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

echo "============================================"
echo "  Ansible Quick Test"
echo "============================================"
echo "Testing: Ubuntu 24.04 only"
echo "Skipping: Idempotency tests"
echo ""

# Run quick test
"$SCRIPT_DIR/run-ansible-tests.sh" --quick

echo ""
echo -e "${GREEN}Quick test completed!${RESET}"
