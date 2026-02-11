#!/bin/bash
# 分析用户行为并生成报告
# 用法: ./analyze-behavior.sh

BEHAVIOR_FILE="/root/.openclaw/workspace/memory/behavior-data.json"
REPORT_FILE="/root/.openclaw/workspace/memory/behavior-report.md"

# 检查数据文件是否存在
if [ ! -f "$BEHAVIOR_FILE" ]; then
    echo "❌ No behavior data found. Run record-interaction.sh first."
    exit 1
fi

# 获取当前时间
CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

# 分析最活跃的时段
echo "# 用户行为分析报告" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**生成时间**: $CURRENT_TIME" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 📊 活跃时段分析" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo '```json' >> "$REPORT_FILE"
jq '.activeHours' "$BEHAVIOR_FILE" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 计算每个时段的总活跃次数
echo "### 最活跃时段" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
jq -r '
    .activeHours | to_entries[] |
    "\(.key): \(.value | length) 次"
' "$BEHAVIOR_FILE" | sort -t: -k2 -rn | head -5 >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 命令统计
echo "## 🔧 常用命令统计" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
jq -r '
    .commandStats |
    to_entries |
    sort_by(.value) | reverse |
    .[:5][] |
    "\(.key): \(.value) 次"
' "$BEHAVIOR_FILE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 交互历史摘要
echo "## 📝 最近交互" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo '```json' >> "$REPORT_FILE"
jq '.interactions[:10]' "$BEHAVIOR_FILE" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"

# 生成洞察
echo "" >> "$REPORT_FILE"
echo "## 💡 洞察与建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 检测高频时段
PEAK_HOURS=$(jq -r '
    [.activeHours | to_entries[] | .value[]] |
    group_by(.) |
    map({hour: .[0], count: length}) |
    sort_by(.count) | reverse |
    .[:3] |
    map("\(.hour):00 - \(.hour):00 (\(.count) 次)") |
    join(", ")
' "$BEHAVIOR_FILE")

echo "- **最活跃时段**: $PEAK_HOURS" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 检测高频命令
TOP_CMD=$(jq -r '.commandStats | to_entries | sort_by(.value) | reverse | .[0] | "\(.key) (\(.value) 次)"' "$BEHAVIOR_FILE")
echo "- **最常用命令**: $TOP_CMD" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 基于模式生成建议
echo "### 主动建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. 根据活跃时段，建议在您最活跃的时间段安排重要任务。" >> "$REPORT_FILE"
echo "2. 可以将常用命令创建为快捷方式，提高效率。" >> "$REPORT_FILE"
echo "3. 考虑基于历史交互创建自动化任务。" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "✓ Report generated: $REPORT_FILE"
cat "$REPORT_FILE"
