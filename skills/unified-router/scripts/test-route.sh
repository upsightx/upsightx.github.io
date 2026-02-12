#!/bin/bash
# Unified Router - Test Routing
# Analyzes a query and shows which skill would handle it (without executing)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Color output helpers
print_header() {
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_INFO}[UNIFIED ROUTER] Task Analysis${COLOR_RESET}"
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

# Display routing result
display_routing() {
    local query="$1"
    local detection_result="$2"
    local routing_result="$3"

    # Parse JSON (simplified)
    local task_type=$(echo "$detection_result" | grep -o '"task_type":"[^"]*"' | cut -d'"' -f4)
    local confidence=$(echo "$detection_result" | grep -o '"confidence":[0-9.]*' | cut -d':' -f2)
    local recommended_skill=$(echo "$routing_result" | grep -o '"recommended_skill":"[^"]*"' | cut -d'"' -f4)
    local fallback=$(echo "$routing_result" | grep -o '"fallback":"[^"]*"' | cut -d'"' -f4)
    local skill_available=$(echo "$routing_result" | grep -o '"skill_available":[^,}]*' | cut -d':' -f2)

    print_header

    echo ""
    echo -e "${COLOR_INFO}Query:${COLOR_RESET} \"$query\""
    echo ""

    print_section "Task Detection"
    echo "  Type: ${COLOR_INFO}$task_type${COLOR_RESET}"
    echo "  Confidence: ${COLOR_INFO}$confidence${COLOR_RESET}"

    if (( $(echo "$confidence >= 0.8" | bc -l) )); then
        print_ok "High confidence - task type clearly identified"
    elif (( $(echo "$confidence >= $MIN_CONFIDENCE" | bc -l) )); then
        print_ok "Good confidence - task type detected"
    elif (( $(echo "$confidence >= $CONFIRM_THRESHOLD" | bc -l) )); then
        print_warn "Medium confidence - task type probable but uncertain"
    else
        print_error "Low confidence - task type unclear, may need clarification"
    fi

    print_section "Skill Routing"
    echo "  Recommended: ${COLOR_INFO}$recommended_skill${COLOR_RESET}"
    echo "  Fallback: ${COLOR_INFO}$fallback${COLOR_RESET}"

    if [[ "$skill_available" == "true" ]]; then
        print_ok "Recommended skill is available"
    else
        print_warn "Recommended skill not available, would use fallback"
    fi

    # Show skill details if available
    if [[ "$recommended_skill" != "none" ]] && [[ "$recommended_skill" != "default" ]]; then
        local skill_details=$($SCRIPT_DIR/get-skill-details.sh "$recommended_skill" 2>/dev/null)
        if [[ -n "$skill_details" ]]; then
            print_section "Skill Details"
            local description=$(echo "$skill_details" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
            local type=$(echo "$skill_details" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
            echo "  Description: $description"
            echo "  Category: $type"
        fi
    fi

    print_section "Recommendation"
    if (( $(echo "$confidence >= $MIN_CONFIDENCE" | bc -l) )) && [[ "$skill_available" == "true" ]]; then
        print_ok "Auto-route to $recommended_skill"
        echo "  The task would be automatically sent to the recommended skill."
    elif [[ "$skill_available" == "true" ]]; then
        print_warn "Route with confirmation to $recommended_skill"
        echo "  The task would be routed after user confirmation."
    else
        print_warn "Route to fallback ($fallback)"
        echo "  The recommended skill is not available."
    fi

    echo ""
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

# Main execution
main() {
    if [[ -z "$1" ]]; then
        echo "Usage: $0 <query>"
        echo ""
        echo "Examples:"
        echo "  $0 \"create a Python function that sorts a list\""
        echo "  $0 \"explain how recursion works\""
        echo "  $0 \"review this codebase for security issues\""
        exit 1
    fi

    local query="$*"

    # Run detection
    local detection_result=$($SCRIPT_DIR/detect.sh "$query")

    # Parse task type and confidence
    local task_type=$(echo "$detection_result" | grep -o '"task_type":"[^"]*"' | cut -d'"' -f4)
    local confidence=$(echo "$detection_result" | grep -o '"confidence":[0-9.]*' | cut -d':' -f2)

    # Run routing
    local routing_result=$($SCRIPT_DIR/route.sh "$query" "$task_type" "$confidence")

    # Display results
    display_routing "$query" "$detection_result" "$routing_result"

    log "TEST-ROUTE" "Query: $query → $task_type ($confidence) → $recommended_skill"
}

# Check for bc (required for floating point comparison)
if ! command -v bc &>/dev/null; then
    echo "Error: 'bc' is required for confidence comparisons"
    echo "Install with: apt-get install bc"
    exit 1
fi

main "$@"
