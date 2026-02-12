#!/bin/bash
IDEA_POOL="/root/.openclaw/workspace/memory/idea-pool.json"
STATUS_FILTER="${1:-all}"

if [ ! -f "$IDEA_POOL" ]; then
    echo "No idea pool found."
    exit 1
fi

echo "💡 Idea Pool"
echo ""

echo "📊 Summary:"
echo "   Total: $(jq '.metadata.totalIdeas' "$IDEA_POOL")"
echo "   Completed: $(jq '.metadata.completedIdeas' "$IDEA_POOL")"
echo "   Pending: $(jq '.metadata.pendingIdeas' "$IDEA_POOL")"
echo ""

if [ "$STATUS_FILTER" == "all" ] || [ "$STATUS_FILTER" == "pending" ]; then
    echo "📋 Pending Ideas:"
    echo ""
    jq -r '.ideas[] | select(.status == "pending") | "\(.id) [\(.priority)] \(.description) (\(.type))"' \
       "$IDEA_POOL" | while read line; do
        echo "   $line"
    done
fi

echo ""
echo "💡 Usage:"
echo "   ./add-idea.sh <source> <type> \"<description>\" [priority]"
echo "   ./extract-ideas.sh <source>"
echo "   ./convert-to-project.sh <idea-id>"
