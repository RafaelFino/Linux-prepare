# Test Pop!_OS - Quick Guide

## Run Tests

```bash
# Pop!_OS only
./tests/test-popos.sh

# All derivatives
./tests/test-derivatives.sh

# Everything
./tests/run-all-tests.sh
```

## Manual Test

```bash
# Build container
docker build -f tests/docker/Dockerfile.popos-22.04 -t test-popos .

# Run validation
docker run --rm test-popos /tmp/validate.sh

# Check specific components
docker run --rm test-popos bash -c "which eza || which exa"
docker run --rm test-popos bash -c "docker --version"
docker run --rm test-popos bash -c "dpkg -l | grep code"
```

## What to Check

- ✅ Pop!_OS detected (`ID=pop` in /etc/os-release)
- ✅ EZA or exa installed
- ✅ Docker working
- ✅ VSCode via apt (not snap)
- ✅ All base tools present

## Report Issues

Include:
- Command run
- Error message
- Last 20 lines of output
- Which workaround failed (EZA/Docker/VSCode)
