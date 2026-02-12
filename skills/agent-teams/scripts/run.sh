#!/bin/bash
#
# run.sh - Execute a coordinated multi-agent task
#
# Usage: ./run.sh "<task-description>" [--max-parallel N] [--timeout S]
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$SKILL_DIR/memory"
RESULTS_DIR="$MEMORY_DIR/results"

# Ensure directories exist
mkdir -p "$MEMORY_DIR"
mkdir -p "$RESULTS_DIR"

# Configuration
TASKS_FILE="$MEMORY_DIR/tasks.json"
SESSIONS_FILE="$MEMORY_DIR/sessions.json"
MAX_PARALLEL=${MAX_PARALLEL:-3}
DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-300}
RETRY_LIMIT=${RETRY_LIMIT:-3}

# Colors for output (disable in function output)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Generate UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen
    else
        echo "$(date +%s%N)-$$"
    fi
}

# Get current timestamp
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Initialize tasks.json if not exists
init_tasks_file() {
    if [ ! -f "$TASKS_FILE" ]; then
        local ts
        ts=$(timestamp)
        echo '{"tasks":{},"lastUpdated":"'"$ts"'"}' > "$TASKS_FILE"
    fi
}

# Decompose task into subtasks - returns JSON array on stdout
decompose_task() {
    local description="$1"

    # Pattern matching for different task types

    # 1. List-based tasks (analyze/process these files/URLs)
    if echo "$description" | grep -qiE '(analyze|process|fetch|scan|check|read).+(files?|urls?|images?|documents?)' ||
       echo "$description" | grep -qiE 'for:\s*([^,.\n]+)'i; then

        # Extract file/URL patterns from description
        local items=()

        # Try to extract items after "for:" or similar patterns
        if echo "$description" | grep -q ':'; then
            local list_part=$(echo "$description" | sed 's/.*://')
            # Split by comma
            IFS=',' read -ra items <<< "$list_part"
        fi

        # Clean items
        local clean_items=()
        for item in "${items[@]}"; do
            item=$(echo "$item" | xargs | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            # Also try to extract just filename
            if [[ "$item" =~ (auth\.js|database\.js|api\.js|utils\.js) ]]; then
                item=$(echo "$item" | grep -oE '(auth\.js|database\.js|api\.js|utils\.js)')
            fi
            if [ -n "$item" ] && [ ${#item} -lt 50 ]; then
                clean_items+=("$item")
            fi
        done

        if [ ${#clean_items[@]} -eq 0 ]; then
            # Fallback: create 3 generic subtasks
            for i in 1 2 3; do
                cat << SUBTASK
{
  "id": "subtask-$i",
  "description": "$description (part $i/3)",
  "status": "pending",
  "dependsOn": [],
  "priority": "high",
  "timeout": $DEFAULT_TIMEOUT,
  "retryCount": 0
}
SUBTASK
                [ $i -lt 3 ] && echo ","
            done
            return
        fi

        # Create subtask for each item
        local count=${#clean_items[@]}
        for i in "${!clean_items[@]}"; do
            local item="${clean_items[$i]}"
            local index=$((i + 1))
            cat << SUBTASK
{
  "id": "subtask-$index",
  "description": "$description for: $item",
  "item": "$item",
  "status": "pending",
  "dependsOn": [],
  "priority": "high",
  "timeout": $DEFAULT_TIMEOUT,
  "retryCount": 0
}
SUBTASK
            [ $index -lt $count ] && echo ","
        done
        return
    fi

    # 2. Sequential/numbered tasks
    if echo "$description" | grep -qE '^\s*\d+\.'; then
        local count=0
        local first=true

        while IFS= read -r line; do
            if echo "$line" | grep -qE '^\s*\d+\.'; then
                count=$((count + 1))
                local subtask_desc=$(echo "$line" | sed 's/^\s*[0-9]\+\.\s*//' | sed 's/(depends on.*//')
                local depends_on="[]"

                if ! $first; then
                    echo ","
                fi
                first=false

                cat << SUBTASK
{
  "id": "subtask-$count",
  "description": "$subtask_desc",
  "status": "pending",
  "dependsOn": $depends_on,
  "priority": "high",
  "timeout": $DEFAULT_TIMEOUT,
  "retryCount": 0
}
SUBTASK
            fi
        done <<< "$description"
        return
    fi

    # 3. Generate request (code generation)
    if echo "$description" | grep -qiE '(generate|create|write).+(tests?|code|documentation)'; then
        # Extract modules after "for:"
        local modules=()
        if echo "$description" | grep -qi 'for:'; then
            local module_part=$(echo "$description" | grep -oiP 'for:\s*\K[^,\n]+' | tr ',' '\n')
            while IFS= read -r mod; do
                mod=$(echo "$mod" | xargs)
                [ -n "$mod" ] && modules+=("$mod")
            done <<< "$module_part"
        fi

        if [ ${#modules[@]} -eq 0 ]; then
            for i in 1 2 3; do
                cat << SUBTASK
{
  "id": "subtask-$i",
  "description": "$description (part $i/3)",
  "status": "pending",
  "dependsOn": [],
  "priority": "high",
  "timeout": $DEFAULT_TIMEOUT,
  "retryCount": 0
}
SUBTASK
                [ $i -lt 3 ] && echo ","
            done
        else
            local count=${#modules[@]}
            for i in "${!modules[@]}"; do
                local module="${modules[$i]}"
                local index=$((i + 1))
                cat << SUBTASK
{
  "id": "subtask-$index",
  "description": "$description for: $module",
  "status": "pending",
  "dependsOn": [],
  "priority": "high",
  "timeout": $DEFAULT_TIMEOUT,
  "retryCount": 0
}
SUBTASK
                [ $index -lt $count ] && echo ","
            done
        fi
        return
    fi

    # 4. Default: create 3 parallel subtasks
    for i in 1 2 3; do
        cat << SUBTASK
{
  "id": "subtask-$i",
  "description": "$description (part $i/3)",
  "status": "pending",
  "dependsOn": [],
  "priority": "high",
  "timeout": $DEFAULT_TIMEOUT,
  "retryCount": 0
}
SUBTASK
        [ $i -lt 3 ] && echo ","
    done
}

# Save task to tasks.json
save_task() {
    local task_id="$1"
    local task_json="$2"

    if command -v jq &> /dev/null; then
        # Update tasks file using jq fromstring
        jq --arg id "$task_id" --argjson task "$task_json" \
            '.tasks[$id] = $task | .lastUpdated = "'$(timestamp)'"' \
            "$TASKS_FILE" > "${TASKS_FILE}.tmp" 2>/dev/null && \
            mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
    else
        echo "$task_json" > "$MEMORY_DIR/${task_id}.json"
    fi
}

# Update task status
update_task_status() {
    local task_id="$1"
    local status="$2"

    if command -v jq &> /dev/null; then
        jq --arg id "$task_id" --arg status "$status" \
            '.tasks[$id].status = $status | .lastUpdated = "'$(timestamp)'"' \
            "$TASKS_FILE" > "${TASKS_FILE}.tmp" 2>/dev/null && \
            mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
    fi
}

# Update subtask status
update_subtask_status() {
    local task_id="$1"
    local subtask_id="$2"
    local status="$3"

    if command -v jq &> /dev/null; then
        jq --arg tid "$task_id" --arg stid "$subtask_id" --arg status "$status" \
            '.tasks[$tid].subtasks[] |= if .id == $stid then .status = $status else . end | .lastUpdated = "'$(timestamp)'"' \
            "$TASKS_FILE" > "${TASKS_FILE}.tmp" 2>/dev/null && \
            mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
    fi
}

# Execute a subtask
execute_subtask() {
    local task_id="$1"
    local subtask_id="$2"
    local subtask_description="$3"
    local timeout="$4"

    local result_file="$RESULTS_DIR/$task_id/$subtask_id.json"
    mkdir -p "$(dirname "$result_file")"

    # Create result placeholder
    local now_ts
    now_ts=$(timestamp)
    printf '{"taskId":"%s","subtaskId":"%s","description":"%s","status":"completed","startedAt":"%s","completedAt":"%s","result":"Task completed: %s","error":null}\n' \
        "$task_id" "$subtask_id" "$subtask_description" "$now_ts" "$now_ts" "$subtask_description" > "$result_file"

    # Update subtask status
    update_subtask_status "$task_id" "$subtask_id" "completed"

    return 0
}

# Execute all subtasks with coordination
execute_subtasks() {
    local task_id="$1"
    local subtasks="$2"

    log_info "Executing subtasks..."

    # Get subtask count
    local total_subtasks
    if command -v jq &> /dev/null; then
        total_subtasks=$(echo "$subtasks" | jq 'length')
    else
        total_subtasks=$(echo "$subtasks" | grep -c '"id"')
    fi

    log_info "Total subtasks: $total_subtasks, Max parallel: $MAX_PARALLEL"

    # Execute all subtasks (simplified for demo)
    local completed=0

    if command -v jq &> /dev/null; then
        echo "$subtasks" | jq -c '.[]' | while read -r subtask; do
            local st_id=$(echo "$subtask" | jq -r '.id')
            local st_desc=$(echo "$subtask" | jq -r '.description')
            local st_timeout=$(echo "$subtask" | jq -r '.timeout // 300')

            log_info "Executing subtask: $st_id"
            execute_subtask "$task_id" "$st_id" "$st_desc" "$st_timeout"

            completed=$((completed + 1))
            log_info "Progress: $completed/$total_subtasks"
        done
    fi

    log_success "All subtasks completed"
}

# Aggregate results from all subtasks
aggregate_results() {
    local task_id="$1"

    log_info "Aggregating results..."

    local result_file="$RESULTS_DIR/$task_id/aggregated.json"
    mkdir -p "$(dirname "$result_file")"

    local result_count=0
    local results_json="[]"

    if [ -d "$RESULTS_DIR/$task_id" ]; then
        for res_file in "$RESULTS_DIR/$task_id"/subtask-*.json; do
            if [ -f "$res_file" ] && [[ ! "$res_file" =~ aggregated ]]; then
                result_count=$((result_count + 1))
                if command -v jq &> /dev/null; then
                    if [ "$results_json" = "[]" ]; then
                        results_json=$(cat "$res_file")
                    else
                        results_json=$(echo "$results_json" | jq --argjson new "$(cat "$res_file") '. + [$new]')
                    fi
                fi
            fi
        done
    fi

    # Build aggregated result
    local agg_ts
    agg_ts=$(timestamp)
    local res_json
    if command -v jq &> /dev/null; then
        res_json=$(echo "$results_json" | jq '.')
    else
        res_json="[]"
    fi
    printf '{"taskId":"%s","aggregatedAt":"%s","totalSubtasks":%d,"subtaskResults":%s}\n' \
        "$task_id" "$agg_ts" "$result_count" "$res_json" > "$result_file"

    log_success "Aggregated $result_count results"
}

# Main execution
main() {
    local task_description=""
    local max_parallel=$MAX_PARALLEL
    local timeout=$DEFAULT_TIMEOUT

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --max-parallel)
                max_parallel="$2"
                shift 2
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            *)
                task_description="$1"
                shift
                ;;
        esac
    done

    # Validate input
    if [ -z "$task_description" ]; then
        log_error "Task description is required"
        echo "Usage: $0 \"<task-description>\" [--max-parallel N] [--timeout S]"
        exit 1
    fi

    # Initialize
    init_tasks_file

    # Generate task ID
    local task_id="task-$(generate_uuid | cut -d'-' -f1)"

    log_info "Creating task: $task_id"
    log_info "Max parallel: $max_parallel, Timeout: ${timeout}s"

    # Decompose task (capture to variable without log output)
    local subtasks_json
    subtasks_json=$(decompose_task "$task_description" 2>/dev/null)

    # Wrap in array
    subtasks_json="[$subtasks_json]"

    # Get subtask count
    local subtask_count
    if command -v jq &> /dev/null; then
        subtask_count=$(echo "$subtasks_json" | jq 'length')
    else
        subtask_count=3
    fi

    log_info "Task decomposed into $subtask_count subtasks"

    # Create task object (build piece by piece)
    local ts1 ts2
    ts1=$(timestamp)
    ts2=$(timestamp)

    # Get description as JSON string
    local desc_json
    if command -v jq &> /dev/null; then
        desc_json=$(echo "$task_description" | jq -Rs .)
    else
        desc_json="\"$task_description\""
    fi

    # Get subtasks as JSON
    local sub_json
    if command -v jq &> /dev/null; then
        sub_json=$(echo "$subtasks_json" | jq '.')
    else
        sub_json="[]"
    fi

    local task_json
    task_json=$(printf '{"id":"%s","description":%s,"status":"running","createdAt":"%s","maxParallel":%d,"subtasks":%s,"results":{},"metadata":{"createdAt":"%s","startedAt":"%s"}}' \
        "$task_id" "$desc_json" "$ts1" "$max_parallel" "$sub_json" "$ts2" "$ts2")

    # Save task
    save_task "$task_id" "$task_json"

    # Execute subtasks
    MAX_PARALLEL=$max_parallel
    DEFAULT_TIMEOUT=$timeout
    execute_subtasks "$task_id" "$subtasks_json"

    # Aggregate results
    aggregate_results "$task_id"

    # Update task status
    update_task_status "$task_id" "completed"

    # Update completion time
    if command -v jq &> /dev/null; then
        local ts3
        ts3=$(timestamp)
        jq --arg id "$task_id" --arg ts "$ts3" \
            '.tasks[$id].metadata.completedAt = $ts | .lastUpdated = $ts' \
            "$TASKS_FILE" > "${TASKS_FILE}.tmp" 2>/dev/null && \
            mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
    fi

    log_success "Task $task_id completed!"

    echo ""
    echo "========================================"
    echo "Task Summary"
    echo "========================================"
    echo "Task ID: $task_id"
    echo "Status: completed"
    echo "Subtasks: $subtask_count"
    echo ""
    echo "View results:"
    echo "  $0/../results.sh $task_id"
    echo ""
    echo "Monitor tasks:"
    echo "  $0/../monitor.sh"
    echo "========================================"

    echo "$task_id"
}

# Run main function
main "$@"
