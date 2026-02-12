#!/bin/bash
# Test parse_json function V2

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

json='{"query": "create a Python function", "task_type": "coding", "confidence": 0.95, "recommended_skill": "project-analyzer", "fallback": "default", "skill_available": true}'

echo "Testing parse_json V2"
echo "JSON: $json"
echo ""

echo "task_type: $(parse_json "$json" "task_type")"
echo "confidence: $(parse_json "$json" "confidence")"
echo "recommended_skill: $(parse_json "$json" "recommended_skill")"
echo "fallback: $(parse_json "$json" "fallback")"
echo "skill_available: $(parse_json "$json" "skill_available")"
