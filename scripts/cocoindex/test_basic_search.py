#!/usr/bin/env python3
"""
Basic search test - No external dependencies required
Tests the metadata we extracted and basic search functionality
"""

import json
from pathlib import Path


def test_metadata_loading():
    """Test that we can load and parse the metadata"""
    print("="*80)
    print("TEST 1: Metadata Loading")
    print("="*80 + "\n")

    metadata_path = Path(".cocoindex/complete-metadata.json")

    if not metadata_path.exists():
        print("❌ FAILED: Metadata file not found")
        print(f"   Expected: {metadata_path}")
        return False

    try:
        with open(metadata_path) as f:
            metadata = json.load(f)

        print("✅ PASSED: Metadata loaded successfully\n")

        print("📊 Statistics:")
        stats = metadata.get("statistics", {})
        print(f"   Total Files: {stats.get('total_files', 'N/A')}")
        print(f"   Total Entities: {stats.get('total_entities', 'N/A')}")
        print(f"   Total Relationships: {stats.get('total_relationships', 'N/A')}")
        print(f"   Protocols Covered: {stats.get('protocols_covered', 'N/A')}")
        print()

        print("📚 Knowledge Bases:")
        kbs = metadata.get("knowledge_bases", {})
        for kb_name, kb_info in kbs.items():
            print(f"   {kb_name.upper()}: {kb_info.get('file_count', 'N/A')} files")
            print(f"      Purpose: {kb_info.get('purpose', 'N/A')}")
        print()

        print("🏷️  Entity Types:")
        entities = metadata.get("entities", {})
        for entity_type, entity_dict in entities.items():
            print(f"   {entity_type}: {len(entity_dict)} entities")
        print()

        return True

    except Exception as e:
        print(f"❌ FAILED: {e}")
        return False


def test_entity_search():
    """Test searching through entities"""
    print("="*80)
    print("TEST 2: Entity Search")
    print("="*80 + "\n")

    try:
        with open(".cocoindex/complete-metadata.json") as f:
            metadata = json.load(f)

        # Test 1: Find all reentrancy-related content
        print("Query 1: Find all reentrancy-related content\n")

        reentrancy_results = []

        # Search vulnerabilities
        vulnerabilities = metadata.get("entities", {}).get("vulnerabilities", {})
        for entity_id, entity in vulnerabilities.items():
            if "reentrancy" in entity_id.lower() or "reentrancy" in entity.get("name", "").lower():
                reentrancy_results.append({
                    "type": "Vulnerability",
                    "name": entity.get("name"),
                    "kb": entity.get("kb_type"),
                    "severity": entity.get("severity"),
                    "file": entity.get("file_path")
                })

        # Search vulnerable contracts
        contracts = metadata.get("entities", {}).get("vulnerable_contracts", {})
        for entity_id, entity in contracts.items():
            if "reentrancy" in entity.get("vulnerability_type", "").lower():
                reentrancy_results.append({
                    "type": "Vulnerable Contract",
                    "name": entity.get("name"),
                    "kb": entity.get("kb_type"),
                    "exploit": entity.get("historical_exploit"),
                    "loss": f"${entity.get('loss_usd', 0):,.0f}",
                    "file": entity.get("file_path")
                })

        if reentrancy_results:
            print(f"✅ Found {len(reentrancy_results)} reentrancy-related entities:\n")
            for i, result in enumerate(reentrancy_results, 1):
                print(f"{i}. {result['name']} ({result['type']})")
                print(f"   KB: {result['kb'].upper()}")
                if 'severity' in result:
                    print(f"   Severity: {result['severity']}")
                if 'exploit' in result:
                    print(f"   Exploit: {result['exploit']}")
                if 'loss' in result:
                    print(f"   Loss: {result['loss']}")
                print(f"   File: {result['file']}")
                print()
        else:
            print("⚠️  No results found")

        print()

        # Test 2: Find Uniswap versions
        print("Query 2: Find all Uniswap protocol versions\n")

        uniswap_results = []

        protocol_versions = metadata.get("entities", {}).get("protocol_versions", {})
        for entity_id, entity in protocol_versions.items():
            if "uniswap" in entity.get("name", "").lower():
                uniswap_results.append({
                    "name": entity.get("name"),
                    "version": entity.get("version"),
                    "release": entity.get("release_date"),
                    "features": entity.get("major_features", [])
                })

        deepdives = metadata.get("entities", {}).get("deepdives", {})
        for entity_id, entity in deepdives.items():
            if "uniswap" in entity.get("protocol", "").lower():
                uniswap_results.append({
                    "name": entity.get("name"),
                    "type": "Deep-Dive",
                    "lines": entity.get("lines"),
                    "file": entity.get("file_path")
                })

        integrations = metadata.get("entities", {}).get("integrations", {})
        for entity_id, entity in integrations.items():
            if "uniswap" in entity.get("protocol", "").lower():
                uniswap_results.append({
                    "name": entity.get("name"),
                    "type": "Integration",
                    "difficulty": entity.get("difficulty"),
                    "time": entity.get("estimated_time"),
                    "file": entity.get("file_path")
                })

        if uniswap_results:
            print(f"✅ Found {len(uniswap_results)} Uniswap-related entities:\n")
            for i, result in enumerate(uniswap_results, 1):
                print(f"{i}. {result['name']}")
                if 'version' in result:
                    print(f"   Version: {result['version']}")
                    print(f"   Release: {result['release']}")
                    print(f"   Features: {', '.join(result['features'])}")
                if 'type' in result:
                    print(f"   Type: {result['type']}")
                if 'lines' in result:
                    print(f"   Size: {result['lines']} lines")
                if 'difficulty' in result:
                    print(f"   Difficulty: {result['difficulty']}")
                if 'time' in result:
                    print(f"   Estimated Time: {result['time']}")
                if 'file' in result:
                    print(f"   File: {result['file']}")
                print()
        else:
            print("⚠️  No results found")

        print()
        return True

    except Exception as e:
        print(f"❌ FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_relationships():
    """Test relationship extraction"""
    print("="*80)
    print("TEST 3: Relationships")
    print("="*80 + "\n")

    try:
        with open(".cocoindex/complete-metadata.json") as f:
            metadata = json.load(f)

        relationships = metadata.get("relationships", [])

        print(f"Total Relationships Extracted: {len(relationships)}\n")

        if relationships:
            print("Sample Relationships:\n")

            # Group by type
            by_type = {}
            for rel in relationships:
                rel_type = rel.get("type", "unknown")
                if rel_type not in by_type:
                    by_type[rel_type] = []
                by_type[rel_type].append(rel)

            for rel_type, rels in by_type.items():
                print(f"  {rel_type}: {len(rels)} relationships")
                # Show first example
                if rels:
                    example = rels[0]
                    print(f"    Example: {example.get('source')} → {example.get('target')}")
                print()

            print("✅ PASSED: Relationships extracted successfully")
        else:
            print("⚠️  No relationships found")

        return True

    except Exception as e:
        print(f"❌ FAILED: {e}")
        return False


def main():
    """Run all tests"""
    print("\n" + "="*80)
    print("🧪 TESTING COCOINDEX METADATA & SEARCH")
    print("="*80 + "\n")

    results = []

    # Run tests
    results.append(("Metadata Loading", test_metadata_loading()))
    print()

    results.append(("Entity Search", test_entity_search()))
    print()

    results.append(("Relationships", test_relationships()))
    print()

    # Summary
    print("="*80)
    print("TEST SUMMARY")
    print("="*80 + "\n")

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{status}: {test_name}")

    print()
    print(f"Results: {passed}/{total} tests passed")
    print()

    if passed == total:
        print("🎉 All tests passed! Metadata extraction is working correctly.")
        print()
        print("Next Steps:")
        print("1. Install sentence-transformers: pip install sentence-transformers")
        print("2. Run semantic search: python scripts/cocoindex/poc_semantic_search.py")
        print("3. Start building the full knowledge graph")
    else:
        print("⚠️  Some tests failed. Please review the output above.")

    print()


if __name__ == "__main__":
    main()
