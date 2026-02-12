#!/bin/bash
IDEA_POOL="/root/.openclaw/workspace/memory/idea-pool.json"
IDEA_ID="$1"

if [ -z "$IDEA_ID" ]; then
    echo "Usage: ./convert-to-project.sh <idea-id>"
    echo ""
    echo "Available ideas:"
    jq -r '.ideas[] | select(.status == "pending") | "  \(.id) - \(.description)"' \
       "$IDEA_POOL"
    exit 1
fi

# Check if idea exists
IDEA_EXISTS=$(jq --arg id "$IDEA_ID" '.ideas[] | select(.id == $id) | length' "$IDEA_POOL")

if [ "$IDEA_EXISTS" == "0" ]; then
    echo "❌ Idea not found: $IDEA_ID"
    exit 1
fi

# Get idea details
SOURCE=$(jq -r --arg id "$IDEA_ID" '.ideas[] | select(.id == $id).source' "$IDEA_POOL")
TYPE=$(jq -r --arg id "$IDEA_ID" '.ideas[] | select(.id == $id).type' "$IDEA_POOL")
DESCRIPTION=$(jq -r --arg id "$IDEA_ID" '.ideas[] | select(.id == $id).description' "$IDEA_POOL")

PROJECT_DIR="/root/.openclaw/workspace/projects/$(echo $IDEA_ID | tr '-' '_')"

echo "💡 Converting idea to project..."
echo "   Source: $SOURCE"
echo "   Type: $TYPE"
echo "   Description: $DESCRIPTION"
echo "   Project: $PROJECT_DIR"
echo ""

# Create project directory
mkdir -p "$PROJECT_DIR"

# Generate project structure
cat > "$PROJECT_DIR/README.md" << EOF
# Project: $DESCRIPTION

**Source**: $SOURCE  
**Type**: $TYPE  
**Idea ID**: $IDEA_ID  
**Created**: $(date '+%Y-%m-%d %H:%M:%S')  

## Overview
This project is derived from an idea in the idea pool.

## Implementation Plan
1. Research requirements
2. Design solution
3. Implement core features
4. Test and iterate
5. Deploy and document

## Status
- [ ] Requirements research
- [ ] Solution design
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
EOF

echo "✅ Project structure created at: $PROJECT_DIR"

# Update idea status
echo ""
echo "📝 Updating idea status..."
jq --arg id "$IDEA_ID" --arg time "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
   '(.ideas |= map(if .id == $id then .status = "developing" | .updatedAt = $time else . end)) | \
    .metadata.lastUpdated = $time' \
   "$IDEA_POOL" > /tmp/idea-pool-temp.json && \
   mv /tmp/idea-pool-temp.json "$IDEA_POOL"

echo "✅ Idea status updated to 'developing'"
echo ""
echo "🚀 Project ready for development!"
