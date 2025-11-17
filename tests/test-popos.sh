#!/bin/bash

# ============================================================================
# Test Pop!_OS Specifically
# ============================================================================
# Tests Pop!_OS with all workarounds (EZA, Docker, VSCode)
# Must be run from project root directory
# ============================================================================

set -e

# Check if running from project root
if [ ! -f "scripts/prepare.sh" ]; then
    echo "Error: Must run from project root directory"
    echo "Usage: ./tests/test-popos.sh"
    exit 1
fi

echo "============================================"
echo "  Testing Pop!_OS 22.04"
echo "============================================"
echo ""
echo "This test validates:"
echo "  - Pop!_OS detection"
echo "  - EZA installation workaround"
echo "  - Docker installation workaround"
echo "  - VSCode installation workaround"
echo "  - All other components"
echo ""

# Build and test
echo "--- Building Pop!_OS test container ---"
docker build -f tests/docker/Dockerfile.popos-22.04 -t linux-prepare-test-popos-22.04 .

echo ""
echo "--- Running validation ---"
docker run --rm linux-prepare-test-popos-22.04 /tmp/validate.sh

echo ""
echo "============================================"
echo "  Pop!_OS Test Completed Successfully!"
echo "============================================"
echo ""
echo "Validated:"
echo "  ✓ Pop!_OS detection working"
echo "  ✓ EZA/exa installed correctly"
echo "  ✓ Docker installed correctly"
echo "  ✓ All base components working"
echo ""
