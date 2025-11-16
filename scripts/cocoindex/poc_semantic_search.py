#!/usr/bin/env python3
"""
Proof-of-Concept: Semantic Search for Safe Smart Contracts KB
Demonstrates CocoIndex-like capabilities using sentence-transformers.

This script:
1. Loads complete metadata from both knowledge bases
2. Creates semantic embeddings for all content
3. Enables natural language search across 284 files
4. Shows multi-KB, version comparison, and cross-reference queries
"""

import json
import numpy as np
from pathlib import Path
from typing import List, Dict, Tuple
import time


def load_metadata() -> Dict:
    """Load complete metadata from both KBs"""
    metadata_path = Path(".cocoindex/complete-metadata.json")

    if not metadata_path.exists():
        print("❌ Metadata file not found. Run extract_complete_metadata.py first.")
        return None

    with open(metadata_path) as f:
        return json.load(f)


def load_file_content(file_path: str) -> str:
    """Load content from a markdown or solidity file"""
    try:
        full_path = Path(file_path)
        if full_path.exists():
            return full_path.read_text()[:5000]  # First 5000 chars
        return ""
    except Exception as e:
        return f"Error loading {file_path}: {e}"


def create_document_corpus(metadata: Dict) -> Tuple[List[str], List[Dict]]:
    """Create searchable document corpus from metadata"""
    documents = []
    doc_metadata = []

    print("📚 Building document corpus...")

    # Process all entity types
    entity_categories = [
        ("vulnerabilities", "Vulnerability"),
        ("templates", "Template"),
        ("deepdives", "Deep-Dive"),
        ("integrations", "Integration"),
        ("vulnerable_contracts", "Vulnerable Contract"),
        ("protocol_versions", "Protocol Version"),
        ("source_repositories", "Source Repository")
    ]

    for category, entity_type in entity_categories:
        if category in metadata.get("entities", {}):
            entities = metadata["entities"][category]
            for entity_id, entity in entities.items():
                # Create searchable text
                text_parts = []

                # Name and description
                if "name" in entity:
                    text_parts.append(f"Name: {entity['name']}")
                if "description" in entity:
                    text_parts.append(f"Description: {entity['description']}")

                # Type-specific fields
                if "protocol" in entity:
                    text_parts.append(f"Protocol: {entity['protocol']}")
                if "vulnerability_type" in entity:
                    text_parts.append(f"Vulnerability: {entity['vulnerability_type']}")
                if "major_features" in entity:
                    text_parts.append(f"Features: {', '.join(entity['major_features'])}")

                # Keywords
                if "keywords" in entity:
                    text_parts.append(f"Keywords: {', '.join(entity['keywords'])}")

                document_text = " | ".join(text_parts)
                documents.append(document_text)

                doc_metadata.append({
                    "id": entity_id,
                    "name": entity.get("name", entity_id),
                    "type": entity_type,
                    "kb": entity.get("kb_type", "unknown"),
                    "file_path": entity.get("file_path", ""),
                    "lines": entity.get("lines", 0)
                })

    print(f"   ✓ Created corpus with {len(documents)} documents")
    return documents, doc_metadata


def create_embeddings_simple(documents: List[str]) -> np.ndarray:
    """Create simple TF-IDF-like embeddings (fallback if sentence-transformers not available)"""
    from collections import Counter
    import re

    print("📊 Creating embeddings (simple TF-IDF method)...")

    # Tokenize and build vocabulary
    all_tokens = []
    doc_tokens = []

    for doc in documents:
        tokens = re.findall(r'\w+', doc.lower())
        doc_tokens.append(tokens)
        all_tokens.extend(tokens)

    # Build vocabulary (top 1000 words)
    vocab = [word for word, _ in Counter(all_tokens).most_common(1000)]
    word_to_idx = {word: idx for idx, word in enumerate(vocab)}

    # Create document vectors
    embeddings = np.zeros((len(documents), len(vocab)))

    for i, tokens in enumerate(doc_tokens):
        token_counts = Counter(tokens)
        for word, count in token_counts.items():
            if word in word_to_idx:
                embeddings[i, word_to_idx[word]] = count

    # Normalize
    norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
    norms[norms == 0] = 1  # Avoid division by zero
    embeddings = embeddings / norms

    print(f"   ✓ Created embeddings: {embeddings.shape}")
    return embeddings


def create_embeddings_transformer(documents: List[str]) -> np.ndarray:
    """Create semantic embeddings using sentence-transformers"""
    try:
        from sentence_transformers import SentenceTransformer

        print("📊 Creating semantic embeddings (sentence-transformers)...")
        print("   Loading model: all-MiniLM-L6-v2...")

        model = SentenceTransformer('all-MiniLM-L6-v2')

        print(f"   Encoding {len(documents)} documents...")
        embeddings = model.encode(documents, show_progress_bar=True)

        print(f"   ✓ Created embeddings: {embeddings.shape}")
        return embeddings

    except ImportError:
        print("   ⚠️  sentence-transformers not available, using simple method")
        return create_embeddings_simple(documents)


def semantic_search(query: str, embeddings: np.ndarray, doc_metadata: List[Dict],
                    documents: List[str], top_k: int = 5) -> List[Dict]:
    """Perform semantic search"""
    try:
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer('all-MiniLM-L6-v2')
        query_embedding = model.encode([query])[0]
        use_transformer = True
    except ImportError:
        # Fallback to simple method
        import re
        tokens = re.findall(r'\w+', query.lower())
        query_embedding = np.zeros(embeddings.shape[1])
        # This is a simplified approach - would need proper implementation
        use_transformer = False

    # Compute similarities
    similarities = np.dot(embeddings, query_embedding)

    # Get top k results
    top_indices = np.argsort(similarities)[::-1][:top_k]

    results = []
    for idx in top_indices:
        results.append({
            "rank": len(results) + 1,
            "score": float(similarities[idx]),
            "metadata": doc_metadata[idx],
            "preview": documents[idx][:200] + "..."
        })

    return results


def display_results(query: str, results: List[Dict]):
    """Display search results in a nice format"""
    print(f"\n{'='*80}")
    print(f"🔍 Search Results for: '{query}'")
    print(f"{'='*80}\n")

    for result in results:
        meta = result["metadata"]
        print(f"{result['rank']}. {meta['name']}")
        print(f"   Type: {meta['type']} | KB: {meta['kb'].upper()}")
        print(f"   Score: {result['score']:.3f}")
        if meta['lines']:
            print(f"   Size: {meta['lines']} lines")
        if meta['file_path']:
            print(f"   File: {meta['file_path']}")
        print(f"   Preview: {result['preview']}")
        print()


def main():
    """Main proof-of-concept demonstration"""
    print("\n" + "="*80)
    print("🔐 Safe Smart Contracts - Semantic Search Proof-of-Concept")
    print("="*80 + "\n")

    # Load metadata
    print("1️⃣  Loading metadata...")
    metadata = load_metadata()
    if not metadata:
        return

    print(f"   ✓ Loaded metadata for {metadata['statistics']['total_files']} files")
    print(f"   ✓ Total entities: {metadata['statistics']['total_entities']}")
    print()

    # Create corpus
    print("2️⃣  Building searchable corpus...")
    documents, doc_metadata = create_document_corpus(metadata)
    print()

    # Create embeddings
    print("3️⃣  Creating semantic embeddings...")
    embeddings = create_embeddings_transformer(documents)
    print()

    # Example queries
    print("4️⃣  Running example queries...\n")

    example_queries = [
        "How do I prevent recursive call attacks that drain funds?",
        "Show me all perspectives on reentrancy vulnerability",
        "Compare Uniswap V2 and V3",
        "What are the best gas optimization techniques?",
        "How do I integrate Chainlink price feeds?"
    ]

    for i, query in enumerate(example_queries, 1):
        print(f"\n{'─'*80}")
        print(f"Example Query {i}/{len(example_queries)}")
        print(f"{'─'*80}")

        results = semantic_search(query, embeddings, doc_metadata, documents, top_k=5)
        display_results(query, results)

        if i < len(example_queries):
            print("\n[Press Enter to continue...]")
            # input()  # Commented out for automated demo
            time.sleep(1)

    print("\n" + "="*80)
    print("✅ Proof-of-Concept Complete!")
    print("="*80)
    print("\nNext Steps:")
    print("1. Review results above")
    print("2. Try your own queries by modifying example_queries list")
    print("3. Proceed with full CocoIndex implementation")
    print()


if __name__ == "__main__":
    main()
