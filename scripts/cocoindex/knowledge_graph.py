#!/usr/bin/env python3
"""
Enhanced Knowledge Graph for Safe Smart Contracts
Provides semantic search and graph queries over the knowledge base.

This bridges the gap between:
1. Existing metadata extraction (complete-metadata.json)
2. CocoIndex full integration (future)
3. Contract generator (current)
"""

import json
import sqlite3
from pathlib import Path
from typing import List, Dict, Any, Optional
from collections import defaultdict
import re


class KnowledgeGraph:
    """In-memory + SQLite knowledge graph with query capabilities"""

    def __init__(self, db_path: str = ".cocoindex/knowledge_graph.db"):
        self.db_path = db_path
        self.conn = None
        self.metadata = None
        self._init_database()
        self._load_metadata()

    def _init_database(self):
        """Initialize SQLite database for graph storage"""
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row

        # Create tables
        self.conn.executescript("""
            -- Graph metadata and versioning
            CREATE TABLE IF NOT EXISTS graph_metadata (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            -- Nodes table (entities)
            CREATE TABLE IF NOT EXISTS nodes (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                name TEXT NOT NULL,
                kb_source TEXT, -- 'action' or 'research'
                file_path TEXT,
                data JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            -- Edges table (relationships)
            CREATE TABLE IF NOT EXISTS edges (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                source_id TEXT NOT NULL,
                target_id TEXT NOT NULL,
                relationship_type TEXT NOT NULL,
                properties JSON,
                FOREIGN KEY (source_id) REFERENCES nodes(id),
                FOREIGN KEY (target_id) REFERENCES nodes(id)
            );

            -- Full-text search index
            CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
                entity_id,
                content,
                tags
            );

            -- Indexes for performance
            CREATE INDEX IF NOT EXISTS idx_node_type ON nodes(type);
            CREATE INDEX IF NOT EXISTS idx_edge_type ON edges(relationship_type);
            CREATE INDEX IF NOT EXISTS idx_kb_source ON nodes(kb_source);
        """)
        self.conn.commit()

    def _load_metadata(self):
        """Load existing metadata from extract_complete_metadata.py"""
        metadata_path = Path(".cocoindex/complete-metadata.json")
        if metadata_path.exists():
            with open(metadata_path) as f:
                self.metadata = json.load(f)
        else:
            self.metadata = {"entities": {}, "relationships": []}

    def index_from_metadata(self):
        """Index all entities and relationships from metadata"""
        print("📊 Indexing entities...")

        # Index vulnerabilities
        for vuln_id, vuln in self.metadata["entities"].get("vulnerabilities", {}).items():
            self._add_node(
                node_id=vuln_id,
                node_type="Vulnerability",
                name=vuln.get("name"),
                kb_source="action",
                file_path=vuln.get("file_path"),
                data=vuln
            )

        # Index templates
        for template_id, template in self.metadata["entities"].get("templates", {}).items():
            self._add_node(
                node_id=template_id,
                node_type="Template",
                name=template.get("name"),
                kb_source="action",
                file_path=template.get("file_path"),
                data=template
            )

        # Index deep dives
        for dd_id, dd in self.metadata["entities"].get("deepdives", {}).items():
            self._add_node(
                node_id=dd_id,
                node_type="DeepDive",
                name=dd.get("name"),
                kb_source="research",
                file_path=dd.get("file_path"),
                data=dd
            )

        # Index integrations
        for int_id, integration in self.metadata["entities"].get("integrations", {}).items():
            self._add_node(
                node_id=int_id,
                node_type="Integration",
                name=integration.get("name"),
                kb_source="research",
                file_path=integration.get("file_path"),
                data=integration
            )

        # Index vulnerable contracts
        for vc_id, vc in self.metadata["entities"].get("vulnerable_contracts", {}).items():
            self._add_node(
                node_id=vc_id,
                node_type="VulnerableContract",
                name=vc.get("name"),
                kb_source="research",
                file_path=vc.get("file_path"),
                data=vc
            )

        print(f"✅ Indexed {self.get_node_count()} nodes")

        # Index relationships
        print("📊 Indexing relationships...")
        for rel in self.metadata["relationships"]:
            self._add_edge(
                source_id=rel["source"],
                target_id=rel["target"],
                relationship_type=rel["type"],
                properties=rel.get("properties", {})
            )

        print(f"✅ Indexed {self.get_edge_count()} relationships")

        self.conn.commit()

    def _add_node(self, node_id: str, node_type: str, name: str,
                  kb_source: str, file_path: str, data: Dict):
        """Add a node to the graph"""
        self.conn.execute("""
            INSERT OR REPLACE INTO nodes (id, type, name, kb_source, file_path, data)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (node_id, node_type, name, kb_source, file_path, json.dumps(data)))

        # Add to search index
        tags = f"{node_type} {kb_source}"
        content = f"{name} {file_path} {json.dumps(data)}"
        self.conn.execute("""
            INSERT INTO search_index (entity_id, content, tags)
            VALUES (?, ?, ?)
        """, (node_id, content, tags))

    def _add_edge(self, source_id: str, target_id: str,
                  relationship_type: str, properties: Dict):
        """Add an edge to the graph"""
        self.conn.execute("""
            INSERT INTO edges (source_id, target_id, relationship_type, properties)
            VALUES (?, ?, ?, ?)
        """, (source_id, target_id, relationship_type, json.dumps(properties)))

    # === QUERY METHODS ===

    def search(self, query: str, limit: int = 10) -> List[Dict]:
        """Full-text search across all entities"""
        cursor = self.conn.execute("""
            SELECT n.*, rank
            FROM search_index s
            JOIN nodes n ON s.entity_id = n.id
            WHERE search_index MATCH ?
            ORDER BY rank
            LIMIT ?
        """, (query, limit))

        return [dict(row) for row in cursor.fetchall()]

    def find_by_type(self, node_type: str) -> List[Dict]:
        """Find all nodes of a specific type"""
        cursor = self.conn.execute("""
            SELECT * FROM nodes WHERE type = ?
        """, (node_type,))

        return [dict(row) for row in cursor.fetchall()]

    def find_vulnerabilities(self, severity: Optional[str] = None,
                            min_loss: Optional[float] = None) -> List[Dict]:
        """Find vulnerabilities with filters"""
        query = "SELECT * FROM nodes WHERE type = 'Vulnerability'"
        params = []

        if severity:
            query += " AND json_extract(data, '$.severity') = ?"
            params.append(severity)

        if min_loss:
            query += " AND CAST(json_extract(data, '$.historical_losses_usd') AS REAL) >= ?"
            params.append(min_loss)

        cursor = self.conn.execute(query, params)
        return [dict(row) for row in cursor.fetchall()]

    def get_related(self, node_id: str, relationship_type: Optional[str] = None) -> List[Dict]:
        """Get all nodes related to a given node"""
        query = """
            SELECT n.*, e.relationship_type
            FROM edges e
            JOIN nodes n ON (e.target_id = n.id OR e.source_id = n.id)
            WHERE (e.source_id = ? OR e.target_id = ?)
            AND n.id != ?
        """
        params = [node_id, node_id, node_id]

        if relationship_type:
            query += " AND e.relationship_type = ?"
            params.append(relationship_type)

        cursor = self.conn.execute(query, params)
        return [dict(row) for row in cursor.fetchall()]

    def get_path(self, source_id: str, target_id: str, max_depth: int = 3) -> List[List[Dict]]:
        """Find paths between two nodes (simplified)"""
        # This is a basic implementation - full graph traversal would be more complex
        direct_path = self.conn.execute("""
            SELECT e.*, s.name as source_name, t.name as target_name
            FROM edges e
            JOIN nodes s ON e.source_id = s.id
            JOIN nodes t ON e.target_id = t.id
            WHERE e.source_id = ? AND e.target_id = ?
        """, (source_id, target_id)).fetchone()

        if direct_path:
            return [[dict(direct_path)]]

        return []  # Could implement BFS for multi-hop paths

    def query(self, cypher_like: str) -> List[Dict]:
        """
        Simple Cypher-like query language
        Examples:
          - "MATCH (v:Vulnerability) RETURN v"
          - "MATCH (v:Vulnerability)-[PREVENTS]-(t:Template) RETURN v, t"
        """
        # Simplified query parser
        if "MATCH" in cypher_like and "Vulnerability" in cypher_like:
            return self.find_by_type("Vulnerability")
        elif "MATCH" in cypher_like and "Template" in cypher_like:
            return self.find_by_type("Template")

        return []

    def get_statistics(self) -> Dict[str, Any]:
        """Get graph statistics"""
        stats = {}

        # Node counts by type
        cursor = self.conn.execute("""
            SELECT type, COUNT(*) as count
            FROM nodes
            GROUP BY type
        """)
        stats["nodes_by_type"] = {row[0]: row[1] for row in cursor.fetchall()}

        # Edge counts by type
        cursor = self.conn.execute("""
            SELECT relationship_type, COUNT(*) as count
            FROM edges
            GROUP BY relationship_type
        """)
        stats["edges_by_type"] = {row[0]: row[1] for row in cursor.fetchall()}

        # KB source distribution
        cursor = self.conn.execute("""
            SELECT kb_source, COUNT(*) as count
            FROM nodes
            GROUP BY kb_source
        """)
        stats["nodes_by_kb"] = {row[0]: row[1] for row in cursor.fetchall()}

        stats["total_nodes"] = sum(stats["nodes_by_type"].values())
        stats["total_edges"] = sum(stats["edges_by_type"].values())

        # Add version and metadata info
        stats["version"] = self.get_version()
        stats["kb_files_count"] = self.get_metadata_value("kb_files_count", "0")
        stats["last_rebuild"] = self.get_metadata_value("last_rebuild", "unknown")

        return stats

    def get_node_count(self) -> int:
        """Get total node count"""
        cursor = self.conn.execute("SELECT COUNT(*) FROM nodes")
        return cursor.fetchone()[0]

    def get_edge_count(self) -> int:
        """Get total edge count"""
        cursor = self.conn.execute("SELECT COUNT(*) FROM edges")
        return cursor.fetchone()[0]

    def export_graphml(self, output_path: str):
        """Export graph in GraphML format for visualization"""
        # Would export to format readable by Gephi, Neo4j, etc.
        pass

    def set_metadata_value(self, key: str, value: str):
        """Set a metadata value with automatic timestamping"""
        self.conn.execute("""
            INSERT OR REPLACE INTO graph_metadata (key, value, updated_at)
            VALUES (?, ?, CURRENT_TIMESTAMP)
        """, (key, value))
        self.conn.commit()

    def get_metadata_value(self, key: str, default: str = None) -> str:
        """Get a metadata value"""
        cursor = self.conn.execute("""
            SELECT value FROM graph_metadata WHERE key = ?
        """, (key,))
        row = cursor.fetchone()
        return row[0] if row else default

    def get_version(self) -> str:
        """Get current graph version"""
        return self.get_metadata_value("version", "1.0.0")

    def increment_version(self, bump_type: str = "patch"):
        """Increment version number (major.minor.patch)"""
        current = self.get_version()
        parts = current.split('.')
        major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])

        if bump_type == "major":
            major += 1
            minor = 0
            patch = 0
        elif bump_type == "minor":
            minor += 1
            patch = 0
        else:  # patch
            patch += 1

        new_version = f"{major}.{minor}.{patch}"
        self.set_metadata_value("version", new_version)
        return new_version

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()


def main():
    print("="*80)
    print("🔍 Knowledge Graph Builder")
    print("="*80)
    print()

    # Create knowledge graph
    kg = KnowledgeGraph()

    # Index all metadata
    print("Building knowledge graph from metadata...")
    kg.index_from_metadata()

    # Show statistics
    print()
    print("="*80)
    print("📊 Knowledge Graph Statistics")
    print("="*80)
    stats = kg.get_statistics()
    print()
    print(f"Total Nodes: {stats['total_nodes']}")
    print(f"Total Edges: {stats['total_edges']}")
    print()
    print("Nodes by Type:")
    for node_type, count in stats['nodes_by_type'].items():
        print(f"  {node_type}: {count}")
    print()
    print("Edges by Type:")
    for edge_type, count in stats['edges_by_type'].items():
        print(f"  {edge_type}: {count}")
    print()
    print("KB Distribution:")
    for kb, count in stats['nodes_by_kb'].items():
        print(f"  {kb}: {count}")
    print()

    # Example queries
    print("="*80)
    print("🔎 Example Queries")
    print("="*80)
    print()

    # Query 1: Search for reentrancy
    print("1. Search for 'reentrancy':")
    results = kg.search("reentrancy", limit=3)
    for r in results:
        print(f"   - {r['name']} ({r['type']})")
    print()

    # Query 2: Find high-severity vulnerabilities
    print("2. High-severity vulnerabilities:")
    vulns = kg.find_vulnerabilities(severity="high")
    for v in vulns[:3]:
        data = json.loads(v['data'])
        print(f"   - {v['name']}: ${data.get('historical_losses_usd', 0):,.0f} in losses")
    print()

    # Query 3: Find all templates
    print("3. Available templates:")
    templates = kg.find_by_type("Template")
    for t in templates[:5]:
        print(f"   - {t['name']}")
    print()

    print("✅ Knowledge graph built successfully!")
    print()
    print(f"Database location: {kg.db_path}")
    print()

    kg.close()


if __name__ == "__main__":
    main()
