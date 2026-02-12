#!/bin/bash
# Retrieve context from RAG memory formatted for LLM
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
        color_error "Usage: $0 <query> [--max-tokens N] [--include-scores]"
        echo
        echo "Examples:"
        echo "  $0 'What did the user ask about yesterday?'"
        echo "  $0 'Security audit findings' --max-tokens 2000"
        echo "  $0 'How to deploy the application' --include-scores"
        exit 1
    fi
    
    # Run retrieve
    "$SCRIPT_DIR/rag-memory" retrieve "$@"
}

# Run main
main "$@"
