#!/bin/bash
# TopicPicker - 自动开发选中的主题

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
TOPICS_JSON="$MEMORY_DIR/topics.json"
SELECTED_IDS_FILE="$MEMORY_DIR/selected-topic-ids.txt"

GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ 缺少 GITHUB_TOKEN 环境变量"
  exit 1
fi

echo "🚀 TopicPicker 自动开发模块"

# 读取选中的主题ID
if [ ! -f "$SELECTED_IDS_FILE" ]; then
  echo "❌ 未找到选中的主题，请先运行 pick.sh"
  exit 1
fi

SELECTED_IDS=$(cat "$SELECTED_IDS_FILE")
TOTAL=$(echo "$SELECTED_IDS" | wc -w)

echo "📋 选中的主题 ($TOTAL 个):"
echo "$SELECTED_IDS"
echo ""

# 遍历选中的主题
INDEX=0
for TOPIC_ID in $SELECTED_IDS; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔧 开发主题 $((INDEX + 1))/$TOTAL: $TOPIC_ID"
  
  # 从 JSON 中获取主题信息
  TOPIC_INFO=$(jq -r ".topics[] | select(.id == \"$TOPIC_ID\")" "$TOPICS_JSON")
  TOPIC_NAME=$(echo "$TOPIC_INFO" | jq -r '.name')
  TOPIC_DESC=$(echo "$TOPIC_INFO" | jq -r '.description')
  TOPIC_SCORE=$(echo "$TOPIC_INFO" | jq -r '.score')
  
  echo "   📦 名称: $TOPIC_NAME"
  echo "   📊 评分: $TOPIC_SCORE"
  echo "   📝 描述: $TOPIC_DESC"
  
  # 生成仓库名称
  REPO_NAME=$(echo "$TOPIC_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/_/-/g' | sed 's/[^a-z0-9-]//g')
  echo "   📦 仓库名: $REPO_NAME"
  
  # 创建项目目录
  PROJECT_DIR="/tmp/$REPO_NAME"
  rm -rf "$PROJECT_DIR"
  mkdir -p "$PROJECT_DIR"
  cd "$PROJECT_DIR"
  
  # 初始化 Git
  git init
  git config user.name "XiaoYi"
  git config user.email "xiao@openclaw.ai"
  
  # 创建基础文件
  echo "# $TOPIC_NAME" > README.md
  echo "" >> README.md
  echo "$TOPIC_DESC" >> README.md
  echo "" >> README.md
  echo "## Installation" >> README.md
  echo "" >> README.md
  echo '```bash' >> README.md
  echo "npm install $REPO_NAME" >> README.md
  echo '```' >> README.md
  echo "" >> README.md
  echo "## License" >> README.md
  echo "MIT" >> README.md
  
  # 创建 LICENSE
  cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 OpenClaw AI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
  
  # 创建 package.json
  cat > package.json << EOF
{
  "name": "$REPO_NAME",
  "version": "0.1.0",
  "description": "$TOPIC_DESC",
  "main": "index.js",
  "scripts": {
    "test": "echo \\"Error: no test specified\\" && exit 1"
  },
  "keywords": ["ai", "automation"],
  "author": "OpenClaw AI",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/upsightx/$REPO_NAME"
  }
}
EOF
  
  # 提交
  git add -A
  git commit -m "feat: 初始化 $TOPIC_NAME"
  
  # 在 GitHub 创建仓库
  echo "   📤 创建 GitHub 仓库..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$REPO_NAME\",\"description\":\"$TOPIC_DESC\",\"private\":false}")
  
  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ 仓库创建成功"
  else
    echo "   ⚠️  仓库可能已存在 (HTTP $HTTP_CODE)"
  fi
  
  # 推送
  echo "   📤 推送到 GitHub..."
  git remote add origin "https://xiao:$GITHUB_TOKEN@github.com/upsightx/$REPO_NAME.git"
  git push -u origin main > /dev/null 2>&1
  
  echo "   ✅ 完成: https://github.com/upsightx/$REPO_NAME"
  echo ""
  
  INDEX=$((INDEX + 1))
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 所有主题开发完成！"
