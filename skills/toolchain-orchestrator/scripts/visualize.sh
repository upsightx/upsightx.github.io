#!/bin/bash
# visualize.sh - Visualize chain execution graph

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
    echo "Usage: $0 <chain-id> [--show-results]"
    echo ""
    echo "Visualize a tool chain execution graph."
    echo ""
    echo "Examples:"
    echo "  $0 chain-001"
    echo "  $0 chain-001 --show-results"
    echo ""
    exit 1
}

# Parse arguments
CHAIN_ID=""
SHOW_RESULTS=false

if [ $# -eq 0 ]; then
    usage
fi

CHAIN_ID="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --show-results|-r)
            SHOW_RESULTS=true
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
    echo ""
    echo "Available chains:"
    ls -1 "$CHAINS_DIR"/*.json 2>/dev/null | sed 's|.*/||' | sed 's|\.json||'
    exit 1
fi

# Load chain
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq not found, using fallback parsing${NC}"
    CHAIN_DATA=$(cat "$CHAIN_FILE")
else
    CHAIN_DATA=$(cat "$CHAIN_FILE")
fi

# Extract chain info
CHAIN_NAME=$(echo "$CHAIN_DATA" | jq -r '.name // "Unnamed Chain"' 2>/dev/null || echo "Unnamed Chain")
CHAIN_DESC=$(echo "$CHAIN_DATA" | jq -r '.description // "No description"' 2>/dev/null || echo "No description")
MAX_PARALLEL=$(echo "$CHAIN_DATA" | jq -r '.config.max_parallel // 3' 2>/dev/null || echo "3")

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Tool Chain Visualization${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Chain ID:${NC}     $CHAIN_ID"
echo -e "${BLUE}Name:${NC}         $CHAIN_NAME"
echo -e "${BLUE}Description:${NC}  $CHAIN_DESC"
echo -e "${BLUE}Max Parallel:${NC} $MAX_PARALLEL"
echo ""

# Load execution results if requested
RESULTS_FILE="$MEMORY_DIR/$CHAIN_ID.json"
if $SHOW_RESULTS && [ -f "$RESULTS_FILE" ]; then
    RESULTS_DATA=$(cat "$RESULTS_FILE")
    STATUS=$(echo "$RESULTS_DATA" | jq -r '.status // "unknown"' 2>/dev/null)
    START_TIME=$(echo "$RESULTS_DATA" | jq -r '.started' 2>/dev/null)
    END_TIME=$(echo "$RESULTS_DATA" | jq -r '.ended' 2>/dev/null)
    
    echo -e "${CYAN}───────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}Execution Status:${NC} $STATUS"
    if [ -n "$START_TIME" ]; then
        echo -e "${BLUE}Started:${NC}        $START_TIME"
    fi
    if [ -n "$END_TIME" ]; then
        echo -e "${BLUE}Ended:${NC}          $END_TIME"
    fi
    echo ""
fi

# Extract tools
if command -v jq &> /dev/null; then
    TOOL_COUNT=$(echo "$CHAIN_DATA" | jq '.tools | length' 2>/dev/null || echo "0")
    
    if [ "$TOOL_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}No tools defined in chain${NC}"
        exit 0
    fi
    
    echo -e "${CYAN}═ Execution Graph ═${NC}"
    echo ""
    
    # Build execution order and levels
    declare -A tool_level
    declare -A tool_deps
    declare -A tool_name
    
    for i in $(seq 0 $((TOOL_COUNT - 1))); do
        tool_id=$(echo "$CHAIN_DATA" | jq -r ".tools[$i].id" 2>/dev/null)
        tool_name[$tool_id]=$(echo "$CHAIN_DATA" | jq -r ".tools[$i].name" 2>/dev/null)
        deps_json=$(echo "$CHAIN_DATA" | jq -c ".tools[$i].depends_on" 2>/dev/null)
        
        # Parse dependencies
        if [ "$deps_json" = "null" ] || [ "$deps_json" = "[]" ]; then
            tool_level[$tool_id]=0
            tool_deps[$tool_id]=""
        else
            # Get count of dependencies
            dep_count=$(echo "$deps_json" | jq 'length' 2>/dev/null || echo "0")
            tool_deps[$tool_id]=""
            max_dep_level=0
            
            for j in $(seq 0 $((dep_count - 1))); do
                dep_id=$(echo "$deps_json" | jq -r ".[$j]" 2>/dev/null)
                if [ -n "$tool_deps[$tool_id]" ]; then
                    tool_deps[$tool_id]+=", $dep_id"
                else
                    tool_deps[$tool_id]="$dep_id"
                fi
                
                # Level is max dependency level + 1
                if [ -n "${tool_level[$dep_id]}" ]; then
                    if [ ${tool_level[$dep_id]} -gt $max_dep_level ]; then
                        max_dep_level=${tool_level[$dep_id]}
                    fi
                fi
            done
            tool_level[$tool_id]=$((max_dep_level + 1))
        fi
    done
    
    # Group tools by level for parallel execution
    max_level=0
    for tool_id in "${!tool_level[@]}"; do
        if [ ${tool_level[$tool_id]} -gt $max_level ]; then
            max_level=${tool_level[$tool_id]}
        fi
    done
    
    # Display by level
    for level in $(seq 0 $max_level); do
        level_tools=()
        for tool_id in "${!tool_level[@]}"; do
            if [ ${tool_level[$tool_id]} -eq $level ]; then
                level_tools+=("$tool_id")
            fi
        done
        
        if [ ${#level_tools[@]} -gt 0 ]; then
            echo -e "${BLUE}Level $level:${NC}"
            
            for tool_id in "${level_tools[@]}"; do
                # Get tool status from results
                tool_status=""
                tool_output=""
                if $SHOW_RESULTS && [ -f "$RESULTS_FILE" ]; then
                    tool_status=$(echo "$RESULTS_DATA" | jq -r ".results[\"$tool_id\"].status // \"pending\"" 2>/dev/null)
                    
                    # Color status
                    case "$tool_status" in
                        success|completed)
                            status_color="${GREEN}✓${NC}"
                            ;;
                        failed|error)
                            status_color="${RED}✗${NC}"
                            ;;
                        running|pending)
                            status_color="${YELLOW}○${NC}"
                            ;;
                        *)
                            status_color="${YELLOW}○${NC}"
                            ;;
                    esac
                else
                    status_color="${CYAN}○${NC}"
                fi
                
                # Show dependencies
                if [ -n "${tool_deps[$tool_id]}" ]; then
                    echo "  $status_color ${tool_id} (${tool_name[$tool_id]})"
                    echo "     └─ depends: ${tool_deps[$tool_id]}"
                else
                    echo "  $status_color ${tool_id} (${tool_name[$tool_id]})"
                fi
                
                # Show output summary if requested
                if $SHOW_RESULTS && [ -f "$RESULTS_FILE" ]; then
                    tool_output=$(echo "$RESULTS_DATA" | jq -r ".results[\"$tool_id\"].output // \"\"" 2>/dev/null)
                    if [ -n "$tool_output" ] && [ "$tool_output" != "null" ]; then
                        output_summary=$(echo "$tool_output" | head -c 80)
                        if [ ${#tool_output} -gt 80 ]; then
                            output_summary+="..."
                        fi
                        echo "     └─ output: ${output_summary}"
                    fi
                fi
            done
            
            if [ $level -lt $max_level ]; then
                echo "     ↓"
            fi
            echo ""
        fi
    done
    
    # Show parallel groups
    echo -e "${CYAN}═ Parallel Execution Groups ═${NC}"
    echo ""
    for level in $(seq 0 $max_level); do
        level_tools=()
        for tool_id in "${!tool_level[@]}"; do
            if [ ${tool_level[$tool_id]} -eq $level ]; then
                level_tools+=("$tool_id")
            fi
        done
        
        if [ ${#level_tools[@]} -gt 1 ]; then
            echo -e "${GREEN}Group $level (parallel, ${#level_tools[@]} tools):${NC}"
            for tool_id in "${level_tools[@]}"; do
                echo "  • $tool_id"
            done
            echo ""
        elif [ ${#level_tools[@]} -eq 1 ]; then
            echo -e "${YELLOW}Group $level (sequential):${NC}"
            for tool_id in "${level_tools[@]}"; do
                echo "  • $tool_id"
            done
            echo ""
        fi
    done
    
else
    # Fallback without jq - simple text display
    echo -e "${YELLOW}jq not available, showing raw file${NC}"
    cat "$CHAIN_FILE"
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
