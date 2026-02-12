#!/usr/bin/env python3
"""
RAG Memory - Vector-based memory for OpenClaw
Implements Retrieval Augmented Generation using local vector storage
"""

import json
import os
import sys
import sqlite3
import hashlib
import math
import re
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, asdict

# Try to import numpy, fall back to pure Python
try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

# Default configuration
DEFAULT_CONFIG = {
    "backend": "sqlite",
    "chunk_size": 500,
    "chunk_overlap": 50,
    "embedding_dim": 384,
    "storage_path": os.path.expanduser("~/.openclaw/data/rag-memory/"),
    "search_threshold": 0.01,  # Lowered for hash-based embeddings
}

@dataclass
class Chunk:
    id: str
    text: str
    embedding: List[float]
    metadata: Dict[str, Any]
    created_at: str
    token_count: int

class RAGMemory:
    """RAG Memory implementation with vector embeddings"""
    
    def __init__(self, config_path: Optional[str] = None):
        self.config = self._load_config(config_path)
        self.storage_path = Path(self.config["storage_path"])
        self.storage_path.mkdir(parents=True, exist_ok=True)
        self.db_path = self.storage_path / "vectors.db"
        self._init_db()
    
    def _load_config(self, config_path: Optional[str]) -> Dict[str, Any]:
        if config_path and os.path.exists(config_path):
            with open(config_path, 'r') as f:
                return json.load(f)
        
        config_path = os.path.expanduser("~/.openclaw/data/rag-memory/config.json")
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                return json.load(f)
        
        return DEFAULT_CONFIG.copy()
    
    def _init_db(self):
        """Initialize SQLite database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS chunks (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                embedding_vector BLOB NOT NULL,
                metadata TEXT,
                created_at TEXT,
                token_count INTEGER,
                content_type TEXT,
                source_file TEXT
            )
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_content_type ON chunks(content_type)
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_created_at ON chunks(created_at)
        ''')
        
        conn.commit()
        conn.close()
    
    def _generate_embedding(self, text: str) -> List[float]:
        """Generate embedding vector for text using hash-based method"""
        # Simple but effective hash-based embedding
        # Works offline, deterministic, fast
        words = text.lower().split()
        dim = self.config["embedding_dim"]
        embedding = [0.0] * dim
        
        for word in words:
            # Hash word to get deterministic pseudo-random values
            word_hash = hashlib.md5(word.encode()).hexdigest()
            
            # Use hash to determine indices and values
            for i in range(0, len(word_hash), 8):
                if i + 8 > len(word_hash):
                    break
                    
                idx = int(word_hash[i:i+4], 16) % dim
                val = int(word_hash[i+4:i+8], 16) / 0xFFFFFFFF
                
                embedding[idx] += val * (1 - 2 * ((ord(word_hash[i]) & 1) == 0))
        
        # Normalize
        norm = math.sqrt(sum(x*x for x in embedding))
        if norm > 0:
            embedding = [x / norm for x in embedding]
        
        return embedding
    
    def _cosine_similarity(self, a: List[float], b: List[float]) -> float:
        """Calculate cosine similarity between two vectors"""
        if HAS_NUMPY:
            a_arr = np.array(a)
            b_arr = np.array(b)
            return float(np.dot(a_arr, b_arr) / (np.linalg.norm(a_arr) * np.linalg.norm(b_arr) + 1e-8))
        else:
            # Pure Python implementation
            dot = sum(x * y for x, y in zip(a, b))
            norm_a = math.sqrt(sum(x * x for x in a))
            norm_b = math.sqrt(sum(y * y for y in b))
            return dot / (norm_a * norm_b + 1e-8)
    
    def _estimate_token_count(self, text: str) -> int:
        """Estimate token count (rough approximation: ~4 chars per token)"""
        return len(text) // 4
    
    def _chunk_text(self, text: str, chunk_size: int, overlap: int, 
                    metadata: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
        """Split text into overlapping chunks"""
        chunks = []
        words = text.split()
        
        if not words:
            return chunks
        
        # Simple word-based chunking
        for i in range(0, len(words), chunk_size - overlap):
            chunk_words = words[i:i + chunk_size]
            chunk_text = ' '.join(chunk_words)
            
            chunk_meta = metadata.copy()
            chunk_meta["chunk_index"] = len(chunks)
            chunk_meta["start_position"] = i
            chunk_meta["end_position"] = i + len(chunk_words)
            
            chunks.append((chunk_text, chunk_meta))
            
            if i + chunk_size >= len(words):
                break
        
        return chunks
    
    def add_chunk(self, text: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """Add a single text chunk to the vector store"""
        if metadata is None:
            metadata = {}
        
        # Generate unique ID
        chunk_id = hashlib.sha256(text.encode()).hexdigest()[:16]
        
        # Generate embedding
        embedding = self._generate_embedding(text)
        
        # Count tokens
        token_count = self._estimate_token_count(text)
        
        # Set metadata defaults
        metadata.setdefault("content_type", "general")
        metadata.setdefault("created_at", datetime.now().isoformat())
        
        # Store in database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT OR REPLACE INTO chunks
            (id, text, embedding_vector, metadata, created_at, token_count, content_type, source_file)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            chunk_id,
            text,
            json.dumps(embedding),
            json.dumps(metadata),
            metadata["created_at"],
            token_count,
            metadata.get("content_type", "general"),
            metadata.get("source_file", "")
        ))
        
        conn.commit()
        conn.close()
        
        return chunk_id
    
    def add_text(self, text: str, metadata: Optional[Dict[str, Any]] = None) -> List[str]:
        """Add text, automatically chunking if needed"""
        if metadata is None:
            metadata = {}
        
        chunk_size = self.config["chunk_size"]
        overlap = self.config["chunk_overlap"]
        
        # Estimate tokens and decide if chunking needed
        token_count = self._estimate_token_count(text)
        
        if token_count <= chunk_size:
            chunk_id = self.add_chunk(text, metadata)
            return [chunk_id]
        
        # Chunk the text
        chunks = self._chunk_text(text, chunk_size, overlap, metadata)
        chunk_ids = []
        
        for chunk_text, chunk_meta in chunks:
            chunk_id = self.add_chunk(chunk_text, chunk_meta)
            chunk_ids.append(chunk_id)
        
        return chunk_ids
    
    def add_file(self, file_path: str) -> List[str]:
        """Add file contents to the vector store"""
        path = Path(file_path)
        
        if not path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        # Read file content
        if path.suffix == '.json':
            with open(path, 'r') as f:
                content = json.dumps(json.load(f), indent=2)
        else:
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        
        # Determine content type
        content_type = "general"
        if path.suffix in ['.md']:
            content_type = "markdown"
        elif path.suffix in ['.py', '.js', '.ts', '.sh', '.bash']:
            content_type = "code"
        elif path.suffix == '.json':
            content_type = "json"
        
        # Determine metadata
        metadata = {
            "source_file": str(path),
            "file_name": path.name,
            "content_type": content_type
        }
        
        # Check if it's a daily memory file
        if 'memory' in str(path) and re.search(r'\d{4}-\d{2}-\d{2}', path.name):
            metadata["content_type"] = "daily"
        
        return self.add_text(content, metadata)
    
    def add_directory(self, dir_path: str, pattern: str = "*.md") -> List[str]:
        """Add all files in a directory matching pattern"""
        path = Path(dir_path)
        
        if not path.exists():
            path = self.storage_path.parent.parent / dir_path
        
        if not path.exists():
            raise FileNotFoundError(f"Directory not found: {dir_path}")
        
        all_chunk_ids = []
        
        for file_path in path.rglob(pattern):
            try:
                chunk_ids = self.add_file(str(file_path))
                all_chunk_ids.extend(chunk_ids)
            except Exception as e:
                print(f"Error processing {file_path}: {e}", file=sys.stderr)
        
        return all_chunk_ids
    
    def search(self, query: str, top_k: int = 5, 
               threshold: float = None,
               content_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """Search for similar chunks"""
        if threshold is None:
            threshold = self.config["search_threshold"]
        
        # Generate query embedding
        query_embedding = self._generate_embedding(query)
        
        # Search database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Build query
        sql = "SELECT id, text, embedding_vector, metadata, created_at, content_type FROM chunks"
        params = []
        
        if content_type:
            sql += " WHERE content_type = ?"
            params.append(content_type)
        
        cursor.execute(sql, params)
        rows = cursor.fetchall()
        conn.close()
        
        # Calculate similarities
        results = []
        for row in rows:
            chunk_id, text, emb_blob, metadata_json, created_at, ct = row
            embedding = json.loads(emb_blob)
            
            similarity = self._cosine_similarity(query_embedding, embedding)
            
            if similarity >= threshold:
                results.append({
                    "id": chunk_id,
                    "text": text,
                    "metadata": json.loads(metadata_json),
                    "similarity": similarity,
                    "created_at": created_at,
                    "content_type": ct
                })
        
        # Sort by similarity descending and return top_k
        results.sort(key=lambda x: x["similarity"], reverse=True)
        return results[:top_k]
    
    def retrieve(self, query: str, max_tokens: int = 4000,
                 include_scores: bool = False,
                 content_type: Optional[str] = None) -> str:
        """Retrieve context formatted for LLM consumption"""
        results = self.search(query, top_k=20, content_type=content_type)
        
        context_parts = []
        total_tokens = 0
        
        for result in results:
            text = result["text"]
            tokens = self._estimate_token_count(text)
            
            if total_tokens + tokens > max_tokens:
                # Truncate if needed
                remaining = max_tokens - total_tokens
                if remaining > 50:
                    text = ' '.join(text.split()[:remaining])
                    context_parts.append(self._format_chunk(text, result, include_scores))
                break
            
            context_parts.append(self._format_chunk(text, result, include_scores))
            total_tokens += tokens
        
        return '\n\n'.join(context_parts)
    
    def _format_chunk(self, text: str, result: Dict[str, Any], 
                      include_scores: bool) -> str:
        """Format a chunk for output"""
        metadata = result["metadata"]
        
        parts = []
        
        source = metadata.get("source_file", "unknown")
        if source.endswith("MEMORY.md"):
            parts.append(f"[Long-term Memory]")
        elif "memory" in source.lower():
            parts.append(f"[Daily Memory: {Path(source).name}]")
        else:
            parts.append(f"[{Path(source).name}]")
        
        if include_scores:
            parts.append(f"(similarity: {result['similarity']:.2f})")
        
        header = ' '.join(parts)
        return f"{header}\n{text}"
    
    def get_stats(self) -> Dict[str, Any]:
        """Get statistics about the vector store"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM chunks")
        total_chunks = cursor.fetchone()[0]
        
        cursor.execute("SELECT SUM(token_count) FROM chunks")
        total_tokens = cursor.fetchone()[0] or 0
        
        cursor.execute("SELECT content_type, COUNT(*) as count FROM chunks GROUP BY content_type")
        type_counts = dict(cursor.fetchall())
        
        cursor.execute("SELECT MAX(created_at) FROM chunks")
        last_ingest = cursor.fetchone()[0]
        
        conn.close()
        
        # Get database size
        db_size = self.db_path.stat().st_size if self.db_path.exists() else 0
        
        return {
            "total_chunks": total_chunks,
            "total_tokens": total_tokens,
            "type_counts": type_counts,
            "last_ingestion": last_ingest,
            "storage_size_bytes": db_size,
            "storage_backend": "sqlite",
            "embedding_dim": self.config["embedding_dim"]
        }
    
    def clear(self) -> None:
        """Clear all chunks from the vector store"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM chunks")
        conn.commit()
        conn.close()

# CLI interface
def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="RAG Memory - Vector-based memory for OpenClaw")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # init command
    init_parser = subparsers.add_parser("init", help="Initialize the vector memory store")
    init_parser.add_argument("--backend", choices=["sqlite"], default="sqlite")
    init_parser.add_argument("--path", default=None)
    
    # ingest command
    ingest_parser = subparsers.add_parser("ingest", help="Ingest documents into the vector store")
    ingest_parser.add_argument("--source", help="File or directory to ingest")
    ingest_parser.add_argument("--text", help="Direct text to ingest")
    ingest_parser.add_argument("--type", dest="content_type", help="Content type")
    ingest_parser.add_argument("--chunk-size", type=int, default=500)
    ingest_parser.add_argument("--chunk-overlap", type=int, default=50)
    ingest_parser.add_argument("--metadata", help="JSON metadata to attach")
    
    # search command
    search_parser = subparsers.add_parser("search", help="Perform semantic search")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument("--top-k", type=int, default=5)
    search_parser.add_argument("--threshold", type=float, default=None)
    search_parser.add_argument("--type", dest="content_type", help="Filter by content type")
    search_parser.add_argument("--format", choices=["json", "text", "markdown"], default="text")
    
    # retrieve command
    retrieve_parser = subparsers.add_parser("retrieve", help="Retrieve context for LLM")
    retrieve_parser.add_argument("query", help="Search query")
    retrieve_parser.add_argument("--max-tokens", type=int, default=4000)
    retrieve_parser.add_argument("--include-scores", action="store_true")
    retrieve_parser.add_argument("--format", choices=["context", "detailed"], default="context")
    
    # stats command
    subparsers.add_parser("stats", help="Show statistics")
    
    # clear command
    clear_parser = subparsers.add_parser("clear", help="Clear the vector store")
    clear_parser.add_argument("--confirm", action="store_true", help="Skip confirmation")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    # Initialize RAG memory
    config = DEFAULT_CONFIG.copy()
    if hasattr(args, 'path') and args.path:
        config["storage_path"] = args.path
    
    rag = RAGMemory()
    
    if args.command == "init":
        print(f"✅ RAG Memory initialized")
        print(f"   Backend: {args.backend}")
        print(f"   Storage: {config['storage_path']}")
        # Save config
        config["backend"] = args.backend
        config_path = Path(config["storage_path"]) / "config.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2)
    
    elif args.command == "ingest":
        all_chunk_ids = []
        
        if args.text:
            metadata = {"content_type": args.content_type or "manual"}
            if args.metadata:
                metadata.update(json.loads(args.metadata))
            chunk_ids = rag.add_text(args.text, metadata)
            all_chunk_ids.extend(chunk_ids)
            print(f"✅ Added {len(chunk_ids)} chunk(s) from direct text")
        
        elif args.source:
            source_path = Path(args.source)
            
            if source_path.is_file():
                chunk_ids = rag.add_file(str(source_path))
                all_chunk_ids.extend(chunk_ids)
                print(f"✅ Added {len(chunk_ids)} chunk(s) from {source_path.name}")
            
            elif source_path.is_dir():
                pattern = "*.md" if not args.content_type else "*"
                if args.content_type == "code":
                    pattern = "*.{py,js,ts,sh,bash}"
                
                chunk_ids = rag.add_directory(str(source_path), pattern)
                all_chunk_ids.extend(chunk_ids)
                print(f"✅ Added {len(chunk_ids)} chunk(s) from {source_path.name}")
        
        if all_chunk_ids:
            print(f"   Total chunks: {len(all_chunk_ids)}")
        
    elif args.command == "search":
        results = rag.search(
            args.query, 
            top_k=args.top_k, 
            threshold=args.threshold,
            content_type=args.content_type
        )
        
        if args.format == "json":
            print(json.dumps(results, indent=2))
        else:
            print(f"Found {len(results)} results for: {args.query}\n")
            for i, result in enumerate(results, 1):
                print(f"{i}. [{result['content_type']}] (score: {result['similarity']:.2f})")
                print(f"   {result['text'][:200]}...")
                print()
    
    elif args.command == "retrieve":
        context = rag.retrieve(
            args.query,
            max_tokens=args.max_tokens,
            include_scores=args.include_scores,
            content_type=args.content_type if hasattr(args, 'content_type') else None
        )
        print(context)
    
    elif args.command == "stats":
        stats = rag.get_stats()
        print("📊 RAG Memory Statistics")
        print(f"   Total chunks: {stats['total_chunks']}")
        print(f"   Total tokens: {stats['total_tokens']:,}")
        print(f"   Backend: {stats['storage_backend']}")
        print(f"   Embedding dim: {stats['embedding_dim']}")
        print(f"   Storage size: {stats['storage_size_bytes']:,} bytes")
        
        if stats['type_counts']:
            print("\n   Content types:")
            for ct, count in stats['type_counts'].items():
                print(f"      {ct}: {count}")
        
        if stats['last_ingestion']:
            print(f"\n   Last ingestion: {stats['last_ingestion']}")
    
    elif args.command == "clear":
        if args.confirm:
            rag.clear()
            print("✅ Vector store cleared")
        else:
            print("⚠️  Use --confirm to clear the vector store")

if __name__ == "__main__":
    main()
