#!/usr/bin/env bats

# Unit tests for parameter parsing functionality in prepare.sh

setup() {
    # Source the main script to access functions
    source prepare.sh
    
    # Reset global variables before each test
    TARGET_USERS=()
    SELECTED_MODULES=()
    INSTALL_BASE_PACKAGES=true
}

@test "parse_parameters handles empty arguments" {
    parse_parameters
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
    [ ${#SELECTED_MODULES[@]} -eq 0 ]
    [ "$INSTALL_BASE_PACKAGES" = true ]
}

@test "parse_parameters handles single user" {
    parse_parameters "-u=testuser"
    
    [ ${#TARGET_USERS[@]} -eq 1 ]
    [ "${TARGET_USERS[0]}" = "testuser" ]
}

@test "parse_parameters handles multiple users" {
    parse_parameters "-u=user1,user2,user3"
    
    [ ${#TARGET_USERS[@]} -eq 3 ]
    [ "${TARGET_USERS[0]}" = "user1" ]
    [ "${TARGET_USERS[1]}" = "user2" ]
    [ "${TARGET_USERS[2]}" = "user3" ]
}

@test "parse_parameters handles users with whitespace" {
    parse_parameters "-u=user1, user2 , user3"
    
    [ ${#TARGET_USERS[@]} -eq 3 ]
    [ "${TARGET_USERS[0]}" = "user1" ]
    [ "${TARGET_USERS[1]}" = "user2" ]
    [ "${TARGET_USERS[2]}" = "user3" ]
}

@test "parse_parameters handles empty user list" {
    parse_parameters "-u="
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

@test "parse_parameters handles invalid usernames" {
    parse_parameters "-u=valid_user,123invalid,UPPERCASE,valid-user2"
    
    [ ${#TARGET_USERS[@]} -eq 2 ]
    [ "${TARGET_USERS[0]}" = "valid_user" ]
    [ "${TARGET_USERS[1]}" = "valid-user2" ]
}

@test "parse_parameters handles single module flag" {
    parse_parameters "-docker"
    
    [ ${#SELECTED_MODULES[@]} -eq 1 ]
    [ "${SELECTED_MODULES[0]}" = "docker" ]
}

@test "parse_parameters handles multiple module flags" {
    parse_parameters "-docker" "-golang" "-vscode"
    
    [ ${#SELECTED_MODULES[@]} -eq 3 ]
    [ "${SELECTED_MODULES[0]}" = "docker" ]
    [ "${SELECTED_MODULES[1]}" = "golang" ]
    [ "${SELECTED_MODULES[2]}" = "vscode" ]
}

@test "parse_parameters handles combined users and modules" {
    parse_parameters "-u=dev,admin" "-docker" "-golang"
    
    [ ${#TARGET_USERS[@]} -eq 2 ]
    [ "${TARGET_USERS[0]}" = "dev" ]
    [ "${TARGET_USERS[1]}" = "admin" ]
    
    [ ${#SELECTED_MODULES[@]} -eq 2 ]
    [ "${SELECTED_MODULES[0]}" = "docker" ]
    [ "${SELECTED_MODULES[1]}" = "golang" ]
}

@test "validate_username accepts valid usernames" {
    run validate_username "validuser"
    [ "$status" -eq 0 ]
    
    run validate_username "user123"
    [ "$status" -eq 0 ]
    
    run validate_username "user_name"
    [ "$status" -eq 0 ]
    
    run validate_username "user-name"
    [ "$status" -eq 0 ]
    
    run validate_username "_username"
    [ "$status" -eq 0 ]
}

@test "validate_username rejects invalid usernames" {
    run validate_username ""
    [ "$status" -eq 1 ]
    
    run validate_username "123user"
    [ "$status" -eq 1 ]
    
    run validate_username "UPPERCASE"
    [ "$status" -eq 1 ]
    
    run validate_username "user@domain"
    [ "$status" -eq 1 ]
    
    run validate_username "user.name"
    [ "$status" -eq 1 ]
    
    # Test username too long (over 32 characters)
    run validate_username "thisusernameiswaytoolongtobevalid123"
    [ "$status" -eq 1 ]
}

@test "parse_user_list handles malformed input gracefully" {
    parse_user_list "user1,,user2,,"
    
    [ ${#TARGET_USERS[@]} -eq 2 ]
    [ "${TARGET_USERS[0]}" = "user1" ]
    [ "${TARGET_USERS[1]}" = "user2" ]
}

@test "parse_user_list handles single comma" {
    parse_user_list ","
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

@test "parse_user_list handles multiple commas only" {
    parse_user_list ",,,"
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

# Additional edge case tests for parameter parsing

@test "parse_parameters handles unknown flags gracefully" {
    run parse_parameters "-unknown-flag"
    [ "$status" -eq 1 ]
}

@test "parse_parameters handles malformed user parameter" {
    # Test -u without equals sign
    run parse_parameters "-u"
    [ "$status" -eq 1 ]
}

@test "parse_parameters handles malformed user parameter with space" {
    # Test -u with space instead of equals
    run parse_parameters "-u user1"
    [ "$status" -eq 1 ]
}

@test "parse_parameters handles duplicate module flags" {
    parse_parameters "-docker" "-docker" "-golang"
    
    # Should contain duplicates as the function doesn't deduplicate
    [ ${#SELECTED_MODULES[@]} -eq 3 ]
    [ "${SELECTED_MODULES[0]}" = "docker" ]
    [ "${SELECTED_MODULES[1]}" = "docker" ]
    [ "${SELECTED_MODULES[2]}" = "golang" ]
}

@test "parse_parameters handles mixed valid and invalid flags" {
    run parse_parameters "-docker" "-invalid" "-golang"
    [ "$status" -eq 1 ]
}

@test "parse_user_list handles extremely long user list" {
    local long_list="user1,user2,user3,user4,user5,user6,user7,user8,user9,user10,user11,user12,user13,user14,user15"
    parse_user_list "$long_list"
    
    [ ${#TARGET_USERS[@]} -eq 15 ]
}

@test "parse_user_list handles special characters in usernames" {
    parse_user_list "user@domain,user.name,user#hash,valid_user"
    
    # Only valid_user should be accepted
    [ ${#TARGET_USERS[@]} -eq 1 ]
    [ "${TARGET_USERS[0]}" = "valid_user" ]
}

@test "parse_user_list handles usernames with leading/trailing spaces" {
    parse_user_list "  user1  ,  user2  ,  user3  "
    
    [ ${#TARGET_USERS[@]} -eq 3 ]
    [ "${TARGET_USERS[0]}" = "user1" ]
    [ "${TARGET_USERS[1]}" = "user2" ]
    [ "${TARGET_USERS[2]}" = "user3" ]
}

@test "parse_user_list handles empty strings between commas" {
    parse_user_list "user1,,user2,,,user3,"
    
    [ ${#TARGET_USERS[@]} -eq 3 ]
    [ "${TARGET_USERS[0]}" = "user1" ]
    [ "${TARGET_USERS[1]}" = "user2" ]
    [ "${TARGET_USERS[2]}" = "user3" ]
}

@test "validate_username handles edge case usernames" {
    # Test minimum length (1 character)
    run validate_username "a"
    [ "$status" -eq 0 ]
    
    # Test maximum length (32 characters)
    run validate_username "abcdefghijklmnopqrstuvwxyz123456"
    [ "$status" -eq 0 ]
    
    # Test username starting with underscore
    run validate_username "_test"
    [ "$status" -eq 0 ]
    
    # Test username with all valid characters
    run validate_username "test_user-123"
    [ "$status" -eq 0 ]
}

@test "validate_username rejects edge case invalid usernames" {
    # Test username starting with number
    run validate_username "1user"
    [ "$status" -eq 1 ]
    
    # Test username starting with hyphen
    run validate_username "-user"
    [ "$status" -eq 1 ]
    
    # Test username with spaces
    run validate_username "user name"
    [ "$status" -eq 1 ]
    
    # Test username with special characters
    run validate_username "user$"
    [ "$status" -eq 1 ]
    
    # Test username with uppercase letters
    run validate_username "User"
    [ "$status" -eq 1 ]
    
    # Test exactly 33 characters (over limit)
    run validate_username "abcdefghijklmnopqrstuvwxyz1234567"
    [ "$status" -eq 1 ]
}

@test "parse_parameters handles help flags" {
    run parse_parameters "-h"
    [ "$status" -eq 0 ]
    
    run parse_parameters "--help"
    [ "$status" -eq 0 ]
}

@test "parse_parameters handles empty user list with equals" {
    parse_parameters "-u="
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

@test "parse_parameters handles user list with only commas" {
    parse_parameters "-u=,,,,"
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

@test "parse_parameters handles user list with only spaces" {
    parse_parameters "-u=   ,   ,   "
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

@test "parse_user_list handles null input" {
    # Test with empty string
    parse_user_list ""
    
    [ ${#TARGET_USERS[@]} -eq 0 ]
}

@test "parse_user_list handles single valid user with trailing comma" {
    parse_user_list "testuser,"
    
    [ ${#TARGET_USERS[@]} -eq 1 ]
    [ "${TARGET_USERS[0]}" = "testuser" ]
}

@test "parse_user_list handles single valid user with leading comma" {
    parse_user_list ",testuser"
    
    [ ${#TARGET_USERS[@]} -eq 1 ]
    [ "${TARGET_USERS[0]}" = "testuser" ]
}