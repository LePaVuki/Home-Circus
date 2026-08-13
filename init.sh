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
DEBUG_MODE=false
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SECRETS_DIR="$SCRIPT_DIR/services/authelia/secrets"
readonly CONFIG_DIR="$SCRIPT_DIR/services/authelia/config"
readonly DATA_DIR="$SCRIPT_DIR/data/authelia"
readonly ENV_FILE="$SCRIPT_DIR/.env"
readonly FILES=(jwt_secret session_secret storage_encryption_key)


# ==============================================================================
# 3. HELPER FUNCTIONS
# ==============================================================================
parse_args() {
    # Parse the command-line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--debug)
                DEBUG_MODE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

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

log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        # \033[1;36m = Bold Cyan
        echo -e "[\033[1;36mDEBUG\033[0m] $1"
    fi
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
    log_debug "Looking for .env file at: $ENV_FILE"

    if [ ! -f "$ENV_FILE" ]; then
        log_success "$ENV_FILE not found. Creating a new one..."
        touch "$ENV_FILE" || { log_error "Failed to create $ENV_FILE"; exit 1; }
    fi

    log_success ".env file is present"

    log_success "Prerequisites satisfied."
}

load_env_variables() {
    log_info "Loading environment variables from $ENV_FILE..."
    if [ -f "$ENV_FILE" ]; then
        set -o allexport
        source "$ENV_FILE"
        set +o allexport
        log_success "Environment variables loaded successfully."
    else
        log_error "Error: $ENV_FILE not found."
        exit 1
    fi
}

generate_secrets() {
    log_info "Generating cryptographic keys..."
    log_debug "Secrets directory: $SECRETS_DIR"
    
    # ensure secrets directory exists
    if ! [ -d "$SECRETS_DIR" ]; then
        log_info "Secrets directory does not exist. Creating: $SECRETS_DIR"
        mkdir -p "$SECRETS_DIR" || { log_error "Failed to create secrets directory: $SECRETS_DIR"; exit 1; }
        log_success "Created secrets directory: $SECRETS_DIR"
    fi

    log_debug "Files to generate: ${FILES[*]}"
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

    log_success "All secrets generated successfully."
}

generate_default_user() {
    log_info "Generating default user for Authelia..."
    log_debug "Data directory: $DATA_DIR"
    log_debug "Configuration directory: $CONFIG_DIR"

    # Check if the default user database file already exists
    if [ -f "$DATA_DIR/users.yml" ]; then
        log_skip "Default user database already exists at $DATA_DIR/users.yml — not overwriting"
        return
    fi
    # Check if the data directory exists
    if [ ! -d "$DATA_DIR" ]; then
        log_info "Data directory does not exist. Creating: $DATA_DIR"
        mkdir -p "$DATA_DIR" || { log_error "Failed to create data directory: $DATA_DIR"; exit 1; }
    fi

    log_info "Creating default user credentials..."
    ADMIN_HASH=$(docker run --rm -it \
        authelia/authelia:latest \
        authelia crypto hash generate \
        --password "$ADMIN_PASSWORD" \
        --no-confirm \
        | awk '/^Digest:/ {print $2}' \
        || { log_error "Failed to generate default user"; exit 1; } )

    log_info "Default user created with credentials:"
    log_success "Username: $ADMIN_USERNAME"
    log_success "Password: $ADMIN_PASSWORD"
    log_debug "Password Hash: $ADMIN_HASH"

    log_info "Writing default user to $DATA_DIR/users.yml..."
    if touch "$DATA_DIR/users.yml"; then
        log_success "Created $DATA_DIR/users.yml"
    else
        log_error "Failed to create $DATA_DIR/users.yml"
        exit 1
    fi

    {
        echo "users:"
        echo "  $ADMIN_USERNAME:"
        echo "    disabled: false"
        echo "    username: $ADMIN_USERNAME"
        echo "    password: \"$ADMIN_HASH\""
        echo "    displayname: \"$ADMIN_USERNAME\""
        echo "    email: \"$ADMIN_EMAIL\""
        echo "    groups:"
        echo "      - admin"
    } >> "$DATA_DIR/users.yml" || { log_error "Failed to write default user to $DATA_DIR/users.yml"; exit 1; }
    log_success "Default user created successfully."
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
    log_debug "Debug mode is ON"
    log_info "=== Starting Automated Docker Deployment ==="
    
    check_prerequisites
    load_env_variables
    generate_secrets
    generate_default_user
    launch_containers
    
    log_success "=== Deployment Finished Successfully ==="
}

# Fire the main function with all arguments passed to the script
parse_args "$@"
main
