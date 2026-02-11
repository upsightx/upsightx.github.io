# MEMORY.md - 长期记忆

## 最新事件（摘要）
- 2026-02-12：创建多模型管理器（model-manager），配置备用模型、实现任务路由、成本监控
- 2026-02-12：创建用户行为学习器（behavior-learner），支持活跃时段分析、命令统计、智能推荐
- 2026-02-12：Phase 2 和 Phase 3 全部完成，所有计划任务已完成
- 2026-02-10：用户 ou_cde9c07bf7a70a5cdef94b8ad3256309 首次通过飞书私聊打招呼；机器人当前缺少飞书联系人只读权限，待管理员授权。
- 2026-02-10：修复空闲检测脚本（idle-trigger），现在能正确检测服务器空闲状态。

## 用户画像（渐进填写）
- 认知来源：飞书 DM（ou_cde9c07bf7a70a5cdef94b8ad3256309）
- 偏好/习惯：待补充

## AI 技术动态
- 2026-02-05：**Claude Opus 4.6 发布**
  - 新增 "agent teams" 功能，可分解大任务为子任务并行处理
  - 编码能力提升，更擅长一次性项目创建
  - 已在 Google Cloud Vertex AI 提供
- 2026-01：**Google Gemini 3 已发布**
  - AI Ultra 订阅提供 Gemini 3 Pro
  - Gemini 2.5 Pro 是免费层最强大模型
  - 新增 "Personal Intelligence" 功能，可基于照片/邮件主动响应
- 2026-02：**AI Agent 框架排名**
  - 主流框架：LangGraph, CrewAI, AutoGen, Pydantic AI
  - 企业平台：Salesforce Agentforce, Microsoft Copilot
  - 无代码工具：Lindy, Gumloop
- Brave Search API 免费版速率限制较低（1 QPS），需要升级或替换

## 约定与提醒
- 重要约定：待补充
- 需周期回顾的事项：无

## 决策与要点
- 2026-02-12：model-manager 技能管理 4 个模型，提供任务路由和成本优化
- 2026-02-12：所有改进计划已完成（Phase 1-3），可考虑添加新技能或优化现有功能
- 2026-02-12：behavior-learner 技能记录用户交互到 memory/behavior-data.json，支持行为分析和推荐
- 2026-02-10：在未获得飞书联系人只读权限前，暂不自动获取用户身份信息；以用户自述为主。
- 2026-02-10：空闲触发器现在基于 `w` 命令检测终端空闲时间，更准确
