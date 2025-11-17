# Desktop Detection & Pop!_OS Support

## What Changed

### Documentation
- Quick Start at top of README
- Desktop Components section (auto-detect + manual flags)
- Usage scenarios simplified
- Pop!_OS added to supported distributions

### Script Features
- `--desktop` flag to force install
- `--skip-desktop` flag to skip install
- Pop!_OS auto-detection
- Workarounds for EZA, Docker, VSCode on Pop!_OS
- Auto-install snap and cargo when needed

### Tests
- Pop!_OS Dockerfile added
- test-derivatives.sh includes Pop!_OS
- test-popos.sh for specific testing

## Quick Usage

```bash
# Auto-detect (default)
sudo ./scripts/prepare.sh

# Force desktop
sudo ./scripts/prepare.sh --desktop

# Skip desktop
sudo ./scripts/prepare.sh --skip-desktop
```

## Pop!_OS Workarounds

**EZA**: Installs cargo → cargo install to /usr/local/bin (global) → fallback exa  
**Docker**: Uses Pop!_OS repositories  
**VSCode**: Uses apt instead of snap  
**Snap**: Auto-installs snapd when needed for other distros

**Note**: Cargo binaries installed to `/usr/local/bin` for system-wide access

## Testing

```bash
./tests/test-popos.sh              # Pop!_OS only (~15min)
./tests/test-derivatives.sh        # All derivatives (~45min)
./tests/run-all-tests.sh           # Everything (~100min)
```

## Files Modified

**Docs**: README.md, CHANGELOG.md, tests/DISTRIBUTIONS.md  
**Script**: scripts/prepare.sh  
**Tests**: Dockerfiles, test scripts, test-config.yml
