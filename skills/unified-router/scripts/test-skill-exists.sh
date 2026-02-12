#!/bin/bash
# Test skill_exists function

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="/root/.openclaw/workspace/skills"
SKILLS_JSON="$SCRIPT_DIR/skills.json"

skill_name="project-analyzer"

echo "Testing skill_exists for: $skill_name"
echo ""

# Test with jq
if command -v jq &>/dev/null; then
    echo "Test with jq:"
    available=$(jq -r --arg name "$skill_name" '.skills[] | select(.name == $name) | .available' "$SKILLS_JSON" 2>/dev/null)
    echo "  available: $available"
    if [[ "$available" == "true" ]]; then
        echo "  Result: skill available"
    else
        echo "  Result: skill not available"
    fi
fi

echo ""

# Test with directory check
echo "Test with directory check:"
if [[ -d "$SKILLS_ROOT/$skill_name" ]] && [[ -f "$SKILLS_ROOT/$skill_name/SKILL.md" ]]; then
    echo "  Result: skill available (directory exists)"
else
    echo "  Result: skill not available (directory missing)"
fi
