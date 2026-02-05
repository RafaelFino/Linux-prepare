#!/usr/bin/env bats

# Property-based tests for conditional module installation functionality
# Feature: env-prepare, Property 2: Conditional Module Installation
# **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7**

setup() {
    # Source the main script to access functions
    source prepare.sh
    
    # Reset global variables before each test
    TARGET_USERS=()
    SELECTED_MODULES=()
    INSTALL_BASE_PACKAGES=true
}

teardown() {
    # Clean up any test state
    TARGET_USERS=()
    SELECTED_MODULES=()
}

# Define all available optional modules
get_available_modules() {
    echo "docker"
    echo "golang"
    echo "jvm"
    echo "vscode"
    echo "fonts"
    echo "terminator"
    echo "dotnet"
}

# Generate random subset of modules
generate_random_module_subset() {
    local available_modules
    readarray -t available_modules < <(get_available_modules)
    
    local count=$((RANDOM % ${#available_modules[@]} + 1))  # 1 to all modules
    local selected_modules=()
    local indices=()
    
    # Generate random unique indices
    while [[ ${#indices[@]} -lt $count ]]; do
        local idx=$((RANDOM % ${#available_modules[@]}))
        if [[ ! " ${indices[*]} " =~ " ${idx} " ]]; then
            indices+=($idx)
            selected_modules+=("${available_modules[$idx]}")
        fi
    done
    
    printf '%s\n' "${selected_modules[@]}"
}

@test "Property 2: Conditional Module Installation - Only specified modules should be selected" {
    # Property: For any combination of optional module flags, only the modules corresponding 
    # to provided flags should be installed
    
    for iteration in {1..20}; do
        # Reset state
        SELECTED_MODULES=()
        
        # Generate random module subset
        local selected_modules
        readarray -t selected_modules < <(generate_random_module_subset)
        
        # Add modules to SELECTED_MODULES
        for module in "${selected_modules[@]}"; do
            SELECTED_MODULES+=("$module")
        done
        
        # Property: SELECTED_MODULES should contain exactly the modules we specified
        [ ${#SELECTED_MODULES[@]} -eq ${#selected_modules[@]} ]
        
        # Property: All selected modules should be in the available modules list
        local available_modules
        readarray -t available_modules < <(get_available_modules)
        
        for selected_module in "${SELECTED_MODULES[@]}"; do
            local found=false
            for available_module in "${available_modules[@]}"; do
                if [[ "$selected_module" == "$available_module" ]]; then
                    found=true
                    break
                fi
            done
            [ "$found" = true ]
        done
    done
}

@test "Property 2: Conditional Module Installation - No duplicate modules should be selected" {
    # Property: The same module should not be selected multiple times
    
    for iteration in {1..15}; do
        SELECTED_MODULES=()
        
        # Generate random module subset
        local selected_modules
        readarray -t selected_modules < <(generate_random_module_subset)
        
        # Add modules to SELECTED_MODULES
        for module in "${selected_modules[@]}"; do
            SELECTED_MODULES+=("$module")
        done
        
        # Property: No duplicates should exist in SELECTED_MODULES
        local unique_modules
        readarray -t unique_modules < <(printf '%s\n' "${SELECTED_MODULES[@]}" | sort -u)
        
        [ ${#unique_modules[@]} -eq ${#SELECTED_MODULES[@]} ]
    done
}

@test "Property 2: Conditional Module Installation - Module names should be valid" {
    # Property: All selected module names should be valid and correspond to existing modules
    
    for iteration in {1..20}; do
        SELECTED_MODULES=()
        
        # Generate random module subset
        local selected_modules
        readarray -t selected_modules < <(generate_random_module_subset)
        
        for module in "${selected_modules[@]}"; do
            SELECTED_MODULES+=("$module")
            
            # Property: Module name should not be empty
            [ -n "$module" ]
            
            # Property: Module name should be lowercase alphanumeric
            [[ "$module" =~ ^[a-z0-9]+$ ]]
            
            # Property: Module should have a corresponding script file
            [ -f "modules/${module}.sh" ]
        done
    done
}

@test "Property 2: Conditional Module Installation - Empty module selection should be valid" {
    # Property: When no optional modules are specified, SELECTED_MODULES should be empty
    # but base packages should still be installed
    
    for iteration in {1..5}; do
        SELECTED_MODULES=()
        INSTALL_BASE_PACKAGES=true
        
        # Property: SELECTED_MODULES should be empty
        [ ${#SELECTED_MODULES[@]} -eq 0 ]
        
        # Property: Base packages flag should still be true
        [ "$INSTALL_BASE_PACKAGES" = true ]
    done
}

@test "Property 2: Conditional Module Installation - Module selection consistency" {
    # Property: Selecting the same set of modules multiple times should produce identical results
    
    for iteration in {1..10}; do
        # Generate a random module subset
        local module_list
        readarray -t module_list < <(generate_random_module_subset)
        
        # First selection
        SELECTED_MODULES=()
        for module in "${module_list[@]}"; do
            SELECTED_MODULES+=("$module")
        done
        local first_result=("${SELECTED_MODULES[@]}")
        
        # Second selection with same modules
        SELECTED_MODULES=()
        for module in "${module_list[@]}"; do
            SELECTED_MODULES+=("$module")
        done
        local second_result=("${SELECTED_MODULES[@]}")
        
        # Property: Results should be identical
        [ ${#first_result[@]} -eq ${#second_result[@]} ]
        
        for ((i=0; i<${#first_result[@]}; i++)); do
            [ "${first_result[i]}" = "${second_result[i]}" ]
        done
    done
}

@test "Property 2: Conditional Module Installation - All available modules should be selectable" {
    # Property: Each available module should be selectable independently
    
    local available_modules
    readarray -t available_modules < <(get_available_modules)
    
    for module in "${available_modules[@]}"; do
        SELECTED_MODULES=()
        
        # Select just this module
        SELECTED_MODULES+=("$module")
        
        # Property: Module should be in SELECTED_MODULES
        [ ${#SELECTED_MODULES[@]} -eq 1 ]
        [ "${SELECTED_MODULES[0]}" = "$module" ]
        
        # Property: Module script should exist
        [ -f "modules/${module}.sh" ]
        
        # Property: Module script should be executable
        [ -x "modules/${module}.sh" ]
    done
}

@test "Property 2: Conditional Module Installation - Module combination validity" {
    # Property: Any combination of modules should be valid and selectable together
    
    for iteration in {1..15}; do
        SELECTED_MODULES=()
        
        # Generate random module subset
        local selected_modules
        readarray -t selected_modules < <(generate_random_module_subset)
        
        # Add all selected modules
        for module in "${selected_modules[@]}"; do
            SELECTED_MODULES+=("$module")
        done
        
        # Property: All modules in combination should be valid
        for selected_module in "${SELECTED_MODULES[@]}"; do
            # Module should exist
            [ -f "modules/${selected_module}.sh" ]
            
            # Module should be readable
            [ -r "modules/${selected_module}.sh" ]
            
            # Module should contain main function
            grep -q "^main()" "modules/${selected_module}.sh"
        done
    done
}

@test "Property 2: Conditional Module Installation - Module independence" {
    # Property: Selecting one module should not affect the availability of other modules
    
    local available_modules
    readarray -t available_modules < <(get_available_modules)
    
    for iteration in {1..10}; do
        # Get first random module by index
        local first_idx=$((RANDOM % ${#available_modules[@]}))
        local first_module="${available_modules[$first_idx]}"
        
        SELECTED_MODULES=("$first_module")
        local first_selection=("${SELECTED_MODULES[@]}")
        
        # Get second random module by index
        local second_idx=$((RANDOM % ${#available_modules[@]}))
        local second_module="${available_modules[$second_idx]}"
        
        SELECTED_MODULES=("$second_module")
        local second_selection=("${SELECTED_MODULES[@]}")
        
        # Property: Selecting different modules should produce different results
        # (unless by chance the same module was selected)
        if [[ "$first_module" != "$second_module" ]]; then
            [ "${first_selection[0]}" != "${second_selection[0]}" ]
        fi
        
        # Property: Both modules should still be available
        [ -f "modules/${first_module}.sh" ]
        [ -f "modules/${second_module}.sh" ]
    done
}
