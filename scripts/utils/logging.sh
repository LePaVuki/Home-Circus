#!/bin/bash
# utils/logging.sh

# Ensure this file is only sourced, never executed directly
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed directly." >&2
    exit 1
fi

# Terminal colors
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
ORANGE='\033[1;38;5;214m'
NC='\033[0m' # No Color

log_info() {
    echo -e "[${BLUE}INFO${NC}] $1"
}

log_success() {
    echo -e "[${GREEN}SUCCESS${NC}] $1"
}

log_skip() {
    echo -e "[${YELLOW}SKIP${NC}] $1"
}

log_error() {
    # >&2 redirects the error message to standard error (stderr) instead of stdout
    echo -e "[${RED}ERROR${NC}] $1" >&2
}

log_warning() {
    echo -e "[${ORANGE}WARNING${NC}] $1"
}

log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        echo -e "[${CYAN}DEBUG${NC}] $1"
    fi
}