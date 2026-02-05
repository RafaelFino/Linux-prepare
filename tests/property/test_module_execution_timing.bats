#!/usr/bin/env bats

# Property-based tests for module execution timing and logging functionality
# Feature: env-prepare, Property 9: Module Execution Timing
# **Validates: Requirements 5.4, 5.5, 5.6**

setup() {
    # Source the logging utility to access timing functions
    source util/log.sh
    
    # Create a temporary directory for testing
    TEST_DIR="/tmp/test_timing_$RANDOM"
    mkdir -p "$TEST_DIR"
    
    # Define test modules
    TEST_MODULES=("base" "docker" "golang" "jvm" "vscode" "fonts" "terminator" "dotnet")
}

teardown() {
    # Clean up test directory
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    
    # Clear timer storage
    unset MODULE_START_TIMES
}

# Generate random module name from available modules
get_random_module() {
    local modules=("base" "docker" "golang" "jvm" "vscode" "fonts" "terminator" "dotnet")
    local idx=$((RANDOM % ${#modules[@]}))
    echo "${modules[$idx]}"
}

# Simulate module execution with random delay
simulate_module_execution() {
    local module="$1"
    local delay=$((RANDOM % 5 + 1))  # Random delay 1-5 seconds
    
    start_timer "$module"
    sleep "$delay"
    end_timer "$module"
}

@test "Property 9: Module Execution Timing - Timer functions should exist and be callable" {
    # Property: The start_timer and end_timer functions should be defined and callable
    
    for iteration in {1..10}; do
        local module
        module=$(get_random_module)
        
        # Property: start_timer should be callable without error
        run start_timer "$module"
        [ "$status" -eq 0 ]
        
        # Property: end_timer should be callable without error
        run end_timer "$module"
        [ "$status" -eq 0 ]
    done
}

@test "Property 9: Module Execution Timing - Timer should record start time" {
    # Property: When start_timer is called, it should store the current time
    
    for iteration in {1..10}; do
        local module
        module=$(get_random_module)
        
        # Get current time before starting timer
        local before_time
        before_time=$(date +%s)
        
        # Start timer
        start_timer "$module"
        
        # Get current time after starting timer
        local after_time
        after_time=$(date +%s)
        
        # Property: MODULE_START_TIMES should contain an entry for this module
        [[ -n "${MODULE_START_TIMES[$module]:-}" ]]
        
        # Property: Stored time should be between before and after times
        local stored_time="${MODULE_START_TIMES[$module]}"
        [ "$stored_time" -ge "$before_time" ]
        [ "$stored_time" -le "$after_time" ]
    done
}

@test "Property 9: Module Execution Timing - Timer should calculate elapsed time correctly" {
    # Property: The elapsed time should be approximately equal to the actual delay
    
    for iteration in {1..5}; do
        local module
        module=$(get_random_module)
        
        local delay=$((RANDOM % 3 + 1))  # 1-3 seconds
        
        # Start timer
        start_timer "$module" > /dev/null 2>&1
        
        # Sleep for known duration
        sleep "$delay"
        
        # Get elapsed time
        local elapsed
        elapsed=$(get_elapsed_time "$module")
        
        # Property: Elapsed time should be approximately equal to delay (within 1 second tolerance)
        [ "$elapsed" -ge "$((delay - 1))" ]
        [ "$elapsed" -le "$((delay + 1))" ]
        
        # Clean up
        end_timer "$module" > /dev/null 2>&1
    done
}

@test "Property 9: Module Execution Timing - End timer should clear timer entry" {
    # Property: After end_timer is called, the timer entry should be removed
    
    for iteration in {1..10}; do
        local module
        module=$(get_random_module)
        
        # Start timer
        start_timer "$module" > /dev/null 2>&1
        
        # Property: Timer should be stored
        [[ -n "${MODULE_START_TIMES[$module]:-}" ]]
        
        # End timer
        end_timer "$module" > /dev/null 2>&1
        
        # Property: Timer entry should be cleared
        [[ -z "${MODULE_START_TIMES[$module]:-}" ]]
    done
}

@test "Property 9: Module Execution Timing - Multiple timers should be independent" {
    # Property: Starting multiple timers should not interfere with each other
    
    for iteration in {1..5}; do
        # Start multiple timers
        local module1
        module1=$(get_random_module)
        local module2
        module2=$(get_random_module)
        
        # Ensure different modules
        while [[ "$module1" == "$module2" ]]; do
            module2=$(get_random_module)
        done
        
        # Start both timers
        start_timer "$module1" > /dev/null 2>&1
        sleep 2
        start_timer "$module2" > /dev/null 2>&1
        
        # Property: Both timers should be stored
        [[ -n "${MODULE_START_TIMES[$module1]:-}" ]]
        [[ -n "${MODULE_START_TIMES[$module2]:-}" ]]
        
        # Property: Module1 timer should be earlier than or equal to module2 timer
        [ "${MODULE_START_TIMES[$module1]}" -le "${MODULE_START_TIMES[$module2]}" ]
        
        # End both timers
        end_timer "$module1" > /dev/null 2>&1
        end_timer "$module2" > /dev/null 2>&1
        
        # Property: Both timers should be cleared
        [[ -z "${MODULE_START_TIMES[$module1]:-}" ]]
        [[ -z "${MODULE_START_TIMES[$module2]:-}" ]]
    done
}

@test "Property 9: Module Execution Timing - Start timer should log 'Installing...' message" {
    # Property: When start_timer is called, it should log "Installing..." message
    
    for iteration in {1..10}; do
        local module
        module=$(get_random_module)
        
        # Capture output from start_timer
        local output
        output=$(start_timer "$module" 2>&1)
        
        # Property: Output should contain "Installing..." message
        [[ "$output" =~ "Installing..." ]]
        
        # Property: Output should contain the module name
        [[ "$output" =~ "$module" ]]
        
        # Property: Output should contain INFO level
        [[ "$output" =~ "INFO" ]]
        
        # Clean up
        end_timer "$module" > /dev/null 2>&1
    done
}

@test "Property 9: Module Execution Timing - End timer should log success message with duration" {
    # Property: When end_timer is called, it should log "Successful in X seconds!" message
    
    for iteration in {1..5}; do
        local module
        module=$(get_random_module)
        
        local delay=$((RANDOM % 2 + 1))  # 1-2 seconds
        
        # Start timer
        start_timer "$module" > /dev/null 2>&1
        sleep "$delay"
        
        # Capture output from end_timer
        local output
        output=$(end_timer "$module" 2>&1)
        
        # Property: Output should contain "Successful in" message
        [[ "$output" =~ "Successful in" ]]
        
        # Property: Output should contain "seconds!" message
        [[ "$output" =~ "seconds!" ]]
        
        # Property: Output should contain the module name
        [[ "$output" =~ "$module" ]]
        
        # Property: Output should contain INFO level
        [[ "$output" =~ "INFO" ]]
        
        # Property: Output should contain a number (the elapsed time)
        [[ "$output" =~ [0-9]+ ]]
    done
}

@test "Property 9: Module Execution Timing - Timer should handle rapid start/end cycles" {
    # Property: Rapid timer start/end cycles should work correctly without errors
    
    for iteration in {1..20}; do
        local module
        module=$(get_random_module)
        
        # Rapid start/end cycle
        start_timer "$module" > /dev/null 2>&1
        end_timer "$module" > /dev/null 2>&1
        
        # Property: Timer should be cleared after end_timer
        [[ -z "${MODULE_START_TIMES[$module]:-}" ]]
    done
}

@test "Property 9: Module Execution Timing - Timer should handle all available modules" {
    # Property: Timer functions should work correctly for all available modules
    
    local modules=("base" "docker" "golang" "jvm" "vscode" "fonts" "terminator" "dotnet")
    
    for module in "${modules[@]}"; do
        # Start timer
        start_timer "$module" > /dev/null 2>&1
        
        # Property: Timer should be stored
        [[ -n "${MODULE_START_TIMES[$module]:-}" ]]
        
        # Sleep briefly
        sleep 1
        
        # Get elapsed time
        local elapsed
        elapsed=$(get_elapsed_time "$module")
        
        # Property: Elapsed time should be at least 1 second
        [ "$elapsed" -ge 1 ]
        
        # End timer
        end_timer "$module" > /dev/null 2>&1
        
        # Property: Timer should be cleared
        [[ -z "${MODULE_START_TIMES[$module]:-}" ]]
    done
}

@test "Property 9: Module Execution Timing - Logging format should be consistent" {
    # Property: All timer-related log messages should follow the standard format
    
    for iteration in {1..10}; do
        local module
        module=$(get_random_module)
        
        # Capture start_timer output
        local start_output
        start_output=$(start_timer "$module" 2>&1)
        
        # Property: Start message should have timestamp format [YYYY-MM-DD HH:MM:SS]
        [[ "$start_output" =~ \[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]
        
        # Property: Start message should have module name in brackets
        [[ "$start_output" =~ \[$module\] ]]
        
        # Property: Start message should have level in brackets
        [[ "$start_output" =~ \[INFO\] ]]
        
        # Sleep briefly
        sleep 1
        
        # Capture end_timer output
        local end_output
        end_output=$(end_timer "$module" 2>&1)
        
        # Property: End message should have timestamp format [YYYY-MM-DD HH:MM:SS]
        [[ "$end_output" =~ \[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]
        
        # Property: End message should have module name in brackets
        [[ "$end_output" =~ \[$module\] ]]
        
        # Property: End message should contain "Successful in" text
        [[ "$end_output" =~ "Successful in" ]]
        
        # Property: End message should contain seconds
        [[ "$end_output" =~ "seconds!" ]]
    done
}

@test "Property 9: Module Execution Timing - Get elapsed time without ending timer" {
    # Property: get_elapsed_time should return elapsed time without clearing the timer
    
    for iteration in {1..5}; do
        local module
        module=$(get_random_module)
        
        # Start timer
        start_timer "$module" > /dev/null 2>&1
        
        # Sleep briefly
        sleep 1
        
        # Get elapsed time (without ending)
        local elapsed1
        elapsed1=$(get_elapsed_time "$module")
        
        # Property: Timer should still be stored
        [[ -n "${MODULE_START_TIMES[$module]:-}" ]]
        
        # Sleep a bit more
        sleep 1
        
        # Get elapsed time again
        local elapsed2
        elapsed2=$(get_elapsed_time "$module")
        
        # Property: Second elapsed time should be greater than first
        [ "$elapsed2" -gt "$elapsed1" ]
        
        # End timer
        end_timer "$module" > /dev/null 2>&1
    done
}

@test "Property 9: Module Execution Timing - Timer should handle module names with special characters" {
    # Property: Timer functions should work with various module name formats
    
    local test_modules=("base" "docker" "golang" "jvm" "vscode" "fonts" "terminator" "dotnet")
    
    for module in "${test_modules[@]}"; do
        # Start timer
        start_timer "$module" > /dev/null 2>&1
        
        # Property: Timer should be stored for this module
        [[ -n "${MODULE_START_TIMES[$module]:-}" ]]
        
        # End timer
        end_timer "$module" > /dev/null 2>&1
        
        # Property: Timer should be cleared
        [[ -z "${MODULE_START_TIMES[$module]:-}" ]]
    done
}
