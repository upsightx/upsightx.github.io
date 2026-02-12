# Agent Teams - Multi-Agent Coordination for OpenClaw

A powerful skill that enables OpenClaw to coordinate multiple sub-agents working in parallel on complex tasks.

## Features

- ✅ **Task Decomposition** - Break down complex tasks into manageable subtasks
- ✅ **Parallel Execution** - Spawn multiple sub-agents to work concurrently
- ✅ **Dependency Management** - Handle task dependencies and execution order
- ✅ **Result Aggregation** - Combine and synthesize results from multiple agents
- ✅ **Error Handling** - Retry failed subtasks and handle timeouts

## Quick Start

```bash
# Run a parallel task
./scripts/run.sh "Analyze files: file1.js, file2.js, file3.js"

# Monitor active tasks
./scripts/monitor.sh

# View task results
./scripts/results.sh <task-id>

# List all tasks
./scripts/list.sh

# Cancel a running task
./scripts/cancel.sh <task-id>
```

## Example

Run the included demonstration:

```bash
./examples/test-parallel-analysis.sh
```

This will:
1. Create test files
2. Run a parallel analysis task
3. Show real-time monitoring
4. Display aggregated results

## Documentation

See [SKILL.md](./SKILL.md) for complete documentation including:
- Task decomposition strategies
- Error handling policies
- Integration guide
- Best practices

## Examples

See [examples/README.md](./examples/README.md) for example scripts and patterns.

## Status

- **Version**: 1.0
- **Status**: ✅ Implemented and tested
- **Requirements**: `jq` (JSON processor)
