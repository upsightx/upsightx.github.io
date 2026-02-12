#!/bin/bash
#
# monitor.sh - Monitor active agent-teams tasks
#
# Usage: ./monitor.sh [--follow]
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

# Format duration
format_duration() {
    local seconds=$1
    if [ $seconds -lt 60 ]; then
        echo "${seconds}s"
    elif [ $seconds -lt 3600 ]; then
        local min=$((seconds / 60))
        local sec=$((seconds % 60))
        echo "${min}m ${sec}s"
    else
        local hour=$((seconds / 3600))
        local min=$(((seconds % 3600) / 60))
        echo "${hour}h ${min}m"
    fi
}

# Clear screen
clear_screen() {
    clear
    echo -e "${CYAN}OpenClaw Agent Teams - Task Monitor${NC}"
    echo "Last update: $(timestamp)"
    echo ""
}

# Display task status
display_task() {
    local task_id="$1"
    local task_json="$2"

    local status=$(echo "$task_json" | jq -r '.status // "unknown"')
    local description=$(echo "$task_json" | jq -r '.description // "No description"')
    local created_at=$(echo "$task_json" | jq -r '.metadata.createdAt // .createdAt // ""')
    local started_at=$(echo "$task_json" | jq -r '.metadata.startedAt // ""')

    # Truncate description
    if [ ${#description} -gt 60 ]; then
        description="${description:0:60}..."
    fi

    # Status color
    local status_color
    case "$status" in
        running)
            status_color=$YELLOW
            ;;
        completed)
            status_color=$GREEN
            ;;
        failed)
            status_color=$RED
            ;;
        *)
            status_color=$BLUE
            ;;
    esac

    echo -e "${CYAN}Task:${NC} $task_id"
    echo -e "  ${CYAN}Description:${NC} $description"
    echo -e "  ${CYAN}Status:${NC} ${status_color}${status}${NC}"
    echo -e "  ${CYAN}Created:${NC} $created_at"

    # Calculate duration
    if [ -n "$started_at" ] && [ "$started_at" != "null" ]; then
        local start_epoch=$(date -d "$started_at" +%s 2>/dev/null || echo "0")
        local current_epoch=$(date +%s)
        local elapsed=$((current_epoch - start_epoch))
        echo -e "  ${CYAN}Elapsed Time:${NC} $(format_duration $elapsed)"
    fi

    # Display subtasks
    local subtasks=$(echo "$task_json" | jq -c '.subtasks // []')
    local subtask_count=$(echo "$subtasks" | jq 'length')

    if [ $subtask_count -gt 0 ]; then
        echo -e "  ${CYAN}Subtasks:${NC}"

        # Count by status
        local completed=$(echo "$subtasks" | jq '[.[] | select(.status == "completed")] | length')
        local running=$(echo "$subtasks" | jq '[.[] | select(.status == "running")] | length')
        local failed=$(echo "$subtasks" | jq '[.[] | select(.status == "failed")] | length')
        local pending=$(echo "$subtasks" | jq '[.[] | select(.status == "pending")] | length')

        # Progress bar
        local total=$subtask_count
        local progress=$((completed * 50 / total))
        local bar=""
        for ((i=0; i<50; i++)); do
            if [ $i -lt $progress ]; then
                bar="${bar}█"
            else
                bar="${bar}░"
            fi
        done

        echo -e "    ${bar} ${completed}/${total} completed"

        # Status breakdown
        if [ $running -gt 0 ]; then
            echo -e "      ${YELLOW}● Running:${NC} $running"
        fi
        if [ $completed -gt 0 ]; then
            echo -e "      ${GREEN}● Completed:${NC} $completed"
        fi
        if [ $pending -gt 0 ]; then
            echo -e "      ${BLUE}● Pending:${NC} $pending"
        fi
        if [ $failed -gt 0 ]; then
            echo -e "      ${RED}● Failed:${NC} $failed"
        fi

        # Show individual subtasks (running first, then others)
        echo "    Details:"
        echo "$subtasks" | jq -c '.[]' | sort | while read -r subtask; do
            local st_id=$(echo "$subtask" | jq -r '.id')
            local st_status=$(echo "$subtask" | jq -r '.status')
            local st_desc=$(echo "$subtask" | jq -r '.description' | cut -c1-50)

            case "$st_status" in
                running)
                    echo -e "      ${YELLOW}▶${NC} $st_id: $st_desc"
                    ;;
                completed)
                    echo -e "      ${GREEN}✓${NC} $st_id: $st_desc"
                    ;;
                failed)
                    echo -e "      ${RED}✗${NC} $st_id: $st_desc"
                    ;;
                pending)
                    echo -e "      ${BLUE}○${NC} $st_id: $st_desc"
                    ;;
            esac
        done
    fi

    echo ""
}

# Display summary
display_summary() {
    local tasks="$1"

    local total=$(echo "$tasks" | jq 'length')
    local running=$(echo "$tasks" | jq '[.[] | select(.status == "running")] | length')
    local completed=$(echo "$tasks" | jq '[.[] | select(.status == "completed")] | length')
    local failed=$(echo "$tasks" | jq '[.[] | select(.status == "failed")] | length')
    local pending=$(echo "$tasks" | jq '[.[] | select(.status == "pending")] | length')

    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Total Tasks:     $total"
    echo -e "${GREEN}Completed:${NC}       $completed"
    echo -e "${YELLOW}Running:${NC}         $running"
    echo -e "${BLUE}Pending:${NC}         $pending"
    echo -e "${RED}Failed:${NC}          $failed"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Monitor mode (follow)
monitor_mode() {
    local interval=5

    if [ "$1" = "--follow" ]; then
        log_info "Monitoring mode - refreshing every ${interval}s (Ctrl+C to exit)"
        echo ""
    fi

    while true; do
        clear_screen

        # Check if tasks file exists
        if [ ! -f "$TASKS_FILE" ]; then
            log_warning "No tasks file found. Run run.sh to create tasks."
            break
        fi

        # Load all tasks
        local tasks=$(jq -c '.tasks | values' "$TASKS_FILE" 2>/dev/null || echo "[]")

        # Check if tasks exist
        if [ "$tasks" = "[]" ]; then
            log_warning "No tasks found. Run run.sh to create tasks."
            break
        fi

        # Display each task
        echo "$tasks" | jq -c '.' | while read -r task_json; do
            local task_id=$(echo "$task_json" | jq -r '.id')
            display_task "$task_id" "$task_json"
        done

        # Display summary
        display_summary "$tasks"

        # Exit if not following
        if [ "$1" != "--follow" ]; then
            break
        fi

        # Wait for interval
        sleep $interval
    done
}

# Single-shot mode
single_mode() {
    clear_screen

    # Check if tasks file exists
    if [ ! -f "$TASKS_FILE" ]; then
        log_warning "No tasks file found. Run run.sh to create tasks."
        return
    fi

    # Load all tasks
    local tasks=$(jq -c '.tasks | values' "$TASKS_FILE" 2>/dev/null || echo "[]")

    # Check if tasks exist
    if [ "$tasks" = "[]" ]; then
        log_warning "No tasks found. Run run.sh to create tasks."
        return
    fi

    # Display each task
    echo "$tasks" | jq -c '.' | while read -r task_json; do
        local task_id=$(echo "$task_json" | jq -r '.id')
        display_task "$task_id" "$task_json"
    done

    # Display summary
    display_summary "$tasks"
}

# Main execution
main() {
    local mode="single"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --follow|-f)
                mode="follow"
                shift
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

    if [ "$mode" = "follow" ]; then
        monitor_mode "--follow"
    else
        single_mode
    fi
}

# Run main function
main "$@"
