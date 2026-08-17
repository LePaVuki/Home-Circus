#!/usr/bin/env bash
# generate_secrets.sh

set -euo pipefail

readonly AUTHELIA_SECRETS_DIR="$ROOT_DIR/services/authelia/secrets"
readonly AUTHELIA_SECRET_FILES=(jwt_secret session_secret storage_encryption_key)

source "$UTILS_DIR/logging.sh"

generate_secrets() {
    log_info "Generating cryptographic keys..."
    log_debug "Secrets directory: $AUTHELIA_SECRETS_DIR"
    
    # Ensure secrets directory exists
    if ! [ -d "$AUTHELIA_SECRETS_DIR" ]; then
        log_warning "Secrets directory does not exist. Creating: $AUTHELIA_SECRETS_DIR"
        mkdir -p "$AUTHELIA_SECRETS_DIR" || { log_error "Failed to create secrets directory: $AUTHELIA_SECRETS_DIR"; exit 1; }
        log_success "Created secrets directory: $AUTHELIA_SECRETS_DIR"
    fi

    log_debug "Files to generate: ${AUTHELIA_SECRET_FILES[*]}"
    for f in "${AUTHELIA_SECRET_FILES[@]}"; do
        path="$AUTHELIA_SECRETS_DIR/$f"

        if [ -f "$path" ]; then
            log_skip "$path already exists — not overwriting"
            continue
        fi

        log_info "Generating secret: $path"
        if openssl rand -hex 64 > "$path"; then
            # Restrict permissions so only the owner can read/write
            chmod 600 "$path" || {  log_error "Failed to set permissions for $path"; exit 1; }
            log_success "$path created"
        else
            log_error "Failed to generate secret for $path"
            exit 1
        fi
    done

    log_success "All secrets generated successfully."
}

main() {
    generate_secrets
}

main