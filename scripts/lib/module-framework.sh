#!/usr/bin/env bash

# ============================================================================
# Module Execution Framework for Linux-prepare Modular Architecture
# ============================================================================
# This framework provides utilities for executing and managing modules
# Used by the main prepare.sh script to orchestrate module execution

# Note: This framework assumes logging.sh and version-detection.sh are already sourced
# by the calling script (prepare.sh)

# ============================================================================
# Module Framework Configuration
# ============================================================================

# Base directories
MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../modules" && pwd)"
LANGUAGES_DIR="$MODULES_DIR/languages"

# Module execution tracking
declare -A MODULE_STATUS
declare -A MODULE_EXECUTION_TIME

# ============================================================================
# Module Discovery Functions
# ============================================================================

# List all available modules
list_available_modules() {
    local modules=()
    
    # Find all .sh files in modules directory
    if [ -d "$MODULES_DIR" ]; then
        while IFS= read -r -d '' file; do
            local module_name=$(basename "$file" .sh)
            modules+=("$module_name")
        done < <(find "$MODULES_DIR" -name "*.sh" -type f -print0)
    fi
    
    # Find language modules
    if [ -d "$LANGUAGES_DIR" ]; then
        while IFS= read -r -d '' file; do
            local module_name="languages/$(basename "$file" .sh)"
            modules+=("$module_name")
        done < <(find "$LANGUAGES_DIR" -name "*.sh" -type f -print0)
    fi
    
    printf '%s\n' "${modules[@]}" | sort
}

# Check if module exists
module_exists() {
    local module_name="$1"
    local module_path
    
    # Check if it's a language module
    if [[ "$module_name" == languages/* ]]; then
        local lang_module=$(echo "$module_name" | cut -d'/' -f2)
        module_path="$LANGUAGES_DIR/${lang_module}.sh"
    else
        module_path="$MODULES_DIR/${module_name}.sh"
    fi
    
    [ -f "$module_path" ]
}

# Get module path
get_module_path() {
    local module_name="$1"
    
    # Check if it's a language module
    if [[ "$module_name" == languages/* ]]; then
        local lang_module=$(echo "$module_name" | cut -d'/' -f2)
        echo "$LANGUAGES_DIR/${lang_module}.sh"
    else
        echo "$MODULES_DIR/${module_name}.sh"
    fi
}

# ============================================================================
# Module Execution Functions
# ============================================================================

# Execute a single module
execute_module() {
    local module_name="$1"
    shift
    local module_args=("$@")
    
    log_info "Executing module: $module_name"
    
    # Check if module exists
    if ! module_exists "$module_name"; then
        log_error "Module not found: $module_name"
        MODULE_STATUS["$module_name"]="not_found"
        return 1
    fi
    
    local module_path=$(get_module_path "$module_name")
    local start_time=$(date +%s)
    
    # Mark module as running
    MODULE_STATUS["$module_name"]="running"
    
    # Execute the module
    if bash "$module_path" "${module_args[@]}"; then
        local end_time=$(date +%s)
        local execution_time=$((end_time - start_time))
        
        MODULE_STATUS["$module_name"]="success"
        MODULE_EXECUTION_TIME["$module_name"]=$execution_time
        
        log_success "Module '$module_name' completed successfully (${execution_time}s)"
        return 0
    else
        local end_time=$(date +%s)
        local execution_time=$((end_time - start_time))
        
        MODULE_STATUS["$module_name"]="failed"
        MODULE_EXECUTION_TIME["$module_name"]=$execution_time
        
        log_error "Module '$module_name' failed (${execution_time}s)"
        return 1
    fi
}

# Execute multiple modules in sequence
execute_modules() {
    local modules=("$@")
    local failed_modules=()
    local total_start_time=$(date +%s)
    
    log_info "Executing ${#modules[@]} modules in sequence"
    
    for module in "${modules[@]}"; do
        if ! execute_module "$module"; then
            failed_modules+=("$module")
        fi
    done
    
    local total_end_time=$(date +%s)
    local total_execution_time=$((total_end_time - total_start_time))
    
    # Report results
    log_info "Module execution completed (${total_execution_time}s total)"
    
    if [ ${#failed_modules[@]} -eq 0 ]; then
        log_success "All modules executed successfully"
        return 0
    else
        log_error "Failed modules: ${failed_modules[*]}"
        return 1
    fi
}

# Execute module with conditional logic
execute_module_conditional() {
    local module_name="$1"
    local condition="$2"
    shift 2
    local module_args=("$@")
    
    # Evaluate condition
    case "$condition" in
        "always")
            execute_module "$module_name" "${module_args[@]}"
            ;;
        "desktop_only")
            if is_desktop_environment_detected; then
                execute_module "$module_name" "${module_args[@]}"
            else
                log_skip "Skipping module '$module_name' (no desktop environment)"
                MODULE_STATUS["$module_name"]="skipped"
            fi
            ;;
        "server_only")
            if ! is_desktop_environment_detected; then
                execute_module "$module_name" "${module_args[@]}"
            else
                log_skip "Skipping module '$module_name' (desktop environment detected)"
                MODULE_STATUS["$module_name"]="skipped"
            fi
            ;;
        "ubuntu_only")
            if is_ubuntu_based; then
                execute_module "$module_name" "${module_args[@]}"
            else
                log_skip "Skipping module '$module_name' (not Ubuntu-based)"
                MODULE_STATUS["$module_name"]="skipped"
            fi
            ;;
        "popos_only")
            if is_popos; then
                execute_module "$module_name" "${module_args[@]}"
            else
                log_skip "Skipping module '$module_name' (not Pop!_OS)"
                MODULE_STATUS["$module_name"]="skipped"
            fi
            ;;
        *)
            log_error "Unknown condition: $condition"
            return 1
            ;;
    esac
}

# ============================================================================
# Module Status and Reporting Functions
# ============================================================================

# Get module status
get_module_status() {
    local module_name="$1"
    echo "${MODULE_STATUS[$module_name]:-not_executed}"
}

# Get module execution time
get_module_execution_time() {
    local module_name="$1"
    echo "${MODULE_EXECUTION_TIME[$module_name]:-0}"
}

# Print module execution summary
print_module_summary() {
    local total_modules=0
    local successful_modules=0
    local failed_modules=0
    local skipped_modules=0
    local total_time=0
    
    log_info "Module Execution Summary:"
    log_info "========================"
    
    for module in $(list_available_modules); do
        local status=$(get_module_status "$module")
        local exec_time=$(get_module_execution_time "$module")
        
        case "$status" in
            "success")
                log_success "✓ $module (${exec_time}s)"
                ((successful_modules++))
                ((total_time += exec_time))
                ;;
            "failed")
                log_error "✗ $module (${exec_time}s)"
                ((failed_modules++))
                ((total_time += exec_time))
                ;;
            "skipped")
                log_skip "⏭ $module"
                ((skipped_modules++))
                ;;
            "not_found")
                log_error "? $module (not found)"
                ((failed_modules++))
                ;;
            "not_executed")
                # Don't count modules that weren't supposed to run
                continue
                ;;
        esac
        ((total_modules++))
    done
    
    log_info "========================"
    log_info "Total modules: $total_modules"
    log_info "Successful: $successful_modules"
    log_info "Failed: $failed_modules"
    log_info "Skipped: $skipped_modules"
    log_info "Total execution time: ${total_time}s"
}

# ============================================================================
# Module Dependency Management
# ============================================================================

# Define module dependencies (updated to reflect actual modules)
declare -A MODULE_DEPENDENCIES=(
    ["system-detection"]=""
    ["docker-install"]="system-detection"
    ["languages/golang-install"]="system-detection"
    ["languages/python-install"]="system-detection"
    ["languages/dotnet-install"]="system-detection"
    ["languages/jvm-kotlin-install"]="system-detection"
    ["terminal-config"]="system-detection"
    ["desktop-components"]="system-detection"
)

# Get module dependencies
get_module_dependencies() {
    local module_name="$1"
    echo "${MODULE_DEPENDENCIES[$module_name]:-}"
}

# Check if module dependencies are satisfied
check_module_dependencies() {
    local module_name="$1"
    local dependencies=$(get_module_dependencies "$module_name")
    
    if [ -z "$dependencies" ]; then
        return 0  # No dependencies
    fi
    
    for dep in $dependencies; do
        local dep_status=$(get_module_status "$dep")
        if [ "$dep_status" != "success" ]; then
            log_error "Module '$module_name' dependency '$dep' not satisfied (status: $dep_status)"
            return 1
        fi
    done
    
    return 0
}

# Execute modules with dependencies and configuration-based skipping
execute_modules_with_dependencies() {
    local requested_modules=("$@")
    local execution_order=()
    local processed_modules=()
    
    log_info "Resolving module dependencies for: ${requested_modules[*]}"
    
    # Function to add module and its dependencies to execution order
    add_module_to_order() {
        local module="$1"
        
        # Skip if already processed
        for processed in "${processed_modules[@]}"; do
            if [ "$processed" = "$module" ]; then
                return 0
            fi
        done
        
        # Check if module should be skipped based on configuration
        if should_skip_module "$module"; then
            log_skip "Skipping module '$module' (disabled by configuration)"
            processed_modules+=("$module")
            return 0
        fi
        
        # Add dependencies first
        local dependencies=$(get_module_dependencies "$module")
        for dep in $dependencies; do
            add_module_to_order "$dep"
        done
        
        # Add the module itself
        execution_order+=("$module")
        processed_modules+=("$module")
    }
    
    # Build execution order
    for module in "${requested_modules[@]}"; do
        add_module_to_order "$module"
    done
    
    log_info "Final execution order: ${execution_order[*]}"
    
    # Execute modules in order
    execute_modules "${execution_order[@]}"
}

# Check if a module should be skipped based on configuration
should_skip_module() {
    local module_name="$1"
    
    case "$module_name" in
        "docker-install")
            [ "${INSTALL_DOCKER:-true}" != "true" ]
            ;;
        "languages/golang-install")
            [ "${INSTALL_GO:-true}" != "true" ]
            ;;
        "languages/python-install")
            [ "${INSTALL_PYTHON:-true}" != "true" ]
            ;;
        "languages/dotnet-install")
            [ "${INSTALL_DOTNET:-true}" != "true" ]
            ;;
        "languages/jvm-kotlin-install")
            [ "${INSTALL_JVM:-true}" != "true" ] && [ "${INSTALL_KOTLIN:-true}" != "true" ]
            ;;
        "desktop-components")
            [ "${INSTALL_DESKTOP:-auto}" != "true" ]
            ;;
        *)
            # Core modules (system-detection, terminal-config) are never skipped
            false
            ;;
    esac
}

# ============================================================================
# Desktop Environment Detection Helper
# ============================================================================

# Check if desktop environment is detected (placeholder - should be implemented in system-detection module)
is_desktop_environment_detected() {
    # This is a placeholder - in the real implementation, this would check
    # the results from the system-detection module
    [ -n "${DISPLAY:-}" ] || [ -n "${XDG_CURRENT_DESKTOP:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]
}