#!/usr/bin/env bash
# start_docker.sh

set -euo pipefail

source "$UTILS_DIR/logging.sh"

# Function to check if Docker daemon is running
is_docker_running() {
    log_debug "Checking if Docker deamon is already running"
    docker info > /dev/null 2>&1
}

# Function to start Docker daemon
start_docker() {
    if is_docker_running; then
        log_info "Docker daemon already running."
        exit 0
    fi

    log_info "Starting Docker daemon..."

    # Detect the operating system
    OS_TYPE="$(uname -s)"
    log_debug "Detected operating system: ${OS_TYPE}"

    case "${OS_TYPE}" in
        Linux*)
            log_info "Linux environment detected, starting deamon"
            # Check if systemd is available, otherwise use service
            if pidof systemd > /dev/null; then
                log_debug "Using systemd to start Docker."
                sudo systemctl start docker
            else
                log_debug "Using service to start Docker."
                sudo service docker start
            fi
            ;;
        
        CYGWIN*|MINGW*|MSYS*)
            # Windows environments (Git Bash, MSYS2, Cygwin)
            log_info "Windows environment detected. Launching Docker Desktop..."
            "/c/Program Files/Docker/Docker/Docker Desktop.exe" &
            ;;
        
        *)
            log_error "Unsupported Operating System: ${OS_TYPE}"
            exit 1
            ;;
    esac

}

main() {
    start_docker
}

main