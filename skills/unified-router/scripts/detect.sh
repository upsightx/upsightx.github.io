#!/bin/bash
# Unified Router - Task Type Detection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Check for coding-related patterns
is_coding_task() {
    local query=$(to_lower "$1")

    # Code generation patterns
    local coding_patterns=(
        "create.*function"
        "write.*function"
        "write.*script"
        "create.*script"
        "implement.*function"
        "implement.*class"
        "define.*function"
        "define.*class"
        "build.*api"
        "create.*api"
        "write.*api"
        "generate.*code"
        "code.*generate"
    )

    # Debugging patterns
    local debug_patterns=(
        "fix.*bug"
        "debug"
        "debugging"
        "troubleshoot"
        "resolve.*error"
        "fix.*error"
        "what.*wrong"
        "why.*not.*working"
    )

    # Code review patterns
    local review_patterns=(
        "review.*code"
        "analyze.*code"
        "check.*code"
        "audit.*code"
        "code.*review"
        "code.*analysis"
    )

    # Refactoring patterns
    local refactor_patterns=(
        "refactor"
        "optimize.*code"
        "improve.*code"
        "clean.*code"
        "restructure"
        "rewrite"
    )

    # Language/framework patterns
    local lang_patterns=(
        "python"
        "javascript"
        "java"
        "c\+\+"
        "golang"
        "rust"
        "typescript"
        "react"
        "vue"
        "angular"
        "node.*js"
        "django"
        "flask"
        "express"
        "spring"
    )

    # Technical patterns
    local tech_patterns=(
        "function"
        "class"
        "method"
        "variable"
        "array"
        "list"
        "dictionary"
        "hash"
        "algorithm"
        "data.*structure"
        "api"
        "endpoint"
        "database"
        "sql"
        "query"
        "json"
        "xml"
        "html"
        "css"
        "frontend"
        "backend"
    )

    # Check all pattern groups
    local all_patterns=(
        "${coding_patterns[@]}"
        "${debug_patterns[@]}"
        "${review_patterns[@]}"
        "${refactor_patterns[@]}"
        "${lang_patterns[@]}"
        "${tech_patterns[@]}"
    )

    for pattern in "${all_patterns[@]}"; do
        if [[ "$query" =~ $pattern ]]; then
            return 0
        fi
    done

    return 1
}

# Check for general task patterns
is_general_task() {
    local query=$(to_lower "$1")

    # Question patterns
    local question_patterns=(
        "what.*is"
        "how.*do.*i"
        "how.*to"
        "how.*does"
        "why.*is"
        "explain"
        "tell.*me.*about"
        "what.*are"
        "can.*you.*explain"
        "what.*means"
        "definition.*of"
    )

    # Writing/analysis patterns
    local write_patterns=(
        "write.*article"
        "write.*email"
        "compose"
        "draft"
        "summarize"
        "analyze.*text"
        "analyze.*document"
        "extract.*information"
        "create.*report"
    )

    # Reminder/scheduling patterns
    local reminder_patterns=(
        "remind.*me"
        "schedule"
        "notify"
        "alarm"
        "timer"
        "don't.*forget"
        "remember.*to"
    )

    # Knowledge patterns
    local knowledge_patterns=(
        "search"
        "find.*information"
        "lookup"
        "what.*knows"
        "retrieve"
    )

    # Check all pattern groups
    local all_patterns=(
        "${question_patterns[@]}"
        "${write_patterns[@]}"
        "${reminder_patterns[@]}"
        "${knowledge_patterns[@]}"
    )

    for pattern in "${all_patterns[@]}"; do
        if [[ "$query" =~ $pattern ]]; then
            return 0
        fi
    done

    return 1
}

# Calculate confidence score for task type
calculate_confidence() {
    local query=$(to_lower "$1")
    local task_type="$2"
    local confidence=0.0

    if [[ "$task_type" == "$TASK_TYPE_CODING" ]]; then
        # Strong coding indicators
        if [[ "$query" =~ (create|write|implement).*function ]]; then
            confidence=0.95
        elif [[ "$query" =~ (create|write).*script ]]; then
            confidence=0.92
        elif [[ "$query" =~ (debug|fix|troubleshoot) ]]; then
            confidence=0.90
        elif [[ "$query" =~ (review|analyze).*code ]]; then
            confidence=0.88
        elif [[ "$query" =~ refactor ]]; then
            confidence=0.87
        elif [[ "$query" =~ (python|javascript|java|golang|rust|typescript|react|vue) ]]; then
            confidence=0.85
        elif [[ "$query" =~ (function|class|method|array|list|api|database) ]]; then
            confidence=0.75
        fi

    elif [[ "$task_type" == "$TASK_TYPE_GENERAL" ]]; then
        # Strong general indicators
        if [[ "$query" =~ (what.*is|explain) ]]; then
            confidence=0.90
        elif [[ "$query" =~ (how.*do.*i|how.*to) ]]; then
            confidence=0.88
        elif [[ "$query" =~ (write.*article|write.*email|compose) ]]; then
            confidence=0.85
        elif [[ "$query" =~ (remind|schedule|notify) ]]; then
            confidence=0.92
        elif [[ "$query" =~ (summarize|analyze.*text) ]]; then
            confidence=0.83
        fi
    fi

    printf "%.2f" "$confidence"
}

# Main detection function
detect_task() {
    local query="$1"
    local task_type="$TASK_TYPE_UNKNOWN"
    local confidence=0.0

    if is_coding_task "$query"; then
        task_type="$TASK_TYPE_CODING"
        confidence=$(calculate_confidence "$query" "$task_type")
    elif is_general_task "$query"; then
        task_type="$TASK_TYPE_GENERAL"
        confidence=$(calculate_confidence "$query" "$task_type")
    fi

    # Output as JSON for easy parsing
    cat << EOF
{
  "task_type": "$task_type",
  "confidence": $confidence,
  "query": "$query"
}
EOF

    log "DETECT" "Query: $query → Type: $task_type, Confidence: $confidence"
}

# Command line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "$1" ]]; then
        echo "Usage: $0 <query>"
        exit 1
    fi

    detect_task "$*"
fi
