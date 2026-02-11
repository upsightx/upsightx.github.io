#!/bin/bash
# 技能协作机制 - 事件发送脚本

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
EVENTS_LOG="$MEMORY_DIR/skills-events.json"
SKILLS_REGISTRY="$MEMORY_DIR/skill-registrations.json"

# 初始化文件
init() {
  if [ ! -f "$EVENTS_LOG" ]; then
    echo '{"events": []}' > "$EVENTS_LOG"
  fi
  if [ ! -f "$SKILLS_REGISTRY" ]; then
    echo '{"skills": []}' > "$SKILLS_REGISTRY"
  fi
}

# 发送事件
emit_event() {
  local event_type=$1
  local payload=$2
  local source=${3:-"unknown"}
  
  local timestamp=$(date -Iseconds)
  
  # 构建事件 JSON
  local event_json=$(cat << EOF
{
  "id": "event-$(date +%s%N)",
  "type": "$event_type",
  "payload": $payload,
  "source": "$source",
  "timestamp": "$timestamp"
}
EOF
)
  
  # 写入事件日志
  jq --argjson event "$event_json" '.events += [$event]' "$EVENTS_LOG" > "${EVENTS_LOG}.tmp" \
    && mv "${EVENTS_LOG}.tmp" "$EVENTS_LOG"
  
  echo "✅ 事件已发送: $event_type (来自: $source)"
  
  # 查找订阅了此事件的技能
  local subscribers=$(jq -r --arg type "$event_type" '.skills[] | select(.events[]? == $type) | .id' "$SKILLS_REGISTRY" 2>/dev/null)
  
  if [ -n "$subscribers" ]; then
    echo "📨 通知订阅者: $subscribers"
    
    # 触发订阅的技能
    for skill_id in $subscribers; do
      echo "   → 触发技能: $skill_id"
      
      # 查找技能路径
      local skill_path=$(jq -r --arg id "$skill_id" '.skills[] | select(.id == $id) | .path' "$SKILLS_REGISTRY")
      
      if [ -n "$skill_path" ] && [ -d "$skill_path" ]; then
        # 查找触发脚本
        local trigger_script="$skill_path/scripts/on-event.sh"
        if [ -f "$trigger_script" ]; then
          bash "$trigger_script" "$event_type" "$payload" "$source"
        fi
      fi
    done
  fi
}

# 主函数
init

case "$1" in
  topic-picked|task-created|task-completed|idle-triggered|user-active)
    if [ -z "$2" ]; then
      echo "用法: $0 <event-type> <json-payload> [source]"
      echo ""
      echo "事件类型:"
      echo "  topic-picked    - 选题完成"
      echo "  task-created     - 任务创建"
      echo "  task-completed  - 任务完成"
      echo "  idle-triggered  - 空闲触发"
      echo "  user-active      - 用户活跃"
      exit 1
    fi
    emit_event "$1" "$2" "$3"
    ;;
  *)
    echo "技能事件发送器"
    echo ""
    echo "用法: $0 <event-type> <json-payload> [source]"
    echo ""
    echo "示例:"
    echo "  $0 topic-picked '{\"topics\":[\"topic-1\",\"topic-3\"]}' 'topic-picker'"
    ;;
esac
