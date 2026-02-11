#!/bin/bash
# 任务列表管理 - 添加、删除、列出任务

TASKS_FILE="${WORKSPACE:-/root/.openclaw/workspace}/memory/tasks.json"

# 初始化任务文件
init_tasks() {
  if [ ! -f "$TASKS_FILE" ]; then
    echo '[]' > "$TASKS_FILE"
  fi
}

# 添加任务
add_task() {
  local id=$1
  local name=$2
  local priority=$3
  local description=$4
  local interval=$5
  
  local created=$(date -Iseconds)
  
  # 使用 jq 添加任务到数组
  cat "$TASKS_FILE" | jq --arg id "$id" \
     --arg name "$name" \
     --arg priority "$priority" \
     --arg desc "$description" \
     --arg interval "$interval" \
     --arg created "$created" \
     '. + [{
       "id": $id,
       "name": $name,
       "priority": $priority,
       "description": $desc,
       "interval": ($interval | tonumber),
       "createdAt": $created,
       "status": "pending",
       "completedAt": null,
       "waitingHours": 0
     }]' > "${TASKS_FILE}.tmp" \
     && mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
  
  echo "✅ 任务已添加: $name (ID: $id)"
}

# 列出任务
list_tasks() {
  echo "📋 任务列表（按优先级排序）"
  echo ""
  
  # 按优先级排序并输出
  jq -r '.[] | "\(.id) | \(.name) | \(.priority) | \(.createdAt)"' "$TASKS_FILE" 2>/dev/null | \
  while IFS='|' read -r id name priority created; do
    # 计算等待小时数
    now=$(date +%s)
    created_ts=$(date -d "$created" +%s 2>/dev/null || echo "$now")
    hours=$(echo "scale=2; ($now - $created_ts) / 3600" | bc 2>/dev/null || echo "0")
    
    # 计算优先级分数
    score=$(bash /root/.openclaw/workspace/skills/priority-manager/scripts/calc-priority.sh "$id" "$priority" "$hours" 2>/dev/null | jq -r '.finalScore' 2>/dev/null || echo "0")
    
    # 格式化输出
    printf "%-20s %-30s %10s %8.2f\n" "$id" "$name" "$priority" "$score"
  done
}

# 删除任务
remove_task() {
  local id=$1
  
  cat "$TASKS_FILE" | jq --arg id "$id" 'del(.[] | select(.id == $id))' > "${TASKS_FILE}.tmp" \
    && mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
  
  echo "🗑️ 任务已删除: $id"
}

# 主函数
init_tasks

case "$1" in
  add)
    if [ $# -lt 4 ]; then
      echo "用法: $0 add <id> <name> <priority> <description> [interval]"
      echo "优先级: critical/high/medium/low/periodic"
      exit 1
    fi
    add_task "$2" "$3" "$4" "$5" "$6"
    ;;
  list)
    list_tasks
    ;;
  remove)
    if [ $# -lt 2 ]; then
      echo "用法: $0 remove <task-id>"
      exit 1
    fi
    remove_task "$2"
    ;;
  *)
    echo "任务管理工具"
    echo ""
    echo "用法:"
    echo "  $0 add <id> <name> <priority> <description> [interval]"
    echo "  $0 list                           列出所有任务（按优先级排序）"
    echo "  $0 remove <task-id>               删除任务"
    echo ""
    echo "示例:"
    echo "  $0 add backup-1 \"每日备份\" high \"备份重要文件\" 24"
    echo "  $0 list"
    ;;
esac
