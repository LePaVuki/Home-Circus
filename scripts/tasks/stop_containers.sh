#!/usr/bin/env bash
# stop_containers.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"

stop_containers() {
    log_info "Stopping Docker Compose services..."
    
    docker compose down
    
    log_success "Docker Compose services successfully stopped!"
}

main() {
    stop_containers
}

main