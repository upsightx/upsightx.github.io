# Toolchain Orchestrator

A powerful tool orchestration system for OpenClaw that handles complex multi-step workflows with dependency tracking, parallel execution, and error recovery.

## Quick Start

### 1. Plan a Chain

```bash
cd /root/.openclaw/workspace/skills/toolchain-orchestrator

# Plan from natural language
./scripts/plan.sh "search web, fetch pages, extract content, and save results"

# Or use an example
cp examples/parallel-chain.json chains/
```

### 2. Visualize the Chain

```bash
./scripts/visualize.sh chain-$(date +%s)
```

### 3. Validate the Chain

```bash
./scripts/validate.sh chain-$(date +%s)
```

### 4. Execute the Chain

```bash
./scripts/run.sh chain-$(date +%s)

# Or dry-run first
./scripts/run.sh chain-$(date +%s) --dry-run
```

### 5. Check Status

```bash
./scripts/status.sh chain-$(date +%s) --tools
```

## Features

- **Dependency Analysis**: Automatically detect and resolve dependencies
- **Parallel Execution**: Run independent tools simultaneously
- **Error Recovery**: Retry failed tools with configurable strategies
- **Visualization**: See execution graph and parallel groups
- **Status Tracking**: Monitor individual tool and chain status

## Chain Structure

```json
{
  "id": "chain-001",
  "name": "My Chain",
  "description": "What this chain does",
  "tools": [
    {
      "id": "tool-1",
      "name": "tool_name",
      "params": {"key": "value"},
      "depends_on": []
    },
    {
      "id": "tool-2",
      "name": "another_tool",
      "params": {"input": "{{tool-1}}"},
      "depends_on": ["tool-1"]
    }
  ],
  "config": {
    "max_parallel": 3,
    "retry_count": 2,
    "timeout": 30,
    "on_error": "continue"
  }
}
```

## Examples

The `examples/` directory contains several ready-to-use chains:

- **simple-chain.json**: Sequential execution demo
- **parallel-chain.json**: Parallel execution with 3 independent fetches
- **complex-workflow.json**: Multi-stage workflow with search, fetch, extract, summarize
- **error-handling-demo.json**: Error recovery patterns

## Scripts

- **plan.sh**: Create chains from natural language
- **visualize.sh**: Display execution graph
- **run.sh**: Execute chains with monitoring
- **status.sh**: Check chain and tool status
- **validate.sh**: Validate chain definitions

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| max_parallel | 3 | Maximum parallel tools per level |
| retry_count | 2 | Retry attempts per tool |
| timeout | 30 | Timeout per tool (seconds) |
| on_error | continue | Error handling: "continue" or "stop" |

## See Also

- **SKILL.md**: Complete documentation
- **examples/**: Example chain definitions
- **chains/**: Your chain definitions
- **memory/**: Execution history and results
