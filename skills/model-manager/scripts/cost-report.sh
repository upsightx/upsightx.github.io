#!/bin/bash
# 生成模型使用成本报告
# 用法: ./cost-report.sh

CONFIG_FILE="/root/.openclaw/workspace/skills/model-manager/config.json"
REPORT_FILE="/root/.openclaw/workspace/memory/model-cost-report.md"
CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "# 模型使用成本报告" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**生成时间**: $CURRENT_TIME" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 📊 可用模型概览" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| 模型 | 提供商 | 上下文 | 输入成本 | 输出成本 | 状态 |" >> "$REPORT_FILE"
echo "|------|--------|--------|----------|----------|------|" >> "$REPORT_FILE"

jq -r '.models | to_entries[] | [.key, .value.provider, .value.contextWindow, .value.cost.input, .value.cost.output, .value.available] | @tsv' "$CONFIG_FILE" | \
    awk -F'\t' '{printf "| %s | %s | %s | $%s/1K | $%s/1K | %s |\n", $1, $2, $3, $4, $5, $6}' >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

echo "## 💰 成本分析" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 计算每个模型的成本等级
echo "### 成本排名（从低到高）" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

jq -r '.models | to_entries[] | select(.value.available==true) | [.key, .value.cost.input, .value.cost.output] | @tsv' "$CONFIG_FILE" | \
    awk -F'\t' '{avg=($2+$3)/2; printf "%s: 输入 $%s/1K, 输出 $%s/1K (平均 $%.4f)\n", $1, $2, $3, avg}' | \
    sort -t: -k2 -n >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

# 识别免费模型
echo "### 免费模型" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
FREE_MODELS=$(jq -r '.models | to_entries[] | select(.value.cost.input == 0 and .value.cost.output == 0) | .key' "$CONFIG_FILE" | tr '\n' ', ' | sed 's/,$//')
if [ -z "$FREE_MODELS" ]; then
    echo "暂无免费模型" >> "$REPORT_FILE"
else
    echo "$FREE_MODELS" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

echo "## 🎯 任务路由建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| 任务类型 | 推荐模型 | 原因 |" >> "$REPORT_FILE"
echo "|----------|----------|------|" >> "$REPORT_FILE"

jq -r '.taskRouting | to_entries[] | [.key, .value.model, .value.reason] | @tsv' "$CONFIG_FILE" | \
    awk -F'\t' '{printf "| %s | %s | %s |\n", $1, $2, $3}' >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

echo "## 🔄 备用模型链" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
PRIMARY=$(jq -r '.fallbackChain.primary' "$CONFIG_FILE")
FALLBACK1=$(jq -r '.fallbackChain.fallback1' "$CONFIG_FILE")
FALLBACK2=$(jq -r '.fallbackChain.fallback2' "$CONFIG_FILE")
FALLBACK3=$(jq -r '.fallbackChain.fallback3' "$CONFIG_FILE")

echo "1. **首选**: $PRIMARY" >> "$REPORT_FILE"
echo "2. **备用 1**: $FALLBACK1" >> "$REPORT_FILE"
echo "3. **备用 2**: $FALLBACK2" >> "$REPORT_FILE"
echo "4. **备用 3**: $FALLBACK3" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

echo "## 💡 优化建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **简单任务** 使用 \`ark/glm-4.7\` - 完全免费" >> "$REPORT_FILE"
echo "2. **编程任务** 使用 \`openrouter/pony-alpha\` - 编程能力强，值得成本" >> "$REPORT_FILE"
echo "3. **中文任务** 使用 \`openrouter/z-ai/glm-4.7\` - 中文理解优秀" >> "$REPORT_FILE"
echo "4. **不确定时** 使用 \`openrouter/auto\` - 自动选择最优模型" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "5. **成本控制策略**:" >> "$REPORT_FILE"
echo "   - 优先使用 \`ark/glm-4.7\` 处理简单任务" >> "$REPORT_FILE"
echo "   - 仅在复杂任务使用 \`pony-alpha\`" >> "$REPORT_FILE"
echo "   - 监控每周使用情况，调整路由策略" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

echo "✓ Report generated: $REPORT_FILE"
cat "$REPORT_FILE"
