---
name: model-manager
description: 多模型管理器 - 配置备用模型、实现任务路由策略、监控模型使用成本。
---

# ModelManager - 多模型管理器

## 功能

1. **备用模型配置** - 配置多个模型作为备份，提高可用性
2. **任务路由策略** - 根据任务类型自动选择最优模型
3. **成本监控** - 追踪模型使用情况和成本
4. **性能优化** - 根据任务复杂度选择性价比最高的模型

## 模型配置

### 可用模型

```json
{
  "models": {
    "ark/glm-4.7": {
      "provider": "ark",
      "contextWindow": 200000,
      "cost": {
        "input": 0,
        "output": 0
      },
      "strength": "中文理解、长文本、免费"
    },
    "openrouter/z-ai/glm-4.7": {
      "provider": "openrouter",
      "contextWindow": 200000,
      "cost": {
        "input": 0.001,
        "output": 0.002
      },
      "strength": "中文理解、长文本"
    },
    "openrouter/pony-alpha": {
      "provider": "openrouter",
      "contextWindow": 128000,
      "cost": {
        "input": 0.003,
        "output": 0.006
      },
      "strength": "复杂推理、编程"
    },
    "openrouter/auto": {
      "provider": "openrouter",
      "contextWindow": 200000,
      "cost": {
        "input": "variable",
        "output": "variable"
      },
      "strength": "自动选择最优模型"
    }
  }
}
```

### 任务路由策略

```json
{
  "taskRouting": {
    "simple": {
      "tasks": ["搜索", "简单问答", "翻译", "摘要"],
      "model": "ark/glm-4.7",
      "reason": "免费，适合简单任务"
    },
    "coding": {
      "tasks": ["代码编写", "代码审查", "调试"],
      "model": "openrouter/pony-alpha",
      "reason": "编程能力强"
    },
    "complex": {
      "tasks": ["深度分析", "任务规划", "多步骤推理"],
      "model": "openrouter/pony-alpha",
      "reason": "推理能力强"
    },
    "chinese": {
      "tasks": ["中文写作", "文档处理", "翻译"],
      "model": "openrouter/z-ai/glm-4.7",
      "reason": "中文理解能力强"
    },
    "long-context": {
      "tasks": ["长文档分析", "代码库分析"],
      "model": "openrouter/z-ai/glm-4.7",
      "reason": "200K 上下文"
    }
  }
}
```

### 备用模型链

```json
{
  "fallbackChain": {
    "primary": "openrouter/z-ai/glm-4.7",
    "fallback1": "ark/glm-4.7",
    "fallback2": "openrouter/auto",
    "fallback3": "openrouter/pony-alpha"
  }
}
```

## 使用方法

```bash
# 获取任务推荐模型
./scripts/get-model.sh <task-type>

# 检查模型可用性
./scripts/check-model.sh <model-id>

# 生成成本报告
./scripts/cost-report.sh

# 切换默认模型
./scripts/set-default-model.sh <model-id>
```

## 输出

### 模型推荐

```json
{
  "task": "代码编写",
  "recommendedModel": "openrouter/pony-alpha",
  "fallbackModels": ["openrouter/z-ai/glm-4.7", "ark/glm-4.7"],
  "reason": "编程能力强，推理深度高"
}
```

### 成本报告

```
模型使用统计（本周）:
- ark/glm-4.7: 15 次调用，成本: $0.00
- openrouter/z-ai/glm-4.7: 23 次调用，成本: $0.15
- openrouter/pony-alpha: 8 次调用，成本: $0.24

总成本: $0.39
平均每次: $0.008
```

## 配置文件

配置文件位于：`/root/.openclaw/workspace/skills/model-manager/config.json`
