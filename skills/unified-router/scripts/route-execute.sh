#!/bin/bash
# Unified Router - Route and Execute
# Routes a task and executes it through the selected skill

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Color output helpers
print_header() {
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_INFO}[UNIFIED ROUTER] Route & Execute${COLOR_RESET}"
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

print_section() {
    echo ""
    echo -e "${COLOR_OK}▶ $1${COLOR_RESET}"
}

print_ok() {
    echo -e "  ${COLOR_OK}✓${COLOR_RESET} $1"
}

print_warn() {
    echo -e "  ${COLOR_WARN}⚠${COLOR_RESET} $1"
}

print_error() {
    echo -e "  ${COLOR_ERROR}✗${COLOR_RESET} $1"
}

# Execute task through a skill
execute_with_skill() {
    local skill_name="$1"
    local query="$2"

    local skill_dir="$SKILLS_ROOT/$skill_name"

    if [[ ! -d "$skill_dir" ]]; then
        print_error "Skill directory not found: $skill_dir"
        return 1
    fi

    print_section "Executing with $skill_name"

    # Try to find an executable script in the skill
    local exec_script=""
    for script_file in "$skill_dir/scripts/"*.sh "$skill_dir/run.sh" "$skill_dir/execute.sh"; do
        if [[ -f "$script_file" ]] && [[ -x "$script_file" ]]; then
            exec_script="$script_file"
            break
        fi
    done

    if [[ -z "$exec_script" ]]; then
        # Try to find any .sh file
        exec_script=$(find "$skill_dir/scripts" -name "*.sh" -type f 2>/dev/null | head -1)
    fi

    if [[ -z "$exec_script" ]] || [[ ! -f "$exec_script" ]]; then
        print_warn "No executable script found in $skill_name"
        print_section "Skill Information"
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            echo "  Available skill documentation:"
            head -20 "$skill_dir/SKILL.md" | sed 's/^/    /'
        fi
        return 1
    fi

    print_ok "Found executable: $exec_script"

    echo ""
    echo -e "${COLOR_INFO}Running: $exec_script${COLOR_RESET}"
    echo -e "${COLOR_INFO}Query: $query${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""

    # Execute the skill
    if [[ -x "$exec_script" ]]; then
        "$exec_script" "$query"
    else
        bash "$exec_script" "$query"
    fi

    local exit_code=$?

    echo ""
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"

    if [[ $exit_code -eq 0 ]]; then
        print_ok "Execution completed successfully"
    else
        print_warn "Execution completed with exit code: $exit_code"
    fi

    return $exit_code
}

# Main execution
main() {
    if [[ -z "$1" ]]; then
        echo "Usage: $0 <query>"
        echo ""
        echo "Examples:"
        echo "  $0 \"create a Python function that sorts a list\""
        echo "  $0 \"explain how recursion works\""
        echo "  $0 \"analyze this codebase for security issues\""
        exit 1
    fi

    local query="$*"

    print_header

    echo ""
    echo -e "${COLOR_INFO}Query:${COLOR_RESET} \"$query\""

    # Run detection
    print_section "Step 1: Detect Task Type"
    local detection_result=$($SCRIPT_DIR/detect.sh "$query")
    local task_type=$(echo "$detection_result" | grep -o '"task_type":"[^"]*"' | cut -d'"' -f4)
    local confidence=$(echo "$detection_result" | grep -o '"confidence":[0-9.]*' | cut -d':' -f2)

    echo "  Detected type: ${COLOR_INFO}$task_type${COLOR_RESET}"
    echo "  Confidence: ${COLOR_INFO}$confidence${COLOR_RESET}"

    # Run routing
    print_section "Step 2: Route to Skill"
    local routing_result=$($SCRIPT_DIR/route.sh "$query" "$task_type" "$confidence")
    local recommended_skill=$(echo "$routing_result" | grep -o '"recommended_skill":"[^"]*"' | cut -d'"' -f4)
    local fallback=$(echo "$routing_result" | grep -o '"fallback":"[^"]*"' | cut -d'"' -f4)
    local skill_available=$(echo "$routing_result" | grep -o '"skill_available":[^,}]*' | cut -d':' -f2)

    echo "  Recommended skill: ${COLOR_INFO}$recommended_skill${COLOR_RESET}"
    echo "  Skill available: ${COLOR_INFO}$skill_available${COLOR_RESET}"

    local target_skill="$recommended_skill"

    # Handle unavailable skill
    if [[ "$skill" != "true" ]] || [[ "$recommended_skill" == "none" ]] || [[ "$recommended_skill" == "default" ]]; then
        print_warn "Recommended skill not available, using fallback"
        target_skill="$fallback"
    fi

    # Confirm if confidence is low
    if command -v bc &>/dev/null; then
        if (( $(echo "$confidence < $CONFIRM_THRESHOLD" | bc -l) )); then
            print_warn "Low confidence detected"
            echo "  Task type is unclear. Routing to $target_skill anyway."
        fi
    fi

    # Execute
    print_section "Step 3: Execute Task"

    if [[ "$target_skill" == "default" ]] || [[ "$target_skill" == "none" ]]; then
        print_warn "No specific skill available"
        echo ""
        echo "  The router couldn't find a suitable skill for this task."
        echo "  The task would be handled by default OpenClaw capabilities."
        echo ""
        print_section "Suggestion"
        echo "  • Use a more specific query"
        echo "  • Check available skills with: ./inventory.sh"
        echo "  • Test routing with: ./test-route.sh \"$query\""
        exit 0
    fi

    execute_with_skill "$target_skill" "$query"

    log "ROUTE-EXECUTE" "Query: $query → $task_type ($confidence) → $target_skill"

    echo ""
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

main "$@"
