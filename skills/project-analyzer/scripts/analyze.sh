#!/bin/bash
# 项目分析脚本
# 扫描项目结构、发现问题、生成报告

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
OUTPUT_JSON="$MEMORY_DIR/project-analysis.json"
OUTPUT_REPORT="$MEMORY_DIR/project-analysis-report.md"

# 确保输出目录存在
mkdir -p "$MEMORY_DIR"

# 分析项目结构
echo "分析项目结构..."
TOTAL_FILES=$(find "$WORKSPACE" -type f | wc -l)
TOTAL_DIRS=$(find "$WORKSPACE" -type d | wc -l)
CODE_LINES=$(find "$WORKSPACE" -name "*.sh" -o -name "*.js" -o -name "*.json" -o -name "*.md" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')

# 查找 TODO/FIXME
echo "查找待办事项..."
TODOS=$(grep -rn "TODO\|FIXME" "$WORKSPACE" --include="*.sh" --include="*.md" --include="*.js" 2>/dev/null | head -20)

# 检查 Git 状态
echo "检查 Git 状态..."
cd "$WORKSPACE"
GIT_STATUS=$(git status --short 2>/dev/null || echo "Not a git repository")
UNCOMMITTED=$(echo "$GIT_STATUS" | grep -c "^" || echo "0")

# 检查大文件
echo "检查大文件..."
LARGE_FILES=$(find "$WORKSPACE" -type f -size +1M 2>/dev/null | head -10)

# 生成 JSON 报告
cat > "$OUTPUT_JSON" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "workspace": "$WORKSPACE",
  "structure": {
    "totalFiles": $TOTAL_FILES,
    "totalDirs": $TOTAL_DIRS,
    "codeLines": ${CODE_LINES:-0}
  },
  "issues": {
    "todos": $(echo "$TODOS" | wc -l),
    "uncommittedFiles": $UNCOMMITTED,
    "largeFiles": $(echo "$LARGE_FILES" | wc -l)
  },
  "improvements": []
}
EOF

# 生成可读报告
cat > "$OUTPUT_REPORT" << EOF
# 项目分析报告 - $(date '+%Y-%m-%d %H:%M')

## 项目结构
- 总文件数: $TOTAL_FILES
- 总目录数: $TOTAL_DIRS
- 代码行数: ${CODE_LINES:-0}

## 发现的问题

### TODO/FIXME 项
\`\`\`
$TODOS
\`\`\`

### Git 状态
未提交文件: $UNCOMMITTED 个
\`\`\`
$GIT_STATUS
\`\`\`

### 大文件 (>1MB)
\`\`\`
$LARGE_FILES
\`\`\`

## 改进建议
1. 处理发现的 TODO/FIXME 项
2. 提交未提交的更改
3. 清理或优化大文件

---
*由 project-analyzer 自动生成*
EOF

echo "分析完成！"
echo "JSON 报告: $OUTPUT_JSON"
echo "可读报告: $OUTPUT_REPORT"
