# Implementation Plan: Ansible Testing Framework

- [x] 1. Create test infrastructure and configuration
  - Create directory structure for Ansible tests at `tests/ansible/`
  - Create test configuration file with distribution and validation definitions
  - _Requirements: 4.1, 4.2, 8.1_

- [x] 1.1 Set up test directory structure
  - Create `tests/ansible/` directory with subdirectories: `config/`, `docker/`, `scripts/`, `fixtures/`, `results/`
  - Create placeholder files to establish structure
  - _Requirements: 4.1, 4.2_

- [x] 1.2 Create test configuration file
  - Write `tests/ansible/config/test-config.yml` with distribution definitions, playbook mappings, role definitions, and validation criteria
  - Include all four distributions: Ubuntu 24.04, Debian 13, Xubuntu 24.04, Linux Mint 22
  - Define validation categories matching script test validation
  - _Requirements: 4.1, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10_

- [x] 2. Create Docker test environments
  - Create Dockerfiles for each distribution that prepare containers for Ansible execution
  - Ensure containers have Python 3, SSH, and sudo configured
  - _Requirements: 4.2, 4.5, 9.1, 9.2, 9.3_

- [x] 2.1 Create Ubuntu 24.04 Dockerfile
  - Write `tests/ansible/docker/Dockerfile.ubuntu-24.04` based on ubuntu:24.04 image
  - Install Python 3, openssh-server, sudo, and basic dependencies
  - Configure SSH and sudo for Ansible execution
  - _Requirements: 4.1, 4.2_

- [x] 2.2 Create Debian 13 Dockerfile
  - Write `tests/ansible/docker/Dockerfile.debian-13` based on debian:13 image
  - Install Python 3, openssh-server, sudo, and basic dependencies
  - Configure for server environment (no desktop)
  - _Requirements: 4.1, 4.2_

- [x] 2.3 Create Xubuntu 24.04 Dockerfile
  - Write `tests/ansible/docker/Dockerfile.xubuntu-24.04` based on ubuntu:24.04 image
  - Install xfce4-session to simulate XFCE environment
  - Set XDG_CURRENT_DESKTOP=XFCE for desktop detection
  - _Requirements: 4.1, 4.2, 9.1, 9.4_

- [x] 2.4 Create Linux Mint 22 Dockerfile
  - Write `tests/ansible/docker/Dockerfile.mint-22` based on linuxmintd/mint22-amd64 image
  - Configure for Cinnamon desktop environment detection
  - Install necessary dependencies for Ansible execution
  - _Requirements: 4.1, 4.2, 9.2, 9.4_

- [x] 3. Implement syntax validation
  - Create syntax checker script that validates YAML, Ansible syntax, and ansible-lint rules
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 3.1 Create syntax check script
  - Write `tests/ansible/scripts/syntax-check.sh` that validates all playbooks and roles
  - Implement YAML syntax validation using yamllint or Python yaml module
  - Implement Ansible syntax check using `ansible-playbook --syntax-check`
  - Implement ansible-lint validation
  - Support filtering by specific playbook or role via command-line arguments
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 4. Implement component validation script
  - Create validation script that checks all installed components match requirements
  - Mirror the validation logic from `tests/scripts/validate.sh`
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 9.4, 9.5_

- [x] 4.1 Create component validator script
  - Write `tests/ansible/scripts/validate-ansible.sh` with validation functions
  - Implement validation for base commands (git, zsh, vim, curl, wget, htop, btop, jq, fzf, eza, micro)
  - Implement validation for modern CLI tools (bat/batcat, httpie, yq, glances, gh, tig, screen, k9s)
  - Implement validation for build tools (cmake, gcc, make)
  - Implement validation for database clients (psql, redis-cli)
  - Implement validation for security & network tools (openssl, ssh, nc)
  - Implement validation for programming languages (docker, go, python3, pip3, dotnet)
  - Implement validation for shell configuration (Oh-My-Zsh, Oh-My-Bash, rc files, Vim runtime)
  - Implement validation for aliases (ls, lt in .zshrc and .bashrc)
  - Implement validation for environment variables (EDITOR, VISUAL)
  - Implement validation for desktop components when applicable
  - Use color-coded output (green for pass, red for fail, gray for optional)
  - _Requirements: 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 9.5_

- [x] 5. Implement idempotency checker
  - Create script that runs playbooks twice and verifies no changes on second run
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5.1 Create idempotency check script
  - Write `tests/ansible/scripts/idempotency-check.sh` that executes playbook twice
  - Parse Ansible output to detect "changed" status on second run
  - Support configurable exclusion list for tasks that are expected to change
  - Report non-idempotent tasks with task names and details
  - Exit with status code 1 if idempotency violations detected
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 6. Implement role testing capability
  - Create script to test individual roles in isolation
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6.1 Create role test script
  - Write `tests/ansible/scripts/test-role.sh` that tests a single role
  - Create isolated test container for role testing
  - Generate minimal playbook that applies only the specified role
  - Execute role in test container
  - Run validation checks specific to the role
  - Clean up test container after execution
  - Support testing role on specific distribution or all distributions
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 7. Implement main test runner
  - Create orchestration script that runs all test types across distributions
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 7.1 Create main test runner script
  - Write `tests/ansible/run-ansible-tests.sh` as main orchestration script
  - Implement command-line argument parsing for test selection options
  - Implement prerequisite checks (Docker installed, Ansible installed)
  - Implement container provisioning for each distribution
  - Implement playbook execution in containers using ansible-playbook with connection=docker
  - Implement validation script execution in containers
  - Implement resource cleanup after tests
  - Implement test result collection and aggregation
  - Support running all tests, specific distribution, specific playbook, or specific role
  - Validate specified playbooks/roles exist before testing
  - Continue execution even if individual tests fail
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 7.2 Implement test execution flow
  - Implement sequential execution: syntax checks → role tests → integration tests → idempotency tests
  - Implement parallel execution for distribution tests (up to 4 concurrent)
  - Implement error handling for each test phase
  - Stop execution if syntax checks fail
  - Continue with remaining tests if individual tests fail
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 8. Implement test report generation
  - Create script that generates comprehensive test reports
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 8.1 Create report generator script
  - Write `tests/ansible/scripts/generate-report.sh` that aggregates test results
  - Parse test result files from results directory
  - Generate formatted summary with distribution results, syntax checks, idempotency results, and component validation
  - Use color coding for passed/failed/skipped tests
  - Display execution time for each test phase
  - Display detailed failure information with file paths and error messages
  - Calculate and display summary statistics (total, passed, failed, skipped)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 9. Create convenience test scripts
  - Create quick test and derivatives test scripts for common workflows
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 9.1 Create quick test script
  - Write `tests/ansible/quick-test.sh` that runs tests on Ubuntu 24.04 only
  - Execute syntax checks, integration test, and validation
  - Skip idempotency test for speed
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 9.2 Create derivatives test script
  - Write `tests/ansible/test-derivatives.sh` that tests Xubuntu and Linux Mint only
  - Execute full test suite on derivative distributions
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 10. Create test fixtures and inventory
  - Create test inventory files and variable files for test execution
  - _Requirements: 4.2, 4.3_

- [x] 10.1 Create test inventory file
  - Write `tests/ansible/fixtures/inventory/test-hosts` with container definitions
  - Define inventory groups for each distribution
  - Configure connection parameters for Docker containers
  - _Requirements: 4.2, 4.3_

- [x] 10.2 Create test variables file
  - Write `tests/ansible/fixtures/vars/test-vars.yml` with test-specific variables
  - Enable all installation flags for comprehensive testing
  - Configure test user settings
  - _Requirements: 4.2, 4.3_

- [x] 11. Update documentation
  - Update all relevant documentation files to include Ansible testing information
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [x] 11.1 Create Ansible test documentation
  - Write `tests/ansible/README.md` with comprehensive testing guide
  - Document test execution commands and options
  - Document test validation criteria
  - Document troubleshooting steps
  - Provide examples of running different test types
  - Document test development guidelines
  - _Requirements: 10.2, 10.3, 10.4, 10.5_

- [x] 11.2 Update ansible/README.md
  - Add "Testing" section to `ansible/README.md`
  - Document how to run Ansible tests
  - Explain test validation criteria
  - Provide examples of test execution
  - Link to detailed test documentation at `tests/ansible/README.md`
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 11.3 Update tests/README.md
  - Add reference to Ansible tests in `tests/README.md`
  - Update test matrix to include Ansible tests
  - Update execution time estimates
  - Add links to Ansible test documentation
  - _Requirements: 10.6_

- [x] 11.4 Update CONTRIBUTING.md
  - Add Ansible testing requirements to `CONTRIBUTING.md`
  - Document that contributors should run Ansible tests before commits
  - Explain how to add new Ansible tests
  - _Requirements: 10.6_

- [x] 11.5 Update project README.md
  - Add mention of Ansible testing capabilities to main `README.md`
  - Link to Ansible test documentation
  - Update testing section to include both script and Ansible tests
  - _Requirements: 10.6_

- [x] 12. Add integration tests for test framework
  - Create tests that validate the test framework itself works correctly
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 12.1 Create test framework validation
  - Write script that validates test scripts execute correctly
  - Test that syntax checker detects invalid YAML
  - Test that validation script correctly identifies missing components
  - Test that idempotency checker detects non-idempotent tasks
  - Test that report generator produces correct output format
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
