#!/usr/bin/env bash
# generate_default_user.sh

set -euo pipefail

readonly AUTHELIA_CONFIG_DIR="$ROOT_DIR/services/authelia/config"
readonly AUTHELIA_DATA_DIR="$ROOT_DIR/data/authelia"

source "$UTILS_DIR/logging.sh"

generate_default_user() {
    log_info "Generating default user for Authelia..."
    log_debug "Data directory: $AUTHELIA_DATA_DIR"
    log_debug "Configuration directory: $AUTHELIA_CONFIG_DIR"

    # Check if the default user database file already exists
    if [ -f "$AUTHELIA_DATA_DIR/users.yml" ]; then
        log_skip "Default user database already exists at $AUTHELIA_DATA_DIR/users.yml — not overwriting"
        return
    fi
    # Check if the data directory exists
    if [ ! -d "$AUTHELIA_DATA_DIR" ]; then
        log_info "Data directory does not exist. Creating: $AUTHELIA_DATA_DIR"
        mkdir -p "$AUTHELIA_DATA_DIR" || { log_error "Failed to create data directory: $AUTHELIA_DATA_DIR"; exit 1; }
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

    log_info "Writing default user to $AUTHELIA_DATA_DIR/users.yml..."
    if touch "$AUTHELIA_DATA_DIR/users.yml"; then
        log_success "Created $AUTHELIA_DATA_DIR/users.yml"
    else
        log_error "Failed to create $AUTHELIA_DATA_DIR/users.yml"
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
    } >> "$AUTHELIA_DATA_DIR/users.yml" || { log_error "Failed to write default user to $AUTHELIA_DATA_DIR/users.yml"; exit 1; }
    log_success "Default user created successfully."
}

main() {
    generate_default_user
}

main