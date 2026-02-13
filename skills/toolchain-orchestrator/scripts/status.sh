#!/bin/bash
# status.sh - Check chain status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$SKILL_DIR/memory"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <chain-id> [--tools]"
    echo ""
    echo "Check chain execution status."
    echo ""
    echo "Options:"
    echo "  --tools    Show individual tool status"
    echo ""
    echo "Examples:"
    echo "  $0 chain-001"
    echo "  $0 chain-001 --tools"
    echo ""
    exit 1
}

# Parse arguments
CHAIN_ID=""
SHOW_TOOLS=false

if [ $# -eq 0 ]; then
    usage
fi

CHAIN_ID="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --tools|-t)
            SHOW_TOOLS=true
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

# Find results file
RESULTS_FILE="$MEMORY_DIR/$CHAIN_ID.json"

if [ ! -f "$RESULTS_FILE" ]; then
    echo -e "${RED}Error: No execution results found for chain: $CHAIN_ID${NC}"
    echo ""
    echo "Available chains with results:"
    ls -1 "$MEMORY_DIR"/*.json 2>/dev/null | sed 's|.*/||' | sed 's|\.json||'
    exit 1
fi

# Load results
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required for status display${NC}"
    cat "$RESULTS_FILE"
    exit 1
fi

# Extract status info
EXEC_ID=$(jq -r '.id // "unknown"' "$RESULTS_FILE")
CHAIN_NAME=$(jq -r '.chain_name // "Unknown"' "$RESULTS_FILE")
STATUS=$(jq -r '.status // "unknown"' "$RESULTS_FILE")
STARTED=$(jq -r '.started // "N/A"' "$RESULTS_FILE")
ENDED=$(jq -r '.ended // "N/A"' "$RESULTS_FILE")
DRY_RUN=$(jq -r '.dry_run // false' "$RESULTS_FILE")

# Status color
case "$STATUS" in
"completed")
    STATUS_COLOR="${GREEN}$STATUS${NC}"
    ;;
"running")
    STATUS_COLOR="${YELLOW}$STATUS${NC}"
    ;;
"failed")
    STATUS_COLOR="${RED}$STATUS${NC}"
    ;;
*)
    STATUS_COLOR="$STATUS"
    ;;
esac

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Chain Execution Status${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Chain:${NC}      $CHAIN_NAME ($CHAIN_ID)"
echo -e "${BLUE}Execution:${NC}  $EXEC_ID"
echo -e "${BLUE}Status:${NC}     $STATUS_COLOR"
echo -e "${BLUE}Started:${NC}    $STARTED"
echo -e "${BLUE}Ended:${NC}      $ENDED"

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${BLUE}Mode:${NC}       ${YELLOW}Dry Run${NC}"
fi

# Calculate duration
if [ "$ENDED" != "N/A" ] && [ "$ENDED" != "null" ] && [ "$STARTED" != "N/A" ]; then
    START_EPOCH=$(date -d "$STARTED" +%s 2>/dev/null || echo "0")
    END_EPOCH=$(date -d "$ENDED" +%s 2>/dev/null || echo "0")
    
    if [ "$START_EPOCH" != "0" ] && [ "$END_EPOCH" != "0" ]; then
        DURATION=$((END_EPOCH - START_EPOCH))
        echo -e "${BLUE}Duration:${NC}   ${DURATION}s"
    fi
fi

echo ""

# Show tool status if requested
if $SHOW_TOOLS; then
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Tool Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Get tool keys
    TOOLS=$(jq -r '.results | keys[]' "$RESULTS_FILE" 2>/dev/null)
    
    if [ -z "$TOOLS" ]; then
        echo "No tools executed yet"
    else
        for tool_id in $TOOLS; do
            tool_status=$(jq -r ".results[\"$tool_id\"].status // \"unknown\"" "$RESULTS_FILE")
            tool_started=$(jq -r ".results[\"$tool_id\"].started // \"N/A\"" "$RESULTS_FILE")
            tool_ended=$(jq -r ".results[\"$tool_id\"].ended // \"N/A\"" "$RESULTS_FILE")
            tool_output=$(jq -r ".results[\"$tool_id\"].output // \"\"" "$RESULTS_FILE")
            
            # Status indicator
            case "$tool_status" in
            "success"|"completed")
                status_indicator="${GREEN}✓${NC}"
                ;;
            "running")
                status_indicator="${YELLOW}○${NC}"
                ;;
            "failed")
                status_indicator="${RED}✗${NC}"
                ;;
            "skipped")
                status_indicator="${YELLOW}⊘${NC}"
                ;;
            *)
                status_indicator="${YELLOW}?${NC}"
                ;;
            esac
            
            echo -e "${status_indicator} ${tool_id}"
            echo "    Status:  $tool_status"
            echo "    Started: $tool_started"
            
            if [ "$tool_ended" != "N/A" ]; then
                echo "    Ended:   $tool_ended"
            fi
            
            if [ -n "$tool_output" ]; then
                output_preview=$(echo "$tool_output" | head -c 100)
                if [ ${#tool_output} -gt 100 ]; then
                    output_preview+="..."
                fi
                echo "    Output:  $output_preview"
            fi
            
            echo ""
        done
    fi
fi

# Show summary stats
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_TOOLS=$(jq '.results | length' "$RESULTS_FILE")
SUCCESS_TOOLS=$(jq '[.results[] | select(.status == "success")] | length' "$RESULTS_FILE")
FAILED_TOOLS=$(jq '[.results[] | select(.status == "failed")] | length' "$RESULTS_FILE")
SKIPPED_TOOLS=$(jq '[.results[] | select(.status == "skipped")] | length' "$RESULTS_FILE")

echo -e "${BLUE}Total Tools:${NC}   $TOTAL_TOOLS"
echo -e "${GREEN}Success:${NC}             $SUCCESS_TOOLS"
echo -e "${RED}Failed:${NC}        $FAILED_TOOLS"
echo -e "${YELLOW}Skipped:${NC}       $SKIPPED_TOOLS"
echo ""

# Show error details if any
if [ "$FAILED_TOOLS" -gt 0 ]; then
    echo -e "${RED}Errors:${NC}"
    TOOLS=$(jq -r '.results | keys[]' "$RESULTS_FILE" 2>/dev/null)
    for tool_id in $TOOLS; do
        tool_status=$(jq -r ".results[\"$tool_id\"].status // \"unknown\"" "$RESULTS_FILE")
        if [ "$tool_status" = "failed" ]; then
            tool_output=$(jq -r ".results[\"$tool_id\"].output // \"\"" "$RESULTS_FILE")
            echo "  • $tool_id: $tool_output"
        fi
    done
    echo ""
fi

exit 0
