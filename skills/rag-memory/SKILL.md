# RAG Memory Skill - External Vector Memory for OpenClaw

## Overview

This skill implements **Retrieval Augmented Generation (RAG)** using vector embeddings to simulate 1M+ token context for OpenClaw. By storing text chunks as vectors and performing semantic search, you can retrieve relevant context without paying for massive token usage.

## Features

- **Vector Embedding Storage**: Store text chunks with semantic embeddings
- **Semantic Search**: Find relevant context using vector similarity
- **Memory Integration**: Seamlessly integrates with OpenClaw's MEMORY.md and daily memory files
- **Multiple Backend Options**: 
  - **SQLite + NumPy** (default, lightweight, no external dependencies)
  - **Chroma** (recommended, persistent, more features)
  - **Pinecone** (cloud, production-ready)
  - **Weaviate** (cloud/self-hosted, powerful)
- **CLI Interface**: Easy-to-use commands for ingesting, searching, and retrieving

## Installation

### Prerequisites

```bash
# Base dependencies (already included in OpenClaw)
pip3 install numpy

# For NumPy-free operation (pure Python cosine similarity)
# No additional requirements needed

# For Chroma backend (recommended)
pip3 install chromadb

# For Pinecone backend
pip3 install pinecone-client

# For Weaviate backend
pip3 install weaviate-client
```

### Quick Start

```bash
# Initialize the memory store
rag-memory init

# Ingest OpenClaw memory files
rag-memory ingest --source memory/

# Search for relevant context
rag-memory search "security vulnerabilities" --top-k 5

# Retrieve context formatted for LLM
rag-memory retrieve "How does OpenClaw handle security?"
```

## Commands

### `rag-memory init`

Initialize the vector memory store.

```bash
rag-memory init [--backend {sqlite,chroma,pinecone,weaviate}] [--path /path/to/store]
```

**Options:**
- `--backend`: Vector database backend (default: sqlite)
- `--path`: Storage path (default: `~/.openclaw/data/rag-memory/`)

### `rag-memory ingest`

Ingest documents into the vector store.

```bash
rag-memory ingest --source /path/to/file.md
rag-memory ingest --source /path/to/directory/
rag-memory ingest --text "Some text to remember"
rag-memory ingest --source memory/ --type daily
```

**Options:**
- `--source`: File or directory to ingest (or use `--text`)
- `--text`: Direct text to ingest
- `--type`: Content type (auto, daily, longterm, code, docs)
- `--chunk-size`: Max tokens per chunk (default: 500)
- `--chunk-overlap`: Overlap between chunks (default: 50)
- `--metadata`: JSON metadata to attach

**Supported formats:**
- Markdown (.md)
- Text files (.txt)
- JSON (.json)
- Code files (.py, .js, .ts, .sh, etc.)

### `rag-memory search`

Perform semantic search for relevant chunks.

```bash
rag-memory search "security vulnerabilities" --top-k 5
rag-memory search "How do I use the project-analyzer skill?" --type skill
```

**Options:**
- `--query`: Search query (or positional argument)
- `--top-k`: Number of results (default: 5)
- `--threshold`: Minimum similarity score (default: 0.5)
- `--type`: Filter by content type
- `--format`: Output format (json, text, markdown)

### `rag-memory retrieve`

Retrieve context formatted for LLM consumption.

```bash
rag-memory retrieve "What did the user ask about yesterday?"
rag-memory retrieve "Security audit findings" --max-tokens 2000
```

**Options:**
- `--query`: Search query (or positional argument)
- `--max-tokens`: Maximum tokens in output (default: 4000)
- `--include-scores`: Show similarity scores
- `--format`: Output format (context, detailed)

### `rag-memory stats`

Show statistics about the vector store.

```bash
rag-memory stats
```

**Output:**
- Total chunks stored
- Total tokens
- Storage backend
- Last ingestion time
- Content type breakdown

### `rag-memory clear`

Clear the vector store (with confirmation).

```bash
rag-memory clear
```

## Usage Examples

### Example 1: Daily Memory Ingestion

```bash
# Ingest today's memory file
rag-memory ingest --source memory/$(date +%Y-%m-%d).md --type daily

# Search recent context
rag-memory search "What was I working on today?" --top-k 3
```

### Example 2: Skill Documentation

```bash
# Ingest all skill documentation
rag-memory ingest --source skills/ --type skill-docs

# Search for skill capabilities
rag-memory search "Which skills can help with code analysis?"
```

### Example 3: Context for Assistant

```bash
# Get relevant context for a query
CONTEXT=$(rag-memory retrieve "User wants to deploy application")

# Use in OpenClaw command
openclaw prompt "Based on this context: $CONTEXT, help deploy the app"
```

### Example 4: Codebase Memory

```bash
# Ingest project files
rag-memory ingest --source /path/to/project/ --type code

# Search for specific implementations
rag-memory search "authentication middleware implementation"
```

## Integration with OpenClaw

### Automatic Memory Sync

Create a cron job to automatically sync OpenClaw memory:

```bash
# Add to crontab
0 */6 * * * cd /root/.openclaw/workspace && rag-memory ingest --source memory/ --type daily
```

### Context Injection

Use in OpenClaw prompts for intelligent context retrieval:

```bash
# Get context before generating response
CONTEXT=$(rag-memory retrieve "$USER_QUERY" --max-tokens 3000)

# Generate with context
openclaw prompt "Context: $CONTEXT\n\nUser question: $USER_QUERY"
```

## Backend Configuration

### SQLite (Default)

Lightweight, uses NumPy for vector operations.

```bash
rag-memory init --backend sqlite
```

**Pros:** Simple, no external deps, fast for small datasets
**Cons:** Limited scaling, in-memory search only

### Chroma (Recommended)

Persistent vector database with built-in indexing.

```bash
pip3 install chromadb
rag-memory init --backend chroma
```

**Pros:** Persistent, fast, production-ready, filtering support
**Cons:** Additional dependency

### Pinecone

Cloud-hosted vector database (requires API key).

```bash
pip3 install pinecone-client
export PINECONE_API_KEY="your-key-here"
rag-memory init --backend pinecone
```

**Pros:** Managed service, excellent scaling, fast
**Cons:** Requires API key, cloud dependency

### Weaviate

Self-hosted or cloud vector database.

```bash
pip3 install weaviate-client
rag-memory init --backend weaviate
```

**Pros:** Powerful, flexible, hybrid search
**Cons:** More complex setup

## Chunking Strategy

Text is automatically chunked for optimal retrieval:

- **Default chunk size:** 500 tokens
- **Overlap:** 50 tokens (ensures context continuity)
- **Smart splitting:** Respects sentence boundaries when possible
- **Metadata tracking:** Each chunk tracks source file, position, type

## Embedding Method

The skill uses **simple hash-based embeddings** for lightweight operation:

- **No external API required**: Works offline
- **Deterministic**: Same text = same embedding
- **Fast**: Suitable for real-time searches
- **Good for short-medium text**: Works well for typical memory chunks

**For production use**, consider upgrading to proper embeddings:

```bash
# Set OpenAI API key for better embeddings
export OPENAI_API_KEY="your-key"
export RAG_MEMORY_EMBEDDING="openai"
```

## Configuration

Configuration file location: `~/.openclaw/data/rag-memory/config.json`

```json
{
  "backend": "sqlite",
  "chunk_size": 500,
  "chunk_overlap": 50,
  "embedding_dim": 384,
  "storage_path": "~/.openclaw/data/rag-memory/",
  "search_threshold": 0.5
}
```

## Troubleshooting

### Import Errors

```bash
# Install missing dependencies
pip3 install numpy chromadb
```

### Performance Issues

```bash
# Switch to Chroma backend for better performance
rag-memory clear
rag-memory init --backend chroma
rag-memory ingest --source memory/
```

### Poor Search Results

- Increase `--top-k` to get more candidates
- Lower `--threshold` to include more results
- Try different chunk sizes with `--chunk-size`
- Add content type metadata for filtering

## API Reference

### Python API

```python
from skills.rag_memory import RAGMemory

# Initialize
rag = RAGMemory(backend="sqlite")

# Add documents
rag.add_text("Remember this important context", metadata={"type": "important"})
rag.add_file("memory/2026-02-13.md")

# Search
results = rag.search("What happened yesterday?", top_k=5)

# Retrieve context
context = rag.retrieve("User wants security advice", max_tokens=2000)
```

## License

Part of OpenClaw. MIT License.

## Contributing

This skill is part of the OpenClaw project. Contributions welcome!

---

**Made with ❤️ for OpenClaw**
