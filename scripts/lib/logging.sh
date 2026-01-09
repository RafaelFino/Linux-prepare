#!/usr/bin/env bash

# ============================================================================
# Logging Library for Linux-prepare Modular Architecture
# ============================================================================
# This library provides standardized logging functions for all modules
# Extracted from prepare.sh to ensure consistent formatting across modules

# ANSI Color Codes
BOLD="\033[1m"
RESET="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
GRAY="\033[90m"

# Symbols
SYMBOL_INFO="ℹ"
SYMBOL_SUCCESS="✓"
SYMBOL_ERROR="✗"
SYMBOL_WARNING="⚠"
SYMBOL_SKIP="⏭"

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${CYAN}[${timestamp}] ${SYMBOL_INFO}${RESET} ${msg}"
}

log_success() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${GREEN}[${timestamp}] ${SYMBOL_SUCCESS}${RESET} ${msg}"
}

log_error() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${RED}[${timestamp}] ${SYMBOL_ERROR}${RESET} ${msg}" >&2
}

log_warning() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${YELLOW}[${timestamp}] ${SYMBOL_WARNING}${RESET} ${msg}"
}

log_skip() {
    local msg="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BOLD}${GRAY}[${timestamp}] ${SYMBOL_SKIP}${RESET} ${msg}"
}

# ============================================================================
# Module-specific logging functions
# ============================================================================

# Log with module name prefix
log_module_info() {
    local module_name="$1"
    shift
    local msg="$*"
    log_info "[$module_name] $msg"
}

log_module_success() {
    local module_name="$1"
    shift
    local msg="$*"
    log_success "[$module_name] $msg"
}

log_module_error() {
    local module_name="$1"
    shift
    local msg="$*"
    log_error "[$module_name] $msg"
}

log_module_warning() {
    local module_name="$1"
    shift
    local msg="$*"
    log_warning "[$module_name] $msg"
}

log_module_skip() {
    local module_name="$1"
    shift
    local msg="$*"
    log_skip "[$module_name] $msg"
}