#!/bin/bash

# Centralized Logging Utility for Env Prepare System
# Provides standardized logging with timestamps, colors, and module identification

# Color codes for different log levels
readonly COLOR_INFO='\033[0;32m'    # Green
readonly COLOR_WARN='\033[0;33m'    # Yellow
readonly COLOR_DEBUG='\033[0;34m'   # Blue
readonly COLOR_ERROR='\033[0;31m'   # Red
readonly COLOR_RESET='\033[0m'      # Reset

# Timer storage for module execution timing
declare -A MODULE_START_TIMES

# Generate timestamp in ISO format [YYYY-MM-DD HH:MM:SS]
get_timestamp() {
    date '+[%Y-%m-%d %H:%M:%S]'
}

# Log function with color coding and standardized format
# Usage: log_with_level "LEVEL" "COLOR" "module_name" "message"
log_with_level() {
    local level="$1"
    local color="$2"
    local module="$3"
    local message="$4"
    
    local timestamp
    timestamp=$(get_timestamp)
    
    printf "${color}%s [%s] [%s] %s${COLOR_RESET}\n" \
        "$timestamp" "$module" "$level" "$message"
}

# Individual logging functions
log_info() {
    log_with_level "INFO" "$COLOR_INFO" "$1" "$2"
}

log_warn() {
    log_with_level "WARN" "$COLOR_WARN" "$1" "$2"
}

log_debug() {
    log_with_level "DEBUG" "$COLOR_DEBUG" "$1" "$2"
}

log_error() {
    log_with_level "ERROR" "$COLOR_ERROR" "$1" "$2"
}

# Timer functions for module execution timing
start_timer() {
    local module="$1"
    MODULE_START_TIMES["$module"]=$(date +%s)
    log_info "$module" "Installing..."
}

end_timer() {
    local module="$1"
    local start_time="${MODULE_START_TIMES[$module]:-}"
    
    if [[ -n "$start_time" ]]; then
        local end_time
        end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        log_info "$module" "Successful in $elapsed seconds!"
        unset MODULE_START_TIMES["$module"]
    else
        log_warn "$module" "Timer was not started for this module"
    fi
}

# Get elapsed time for a module (without ending the timer)
get_elapsed_time() {
    local module="$1"
    local start_time="${MODULE_START_TIMES[$module]:-}"
    
    if [[ -n "$start_time" ]]; then
        local current_time
        current_time=$(date +%s)
        echo $((current_time - start_time))
    else
        echo "0"
    fi
}

# Error handling function
handle_error() {
    local module="$1"
    local error_message="$2"
    local exit_code="${3:-1}"
    
    log_error "$module" "$error_message"
    return "$exit_code"
}