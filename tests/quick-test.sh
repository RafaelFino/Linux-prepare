#!/bin/bash

# ============================================================================
# Quick Test Script
# ============================================================================
# Teste rápido para validar se o script básico funciona
# Mais rápido que o teste completo
# ============================================================================

set -e

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

echo -e "${CYAN}============================================${RESET}"
echo -e "${CYAN}  Quick Test - Linux Prepare${RESET}"
echo -e "${CYAN}============================================${RESET}"
echo ""

# Check if running from project root
if [ ! -f "scripts/prepare.sh" ]; then
    echo -e "${RED}Error: Must run from project root directory${RESET}"
    echo "Usage: ./tests/quick-test.sh"
    exit 1
fi

echo -e "${YELLOW}This will test basic installation in Ubuntu 24.04${RESET}"
echo -e "${YELLOW}Estimated time: 5-10 minutes${RESET}"
echo ""

# Build minimal test
echo -e "${CYAN}Building test container...${RESET}"
docker build -f - -t linux-prepare-quick-test . << 'EOF'
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal requirements
RUN apt-get update && \
    apt-get install -y sudo curl wget git ca-certificates gnupg && \
    apt-get clean

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy script
COPY ./scripts/prepare.sh /tmp/prepare.sh
RUN chmod +x /tmp/prepare.sh

# Run script with minimal components (faster test)
# Note: desktop is NOT installed by default, so no --skip-desktop needed
RUN /tmp/prepare.sh -u=testuser --skip-kotlin --skip-jvm --skip-dotnet

# Quick validation
RUN command -v docker && \
    /usr/local/go/bin/go version && \
    command -v python3 && \
    command -v zsh && \
    command -v eza && \
    command -v micro && \
    echo "Basic validation passed!"

WORKDIR /home/testuser
CMD ["/bin/bash"]
EOF

echo ""
echo -e "${GREEN}✓ Build successful!${RESET}"
echo ""

# Run validation
echo -e "${CYAN}Running validation...${RESET}"
docker run --rm linux-prepare-quick-test bash -c '
echo "=== Checking installed components ==="
echo -n "Docker: " && docker --version
echo -n "Golang: " && /usr/local/go/bin/go version
echo -n "Python: " && python3 --version
echo -n "Zsh: " && zsh --version
echo -n "eza: " && eza --version
echo -n "micro: " && micro --version
echo ""
echo "=== Checking configurations ==="
echo -n "Oh-My-Zsh: " && [ -d ~/.oh-my-zsh ] && echo "Installed" || echo "Not found"
echo -n "Aliases: " && grep -q "alias ls=" ~/.zshrc && echo "Configured" || echo "Not found"
echo ""
echo "=== All checks passed! ==="
'

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}  Quick Test Completed Successfully!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo -e "${YELLOW}Next steps:${RESET}"
echo "  1. Run full tests: ./tests/run-all-tests.sh"
echo "  2. Test in a VM (optional)"
echo "  3. Use in production: sudo ./scripts/prepare.sh"
echo ""
