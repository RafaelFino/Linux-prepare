#!/bin/bash

# ============================================================================
# Run All Tests Script
# ============================================================================
# Builds and tests Docker images for multiple distributions
# ============================================================================

set -e

echo "============================================"
echo "  Running All Tests"
echo "============================================"
echo ""

# Test Ubuntu 22.04
echo "--- Testing Ubuntu 22.04 ---"
docker build -f tests/docker/Dockerfile.ubuntu-22.04 -t linux-prepare-test-ubuntu-22.04 .
docker run --rm linux-prepare-test-ubuntu-22.04 /tmp/validate.sh
echo ""

# Test Debian 12
echo "--- Testing Debian 12 ---"
docker build -f tests/docker/Dockerfile.debian-12 -t linux-prepare-test-debian-12 .
docker run --rm linux-prepare-test-debian-12 /tmp/validate.sh
echo ""

# Test Idempotence (run script twice)
echo "--- Testing Idempotence ---"
echo "Building image with script run twice..."
docker build -f - -t linux-prepare-test-idempotence . << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y sudo curl wget git && \
    apt-get clean

RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY scripts/prepare.sh /tmp/prepare.sh
RUN chmod +x /tmp/prepare.sh

# Run script first time
RUN /tmp/prepare.sh -u=testuser --skip-desktop

# Run script second time (should be idempotent)
RUN /tmp/prepare.sh -u=testuser --skip-desktop

COPY tests/scripts/validate.sh /tmp/validate.sh
RUN chmod +x /tmp/validate.sh

WORKDIR /home/testuser
CMD ["/bin/bash"]
EOF

docker run --rm linux-prepare-test-idempotence /tmp/validate.sh
echo ""

echo "============================================"
echo "  All Tests Completed Successfully!"
echo "============================================"
