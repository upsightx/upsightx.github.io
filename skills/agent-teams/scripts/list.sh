#!/bin/bash
#
# list.sh - List all agent-teams tasks
#
# Usage: ./list.sh [--status all|pending|running|completed|failed]
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$SKILL_DIR/memory"

# Configuration
TASKS_FILE="$MEMORY_DIR/tasks.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Format date
format_date() {
    local date_str="$1"
    if [ -n "$date_str" ] && [ "$date_str" != "null" ]; then
        # Convert to local time and format
        date -d "$date_str" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$date_str"
    else
        echo "N/A"
    fi
}

# Main execution
main() {
    local status_filter="all"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --status|-s)
                status_filter="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--status all|pending|running|completed|failed]"
                echo ""
                echo "List all agent-teams tasks with optional status filtering."
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq."
        exit 1
    fi

    # Check if tasks file exists
    if [ ! -f "$TASKS_FILE" ]; then
        log_warning "No tasks file found. Run run.sh to create tasks."
        exit 0
    fi

    # Load all tasks
    local tasks=$(jq -c '.tasks | values' "$TASKS_FILE" 2>/dev/null || echo "[]")

    # Check if tasks exist
    if [ "$tasks" = "[]" ]; then
        log_warning "No tasks found. Run run.sh to create tasks."
        exit 0
    fi

    # Filter by status
    if [ "$status_filter" != "all" ]; then
        tasks=$(echo "$tasks" | jq "[.[] | select(.status == \"$status_filter\")]")
    fi

    # Get task count
    local total=$(echo "$tasks" | jq 'length')

    if [ $total -eq 0 ]; then
        if [ "$status_filter" = "all" ]; then
            log_warning "No tasks found."
        else
            log_warning "No tasks with status '$status_filter' found."
        fi
        exit 0
    fi

    # Display header
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Agent Teams Tasks${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # Display each task
    echo "$tasks" | jq -c '.' | while read -r task_json; do
        local task_id=$(echo "$task_json" | jq -r '.id')
        local status=$(echo "$task_json" | jq -r '.status // "unknown"')
        local description=$(echo "$task_json" | jq -r '.description // "No description"')
        local created_at=$(echo "$task_json" | jq -r '.metadata.createdAt // .createdAt // ""')
        local started_at=$(echo "$task_json" | jq -r '.metadata.startedAt // ""')
        local completed_at=$(echo "$task_json" | jq -r '.metadata.completedAt // ""')

        # Truncate description
        if [ ${#description} -gt 70 ]; then
            description="${description:0:70}..."
        fi

        # Status color and emoji
        local status_color
        local status_emoji
        case "$status" in
            running)
                status_color=$YELLOW
                status_emoji="🔄"
                ;;
            completed)
                status_color=$GREEN
                status_emoji="✅"
                ;;
            failed)
                status_color=$RED
                status_emoji="❌"
                ;;
            pending)
                status_color=$BLUE
                status_emoji="⏳"
                ;;
            *)
                status_color=$BLUE
                status_emoji="📋"
                ;;
        esac

        echo -e "${CYAN}Task ID:${NC}       $task_id"
        echo -e "${CYAN}Description:${NC}    $description"
        echo -e "${CYAN}Status:${NC}         ${status_color}${status_emoji} ${status}${NC}"
        echo -e "${CYAN}Created:${NC}        $(format_date "$created_at")"
        if [ -n "$started_at" ] && [ "$started_at" != "null" ]; then
            echo -e "${CYAN}Started:${NC}        $(format_date "$started_at")"
        fi
        if [ -n "$completed_at" ] && [ "$completed_at" != "null" ]; then
            echo -e "${CYAN}Completed:${NC}      $(format_date "$completed_at")"
        fi

        # Show subtask summary
        local subtasks=$(echo "$task_json" | jq -c '.subtasks // []')
        local subtask_count=$(echo "$subtasks" | jq 'length')

        if [ $subtask_count -gt 0 ]; then
            local completed=$(echo "$subtasks" | jq '[.[] | select(.status == "completed")] | length')
            local running=$(echo "$subtasks" | jq '[.[] | select(.status == "running")] | length')
            local failed=$(echo "$subtasks" | jq '[.[] | select(.status == "failed")] | length')
            echo -e "${CYAN}Subtasks:${NC}       $completed/$subtask_count completed (running: $running, failed: $failed)"
        fi

        echo ""
        echo -e "${CYAN}---${NC}"
        echo ""
    done

    # Display summary statistics
    if [ "$status_filter" = "all" ]; then
        local all_tasks=$(jq -c '.tasks | values' "$TASKS_FILE" 2>/dev/null || echo "[]")
        local all_count=$(echo "$all_tasks" | jq 'length')
        local completed_running=$(echo "$all_tasks" | jq '[.[] | select(.status == "completed" or .status == "running")] | length')
        local failed_count=$(echo "$all_tasks" | jq '[.[] | select(.status == "failed")] | length')

        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}Summary${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo "Total tasks:           $all_count"
        echo -e "Active (running):      $(echo "$all_tasks" | jq '[.[] | select(.status == "running")] | length')"
        echo -e "Completed:             $(echo "$all_tasks" | jq '[.[] | select(.status == "completed")] | length')"
        echo -e "Failed:                $failed_count"
        echo -e "${CYAN}========================================${NC}"
    else
        echo -e "${CYAN}========================================${NC}"
        echo "Tasks shown: $total (filter: $status_filter)"
        echo -e "${CYAN}========================================${NC}"
    fi
}

# Run main function
main "$@"
