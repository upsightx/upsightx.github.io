#!/bin/bash
# run.sh - Execute chains with monitoring

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
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <chain-id> [--dry-run] [--watch]"
    echo ""
    echo "Execute a tool chain with monitoring."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be executed without running"
    echo "  --watch      Monitor execution in real-time"
    echo ""
    echo "Examples:"
    echo "  $0 chain-001"
    echo "  $0 chain-001 --watch"
    echo "  $0 chain-001 --dry-run"
    echo ""
    exit 1
}

# Parse arguments
CHAIN_ID=""
DRY_RUN=false
WATCH=false

if [ $# -eq 0 ]; then
    usage
fi

CHAIN_ID="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --watch|-w)
            WATCH=true
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

# Load chain data
if command -v jq &> /dev/null; then
    CHAIN_NAME=$(jq -r '.name // "Unnamed Chain"' "$CHAIN_FILE")
    TOOL_COUNT=$(jq '.tools | length' "$CHAIN_FILE")
    MAX_PARALLEL=$(jq -r '.config.max_parallel // 3' "$CHAIN_FILE")
    RETRY_COUNT=$(jq -r '.config.retry_count // 2' "$CHAIN_FILE")
    TIMEOUT=$(jq -r '.config.timeout // 30' "$CHAIN_FILE")
    ON_ERROR=$(jq -r '.config.on_error // "continue"' "$CHAIN_FILE")
else
    echo -e "${RED}Error: jq is required for chain execution${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Executing Tool Chain${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Chain:${NC}        $CHAIN_NAME ($CHAIN_ID)"
echo -e "${BLUE}Tools:${NC}        $TOOL_COUNT"
echo -e "${BLUE}Max Parallel:${NC} $MAX_PARALLEL"
echo -e "${BLUE}Retry Count:${NC}  $RETRY_COUNT"
echo -e "${BLUE}Timeout:${NC}      ${TIMEOUT}s"
echo -e "${BLUE}On Error:${NC}     $ON_ERROR"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}═══ DRY RUN MODE - No tools will be executed ═══${NC}"
    echo ""
fi

# Create execution record
EXECUTION_ID="exec-$(date +%s)"
START_TIME=$(date -Iseconds)

EXECUTION_RECORD=$(cat <<EOF
{
  "id": "$EXECUTION_ID",
  "chain_id": "$CHAIN_ID",
  "chain_name": "$CHAIN_NAME",
  "status": "running",
  "started": "$START_TIME",
  "ended": null,
  "dry_run": $DRY_RUN,
  "config": {
    "max_parallel": $MAX_PARALLEL,
    "retry_count": $RETRY_COUNT,
    "timeout": $TIMEOUT,
    "on_error": "$ON_ERROR"
  },
  "results": {}
}
EOF
)

RESULTS_FILE="$MEMORY_DIR/$CHAIN_ID.json"
echo "$EXECUTION_RECORD" > "$RESULTS_FILE"

# Build tool dependency graph
declare -A tool_level
declare -A tool_deps
declare -A tool_name
declare -A tool_params

for i in $(seq 0 $((TOOL_COUNT - 1))); do
    tool_id=$(jq -r ".tools[$i].id" "$CHAIN_FILE")
    tool_name[$tool_id]=$(jq -r ".tools[$i].name" "$CHAIN_FILE")
    tool_params[$tool_id]=$(jq -c ".tools[$i].params // {}" "$CHAIN_FILE")
    
    deps_json=$(jq -c ".tools[$i].depends_on // []" "$CHAIN_FILE")
    dep_count=$(echo "$deps_json" | jq 'length')
    
    if [ "$dep_count" -eq 0 ]; then
        tool_level[$tool_id]=0
        tool_deps[$tool_id]=""
    else
        tool_deps[$tool_id]=$(echo "$deps_json" | jq -r 'join(", ")')
        max_dep_level=0
        
        for j in $(seq 0 $((dep_count - 1))); do
            dep_id=$(echo "$deps_json" | jq -r ".[$j]")
            if [ -n "${tool_level[$dep_id]}" ]; then
                if [ ${tool_level[$dep_id]} -gt $max_dep_level ]; then
                    max_dep_level=${tool_level[$dep_id]}
                fi
            fi
        done
        tool_level[$tool_id]=$((max_dep_level + 1))
    fi
done

# Find max level
max_level=0
for tool_id in "${!tool_level[@]}"; do
    if [ ${tool_level[$tool_id]} -gt $max_level ]; then
        max_level=${tool_level[$tool_id]}
    fi
done

# Execute by level
ERROR_OCCURRED=false

for level in $(seq 0 $max_level); do
    level_tools=()
    for tool_id in "${!tool_level[@]}"; do
        if [ ${tool_level[$tool_id]} -eq $level ]; then
            level_tools+=("$tool_id")
        fi
    done
    
    if [ ${#level_tools[@]} -eq 0 ]; then
        continue
    fi
    
    echo -e "${BLUE}Level $level: ${#level_tools[@]} tool(s)${NC}"
    
    for tool_id in "${level_tools[@]}"; do
        echo -e "${CYAN}  Executing: ${tool_id} (${tool_name[$tool_id]})${NC}"
        
        if [ -n "${tool_deps[$tool_id]}" ]; then
            echo "    Dependencies: ${tool_deps[$tool_id]}"
        fi
        
        if $DRY_RUN; then
            # In dry run mode, just log
            tool_result='{"status": "skipped", "output": "Dry run mode", "started": "'$(date -Iseconds)'", "ended": "'$(date -Iseconds)'"}'
            echo "    ${YELLOW}[DRY RUN] Would execute with params: ${tool_params[$tool_id]}${NC}"
        else
            # Simulate tool execution
            tool_start=$(date -Iseconds)
            
            # Check for dependency results
            can_execute=true
            if [ -n "${tool_deps[$tool_id]}" ]; then
                IFS=', ' read -ra DEP_ARRAY <<< "${tool_deps[$tool_id]}"
                for dep in "${DEP_ARRAY[@]}"; do
                    dep_status=$(jq -r ".results[\"$dep\"].status" "$RESULTS_FILE" 2>/dev/null)
                    if [ "$dep_status" = "failed" ]; then
                        can_execute=false
                        break
                    fi
                done
            fi
            
            if ! $can_execute; then
                echo "    ${RED}Skipping: dependency failed${NC}"
                tool_result='{"status": "skipped", "output": "Dependency failed", "started": "'"$tool_start"'", "ended": "'$(date -Iseconds)'"}'
                ERROR_OCCURRED=true
            else
                # Execute the tool (simulation)
                echo "    ${GREEN}[EXECUTING]${NC}"
                
                # Simulate tool execution based on name
                tool_output="Executed ${tool_name[$tool_id]} successfully"
                tool_status="success"
                
                # Simulate some tools failing for demo
                if [[ "$tool_id" == *"fail"* ]]; then
                    tool_output="Simulated failure for demo purposes"
                    tool_status="failed"
                    ERROR_OCCURRED=true
                fi
                
                tool_end=$(date -Iseconds)
                tool_result=$(cat <<EOF
{
  "status": "$tool_status",
  "output": "$tool_output",
  "started": "$tool_start",
  "ended": "$tool_end"
}
EOF
)
                
                if [ "$tool_status" = "success" ]; then
                    echo "    ${GREEN}✓ Success${NC}"
                else
                    echo "    ${RED}✗ Failed: $tool_output${NC}"
                    
                    if [ "$ON_ERROR" = "stop" ]; then
                        echo -e "${RED}Halting chain due to error${NC}"
                        break 3
                    fi
                fi
            fi
        fi
        
        # Update results in file
        temp_file=$(mktemp)
        jq ".results[\"$tool_id\"] = $tool_result" "$RESULTS_FILE" > "$temp_file"
        mv "$temp_file" "$RESULTS_FILE"
    done
    
    echo ""
done

# Finalize execution
END_TIME=$(date -Iseconds)
if $ERROR_OCCURRED; then
    FINAL_STATUS="failed"
else
    FINAL_STATUS="completed"
fi

# Update execution record
temp_file=$(mktemp)
jq ".status = \"$FINAL_STATUS\" | .ended = \"$END_TIME\"" "$RESULTS_FILE" > "$temp_file"
mv "$temp_file" "$RESULTS_FILE"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Execution completed:${NC} $FINAL_STATUS"
echo -e "${BLUE}Duration:${NC}         $(date -d "$START_TIME" +%s 2>/dev/null || echo 0) to $(date -d "$END_TIME" +%s 2>/dev/null || echo 0)"
echo -e "${BLUE}Results:${NC}         $RESULTS_FILE"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
