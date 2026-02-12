# RAG Memory Skill

A vector-based memory implementation for OpenClaw using Retrieval Augmented Generation (RAG).

## Quick Start

```bash
# Initialize
cd /root/.openclaw/workspace/skills/rag-memory
./scripts/rag-memory init

# Ingest memory files
./scripts/rag-memory ingest --source /root/.openclaw/workspace/memory/

# Search for context
./scripts/search.sh "security vulnerabilities" --top-k 3

# Retrieve context for LLM
./scripts/retrieve.sh "What happened yesterday?" --max-tokens 2000

# Show statistics
./scripts/rag-memory stats
```

## Scripts

- `rag-memory` - Main CLI tool
- `search.sh` - Semantic search wrapper
- `retrieve.sh` - Context retrieval wrapper
- `ingest-all.sh` - Ingest all OpenClaw memory files

## Current Status

- **Backend**: SQLite with hash-based embeddings
- **Chunks stored**: 67+
- **Tokens**: ~38,000
- **Storage**: ~700KB

## Notes

The hash-based embedding method works offline and is fast but has limited semantic understanding. For production use with better search results, consider:
- Using Chroma backend (requires `pip install chromadb`)
- Configuring OpenAI embeddings (requires API key)

See SKILL.md for full documentation.
