---
name: security-auditor
description: 扫描代码库漏洞和安全问题，生成安全审计报告和修复建议。支持检测缓冲区溢出、SQL注入、XSS、依赖漏洞等多种安全风险。
---

# Security Auditor 技能

## 功能

1. **漏洞扫描**
   - 检测常见 Web 漏洞（SQL 注入、XSS、CSRF）
   - 查找缓冲区溢出风险
   - 识别硬编码凭证和敏感信息
   - 检测不安全的函数调用

2. **依赖安全检查**
   - 扫描 package.json、requirements.txt、Gemfile 等依赖文件
   - 识别过时的依赖版本
   - 检测已知漏洞的包

3. **配置安全审计**
   - 检查 .env 文件暴露
   - 分析权限配置
   - 检测弱加密使用

4. **报告生成**
   - JSON 格式结构化报告
   - Markdown 可读报告
   - 修复建议和优先级

## 使用方法

### 手动触发
```
用户：对当前代码库进行安全审计
用户：检查 security-auditor 报告
```

### 独立运行脚本

```bash
# 基础安全扫描
./skills/security-auditor/scripts/scan.sh

# 扫描指定目录
./skills/security-auditor/scripts/scan.sh /path/to/code

# 深度扫描（包括依赖分析）
./skills/security-auditor/scripts/scan.sh /path/to/code --deep

# 生成详细报告
./skills/security-auditor/scripts/scan.sh /path/to/code --report
```

## 输出文件

- `memory/security-audit.json` - 结构化漏洞数据
- `memory/security-audit-report.md` - 可读审计报告
- `memory/security-audit-findings.txt` - 原始发现列表

## 检测类别

### 严重级别
- **Critical** - 可直接利用的漏洞
- **High** - 高风险安全问题
- **Medium** - 中等风险问题
- **Low** - 低风险或最佳实践问题
- **Info** - 信息性发现

### 漏洞类型
- **sql_injection** - SQL 注入风险
- **xss** - 跨站脚本攻击
- **buffer_overflow** - 缓冲区溢出风险
- **hardcoded_secrets** - 硬编码凭证
- **insecure_crypto** - 不安全加密
- **command_injection** - 命令注入
- **path_traversal** - 路径遍历
- **dependency_vuln** - 依赖漏洞
- **misconfiguration** - 配置错误
- **sensitive_data** - 敏感数据暴露

## 示例报告

```markdown
# 安全审计报告 - 2026-02-13

## 概要
- 扫描时间: 2026-02-13 04:30:00
- 扫描目录: /root/.openclaw/workspace
- 总文件数: 127
- 发现问题: 8 个
  - Critical: 0
  - High: 2
  - Medium: 4
  - Low: 2

## 高危问题

### [HIGH] 硬编码数据库密码
- 文件: src/database.js:23
- 描述: 发现硬编码的数据库连接字符串
- 建议: 使用环境变量或配置管理工具

### [HIGH] 不安全的 eval() 使用
- 文件: src/parser.js:45
- 描述: 使用 eval() 处理用户输入
- 建议: 使用 JSON.parse 或安全的解析器

## 修复建议

1. 立即修复所有 High 和 Critical 问题
2. 将敏感配置移至 .env 或密钥管理服务
3. 更新过时的依赖包
4. 启用安全头 (CSP, HSTS, etc.)

---
*由 security-auditor 自动生成*
```

## 自定义规则

在 `skills/security-auditor/rules/` 目录中添加自定义检测规则（如果需要）。
