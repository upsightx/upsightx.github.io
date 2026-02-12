#!/bin/bash
#
# results.sh - View results of a completed task
#
# Usage: ./results.sh <task-id> [--format json|markdown]
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$SKILL_DIR/memory"
RESULTS_DIR="$MEMORY_DIR/results"

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
log_success()() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
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

# Display results in markdown format
display_markdown() {
    local task_id="$1"
    local task_json="$2"
    local aggregated_results="$3"

    local status=$(echo "$task_json" | jq -r '.status // "unknown"')
    local description=$(echo "$task_json" | jq -r '.description // "No description"')
    local created_at=$(echo "$task_json" | jq -r '.metadata.createdAt // .createdAt // ""')
    local started_at=$(echo "$task_json" | jq -r '.metadata.startedAt // ""')
    local completed_at=$(echo "$task_json" | jq -r '.metadata.completedAt // ""')

    # Calculate duration
    local duration=""
    if [ -n "$started_at" ] && [ "$started_at" != "null" ]; then
        local start_epoch=$(date -d "$started_at" +%s 2>/dev/null || echo "0")
        if [ -n "$completed_at" ] && [ "$completed_at" != "null" ]; then
            local end_epoch=$(date -d "$completed_at" +%s 2>/dev/null || echo "0")
            duration=$((end_epoch - start_epoch))
        else
            local current_epoch=$(date +%s)
            duration=$((current_epoch - start_epoch))
        fi
        duration=" ($(format_duration $duration))"
    fi

    # Header
    echo "# Task Results: $task_id"
    echo ""
    echo "**Description:** $description"
    echo "**Status:** \`$status\`"
    echo "**Created:** $created_at"
    if [ -n "$started_at" ] && [ "$started_at" != "null" ]; then
        echo "**Started:** $started_at"
    fi
    if [ -n "$completed_at" ] && [ "$completed_at" != "null" ]; then
        echo "**Completed:** $completed_at"
    fi
    if [ -n "$duration" ]; then
        echo "**Duration:**$duration"
    fi
    echo ""

    # Subtask results
    local subtasks=$(echo "$task_json" | jq -c '.subtasks // []')
    local subtask_count=$(echo "$subtasks" | jq 'length')

    if [ $subtask_count -gt 0 ]; then
        echo "## Subtask Results"
        echo ""

        # Table header
        echo "| Subtask | Status | Description | Result |"
        echo "|---------|--------|-------------|--------|"

        echo "$subtasks" | jq -c '.' | while read -r subtask; do
            local st_id=$(echo "$subtask" | jq -r '.id')
            local st_status=$(echo "$subtask" | jq -r '.status')
            local st_desc=$(echo "$subtask" | jq -r '.description' | sed 's/|/\\|/g')
            local st_result=$(echo "$subtask" | jq -r '.result // empty')

            # Truncate result for table
            if [ ${#st_result} -gt 50 ]; then
                st_result="${st_result:0:50}..."
            fi
            st_result=$(echo "$st_result" | sed 's/|/\\|/g')

            # Status emoji
            local status_emoji=""
            case "$st_status" in
                completed) status_emoji="✅" ;;
                running) status_emoji="🔄" ;;
                failed) status_emoji="❌" ;;
                pending) status_emoji="⏳" ;;
            esac

            echo "| \`$st_id\` | $status_emoji \`$st_status\` | $st_desc | $st_result |"
        done
        echo ""
    fi

    # Aggregated results
    if [ -n "$aggregated_results" ] && [ "$aggregated_results" != "null" ]; then
        echo "## Aggregated Results"
        echo ""

        # Format aggregated results
        local agg_summary=$(echo "$aggregated_results" | jq -r '.subtaskResults | length' 2>/dev/null || echo "0")
        echo "**Total subtasks:** $agg_summary"
        echo ""

        # Show detailed results if available
        local results=$(echo "$aggregated_results" | jq -c '.subtaskResults[]' 2>/dev/null)
        if [ -n "$results" ]; then
            echo "### Detailed Results"
            echo ""

            local index=1
            echo "$results" | while read -r result; do
                local st_id=$(echo "$result" | jq -r '.subtaskId // empty')
                local st_result=$(echo "$result" | jq -r '.result // empty')
                local st_error=$(echo "$result" | jq -r '.error // empty')

                if [ -n "$st_id" ]; then
                    echo "#### $st_id"
                    if [ -n "$st_result" ]; then
                        echo ""
                        echo "**Result:**"
                        echo "\`\`\`"
                        echo "$st_result"
                        echo "\`\`\`"
                    fi
                    if [ -n "$st_error" ]; then
                        echo ""
                        echo "**Error:**"
                        echo "\`\`\`"
                        echo "$st_error"
                        echo "\`\`\`"
                    fi
                    echo ""
                fi
                index=$((index + 1))
            done
        fi
    fi

    # Errors and warnings
    echo "## Errors and Warnings"
    echo ""

    local error_count=0
    echo "$subtasks" | jq -c '.[] | select(.status == "failed")' | while read -r failed_subtask; do
        local st_id=$(echo "$failed_subtask" | jq -r '.id')
        local st_desc=$(echo "$failed_subtask" | jq -r '.description')
        local st_error=$(echo "$failed_subtask" | jq -r '.error // "No error details"')

        echo "### ❌ $st_id"
        echo "**Description:** $st_desc"
        echo "**Error:**"
        echo "\`\`\`"
        echo "$st_error"
        echo "\`\`\`"
        echo ""

        error_count=$((error_count + 1))
    done

    if [ $error_count -eq 0 ]; then
        echo "No errors. All subtasks completed successfully. ✅"
    fi
}

# Display results in JSON format
display_json() {
    local task_id="$1"
    local task_json="$2"
    local aggregated_results="$3"

    # Combine task and results
    echo "$task_json" | jq --argjson aggregated "$aggregated_results" \
        '. + {aggregatedResults: $aggregated}'
}

# Display results in plain text format
display_text() {
    local task_id="$1"
    local task_json="$2"
    local aggregated_results="$3"

    local status=$(echo "$task_json" | jq -r '.status // "unknown"')
    local description=$(echo "$task_json" | jq -r '.description // "No description"')
    local created_at=$(echo "$task_json" | jq -r '.metadata.createdAt // .createdAt // ""')
    local started_at=$(echo "$task_json" | jq -r '.metadata.startedAt // ""')
    local completed_at=$(echo "$task_json" | jq -r '.metadata.completedAt // ""')

    echo "========================================"
    echo "Task Results: $task_id"
    echo "========================================"
    echo "Description: $description"
    echo "Status: $status"
    echo "Created: $created_at"
    if [ -n "$started_at" ] && [ "$started_at" != "null" ]; then
        echo "Started: $started_at"
    fi
    if [ -n "$completed_at" ] && [ "$completed_at" != "null" ]; then
        echo "Completed: $completed_at"
    fi
    echo "========================================"
    echo ""

    # Subtasks
    local subtasks=$(echo "$task_json" | jq -c '.subtasks // []')
    local subtask_count=$(echo "$subtasks" | jq 'length')

    echo "Subtasks ($subtask_count total):"
    echo ""

    echo "$subtasks" | jq -c '.' | while read -r subtask; do
        local st_id=$(echo "$subtask" | jq -r '.id')
        local st_status=$(echo "$subtask" | jq -r '.status')
        local st_desc=$(echo "$subtask" | jq -r '.description')

        case "$st_status" in
            completed) echo "  [✓] $st_id: $st_desc" ;;
            running) echo "  [→] $st_id: $st_desc" ;;
            failed) echo "  [✗] $st_id: $st_desc" ;;
            *) echo "  [ ] $st_id: $st_desc" ;;
        esac
    done

    echo ""
    echo "========================================"
}

# Main execution
main() {
    local task_id=""
    local format="text"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                format="$2"
                shift 2
                ;;
            *)
                task_id="$1"
                shift
                ;;
        esac
    done

    # Validate input
    if [ -z "$task_id" ]; then
        log_error "Task ID is required"
        echo "Usage: $0 <task-id> [--format json|markdown|text]"
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

    # Load aggregated results
    local aggregated_results="null"
    local aggregated_file="$RESULTS_DIR/$task_id/aggregated.json"
    if [ -f "$aggregated_file" ]; then
        aggregated_results=$(cat "$aggregated_file")
    fi

    # Display results based on format
    case "$format" in
        json)
            display_json "$task_id" "$task_json" "$aggregated_results"
            ;;
        markdown)
            display_markdown "$task_id" "$task_json" "$aggregated_results"
            ;;
        text|*)
            display_text "$task_id" "$task_json" "$aggregated_results"
            ;;
    esac
}

# Run main function
main "$@"
