---
name: knowledge-manager
description: 知识管理器 - 自动整理和更新知识库（MEMORY.md、memory/*.md），提取洞察，维护长期记忆。
---

# KnowledgeManager - 知识管理器

## 功能

1. **自动整理**
   - 定期分析 daily memory 文件（memory/YYYY-MM-DD.md）
   - 提取重要事件和洞察
   - 更新长期记忆（MEMORY.md）

2. **洞察提取**
   - 识别决策、模式、偏好
   - 总结经验教训
   - 维护用户画像

3. **知识优化**
   - 清理过时信息
   - 去重和合并相似内容
   - 保持知识库的结构化

4. **智能检索**
   - 语义搜索记忆内容
   - 快速定位相关信息
   - 关联相关记忆

## 工作流程

```
收集数据（daily memory）
    ↓
分析内容（提取关键事件）
    ↓
识别洞察（决策、模式、教训）
    ↓
更新 MEMORY.md（长期记忆）
    ↓
清理过期内容
```

## 使用方法

```bash
# 整理和更新知识库
./scripts/organize-knowledge.sh

# 提取洞察
./scripts/extract-insights.sh

# 搜索记忆
./scripts/search-memory.sh <query>

# 生成知识报告
./scripts/knowledge-report.sh
```

## 输出

### 整理结果
- 更新的 MEMORY.md
- 提取的洞察列表
- 处理的 daily memory 文件

### 洞察报告
- 发现的模式
- 用户偏好
- 经验教训
- 待办事项

## 自动触发

### 心跳触发
当满足以下条件时自动执行：
- 距上次整理 >= 24 小时
- 有新的 daily memory 文件
- 系统空闲时间 >= 15 分钟

### 触发频率
- 自动整理：每天一次
- 洞察提取：每 2 天一次
- 知识报告：每周一次