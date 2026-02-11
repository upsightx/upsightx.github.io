#!/bin/bash
# 切换默认模型
# 用法: ./set-default-model.sh <model-id>

CONFIG_FILE="/root/.openclaw/openclaw.json"
MODEL_MANAGER_CONFIG="/root/.openclaw/workspace/skills/model-manager/config.json"
MODEL_ID="$1"

# 如果没有指定模型，显示当前默认模型和可用模型
if [ -z "$MODEL_ID" ]; then
    CURRENT_MODEL=$(jq -r '.agents.defaults.model.primary' "$CONFIG_FILE")
    echo "📋 当前默认模型: $CURRENT_MODEL"
    echo ""
    echo "可用的模型："
    jq -r '.models | keys[]' "$MODEL_MANAGER_CONFIG" | while read model; do
        AVAILABLE=$(jq -r ".models[\"$model\"].available" "$MODEL_MANAGER_CONFIG")
        if [ "$AVAILABLE" == "true" ]; then
            echo "  ✅ $model"
        else
            echo "  ❌ $model"
        fi
    done
    echo ""
    echo "用法: ./set-default-model.sh <model-id>"
    exit 0
fi

# 检查模型是否在 model-manager 配置中
if ! jq -e ".models[\"$MODEL_ID\"]" "$MODEL_MANAGER_CONFIG" > /dev/null 2>&1; then
    echo "❌ 未知的模型 ID: $MODEL_ID"
    echo ""
    echo "请使用 model-manager 中配置的模型："
    jq -r '.models | keys[]' "$MODEL_MANAGER_CONFIG"
    exit 1
fi

# 检查模型是否可用
AVAILABLE=$(jq -r ".models[\"$MODEL_ID\"].available" "$MODEL_MANAGER_CONFIG")
if [ "$AVAILABLE" != "true" ]; then
    echo "⚠️  模型 $MODEL_ID 当前不可用"
    exit 1
fi

# 备份配置文件
cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"

# 更新默认模型
jq --arg model "$MODEL_ID" '.agents.defaults.model.primary = $model' "$CONFIG_FILE" > /tmp/openclaw-temp.json && mv /tmp/openclaw-temp.json "$CONFIG_FILE"

echo "✅ 默认模型已更新为: $MODEL_ID"
echo ""
echo "⚠️  注意: 这需要重启 OpenClaw Gateway 才能生效"
echo ""
echo "运行以下命令重启："
echo "  openclaw gateway restart"
echo ""
echo "或者使用 gateway 工具："
echo "  使用 /reasoning 切换后触发重启"

# 显示模型信息
PROVIDER=$(jq -r ".models[\"$MODEL_ID\"].provider" "$MODEL_MANAGER_CONFIG")
STRENGTH=$(jq -r ".models[\"$MODEL_ID\"].strength" "$MODEL_MANAGER_CONFIG")
echo ""
echo "📋 模型信息:"
echo "  提供商: $PROVIDER"
echo "  优势: $STRENGTH"
