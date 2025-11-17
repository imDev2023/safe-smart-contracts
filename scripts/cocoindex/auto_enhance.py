#!/usr/bin/env python3
"""
Automatic Knowledge Graph Enhancement with Pattern Detection

This script automatically detects and adds relationships based on:
1. File name patterns
2. Content analysis
3. Semantic similarity
4. Existing relationship patterns

It's designed to work with ANY new content added to the knowledge bases.
"""

import sys
import os
import re
from pathlib import Path
from typing import List, Dict, Tuple, Set

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from knowledge_graph import KnowledgeGraph
import json


class AutoEnhancer:
    """Automatically enhance knowledge graph with intelligent relationship detection"""

    def __init__(self):
        self.kg = KnowledgeGraph()
        self.stats = {
            'edges_before': 0,
            'edges_added': 0,
            'edges_by_type': {}
        }

        # Pattern libraries for automatic detection
        self.vulnerability_keywords = {
            'reentrancy': ['reentrancy', 'reentrant', 'call.value', 'external call'],
            'access_control': ['access control', 'ownable', 'onlyowner', 'permission', 'authorization'],
            'integer_overflow': ['overflow', 'underflow', 'safemath', 'arithmetic'],
            'frontrunning': ['frontrun', 'mev', 'sandwich', 'mempool'],
            'flash_loan': ['flash loan', 'flash attack', 'price manipulation'],
            'dos': ['dos', 'denial of service', 'gas limit', 'block gas'],
            'delegatecall': ['delegatecall', 'proxy', 'upgradeable'],
            'timestamp': ['timestamp', 'block.timestamp', 'now'],
            'tx_origin': ['tx.origin', 'transaction origin'],
            'unchecked': ['unchecked', 'return value', 'call return']
        }

        self.prevention_patterns = {
            'ReentrancyGuard': 'reentrancy',
            'nonReentrant': 'reentrancy',
            'Ownable': 'access_control',
            'AccessControl': 'access_control',
            'SafeMath': 'integer_overflow',
            'Pausable': 'dos',
            'SafeERC20': 'unchecked'
        }

    def enhance(self):
        """Main enhancement workflow"""
        print("="*80)
        print("🤖 AUTOMATIC KNOWLEDGE GRAPH ENHANCEMENT")
        print("="*80)
        print()

        # Get initial stats
        initial_stats = self.kg.get_statistics()
        self.stats['edges_before'] = initial_stats['total_edges']

        print(f"Initial state:")
        print(f"  Nodes: {initial_stats['total_nodes']}")
        print(f"  Edges: {initial_stats['total_edges']}")
        print()

        # Run enhancement strategies
        print("Strategy 1: Detecting DEMONSTRATES relationships...")
        self._auto_detect_demonstrates()

        print("\nStrategy 2: Detecting PAIRS_WITH relationships...")
        self._auto_detect_pairs()

        print("\nStrategy 3: Detecting PREVENTS relationships...")
        self._auto_detect_prevents()

        print("\nStrategy 4: Detecting EXPLAINS relationships...")
        self._auto_detect_explains()

        print("\nStrategy 5: Detecting USES relationships...")
        self._auto_detect_uses()

        print("\nStrategy 6: Detecting RELATES_TO relationships...")
        self._auto_detect_relates()

        print("\nStrategy 7: Detecting domain-specific relationships...")
        self._auto_detect_domains()

        # Commit changes
        self._commit()

        # Final stats
        print()
        print("="*80)
        print("ENHANCEMENT COMPLETE")
        print("="*80)
        final_stats = self.kg.get_statistics()
        self.stats['edges_after'] = final_stats['total_edges']

        print(f"\nBefore: {self.stats['edges_before']} edges")
        print(f"After:  {self.stats['edges_after']} edges")
        print(f"Added:  {self.stats['edges_added']} new edges")
        print()

        if self.stats['edges_by_type']:
            print("Edges added by type:")
            for rel_type, count in sorted(self.stats['edges_by_type'].items()):
                print(f"  {rel_type}: {count}")
        print()

    def _add_edge_safe(self, source_id: str, target_id: str,
                       relationship_type: str, properties: Dict = None) -> bool:
        """Add edge only if it doesn't already exist"""
        # Check if both nodes exist
        cursor = self.kg.conn.execute("SELECT COUNT(*) as count FROM nodes WHERE id = ?", (source_id,))
        if cursor.fetchone()['count'] == 0:
            return False

        cursor = self.kg.conn.execute("SELECT COUNT(*) as count FROM nodes WHERE id = ?", (target_id,))
        if cursor.fetchone()['count'] == 0:
            return False

        # Check if edge already exists
        cursor = self.kg.conn.execute("""
            SELECT COUNT(*) as count FROM edges
            WHERE source_id = ? AND target_id = ? AND relationship_type = ?
        """, (source_id, target_id, relationship_type))

        if cursor.fetchone()['count'] == 0:
            self.kg._add_edge(source_id, target_id, relationship_type, properties or {})
            self.stats['edges_added'] += 1
            self.stats['edges_by_type'][relationship_type] = \
                self.stats['edges_by_type'].get(relationship_type, 0) + 1
            return True
        return False

    def _auto_detect_demonstrates(self):
        """Automatically detect vulnerable contracts demonstrating vulnerabilities"""
        # Get all vulnerable contracts
        vulnerable_contracts = self.kg.find_by_type('VulnerableContract')
        vulnerabilities = self.kg.find_by_type('Vulnerability')

        for vc in vulnerable_contracts:
            vc_name = vc['name'].lower()
            vc_path = vc['file_path'].lower()

            for vuln in vulnerabilities:
                vuln_name = vuln['name'].lower()
                vuln_id = vuln['id']

                # Check if vulnerability name is in contract name or path
                if vuln_name.replace(' ', '_') in vc_name or vuln_name.replace(' ', '_') in vc_path:
                    if self._add_edge_safe(vc['id'], vuln_id, "DEMONSTRATES",
                                          {"auto_detected": True}):
                        print(f"  ✓ {vc['id']} → DEMONSTRATES → {vuln_id}")

    def _auto_detect_pairs(self):
        """Automatically detect DeepDive-Integration pairs"""
        deep_dives = self.kg.find_by_type('DeepDive')
        integrations = self.kg.find_by_type('Integration')

        for dd in deep_dives:
            dd_data = json.loads(dd['data']) if dd['data'] else {}
            dd_protocol = dd_data.get('protocol', '').lower()
            dd_name = dd['name'].lower()

            for integ in integrations:
                integ_data = json.loads(integ['data']) if integ['data'] else {}
                integ_protocol = integ_data.get('protocol', '').lower()
                integ_name = integ['name'].lower()

                # Check if protocols match or names are similar
                if (dd_protocol and dd_protocol in integ_protocol) or \
                   (dd_protocol and integ_protocol in dd_protocol) or \
                   self._name_similarity(dd_name, integ_name) > 0.5:

                    if self._add_edge_safe(dd['id'], integ['id'], "PAIRS_WITH",
                                          {"depth_ladder": "theory_to_practice", "auto_detected": True}):
                        print(f"  ✓ {dd['id']} ↔ {integ['id']}")

    def _auto_detect_prevents(self):
        """Automatically detect templates preventing vulnerabilities"""
        templates = self.kg.find_by_type('Template')
        vulnerabilities = self.kg.find_by_type('Vulnerability')

        for template in templates:
            # Read template file content
            template_path = Path(template['file_path'])
            if template_path.exists():
                content = template_path.read_text().lower()

                for vuln in vulnerabilities:
                    vuln_name = vuln['name'].lower()
                    vuln_keywords = self.vulnerability_keywords.get(
                        vuln_name.replace(' ', '_'), [vuln_name]
                    )

                    # Check for prevention patterns
                    for pattern, prevents_vuln in self.prevention_patterns.items():
                        if pattern.lower() in content and prevents_vuln in vuln_name.replace(' ', '_'):
                            if self._add_edge_safe(template['id'], vuln['id'], "PREVENTS",
                                                  {"mechanism": pattern, "auto_detected": True}):
                                print(f"  ✓ {template['id']} → PREVENTS → {vuln['id']} (via {pattern})")

    def _auto_detect_explains(self):
        """Automatically detect DeepDives explaining vulnerabilities"""
        deep_dives = self.kg.find_by_type('DeepDive')
        vulnerabilities = self.kg.find_by_type('Vulnerability')

        for dd in deep_dives:
            dd_path = Path(dd['file_path'])
            if dd_path.exists():
                content = dd_path.read_text().lower()

                for vuln in vulnerabilities:
                    vuln_name = vuln['name'].lower()
                    vuln_keywords = self.vulnerability_keywords.get(
                        vuln_name.replace(' ', '_'), [vuln_name]
                    )

                    # Check if DeepDive mentions vulnerability
                    mentions = sum(1 for keyword in vuln_keywords if keyword in content)
                    if mentions >= 2:  # At least 2 mentions to establish explanation
                        if self._add_edge_safe(dd['id'], vuln['id'], "EXPLAINS",
                                              {"mentions": mentions, "auto_detected": True}):
                            print(f"  ✓ {dd['id']} → EXPLAINS → {vuln['id']} ({mentions} mentions)")

    def _auto_detect_uses(self):
        """Automatically detect integrations using templates"""
        integrations = self.kg.find_by_type('Integration')
        templates = self.kg.find_by_type('Template')

        for integ in integrations:
            integ_path = Path(integ['file_path'])
            if integ_path.exists():
                content = integ_path.read_text().lower()

                for template in templates:
                    template_name = template['name'].lower().replace('.sol', '')

                    # Check if template type is mentioned
                    if 'erc20' in template_name and 'erc20' in content:
                        if self._add_edge_safe(integ['id'], template['id'], "USES",
                                              {"integration_type": "token", "auto_detected": True}):
                            print(f"  ✓ {integ['id']} → USES → {template['id']}")

                    elif 'erc721' in template_name and ('erc721' in content or 'nft' in content):
                        if self._add_edge_safe(integ['id'], template['id'], "USES",
                                              {"integration_type": "nft", "auto_detected": True}):
                            print(f"  ✓ {integ['id']} → USES → {template['id']}")

                    elif 'upgradeable' in template_name and ('proxy' in content or 'upgradeable' in content):
                        if self._add_edge_safe(integ['id'], template['id'], "USES",
                                              {"integration_type": "upgradeable", "auto_detected": True}):
                            print(f"  ✓ {integ['id']} → USES → {template['id']}")

    def _auto_detect_relates(self):
        """Automatically detect cross-category relationships"""
        # DeepDives relating to Templates based on domain
        deep_dives = self.kg.find_by_type('DeepDive')
        templates = self.kg.find_by_type('Template')

        for dd in deep_dives:
            dd_name = dd['name'].lower()
            dd_data = json.loads(dd['data']) if dd['data'] else {}

            for template in templates:
                template_name = template['name'].lower()

                # NFT domain
                if ('nft' in dd_name or 'seaport' in dd_name) and 'erc721' in template_name:
                    if self._add_edge_safe(dd['id'], template['id'], "RELATES_TO",
                                          {"domain": "NFT", "auto_detected": True}):
                        print(f"  ✓ {dd['id']} → RELATES_TO → {template['id']} (NFT domain)")

                # DeFi domain
                elif ('defi' in dd_name or 'uniswap' in dd_name or 'curve' in dd_name) and 'erc20' in template_name:
                    if self._add_edge_safe(dd['id'], template['id'], "RELATES_TO",
                                          {"domain": "DeFi", "auto_detected": True}):
                        print(f"  ✓ {dd['id']} → RELATES_TO → {template['id']} (DeFi domain)")

                # Staking domain
                elif ('staking' in dd_name or 'yield' in dd_name or 'yearn' in dd_name) and 'staking' in template_name:
                    if self._add_edge_safe(dd['id'], template['id'], "RELATES_TO",
                                          {"domain": "Staking", "auto_detected": True}):
                        print(f"  ✓ {dd['id']} → RELATES_TO → {template['id']} (Staking domain)")

    def _auto_detect_domains(self):
        """Detect domain-specific relationships for new content"""
        all_nodes = self.kg.conn.execute("SELECT * FROM nodes").fetchall()

        domain_keywords = {
            'DeFi': ['defi', 'swap', 'amm', 'dex', 'liquidity', 'yield', 'lending'],
            'NFT': ['nft', 'erc721', 'erc1155', 'marketplace', 'collectible'],
            'Gaming': ['game', 'gaming', 'vrf', 'random', 'achievement'],
            'AI': ['ai', 'oracle', 'chainlink functions', 'automation'],
            'Governance': ['governance', 'dao', 'vote', 'proposal', 'multisig']
        }

        for node in all_nodes:
            node_name = node['name'].lower()
            node_path = node['file_path'].lower()
            node_data = json.loads(node['data']) if node['data'] else {}

            # Detect domain based on keywords
            for domain, keywords in domain_keywords.items():
                if any(kw in node_name or kw in node_path for kw in keywords):
                    # Update node data with domain tag
                    node_data['inferred_domain'] = domain

                    # Update in database
                    self.kg.conn.execute("""
                        UPDATE nodes SET data = ? WHERE id = ?
                    """, (json.dumps(node_data), node['id']))

    def _name_similarity(self, name1: str, name2: str) -> float:
        """Calculate simple name similarity score"""
        name1_words = set(re.findall(r'\w+', name1.lower()))
        name2_words = set(re.findall(r'\w+', name2.lower()))

        if not name1_words or not name2_words:
            return 0.0

        intersection = name1_words & name2_words
        union = name1_words | name2_words

        return len(intersection) / len(union)

    def _commit(self):
        """Commit changes to database"""
        if self.kg and self.kg.conn:
            self.kg.conn.commit()
            print("\n✓ Changes committed to database")

    def close(self):
        """Close knowledge graph connection"""
        if self.kg:
            self.kg.close()


def main():
    enhancer = AutoEnhancer()

    try:
        enhancer.enhance()
    except Exception as e:
        print(f"\n❌ Error during enhancement: {e}")
        import traceback
        traceback.print_exc()
    finally:
        enhancer.close()

    print("\n✅ Automatic enhancement complete!")
    print("\nThe knowledge graph will now adapt to new content automatically!")
    print()


if __name__ == "__main__":
    main()
