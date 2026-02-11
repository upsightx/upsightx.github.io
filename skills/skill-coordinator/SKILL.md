---
name: skill-coordinator
description: 技能协作机制 - 让不同技能之间互相调用和协作。TopicPicker 选题后自动创建任务，PriorityManager 自动触发执行。
---

# SkillCoordinator - 技能协作机制

## 功能

1. **技能通信** - 技能之间传递数据和触发
2. **事件总线** - 统一的事件分发机制
3. **自动链式** - A 技能完成 → 自动触发 B 技能

## 工作流示例

```
TopicPicker 选题
  ↓ 发送事件: topic-picked
PriorityManager 创建任务
  ↓ 发送事件: task-created
IdleTrigger 检测空闲
  ↓ 触发执行
TaskExecutor 执行任务
```

## 使用方法

### 技能发送事件

```bash
# TopicPicker 完成选题后
./scripts/emit-event.sh topic-picked '{"topics":["..."]}'
```

### 技能订阅事件

```bash
# PriorityManager 订阅 topic-picked 事件
./scripts/subscribe.sh topic-picked
```

## 事件类型

- `topic-picked` - 选题完成
- `task-created` - 任务创建
- `task-completed` - 任务完成
- `idle-triggered` - 空闲触发
- `user-active` - 用户活跃

## 输出

- `memory/skills-events.json` - 事件日志
- `memory/skill-registrations.json` - 技能注册表
