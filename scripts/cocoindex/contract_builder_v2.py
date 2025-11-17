#!/usr/bin/env python3
"""
Smart Contract Builder V2 - With Knowledge Graph Integration

This version queries the knowledge graph to:
1. Find relevant security patterns
2. Discover vulnerabilities to protect against
3. Select optimal templates
4. Add contextual documentation from deep dives
"""

import sys
import os

# Add the current directory to path so we can import knowledge_graph
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from knowledge_graph import KnowledgeGraph
from contract_builder import (
    SmartContractBuilder,
    SecurityInjector,
    GasOptimizer,
    DeFiProtectionModule,
    GamingProtectionModule,
    NFTProtectionModule,
    AIIntegrationModule
)
import json
import argparse
from pathlib import Path
from datetime import datetime


class EnhancedContractBuilder(SmartContractBuilder):
    """Enhanced contract builder with knowledge graph integration"""

    def __init__(self):
        super().__init__()
        self.kg = KnowledgeGraph()

    def generate_contract_with_kg(self, args) -> str:
        """Generate contract using knowledge graph insights"""

        print(f"\n🔍 Querying knowledge graph for {args.domain} patterns...")

        # Query knowledge graph for relevant information
        kg_insights = self._query_knowledge_graph(args)

        # Log insights
        print(f"  Found {len(kg_insights['vulnerabilities'])} relevant vulnerabilities")
        print(f"  Found {len(kg_insights['templates'])} template matches")
        print(f"  Found {len(kg_insights['deepdives'])} relevant deep dives")
        print(f"  Found {len(kg_insights['integrations'])} integration guides")

        # Generate contract using parent method
        contract = self.generate_contract(args)

        # Enhance with KG-derived documentation
        enhanced = self._add_kg_documentation(contract, kg_insights, args)

        return enhanced

    def _query_knowledge_graph(self, args) -> dict:
        """Query knowledge graph for relevant entities"""

        insights = {
            "vulnerabilities": [],
            "templates": [],
            "deepdives": [],
            "integrations": [],
            "vulnerable_contracts": []
        }

        # 1. Find all vulnerabilities (to know what to protect against)
        vulns = self.kg.find_by_type("Vulnerability")
        insights["vulnerabilities"] = vulns

        # 2. Find templates matching contract type
        templates = self.kg.find_by_type("Template")
        # Filter by contract type
        matching_templates = [
            t for t in templates
            if args.type.lower() in json.loads(t['data']).get('name', '').lower()
        ]
        insights["templates"] = matching_templates

        # 3. Search for domain-relevant deep dives
        domain_keywords = {
            "defi": ["uniswap", "defi", "dex", "amm", "trading"],
            "gaming": ["game", "vrf", "randomness", "nft"],
            "nft": ["erc721", "nft", "metadata", "royalty"],
            "ai": ["chainlink", "oracle", "ai", "agent"]
        }

        keywords = domain_keywords.get(args.domain, [])
        for keyword in keywords:
            results = self.kg.search(keyword, limit=5)
            for r in results:
                if r['type'] == 'DeepDive':
                    insights["deepdives"].append(r)
                elif r['type'] == 'Integration':
                    insights["integrations"].append(r)

        # Remove duplicates
        insights["deepdives"] = list({d['id']: d for d in insights["deepdives"]}.values())
        insights["integrations"] = list({i['id']: i for i in insights["integrations"]}.values())

        # 4. Find vulnerable contracts (anti-patterns to avoid)
        vulnerable = self.kg.find_by_type("VulnerableContract")
        insights["vulnerable_contracts"] = vulnerable

        return insights

    def _add_kg_documentation(self, contract: str, insights: dict, args) -> str:
        """Add KG-derived documentation to contract"""

        # Create header comment with KB references
        header = []
        header.append("/**")
        header.append(" * KNOWLEDGE BASE REFERENCES")
        header.append(" * This contract was generated using knowledge from:")
        header.append(" *")

        # Add vulnerability references
        if insights["vulnerabilities"]:
            header.append(" * VULNERABILITIES PROTECTED AGAINST:")
            for vuln in insights["vulnerabilities"][:5]:
                data = json.loads(vuln['data'])
                loss = data.get('historical_losses_usd', 0)
                if loss > 0:
                    header.append(f" *   - {vuln['name']}: ${loss:,.0f} in historical losses")
                else:
                    header.append(f" *   - {vuln['name']}")

        # Add template references
        if insights["templates"]:
            header.append(" *")
            header.append(" * BASED ON TEMPLATES:")
            for template in insights["templates"][:3]:
                header.append(f" *   - {template['file_path']}")

        # Add deep dive references
        if insights["deepdives"]:
            header.append(" *")
            header.append(" * REFERENCE MATERIALS:")
            for dd in insights["deepdives"][:3]:
                header.append(f" *   - {dd['name']}")

        # Add integration guides
        if insights["integrations"]:
            header.append(" *")
            header.append(" * INTEGRATION GUIDES:")
            for integ in insights["integrations"][:3]:
                header.append(f" *   - {integ['name']}")

        header.append(" */")
        header.append("")

        # Insert header after SPDX and pragma
        lines = contract.split("\n")
        insert_pos = 0
        for i, line in enumerate(lines):
            if line.startswith("// Auto-generated"):
                insert_pos = i
                break

        # Insert header
        enhanced_lines = lines[:insert_pos] + header + lines[insert_pos:]

        return "\n".join(enhanced_lines)

    def generate_deployment_guide(self, args, insights: dict) -> str:
        """Generate deployment guide with KB references"""

        guide = []
        guide.append(f"# {args.type} {args.domain.capitalize()} Contract Deployment Guide")
        guide.append(f"## Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        guide.append("")

        # Security considerations from KB
        guide.append("## Security Considerations")
        guide.append("")
        guide.append("This contract protects against the following vulnerabilities:")
        guide.append("")

        for vuln in insights["vulnerabilities"][:10]:
            data = json.loads(vuln['data'])
            guide.append(f"### {vuln['name']}")
            guide.append(f"- **Severity**: {data.get('severity', 'unknown')}")
            if data.get('historical_losses_usd', 0) > 0:
                guide.append(f"- **Historical Loss**: ${data['historical_losses_usd']:,.0f}")
            guide.append(f"- **Reference**: `{vuln['file_path']}`")
            guide.append("")

        # Recommended reading
        if insights["deepdives"]:
            guide.append("## Recommended Reading")
            guide.append("")
            guide.append("Before deploying, review these deep dives:")
            guide.append("")
            for dd in insights["deepdives"][:5]:
                data = json.loads(dd['data'])
                guide.append(f"- **{dd['name']}**")
                guide.append(f"  - Protocol: {data.get('protocol', 'N/A')}")
                guide.append(f"  - File: `{dd['file_path']}`")
                guide.append("")

        # Integration guides
        if insights["integrations"]:
            guide.append("## Integration Guides")
            guide.append("")
            for integ in insights["integrations"][:5]:
                data = json.loads(integ['data'])
                guide.append(f"- **{integ['name']}**")
                guide.append(f"  - File: `{integ['file_path']}`")
                guide.append("")

        return "\n".join(guide)

    def close(self):
        """Close knowledge graph connection"""
        if self.kg:
            self.kg.close()


def main():
    parser = argparse.ArgumentParser(
        description="Generate secure smart contracts using knowledge graph"
    )
    parser.add_argument("--type", required=True, choices=["ERC20", "ERC721", "ERC1155"],
                        help="Contract type")
    parser.add_argument("--domain", required=True, choices=["defi", "gaming", "nft", "ai"],
                        help="Application domain")
    parser.add_argument("--features", default="",
                        help="Comma-separated features")
    parser.add_argument("--output", default="generated/",
                        help="Output directory")

    args = parser.parse_args()

    print("="*80)
    print("🔐 Safe Smart Contract Builder V2 (Knowledge Graph Powered)")
    print("="*80)
    print()
    print(f"Generating {args.type} contract for {args.domain} domain...")
    print(f"Features: {args.features or 'default'}")

    # Build contract with KG integration
    builder = EnhancedContractBuilder()

    print("\n📋 Step 1: Querying knowledge graph and generating contract...")
    contract_code = builder.generate_contract_with_kg(args)

    print("🧪 Step 2: Generating test suite...")
    test_code = builder.generate_tests(contract_code, args)

    print("✅ Step 3: Generating deployment checklist...")
    checklist = builder.generate_deployment_checklist(args)

    # Get KG insights for deployment guide
    insights = builder._query_knowledge_graph(args)

    print("📚 Step 4: Generating deployment guide from KB...")
    deployment_guide = builder.generate_deployment_guide(args, insights)

    # Save files
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    contract_file = output_dir / f"Secure{args.type}Contract.sol"
    test_file = output_dir / f"Secure{args.type}Test.sol"
    checklist_file = output_dir / "PRE_DEPLOYMENT_CHECKLIST.md"
    guide_file = output_dir / "DEPLOYMENT_GUIDE.md"

    contract_file.write_text(contract_code)
    test_file.write_text(test_code)
    checklist_file.write_text(checklist)
    guide_file.write_text(deployment_guide)

    print()
    print("✅ Generation complete!")
    print()
    print(f"📁 Files created:")
    print(f"   Contract:  {contract_file}")
    print(f"   Tests:     {test_file}")
    print(f"   Checklist: {checklist_file}")
    print(f"   Guide:     {guide_file}")
    print()
    print("🎯 Next steps:")
    print("   1. Review generated contract and KB references")
    print("   2. Read deployment guide")
    print("   3. Run tests: forge test")
    print("   4. Complete security checklist")
    print("   5. Deploy to testnet")
    print()

    builder.close()


if __name__ == "__main__":
    main()
