#!/bin/bash
# 技能注册 - 让技能订阅事件

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
SKILLS_REGISTRY="$MEMORY_DIR/skill-registrations.json"

# 初始化
if [ ! -f "$SKILLS_REGISTRY" ]; then
  echo '{"skills": []}' > "$SKILLS_REGISTRY"
fi

# 注册技能
register_skill() {
  local skill_id=$1
  local skill_name=$2
  local skill_path=$3
  local events=$4
  
  # 创建技能 JSON
  cat > "/tmp/new-skill.json" << EOF
{
  "id": "$skill_id",
  "name": "$skill_name",
  "path": "$skill_path",
  "events": $events,
  "registeredAt": "$(date -Iseconds)",
  "status": "active"
}
EOF
  
  # 合并到注册表（使用 bash + cat 替代 jq 的复杂操作）
  local current=$(cat "$SKILLS_REGISTRY")
  local new_skill=$(cat /tmp/new-skill.json)
  
  # 手动合并 JSON
  python3 << PYTHON_SCRIPT 2>/dev/null || true
import json
with open("$SKILLS_REGISTRY") as f:
    data = json.load(f)
with open("/tmp/new-skill.json") as f:
    new = json.load(f)
    data["skills"].append(new)
with open("$SKILLS_REGISTRY", "w") as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
  
  echo "✅ 技能已注册: $skill_name (ID: $skill_id)"
  echo "   订阅事件: $events"
}

# 列出技能
list_skills() {
  echo "📋 已注册的技能"
  echo ""
  python3 << PYTHON_SCRIPT 2>/dev/null || true
import json
with open("$SKILLS_REGISTRY") as f:
    data = json.load(f)
    for skill in data["skills"]:
        events = ", ".join(skill["events"])
        print(f"{skill['id']:<20} {skill['name']:<30}")
        print(f"   路径: {skill['path']}")
        print(f"   订阅: {events}")
        print()
PYTHON_SCRIPT
}

# 移除技能
unregister_skill() {
  local skill_id=$1
  
  python3 << PYTHON_SCRIPT 2>/dev/null || true
import json
with open("$SKILLS_REGISTRY") as f:
    data = json.load(f)
    data["skills"] = [s for s in data["skills"] if s["id"] != "$skill_id"]
with open("$SKILLS_REGISTRY", "w") as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
  
  echo "🗑️ 技能已移除: $skill_id"
}

# 主函数
case "$1" in
  register)
    if [ $# -lt 5 ]; then
      echo "用法: $0 register <skill-id> <skill-name> <skill-path> <events>"
      echo ""
      echo "示例:"
      echo "  $0 register priority-manager \"优先级管理\" /root/.openclaw/workspace/skills/priority-manager '[\"task-created\",\"task-completed\"]'"
      exit 1
    fi
    register_skill "$2" "$3" "$4" "$5"
    ;;
  list)
    list_skills
    ;;
  unregister)
    if [ $# -lt 2 ]; then
      echo "用法: $0 unregister <skill-id>"
      exit 1
    fi
    unregister_skill "$2"
    ;;
  *)
    echo "技能注册工具"
    echo ""
    echo "用法:"
    echo "  $0 register <id> <name> <path> <events>     注册技能"
    echo "  $0 list                                        列出所有技能"
    echo "  $0 unregister <id>                            移除技能"
    echo ""
    echo "事件类型:"
    echo "  topic-picked, task-created, task-completed, idle-triggered, user-active"
    ;;
esac
