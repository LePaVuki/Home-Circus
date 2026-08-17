#!/usr/bin/env bash
# stop.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"
source "$UTILS_DIR/execute.sh"

main() {
    log_info "Stopping docker stack..."
    run_task_script "$TASKS_DIR/stop_containers.sh"
    log_success "Docker stack stopped!"
}

main