# OpenClaw 改进计划

## 基于 AI 技术动态的改进思路

### 1. Claude Opus 4.6 "Agent Teams" 启发

**发现**: Claude Opus 4.6 可以分解大任务为子任务并行处理

**应用方案**:
- OpenClaw 已有 `sessions_spawn` 支持子代理
- 改进 HEARTBEAT.md：添加任务分解策略
- 创建 "任务分解器" 技能：自动将复杂任务拆分为可并行执行的子任务

**具体实现**:
```markdown
# HEARTBEAT.md 改进
## 任务分解策略
- 分析待办任务的复杂度
- 复杂任务 → 分解为子任务 → 并行启动 sessions_spawn
- 示例：搜索AI信息 + 整理记忆 + 检查服务器 → 并行执行
```

### 2. AI Agent 框架（LangGraph, CrewAI）启发

**发现**: 主流框架支持角色分工、工具链、状态管理

**应用方案**:
- 创建专门的 "技能" 处理特定领域任务
- 建立技能之间的协作机制
- 添加任务状态跟踪

**具体实现**:
- [ ] 创建 `project-analyzer` 技能：分析代码库结构和问题
- [ ] 创建 `smart-reminder` 技能：基于用户行为模式主动提醒
- [ ] 创建 `knowledge-manager` 技能：自动整理和更新知识库

### 3. Gemini "Personal Intelligence" 启发

**发现**: 可基于用户数据（照片、邮件）主动响应

**应用方案**:
- 利用 memory 系统分析用户行为模式
- 预测用户需求，主动提供建议
- 建立用户偏好学习机制

**具体实现**:
- [ ] 分析用户活跃时间段
- [ ] 学习用户常用命令和任务类型
- [ ] 主动推荐相关功能

### 4. OpenRouter 多模型策略

**发现**: Aurora Alpha (128k), Solar Pro 3 (免费), Free Router (200k)

**应用方案**:
- 配置备用模型，提高可用性
- 根据任务类型选择最优模型
- 成本优化：简单任务用免费模型

**具体实现**:
```json
{
  "models": {
    "fallback": ["ark/glm-4.7", "openrouter/auto"],
    "taskRouting": {
      "simple": "solar-pro-3",
      "complex": "openrouter/pony-alpha",
      "coding": "openrouter/pony-alpha"
    }
  }
}
```

## 立即执行的改进

### Phase 1: 基础能力增强 ✅
1. [x] 修复空闲检测脚本
2. [x] 改进 HEARTBEAT 任务执行逻辑
3. [x] 创建项目分析技能
4. [x] Git 提交并推送改进

### Phase 2: 智能化升级
1. [x] 实现任务优先级自动判断
2. [x] 建立技能协作机制
3. [x] 添加用户行为学习

### Phase 3: 多模型优化
1. [x] 配置备用模型
2. [x] 实现任务路由策略
3. [x] 监控模型使用成本

## 改进日志

### 2026-02-11
- 修复空闲检测脚本，使用 `w` 命令检测终端空闲
- 创建本改进计划文档
- 下一步：实现 Phase 1 剩余任务

### 2026-02-12
- 创建 TaskWeaver 开源项目并推送到 GitHub
- 创建 TopicPicker 智能选题模块
- 自动创建 2 个 GitHub 仓库（智能 CLI 助手、代码分析 AI 引擎）
- 实现任务优先级自动判断（priority-manager 技能）
- 建立技能协作机制（skill-coordinator 技能）
- 创建用户行为学习器（behavior-learner 技能）
- 创建多模型管理器（model-manager 技能）
  - 配置备用模型链（4 个模型）
  - 实现任务路由策略（5 种任务类型）
  - 提供成本监控和报告
- Phase 2 完成 ✅
- Phase 3 完成 ✅
- 所有改进已推送到 GitHub
