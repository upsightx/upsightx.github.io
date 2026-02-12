#!/bin/bash
# Unified Router - Skill Routing Logic

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Check if a skill exists and is available
skill_exists() {
    local skill_name="$1"
    local skills_json="$SCRIPT_DIR/skills.json"

    if command -v jq &>/dev/null; then
        local available=$(jq -r --arg name "$skill_name" '.skills[] | select(.name == $name) | .available' "$skills_json" 2>/dev/null)
        [[ "$available" == "true" ]]
    else
        # Fallback: check if directory exists
        [[ -d "$SKILLS_ROOT/$skill_name" ]] && [[ -f "$SKILLS_ROOT/$skill_name/SKILL.md" ]]
    fi
}

# Get skills of a specific type, sorted by priority
get_skills_by_type() {
    local skill_type="$1"
    local skills_json="$SCRIPT_DIR/skills.json"

    if command -v jq &>/dev/null; then
        jq -r --arg type "$skill_type" \
            '.skills[] | select(.type == $type and .available == true) | .name' \
            "$skills_json" 2>/dev/null
    else
        # Fallback: use config.sh lists
        if [[ "$skill_type" == "coding" ]]; then
            echo "$CODING_SKILLS" | tr ',' '\n'
        elif [[ "$skill_type" == "general" ]]; then
            echo "$GENERAL_SKILLS" | tr ',' '\n'
        fi
    fi
}

# Find best skill for a task
find_best_skill() {
    local task_type="$1"
    local query=$(to_lower "$2")
    local skills_json="$SCRIPT_DIR/skills.json"

    # Get skills of the requested type
    local skills=($(get_skills_by_type "$task_type"))

    if [[ ${#skills[@]} -eq 0 ]]; then
        echo "none"
        return
    fi

    # Try to match keywords in query with skill keywords
    if command -v jq &>/dev/null; then
        for skill in "${skills[@]}"; do
            local keywords=$(jq -r --arg name "$skill" \
                '.skills[] | select(.name == $name) | .keywords | join(" ")' \
                "$skills_json" 2>/dev/null)

            if [[ -n "$keywords" ]]; then
                for keyword in $keywords; do
                    if [[ "$query" =~ $keyword ]]; then
                        echo "$skill"
                        log "ROUTE" "Matched keyword '$keyword' → $skill"
                        return
                    fi
                done
            fi
        done
    fi

    # No keyword match, return highest priority skill
    echo "${skills[0]}"
    log "ROUTE" "Using default skill for $task_type: ${skills[0]}"
}

# Get skill details
get_skill_details() {
    local skill_name="$1"
    local skills_json="$SCRIPT_DIR/skills.json"

    if command -v jq &>/dev/null; then
        jq -r --arg name "$skill_name" \
            '.skills[] | select(.name == $name) | {
                name: .name,
                type: .type,
                description: .description,
                capabilities: .capabilities,
                priority: .priority
            }' \
            "$skills_json" 2>/dev/null
    else
        cat << EOF
{
  "name": "$skill_name",
  "type": "unknown",
  "description": "Skill details unavailable",
  "capabilities": [],
  "priority": 0
}
EOF
    fi
}

# Route a task to the best skill
route_task() {
    local query="$1"
    local task_type="$2"
    local confidence="$3"

    local best_skill="none"
    local fallback="$DEFAULT_SKILL"

    # Route based on task type
    case "$task_type" in
        "$TASK_TYPE_CODING")
            best_skill=$(find_best_skill "coding" "$query")
            ;;
        "$TASK_TYPE_GENERAL")
            best_skill=$(find_best_skill "general" "$query")
            ;;
        *)
            best_skill="$fallback"
            ;;
    esac

    # Check if best skill exists
    if [[ "$best_skill" == "none" ]] || ! skill_exists "$best_skill"; then
        best_skill="$fallback"
        log "ROUTE" "Best skill not available, using fallback: $fallback"
    fi

    # Output routing decision
    cat << EOF
{
  "query": "$query",
  "task_type": "$task_type",
  "confidence": $confidence,
  "recommended_skill": "$best_skill",
  "fallback": "$fallback",
  "skill_available": $(skill_exists "$best_skill" && echo "true" || echo "false")
}
EOF

    log "ROUTE" "Routed to: $best_skill (type: $task_type, confidence: $confidence)"
}

# Main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 3 ]]; then
        echo "Usage: $0 <query> <task_type> <confidence>"
        exit 1
    fi

    route_task "$1" "$2" "$3"
fi
