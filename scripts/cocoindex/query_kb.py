#!/usr/bin/env python3
"""
Interactive Knowledge Base Query Tool
Query the knowledge graph with natural language or structured queries.
"""

import sys
import json
from knowledge_graph import KnowledgeGraph


class KBQueryInterface:
    """Interactive query interface for the knowledge graph"""

    def __init__(self):
        self.kg = KnowledgeGraph()

    def run_query(self, query_type: str, **kwargs):
        """Run a specific query type"""

        if query_type == "search":
            return self.kg.search(kwargs.get("term"), limit=kwargs.get("limit", 10))

        elif query_type == "vulnerabilities":
            severity = kwargs.get("severity")
            min_loss = kwargs.get("min_loss")
            return self.kg.find_vulnerabilities(severity=severity, min_loss=min_loss)

        elif query_type == "templates":
            return self.kg.find_by_type("Template")

        elif query_type == "deepdives":
            return self.kg.find_by_type("DeepDive")

        elif query_type == "integrations":
            return self.kg.find_by_type("Integration")

        elif query_type == "related":
            return self.kg.get_related(kwargs.get("node_id"))

        elif query_type == "stats":
            return self.kg.get_statistics()

        else:
            return {"error": f"Unknown query type: {query_type}"}

    def interactive_mode(self):
        """Run in interactive mode"""
        print("="*80)
        print("🔍 Knowledge Base Interactive Query")
        print("="*80)
        print()
        print("Available commands:")
        print("  search <term>              - Search for term")
        print("  vulns [severity] [min_loss] - Find vulnerabilities")
        print("  templates                  - List all templates")
        print("  deepdives                  - List all deep dives")
        print("  integrations               - List all integrations")
        print("  related <id>               - Find related entities")
        print("  stats                      - Show graph statistics")
        print("  help                       - Show this help")
        print("  exit                       - Exit")
        print()

        while True:
            try:
                cmd = input("query> ").strip()

                if not cmd:
                    continue

                if cmd == "exit":
                    break

                if cmd == "help":
                    self.interactive_mode()
                    return

                # Parse command
                parts = cmd.split()
                cmd_type = parts[0]

                if cmd_type == "search":
                    if len(parts) < 2:
                        print("Usage: search <term>")
                        continue

                    term = " ".join(parts[1:])
                    results = self.kg.search(term, limit=10)
                    print(f"\nFound {len(results)} results for '{term}':\n")
                    for r in results:
                        data = json.loads(r['data'])
                        print(f"  [{r['type']}] {r['name']}")
                        print(f"    Path: {r['file_path']}")
                        if r['type'] == 'Vulnerability':
                            print(f"    Severity: {data.get('severity', 'unknown')}")
                            if data.get('historical_losses_usd'):
                                print(f"    Historical Loss: ${data['historical_losses_usd']:,.0f}")
                        print()

                elif cmd_type == "vulns":
                    severity = parts[1] if len(parts) > 1 else None
                    min_loss = float(parts[2]) if len(parts) > 2 else None

                    results = self.kg.find_vulnerabilities(severity=severity, min_loss=min_loss)
                    print(f"\nFound {len(results)} vulnerabilities:\n")
                    for v in results:
                        data = json.loads(v['data'])
                        print(f"  {v['name']}")
                        print(f"    Severity: {data.get('severity', 'unknown')}")
                        if data.get('historical_losses_usd'):
                            print(f"    Historical Loss: ${data['historical_losses_usd']:,.0f}")
                        print(f"    File: {v['file_path']}")
                        print()

                elif cmd_type == "templates":
                    results = self.kg.find_by_type("Template")
                    print(f"\nFound {len(results)} templates:\n")
                    for t in results:
                        data = json.loads(t['data'])
                        print(f"  {t['name']}")
                        print(f"    Type: {data.get('contract_type', 'unknown')}")
                        print(f"    Lines: {data.get('lines_of_code', 'unknown')}")
                        print(f"    File: {t['file_path']}")
                        print()

                elif cmd_type == "deepdives":
                    results = self.kg.find_by_type("DeepDive")
                    print(f"\nFound {len(results)} deep dives:\n")
                    for d in results:
                        data = json.loads(d['data'])
                        print(f"  {d['name']}")
                        print(f"    Protocol: {data.get('protocol', 'unknown')}")
                        print(f"    Words: {data.get('word_count', 'unknown')}")
                        print(f"    File: {d['file_path']}")
                        print()

                elif cmd_type == "integrations":
                    results = self.kg.find_by_type("Integration")
                    print(f"\nFound {len(results)} integrations:\n")
                    for i in results:
                        data = json.loads(i['data'])
                        print(f"  {i['name']}")
                        print(f"    Protocol: {data.get('protocol', 'unknown')}")
                        print(f"    File: {i['file_path']}")
                        print()

                elif cmd_type == "related":
                    if len(parts) < 2:
                        print("Usage: related <entity_id>")
                        continue

                    node_id = parts[1]
                    results = self.kg.get_related(node_id)
                    print(f"\nFound {len(results)} related entities:\n")
                    for r in results:
                        print(f"  [{r['relationship_type']}] {r['name']} ({r['type']})")
                        print()

                elif cmd_type == "stats":
                    stats = self.kg.get_statistics()
                    print("\n📊 Knowledge Graph Statistics\n")
                    print(f"Total Nodes: {stats['total_nodes']}")
                    print(f"Total Edges: {stats['total_edges']}")
                    print("\nNodes by Type:")
                    for node_type, count in stats['nodes_by_type'].items():
                        print(f"  {node_type}: {count}")
                    print("\nEdges by Type:")
                    for edge_type, count in stats['edges_by_type'].items():
                        print(f"  {edge_type}: {count}")
                    print()

                else:
                    print(f"Unknown command: {cmd_type}")
                    print("Type 'help' for available commands")

            except KeyboardInterrupt:
                print("\nExiting...")
                break
            except Exception as e:
                print(f"Error: {e}")

        self.kg.close()

    def close(self):
        """Close the knowledge graph connection"""
        self.kg.close()


def main():
    """Main entry point"""

    if len(sys.argv) == 1:
        # Interactive mode
        interface = KBQueryInterface()
        interface.interactive_mode()
        interface.close()

    else:
        # Command-line mode
        interface = KBQueryInterface()

        query_type = sys.argv[1]

        if query_type == "search":
            term = " ".join(sys.argv[2:])
            results = interface.run_query("search", term=term)
            print(json.dumps(results, indent=2))

        elif query_type == "vulns":
            severity = sys.argv[2] if len(sys.argv) > 2 else None
            min_loss = float(sys.argv[3]) if len(sys.argv) > 3 else None
            results = interface.run_query("vulnerabilities", severity=severity, min_loss=min_loss)
            print(json.dumps(results, indent=2))

        elif query_type == "templates":
            results = interface.run_query("templates")
            print(json.dumps(results, indent=2))

        elif query_type == "stats":
            results = interface.run_query("stats")
            print(json.dumps(results, indent=2))

        else:
            print(f"Unknown query type: {query_type}")
            print("Available: search, vulns, templates, stats")

        interface.close()


if __name__ == "__main__":
    main()
