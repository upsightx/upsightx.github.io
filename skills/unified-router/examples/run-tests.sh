#!/bin/bash
# Test Suite for Unified Router
# Demonstrates routing for various coding and general tasks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
SCRIPT_DIR="$SCRIPT_DIR/scripts"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Unified Router - Test Suite                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Test coding tasks
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Coding Tasks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

coding_tests=(
    "create a Python function that sorts a list"
    "write a REST API endpoint in Node.js"
    "debug why the database connection is failing"
    "review this codebase for security issues"
    "refactor this function to be more efficient"
)

for test in "${coding_tests[@]}"; do
    echo "Test: \"$test\""
    $SCRIPT_DIR/test-route.sh "$test"
    echo ""
    read -p "Press Enter to continue..."
    echo ""
done

# Test general tasks
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing General Tasks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

general_tests=(
    "what is machine learning"
    "how do I install Python on Linux"
    "write an article about open source"
    "remind me to review the code at 3pm"
    "explain how recursion works"
)

for test in "${general_tests[@]}"; do
    echo "Test: \"$test\""
    $SCRIPT_DIR/test-route.sh "$test"
    echo ""
    read -p "Press Enter to continue..."
    echo ""
done

# Show inventory
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Skill Inventory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
$SCRIPT_DIR/inventory.sh

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Test Suite Complete                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
