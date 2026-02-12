# Security Auditor 自定义规则

此目录用于存放自定义安全检测规则。

## 规则格式

规则文件采用 YAML 或 JSON 格式，定义自定义的检测模式。

### 示例规则 (YAML)

```yaml
name: "custom_api_key_leak"
severity: "HIGH"
type: "hardcoded_secrets"
description: "检测自定义 API 密钥泄露"
patterns:
  - "CUSTOM_API_KEY\s*=\s*['\"][^'\"]+['\"]"
  - "serviceAuthToken\s*=\s*['\"][^'\"]+['\"]"
suggestion: "使用环境变量或密钥管理服务存储 API 密钥"
extensions:
  - ".js"
  - ".py"
  - ".ts"
```

## 添加规则

1. 在此目录创建规则文件（.yaml 或 .json）
2. 主扫描脚本会自动加载这些规则
3. 下次运行扫描时会应用新规则

## 规则最佳实践

- 使用精确的正则表达式避免误报
- 提供清晰的修复建议
- 设置正确的严重级别
- 限制定位到特定文件类型
