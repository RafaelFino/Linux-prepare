#!/bin/bash

# ============================================================================
# Test Derivative Distributions Script
# ============================================================================
# Tests Xubuntu and Linux Mint specifically
# Must be run from project root directory
# ============================================================================

set -e

# Check if running from project root
if [ ! -f "scripts/prepare.sh" ]; then
    echo "Error: Must run from project root directory"
    echo "Usage: ./tests/test-derivatives.sh"
    exit 1
fi

echo "============================================"
echo "  Testing Derivative Distributions"
echo "============================================"
echo ""

# Test Xubuntu 24.04
echo "--- Testing Xubuntu 24.04 ---"
echo "This tests XFCE desktop detection..."
docker build -f tests/docker/Dockerfile.xubuntu-24.04 -t linux-prepare-test-xubuntu-24.04 .
docker run --rm linux-prepare-test-xubuntu-24.04 /tmp/validate.sh
echo ""

# Test Linux Mint 22
echo "--- Testing Linux Mint 22 ---"
echo "This tests Linux Mint compatibility..."
docker build -f tests/docker/Dockerfile.mint-22 -t linux-prepare-test-mint-22 .
docker run --rm linux-prepare-test-mint-22 /tmp/validate.sh
echo ""

echo "============================================"
echo "  Derivative Tests Completed Successfully!"
echo "============================================"
