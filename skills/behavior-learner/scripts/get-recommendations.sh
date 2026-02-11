#!/bin/bash
# 基于用户行为生成推荐
# 用法: ./get-recommendations.sh

BEHAVIOR_FILE="/root/.openclaw/workspace/memory/behavior-data.json"
CURRENT_HOUR=$(date +"%H")
CURRENT_DAY=$(date +"%a")

# 检查数据文件是否存在
if [ ! -f "$BEHAVIOR_FILE" ]; then
    echo "❌ No behavior data found. Run record-interaction.sh first."
    exit 1
fi

echo "🤖 智能推荐"
echo ""

# 1. 基于时段的推荐
echo "### 🕐 当前时段推荐 ($CURRENT_HOUR:00)"
echo ""

# 检查当前时段是否是用户的活跃时段
IS_ACTIVE=$(jq --arg day "$CURRENT_DAY" --argjson hour $CURRENT_HOUR '
    .activeHours[$day] // [] | index($hour)
' "$BEHAVIOR_FILE")

if [ "$IS_ACTIVE" != "null" ]; then
    echo "✅ 您现在通常很活跃，适合执行重要任务。"

    # 基于当前时段的历史命令推荐
    RECOMMENDED_CMD=$(jq -r --arg day "$CURRENT_DAY" --argjson hour $CURRENT_HOUR '
        [.interactions[] |
         select((.timestamp | fromdateiso8601 | strftime("%a")) == $day and
                (.timestamp | fromdateiso8601 | strftime("%H") | tonumber) == $hour)][0:3] |
         map(.command) | unique | join(", ")
    ' "$BEHAVIOR_FILE")

    if [ ! -z "$RECOMMENDED_CMD" ] && [ "$RECOMMENDED_CMD" != "null" ]; then
        echo "   💡 建议操作: $RECOMMENDED_CMD"
    fi
else
    echo "ℹ️  现在通常是您的空闲时间，可以安排系统维护或学习任务。"
fi

echo ""

# 2. 基于历史偏好的推荐
echo "### 📈 基于历史偏好"
echo ""

TOP_COMMANDS=$(jq -r '
    .commandStats | to_entries |
    sort_by(-.value) |
    .[:3] |
    map("\(.key) (\(.value) 次使用)") |
    join("\n- ")
' "$BEHAVIOR_FILE")

echo "- $TOP_COMMANDS"
echo ""

# 3. 预测性推荐
echo "### 🔮 预测下一步"
echo ""

LAST_INTERACTIONS=$(jq -r '
    .interactions[0:3] |
    map(.command) |
    unique |
    join(", ")
' "$BEHAVIOR_FILE")

if [ ! -z "$LAST_INTERACTIONS" ] && [ "$LAST_INTERACTIONS" != "null" ]; then
    echo "基于您最近的操作 ($LAST_INTERACTIONS)，您可能想："

    # 简单的模式匹配规则
    if echo "$LAST_INTERACTIONS" | grep -q "web_search"; then
        echo "   🔍 搜索更多相关信息"
    fi

    if echo "$LAST_INTERACTIONS" | grep -q "feishu"; then
        echo "   📄 继续处理飞书文档"
    fi

    if echo "$LAST_INTERACTIONS" | grep -q "sessions_spawn"; then
        echo "   🚀 启动更多子任务"
    fi
fi

echo ""
echo "---"
echo "💭 这些推荐基于您的历史行为数据。"
