#!/bin/bash
# Semantic search script for RAG memory
# Part of the rag-memory skill

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
color_info() { echo -e "\e[34mℹ $1\e[0m"; }
color_success() { echo -e "\e[32m✅ $1\e[0m"; }
color_warn() { echo -e "\e[33m⚠️  $1\e[0m"; }
color_error() { echo -e "\e[31m❌ $1\e[0m"; }

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        color_error "Usage: $0 <query> [--top-k N] [--threshold X] [--type TYPE]"
        echo
        echo "Examples:"
        echo "  $0 'security vulnerabilities' --top-k 5"
        echo "  $0 'How do I use the project-analyzer skill?'"
        echo "  $0 'What was I working on yesterday?' --type daily"
        exit 1
    fi
    
    # Run search
    "$SCRIPT_DIR/rag-memory" search "$@"
}

# Run main
main "$@"
