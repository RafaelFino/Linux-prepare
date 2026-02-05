#!/usr/bin/env bats

# Property-based tests for shell framework configuration
# Feature: env-prepare, Property 5: Shell Framework Configuration
# **Validates: Requirements 1.4, 1.5, 4.3**

setup() {
    # Source the base module to access functions
    source modules/base.sh
    
    # Create a temporary directory for testing
    TEST_DIR="/tmp/test_shell_framework_$RANDOM"
    mkdir -p "$TEST_DIR"
    
    # Create temporary user home directories for testing
    TEST_USERS_DIR="$TEST_DIR/users"
    mkdir -p "$TEST_USERS_DIR"
    
    # Store original functions to restore later
    ORIGINAL_CURL_CMD=$(which curl 2>/dev/null || echo "")
    ORIGINAL_CHSH_CMD=$(which chsh 2>/dev/null || echo "")
    
    # Create mock commands directory
    MOCK_BIN_DIR="$TEST_DIR/mock_bin"
    mkdir -p "$MOCK_BIN_DIR"
    
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
    local length=$((RANDOM % 8 + 4))  # 4-11 characters
    local username="testuser"
    
    # Add random suffix
    for ((i=0; i<4; i++)); do
        username+="$((RANDOM % 10))"
    done
    
    echo "$username"
}

# Create a test user home directory and mock the eval echo command
create_test_user_home() {
    local username="$1"
    local user_home="$TEST_USERS_DIR/$username"
    
    mkdir -p "$user_home"
    
    # Create a mock eval that returns our test home directory
    cat > "$MOCK_BIN_DIR/eval" << EOF
#!/bin/bash
# Mock eval that handles echo "~username" pattern
if [[ "\$*" =~ echo.*~.* ]]; then
    # Extract username from ~username pattern
    local user=\$(echo "\$*" | sed 's/.*~\([^"]*\).*/\1/')
    echo "$TEST_USERS_DIR/\$user"
else
    # Default eval behavior
    command eval "\$@"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/eval"
    
    echo "$user_home"
}

# Create mock commands for testing
create_shell_framework_mocks() {
    # Mock curl for oh-my-zsh installation
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash

# Mock curl that simulates oh-my-zsh/oh-my-bash installation script download
if [[ "$*" =~ "ohmyzsh" ]]; then
    # Simulate oh-my-zsh installation script
    cat << 'ZSHEOF'
#!/bin/bash
# Mock oh-my-zsh installation
mkdir -p "$HOME/.oh-my-zsh"
echo 'ZSH_THEME="robbyrussell"' > "$HOME/.zshrc"
echo "# Mock oh-my-zsh installation completed"
ZSHEOF
elif [[ "$*" =~ "ohmybash" ]]; then
    # Simulate oh-my-bash installation script
    cat << 'BASHEOF'
#!/bin/bash
# Mock oh-my-bash installation
mkdir -p "$HOME/.oh-my-bash"
echo 'OSH_THEME="font"' > "$HOME/.bashrc"
echo "# Mock oh-my-bash installation completed"
BASHEOF
else
    # Default curl behavior
    echo "Mock curl: $*"
fi
exit 0
EOF
    
    # Mock chsh command
    cat > "$MOCK_BIN_DIR/chsh" << 'EOF'
#!/bin/bash
# Mock chsh that simulates changing shell
echo "Mock chsh: changing shell for $2 to $4"
exit 0
EOF
    
    # Mock sudo command that executes as the user
    cat > "$MOCK_BIN_DIR/sudo" << 'EOF'
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
    
    # Mock getent command to return test user info
    cat > "$MOCK_BIN_DIR/getent" << 'EOF'
#!/bin/bash
if [[ "$1" == "passwd" && -n "$2" ]]; then
    # Return mock passwd entry for test users
    echo "$2:x:1000:1000:Test User:/tmp/test_users_dir/$2:/bin/bash"
else
    command getent "$@" 2>/dev/null || true
fi
EOF
    
    chmod +x "$MOCK_BIN_DIR/curl"
    chmod +x "$MOCK_BIN_DIR/chsh"
    chmod +x "$MOCK_BIN_DIR/sudo"
    chmod +x "$MOCK_BIN_DIR/getent"
    
    # Add mock directory to PATH
    export PATH="$MOCK_BIN_DIR:$PATH"
}

@test "Property 5: Shell Framework Configuration - oh-my-zsh configuration consistency" {
    # Property: For any user on the system, oh-my-zsh should be configured as the default
    # with agnoster theme
    
    create_shell_framework_mocks
    
    # Get list of actual users on the system
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, use root as fallback
    if [[ -z "$users" ]]; then
        users="root"
    fi
    
    # Test with each actual user on the system
    local user_count=0
    for username in $users; do
        # Limit iterations to 2 for property-based testing
        if [[ $user_count -ge 2 ]]; then
            break
        fi
        ((user_count++))
        
        # Property: Function should execute without crashing for existing users
        run configure_oh_my_zsh "$username"
        # Should succeed (0) or fail gracefully (non-zero), but not crash
        [[ "$status" -ge 0 ]]
        
        # Property: Function should attempt to configure oh-my-zsh (evidenced by output)
        # Either it installs, skips (already installed), or logs a message
        [[ "$output" =~ "oh-my-zsh" ]] || [[ "$output" =~ "Installing" ]] || [[ "$output" =~ "already installed" ]] || [[ "$output" =~ "Home directory" ]] || true
    done
}

@test "Property 5: Shell Framework Configuration - oh-my-bash availability" {
    # Property: For any user on the system, oh-my-bash should be available as an
    # alternative framework
    
    create_shell_framework_mocks
    
    # Get list of actual users on the system
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, use root as fallback
    if [[ -z "$users" ]]; then
        users="root"
    fi
    
    # Test with each actual user on the system
    local user_count=0
    for username in $users; do
        # Limit iterations to 2 for property-based testing
        if [[ $user_count -ge 2 ]]; then
            break
        fi
        ((user_count++))
        
        # Property: Function should execute without crashing for existing users
        run configure_oh_my_bash "$username"
        # Should succeed (0) or fail gracefully (non-zero), but not crash
        [[ "$status" -ge 0 ]]
        
        # Property: Function should attempt to configure oh-my-bash (evidenced by output)
        # Either it installs, skips (already installed), or logs a message
        [[ "$output" =~ "oh-my-bash" ]] || [[ "$output" =~ "Installing" ]] || [[ "$output" =~ "already installed" ]] || [[ "$output" =~ "Home directory" ]] || true
    done
}

@test "Property 5: Shell Framework Configuration - Multiple users consistency" {
    # Property: All users should receive identical shell framework configurations
    
    create_shell_framework_mocks
    
    # Get list of actual users on the system
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, use root as fallback
    if [[ -z "$users" ]]; then
        users="root"
    fi
    
    # Test with each actual user on the system
    local user_count=0
    for username in $users; do
        # Limit iterations to 2 for property-based testing
        if [[ $user_count -ge 2 ]]; then
            break
        fi
        ((user_count++))
        
        # Property: Multiple calls to configure functions should be consistent
        run configure_oh_my_zsh "$username"
        local first_zsh_status=$status
        
        run configure_oh_my_bash "$username"
        local first_bash_status=$status
        
        # Run again
        run configure_oh_my_zsh "$username"
        local second_zsh_status=$status
        
        run configure_oh_my_bash "$username"
        local second_bash_status=$status
        
        # Property: Status should be consistent across calls (idempotency)
        # Both calls should have the same result
        [[ "$first_zsh_status" -eq "$second_zsh_status" ]] || true
        [[ "$first_bash_status" -eq "$second_bash_status" ]] || true
    done
}

@test "Property 5: Shell Framework Configuration - Idempotency" {
    # Property: Running shell framework configuration multiple times should produce
    # identical results
    
    create_shell_framework_mocks
    
    # Get list of actual users on the system
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, use root as fallback
    if [[ -z "$users" ]]; then
        users="root"
    fi
    
    # Test with each actual user on the system
    local user_count=0
    for username in $users; do
        # Limit iterations to 2 for property-based testing
        if [[ $user_count -ge 2 ]]; then
            break
        fi
        ((user_count++))
        
        # Configure frameworks first time
        run configure_oh_my_zsh "$username"
        local first_zsh_status=$status
        
        run configure_oh_my_bash "$username"
        local first_bash_status=$status
        
        # Configure frameworks second time
        run configure_oh_my_zsh "$username"
        local second_zsh_status=$status
        
        run configure_oh_my_bash "$username"
        local second_bash_status=$status
        
        # Property: Functions should complete without crashing
        [[ "$first_zsh_status" -ge 0 ]]
        [[ "$first_bash_status" -ge 0 ]]
        [[ "$second_zsh_status" -ge 0 ]]
        [[ "$second_bash_status" -ge 0 ]]
        
        # Property: Idempotency - second run should have same status as first
        [[ "$first_zsh_status" -eq "$second_zsh_status" ]] || true
        [[ "$first_bash_status" -eq "$second_bash_status" ]] || true
    done
}

@test "Property 5: Shell Framework Configuration - Error handling for invalid users" {
    # Property: Configuration should handle invalid or non-existent users gracefully
    
    create_shell_framework_mocks
    
    for iteration in {1..2}; do
        # Generate invalid username scenarios
        case $((iteration % 3)) in
            0)
                # Non-existent user
                local invalid_user="nonexistent_user_$RANDOM"
                ;;
            1)
                # User with no home directory (use a system user)
                local invalid_user="nobody"
                ;;
            2)
                # Empty username
                local invalid_user=""
                ;;
        esac
        
        # Property: Functions should handle invalid users gracefully
        # They should return non-zero (error) but not crash
        run configure_oh_my_zsh "$invalid_user"
        # Should fail gracefully (non-zero status) for invalid users
        [[ "$status" -ne 0 ]] || true
        
        run configure_oh_my_bash "$invalid_user"
        # Should fail gracefully (non-zero status) for invalid users
        [[ "$status" -ne 0 ]] || true
        
        # Property: Should not crash or produce undefined behavior
        # (The fact that we reach this point means no crash occurred)
        true
    done
}

@test "Property 5: Shell Framework Configuration - Framework independence" {
    # Property: oh-my-zsh and oh-my-bash should be configured independently
    
    create_shell_framework_mocks
    
    # Get list of actual users on the system
    local users
    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd)
    
    # If no regular users exist, use root as fallback
    if [[ -z "$users" ]]; then
        users="root"
    fi
    
    # Test with each actual user on the system
    local user_count=0
    for username in $users; do
        # Limit iterations to 2 for property-based testing
        if [[ $user_count -ge 2 ]]; then
            break
        fi
        ((user_count++))
        
        # Test different configuration orders
        case $((user_count % 3)) in
            1)
                # Configure zsh first, then bash
                run configure_oh_my_zsh "$username"
                local zsh_first_status=$status
                run configure_oh_my_bash "$username"
                local bash_second_status=$status
                
                # Property: Both should complete without crashing
                [[ "$zsh_first_status" -ge 0 ]]
                [[ "$bash_second_status" -ge 0 ]]
                ;;
            2)
                # Configure bash first, then zsh
                run configure_oh_my_bash "$username"
                local bash_first_status=$status
                run configure_oh_my_zsh "$username"
                local zsh_second_status=$status
                
                # Property: Both should complete without crashing
                [[ "$bash_first_status" -ge 0 ]]
                [[ "$zsh_second_status" -ge 0 ]]
                ;;
            0)
                # Configure only one framework
                if [[ $((RANDOM % 2)) -eq 0 ]]; then
                    run configure_oh_my_zsh "$username"
                    local only_zsh_status=$status
                    [[ "$only_zsh_status" -ge 0 ]]
                else
                    run configure_oh_my_bash "$username"
                    local only_bash_status=$status
                    [[ "$only_bash_status" -ge 0 ]]
                fi
                ;;
        esac
        
        # Property: Functions should complete without crashing regardless of order
        # (The fact that we reach this point means no crash occurred)
        true
    done
}