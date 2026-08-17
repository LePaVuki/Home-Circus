#!/usr/bin/env bash
# initialise.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"
source "$UTILS_DIR/execute.sh"

main() {
    log_info "Starting initialisation of the project..."
    run_task_script "$TASKS_DIR/check_prerequisites.sh"
    run_task_script "$TASKS_DIR/generate_secrets.sh"
    run_task_script "$TASKS_DIR/generate_default_user.sh"
    log_success "Initialisation completed successfully!"
}

main