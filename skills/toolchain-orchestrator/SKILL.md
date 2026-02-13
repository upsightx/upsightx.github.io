# Toolchain Orchestrator

## Overview

Enhances OpenClaw's tool orchestration to handle complex multi-step workflows with many tool invocations. Inspired by GPT-5's improved long tool chain execution capabilities.

## Features

- **Tool Dependency Analysis**: Automatically detect dependencies between tool calls
- **Chain Planning (DAG)**: Build directed acyclic graphs for optimal execution order
- **Parallel Execution**: Run independent tools simultaneously where possible
- **Result Aggregation**: Combine tool outputs into structured results
- **Error Recovery**: Retry failed tools with configurable strategies
- **Chain Visualization**: Display execution graph and status

## Core Concepts

### Chain Definition

A chain is defined in JSON format with the following structure:

```json
{
  "id": "chain-001",
  "name": "Example Chain",
  "description": "Demonstrates basic tool chaining",
  "tools": [
    {
      "id": "tool-1",
      "name": "read_file",
      "params": {"path": "/tmp/data.txt"},
      "depends_on": []
    },
    {
      "id": "tool-2",
      "name": "process_data",
      "params": {"input": "{{tool-1}}"},
      "depends_on": ["tool-1"]
    }
  ],
  "config": {
    "max_parallel": 3,
    "retry_count": 2,
    "timeout": 30
  }
}
```

### Dependencies

Tools declare dependencies via `depends_on` array:
- Empty array: no dependencies (can run first)
- List of tool IDs: must wait for those tools to complete

### Result References

Use `{{tool-id}}` to reference output from previous tools:
- `{{tool-1}}` - full output of tool-1
- `{{tool-1.data}}` - specific field from tool-1 output

## Usage

### Plan a Chain from Natural Language

```bash
./skills/toolchain-orchestrator/scripts/plan.sh "read file, process data, and save results"
```

Outputs a chain definition JSON file in `chains/` directory.

### Visualize a Chain

```bash
./skills/toolchain-orchestrator/scripts/visualize.sh chain-001
```

Shows:
- Execution graph (ASCII art)
- Tool dependencies
- Parallel execution groups
- Estimated execution order

### Run a Chain

```bash
./skills/toolchain-orchestrator/scripts/run.sh chain-001
```

Monitors execution and stores results in `memory/` directory.

### Check Chain Status

```bash
./skills/toolchain-orchestrator/scripts/status.sh chain-001
```

Shows:
- Overall status (pending, running, completed, failed)
- Individual tool statuses
- Execution time
- Error details (if any)

## Directory Structure

```
toolchain-orchestrator/
├── SKILL.md           # This file
├── scripts/
│   ├── plan.sh        # Plan chains from natural language
│   ├── visualize.sh   # Visualize chain execution graph
│   ├── run.sh         # Execute chains with monitoring
│   ├── status.sh      # Check chain status
│   ├── validate.sh    # Validate chain definitions
│   └── retry.sh       # Retry failed tools in a chain
├── examples/
│   ├── simple-chain.json
│   ├── parallel-chain.json
│   ├── complex-workflow.json
│   └── error-handling-demo.json
├── chains/
│   └── *.json         # User-defined chains
└── memory/
    ├── executions.json  # Execution history
    └── chain-001.json  # Individual chain results
```

## Configuration

### Global Config (memory/config.json)

```json
{
  "default_max_parallel": 3,
  "default_retry_count": 2,
  "default_timeout": 30,
  "log_level": "info",
  "enable_dry_run": false
}
```

### Chain-Level Config

Overrides global config per chain:

```json
{
  "config": {
    "max_parallel": 5,
    "retry_count": 3,
    "timeout": 60,
    "on_error": "continue"  // or "stop"
  }
}
```

## Error Handling

### Retry Strategies

1. **Immediate Retry**: Retry immediately after failure
2. **Exponential Backoff**: Wait 2^retry_count seconds between retries
3. **Fallback**: Run alternative tool if configured

### Error Propagation

- `on_error: "stop"` - halt chain on first error
- `on_error: "continue"` - skip failed tool, continue with others
- `on_error: "fallback"` - use fallback tool if configured

## Execution Flow

```
1. Load Chain Definition
   ↓
2. Validate Syntax & Dependencies
   ↓
3. Build Execution DAG
   ↓
4. Identify Parallel Groups
   ↓
5. Execute Groups Sequentially (parallel within groups)
   ↓
6. Aggregate Results
   ↓
7. Save to Memory
```

## API Integration

The orchestrator can call OpenClaw tools via:
- Shell commands (for CLI tools)
- Direct function calls (for internal skills)
- HTTP requests (for web APIs)

## Examples

See `examples/` directory for:
- Simple sequential chains
- Parallel execution demonstrations
- Error handling patterns
- Complex multi-step workflows

## Testing

Run the test suite:

```bash
./skills/toolchain-orchestrator/scripts/test.sh
```

Tests:
- Dependency resolution
- Parallel execution logic
- Error recovery
- Result aggregation
- Chain validation

## Advanced Features

### Conditional Execution

```json
{
  "condition": "{{tool-1.status}} == 'success'",
  "if_true": ["tool-2"],
  "if_false": ["tool-3"]
}
```

### Loops

```json
{
  "loop": {
    "over": "{{tool-1.items}}",
    "as": "item",
    "tools": [
      {
        "name": "process_item",
        "params": {"item": "{{item}}"}
      }
    ]
  }
}
```

### Output Transformation

```json
{
  "output_transform": {
    "format": "json",
    "filter": ["field1", "field2"],
    "rename": {"field1": "name", "field2": "value"}
  }
}
```

## Performance Tips

1. **Maximize Parallelism**: Identify independent tools
2. **Reduce Dependencies**: Only depend on necessary outputs
3. **Optimize Timeouts**: Set appropriate timeouts per tool
4. **Batch Results**: Aggregate multiple outputs efficiently

## Troubleshooting

### Chain hangs
- Check for circular dependencies
- Verify timeouts are appropriate
- Use `status.sh` to see which tool is stuck

### Parallel tools not running
- Verify `max_parallel` config
- Check system resource limits
- Review dependency declarations

### Tools failing repeatedly
- Check tool parameters
- Review error messages in execution log
- Consider fallback tools

## Contributing

To add new features:
1. Update SKILL.md with documentation
2. Implement in scripts/
3. Add examples to examples/
4. Update tests in test.sh
