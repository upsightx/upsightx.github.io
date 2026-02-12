# Agent Teams Examples

This directory contains example scripts demonstrating the agent-teams skill.

## Test Scripts

### test-parallel-analysis.sh

Demonstrates parallel file analysis using multiple sub-agents:

```bash
./test-parallel-analysis.sh
```

What this script does:

1. **Creates test files** - Generates 4 JavaScript files (auth.js, database.js, api.js, utils.js)
2. **Runs parallel analysis** - Decomposes the task and spawns 3 sub-agents
3. **Monitors progress** - Shows real-time task and subtask status
4. **Displays results** - Shows aggregated results from all sub-agents

## Running Examples

From the skill directory:

```bash
# Run the parallel analysis test
./examples/test-parallel-analysis.sh
```

## Creating Your Own Examples

Use the test script as a template. The basic pattern is:

```bash
# 1. Prepare your data/files
# ...

# 2. Run the task
TASK_ID=$("./scripts/run.sh" "Your task description" --max-parallel N)

# 3. Monitor (optional)
./scripts/monitor.sh

# 4. View results
./scripts/results.sh "$TASK_ID"
```

## Example Task Patterns

### Parallel File Processing

```bash
./scripts/run.sh "Analyze files: file1.js, file2.js, file3.js for security vulnerabilities"
```

### Parallel Web Scraping

```bash
./scripts/run.sh "Fetch content from: https://example1.com, https://example2.com, https://example3.com"
```

### Sequential Dependencies

```bash
./scripts/run.sh "1. Fetch data from API
2. Transform and validate data
3. Generate report from data
4. Save report to database"
```

### Code Generation

```bash
./scripts/run.sh "Generate unit tests for modules: auth, database, api, utils"
```
