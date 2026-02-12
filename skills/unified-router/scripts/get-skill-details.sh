#!/bin/bash
# Unified Router - Get Skill Details
# Returns details about a specific skill from skills.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_JSON="$SCRIPT_DIR/skills.json"

if [[ -z "$1" ]]; then
    echo "Usage: $0 <skill_name>"
    exit 1
fi

skill_name="$1"

if command -v jq &>/dev/null; then
    jq -r --arg name "$skill_name" \
        '.skills[] | select(.name == $name) | {
            name: .name,
            type: .type,
            description: .description,
            capabilities: .capabilities,
            keywords: .keywords,
            priority: .priority,
            available: .available
        }' \
        "$SKILLS_JSON" 2>/dev/null
else
    # Simple grep-based fallback
    echo "{\"name\":\"$skill_name\",\"type\":\"unknown\",\"description\":\"Install jq for full details\",\"capabilities\":[],\"priority\":0}"
fi
