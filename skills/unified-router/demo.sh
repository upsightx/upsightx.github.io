#!/bin/bash
# Quick demo of unified router functionality

SCRIPT_DIR="/root/.openclaw/workspace/skills/unified-router/scripts"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Unified Router - Quick Demo                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Coding task
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Coding Task (Code Generation)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SCRIPT_DIR/test-route.sh "create a Python function that sorts a list"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 2: Debugging task
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Coding Task (Debugging)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SCRIPT_DIR/test-route.sh "debug why the database connection is failing"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 3: Security task
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Coding Task (Security Audit)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SCRIPT_DIR/test-route.sh "review this codebase for security vulnerabilities"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 4: General question
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: General Task (Knowledge Question)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SCRIPT_DIR/test-route.sh "explain how recursion works"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 5: Reminder task
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: General Task (Reminder)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SCRIPT_DIR/test-route.sh "remind me to review the code at 3pm"
echo ""
read -p "Press Enter to continue..."
echo ""

# Show inventory
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Skill Inventory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SCRIPT_DIR/inventory.sh

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Demo Complete                                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
