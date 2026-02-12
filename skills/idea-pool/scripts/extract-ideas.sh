#!/bin/bash
IDEA_POOL="/root/.openclaw/workspace/memory/idea-pool.json"
SOURCE="$1"

if [ -z "$SOURCE" ]; then
    echo "Usage: ./extract-ideas.sh <source>"
    echo ""
    echo "Examples:"
    echo "  ./extract-ideas.sh \"AI News: Claude Opus 4.6\""
    echo "  ./extract-ideas.sh \"User Feedback\""
    exit 1
fi

echo "🔍 Extracting ideas from: $SOURCE"
echo ""

# AI资讯启发
if [[ "$SOURCE" == *"AI"* ]] || [[ "$SOURCE" == *"news"* ]]; then
    echo "Detected AI news source. Suggested ideas:"
    echo ""
    echo "1. Task Decomposition (feature) - Implement like Claude Opus 4.6 Agent Teams"
    echo "2. Parallel Task Execution (feature) - Use sessions_spawn for parallelism"
    echo "3. Enhanced Context Window (feature) - Support longer conversations"
    echo ""
    echo "Add these ideas? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "AI News" "feature" "Implement task decomposition - split large tasks into parallel subtasks" "high"
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "AI News" "feature" "Implement parallel task execution using sessions_spawn" "high"
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "AI News" "feature" "Enhance context window support for longer conversations" "medium"
    fi

# 用户反馈启发
elif [[ "$SOURCE" == *"user"* ]] || [[ "$SOURCE" == *"feedback"* ]]; then
    echo "Detected user feedback source. Common themes:"
    echo ""
    echo "1. Response Speed (optimization) - Optimize response time"
    echo "2. Cost Control (feature) - Better API cost management"
    echo "3. User Experience (feature) - Improve interaction flow"
    echo ""
    echo "Add these ideas? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "User Feedback" "optimization" "Optimize response speed for better UX" "medium"
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "User Feedback" "feature" "Implement better API cost control and monitoring" "high"
    fi

# 技术动态启发
elif [[ "$SOURCE" == *"tech"* ]] || [[ "$SOURCE" == *"framework"* ]]; then
    echo "Detected tech/framework source. Integration ideas:"
    echo ""
    echo "1. MCP Integration (integration) - Add Model Context Protocol support"
    echo "2. Tool Marketplace (feature) - Community-contributed tools"
    echo "3. Plugin System (feature) - Modular plugin architecture"
    echo ""
    echo "Add these ideas? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "Tech Trend" "integration" "Add MCP (Model Context Protocol) support for better tool integration" "high"
        /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "Tech Trend" "feature" "Implement tool marketplace for community contributions" "medium"
    fi
else
    echo "Source type not recognized. Adding as general idea..."
    /root/.openclaw/workspace/skills/idea-pool/scripts/add-idea.sh "$SOURCE" "research" "Explore and implement features inspired by: $SOURCE" "medium"
fi

echo ""
echo "✅ Ideas extracted and added to pool!"
