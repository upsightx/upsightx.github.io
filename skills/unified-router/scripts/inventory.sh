#!/bin/bash
# Unified Router - Skill Inventory
# Lists all available skills with their types and capabilities

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_JSON="$SCRIPT_DIR/skills.json"
source "$SCRIPT_DIR/config.sh"

# Color output helpers
print_header() {
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_INFO}[UNIFIED ROUTER] Skill Inventory${COLOR_RESET}"
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

print_section() {
    echo ""
    echo -e "${COLOR_INFO}$1${COLOR_RESET}"
}

print_skill() {
    local name="$1"
    local desc="$2"
    local available="$3"
    local priority="$4"

    if [[ "$available" == "true" ]]; then
        echo -e "  ${COLOR_OK}•${COLOR_RESET} $(printf '%-20s' "$name") - $desc"
        echo -e "    Priority: $priority | Status: ${COLOR_OK}Available${COLOR_RESET}"
        echo ""
    else
        echo -e "  ${COLOR_WARN}○${COLOR_RESET} $(printf '%-20s' "$name") - $desc"
        echo -e "    Priority: $priority | Status: ${COLOR_WARN}Unavailable${COLOR_RESET}"
        echo ""
    fi
}

# Main function
main() {
    print_header

    if command -v jq &>/dev/null; then
        # Group skills by type
        print_section "CODING SKILLS:"

        jq -r '.skills[] | select(.type == "coding") |
            "\(.name)|\(.description)|\(.available)|\(.priority)"' \
            "$SKILLS_JSON" 2>/dev/null | while IFS='|' read -r name desc avail prio; do
            print_skill "$name" "$desc" "$avail" "$prio"
        done

        print_section "GENERAL SKILLS:"

        jq -r '.skills[] | select(.type == "general") |
            "\(.name)|\(.description)|\(.available)|\(.priority)"' \
            "$SKILLS_JSON" 2>/dev/null | while IFS='|' read -r name desc avail prio; do
            print_skill "$name" "$desc" "$avail" "$prio"
        done

        # Check for uncategorized
        local uncategorized=$(jq -r '.skills[] | select(.type != "coding" and .type != "general") | .name' "$SKILLS_JSON" 2>/dev/null)
        if [[ -n "$uncategorized" ]]; then
            print_section "UNCATEGORIZED:"

            jq -r '.skills[] | select(.type != "coding" and .type != "general") |
                "\(.name)|\(.description)|\(.available)|\(.priority)"' \
                "$SKILLS_JSON" 2>/dev/null | while IFS='|' read -r name desc avail prio; do
                print_skill "$name" "$desc" "$avail" "$prio"
            done
        fi

        # Summary
        local total=$(jq '.skills | length' "$SKILLS_JSON" 2>/dev/null)
        local available=$(jq '[.skills[] | select(.available == true)] | length' "$SKILLS_JSON" 2>/dev/null)
        local coding=$(jq '[.skills[] | select(.type == "coding")] | length' "$SKILLS_JSON" 2>/dev/null)
        local general=$(jq '[.skills[] | select(.type == "general")] | length' "$SKILLS_JSON" 2>/dev/null)

        echo ""
        print_section "SUMMARY:"
        echo "  Total Skills: $total"
        echo -e "  Available: ${COLOR_OK}$available${COLOR_RESET} / $total"
        echo "  Coding Skills: $coding"
        echo "  General Skills: $general"

    else
        echo -e "${COLOR_WARN}Note: Install 'jq' for detailed skill information${COLOR_RESET}"
        echo ""
        print_section "CODING SKILLS:"
        echo "  • project-analyzer"
        echo "  • security-auditor"
        echo ""
        print_section "GENERAL SKILLS:"
        echo "  • rag-memory"
        echo "  • knowledge-manager"
        echo "  • smart-reminder"
        echo "  • agent-teams"
    fi

    echo ""
    echo -e "${COLOR_INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

main "$@"
