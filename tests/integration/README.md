# Integration Tests for Modular Architecture

This directory contains integration tests that validate module interactions, execution order, dependencies, and backward compatibility.

## Structure

- `framework/` - Integration test framework utilities
- `scenarios/` - Test scenarios for different use cases
- `run-integration-tests.sh` - Main integration test runner

## Test Scenarios

### Module Interaction Tests
- Module dependency resolution
- Data flow between modules
- Module execution order validation
- Error propagation and handling

### Backward Compatibility Tests
- Monolithic vs modular behavior comparison
- Command-line flag compatibility
- Output format consistency
- Installation result validation

### Performance Tests
- Execution time comparison
- Memory usage analysis
- Module loading overhead
- Parallel execution capabilities

## Running Tests

```bash
# Run all integration tests
./tests/integration/run-integration-tests.sh

# Run specific scenario
./tests/integration/run-integration-tests.sh module-dependencies

# Run with performance benchmarking
./tests/integration/run-integration-tests.sh --benchmark
```

## Test Environment

Integration tests use Docker containers to provide isolated, reproducible environments for testing different scenarios and distributions.