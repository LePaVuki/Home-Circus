#!/usr/bin/env bash
# start.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"
source "$UTILS_DIR/execute.sh"

main() {
    log_info "Starting docker stack..."
    run_task_script "$TASKS_DIR/check_prerequisites.sh"
    run_task_script "$TASKS_DIR/start_docker.sh"
    run_task_script "$TASKS_DIR/launch_containers.sh"
    log_success "Docker stack launched!"
}

main