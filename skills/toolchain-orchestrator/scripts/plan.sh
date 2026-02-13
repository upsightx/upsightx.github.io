#!/bin/bash
# plan.sh - Plan tool chains from natural language

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CHAINS_DIR="$SKILL_DIR/chains"
MEMORY_DIR="$SKILL_DIR/memory"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$CHAINS_DIR" "$MEMORY_DIR"

usage() {
    echo "Usage: $0 <natural-language-description> [--output <file>]"
    echo ""
    echo "Plan a tool chain from natural language description."
    echo ""
    echo "Examples:"
    echo "  $0 \"read file, process data, and save results\""
    echo "  $0 \"search web, fetch pages, extract content, summarize\" --output my-chain.json"
    echo ""
    exit 1
}

# Parse arguments
DESCRIPTION=""
OUTPUT_FILE=""

if [ $# -eq 0 ]; then
    usage
fi

DESCRIPTION="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
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

echo -e "${BLUE}Planning tool chain from description...${NC}"
echo "Description: $DESCRIPTION"
echo ""

# Generate chain ID
CHAIN_ID="chain-$(date +%s)"

# Extract tools from description using keyword matching
declare -A TOOL_NAMES
declare -A TOOL_PARAMS
TOOL_ORDER=()
TOOL_ID=0

# Function to add a tool to the chain
add_tool() {
    local name="$1"
    local params="$2"
    local deps="$3"

    local tool_id="tool-$TOOL_ID"
    TOOL_NAMES[$tool_id]="$name"
    TOOL_PARAMS[$tool_id]="$params"
    TOOL_ORDER+=("$tool_id")

    echo "  Detected tool: $name"
    TOOL_ID=$((TOOL_ID + 1))
}

# Analyze description and extract tools
lower_desc=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')

# Check for common tool patterns
if echo "$lower_desc" | grep -q "read.*file\|file.*read"; then
    add_tool "read" '{"path": "/tmp/data.txt"}' ""
fi

if echo "$lower_desc" | grep -q "write.*file\|save.*file\|file.*write\|file.*save"; then
    add_tool "write" '{"path": "/tmp/output.txt", "content": "processed_data"}' ""
fi

if echo "$lower_desc" | grep -q "search.*web\|web.*search\|google\|search"; then
    add_tool "web_search" '{"query": "search terms"}' ""
fi

if echo "$lower_desc" | grep -q "fetch.*page\|download\|get.*url\|url.*get"; then
    add_tool "web_fetch" '{"url": "https://example.com"}' ""
fi

if echo "$lower_desc" | grep -q "extract\|parse\|analyze\|process.*data"; then
    add_tool "process" '{"input": "data"}' ""
fi

if echo "$lower_desc" | grep -q "summarize\|summary\|condense"; then
    add_tool "summarize" '{"text": "content"}' ""
fi

if echo "$lower_desc" | grep -q "exec\|run.*command\|command.*run\|shell"; then
    add_tool "exec" '{"command": "echo hello"}' ""
fi

if echo "$lower_desc" | grep -q "send.*message\|message.*send\|notify\|alert"; then
    add_tool "message" '{"text": "notification"}' ""
fi

# If no tools detected, create a generic one
if [ ${#TOOL_ORDER[@]} -eq 0 ]; then
    add_tool "generic" '{"action": "execute_task"}' ""
    echo "  No specific tools detected, created generic task"
fi

echo ""
echo -e "${GREEN}Detected ${#TOOL_ORDER[@]} tool(s)${NC}"

# Determine dependencies (simple sequential for now)
if [ ${#TOOL_ORDER[@]} -gt 1 ]; then
    echo "Building execution order..."
    for i in $(seq 1 $((${#TOOL_ORDER[@]} - 1))); do
        echo "  ${TOOL_ORDER[$i]} depends on ${TOOL_ORDER[$((i-1))]}"
    done
fi

# Build JSON chain
CHAIN_JSON=$(cat <<EOF
{
  "id": "$CHAIN_ID",
  "name": "Planned Chain",
  "description": "$DESCRIPTION",
  "created_at": "$(date -Iseconds)",
  "tools": [
EOF
)

# Add tools to JSON
first=true
for i in "${!TOOL_ORDER[@]}"; do
    tool_id="${TOOL_ORDER[$i]}"
    tool_name="${TOOL_NAMES[$tool_id]}"
    tool_params="${TOOL_PARAMS[$tool_id]}"
    
    if [ "$first" = true ]; then
        first=false
    else
        CHAIN_JSON+=","
    fi

    # Build dependencies array
    if [ $i -gt 0 ]; then
        prev_tool="${TOOL_ORDER[$((i-1))]}"
        deps="\"$prev_tool\""
    else
        deps=""
    fi

    CHAIN_JSON+=$(cat <<EOF

    {
      "id": "$tool_id",
      "name": "$tool_name",
      "params": $tool_params,
      "depends_on": [$deps]
    }
EOF
)
done

CHAIN_JSON+=$(cat <<EOF

  ],
  "config": {
    "max_parallel": 3,
    "retry_count": 2,
    "timeout": 30,
    "on_error": "continue"
  }
}
EOF
)

# Determine output file
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="$CHAINS_DIR/$CHAIN_ID.json"
fi

# Save chain
echo "$CHAIN_JSON" | jq '.' > "$OUTPUT_FILE" 2>/dev/null || echo "$CHAIN_JSON" > "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}✓ Chain saved to: $OUTPUT_FILE${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and edit the chain: $OUTPUT_FILE"
echo "  2. Visualize: ./scripts/visualize.sh $CHAIN_ID"
echo "  3. Execute: ./scripts/run.sh $CHAIN_ID"

exit 0
