#!/bin/bash
# Security Auditor - 安全审计脚本
# 扫描代码库漏洞和安全问题

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
SCAN_DIR="${1:-$WORKSPACE}"
MEMORY_DIR="$WORKSPACE/memory"
OUTPUT_JSON="$MEMORY_DIR/security-audit.json"
OUTPUT_REPORT="$MEMORY_DIR/security-audit-report.md"
OUTPUT_FINDINGS="$MEMORY_DIR/security-audit-findings.txt"

# 模式标志
DEEP_SCAN=false
GENERATE_REPORT=true

# 解析参数
shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case $1 in
    --deep)
      DEEP_SCAN=true
      shift
      ;;
    --no-report)
      GENERATE_REPORT=false
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# 颜色输出
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 确保 memory 目录存在
mkdir -p "$MEMORY_DIR"

# 初始化统计
TOTAL_FILES=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
INFO_COUNT=0

# 创建临时文件
TEMP_DIR=$(mktemp -d)
FINDINGS_FILE="$TEMP_DIR/findings.txt"
JSON_FILE="$TEMP_DIR/findings.json"

echo -e "${BLUE}=== Security Auditor ===${NC}"
echo -e "${BLUE}扫描目录: $SCAN_DIR${NC}"
if [ "$DEEP_SCAN" = true ]; then
  echo -e "${BLUE}扫描模式: 深度${NC}"
else
  echo -e "${BLUE}扫描模式: 标准${NC}"
fi
echo ""

# 辅助函数：添加发现
add_finding() {
  local severity="$1"
  local type="$2"
  local file="$3"
  local line="$4"
  local description="$5"
  local suggestion="$6"

  # 写入文本发现 - 使用制表符分隔
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$severity" "$type" "$file" "$line" "$description" "$suggestion" >> "$FINDINGS_FILE"

  # 更新统计
  case "$severity" in
    CRITICAL) ((CRITICAL_COUNT++)) ;;
    HIGH) ((HIGH_COUNT++)) ;;
    MEDIUM) ((MEDIUM_COUNT++)) ;;
    LOW) ((LOW_COUNT++)) ;;
    INFO) ((INFO_COUNT++)) ;;
  esac

  # 转义 JSON 字符串
  file_escaped=$(echo "$file" | sed 's/"/\\"/g')
  desc_escaped=$(echo "$description" | sed 's/"/\\"/g')
  suggest_escaped=$(echo "$suggestion" | sed 's/"/\\"/g')

  # 写入 JSON
  cat >> "$JSON_FILE" << EOJ
  {
    "severity": "$severity",
    "type": "$type",
    "file": "$file_escaped",
    "line": "$line",
    "description": "$desc_escaped",
    "suggestion": "$suggest_escaped",
    "timestamp": "$(date -Iseconds)"
  },
EOJ
}

# 1. 扫描硬编码凭证
echo -e "${BLUE}[1/8] 扫描硬编码凭证...${NC}"
RESULTS=$(grep -rn 'password[ ]*=[ ]*"[^"]"' "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | head -20 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "HIGH" "hardcoded_secrets" "$file" "$line" "发现硬编码密码" "使用环境变量或密钥管理服务"
  done
fi

RESULTS=$(grep -rn "api_key[ ]*=[ ]*'" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "HIGH" "hardcoded_secrets" "$file" "$line" "发现硬编码 API Key" "使用环境变量存储"
  done
fi

# 2. 扫描 SQL 注入风险
echo -e "${BLUE}[2/8] 扫描 SQL 注入风险...${NC}"
RESULTS=$(grep -rn "mysql_query" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "HIGH" "sql_injection" "$file" "$line" "可能的 SQL 注入: mysql_query" "使用参数化查询"
  done
fi

# 3. 扫描 XSS 风险
echo -e "${BLUE}[3/8] 扫描 XSS 风险...${NC}"
RESULTS=$(grep -rn "innerHTML" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | grep -E "\.(js|ts|jsx|tsx):" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "MEDIUM" "xss" "$file" "$line" "可能的 XSS: innerHTML" "使用 textContent 或 DOMPurify"
  done
fi

# 4. 扫描命令注入风险
echo -e "${BLUE}[4/8] 扫描命令注入风险...${NC}"
RESULTS=$(grep -rn "exec(" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | grep -E "\.(py|rb|pl):" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "HIGH" "command_injection" "$file" "$line" "可能的命令注入: exec()" "使用 subprocess 的安全模式"
  done
fi

RESULTS=$(grep -rn "system(" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | grep -E "\.(c|cpp|py|rb):" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "HIGH" "command_injection" "$file" "$line" "可能的命令注入: system()" "使用安全的命令执行方法"
  done
fi

# 5. 扫描不安全的加密
echo -e "${BLUE}[5/8] 扫描不安全的加密...${NC}"
RESULTS=$(grep -rn "md5(" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "MEDIUM" "insecure_crypto" "$file" "$line" "使用不安全的 MD5 算法" "使用 SHA-256 或更强的哈希"
  done
fi

# 6. 扫描路径遍历风险
echo -e "${BLUE}[6/8] 扫描路径遍历风险...${NC}"
RESULTS=$(grep -rn "\.\./" "$SCAN_DIR" 2>/dev/null | grep -v "node_modules\|\.git\|vendor\|__pycache__\|scan.sh" | grep -E "\.(js|ts|py|rb|php):" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "LOW" "path_traversal" "$file" "$line" "可能的路径遍历: ../" "验证并规范化文件路径"
  done
fi

# 7. 扫描缓冲区溢出风险 (C/C++)
echo -e "${BLUE}[7/8] 扫描缓冲区溢出风险...${NC}"
RESULTS=$(grep -rn "gets(" "$SCAN_DIR" 2>/dev/null | grep -E "\.(c|cpp|h|hpp):" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "CRITICAL" "buffer_overflow" "$file" "$line" "缓冲区溢出风险: gets()" "使用 fgets()"
  done
fi

RESULTS=$(grep -rn "strcpy(" "$SCAN_DIR" 2>/dev/null | grep -E "\.(c|cpp|h|hpp):" | head -10 || true)
if [ -n "$RESULTS" ]; then
  echo "$RESULTS" | while IFS=: read -r file line content; do
    add_finding "CRITICAL" "buffer_overflow" "$file" "$line" "缓冲区溢出风险: strcpy()" "使用 strncpy()"
  done
fi

# 8. 深度扫描 - 依赖检查
if [ "$DEEP_SCAN" = true ]; then
  echo -e "${BLUE}[8/8] 扫描依赖安全...${NC}"

  # 检查 package.json
  if [ -f "$SCAN_DIR/package.json" ]; then
    echo "  检查 package.json..."
    if [ ! -f "$SCAN_DIR/package-lock.json" ] && [ ! -f "$SCAN_DIR/yarn.lock" ]; then
      add_finding "MEDIUM" "misconfiguration" "package.json" "1" "缺少依赖锁文件" "运行 npm install 生成锁文件"
    fi
  fi

  # 检查 requirements.txt
  if [ -f "$SCAN_DIR/requirements.txt" ]; then
    echo "  检查 requirements.txt..."
    unpinned=$(grep -v "==" "$SCAN_DIR/requirements.txt" | grep -v "^#" | grep -v "^$" | head -5 || true)
    if [ -n "$unpinned" ]; then
      add_finding "LOW" "dependency_vuln" "requirements.txt" "1" "部分依赖未固定版本" "使用 pip freeze 固定版本"
    fi
  fi

  # 检查 .env 文件
  if [ -f "$SCAN_DIR/.env" ] || [ -f "$SCAN_DIR/.env.local" ]; then
    add_finding "HIGH" "sensitive_data" ".env" "1" ".env 文件存在" "确保 .env 在 .gitignore 中"
  fi
else
  echo -e "${BLUE}[8/8] 跳过依赖扫描（使用 --deep 启用）${NC}"
fi

# 计算总文件数
TOTAL_FILES=$(find "$SCAN_DIR" -type f 2>/dev/null | grep -v "node_modules\|\.git" | wc -l)

# 构建 JSON 报告
TOTAL_ISSUES=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT + INFO_COUNT))

# 处理 JSON 数组
if [ -s "$JSON_FILE" ]; then
  sed -i '$ s/,$//' "$JSON_FILE" 2>/dev/null
  FINDINGS_JSON=$(cat "$JSON_FILE" 2>/dev/null)
else
  FINDINGS_JSON=""
fi

cat > "$OUTPUT_JSON" << EOF
{
  "scanTime": "$(date -Iseconds)",
  "scanDirectory": "$SCAN_DIR",
  "scanMode": "$([ "$DEEP_SCAN" = true ] && echo "deep" || echo "standard")",
  "totalFiles": $TOTAL_FILES,
  "summary": {
    "totalIssues": $TOTAL_ISSUES,
    "critical": $CRITICAL_COUNT,
    "high": $HIGH_COUNT,
    "medium": $MEDIUM_COUNT,
    "low": $LOW_COUNT,
    "info": $INFO_COUNT
  },
  "findings": [
$FINDINGS_JSON
  ]
}
EOF

# 复制原始发现文件
if [ -f "$FINDINGS_FILE" ]; then
  cp "$FINDINGS_FILE" "$OUTPUT_FINDINGS"
fi

# 生成 Markdown 报告
if [ "$GENERATE_REPORT" = true ]; then
  cat > "$OUTPUT_REPORT" << EOF
# 安全审计报告 - $(date '+%Y-%m-%d %H:%M:%S')

## 概要

| 项目 | 数值 |
|------|------|
| 扫描时间 | $(date '+%Y-%m-%d %H:%M:%S') |
| 扫描目录 | \`$SCAN_DIR\` |
| 扫描模式 | $([ "$DEEP_SCAN" = true ] && echo "深度" || echo "标准") |
| 总文件数 | $TOTAL_FILES |
| 发现问题 | **$TOTAL_ISSUES** |
| 🔴 Critical | $CRITICAL_COUNT |
| 🟠 High | $HIGH_COUNT |
| 🟡 Medium | $MEDIUM_COUNT |
| 🔵 Low | $LOW_COUNT |
| ℹ️ Info | $INFO_COUNT |

EOF

  # 按严重级别分组显示
  if [ $CRITICAL_COUNT -gt 0 ]; then
    echo "## 🔀 Critical 问题" >> "$OUTPUT_REPORT"
    echo "" >> "$OUTPUT_REPORT"
    grep "^CRITICAL" "$FINDINGS_FILE" 2>/dev/null | head -20 | while IFS=$'\t' read -r severity type file line desc suggest; do
      echo "### ${desc}" >> "$OUTPUT_REPORT"
      echo "- **文件**: \`${file}:${line}\`" >> "$OUTPUT_REPORT"
      echo "- **类型**: \`${type}\`" >> "$OUTPUT_REPORT"
      echo "- **修复建议**: ${suggest}" >> "$OUTPUT_REPORT"
      echo "" >> "$OUTPUT_REPORT"
    done
  fi

  if [ $HIGH_COUNT -gt 0 ]; then
    echo "## 🟠 High 问题" >> "$OUTPUT_REPORT"
    echo "" >> "$OUTPUT_REPORT"
    grep "^HIGH" "$FINDINGS_FILE" 2>/dev/null | head -20 | while IFS=$'\t' read -r severity type file line desc suggest; do
      echo "### ${desc}" >> "$OUTPUT_REPORT"
      echo "- **文件**: \`${file}:${line}\`" >> "$OUTPUT_REPORT"
      echo "- **类型**: \`${type}\`" >> "$OUTPUT_REPORT"
      echo "- **修复建议**: ${suggest}" >> "$OUTPUT_REPORT"
      echo "" >> "$OUTPUT_REPORT"
    done
  fi

  if [ $MEDIUM_COUNT -gt 0 ]; then
    echo "## 🟡 Medium 问题" >> "$OUTPUT_REPORT"
    echo "" >> "$OUTPUT_REPORT"
    grep "^MEDIUM" "$FINDINGS_FILE" 2>/dev/null | head -20 | while IFS=$'\t' read -r severity type file line desc suggest; do
      echo "### ${desc}" >> "$OUTPUT_REPORT"
      echo "- **文件**: \`${file}:${line}\`" >> "$OUTPUT_REPORT"
      echo "- **类型**: \`${type}\`" >> "$OUTPUT_REPORT"
      echo "- **修复建议**: ${suggest}" >> "$OUTPUT_REPORT"
      echo "" >> "$OUTPUT_REPORT"
    done
  fi

  if [ $LOW_COUNT -gt 0 ]; then
    echo "## 🔵 Low 问题" >> "$OUTPUT_REPORT"
    echo "" >> "$OUTPUT_REPORT"
    grep "^LOW" "$FINDINGS_FILE" 2>/dev/null | head -20 | while IFS=$'\t' read -r severity type file line desc suggest; do
      echo "### ${desc}" >> "$OUTPUT_REPORT"
      echo "- **文件**: \`${file}:${line}\`" >> "$OUTPUT_REPORT"
      echo "- **类型**: \`${type}\`" >> "$OUTPUT_REPORT"
      echo "- **修复建议**: ${suggest}" >> "$OUTPUT_REPORT"
      echo "" >> "$OUTPUT_REPORT"
    done
  fi

  cat >> "$OUTPUT_REPORT" << EOF
## 修复建议优先级

1. **立即处理** - 所有 Critical 和 High 级别问题
2. **尽快处理** - Medium 级别问题
3. **计划处理** - Low 和 Info 级别问题

## 最佳实践

- 定期运行安全审计（建议每月一次）
- 在 CI/CD 流程中集成安全扫描
- 使用自动化工具（如 Snyk, Dependabot）监控依赖漏洞
- 对发现的漏洞进行优先级排序和跟踪

---

*由 security-auditor 自动生成*
EOF
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

# 输出结果
echo ""
echo -e "${GREEN}=== 扫描完成 ===${NC}"
echo -e "总文件数: $TOTAL_FILES"
echo -e "发现的问题:"
echo -e "  ${RED}🔴 Critical: $CRITICAL_COUNT${NC}"
echo -e "  ${RED}🟠 High: $HIGH_COUNT${NC}"
echo -e "  ${YELLOW}🟡 Medium: $MEDIUM_COUNT${NC}"
echo -e "  ${BLUE}🔵 Low: $LOW_COUNT${NC}"
echo ""
echo -e "输出文件:"
echo -e "  ${GREEN}✓${NC} $OUTPUT_JSON"
echo -e "  ${GREEN}✓${NC} $OUTPUT_REPORT"
if [ -f "$OUTPUT_FINDINGS" ]; then
  echo -e "  ${GREEN}✓${NC} $OUTPUT_FINDINGS"
fi

exit 0
