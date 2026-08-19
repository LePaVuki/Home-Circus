#!/usr/bin/env bash
# check_prerequisites.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"
source "$UTILS_DIR/env.sh"

check_prerequisites() {
    log_info "Checking system requirements..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed."
        exit 1
    fi

    log_success "Docker is installed. Checking Docker Compose..."

    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose is not installed."
        exit 1
    fi

    log_success "Docker Compose is installed. Checking for .env file..."
    log_debug "Looking for .env file at: $ENV_FILE"
    verify_env_file
    log_success ".env file is present"

    log_success "Prerequisites satisfied."
}

main() {
    check_prerequisites
}

main