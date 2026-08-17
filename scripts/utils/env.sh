#!/usr/bin/env bash
# env.sh

# Ensure this file is only sourced, never executed directly
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed directly." >&2
    exit 1
fi

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
        export "$key"="$value"
        variables_loaded=$((variables_loaded + 1))
        log_debug "Exported: $key=$value"
        else
            log_warning "Malformed line in .env file: '$line'. Skipping."
        fi
    done < .env

    if [ $variables_loaded -eq 0 ]; then
        log_warning "No valid environment variables were found in $ENV_FILE."
    else
        log_success "$variables_loaded environment variables loaded successfully."
    fi
}