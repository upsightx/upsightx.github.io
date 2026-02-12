#!/bin/bash
# Ingest all OpenClaw memory files into RAG memory
# Part of the rag-memory skill

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")"))"

# Colors
color_info() { echo -e "\e[34mℹ $1\e[0m"; }
color_success() { echo -e "\e[32m✅ $1\e[0m"; }
color_warn() { echo -e "\e[33m⚠️  $1\e[0m"; }
color_error() { echo -e "\e[31m❌ $1\e[0m"; }

# Main function
main() {
    color_info "Ingesting OpenClaw memory files into RAG memory..."
    echo
    
    cd "$WORKSPACE"
    
    # Initialize RAG memory
    color_info "Initializing RAG memory..."
    "$SCRIPT_DIR/rag-memory" init
    echo
    
    # Count total files
    total_files=0
    
    # Ingest MEMORY.md if it exists
    if [[ -f "MEMORY.md" ]]; then
        color_info "Ingesting MEMORY.md (long-term memory)..."
        "$SCRIPT_DIR/rag-memory" ingest --source "MEMORY.md"
        total_files=$((total_files + 1))
        echo
    fi
    
    # Ingest daily memory files
    if [[ -d "memory" ]]; then
        color_info "Ingesting daily memory files..."
        
        # Count markdown files in memory directory
        md_count=$(find memory -name "*.md" 2>/dev/null | wc -l)
        
        if [[ $md_count -gt 0 ]]; then
            "$SCRIPT_DIR/rag-memory" ingest --source memory/
            total_files=$((total_files + md_count))
        else
            color_warn "No markdown files found in memory/"
        fi
        echo
    fi
    
    # Ingest skill documentation
    if [[ -d "skills" ]]; then
        color_info "Ingesting skill documentation..."
        
        skill_count=$(find skills -name "SKILL.md" 2>/dev/null | wc -l)
        
        if [[ $skill_count -gt 0 ]]; then
            "$SCRIPT_DIR/rag-memory" ingest --source skills/ --type skill-docs
            total_files=$((total_files + skill_count))
        else
            color_warn "No SKILL.md files found in skills/"
        fi
        echo
    fi
    
    # Show stats
    color_success "Ingestion complete!"
    echo
    "$SCRIPT_DIR/rag-memory" stats
    
    color_success "Successfully ingested $total_files+ files"
}

# Run main
main "$@"
