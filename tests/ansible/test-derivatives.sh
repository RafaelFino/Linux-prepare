#!/bin/bash

# ============================================================================
# Ansible Derivatives Test Script
# ============================================================================
# This script tests Xubuntu and Linux Mint specifically to validate
# compatibility with derivative distributions.
# ============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

echo "============================================"
echo "  Ansible Derivatives Test"
echo "============================================"
echo "Testing: Xubuntu 24.04 and Linux Mint 22"
echo ""

# Run derivatives test
"$SCRIPT_DIR/run-ansible-tests.sh" --derivatives

echo ""
echo -e "${GREEN}Derivatives test completed!${RESET}"
