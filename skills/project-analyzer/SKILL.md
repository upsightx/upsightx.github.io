---
name: project-analyzer
description: 分析代码库结构、发现问题、生成改进报告。在空闲时自动检查项目健康状况，提出优化建议。
---

# Project Analyzer 技能

## 功能

1. **代码库结构分析**
   - 扫描项目目录结构
   - 识别主要模块和依赖关系
   - 生成项目结构报告

2. **问题检测**
   - 查找 TODO/FIXME 注释
   - 检测大文件和潜在问题
   - 分析 Git 状态（未提交的更改）

3. **改进建议**
   - 基于发现的问题提出优化建议
   - 自动执行简单的改进（代码格式化、文档更新）
   - 生成改进报告

## 使用方法

### 手动触发
```
用户：分析当前项目
```

### 自动触发（心跳）
当空闲触发器检测到项目有未处理的问题时，自动执行分析。

## 执行脚本

```bash
# 分析脚本位置
./scripts/analyze.sh

# 返回格式：
# - 项目结构概览
# - 问题列表
# - 改进建议
```

## 输出

分析结果保存在：
- `memory/project-analysis.json` - 结构化数据
- `memory/project-analysis-report.md` - 可读报告

## 示例输出

```markdown
# 项目分析报告 - 2026-02-11

## 项目结构
- 总文件数: 42
- 主要目录: skills/, memory/, docs/
- 代码行数: ~2500

## 发现的问题
1. [TODO] HEARTBEAT.md:45 - 添加任务分解逻辑
2. [FIXME] idle-trigger/check_idle.sh - SSH 检测逻辑
3. 未提交文件: 3 个

## 改进建议
1. 创建 task-decomposer 技能
2. 优化空闲检测脚本
3. 提交当前更改
```
