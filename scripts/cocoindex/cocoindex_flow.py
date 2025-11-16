#!/usr/bin/env python3
"""
CocoIndex Flow Configuration for Safe Smart Contracts Knowledge Base

This creates a knowledge graph indexing all 284 files across Action KB and Research KB.
"""

import cocoindex as cci
from pathlib import Path
import json


# Initialize CocoIndex
cci.init("safe-smart-contracts-kb")


@cci.flow_def
def kb_indexing_flow():
    """
    Main flow to index the entire knowledge base into CocoIndex graph database
    """

    # Define source directories
    action_kb_path = Path("knowledge-base-action")
    research_kb_path = Path("knowledge-base-research")

    # Source 1: Action KB (39 files - production-ready patterns)
    action_docs = (
        cci.sources.filesystem(
            path=str(action_kb_path),
            pattern="**/*.md",
            recursive=True
        )
        .map(lambda file: {
            "file_path": file["path"],
            "content": file["content"],
            "kb_type": "action",
            "category": _extract_category(file["path"], "action")
        })
    )

    # Source 2: Research KB (162 files - deep-dive analysis)
    research_docs = (
        cci.sources.filesystem(
            path=str(research_kb_path),
            pattern="**/*.md",
            recursive=True
        )
        .map(lambda file: {
            "file_path": file["path"],
            "content": file["content"],
            "kb_type": "research",
            "category": _extract_category(file["path"], "research")
        })
    )

    # Source 3: Solidity contract templates
    contract_files = (
        cci.sources.filesystem(
            path=str(action_kb_path / "02-contract-templates"),
            pattern="**/*.sol",
            recursive=True
        )
        .map(lambda file: {
            "file_path": file["path"],
            "content": file["content"],
            "file_type": "solidity",
            "kb_type": "action"
        })
    )

    # Merge all sources
    all_documents = action_docs.union(research_docs).union(contract_files)

    # Extract entities and relationships
    processed = (
        all_documents
        .map(_extract_metadata)
        .map(_extract_entities)
        .map(_extract_relationships)
    )

    # Index to vector database for semantic search
    processed.index(
        index_name="kb_semantic_search",
        embedding_field="content",
        metadata_fields=["file_path", "kb_type", "category", "entities"]
    )

    # Store in graph database
    processed.to_storage(
        storage_type="graph",
        node_types=["Vulnerability", "Template", "Pattern", "DeepDive", "Integration"],
        relationship_types=["PREVENTS", "USES", "REFERENCES", "RELATES_TO"]
    )

    return processed


def _extract_category(file_path: str, kb_type: str) -> str:
    """Extract category from file path"""
    path_parts = Path(file_path).parts

    if kb_type == "action":
        # knowledge-base-action/03-attack-prevention/reentrancy.md -> "attack-prevention"
        if len(path_parts) >= 2:
            return path_parts[1] if path_parts[1] != "knowledge-base-action" else "root"
    else:
        # knowledge-base-research/repos/uniswap/... -> "uniswap"
        if len(path_parts) >= 3:
            return path_parts[2] if path_parts[1] == "repos" else path_parts[1]

    return "uncategorized"


def _extract_metadata(doc: dict) -> dict:
    """Extract structured metadata from document"""
    content = doc.get("content", "")
    file_path = doc.get("file_path", "")

    # Parse frontmatter if exists
    metadata = {
        "word_count": len(content.split()),
        "has_code_blocks": "```" in content,
        "has_links": "[" in content and "](" in content,
    }

    # Detect document type based on content
    if "vulnerability" in content.lower() or "exploit" in content.lower():
        metadata["doc_type"] = "vulnerability"
    elif "template" in file_path.lower() or ".sol" in file_path:
        metadata["doc_type"] = "template"
    elif "deep-dive" in file_path.lower():
        metadata["doc_type"] = "deepdive"
    elif "integration" in file_path.lower():
        metadata["doc_type"] = "integration"
    else:
        metadata["doc_type"] = "guide"

    doc["metadata"] = metadata
    return doc


def _extract_entities(doc: dict) -> dict:
    """Extract entities (vulnerabilities, contracts, patterns)"""
    content = doc.get("content", "")
    entities = []

    # Extract vulnerability mentions
    vuln_keywords = [
        "reentrancy", "overflow", "underflow", "access control",
        "front-running", "sandwich attack", "flash loan",
        "oracle manipulation", "DoS"
    ]

    for keyword in vuln_keywords:
        if keyword.lower() in content.lower():
            entities.append({
                "type": "vulnerability",
                "name": keyword,
                "confidence": 0.8
            })

    # Extract protocol mentions
    protocols = [
        "Uniswap", "Aave", "Compound", "Chainlink",
        "OpenZeppelin", "ERC20", "ERC721", "ERC1155"
    ]

    for protocol in protocols:
        if protocol in content:
            entities.append({
                "type": "protocol",
                "name": protocol,
                "confidence": 0.9
            })

    doc["entities"] = entities
    return doc


def _extract_relationships(doc: dict) -> dict:
    """Extract relationships between entities"""
    content = doc.get("content", "")
    file_path = doc.get("file_path", "")
    relationships = []

    # Link patterns
    # [text](path) -> REFERENCES relationship
    import re
    links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)

    for link_text, link_path in links:
        relationships.append({
            "type": "REFERENCES",
            "source": file_path,
            "target": link_path,
            "context": link_text
        })

    # Prevention patterns
    # "prevents X" or "protects against Y"
    prevents_pattern = r'prevent[s]?\s+([a-zA-Z\s]+?)(attack|vulnerability|exploit)'
    prevents_matches = re.findall(prevents_pattern, content, re.IGNORECASE)

    for match in prevents_matches:
        vuln_name = match[0].strip()
        relationships.append({
            "type": "PREVENTS",
            "source": file_path,
            "target": vuln_name,
            "relationship": "prevention"
        })

    doc["relationships"] = relationships
    return doc


if __name__ == "__main__":
    print("="*80)
    print("🔍 CocoIndex Knowledge Base Indexing")
    print("="*80)
    print()
    print("Indexing 284 files from safe-smart-contracts knowledge base...")
    print()

    # Setup the flow
    try:
        cci.setup()
        print("✅ CocoIndex initialized")

        # Run the indexing flow
        print("📊 Starting indexing flow...")
        kb_indexing_flow()

        print()
        print("✅ Indexing complete!")
        print()
        print("Next steps:")
        print("  1. Query the knowledge graph")
        print("  2. Use semantic search")
        print("  3. Integrate with contract generator")

    except Exception as e:
        print(f"❌ Error: {e}")
        print()
        print("Note: CocoIndex requires PostgreSQL database.")
        print("Run: scripts/cocoindex/setup_postgres.sh to install")
