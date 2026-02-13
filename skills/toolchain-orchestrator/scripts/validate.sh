#!/bin/bash
# validate.sh - Validate chain definitions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CHAINS_DIR="$SKILL_DIR/chains"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <chain-id> [--fix]"
    echo ""
    echo "Validate a tool chain definition."
    echo ""
    echo "Options:"
    echo "  --fix    Attempt to fix common issues"
    echo ""
    echo "Examples:"
    echo "  $0 chain-001"
    echo "  $0 chain-001 --fix"
    echo ""
    exit 1
}

# Parse arguments
CHAIN_ID=""
FIX=false

if [ $# -eq 0 ]; then
    usage
fi

CHAIN_ID="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --fix)
            FIX=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Find chain file
CHAIN_FILE=""
if [ -f "$CHAINS_DIR/$CHAIN_ID.json" ]; then
    CHAIN_FILE="$CHAINS_DIR/$CHAIN_ID.json"
elif [ -f "$CHAINS_DIR/$CHAIN_ID" ]; then
    CHAIN_FILE="$CHAINS_DIR/$CHAIN_ID"
elif [ -f "$CHAIN_ID" ]; then
    CHAIN_FILE="$CHAIN_ID"
else
    echo -e "${RED}Error: Chain not found: $CHAIN_ID${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required for validation${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Chain Validation${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Validating: $CHAIN_FILE"
echo ""

ERRORS=0
WARNINGS=0

# Check if JSON is valid
if ! jq empty "$CHAIN_FILE" 2>/dev/null; then
    echo -e "${RED}✗ Invalid JSON format${NC}"
    ((ERRORS++))
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Valid JSON format${NC}"

# Check required fields
REQUIRED_FIELDS=("id" "name" "tools" "config")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".$field" "$CHAIN_FILE" > /dev/null 2>&1; then
        echo -e "${RED}✗ Missing required field: $field${NC}"
        ((ERRORS++))
    else
        echo -e "${GREEN}✓ Has field: $field${NC}"
    fi
done

# Check tools array
TOOL_COUNT=$(jq '.tools | length' "$CHAIN_FILE" 2>/dev/null || echo "0")
echo -e "${BLUE}Tool count: $TOOL_COUNT${NC}"

if [ "$TOOL_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No tools defined${NC}"
    ((WARNINGS++))
fi

# Check each tool
declare -A tool_ids
for i in $(seq 0 $((TOOL_COUNT - 1))); do
    tool_id=$(jq -r ".tools[$i].id // \"\"" "$CHAIN_FILE")
    
    if [ -z "$tool_id" ]; then
        echo -e "${RED}✗ Tool at index $i has no id${NC}"
        ((ERRORS++))
        continue
    fi
    
    # Check for duplicate IDs
    if [ -n "${tool_ids[$tool_id]}" ]; then
        echo -e "${RED}✗ Duplicate tool ID: $tool_id${NC}"
        ((ERRORS++))
    else
        tool_ids[$tool_id]=1
    fi
    
    # Check tool has name
    tool_name=$(jq -r ".tools[$i].name // \"\"" "$CHAIN_FILE")
    if [ -z "$tool_name" ]; then
        echo -e "${YELLOW}⚠ Tool $tool_id has no name${NC}"
        ((WARNINGS++))
    fi
    
    # Check depends_on is an array
    if ! jq -e ".tools[$i].depends_on" "$CHAIN_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Tool $tool_id missing depends_on array${NC}"
        ((WARNINGS++))
    fi
done

# Check for circular dependencies
check_circular() {
    local tool_id=$1
    local visited=$2
    
    for visited_id in $visited; do
        if [ "$tool_id" = "$visited_id" ]; then
            return 0  # Circular dependency found
        fi
    done
    
    local new_visited="$visited $tool_id"
    
    # Get dependencies
    local deps=$(jq -r ".tools[] | select(.id == \"$tool_id\") | .depends_on[]?" "$CHAIN_FILE" 2>/dev/null)
    
    for dep in $deps; do
        if check_circular "$dep" "$new_visited"; then
            return 0
        fi
    done
    
    return 1  # No circular dependency
}

HAS_CIRCULAR=false
for tool_id in "${!tool_ids[@]}"; do
    if check_circular "$tool_id" ""; then
        echo -e "${RED}✗ Circular dependency detected involving: $tool_id${NC}"
        ((ERRORS++))
        HAS_CIRCULAR=true
        break
    fi
done

if [ "$HAS_CIRCULAR" = false ]; then
    echo -e "${GREEN}✓ No circular dependencies${NC}"
fi

# Check config
CONFIG_MAX_PARALLEL=$(jq -r '.config.max_parallel // ""' "$CHAIN_FILE")
if [ -z "$CONFIG_MAX_PARALLEL" ]; then
    echo -e "${YELLOW}⚠ config.max_parallel not set (will use default: 3)${NC}"
    ((WARNINGS++))
elif ! [[ "$CONFIG_MAX_PARALLEL" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}✗ config.max_parallel must be a number${NC}"
    ((ERRORS++))
fi

CONFIG_RETRY_COUNT=$(jq -r '.config.retry_count // ""' "$CHAIN_FILE")
if [ -z "$CONFIG_RETRY_COUNT" ]; then
    echo -e "${YELLOW}⚠ config.retry_count not set (will use default: 2)${NC}"
    ((WARNINGS++))
elif ! [[ "$CONFIG_RETRY_COUNT" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}✗ config.retry_count must be a number${NC}"
    ((ERRORS++))
fi

# Print summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Validation Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Chain is valid!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Chain valid with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Chain has $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
