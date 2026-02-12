#!/bin/bash
# Test parse_json function

parse_json() {
    local json="$1"
    local key="$2"
    local value
    value=$(echo "$json" | grep -o "\"$key\":\s*\"[^\"]*\"" | head -1 | cut -d'"' -f4)
    if [[ -z "$value" ]]; then
        value=$(echo "$json" | grep -o "\"$key\":\s*[0-9.]*" | head -1 | grep -o "[0-9.]*" | head -1)
    fi
    if [[ -z "$value" ]]; then
        value=$(echo "$json" | grep -o "\"$key\":\s*true" | head -1 && echo "true")
        value=${value:-false}
    fi
    echo "$value"
}

json='{"query": "create a Python function", "task_type": "coding", "confidence": 0.95, "recommended_skill": "project-analyzer", "fallback": "default", "skill_available": true}'

echo "Testing parse_json"
echo "JSON: $json"
echo ""

echo "task_type: $(parse_json "$json" "task_type")"
echo "confidence: $(parse_json "$json" "confidence")"
echo "recommended_skill: $(parse_json "$json" "recommended_skill")"
echo "fallback: $(parse_json "$json" "fallback")"
echo "skill_available: $(parse_json "$json" "skill_available")"
