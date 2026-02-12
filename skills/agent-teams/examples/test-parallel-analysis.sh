#!/bin/bash
#
# test-parallel-analysis.sh - Example script demonstrating multi-agent task coordination
#
# This script demonstrates the agent-teams skill by:
# 1. Creating sample test files
# 2. Running a parallel analysis task
# 3. Monitoring progress
# 4. Displaying aggregated results
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$SKILL_DIR/examples/test-files"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_step() { echo -e "${CYAN}>>>${NC} $1"; }

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Agent Teams - Parallel Analysis Demo${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Step 1: Create test files
log_step "Creating test files..."
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/auth.js" << 'EOF'
// Authentication module
const bcrypt = require('bcrypt');

class AuthService {
    constructor() {
        this.users = new Map();
    }

    async register(username, password) {
        if (this.users.has(username)) {
            throw new Error('User already exists');
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        this.users.set(username, hashedPassword);
        return { success: true, username };
    }

    async login(username, password) {
        const hashedPassword = this.users.get(username);
        if (!hashedPassword) {
            throw new Error('Invalid credentials');
            // TODO: Add rate limiting
        }
        const isValid = await bcrypt.compare(password, hashedPassword);
        if (!isValid) {
            throw new Error('Invalid credentials');
        }
        return { success: true, username };
    }
}

module.exports = AuthService;
EOF

cat > "$TEST_DIR/database.js" << 'EOF'
// Database module
const sqlite3 = require('sqlite3').verbose();

class DatabaseService {
    constructor(dbPath) {
        this.db = new sqlite3.Database(dbPath);
    }

    async query(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.all(sql, params, (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }

    async insert(table, data) {
        const keys = Object.keys(data);
        const values = Object.values(data);
        const placeholders = keys.map(() => '?').join(',');

        const sql = `INSERT INTO ${table} (${keys.join(',')}) VALUES (${placeholders})`;

        return new Promise((resolve, reject) => {
            this.db.run(sql, values, function(err) {
                if (err) reject(err);
                else resolve({ id: this.lastID });
            });
        });
    }

    close() {
        this.db.close();
    }
}

module.exports = DatabaseService;
EOF

cat > "$TEST_DIR/api.js" << 'EOF'
// API module
const express = require('express');

class ApiService {
    constructor(port = 3000) {
        this.app = express();
        this.port = port;
        this.routes = [];
    }

    init() {
        this.app.use(express.json());

        // Health check
        this.app.get('/health', (req, res) => {
            res.json({ status: 'ok', timestamp: Date.now() });
        });

        return this;
    }

    addRoute(method, path, handler) {
        this.routes.push({ method, path });
        this.app[method.toLowerCase()](path, handler);
    }

    start() {
        return new Promise((resolve) => {
            this.server = this.app.listen(this.port, () => {
                console.log(`API server listening on port ${this.port}`);
                resolve();
            });
        });
    }

    stop() {
        if (this.server) {
            this.server.close();
        }
    }
}

module.exports = ApiService;
EOF

cat > "$TEST_DIR/utils.js" << 'EOF'
// Utility functions
const crypto = require('crypto');

function generateToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
}

function sanitizeInput(input) {
    if (typeof input !== 'string') return '';
    return input.replace(/[<>]/g, '');
}

function formatDate(date) {
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    }).format(date);
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

module.exports = {
    generateToken,
    sanitizeInput,
    formatDate,
    debounce
};
EOF

log_success "Test files created: auth.js, database.js, api.js, utils.js"
echo ""

# Step 2: Run parallel analysis task
log_step "Running parallel analysis task..."
echo ""

# Create a task description for analyzing the files
TASK_DESC="Analyze the following JavaScript files for code quality, best practices, and potential issues:
- $TEST_DIR/auth.js
- $TEST_DIR/database.js
- $TEST_DIR/api.js
- $TEST_DIR/utils.js

For each file, report:
1. Code structure and complexity
2. Any anti-patterns or issues found
3. Security considerations
4. Suggested improvements"

if [ ! -f "$SKILL_DIR/scripts/run.sh" ]; then
    log_info "Making scripts executable..."
    chmod +x "$SKILL_DIR/scripts"/*.sh
fi

log_info "Task description: $TASK_DESC"
echo ""
log_info "Executing task..."

# Run the task
TASK_ID=$("$SKILL_DIR/scripts/run.sh" "$TASK_DESC" --max-parallel 3)

if [ -z "$TASK_ID" ]; then
    log_info "Task execution completed (no task ID returned)"
else
    log_success "Task started with ID: $TASK_ID"
fi

echo ""

# Step 3: Monitor progress
log_step "Monitoring task progress..."
echo ""

"$SKILL_DIR/scripts/monitor.sh"

echo ""

# Step 4: Show task list
log_step "Listing all tasks..."
echo ""

"$SKILL_DIR/scripts/list.sh" --status all

echo ""

# Step 5: Display results
if [ -n "$TASK_ID" ]; then
    log_step "Displaying results for task: $TASK_ID"
    echo ""

    "$SKILL_DIR/scripts/results.sh" "$TASK_ID" --format text
else
    log_step "Displaying latest task results..."
    echo ""

    # Get the most recent task ID
    TASK_ID=$(jq -r '.tasks | keys | last' "$SKILL_DIR/memory/tasks.json" 2>/dev/null || echo "")
    if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "null" ]; then
        "$SKILL_DIR/scripts/results.sh" "$TASK_ID" --format text
    else
        log_info "No tasks found to display results"
    fi
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Test completed successfully!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "What was demonstrated:"
echo "  1. Created 4 test JavaScript files"
echo "  2. Decomposed analysis task into parallel subtasks"
echo "  3. Coordinated sub-agent execution"
echo "  4. Aggregated results from all subtasks"
echo "  5. Displayed unified results"
echo ""
echo "You can view the skill at: $SKILL_DIR"
echo "Test files are located at: $TEST_DIR"
echo ""
