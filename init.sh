#!/usr/bin/env bash

# ==============================================================================
# 1. FAIL-SAFE SETTINGS
# ==============================================================================
set -euo pipefail
# -e: Exit immediately if any command returns a non-zero status
# -u: Treat unset variables as an error and exit immediately
# -o pipefail: Prevents errors in a pipeline from being masked


# ==============================================================================
# 2. GLOBAL CONFIGURATION & CONSTANTS
# ==============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SECRETS_DIR="$SCRIPT_DIR/services/authelia/secrets"
readonly CONFIG_DIR="$SCRIPT_DIR/services/authelia/config"
readonly DATA_DIR="$SCRIPT_DIR/data/authelia"
readonly ENV_FILE="$SCRIPT_DIR/.env"
readonly FILES=(jwt_secret session_secret storage_encryption_key)


# ==============================================================================
# 3. HELPER FUNCTIONS
# ==============================================================================
log_info() {
    # \033[1;34m = Bold Blue
    echo -e "\n[\033[1;34mINFO\033[0m] $1"
}

log_success() {
    # \033[1;32m = Bold Green
    echo -e "[\033[1;32mSUCCESS\033[0m] $1"
}

log_skip() {
    # \033[1;33m = Bold Yellow
    echo -e "[\033[1;33mSKIP\033[0m] $1"
}

log_error() {
    # \033[1;31m = Bold Red
    # >&2 redirects the error message to standard error (stderr) instead of stdout
    echo -e "\n[\033[1;31mERROR\033[0m] $1" >&2
}


# ==============================================================================
# 4. DEPLOYMENT STEPS
# ==============================================================================
check_prerequisites() {
    log_info "Checking system requirements..."

    if ! command -v docker &> /dev/null; then
        log_error "Error: Docker is not installed."
        exit 1
    fi

    log_success "Docker is installed. Checking Docker Compose..."

    if ! command -v docker compose &> /dev/null; then
        log_error "Error: Docker Compose is not installed."
        exit 1
    fi

    log_success "Docker Compose is installed. Checking for .env file..."

    if [ ! -f "$ENV_FILE" ]; then
        log_success "$ENV_FILE not found. Creating a new one..."
        touch "$ENV_FILE" || { log_error "Failed to create $ENV_FILE"; exit 1; }
    fi

    log_success ".env file is present"

    log_success "Prerequisites satisfied."
}


generate_secrets() {
    log_info "Generating cryptographic keys..."
    
    # ensure secrets directory exists
    if ! [ -d "$SECRETS_DIR" ]; then
        log_info "Secrets directory does not exist. Creating: $SECRETS_DIR"
        mkdir -p "$SECRETS_DIR" || { log_error "Failed to create secrets directory: $SECRETS_DIR"; exit 1; }
        log_success "Created secrets directory: $SECRETS_DIR"
    fi

    for f in "${FILES[@]}"; do
        path="$SECRETS_DIR/$f"

        if [ -f "$path" ]; then
            log_skip "$path already exists — not overwriting"
            continue
        fi

        log_info "Generating secret: $path"
        if openssl rand -hex 64 > "$path"; then
            # restrict permissions so only the owner can read/write
            chmod 600 "$path" || {  log_error "Failed to set permissions for $path"; exit 1; }
            log_success "$path created"
        else
            log_error "Failed to generate secret for $path"
            exit 1
        fi
    done
}

generate_default_user() {
    log_info "Generating default user for Authelia..."
    
    # Check if the default user already exists
    if [ -f "$DATA_DIR/users_database.yml" ]; then
        log_skip "Default user already exists — not overwriting"
        return
    fi

    log_info "Creating default user with username 'admin' and a generated password..."
    if (docker run --rm -it -v $CONFIG_DIR/configuration.yml:/configuration.yml authelia/authelia:latest authelia crypto hash generate --config /configuration.yml); then
    
    log_success "Default user created with username 'admin' and a generated password. Credentials saved in $SECRETS_DIR/default_user.txt"
}

launch_containers() {
    log_info "Starting Docker Compose services..."
    
    docker compose up -d
    
    log_success "Application deployed successfully!"
}


# ==============================================================================
# 5. ORCHESTRATION / EXECUTION ENGINE
# ==============================================================================
main() {
    log_info "=== Starting Automated Docker Deployment ==="
    
    check_prerequisites
    generate_secrets
    launch_containers
    
    log_success "=== Deployment Finished Successfully ==="
}

# Fire the main function with all arguments passed to the script
main "$@"
