#!/usr/bin/env bash
# =============================================================================
# run-in-docker.sh — Build and run the Ubuntu Dev Setup Script inside Docker
# =============================================================================
# Usage: ./run-in-docker.sh [OPTIONS]
# All OPTIONS are forwarded to setup.sh inside the container.
# =============================================================================

set -euo pipefail

IMAGE_NAME="ubuntu-dev-setup"
LOG_DIR="$(pwd)/logs"

show_usage() {
    cat <<'EOF'
Usage: ./run-in-docker.sh [OPTIONS]

Builds the Docker image and runs setup.sh inside a container.
All options are forwarded to setup.sh.

Options:
  --base          Install BASE group (default)
  --desktop       Install DESKTOP group
  --docker        Install DOCKER group
  --golang        Install GOLANG group
  --java          Install JAVA group
  --dotnet        Install DOTNET group
  --full          Install ALL groups
  --users USER... Create additional users
  --help, -h      Show this help message

Examples:
  ./run-in-docker.sh --base
  ./run-in-docker.sh --full
  ./run-in-docker.sh --base --docker
  ./run-in-docker.sh --users alice bob
EOF
}

if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

# Create logs directory on host
mkdir -p "${LOG_DIR}"

echo "[INFO] Building Docker image: ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" .

echo "[INFO] Running setup.sh inside container with args: $*"
docker run --rm \
    --privileged \
    -v /proc/meminfo:/proc/meminfo:ro \
    -v "${LOG_DIR}":/var/log \
    "${IMAGE_NAME}" "$@"
