#!/bin/bash

# ============================================================================
# Test Derivative Distributions Script
# ============================================================================
# Tests Xubuntu, Linux Mint, and Pop!_OS specifically
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

# Test Pop!_OS 22.04
echo "--- Testing Pop!_OS 22.04 ---"
echo "This tests Pop!_OS compatibility with EZA, Docker, and VSCode workarounds..."
docker build -f tests/docker/Dockerfile.popos-22.04 -t linux-prepare-test-popos-22.04 .
docker run --rm linux-prepare-test-popos-22.04 /tmp/validate.sh
echo ""

echo "============================================"
echo "  Derivative Tests Completed Successfully!"
echo "============================================"
