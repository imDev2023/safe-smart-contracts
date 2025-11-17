#!/usr/bin/env python3
"""
Extract structured metadata from SEARCHINDEX.json and markdown files.
This creates .cocoindex/structured-metadata.json for CocoIndex to use.
"""

import json
from pathlib import Path
from typing import Dict, List, Any


def load_search_index() -> Dict:
    """Load existing SEARCHINDEX.json"""
    with open("SEARCHINDEX.json") as f:
        return json.load(f)


def extract_vulnerability_metadata(search_index: Dict) -> Dict[str, Any]:
    """Extract vulnerability metadata from attack_prevention section"""
    vulnerabilities = {}

    attack_files = search_index["sections"]["attack_prevention"]["files"]

    for entry in attack_files:
        vuln_id = f"vuln_{entry['name'].replace('.md', '').replace('-', '_')}"

        # Extract prevention methods
        prevention_methods = []
        for method in entry.get("prevention_methods", []):
            prevention_methods.append({
                "id": f"prevent_{method.lower().replace(' ', '_').replace('-', '_')}",
                "name": method,
                "type": "TECHNIQUE"  # Default, can be refined
            })

        # Extract real exploits
        real_exploits = []
        for exploit_str in entry.get("real_exploits", []):
            # Parse exploit string like "The DAO ($60 million)"
            if "(" in exploit_str:
                name = exploit_str.split("(")[0].strip()
                loss_str = exploit_str.split("(")[1].split(")")[0]

                # Extract dollar amount
                loss_usd = 0
                if "$" in loss_str and "M" in loss_str:
                    amount = loss_str.replace("$", "").replace("M", "").strip()
                    try:
                        loss_usd = float(amount.replace(",", "")) * 1_000_000
                    except ValueError:
                        pass

                real_exploits.append({
                    "id": f"exploit_{name.lower().replace(' ', '_')}",
                    "name": name,
                    "loss_usd": loss_usd
                })

        vulnerabilities[vuln_id] = {
            "id": vuln_id,
            "name": entry["name"].replace(".md", "").replace("-", " ").title(),
            "severity": entry["severity"].upper(),
            "cwe": entry.get("cve", ""),
            "file_path": f"knowledge-base-action/03-attack-prevention/{entry['name']}",
            "keywords": entry["keywords"],
            "description": entry["description"],
            "prevention_methods": prevention_methods,
            "real_exploits": real_exploits,
            "categories": []  # Will be extracted from vulnerability-matrix.md
        }

    return vulnerabilities


def extract_template_metadata(search_index: Dict) -> Dict[str, Any]:
    """Extract template metadata from templates section"""
    templates = {}

    template_files = search_index["sections"]["templates"]["files"]

    for entry in template_files:
        template_id = f"template_{entry['name'].replace('.sol', '').replace('-', '_')}"

        templates[template_id] = {
            "id": template_id,
            "name": entry["name"],
            "file_path": f"knowledge-base-action/02-contract-templates/{entry['name']}",
            "solidity_version": entry.get("solidity_version", "0.8.20"),
            "lines": entry["lines"],
            "features": entry.get("features", []),
            "use_cases": entry.get("use_cases", []),
            "keywords": entry["keywords"]
        }

    return templates


def extract_pattern_metadata() -> Dict[str, Any]:
    """Extract pattern metadata from pattern-catalog.md"""
    patterns = {}

    # Read pattern-catalog.md
    pattern_file = Path("knowledge-base-action/01-quick-reference/pattern-catalog.md")

    if pattern_file.exists():
        content = pattern_file.read_text()

        # Basic pattern extraction (can be enhanced)
        # For now, create entries for known patterns
        known_patterns = [
            "Factory Pattern",
            "Proxy Delegate Pattern",
            "Vault Pattern",
            "Staking Pattern",
            "AMM Pattern",
            "Time Lock Pattern",
            "Governor Pattern",
            "Oracle Pattern",
            "Flash Loan Pattern",
            "Beacon Pattern",
            "Access Restriction Pattern",
            "Checks-Effects-Interactions Pattern"
        ]

        for pattern_name in known_patterns:
            pattern_id = f"pattern_{pattern_name.lower().replace(' ', '_').replace('-', '_')}"

            patterns[pattern_id] = {
                "id": pattern_id,
                "name": pattern_name,
                "file_path": "knowledge-base-action/01-quick-reference/pattern-catalog.md",
                "category": "SECURITY" if "security" in pattern_name.lower() else "BEHAVIORAL"
            }

    return patterns


def extract_snippet_metadata(search_index: Dict) -> Dict[str, Any]:
    """Extract code snippet metadata"""
    snippets = {}

    snippet_files = search_index["sections"]["code_snippets"]["files"]

    for entry in snippet_files:
        # Determine snippet type from filename
        snippet_type = entry["name"].replace(".md", "").upper()
        if snippet_type == "OZ-IMPORTS":
            snippet_type = "IMPORT"
        elif snippet_type == "MODIFIERS":
            snippet_type = "MODIFIER"
        elif snippet_type == "EVENTS":
            snippet_type = "EVENT"
        elif snippet_type == "ERRORS":
            snippet_type = "ERROR"
        elif snippet_type == "LIBRARIES":
            snippet_type = "FUNCTION"

        # Create entries for each snippet (simplified - would parse file in full implementation)
        snippet_id = f"snippets_{entry['name'].replace('.md', '').replace('-', '_')}"

        snippets[snippet_id] = {
            "id": snippet_id,
            "name": entry["name"].replace(".md", ""),
            "type": snippet_type,
            "file_path": f"knowledge-base-action/04-code-snippets/{entry['name']}",
            "count": entry.get("snippets_count", 0),
            "categories": entry.get("categories", [])
        }

    return snippets


def main():
    """Extract all metadata and save to structured-metadata.json"""
    print("📊 Extracting metadata from knowledge base...")

    # Load search index
    search_index = load_search_index()

    # Extract all entity types
    print("   - Extracting vulnerabilities...")
    vulnerabilities = extract_vulnerability_metadata(search_index)
    print(f"     ✓ Found {len(vulnerabilities)} vulnerabilities")

    print("   - Extracting templates...")
    templates = extract_template_metadata(search_index)
    print(f"     ✓ Found {len(templates)} templates")

    print("   - Extracting patterns...")
    patterns = extract_pattern_metadata()
    print(f"     ✓ Found {len(patterns)} patterns")

    print("   - Extracting code snippets...")
    snippets = extract_snippet_metadata(search_index)
    print(f"     ✓ Found {len(snippets)} snippet collections")

    # Combine all metadata
    structured_metadata = {
        "version": "1.0.0",
        "created": "2025-11-16",
        "description": "Structured metadata for CocoIndex knowledge graph",
        "entities": {
            "vulnerabilities": vulnerabilities,
            "templates": templates,
            "patterns": patterns,
            "code_snippets": snippets
        },
        "statistics": {
            "total_vulnerabilities": len(vulnerabilities),
            "total_templates": len(templates),
            "total_patterns": len(patterns),
            "total_snippet_collections": len(snippets)
        }
    }

    # Save to file
    output_path = Path(".cocoindex/structured-metadata.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(structured_metadata, indent=2))

    print(f"\n✅ Metadata extraction complete!")
    print(f"   Output: {output_path}")
    print(f"   Total entities: {sum(structured_metadata['statistics'].values())}")


if __name__ == "__main__":
    main()
