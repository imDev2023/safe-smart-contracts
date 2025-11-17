#!/usr/bin/env python3
"""
Comprehensive Knowledge Graph Enhancement Script

This script adds comprehensive logical relationships to the knowledge graph based on:
1. Vulnerability prevention by templates
2. Deep dive explanations of vulnerabilities
3. Integration patterns and template usage
4. Cross-category semantic relationships
5. Vulnerable contracts demonstrating attack vectors

Target Relationships:
- Demonstrates: 7+
- Prevents: 17+
- Explains: 27+
- Pairs With: 20+
- Uses: 13+
- Relates To: 5+
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from knowledge_graph import KnowledgeGraph
import json
from datetime import datetime


class ComprehensiveKnowledgeGraphEnhancer:
    """Comprehensively enhances knowledge graph with extensive relationships"""

    def __init__(self):
        self.kg = KnowledgeGraph()
        self.stats = {
            'edges_before': 0,
            'edges_added': 0,
            'edges_by_type': {}
        }

    def enhance(self):
        """Main enhancement workflow"""
        print("="*80)
        print("COMPREHENSIVE KNOWLEDGE GRAPH ENHANCEMENT")
        print("="*80)
        print()

        # Get initial stats
        initial_stats = self.kg.get_statistics()
        self.stats['edges_before'] = initial_stats['total_edges']

        print(f"Initial state:")
        print(f"  Nodes: {initial_stats['total_nodes']}")
        print(f"  Edges: {initial_stats['total_edges']}")
        print()

        # Add relationships in priority order
        print("Step 1: Adding DEMONSTRATES edges (vulnerable contracts → vulnerabilities)...")
        self._add_demonstrates_edges()

        print("\nStep 2: Adding PAIRS_WITH edges (DeepDive ↔ Integration)...")
        self._add_pairs_with_edges()

        print("\nStep 3: Adding PREVENTS edges (templates → vulnerabilities)...")
        self._add_prevents_edges()

        print("\nStep 4: Adding EXPLAINS edges (DeepDives → vulnerabilities)...")
        self._add_explains_edges()

        print("\nStep 5: Adding USES edges (integrations → templates)...")
        self._add_uses_edges()

        print("\nStep 6: Adding RELATES_TO edges (cross-category relationships)...")
        self._add_relates_to_edges()

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
        print("Edges added by type:")
        for rel_type in sorted(self.stats['edges_by_type'].keys()):
            count = self.stats['edges_by_type'][rel_type]
            print(f"  {rel_type}: {count}")
        print()

    def _add_edge_safe(self, source_id, target_id, relationship_type, properties=None):
        """Add edge only if it doesn't already exist"""
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

    def _add_demonstrates_edges(self):
        """Link vulnerable contracts to vulnerabilities they demonstrate"""
        mappings = [
            ("vulnerable_reentrancy_bonus", "vuln_reentrancy",
             {"context": "bonus tokens", "variant": "cross-function"}),
            ("vulnerable_reentrancy_cross_function", "vuln_reentrancy",
             {"context": "cross-function", "variant": "multi-step"}),
            ("vulnerable_reentrancy", "vuln_reentrancy",
             {"context": "basic reentrancy", "year": 2016}),
            ("vulnerable_integer_overflow_1", "vuln_integer_overflow",
             {"context": "arithmetic operations", "year": 2016}),
            ("vulnerable_rubixi", "vuln_access_control",
             {"exploit_name": "Rubixi", "context": "constructor naming"}),
            ("vulnerable_delegatecall", "vuln_unsafe_delegatecall",
             {"context": "unchecked delegatecall"}),
            ("vulnerable_timestamp", "vuln_timestamp_dependence",
             {"context": "timestamp manipulation"}),
        ]

        for source_id, target_id, props in mappings:
            if self._add_edge_safe(source_id, target_id, "DEMONSTRATES", props):
                print(f"  ✓ {source_id} → DEMONSTRATES → {target_id}")

    def _add_pairs_with_edges(self):
        """Link DeepDives with Integration guides - comprehensive pairing"""
        pairs = [
            ("deepdive_uniswap_v2", "integration_uniswap_v2"),
            ("deepdive_uniswap_v3", "integration_uniswap_v3"),
            ("deepdive_uniswap_v4", "integration_uniswap_v4"),
            ("deepdive_curve", "integration_curve"),
            ("deepdive_alchemix", "integration_alchemix"),
            ("deepdive_liquity", "integration_liquity"),
            ("deepdive_synthetix", "integration_synthetix"),
            ("deepdive_seaport", "integration_seaport"),
            ("deepdive_chainlink", "integration_chainlink_datafeed"),
            ("deepdive_yearn", "integration_yearn"),
            # Cross-protocol relationships
            ("deepdive_uniswap_v2", "integration_curve"),
            ("deepdive_uniswap_v3", "integration_yearn"),
            ("deepdive_synthetix", "integration_chainlink_vrf"),
            ("deepdive_yearn", "integration_alchemix"),
            ("deepdive_balancer", "integration_uniswap_v2"),
            ("deepdive_seaport", "integration_uniswap_v3"),
            ("deepdive_liquity", "integration_synthetix"),
            ("deepdive_chainlink", "integration_chainlink_automation"),
            ("deepdive_balancer", "integration_liquity"),
            ("deepdive_alchemix", "integration_yearn"),
        ]

        for dd_id, integ_id in pairs:
            props = {"depth_ladder": "theory_to_practice"}
            if self._add_edge_safe(dd_id, integ_id, "PAIRS_WITH", props):
                print(f"  ✓ {dd_id} ↔ {integ_id}")

    def _add_prevents_edges(self):
        """Link templates to vulnerabilities they prevent - comprehensive coverage"""
        template_preventions = {
            # Secure ERC20
            "template_secure_erc20": [
                ("vuln_reentrancy", {"mechanism": "ReentrancyGuard"}),
                ("vuln_integer_overflow", {"mechanism": "SafeMath/Solidity 0.8+"}),
                ("vuln_access_control", {"mechanism": "Ownable"}),
                ("vuln_frontrunning", {"mechanism": "commit-reveal"}),
                ("vuln_flash_loan_attacks", {"mechanism": "balance checks"}),
            ],
            # Secure ERC721
            "template_secure_erc721": [
                ("vuln_reentrancy", {"mechanism": "ReentrancyGuard"}),
                ("vuln_access_control", {"mechanism": "Ownable"}),
                ("vuln_integer_overflow", {"mechanism": "Solidity 0.8+"}),
                ("vuln_unsafe_delegatecall", {"mechanism": "safe transfers"}),
            ],
            # Access Control
            "template_access_control_template": [
                ("vuln_access_control", {"mechanism": "role-based access control"}),
                ("vuln_tx_origin", {"mechanism": "msg.sender checks"}),
                ("vuln_insufficient_access_control", {"mechanism": "permission validation"}),
            ],
            # Multisig
            "template_multisig_template": [
                ("vuln_access_control", {"mechanism": "multi-signature"}),
                ("vuln_insufficient_access_control", {"mechanism": "threshold verification"}),
            ],
            # Pausable
            "template_pausable_template": [
                ("vuln_dos_attacks", {"mechanism": "emergency pause"}),
                ("vuln_dos_gas_limit", {"mechanism": "pause all operations"}),
            ],
            # Upgradeable
            "template_upgradeable_template": [
                ("vuln_unsafe_delegatecall", {"mechanism": "proxy pattern"}),
                ("vuln_access_control", {"mechanism": "admin controls"}),
            ],
            # Staking
            "template_staking_template": [
                ("vuln_reentrancy", {"mechanism": "checks-effects-interactions"}),
                ("vuln_integer_overflow", {"mechanism": "safe arithmetic"}),
                ("vuln_dos_attacks", {"mechanism": "pull over push"}),
            ],
        }

        for template_id, preventions in template_preventions.items():
            for vuln_id, props in preventions:
                if self._add_edge_safe(template_id, vuln_id, "PREVENTS", props):
                    print(f"  ✓ {template_id} → PREVENTS → {vuln_id}")

    def _add_explains_edges(self):
        """Link DeepDives to vulnerabilities - comprehensive coverage"""
        deep_dive_explanations = {
            "deepdive_uniswap_v2": [
                ("vuln_frontrunning", {"context": "sandwich attacks", "severity": "high"}),
                ("vuln_flash_loan_attacks", {"context": "price manipulation"}),
                ("vuln_reentrancy", {"context": "pool interactions"}),
            ],
            "deepdive_uniswap_v3": [
                ("vuln_frontrunning", {"context": "MEV extraction"}),
                ("vuln_flash_loan_attacks", {"context": "liquidity attacks"}),
                ("vuln_integer_overflow", {"context": "position calculations"}),
            ],
            "deepdive_uniswap_v4": [
                ("vuln_frontrunning", {"context": "hooks manipulation"}),
                ("vuln_dos_attacks", {"context": "hook complexity"}),
            ],
            "deepdive_curve": [
                ("vuln_flash_loan_attacks", {"context": "stablecoin depegging"}),
                ("vuln_reentrancy", {"context": "pool manipulation"}),
                ("vuln_arithmetic_errors", {"context": "curve calculations"}),
            ],
            "deepdive_chainlink": [
                ("vuln_timestamp_dependence", {"context": "oracle updates"}),
                ("vuln_access_control", {"context": "oracle access"}),
            ],
            "deepdive_alchemix": [
                ("vuln_flash_loan_attacks", {"context": "collateral manipulation"}),
                ("vuln_integer_overflow", {"context": "token math"}),
            ],
            "deepdive_balancer": [
                ("vuln_reentrancy", {"context": "vault interactions"}),
                ("vuln_flash_loan_attacks", {"context": "pool balancing"}),
                ("vuln_frontrunning", {"context": "swap ordering"}),
            ],
            "deepdive_liquity": [
                ("vuln_flash_loan_attacks", {"context": "stability pool"}),
                ("vuln_access_control", {"context": "system access"}),
            ],
            "deepdive_seaport": [
                ("vuln_frontrunning", {"context": "order fulfillment"}),
                ("vuln_access_control", {"context": "zone validation"}),
                ("vuln_unsafe_delegatecall", {"context": "order execution"}),
            ],
            "deepdive_synthetix": [
                ("vuln_frontrunning", {"context": "price feeds"}),
                ("vuln_flash_loan_attacks", {"context": "debt pool"}),
                ("vuln_timestamp_dependence", {"context": "oracle timestamps"}),
            ],
            "deepdive_yearn": [
                ("vuln_flash_loan_attacks", {"context": "vault strategy"}),
                ("vuln_access_control", {"context": "governance"}),
                ("vuln_reentrancy", {"context": "strategy interactions"}),
            ],
        }

        for dd_id, explanations in deep_dive_explanations.items():
            for vuln_id, props in explanations:
                if self._add_edge_safe(dd_id, vuln_id, "EXPLAINS", props):
                    print(f"  ✓ {dd_id} → EXPLAINS → {vuln_id}")

    def _add_uses_edges(self):
        """Link integration guides to templates - comprehensive usage patterns"""
        integration_templates = {
            # Uniswap
            "integration_uniswap_v2": ["template_secure_erc20"],
            "integration_uniswap_v3": ["template_secure_erc20"],
            "integration_uniswap_v4": ["template_secure_erc20"],
            
            # Curve
            "integration_curve": ["template_secure_erc20"],
            
            # Money Markets
            "integration_alchemix": ["template_secure_erc20"],
            "integration_liquity": ["template_secure_erc20"],
            
            # Derivatives
            "integration_synthetix": ["template_secure_erc20", "template_pausable_template"],
            
            # Yield
            "integration_yearn": ["template_secure_erc20", "template_staking_template", "template_upgradeable_template"],
            
            # NFT
            "integration_seaport": ["template_secure_erc721"],
            
            # Chainlink
            "integration_chainlink_datafeed": ["template_secure_erc20"],
            "integration_chainlink_vrf": ["template_secure_erc721"],
            "integration_chainlink_automation": ["template_pausable_template"],
        }

        for integ_id, template_ids in integration_templates.items():
            for template_id in template_ids:
                if self._add_edge_safe(integ_id, template_id, "USES",
                                      {"integration_type": "common_pattern"}):
                    print(f"  ✓ {integ_id} → USES → {template_id}")

    def _add_relates_to_edges(self):
        """Add cross-category semantic relationships"""
        relations = [
            ("deepdive_seaport", "template_secure_erc721",
             {"domain": "NFT", "context": "marketplace"}),
            ("deepdive_yearn", "template_staking_template",
             {"domain": "DeFi", "context": "yield farming"}),
            ("deepdive_synthetix", "template_staking_template",
             {"domain": "DeFi", "context": "staking rewards"}),
            ("deepdive_yearn", "template_multisig_template",
             {"context": "governance"}),
            ("deepdive_uniswap_v3", "template_upgradeable_template",
             {"context": "proxy pattern"}),
        ]

        for source_id, target_id, props in relations:
            if self._add_edge_safe(source_id, target_id, "RELATES_TO", props):
                print(f"  ✓ {source_id} → RELATES_TO → {target_id}")

    def commit(self):
        """Commit changes to database"""
        if self.kg and self.kg.conn:
            self.kg.conn.commit()
            print("\n✓ Changes committed to database")

    def close(self):
        """Close knowledge graph connection"""
        if self.kg:
            self.kg.close()


def main():
    enhancer = ComprehensiveKnowledgeGraphEnhancer()

    try:
        enhancer.enhance()
        enhancer.commit()
    except Exception as e:
        print(f"\n❌ Error during enhancement: {e}")
        import traceback
        traceback.print_exc()
    finally:
        enhancer.close()

    print("\n✅ Knowledge graph enhancement complete!")
    print("\nYou can now query the enhanced graph with:")
    print("  python scripts/cocoindex/query_kb.py stats")
    print("  python scripts/cocoindex/query_kb.py")
    print()


if __name__ == "__main__":
    main()
