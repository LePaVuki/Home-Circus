#!/bin/bash
# utils/execute.sh

# Safety guard to prevent direct execution
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed directly." >&2
    exit 1
fi

# central execution wrapper
# Usage: run_task_script "/path/to/script.sh" "arg1" "arg2"
run_task_script() {
    local target_path="$1"
    shift # Remove the path argument, leaving only target task flags/arguments
    
    local script_name
    script_name=$(basename "$target_path")

    # 1. Verification checks
    if [ ! -f "$target_path" ]; then
        log_error "Task file not found: $script_name"
        return 1
    fi

    log_debug "Executing task: $script_name..."

    # 2. ROBUST CROSS-PLATFORM EXECUTION
    # Try running directly if permissions allow; fallback to explicit bash interpreter for Windows
    if [ -x "$target_path" ]; then
        log_debug "Running $script_name directly (has execute permissions)."
        "$target_path" "$@"
        local exit_code=$?
    else
        # If execution permission is missing, passing it to 'bash' only requires read rights
        log_debug "Running $script_name via explicit bash interpreter."
        bash "$target_path" "$@"
        local exit_code=$?
    fi

    # 3. Standardized telemetry and output logging
    if [ $exit_code -eq 0 ]; then
        log_debug "$script_name completed successfully."
    else
        log_error "$script_name failed with exit code $exit_code."
    fi

    return $exit_code
}