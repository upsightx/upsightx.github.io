# Unified Router Skill

## Overview

The Unified Router implements the "Unified Code + General Intelligence" concept, bringing together coding and general-purpose intelligence in one seamless skill manager. Inspired by GPT-5's unified architecture, this skill intelligently routes tasks to the most appropriate skills based on task type and user intent.

## Core Philosophy

- **One Interface, Many Skills**: Users speak naturally; the router determines the best skill
- **Context Preservation**: Carry context between routing decisions for seamless switching
- **Intelligent Detection**: Automatically distinguish coding tasks from general tasks
- **Fallback Handling**: Graceful degradation to default skills when needed

## How It Works

### 1. Task Type Detection

The router analyzes user input to determine task type:

**Coding Tasks Detected:**
- Code generation requests ("create a function", "write a script")
- Debugging requests ("fix this bug", "debug this code")
- Code review requests ("review this", "analyze this code")
- Refactoring requests ("refactor", "optimize this code")
- Technical questions about languages, frameworks, APIs

**General Tasks Detected:**
- Questions ("what is", "how do I", "tell me about")
- Analysis requests ("analyze this", "summarize")
- Writing tasks ("write an article", "compose an email")
- Conversational interactions

### 2. Skill Routing

Based on task type, the router selects the best skill:

**Coding Tasks →** Coding Skills (when available):
- `project-analyzer`: Codebase analysis
- `security-auditor`: Security scanning
- `rag-memory`: Context-aware code retrieval

**General Tasks →** General Skills:
- `rag-memory`: Knowledge retrieval
- `knowledge-manager`: Information management
- `smart-reminder`: Reminders and scheduling

### 3. Fallback Handling

When specialized skills are unavailable or the task type is unclear, the router:
- Uses default OpenClaw capabilities
- Requests clarification if needed
- Provides helpful suggestions

## Usage

### Quick Start

```bash
# Test routing for a specific query
./scripts/test-route.sh "create a Python function that sorts a list"

# List all available skills
./scripts/inventory.sh

# Route and execute a task
./scripts/route-execute.sh "explain how recursion works"
```

### Examples

**Coding Task Routing:**
```bash
./scripts/test-route.sh "write a REST API endpoint"
# → Routes to coding skills

./scripts/test-route.sh "analyze this codebase for security issues"
# → Routes to security-auditor skill
```

**General Task Routing:**
```bash
./scripts/test-route.sh "what is machine learning?"
# → Routes to general skills (rag-memory, knowledge-manager)

./scripts/test-route.sh "remind me to call Alice at 3pm"
# → Routes to smart-reminder skill
```

## API / Script Interface

### `scripts/test-route.sh` - Test Routing

Analyze and display which skill would handle a task (without executing).

```bash
./scripts/test-route.sh "your query here"
```

**Output:**
```
[UNIFIED ROUTER] Task Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Query: "create a Python function"
Task Type: CODING
Confidence: 0.92
Recommended Skill: coding-stack (project-analyzer + security-auditor)
Fallback: default
```

### `scripts/inventory.sh` - Skill Inventory

List all available skills with their types and capabilities.

```bash
./scripts/inventory.sh
```

**Output:**
```
[UNIFIED ROUTER] Skill Inventory
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CODING SKILLS:
  • project-analyzer: Codebase analysis and metrics
  • security-auditor: Security vulnerability scanning

GENERAL SKILLS:
  • rag-memory: Knowledge retrieval and RAG
  • knowledge-manager: Information management
  • smart-reminder: Reminder and scheduling

UNCATEGORIZED:
  • agent-teams: Multi-agent coordination
```

### `scripts/route-execute.sh` - Route and Execute

Full routing analysis plus execution through the selected skill.

```bash
./scripts/route-execute.sh "your task here"
```

## Configuration

### Skill Mapping

Edit `scripts/config.sh` to customize routing rules:

```bash
# Coding skill priority
CODING_SKILLS="project-analyzer,security-auditor"

# General skill priority
GENERAL_SKILLS="rag-memory,knowledge-manager,smart-reminder"

# Default fallback
DEFAULT_SKILL="default"
```

### Thresholds

Adjust confidence thresholds for routing:

```bash
# Minimum confidence for auto-routing
MIN_CONFIDENCE=0.7

# Require confirmation below this
CONFIRM_THRESHOLD=0.5
```

## Extending the Router

### Adding New Skills

1. Register skill in `scripts/skills.json`:

```json
{
  "name": "your-skill",
  "type": "coding|general",
  "description": "Brief description",
  "capabilities": ["capability1", "capability2"],
  "keywords": ["keyword1", "keyword2"],
  "script": "./scripts/your-skill/run.sh"
}
```

2. Update routing logic in `scripts/route.sh` if needed

### Adding New Detection Patterns

Edit `scripts/detect.sh` to add new task type patterns:

```bash
# Your detection logic
if [[ "$query" =~ your_pattern ]]; then
    echo "your_task_type"
    exit 0
fi
```

## Architecture

```
unified-router/
├── SKILL.md              # This file
├── scripts/
│   ├── config.sh         # Configuration
│   ├── detect.sh         # Task type detection
│   ├── route.sh          # Skill routing logic
│   ├── skills.json       # Skill registry
│   ├── test-route.sh     # Test routing (non-exec)
│   ├── inventory.sh      # List available skills
│   └── route-execute.sh  # Route + execute
└── examples/
    ├── coding-tasks.txt  # Sample coding queries
    └── general-tasks.txt # Sample general queries
```

## Best Practices

### For Users

- **Be Specific**: Clear queries lead to better routing
- **Use Natural Language**: The router understands conversational input
- **Provide Context**: Include relevant details for complex tasks
- **Review Routing**: Use `test-route.sh` to understand how tasks are classified

### For Developers

- **Keep Skills Focused**: Each skill should have clear purpose
- **Register Properly**: Update `skills.json` when adding skills
- **Test Routings**: Verify detection works for your skill's use cases
- **Handle Errors**: Skills should gracefully handle unsupported tasks

## Troubleshooting

**Issue: Task routed to wrong skill**
- Run `test-route.sh` to see classification details
- Check `detect.sh` for pattern conflicts
- Adjust keywords in `skills.json`

**Issue: Skill not found**
- Verify skill directory exists
- Check `skills.json` registration
`inventory.sh` to see available skills

**Issue: Low confidence warnings**
- Task may be ambiguous - provide more context
- Adjust thresholds in `config.sh`
- Add clarifying questions to your query

## Performance Notes

- Detection runs in <10ms for typical queries
- Skill inventory cached after first call
- Context preserved in session state
- No external dependencies required

## License

Part of OpenClaw workspace. Follow OpenClaw license terms.

## Version

1.0.0 - Initial implementation
- Task type detection
- Skill routing
- Fallback handling
- Test suite
