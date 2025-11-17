#!/bin/bash

# ============================================================================
# Ansible Idempotency Check Script
# ============================================================================
# This script verifies that Ansible playbooks are idempotent by running them
# twice and checking that no tasks report "changed" status on the second run.
# ============================================================================

set -e

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Parse command-line arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <playbook> <distribution> [--exclude task1,task2,...]"
    echo ""
    echo "Examples:"
    echo "  $0 site.yml ubuntu-24.04"
    echo "  $0 site.yml ubuntu-24.04 --exclude 'Download*,Fetch*'"
    exit 1
fi

PLAYBOOK="$1"
DISTRIBUTION="$2"
EXCLUDE_TASKS=""

shift 2

while [[ $# -gt 0 ]]; do
    case $1 in
        --exclude)
            EXCLUDE_TASKS="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            exit 1
            ;;
    esac
done

# Temporary files for output
FIRST_RUN_OUTPUT=$(mktemp)
SECOND_RUN_OUTPUT=$(mktemp)
CHANGED_TASKS=$(mktemp)

# Cleanup on exit
cleanup() {
    rm -f "$FIRST_RUN_OUTPUT" "$SECOND_RUN_OUTPUT" "$CHANGED_TASKS"
}
trap cleanup EXIT

echo "============================================"
echo "  Ansible Idempotency Check"
echo "============================================"
echo "Playbook: $PLAYBOOK"
echo "Distribution: $DISTRIBUTION"
if [ -n "$EXCLUDE_TASKS" ]; then
    echo "Excluded tasks: $EXCLUDE_TASKS"
fi
echo ""

# Check if playbook exists
cd "$PROJECT_ROOT/ansible"
if [ ! -f "$PLAYBOOK" ]; then
    echo -e "${RED}✗ Playbook not found: $PLAYBOOK${RESET}"
    exit 1
fi

# Function to run playbook
run_playbook() {
    local run_number=$1
    local output_file=$2
    
    echo "--- Run $run_number ---"
    
    # Run ansible-playbook and capture output
    # Note: This assumes the container is already running and configured
    # In actual test runner, this would use proper inventory and connection settings
    if ansible-playbook "$PLAYBOOK" -i "localhost," -c local > "$output_file" 2>&1; then
        echo -e "${GREEN}✓${RESET} Playbook execution completed"
        return 0
    else
        echo -e "${RED}✗${RESET} Playbook execution failed"
        cat "$output_file"
        return 1
    fi
}

# Function to parse changed tasks from output
parse_changed_tasks() {
    local output_file=$1
    local changed_file=$2
    
    # Extract lines that show "changed" status
    # Ansible output format: "changed: [host] => (item=...)" or "changed: [host]"
    grep "^changed:" "$output_file" | sed 's/^changed: //' > "$changed_file" || true
    
    # Also check the recap section for changed count
    local changed_count=$(grep -A 10 "PLAY RECAP" "$output_file" | grep "changed=" | sed 's/.*changed=\([0-9]*\).*/\1/' || echo "0")
    
    echo "$changed_count"
}

# Function to check if task should be excluded
should_exclude_task() {
    local task_name=$1
    
    if [ -z "$EXCLUDE_TASKS" ]; then
        return 1  # Don't exclude
    fi
    
    # Split exclude patterns by comma
    IFS=',' read -ra PATTERNS <<< "$EXCLUDE_TASKS"
    for pattern in "${PATTERNS[@]}"; do
        # Remove leading/trailing whitespace
        pattern=$(echo "$pattern" | xargs)
        
        # Check if task matches pattern (supports wildcards)
        if [[ "$task_name" == $pattern ]]; then
            return 0  # Exclude this task
        fi
    done
    
    return 1  # Don't exclude
}

# First run
echo "Running playbook (first time)..."
if ! run_playbook 1 "$FIRST_RUN_OUTPUT"; then
    echo -e "${RED}First run failed. Cannot proceed with idempotency check.${RESET}"
    exit 1
fi

FIRST_CHANGED=$(parse_changed_tasks "$FIRST_RUN_OUTPUT" /dev/null)
echo "First run: $FIRST_CHANGED tasks changed"
echo ""

# Wait a moment between runs
sleep 2

# Second run
echo "Running playbook (second time)..."
if ! run_playbook 2 "$SECOND_RUN_OUTPUT"; then
    echo -e "${RED}Second run failed. Cannot proceed with idempotency check.${RESET}"
    exit 1
fi

SECOND_CHANGED=$(parse_changed_tasks "$SECOND_RUN_OUTPUT" "$CHANGED_TASKS")
echo "Second run: $SECOND_CHANGED tasks changed"
echo ""

# Analyze results
echo "============================================"
echo "  Idempotency Analysis"
echo "============================================"

if [ "$SECOND_CHANGED" -eq 0 ]; then
    echo -e "${GREEN}✓ Playbook is idempotent!${RESET}"
    echo "No tasks reported 'changed' status on second run."
    exit 0
else
    echo -e "${RED}✗ Playbook is NOT idempotent!${RESET}"
    echo "$SECOND_CHANGED tasks reported 'changed' status on second run."
    echo ""
    
    # Show which tasks changed
    if [ -s "$CHANGED_TASKS" ]; then
        echo "Tasks that changed on second run:"
        
        NON_EXCLUDED_CHANGES=0
        while IFS= read -r task; do
            # Try to extract task name from the line
            task_name=$(echo "$task" | sed 's/\[.*\]//' | xargs)
            
            if should_exclude_task "$task_name"; then
                echo -e "${YELLOW}  ⚠ $task (excluded)${RESET}"
            else
                echo -e "${RED}  ✗ $task${RESET}"
                ((NON_EXCLUDED_CHANGES++))
            fi
        done < "$CHANGED_TASKS"
        
        echo ""
        
        if [ $NON_EXCLUDED_CHANGES -eq 0 ]; then
            echo -e "${GREEN}All changed tasks are in the exclusion list.${RESET}"
            echo -e "${GREEN}Playbook is considered idempotent.${RESET}"
            exit 0
        else
            echo -e "${RED}$NON_EXCLUDED_CHANGES non-excluded tasks changed.${RESET}"
            echo ""
            echo "Suggestions:"
            echo "  1. Review the tasks that changed"
            echo "  2. Ensure tasks check current state before making changes"
            echo "  3. Use 'creates', 'removes', or 'when' conditions appropriately"
            echo "  4. If tasks are expected to change, add them to exclusion list"
            exit 1
        fi
    else
        echo "Could not parse changed tasks from output."
        echo "Check the playbook output manually:"
        echo "  First run: $FIRST_RUN_OUTPUT"
        echo "  Second run: $SECOND_RUN_OUTPUT"
        exit 1
    fi
fi
