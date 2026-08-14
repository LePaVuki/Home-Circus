#!/bin/bash
# menu.sh

# ==============================================================================
# 1. GLOBAL CONFIGURATION & CONSTANTS
# ==============================================================================
readonly ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE}")" &> /dev/null && pwd)
readonly TASKS_DIR="$ROOT_DIR/tasks"
readonly UTILS_DIR="$ROOT_DIR/utils"
readonly DEBUG_MODE=false

# 1. SOURCE the infrastructure libraries (Loads them into memory)
if [ -f "$UTILS_DIR/logging.sh" ] && [ -f "$UTILS_DIR/execute.sh" ]; then
    source "$UTILS_DIR/logging.sh"
    source "$UTILS_DIR/execute.sh"
else
    echo "[ERROR] Missing core utilities in utils/ directory!" >&2
    exit 1
fi

# 2. Parse the command-line arguments
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

log_debug "DEBUG MODE ACTIVE!"

while true; do

    # 3. Read executable task files into a Bash array
    tasks=()
    while IFS= read -r -d '' file; do
        tasks+=("$file")
    done < <(find "$TASKS_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

    total_tasks=${#tasks[@]}
    log_debug "Found $total_tasks task(s) in $TASKS_DIR"

    # 4. Render the dynamic UI
    echo "================================="
    echo "       DYNAMIC CONTROL CLI       "
    echo "================================="
    
    if [ "$total_tasks" -eq 0 ]; then
        log_error "No tasks found in $TASKS_DIR"
    else
        for i in "${!tasks[@]}"; do
            display_name=$(basename "${tasks[$i]}" .sh)
            display_name=$(echo "$display_name" | tr '_-' ' ' | sed -e 's/\b\(.\)/\u\1/g')
            echo "$((i + 1))) Run $display_name"
        done
    fi
    
    echo "$((total_tasks + 1))) Exit"
    echo "================================="
    echo -n "Enter your choice [1-$((total_tasks + 1))]: "
    read -r choice

    # Validate if user wants to exit
    if [ "$choice" -eq "$((total_tasks + 1))" ] 2>/dev/null; then
        log_success "Exiting tool. Goodbye!"
        exit 0
    fi

    # 5. Route selection to the execute function
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_tasks" ]; then
        target_index=$((choice - 1))
        target_script="${tasks[$target_index]}"

        # CALL THE EXECUTOR FUNCTION (Hand over the script path)
        log_debug "User selected task: $target_script"
        log_info "Running task: $(basename "$target_script")"
        run_task_script "$target_script"
        
    else
        log_error "Invalid selection. Please choose a valid number."
    fi

    echo ""
    echo -n "Press [ENTER] to return to the menu..."
    read -r

    clear
done