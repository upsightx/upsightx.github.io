---
name: priority-manager
description: 任务优先级自动判断 - 基于任务类型、用户行为、系统状态自动计算任务优先级。
---

# PriorityManager - 任务优先级自动判断

## 功能

1. **动态优先级** - 根据上下文调整任务优先级
2. **用户行为分析** - 学习用户偏好和活跃模式
3. **智能排序** - 自动选择最合适的任务

## 优先级算法

```
基础优先级 = 预定义优先级 (critical/high/medium/low)

调整因子:
- 用户活跃时段: ×1.5 (用户在线时降低优先级）
- 系统负载低: ×1.3 (系统空闲时提高优先级）
- 任务等待时间: 每小时 +0.2 (等待越久优先级越高）
- 用户历史偏好: ×1.2 (用户经常执行的任务优先）

最终优先级 = 基础优先级 × 调整因子
```

## 使用方法

```bash
# 计算任务优先级
./scripts/calc-priority.sh <task-id>
```

## 输出

```json
{
  "taskId": "task-1",
  "basePriority": "high",
  "finalScore": 9.1,
  "factors": {
    "userActive": false,
    "systemLoad": 0.1,
    "waitingTime": 2.5,
    "userPreference": 1.1
  }
}
```
