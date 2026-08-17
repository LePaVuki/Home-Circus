#!/usr/bin/env bash
# launch_containers.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"

launch_containers() {
    log_info "Starting Docker Compose services..."
    
    docker compose up -d
    
    log_success "Docker Compose services successfully started!"
}

main() {
    launch_containers
}

main