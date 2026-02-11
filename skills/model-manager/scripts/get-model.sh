#!/bin/bash
# 根据任务类型推荐模型
# 用法: ./get-model.sh <task-type>

CONFIG_FILE="/root/.openclaw/workspace/skills/model-manager/config.json"
TASK_TYPE="$1"

# 如果没有指定任务类型，显示所有可用的任务类型
if [ -z "$TASK_TYPE" ]; then
    echo "📋 可用的任务类型："
    echo ""
    jq -r '.taskRouting | keys[]' "$CONFIG_FILE" | while read type; do
        echo "- $type"
        jq -r ".taskRouting[\"$type\"].tasks | join(\", \")" "$CONFIG_FILE" | xargs -I {} echo "  → {}"
    done
    echo ""
    echo "用法: ./get-model.sh <task-type>"
    exit 0
fi

# 检查任务类型是否存在
if ! jq -e ".taskRouting[\"$TASK_TYPE\"]" "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ 未知的任务类型: $TASK_TYPE"
    echo ""
    echo "可用的任务类型："
    jq -r '.taskRouting | keys[]' "$CONFIG_FILE" | while read type; do
        echo "- $type"
    done
    exit 1
fi

# 获取推荐模型
RECOMMENDED_MODEL=$(jq -r ".taskRouting[\"$TASK_TYPE\"].model" "$CONFIG_FILE")
REASON=$(jq -r ".taskRouting[\"$TASK_TYPE\"].reason" "$CONFIG_FILE")
TASKS=$(jq -r ".taskRouting[\"$TASK_TYPE\"].tasks | join(\", \")" "$CONFIG_FILE")

# 获取备用模型链
FALLBACK1=$(jq -r '.fallbackChain.fallback1' "$CONFIG_FILE")
FALLBACK2=$(jq -r '.fallbackChain.fallback2' "$CONFIG_FILE")

echo "🎯 任务类型: $TASK_TYPE"
echo ""
echo "📝 适用任务: $TASKS"
echo ""
echo "✅ 推荐模型: $RECOMMENDED_MODEL"
echo "💡 原因: $REASON"
echo ""
echo "🔄 备用模型链:"
echo "  1. $RECOMMENDED_MODEL (首选)"
echo "  2. $FALLBACK1"
echo "  3. $FALLBACK2"
echo ""
echo "💰 成本估算:"
jq -r ".models[\"$RECOMMENDED_MODEL\"].cost" "$CONFIG_FILE" | jq -r 'to_entries | map("  \(.key): $\(.value)/1K tokens") | join("\n")'
