# HEARTBEAT.md - 心跳检查任务

# 空闲触发配置
IDLE_TRIGGER_MINUTES=10
IDLE_COOLDOWN_MINUTES=30
AI_SEARCH_INTERVAL_MINUTES=60

# 心跳检查流程

## 1. 检查空闲触发条件

首先运行空闲检测：
```bash
/root/.openclaw/workspace/skills/idle-trigger/scripts/check_idle.sh
```

检查以下条件：
- [ ] 系统空闲时间 >= 10 分钟
- [ ] 用户静默时间 >= 10 分钟（查看 memory/idle-state.json）
- [ ] 没有正在执行的任务（通过 sessions_list 检查）
- [ ] 距上次触发 >= 30 分钟（冷却期）

## 2. 如果满足条件，执行任务（按优先级）

### 🚨 最高优先级：执行 OPENCLAW_IMPROVEMENTS.md 中的改进

**每次触发必须至少执行一项改进任务，不只是搜索信息！**

执行流程：
1. 读取 OPENCLAW_IMPROVEMENTS.md
2. 找到下一个未完成的 `[ ]` 任务
3. **立即执行**（不是记录，是真正执行代码、创建文件、修改配置）
4. 更新任务状态为 `[x]`
5. 记录到 memory/idle-state.json

### 🔥 高优先级任务列表

1. **改进空闲触发器智能度**
   - [ ] 实现任务优先级自动判断
   - [ ] 添加任务分解能力（复杂任务 → 并行子任务）
   - [ ] 建立技能协作机制

2. **创建新技能**
   - [ ] `project-analyzer`: 分析代码库结构、发现问题、生成报告
   - [ ] `knowledge-manager`: 自动整理 memory、提取洞察、更新 MEMORY.md
   - [ ] `smart-notifier`: 根据用户模式主动推送重要信息

3. **优化配置**
   - [ ] 配置备用模型（glm-4.7, solar-pro-3）
   - [ ] 实现任务类型到模型的智能路由
   - [ ] 监控 API 使用成本

### 定期任务（每小时/每天）

- **每小时**: AI 信息搜索 → 分析 → 应用到改进计划
- **每天**: 服务器健康检查、记忆文件整理、Git 提交推送

## 3. 任务执行原则

### ⚡ 核心原则：DO > THINK > RECORD

1. **先执行**：写代码、创建文件、修改配置
2. **再思考**：分析结果、总结经验
3. **最后记录**：更新状态文件

### 🚫 不要做的事

- ❌ 只搜索不执行
- ❌ 只记录不行动
- ❌ 等待用户指令
- ❌ 浅尝辄止

### ✅ 要做的事

- ✅ 深度思考如何应用发现
- ✅ 立即执行可行的改进
- ✅ 主动推进未完成任务
- ✅ 遇到阻塞时寻求替代方案

## 4. AI 搜索关键词模板

```
"Claude Opus 4.6 Anthropic new features 2026"
"OpenAI GPT-5 o3 model release 2026"
"Google Gemini 3 latest update 2026"
"MCP Model Context Protocol tools 2026"
"AI autonomous agent framework 2026"
"OpenRouter new models 2026"
```

## 5. 更新状态

执行任务后，更新 memory/idle-state.json：
```json
{
  "lastUserMessage": "上次用户消息时间",
  "lastTrigger": "上次触发时间",
  "lastAISearch": "上次AI搜索时间",
  "lastTask": "上次执行的任务",
  "completedImprovements": ["已完成的改进1", "已完成的改进2"],
  "nextImprovement": "下一个要执行的改进"
}
```

---

# 注意事项

- 每次心跳必须**真正执行**至少一项改进任务
- AI 搜索每小时最多一次，但改进执行是持续的
- 深夜时段（23:00-08:00）继续执行，但降低消息推送频率
- 如果用户说"别打扰"，暂停主动消息但继续后台改进
