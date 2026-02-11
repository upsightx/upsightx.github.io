#!/bin/bash
# 任务优先级计算脚本

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
TASKS_JSON="$MEMORY_DIR/tasks.json"
USER_BEHAVIOR="$MEMORY_DIR/user-behavior.json"

# 任务类型权重
declare -A TYPE_WEIGHTS=(
  ["critical"]=10.0
  ["high"]=8.0
  ["medium"]=5.0
  ["low"]=3.0
  ["periodic"]=6.0
)

# 获取系统负载
get_system_load() {
  local load=$(cat /proc/loadavg | awk '{print $1}')
  echo "$load"
}

# 获取用户活跃状态
is_user_active() {
  # 检查最近用户消息时间
  local last_msg=$(jq -r '.lastUserMessage // "empty"' "$USER_BEHAVIOR" 2>/dev/null)
  if [ "$last_msg" = "empty" ] || [ -z "$last_msg" ]; then
    return 1 # 不活跃
  fi
  
  local now=$(date +%s)
  local last=$(date -d "$last_msg" +%s 2>/dev/null || echo "0")
  local diff=$((now - last))
  
  # 10分钟内有消息 = 活跃
  if [ $diff -lt 600 ]; then
    return 0 # 活跃
  else
    return 1 # 不活跃
  fi
}

# 计算任务优先级
calculate_priority() {
  local task_id=$1
  local task_type=$2
  local waiting_hours=$3
  
  # 基础优先级
  local base=${TYPE_WEIGHTS[$task_type]:-5.0}
  
  # 因子1: 用户活跃状态
  if is_user_active; then
    local user_factor=0.8  # 用户活跃时降低优先级
  else
    local user_factor=1.2  # 用户不活跃时提高优先级
  fi
  
  # 因子2: 系统负载
  local load=$(get_system_load)
  local load_factor=$(echo "scale=2; 1.3 - $load" | bc)
  # 限制在 0.8-1.3 范围
  if (( $(echo "$load_factor < 0.8" | bc -l) )); then
    load_factor=0.8
  fi
  if (( $(echo "$load_factor > 1.3" | bc -l) )); then
    load_factor=1.3
  fi
  
  # 因子3: 等待时间（每小时+0.2）
  local wait_hours=${waiting_hours:-0}
  local wait_factor=$(echo "scale=2; 1.0 + $wait_hours * 0.2" | bc)
  
  # 最终分数
  local final=$(echo "scale=2; $base * $user_factor * $load_factor * $wait_factor" | bc)
  
  # 输出 JSON
  cat << EOF
{
  "taskId": "$task_id",
  "basePriority": "$task_type",
  "baseScore": $base,
  "factors": {
    "userActive": $(is_user_active && echo "true" || echo "false"),
    "systemLoad": $load,
    "loadFactor": $load_factor,
    "waitingHours": $wait_hours,
    "waitFactor": $wait_factor
  },
  "finalScore": $final
}
EOF
}

# 主函数
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "用法: $0 <task-id> <priority-type> <waiting-hours>"
  echo ""
  echo "示例: $0 task-1 high 2.5"
  exit 1
fi

calculate_priority "$1" "$2" "$3"
