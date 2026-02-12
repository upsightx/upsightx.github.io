---
name: agent-teams
description: Multi-agent coordination for OpenClaw - split complex tasks into parallel subtasks, coordinate execution, and aggregate results.
---

# Agent Teams - Multi-Agent Coordination for OpenClaw

## Overview

Agent Teams enables OpenClaw to spawn and coordinate multiple sub-agents working in parallel on different aspects of a complex task. Inspired by Claude Opus 4.6's agent teams feature, this skill provides:

- **Task Decomposition** - Break down complex tasks into manageable subtasks
- **Parallel Execution** - Spawn multiple sub-agents to work concurrently
- **Dependency Management** - Handle task dependencies and execution order
- **Result Aggregation** - Combine and synthesize results from multiple agents
- **Error Handling** - Retry failed subtasks and handle timeouts

## Core Concepts

### Task Structure

```json
{
  "id": "task-uuid",
  "description": "Analyze multiple code files in parallel",
  "status": "pending",
  "createdAt": "2026-02-13T06:30:00Z",
  "subtasks": [
    {
      "id": "subtask-1",
      "description": "Analyze auth module",
      "status": "pending",
      "dependsOn": [],
      "priority": "high",
      "timeout": 300
    },
    {
      "id": "subtask-2",
      "description": "Analyze database module",
      "status": "pending",
      "dependsOn": [],
      "priority": "high",
      "timeout": 300
    }
  ],
  "results": {}
}
```

### Task Status Values

- `pending` - Waiting to start
- `running` - Currently executing
- `completed` - Finished successfully
- `failed` - Failed with error
- `retrying` - Retrying after failure

## Usage

### 1. Simple Parallel Task

User command:
```
Run agent-teams task: Analyze these files in parallel: auth.js, database.js, api.js
```

The main agent will:
1. Decompose the task into 3 subtasks (one per file)
2. Spawn 3 sub-agents in parallel
3. Aggregate results into a unified report

### 2. Task with Dependencies

User command:
`````
Run agent-teams task:
1. Fetch data from API (primary)
2. Transform data (depends on 1)
3. Generate report (depends on 2)
4. Send notification (depends on 3)
`````

The system will execute tasks in dependency order, with parallel execution where possible.

### 3. Using Scripts

```bash
# Run a coordinated task
./skills/agent-teams/scripts/run.sh "task-description"

# Monitor active tasks
./skills/agent-teams/scripts/monitor.sh

# View results of a specific task
./skills/agent-teams/scripts/results.sh <task-id>

# List all tasks
./skills/agent-teams/scripts/list.sh

# Cancel a running task
./skills/agent-teams/scripts/cancel.sh <task-id>
```

## Execution Scripts

### `scripts/run.sh`

Coordinates multi-agent task execution.

**Usage:**
```bash
./run.sh "<task-description>" [--max-parallel N] [--timeout S]
```

**Options:**
- `--max-parallel N` - Maximum concurrent sub-agents (default: 3)
- `--timeout S` - Default subtask timeout in seconds (default: 300)

**Output:**
- Task ID
- Subtask breakdown
- Real-time progress updates
- Final aggregated results

### `scripts/monitor.sh`

Monitor active agent-teams tasks.

**Usage:**
```bash
./monitor.sh [--follow]
```

**Options:**
- `--follow` - Continuously refresh (watch mode)

**Output:**
- Active tasks with status
- Subagent sessions
- Progress bars
- Time elapsed

### `scripts/results.sh`

View results of a completed task.

**Usage:**
```bash
./results.sh <task-id> [--format json|markdown]
```

**Output:**
- Task summary
- Individual subtask results
- Aggregated final result
- Errors and warnings

### `scripts/list.sh`

List all agent-teams tasks.

**Usage:**
```bash
./list.sh [--status all|pending|running|completed|failed]
```

**Output:**
- Task list with filters
- Summary statistics

### `scripts/cancel.sh`

Cancel a running task and terminate sub-agents.

**Usage:**
```bash
./cancel.sh <task-id>
```

## Memory Structure

### `memory/tasks.json`

Stores all task definitions and status.

```json
{
  "tasks": {
    "task-uuid": {
      "id": "task-uuid",
      "description": "...",
      "status": "completed",
      "subtasks": [...],
      "results": {...},
      "metadata": {
        "createdAt": "...",
        "completedAt": "...",
        "totalDuration": 45.2
      }
    }
  },
  "lastUpdated": "2026-02-13T06:30:00Z"
}
```

### `memory/sessions.json`

Tracks sub-agent sessions.

```json
{
  "sessions": {
    "session-uuid": {
      "id": "session-uuid",
      "taskId": "task-uuid",
      "subtaskId": "subtask-1",
      "status": "completed",
      "pid": 12345
    }
  }
}
```

## Task Decomposition Strategies

### Strategy 1: List-Based Decomposition

For tasks like "analyze these files", "process these URLs":
- Split input list into individual subtasks
- All subtasks are independent (parallel execution)

### Strategy 2: Sequential Dependency

For tasks with clear ordering (fetch → transform → save):
- Each subtask depends on previous
- Sequential execution

### Strategy 3: Dependency Graph

For complex workflows:
- Build dependency graph
- Use topological sort for execution order
- Execute independent tasks in parallel

## Error Handling

### Retry Policy

- **Transient errors**: Retry up to 3 times with exponential backoff
- **Permanent errors**: Mark as failed, continue with other subtasks
- **Timeout**: Kill subprocess, mark as timed out, optional retry

### Failure Modes

- **Continue on error**: Complete successful subtasks, report failures
- **Fail fast**: Stop entire task on first subtask failure
- **Best effort**: Aggregate partial results

## Best Practices

1. **Keep subtasks focused** - Each subtask should do one thing well
2. **Set appropriate timeouts** - Prevent hanging subtasks
3. **Limit parallelism** - Don't overwhelm system resources (default: 3)
4. **Clear descriptions** - Help sub-agents understand their scope
5. **Handle partial failures** - Design tasks to be resilient

## Integration with OpenClaw

### Main Agent Usage

When a user requests parallel work:

```bash
# The main agent should:
1. Call run.sh with task description
2. Monitor progress with monitor.sh
3. Retrieve results with results.sh
4. Present aggregated results to user
```

### Example Workflow

```bash
# User: "Analyze all Python files in src/ directory"

# Main agent:
./skills/agent-teams/scripts/run.sh \
  "Find all Python files in src/ directory and analyze each one for code quality issues. For each file: check for PEP8 violations, identify complexity issues, suggest improvements. Return a consolidated report with file-by-file findings analysis." \
  --max-parallel 5

# System:
- Decomposes: [file1.py] [file2.py] [file3.py] ... (5 subtasks)
- Spawns: 5 sub-agents in parallel
- Monitors: Progress updates every 10s
- Aggregates: Combines all file analyses into unified report
- Returns: Complete code quality report
```

## Example Task Templates

### Parallel File Analysis

```bash
./run.sh "Analyze files: file1.js, file2.js, file3.js for security vulnerabilities"
```

### Parallel Web Scraping

```bash
./run.sh "Fetch and extract content from: url1, url2, url3, url4, url5" --max-parallel 3
```

### Batch Processing

```bash
./run.sh "Process these images for OCR: img1.png, img2.png, img3.png" --timeout 600
```

### Parallel Code Generation

```bash
./run.sh "Generate unit tests for modules: auth, database, api, utils"
```

## Technical Implementation

### Sub-Agent Spawning

Uses `openclaw agent spawn` to create agent sessions:

```bash
openclaw agent spawn --model ark/glm-4.7 --timeout 300
```

### Process Tracking

Uses `openclaw agent list` and `openclaw agent kill` for session management.

### Result Collection

Sub-agents write results to:
- `memory/results/<task-id>/<subtask-id>.json`

Main agent reads and aggregates these files.

## Performance Considerations

- **Parallelism vs Resources**: Default max-parallel=3 balances speed with resource usage
- **Timeout Management**: Prevents indefinite hangs
- **Memory Usage**: Each sub-agent creates a session; monitor system load
- **Network Bound**: For I/O tasks, higher parallelism helps
- **CPU Bound**: For compute tasks, limit to core count

## Testing

See `examples/test-parallel-analysis.sh` for a complete working example.

Run test:
```bash
./examples/test-parallel-analysis.sh
```

## Troubleshooting

### Subtasks hanging

Check with `./monitor.sh --follow` and use `./cancel.sh <task-id>` if needed.

### Partial results

Check `./results.sh <task-id>`` for error messages and retry options.

### High resource usage

Reduce `--max-parallel` or cancel active tasks.

## Future Enhancements

- [ ] Visual task graph display
- [ ] Task templates library
- [ ] Sub-agent communication channels
- [ ] Result streaming (real-time aggregation)
- [ ] Task checkpointing and resume
- [ ] Resource-aware parallelism scaling
