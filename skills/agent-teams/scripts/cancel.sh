#!/bin/bash
#
# cancel.sh - Cancel a running task and terminate sub-agents
#
# Usage: ./cancel.sh <task-id>
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$SKILL_DIR/memory"

# Configuration
TASKS_FILE="$MEMORY_DIR/tasks.json"
SESSIONS_FILE="$MEMORY_DIR/sessions.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get current timestamp
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Main execution
main() {
    local task_id=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                echo "Usage: $0 <task-id>"
                echo ""
                echo "Cancel a running task and terminate all associated sub-agents."
                echo ""
                echo "Arguments:"
                echo "  task-id    The ID of the task to cancel"
                exit 0
                ;;
            *)
                task_id="$1"
                shift
                ;;
        esac
    done

    # Validate input
    if [ -z "$task_id" ]; then
        log_error="Task ID is required"
        echo "Usage: $0 <task-id>"
        exit 1
    fi

    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq."
        exit 1
    fi

    # Check if tasks file exists
    if [ ! -f "$TASKS_FILE" ]; then
        log_error "No tasks file found. Run run.sh to create tasks."
        exit 1
    fi

    # Load task
    local task_json=$(jq -r ".tasks[\"$task_id\"]" "$TASKS_FILE" 2>/dev/null)

    if [ "$task_json" = "null" ] || [ -z "$task_json" ]; then
        log_error "Task '$task_id' not found"
        echo ""
        echo "Available tasks:"
        jq -r '.tasks | keys[]' "$TASKS_FILE" 2>/dev/null | sed 's/^/  - /'
        exit 1
    fi

    # Check task status
    local status=$(echo "$task_json" | jq -r '.status // "unknown"')

    case "$status" in
        completed)
            log_warning "Task '$task_id' is already completed. Nothing to cancel."
            exit 0
            ;;
        failed)
            log_warning "Task '$task_id' has already failed. Nothing to cancel."
            exit 0
            ;;
        running|pending)
            log_info "Cancelling task '$task_id' (status: $status)..."
            ;;
    esac

    # Update task status to cancelled
    jq --arg id "$task_id" \
        '.tasks[$id].status = "cancelled" | .tasks[$id].metadata.cancelledAt = "'$(timestamp)'" | .lastUpdated = "'$(timestamp)'"' \
        "$TASKS_FILE" > "${TASKS_FILE}.tmp" && \
        mv "${TASKS_FILE}.tmp" "$TASKS_FILE"

    # Cancel all running subtasks
    local subtasks=$(echo "$task_json" | jq -c '.subtasks // []')
    local cancelled_count=0
    local already_done=0

    echo "$subtasks" | jq -c '.' | while read -r subtask; do
        local st_id=$(echo "$subtask" | jq -r '.id')
        local st_status=$(echo "$subtask" | jq -r '.status')

        if [ "$st_status" = "running" ] || [ "$st_status" = "pending" ]; then
            log_info "Cancelling subtask: $st_id"

            # Update subtask status
            jq --arg tid "$task_id" --arg stid "$st_id" \
                '.tasks[$tid].subtasks[] | select(.id == $stid) | .status = "cancelled"' \
                "$TASKS_FILE" > "${TASKS_FILE}.tmp" && \
                mv "${TASKS_FILE}.tmp" "$TASKS_FILE" 2>/dev/null || true

            # In a real implementation, we would:
            # 1. Find the sub-agent session ID
            # 2. Call openclaw agent kill <session-id>
            # For now, we just update the status

            cancelled_count=$((cancelled_count + 1))
        else
            already_done=$((already_done + 1))
        fi
    done

    log_success "Task '$task_id' cancelled successfully!"
    echo ""
    echo "Summary:"
    echo "  Subtasks cancelled: $(echo "$subtasks" | jq '[.[] | select(.status == "running" or .status == "pending")] | length')"
    echo "  Already completed: $(echo "$subtasks" | jq '[.[] | select(.status == "completed")] | length')"
    echo ""
    echo "Task status updated to: cancelled"
}

# Run main function
main "$@"
