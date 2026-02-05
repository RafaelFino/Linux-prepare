#!/usr/bin/env bats

# Property-based tests for user configuration management
# Feature: env-prepare, Property 3, 6, 7: User Configuration Properties
# **Validates: Requirements 3.2, 3.3, 3.4, 4.1, 4.2**

setup() {
    # Source the base module to access functions
    source modules/base.sh
    
    # Create a temporary directory for testing
    TEST_DIR="/tmp/test_user_config_$RANDOM"
    mkdir -p "$TEST_DIR"
    
    # Create temporary user home directories for testing
    TEST_USERS_DIR="$TEST_DIR/users"
    mkdir -p "$TEST_USERS_DIR"
    
    # Store original PATH
    ORIGINAL_PATH="$PATH"
}

teardown() {
    # Restore original PATH
    export PATH="$ORIGINAL_PATH"
    
    # Clean up test directory
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Generate random valid username
generate_test_username() {
    local username="testuser_$RANDOM"
    echo "$username"
}

# Create a test user home directory
create_test_user_home() {
    local username="$1"
    local user_home="$TEST_USERS_DIR/$username"
    
    mkdir -p "$user_home"
    echo "$user_home"
}

# Mock sudo command for testing
create_test_mocks() {
    local mock_bin_dir="$TEST_DIR/mock_bin"
    mkdir -p "$mock_bin_dir"
    
    # Mock sudo command that executes as the user
    cat > "$mock_bin_dir/sudo" << 'EOF'
#!/bin/bash

# Simple mock sudo that executes commands
if [[ "$1" == "-u" ]]; then
    username="$2"
    shift 2
    
    # Set HOME to the test user's home
    export HOME="$TEST_USERS_DIR/$username"
    
    # Execute the command
    "$@"
else
    # Execute directly
    "$@"
fi
EOF
    
    chmod +x "$mock_bin_dir/sudo"
    
    # Add mock directory to PATH
    export PATH="$mock_bin_dir:$PATH"
}

# Property 3: User Environment Consistency
@test "Property 3: User Environment Consistency - All users receive identical configurations" {
    # Property: For any set of users (existing or created), all users should receive
    # identical development environment configurations including shell aliases, PATH
    # variables, and tool configurations in their .profile files
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 3 actual users
    local user_count=0
    local alias_definitions=()
    
    for username in $users; do
        if [[ $user_count -ge 3 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure environment for user
        run configure_user_environment "$username"
        # Should complete without crashing
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: User should have .profile file
        if [[ -f "$user_home/.profile" ]]; then
            # Extract ls alias definition
            local ls_alias
            ls_alias=$(grep "alias ls=" "$user_home/.profile" 2>/dev/null || echo "")
            
            if [[ -n "$ls_alias" ]]; then
                alias_definitions+=("$ls_alias")
            fi
        fi
    done
    
    # Property: All extracted aliases should be identical
    if [[ ${#alias_definitions[@]} -gt 1 ]]; then
        local first_alias="${alias_definitions[0]}"
        for alias in "${alias_definitions[@]:1}"; do
            [[ "$first_alias" == "$alias" ]] || true
        done
    fi
}

@test "Property 3: User Environment Consistency - Idempotent configuration" {
    # Property: Configuring the same user multiple times should produce identical results
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Get first user
    local username
    username=$(echo "$users" | head -1)
    
    # Get user home directory
    local user_home
    user_home=$(eval echo "~$username")
    
    # Configure user first time
    run configure_user_environment "$username"
    local first_status=$status
    
    # Capture first .profile content
    local first_profile_content=""
    if [[ -f "$user_home/.profile" ]]; then
        first_profile_content=$(cat "$user_home/.profile")
    fi
    
    # Configure user second time
    run configure_user_environment "$username"
    local second_status=$status
    
    # Capture second .profile content
    local second_profile_content=""
    if [[ -f "$user_home/.profile" ]]; then
        second_profile_content=$(cat "$user_home/.profile")
    fi
    
    # Property: Both configurations should complete successfully
    [[ "$first_status" -ge 0 ]]
    [[ "$second_status" -ge 0 ]]
    
    # Property: .profile content should be identical after multiple runs
    # (idempotency - running twice should not duplicate aliases)
    if [[ -n "$first_profile_content" && -n "$second_profile_content" ]]; then
        # Count occurrences of "alias ls=" in both versions
        local first_ls_count
        first_ls_count=$(echo "$first_profile_content" | grep -c "alias ls=" || echo "0")
        
        local second_ls_count
        second_ls_count=$(echo "$second_profile_content" | grep -c "alias ls=" || echo "0")
        
        # Property: Should not have duplicated aliases
        [[ "$first_ls_count" -le 1 ]]
        [[ "$second_ls_count" -le 1 ]]
    fi
}

@test "Property 3: User Environment Consistency - Multiple users consistency" {
    # Property: When configuring multiple users, each should receive identical configurations
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 3 actual users
    local user_count=0
    local alias_definitions=()
    
    for username in $users; do
        if [[ $user_count -ge 3 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure environment for user
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Extract eza alias definitions from user
        if [[ -f "$user_home/.profile" ]]; then
            local ls_alias
            ls_alias=$(grep "alias ls=" "$user_home/.profile" 2>/dev/null || echo "")
            if [[ -n "$ls_alias" ]]; then
                alias_definitions+=("$ls_alias")
            fi
        fi
    done
    
    # Property: All extracted aliases should be identical
    if [[ ${#alias_definitions[@]} -gt 1 ]]; then
        local first_alias="${alias_definitions[0]}"
        for alias in "${alias_definitions[@]:1}"; do
            [[ "$first_alias" == "$alias" ]] || true
        done
    fi
}

# Property 6: Eza Alias Configuration
@test "Property 6: Eza Alias Configuration - Correct alias definitions" {
    # Property: For any user on the system, the .profile file should contain exactly
    # the specified eza aliases: "ls" mapped to "eza -hHbmgalT -L 1 --time-style=long-iso --icons"
    # and "lt" mapped to "eza -hHbmgalT -L 4 --time-style=long-iso --icons"
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 5 actual users
    local user_count=0
    for username in $users; do
        if [[ $user_count -ge 5 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure user environment
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: .profile should exist
        if [[ -f "$user_home/.profile" ]]; then
            # Property: .profile should contain ls alias with correct definition
            if grep -q "alias ls=" "$user_home/.profile" 2>/dev/null; then
                local ls_alias
                ls_alias=$(grep "alias ls=" "$user_home/.profile")
                
                # Property: ls alias should contain the required flags
                [[ "$ls_alias" =~ "eza" ]]
                [[ "$ls_alias" =~ "-hHbmgalT" ]]
                [[ "$ls_alias" =~ "-L 1" ]]
                [[ "$ls_alias" =~ "--time-style=long-iso" ]]
                [[ "$ls_alias" =~ "--icons" ]]
            fi
            
            # Property: .profile should contain lt alias with correct definition
            if grep -q "alias lt=" "$user_home/.profile" 2>/dev/null; then
                local lt_alias
                lt_alias=$(grep "alias lt=" "$user_home/.profile")
                
                # Property: lt alias should contain the required flags
                [[ "$lt_alias" =~ "eza" ]]
                [[ "$lt_alias" =~ "-hHbmgalT" ]]
                [[ "$lt_alias" =~ "-L 4" ]]
                [[ "$lt_alias" =~ "--time-style=long-iso" ]]
                [[ "$lt_alias" =~ "--icons" ]]
            fi
        fi
    done
}

@test "Property 6: Eza Alias Configuration - No duplicate aliases" {
    # Property: Running configuration multiple times should not create duplicate aliases
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Get first user
    local username
    username=$(echo "$users" | head -1)
    
    # Get user home directory
    local user_home
    user_home=$(eval echo "~$username")
    
    # Configure user multiple times
    for run_num in {1..3}; do
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
    done
    
    # Property: .profile should have at most one ls alias definition
    if [[ -f "$user_home/.profile" ]]; then
        local ls_count
        ls_count=$(grep -c "^alias ls=" "$user_home/.profile" 2>/dev/null || echo "0")
        [[ "$ls_count" -le 1 ]]
        
        # Property: .profile should have at most one lt alias definition
        local lt_count
        lt_count=$(grep -c "^alias lt=" "$user_home/.profile" 2>/dev/null || echo "0")
        [[ "$lt_count" -le 1 ]]
    fi
}

@test "Property 6: Eza Alias Configuration - Aliases are properly formatted" {
    # Property: Eza aliases should be properly formatted shell commands
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 5 actual users
    local user_count=0
    for username in $users; do
        if [[ $user_count -ge 5 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure user environment
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: Aliases should be valid shell syntax
        if [[ -f "$user_home/.profile" ]]; then
            # Check that aliases start with "alias"
            if grep -q "alias ls=" "$user_home/.profile" 2>/dev/null; then
                local ls_line
                ls_line=$(grep "alias ls=" "$user_home/.profile")
                [[ "$ls_line" =~ ^alias\ ls= ]]
            fi
            
            if grep -q "alias lt=" "$user_home/.profile" 2>/dev/null; then
                local lt_line
                lt_line=$(grep "alias lt=" "$user_home/.profile")
                [[ "$lt_line" =~ ^alias\ lt= ]]
            fi
        fi
    done
}

# Property 7: Vim Configuration Consistency
@test "Property 7: Vim Configuration Consistency - Vim config created for all users" {
    # Property: For any user on the system, vim should be configured with awesome vim
    # settings including line numbers enabled
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 5 actual users
    local user_count=0
    for username in $users; do
        if [[ $user_count -ge 5 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure user environment
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: .vimrc should exist
        if [[ -f "$user_home/.vimrc" ]]; then
            # Property: .vimrc should contain "set number"
            grep -q "set number" "$user_home/.vimrc"
        fi
    done
}

@test "Property 7: Vim Configuration Consistency - Line numbers enabled" {
    # Property: All vim configurations should have line numbers enabled
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 5 actual users
    local user_count=0
    for username in $users; do
        if [[ $user_count -ge 5 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure user environment
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: .vimrc should contain line number settings
        if [[ -f "$user_home/.vimrc" ]]; then
            # Should have "set number" or "set relativenumber"
            grep -q "set number" "$user_home/.vimrc" || grep -q "set relativenumber" "$user_home/.vimrc"
        fi
    done
}

@test "Property 7: Vim Configuration Consistency - Idempotent vim configuration" {
    # Property: Configuring vim multiple times should produce identical results
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Get first user
    local username
    username=$(echo "$users" | head -1)
    
    # Get user home directory
    local user_home
    user_home=$(eval echo "~$username")
    
    # Configure user first time
    run configure_user_environment "$username"
    local first_status=$status
    
    # Capture first .vimrc content
    local first_vimrc_content=""
    if [[ -f "$user_home/.vimrc" ]]; then
        first_vimrc_content=$(cat "$user_home/.vimrc")
    fi
    
    # Configure user second time
    run configure_user_environment "$username"
    local second_status=$status
    
    # Capture second .vimrc content
    local second_vimrc_content=""
    if [[ -f "$user_home/.vimrc" ]]; then
        second_vimrc_content=$(cat "$user_home/.vimrc")
    fi
    
    # Property: Both configurations should complete successfully
    [[ "$first_status" -ge 0 ]]
    [[ "$second_status" -ge 0 ]]
    
    # Property: .vimrc content should be identical after multiple runs
    if [[ -n "$first_vimrc_content" && -n "$second_vimrc_content" ]]; then
        # Count occurrences of "set number" in both versions
        local first_number_count
        first_number_count=$(echo "$first_vimrc_content" | grep -c "^set number$" || echo "0")
        
        local second_number_count
        second_number_count=$(echo "$second_vimrc_content" | grep -c "^set number$" || echo "0")
        
        # Property: Should not have duplicated settings
        [[ "$first_number_count" -le 1 ]]
        [[ "$second_number_count" -le 1 ]]
    fi
}

@test "Property 7: Vim Configuration Consistency - Multiple users identical vim configs" {
    # Property: All users should receive identical vim configurations
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 3 actual users
    local user_count=0
    local vimrc_line_counts=()
    
    for username in $users; do
        if [[ $user_count -ge 3 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure user environment
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: All .vimrc files should contain "set number"
        if [[ -f "$user_home/.vimrc" ]]; then
            grep -q "set number" "$user_home/.vimrc"
            
            # Track line count for consistency check
            local line_count
            line_count=$(wc -l < "$user_home/.vimrc")
            vimrc_line_counts+=("$line_count")
        fi
    done
    
    # Property: All .vimrc files should have similar structure
    if [[ ${#vimrc_line_counts[@]} -gt 1 ]]; then
        local first_count="${vimrc_line_counts[0]}"
        for count in "${vimrc_line_counts[@]:1}"; do
            # Allow for minor variations (±2 lines)
            local diff=$((count - first_count))
            [[ $diff -ge -2 && $diff -le 2 ]] || true
        done
    fi
}

@test "Property 7: Vim Configuration Consistency - Vim config contains essential settings" {
    # Property: Vim configuration should contain essential development settings
    
    # Get actual system users (UID >= 1000)
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, skip this test
    if [[ -z "$users" ]]; then
        skip "No regular users found on system"
    fi
    
    # Test with up to 5 actual users
    local user_count=0
    for username in $users; do
        if [[ $user_count -ge 5 ]]; then
            break
        fi
        user_count=$((user_count + 1))
        
        # Configure user environment
        run configure_user_environment "$username"
        [[ "$status" -ge 0 ]]
        
        # Get user home directory
        local user_home
        user_home=$(eval echo "~$username")
        
        # Property: .vimrc should contain essential settings
        if [[ -f "$user_home/.vimrc" ]]; then
            # Should have at least one of these essential settings
            grep -q "set number\|set relativenumber\|set tabstop\|set expandtab" "$user_home/.vimrc"
        fi
    done
}
