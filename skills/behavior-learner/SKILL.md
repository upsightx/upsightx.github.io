---
name: behavior-learner
description: 用户行为学习器 - 分析用户活跃时间段、常用命令、任务偏好，主动推荐功能。
---

# BehaviorLearner - 用户行为学习器

## 功能

1. **活跃时段分析** - 记录用户交互时间，识别活跃和空闲时段
2. **命令模式学习** - 统计用户最常用的命令和操作
3. **任务偏好跟踪** - 识别用户关注的任务类型和优先级
4. **主动推荐** - 基于学习到的模式主动建议相关功能

## 工作原理

```
收集数据 (memory/behavior-data.json)
    ↓
分析模式 (活跃时段、常用命令)
    ↓
生成洞察 (每周报告)
    ↓
主动推荐 (在合适时机推送)
```

## 数据结构

```json
{
  "activeHours": {
    "Mon": [9, 10, 14, 15, 21, 22],
    "Tue": [10, 11, 15, 16],
    "Wed": []
  },
  "commandStats": {
    "web_search": 15,
    "feishu_doc": 8,
    "sessions_spawn": 5
  },
  "taskPreferences": {
    "AI资讯搜集": "high",
    "代码开发": "medium",
    "文档整理": "low"
  },
  "lastUpdated": "2026-02-12T00:00:00+08:00"
}
```

## 使用方法

```bash
# 记录用户交互
./scripts/record-interaction.sh <command> <context>

# 生成分析报告
./scripts/analyze-behavior.sh

# 获取推荐
./scripts/get-recommendations.sh
```

## 输出

### 每周报告
- 最活跃的时段
- 最常用的 5 个命令
- 任务偏好总结
- 基于模式的建议

### 实时推荐
- 基于当前时段推荐相关功能
- 基于历史推荐相似任务
- 预测用户可能的下一步操作
