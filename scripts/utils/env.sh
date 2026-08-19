#!/usr/bin/env bash
# env.sh

# Ensure this file is only sourced, never executed directly
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed directly." >&2
    exit 1
fi

validate_env() {
    log_info "Validating required environment variables..."
    local required_vars=("ROOT_DOMAIN" "ADMIN_USERNAME" "ADMIN_PASSWORD" "ADMIN_EMAIL")
    local missing_vars=""
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var+x}" ]; then
            missing_vars="${missing_vars} ${var}"
        fi
    done
    
    if [ -n "$missing_vars" ]; then
        log_error "Missing required environment variables: $missing_vars"
        exit 1
    else
        log_success "All required environment variables are present"
    fi
}

verify_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file not found at $ENV_FILE"
        echo "Please create a .env file based on the example in .env.example" >&2
        exit 1
    fi
}

trap 'log_error "Script interrupted or failed. Environment variables may be incomplete."' SIGINT SIGTERM

load_env() {
    log_info "Loading environment variables from $ENV_FILE..."
    variables_loaded=0
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Error: $ENV_FILE not found."
        exit 1
    fi
    # Read file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Clean up carriage returns (\r) immediately for cross-platform safety
        line=$(echo "$line" | tr -d '\r')
        
        # Skip comments (#), completely empty lines, or lines with only spaces/tabs
        case "$line" in
            \#* | "" | [[:space:]]*) continue ;;
        esac
        
        # 3. Parse the key and value
        key=$(echo "$line" | cut -d '=' -f 1)
        value=$(echo "$line" | cut -d '=' -f 2-)
        
        # 4. Double check that the key actually contains text before exporting
        if [ -n "$key" ]; then
        export readonly "$key"="$value"
        variables_loaded=$((variables_loaded + 1))
        log_debug "Exported environment variable: $key"
        else
            log_warning "Malformed line in .env file: '$line'. Skipping."
        fi
    done < "$ENV_FILE"
    
    if [ $variables_loaded -eq 0 ]; then
        log_warning "No valid environment variables were found in $ENV_FILE."
    else
        log_success "$variables_loaded environment variables loaded successfully."
    fi
}
