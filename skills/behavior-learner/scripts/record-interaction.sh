#!/bin/bash
# 记录用户交互
# 用法: ./record-interaction.sh <command> <context>

BEHAVIOR_FILE="/root/.openclaw/workspace/memory/behavior-data.json"
COMMAND="$1"
CONTEXT="$2"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOUR=$(date +"%H")
DAY=$(date +"%a")

# 如果数据文件不存在，创建初始结构
if [ ! -f "$BEHAVIOR_FILE" ]; then
    echo '{"activeHours":{},"commandStats":{},"interactions":[],"lastUpdated":""}' > "$BEHAVIOR_FILE"
fi

# 记录活跃时段
# 使用 jq 更新 activeHours
jq --arg day "$DAY" --argjson hour $HOUR '
    if .activeHours[$day] == null then
        .activeHours[$day] = [$hour]
    else
        .activeHours[$day] |= if index($hour) == null then . + [$hour] else . end
    end
' "$BEHAVIOR_FILE" > /tmp/behavior-temp.json && mv /tmp/behavior-temp.json "$BEHAVIOR_FILE"

# 更新命令统计
jq --arg cmd "$COMMAND" '
    if .commandStats[$cmd] == null then
        .commandStats[$cmd] = 1
    else
        .commandStats[$cmd] += 1
    end
' "$BEHAVIOR_FILE" > /tmp/behavior-temp.json && mv /tmp/behavior-temp.json "$BEHAVIOR_FILE"

# 记录交互历史（保留最近 100 条）
jq --arg ts "$TIMESTAMP" --arg cmd "$COMMAND" --arg ctx "$CONTEXT" '
    .interactions |= [{timestamp: $ts, command: $cmd, context: $ctx}] + . | .[:100]
' "$BEHAVIOR_FILE" > /tmp/behavior-temp.json && mv /tmp/behavior-temp.json "$BEHAVIOR_FILE"

# 更新最后更新时间
jq --arg ts "$TIMESTAMP" '.lastUpdated = $ts' "$BEHAVIOR_FILE" > /tmp/behavior-temp.json && mv /tmp/behavior-temp.json "$BEHAVIOR_FILE"

echo "✓ Interaction recorded: $COMMAND (context: $CONTEXT)"
