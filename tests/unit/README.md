# Unit Tests for Modular Architecture

This directory contains unit tests for individual modules in the Linux-prepare project.

## Structure

- `framework/` - Test framework utilities
- `modules/` - Tests for individual modules
- `lib/` - Tests for shared libraries
- `run-unit-tests.sh` - Main test runner

## Running Tests

```bash
# Run all unit tests
./tests/unit/run-unit-tests.sh

# Run tests for specific module
./tests/unit/run-unit-tests.sh system-detection

# Run tests with verbose output
./tests/unit/run-unit-tests.sh --verbose
```

## Test Framework

The test framework provides:
- Module isolation and mocking
- Assertion functions
- Test result reporting
- Error handling and cleanup

## Writing Tests

Each module test should:
1. Test core functionality
2. Test error handling
3. Validate module independence
4. Test rollback capabilities (where applicable)