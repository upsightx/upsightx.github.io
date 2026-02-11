#!/bin/bash
# 检查模型可用性和配置
# 用法: ./check-model.sh <model-id>

CONFIG_FILE="/root/.openclaw/workspace/skills/model-manager/config.json"
MODEL_ID="$1"

# 如果没有指定模型，显示所有模型
if [ -z "$MODEL_ID" ]; then
    echo "📊 所有模型状态："
    echo ""
    jq -r '.models | to_entries[] | "\(.key)\t\(.value.available)"' "$CONFIG_FILE" | \
        awk -F'\t' '{available=$2; gsub(/"/, "", available); if(available=="true") status="✅ 可用"; else status="❌ 不可用"; printf "%-35s %s\n", $1, status}'
    echo ""
    echo "用法: ./check-model.sh <model-id>"
    echo ""
    echo "可用模型："
    jq -r '.models | to_entries[] | select(.value.available==true) | "  - \(.key)"' "$CONFIG_FILE"
    exit 0
fi

# 检查模型是否存在
if ! jq -e ".models[\"$MODEL_ID\"]" "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ 未知的模型 ID: $MODEL_ID"
    echo ""
    echo "可用的模型："
    jq -r '.models | keys[]' "$CONFIG_FILE" | while read model; do
        echo "- $model"
    done
    exit 1
fi

# 获取模型信息
AVAILABLE=$(jq -r ".models[\"$MODEL_ID\"].available" "$CONFIG_FILE")
PROVIDER=$(jq -r ".models[\"$MODEL_ID\"].provider" "$CONFIG_FILE")
CONTEXT_WINDOW=$(jq -r ".models[\"$MODEL_ID\"].contextWindow" "$CONFIG_FILE")
STRENGTH=$(jq -r ".models[\"$MODEL_ID\"].strength" "$CONFIG_FILE")

# 计算成本
INPUT_COST=$(jq -r ".models[\"$MODEL_ID\"].cost.input" "$CONFIG_FILE")
OUTPUT_COST=$(jq -r ".models[\"$MODEL_ID\"].cost.output" "$CONFIG_FILE")

# 显示模型信息
if [ "$AVAILABLE" == "true" ]; then
    echo "✅ 模型: $MODEL_ID"
else
    echo "❌ 模型: $MODEL_ID"
fi
echo ""
echo "📋 详细信息:"
echo "  提供商: $PROVIDER"
echo "  上下文窗口: $CONTEXT_WINDOW tokens"
echo "  可用性: $AVAILABLE"
echo ""
echo "💪 优势: $STRENGTH"
echo ""
echo "💰 成本:"
echo "  输入: \$$INPUT_COST/1K tokens"
echo "  输出: \$$OUTPUT_COST/1K tokens"

# 如果是免费模型，显示特别说明
if [ "$INPUT_COST" == "0" ] && [ "$OUTPUT_COST" == "0" ]; then
    echo ""
    echo "🎉 此模型完全免费！"
fi
