#!/bin/bash

# ============================================================================
# Run All Tests Script
# ============================================================================
# Builds and tests Docker images for multiple distributions
# Must be run from project root directory
# ============================================================================

set -e

# Check if running from project root
if [ ! -f "scripts/prepare.sh" ]; then
    echo "Error: Must run from project root directory"
    echo "Usage: ./tests/run-all-tests.sh"
    exit 1
fi

echo "============================================"
echo "  Running All Tests"
echo "============================================"
echo ""

# Test Ubuntu 24.04
echo "--- Testing Ubuntu 24.04 ---"
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t linux-prepare-test-ubuntu-24.04 .
docker run --rm linux-prepare-test-ubuntu-24.04 /tmp/validate.sh
echo ""

# Test Debian 13
echo "--- Testing Debian 13 ---"
docker build -f tests/docker/Dockerfile.debian-13 -t linux-prepare-test-debian-13 .
docker run --rm linux-prepare-test-debian-13 /tmp/validate.sh
echo ""

# Test Idempotence (run script twice)
echo "--- Testing Idempotence ---"
echo "Building image with script run twice..."
docker build -f - -t linux-prepare-test-idempotence . << 'EOF'
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y sudo curl wget git ca-certificates gnupg && \
    apt-get clean

RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY ./scripts/prepare.sh /tmp/prepare.sh
RUN chmod +x /tmp/prepare.sh

# Run script first time (desktop is NOT installed by default)
RUN /tmp/prepare.sh -u=testuser

# Run script second time (should be idempotent)
RUN /tmp/prepare.sh -u=testuser

COPY ./tests/scripts/validate.sh /tmp/validate.sh
RUN chmod +x /tmp/validate.sh

WORKDIR /home/testuser
CMD ["/bin/bash"]
EOF

docker run --rm linux-prepare-test-idempotence /tmp/validate.sh
echo ""

echo "============================================"
echo "  All Tests Completed Successfully!"
echo "============================================"
