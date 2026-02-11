---
name: topic-picker
description: 智能选题模块 - 自动搜集信息、筛选主题、开发新项目。每2小时搜集最新AI技术，选择适合OpenClaw的主题自动开发。
---

# TopicPicker - 智能选题模块

## 功能

1. **信息搜集** - 每2小时搜集不同AI领域的信息
2. **主题筛选** - 列出10个适合借鉴到OpenClaw的主题
3. **自动开发** - 选2个主题开发，创建GitHub仓库并推送

## 工作流程

```
搜集信息 → 评估价值 → 排序筛选 → 自动开发 → 推送GitHub
```

## 使用方法

### 手动触发
```bash
# 搜集并评分主题
./scripts/pick.sh

# 查看选中主题报告
cat memory/selected-topics.md

# 自动开发选中的主题
./scripts/develop.sh
```

### 自动触发（空闲时）
当空闲触发器检测到满足条件时，自动执行完整的选题和开发流程。

## 主题评分维度

- **可行性** (0-10) - 技术难度、开发时间
- **价值** (0-10) - 实用性、创新性
- **适配性** (0-10) - 与OpenClaw的契合度
- **独特性** (0-10) - 市场空白点

总评分 = 可行性 × 0.3 + 价值 × 0.4 + 适配性 × 0.2 + 独特性 × 0.1

## 输出

搜集结果：
- `memory/topics.json` - 搜集到的主题列表（结构化）
- `memory/selected-topics.md` - 选中的主题报告（可读）
- `memory/selected-topic-ids.txt` - 选中主题ID列表

开发结果：
- 自动创建的 GitHub 仓库
- 推送到 https://github.com/upsightx/
