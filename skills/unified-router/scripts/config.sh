#!/bin/bash
# Unified Router - Configuration

# Skill directories
WORKSPACE_ROOT="/root/.openclaw/workspace"
SKILLS_ROOT="$WORKSPACE_ROOT/skills"

# Skill priorities (comma-separated)
CODING_SKILLS="project-analyzer,security-auditor"
GENERAL_SKILLS="rag-memory,knowledge-manager,smart-reminder"

# Default fallback
DEFAULT_SKILL="default"

# Confidence thresholds
MIN_CONFIDENCE=0.7
CONFIRM_THRESHOLD=0.5

# Task types
TASK_TYPE_CODING="coding"
TASK_TYPE_GENERAL="general"
TASK_TYPE_UNKNOWN="unknown"

# Colors for output
COLOR_OK='\033[0;32m'
COLOR_WARN='\033[0;33m'
COLOR_ERROR='\033[0;31m'
COLOR_INFO='\033[0;36m'
COLOR_RESET='\033[0m'

# Logging
LOG_FILE="$SKILLS_ROOT/unified-router/scripts/router.log"

# Create log file if needed
touch "$LOG_FILE" 2>/dev/null || true

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}
