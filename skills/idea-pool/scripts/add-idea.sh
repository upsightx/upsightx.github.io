#!/bin/bash
IDEA_POOL="/root/.openclaw/workspace/memory/idea-pool.json"
SOURCE="$1"
TYPE="$2"
DESCRIPTION="$3"
PRIORITY="${4:-medium}"

if [ -z "$SOURCE" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: ./add-idea.sh \"<source>\" <type> \"<description>\" [priority]"
    echo ""
    echo "Examples:"
    echo "  ./add-idea.sh \"AI News\" feature \"Implement task decomposition\" high"
    echo "  ./add-idea.sh \"User Feedback\" optimization \"Improve response speed\" medium"
    exit 1
fi

IDEA_ID="idea-$(date +%s%N)"
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq --arg id "$IDEA_ID" \
   --arg source "$SOURCE" \
   --arg type "$TYPE" \
   --arg desc "$DESCRIPTION" \
   --arg pri "$PRIORITY" \
   --arg time "$CURRENT_TIME" \
   '.ideas += [{id: $id, source: $source, type: $type, description: $desc, priority: $pri, feasibility: "medium", complexity: "medium", status: "pending", createdAt: $time, tags: []}] | \
   .metadata.lastUpdated = $time | \
   .metadata.totalIdeas += 1 | \
   .metadata.pendingIdeas += 1' \
   "$IDEA_POOL" > /tmp/idea-pool-temp.json && \
   mv /tmp/idea-pool-temp.json "$IDEA_POOL"

echo "✅ Idea added: $IDEA_ID"
echo "   Source: $SOURCE"
echo "   Type: $TYPE"
echo "   Priority: $PRIORITY"
echo "   Description: $DESCRIPTION"
