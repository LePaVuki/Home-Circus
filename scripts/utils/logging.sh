#!/bin/bash
# utils/logging.sh

# Ensure this file is only sourced, never executed directly
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed directly." >&2
    exit 1
fi

# Terminal colors
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
BLUE=$'\033[1;34m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
ORANGE=$'\033[1;38;5;214m'
NC=$'\033[0m' # No Color

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S.%3N")
    echo "$timestamp | [$level] | $message"
}

log_info() {
    local type="${BLUE}INFO${NC}"
    log_message "$type" "$1"
}

log_success() {
    local type="${GREEN}SUCCESS${NC}"
    log_message "$type" "$1"
}

log_skip() {
    local type="${YELLOW}SKIP${NC}"
    log_message "$type" "$1"
}

log_error() {
    # >&2 redirects the error message to standard error (stderr) instead of stdout
    local type="${RED}ERROR${NC}"
    log_message "$type" "$1" >&2
}

log_warning() {
    local type="${ORANGE}WARNING${NC}"
    log_message "$type" "$1"
}

log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        local type="${CYAN}DEBUG${NC}"
        executor=$(basename $0)
        log_message "$type" "$executor | $1"
    fi
}