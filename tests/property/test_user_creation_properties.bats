#!/usr/bin/env bats

# Property-based tests for user creation functionality
# Feature: env-prepare, Property 4: User Creation from Parameters
# **Validates: Requirements 3.1**

setup() {
    # Source the main script to access functions
    source prepare.sh
    
    # Reset global variables before each test
    TARGET_USERS=()
    SELECTED_MODULES=()
    INSTALL_BASE_PACKAGES=true
    
    # Create a temporary directory for test users
    TEST_HOME_BASE="/tmp/test_home_$$"
    mkdir -p "$TEST_HOME_BASE"
    
    # Mock useradd and id commands for testing
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
}

teardown() {
    # Clean up test directory
    if [[ -d "$TEST_HOME_BASE" ]]; then
        rm -rf "$TEST_HOME_BASE"
    fi
    
    # Clean up any test users that might have been created
    for user in "${TARGET_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            userdel -r "$user" 2>/dev/null || true
        fi
    done
}

# Generate random valid username
generate_valid_username() {
    local length=$((RANDOM % 10 + 3))  # 3-12 characters
    local username=""
    
    # First character: letter or underscore
    local first_chars="abcdefghijklmnopqrstuvwxyz_"
    username="${first_chars:$((RANDOM % ${#first_chars})):1}"
    
    # Remaining characters: letters, digits, hyphens, underscores
    local chars="abcdefghijklmnopqrstuvwxyz0123456789_-"
    for ((i=1; i<length; i++)); do
        username+="${chars:$((RANDOM % ${#chars})):1}"
    done
    
    echo "$username"
}

# Generate random comma-separated user list
generate_user_list() {
    local count=$((RANDOM % 5 + 1))  # 1-5 users
    local users=()
    
    for ((i=0; i<count; i++)); do
        users+=("$(generate_valid_username)")
    done
    
    # Join with commas
    local IFS=','
    echo "${users[*]}"
}

@test "Property 4: User Creation from Parameters - Random valid user lists" {
    # Run property test with multiple iterations
    for iteration in {1..20}; do
        # Reset state
        TARGET_USERS=()
        
        # Generate random user list
        local user_list
        user_list=$(generate_user_list)
        
        # Parse the user list
        parse_user_list "$user_list"
        
        # Property: All users in the list should be added to TARGET_USERS
        # if they are valid usernames
        IFS=',' read -ra expected_users <<< "$user_list"
        local valid_count=0
        
        for user in "${expected_users[@]}"; do
            user=$(echo "$user" | xargs)  # Trim whitespace
            if validate_username "$user"; then
                valid_count=$((valid_count + 1))
            fi
        done
        
        # Assert: Number of target users should equal number of valid users
        [ ${#TARGET_USERS[@]} -eq $valid_count ]
        
        # Assert: All target users should be valid usernames
        for target_user in "${TARGET_USERS[@]}"; do
            run validate_username "$target_user"
            [ "$status" -eq 0 ]
        done
    done
}

@test "Property 4: User Creation from Parameters - Edge cases with random data" {
    # Test various edge cases with random data
    for iteration in {1..10}; do
        TARGET_USERS=()
        
        # Generate edge case scenarios
        case $((iteration % 4)) in
            0)
                # Empty list
                parse_user_list ""
                [ ${#TARGET_USERS[@]} -eq 0 ]
                ;;
            1)
                # Single user
                local single_user
                single_user=$(generate_valid_username)
                parse_user_list "$single_user"
                [ ${#TARGET_USERS[@]} -eq 1 ]
                [ "${TARGET_USERS[0]}" = "$single_user" ]
                ;;
            2)
                # List with extra commas and whitespace
                local user1 user2
                user1=$(generate_valid_username)
                user2=$(generate_valid_username)
                parse_user_list " $user1 , , $user2 , "
                [ ${#TARGET_USERS[@]} -eq 2 ]
                ;;
            3)
                # Mixed valid and invalid usernames
                local valid_user
                valid_user=$(generate_valid_username)
                parse_user_list "$valid_user,123invalid,INVALID"
                [ ${#TARGET_USERS[@]} -eq 1 ]
                [ "${TARGET_USERS[0]}" = "$valid_user" ]
                ;;
        esac
    done
}

@test "Property 4: User Creation from Parameters - Consistency across multiple calls" {
    # Property: Parsing the same user list multiple times should produce identical results
    for iteration in {1..10}; do
        local user_list
        user_list=$(generate_user_list)
        
        # Parse first time
        TARGET_USERS=()
        parse_user_list "$user_list"
        local first_result=("${TARGET_USERS[@]}")
        
        # Parse second time
        TARGET_USERS=()
        parse_user_list "$user_list"
        local second_result=("${TARGET_USERS[@]}")
        
        # Assert: Results should be identical
        [ ${#first_result[@]} -eq ${#second_result[@]} ]
        
        for ((i=0; i<${#first_result[@]}; i++)); do
            [ "${first_result[i]}" = "${second_result[i]}" ]
        done
    done
}

@test "Property 4: User Creation from Parameters - Username validation consistency" {
    # Property: Username validation should be consistent and follow Linux standards
    for iteration in {1..50}; do
        local username
        username=$(generate_valid_username)
        
        # Valid usernames should always pass validation
        run validate_username "$username"
        [ "$status" -eq 0 ]
        
        # When added to user list, should be included in TARGET_USERS
        TARGET_USERS=()
        parse_user_list "$username"
        [ ${#TARGET_USERS[@]} -eq 1 ]
        [ "${TARGET_USERS[0]}" = "$username" ]
    done
}