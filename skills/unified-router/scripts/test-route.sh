#!/bin/bash
# Unified Router - Test Routing
# Analyzes a query and shows which skill would handle it (without executing)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config without colors for JSON
export COLOR_OK=''
export COLOR_WARN=''
export COLOR_ERROR=''
export COLOR_INFO=''
export COLOR_RESET=''
source "$SCRIPT_DIR/config.sh"

# Re-enable colors for output
COLOR_OK='\033[0;32m'
COLOR_WARN='\033[0;33m'
COLOR_ERROR='\033[0;31m'
COLOR_INFO='\033[0;36m'
COLOR_RESET='\033[0m'

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

# Parse JSON - extract value by key (works with both strings and numbers)
parse_json() {
    local json="$1"
    local key="$2"
    local value

    # Check for boolean true first
    if echo "$json" | grep -q "\"$key\":\s*true"; then
        echo "true"
        return
    fi

    # Check for boolean false
    if echo "$json" | grep -q "\"$key\":\s*false"; then
        echo "false"
        return
    fi

    # Check for string value
    value=$(echo "$json" | grep -o "\"$key\":\s*\"[^\"]*\"" | head -1 | cut -d'"' -f4)
    if [[ -n "$value" ]]; then
        echo "$value"
        return
    fi

    # Check for number value
    value=$(echo "$json" | grep -o "\"$key\":\s*[0-9.]*" | head -1 | grep -o "[0-9.]*" | head -1)
    if [[ -n "$value" ]]; then
        echo "$value"
        return
    fi

    echo ""
}

# Display routing result
display_routing() {
    local query="$1"
    local detection_result="$2"
    local routing_result="$3"

    # Parse JSON
    local task_type=$(parse_json "$detection_result" "task_type")
    local confidence=$(parse_json "$detection_result" "confidence")
    local recommended_skill=$(parse_json "$routing_result" "recommended_skill")
    local fallback=$(parse_json "$routing_result" "fallback")
    local skill_available=$(parse_json "$routing_result" "skill_available")

    # Set defaults if parsing failed
    task_type=${task_type:-"unknown"}
    confidence=${confidence:-"0.0"}
    recommended_skill=${recommended_skill:-"none"}
    fallback=${fallback:-"default"}
    skill_available=${skill_available:-"false"}

    print_header

    echo ""
    echo -e "${COLOR_INFO}Query:${COLOR_RESET} \"$query\""
    echo ""

    print_section "Task Detection"
    echo "  Type: ${COLOR_INFO}$task_type${COLOR_RESET}"
    echo "  Confidence: ${COLOR_INFO}$confidence${COLOR_RESET}"

    # Confidence checks (using awk for)
    local conf_num=$(echo "$confidence" | awk '{printf "%.2f", $1}')

    if awk "BEGIN {exit !($conf_num >= 0.8)}"; then
        print_ok "High confidence - task type clearly identified"
    elif awk "BEGIN {exit !($conf_num >= $MIN_CONFIDENCE)}"; then
        print_ok "Good confidence - task type detected"
    elif awk "BEGIN {exit !($conf_num >= $CONFIRM_THRESHOLD)}"; then
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
            local description=$(parse_json "$skill_details" "description")
            local type=$(parse_json "$skill_details" "type")
            echo "  Description: $description"
            echo "  Category: $type"
        fi
    fi

    print_section "Recommendation"
    if awk "BEGIN {exit !($conf_num >= $MIN_CONFIDENCE)}" && [[ "$skill_available" == "true" ]]; then
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
    local task_type=$(parse_json "$detection_result" "task_type")
    local confidence=$(parse_json "$detection_result" "confidence")

    # Run routing
    local routing_result=$($SCRIPT_DIR/route.sh "$query" "$task_type" "$confidence")

    # Display results
    display_routing "$query" "$detection_result" "$routing_result"

    log "TEST-ROUTE" "Query: $query → $task_type ($confidence) → $recommended_skill"
}

main "$@"
