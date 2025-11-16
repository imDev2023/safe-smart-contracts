# Adding New Content to Knowledge Bases

This guide explains how to add new repositories, files, and content to your knowledge bases while maintaining the knowledge graph.

## 📚 Knowledge Base Structure

```
knowledge-base-action/          # Production security patterns
├── 01-gas-optimization/        # Gas optimization techniques
├── 02-contract-templates/      # Secure contract templates
└── 03-attack-prevention/       # Vulnerability guides

knowledge-base-research/        # Protocol analysis
├── repos/                      # Deep dives and integrations
│   ├── uniswap/
│   ├── chainlink/
│   ├── curve/
│   └── [your-new-repo]/       # Add new repos here
└── not-so-smart/              # Vulnerable contract examples
```

## 🚀 Quick Start: Adding New Content

### Option 1: Automatic Rebuild (Recommended)

```bash
# 1. Add your new files to knowledge-base-action or knowledge-base-research
cp -r /path/to/new-repo knowledge-base-research/repos/new-repo

# 2. Run automatic rebuild
./scripts/cocoindex/rebuild_graph.sh

# 3. Done! View updated graph at http://localhost:5000/graph
```

### Option 2: Manual Steps

```bash
# 1. Add content
# 2. Extract metadata
python3 scripts/cocoindex/extract_complete_metadata.py

# 3. Rebuild knowledge graph
python3 scripts/cocoindex/knowledge_graph.py

# 4. Auto-enhance relationships
python3 scripts/cocoindex/auto_enhance.py

# 5. View results
./start-web.sh
```

## 📖 Detailed Instructions

### 1. Adding a New Protocol/Repo

When adding analysis of a new DeFi protocol, NFT marketplace, or any repo:

```bash
# Example: Adding Compound Finance analysis
mkdir -p knowledge-base-research/repos/compound

# Add deep dive (theory)
cat > knowledge-base-research/repos/compound/01-compound-deep-dive.md << 'EOF'
# Compound Finance Architecture Deep-Dive

## Overview
Compound is a decentralized lending protocol...

## Core Concepts
- cTokens
- Interest rate models
- Liquidations

## Security Considerations
- Flash loan attacks via borrow/repay
- Oracle manipulation risks
- Collateral factor vulnerabilities
EOF

# Add integration guide (practice)
cat > knowledge-base-research/repos/compound/02-compound-integration.md << 'EOF'
# Compound Integration Guide

## Setup
```solidity
import "@compound/CToken.sol";

contract MyDeFiProtocol {
    CToken public cToken;

    function supply(uint256 amount) external {
        // Integration code
    }
}
```

## Best Practices
- Always check return values
- Handle liquidation edge cases
EOF

# Rebuild graph
./scripts/cocoindex/rebuild_graph.sh
```

**What happens automatically:**
- ✅ New nodes created: `deepdive_compound`, `integration_compound`
- ✅ Relationship detected: `PAIRS_WITH` (DeepDive ↔ Integration)
- ✅ Vulnerability relationships inferred based on content
- ✅ Domain tagged automatically (DeFi)

### 2. Adding a New Vulnerability Pattern

```bash
# Add to Action KB
cat > knowledge-base-action/03-attack-prevention/price-oracle-manipulation.md << 'EOF'
# Price Oracle Manipulation

**Severity**: CRITICAL

## Description
Attackers can manipulate price oracles using flash loans...

## Prevention
1. Use time-weighted average prices (TWAP)
2. Multi-oracle aggregation
3. Circuit breakers

## Example Safe Implementation
```solidity
contract SafeOracle {
    using Chainlink for AggregatorV3Interface;
    // ...
}
```
EOF

# Rebuild
./scripts/cocoindex/rebuild_graph.sh
```

**What happens automatically:**
- ✅ New vulnerability node created
- ✅ Linked to DeepDives that mention oracle manipulation
- ✅ Linked to templates that use Chainlink
- ✅ Available in contract generator

### 3. Adding a New Template

```bash
# Add to Action KB
cat > knowledge-base-action/02-contract-templates/lending-template.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Secure Lending Template
 * @notice Template for building lending protocols
 */
contract SecureLending is ReentrancyGuard, Ownable {
    // Implementation
}
EOF

# Rebuild
./scripts/cocoindex/rebuild_graph.sh
```

**What happens automatically:**
- ✅ New template node created
- ✅ `PREVENTS` relationships detected (ReentrancyGuard → Reentrancy)
- ✅ `USES` relationships from DeFi integrations
- ✅ Available in contract generator

### 4. Adding Vulnerable Contract Examples

```bash
# Add to Research KB
mkdir -p knowledge-base-research/repos/not-so-smart/oracle_manipulation

cat > knowledge-base-research/repos/not-so-smart/oracle_manipulation/vulnerable_oracle.sol << 'EOF'
// Example of vulnerable oracle usage
contract VulnerableOracle {
    IUniswapV2Pair public pair;

    function getPrice() public view returns (uint256) {
        // VULNERABLE: Uses spot price without TWAP
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return (reserve1 * 1e18) / reserve0;
    }
}
EOF

# Rebuild
./scripts/cocoindex/rebuild_graph.sh
```

**What happens automatically:**
- ✅ New vulnerable contract node created
- ✅ `DEMONSTRATES` relationship to "Price Oracle Manipulation" vulnerability
- ✅ Used as negative example in educational queries

### 5. Adding Multi-File Analysis

For complex protocols with multiple files:

```bash
# Add complete protocol analysis
mkdir -p knowledge-base-research/repos/aave-v3

# Add multiple deep dives
cat > knowledge-base-research/repos/aave-v3/01-pool-architecture.md
cat > knowledge-base-research/repos/aave-v3/02-liquidation-engine.md
cat > knowledge-base-research/repos/aave-v3/03-flashloan-implementation.md

# Add integration guides
cat > knowledge-base-research/repos/aave-v3/10-aave-integration.md
cat > knowledge-base-research/repos/aave-v3/11-flashloan-integration.md

# Rebuild (all files indexed at once)
./scripts/cocoindex/rebuild_graph.sh
```

## 🎯 File Naming Conventions

### Deep Dive Files
```
01-[protocol]-deep-dive.md
08-[protocol]-v2-deep-dive.md
11-[specific-feature]-deep-dive.md
```

### Integration Files
```
02-[protocol]-integration.md
10-[protocol]-integration.md
```

### Templates
```
[type]-template.sol
secure-[standard].sol
[pattern]-template.sol
```

### Vulnerabilities
```
[vulnerability-name].md
[attack-type].md
```

## 🤖 Automatic Relationship Detection

The system automatically detects:

### 1. DEMONSTRATES
- **Pattern**: Filename contains vulnerability name
- **Example**: `reentrancy_attack.sol` → DEMONSTRATES → Reentrancy

### 2. PAIRS_WITH
- **Pattern**: Matching protocol names between DeepDive and Integration
- **Example**: `uniswap-v3-deep-dive.md` ↔ `uniswap-v3-integration.md`

### 3. PREVENTS
- **Pattern**: Template imports prevention libraries
- **Example**: Template imports `ReentrancyGuard` → PREVENTS → Reentrancy

### 4. EXPLAINS
- **Pattern**: DeepDive mentions vulnerability 2+ times
- **Example**: Deep dive discussing MEV → EXPLAINS → Frontrunning

### 5. USES
- **Pattern**: Integration mentions template type
- **Example**: Integration mentions ERC20 → USES → secure-erc20.sol

### 6. RELATES_TO
- **Pattern**: Shared domain keywords
- **Example**: NFT DeepDive → RELATES_TO → secure-erc721.sol

## 📊 Verification After Adding Content

```bash
# Check new nodes
python3 scripts/cocoindex/query_kb.py stats

# Search for your new content
python3 scripts/cocoindex/query_kb.py search "your new protocol"

# View on web interface
./start-web.sh
# Visit: http://localhost:5000/graph
# Search for your new nodes
```

## 🔄 Update Workflow

### When Adding Multiple Repos

```bash
# 1. Add all new content first
cp -r /path/to/repo1 knowledge-base-research/repos/
cp -r /path/to/repo2 knowledge-base-research/repos/
cp -r /path/to/repo3 knowledge-base-research/repos/

# 2. Single rebuild (more efficient)
./scripts/cocoindex/rebuild_graph.sh

# 3. Verify
python3 scripts/cocoindex/query_kb.py stats
```

### Incremental Updates

```bash
# Quick mode (skip metadata extraction if minimal changes)
./scripts/cocoindex/rebuild_graph.sh --quick
```

## 🎨 Customizing Relationship Detection

To add custom relationship patterns, edit:
```
scripts/cocoindex/auto_enhance.py
```

Example - Adding new vulnerability detection:

```python
# In auto_enhance.py, update vulnerability_keywords dict:
self.vulnerability_keywords = {
    'reentrancy': ['reentrancy', 'reentrant', 'call.value'],
    'your_new_vuln': ['keyword1', 'keyword2', 'pattern'],  # Add this
    # ...
}
```

Then rebuild:
```bash
python3 scripts/cocoindex/auto_enhance.py
```

## 📁 Recommended Directory Structure for New Repos

```
knowledge-base-research/repos/[protocol-name]/
├── 01-[protocol]-architecture-deep-dive.md
├── 02-[protocol]-security-analysis.md
├── 03-[protocol]-economic-model.md
├── 10-[protocol]-integration.md
├── 11-[protocol]-advanced-integration.md
└── contracts/
    ├── example1.sol
    └── example2.sol
```

## ✅ Best Practices

1. **Use descriptive file names** - Helps automatic relationship detection
2. **Include keywords** - Mention vulnerabilities, patterns, protocols explicitly
3. **Follow conventions** - Use established naming patterns
4. **Add both theory and practice** - DeepDive + Integration guides
5. **Document vulnerabilities** - Show both vulnerable and secure examples
6. **Tag domains** - Use keywords like "DeFi", "NFT", "Gaming" in content
7. **Test after adding** - Always verify new nodes appear in graph

## 🚨 Troubleshooting

### New content not appearing?

```bash
# 1. Check files exist
ls -la knowledge-base-*/
find knowledge-base-* -name "*.md" -o -name "*.sol" | wc -l

# 2. Force full rebuild
rm .cocoindex/knowledge_graph.db
./scripts/cocoindex/rebuild_graph.sh

# 3. Check logs for errors
```

### Relationships not detected?

```bash
# 1. Check file content contains relevant keywords
grep -i "reentrancy" knowledge-base-*/path/to/file.md

# 2. Run auto-enhance separately
python3 scripts/cocoindex/auto_enhance.py

# 3. Check relationship patterns in auto_enhance.py
```

### Graph seems incomplete?

```bash
# View detailed statistics
python3 << 'EOF'
import sys
sys.path.insert(0, 'scripts/cocoindex')
from knowledge_graph import KnowledgeGraph

kg = KnowledgeGraph()
stats = kg.get_statistics()
print(f"Nodes: {stats['total_nodes']}")
print(f"Edges: {stats['total_edges']}")
print(f"By type: {stats['nodes_by_type']}")
kg.close()
EOF
```

## 🎯 Examples by Use Case

### Adding a New Blockchain (e.g., Arbitrum)
```bash
mkdir -p knowledge-base-research/repos/arbitrum
# Add L2-specific security patterns
# System will auto-detect domain: L2/Scaling
```

### Adding a New Attack Vector
```bash
# Add to action KB
vim knowledge-base-action/03-attack-prevention/new-attack.md
# Auto-detected as Vulnerability node
# Auto-linked to templates that prevent it
```

### Adding a New DeFi Primitive
```bash
mkdir -p knowledge-base-research/repos/new-primitive
# Add deep dive + integration
# Auto-linked to ERC20 templates
# Auto-tagged as DeFi domain
```

### Adding Gaming Patterns
```bash
mkdir -p knowledge-base-action/04-gaming-patterns
# Add game-specific security patterns
# Auto-linked to VRF integrations
# Auto-tagged as Gaming domain
```

## 🌟 Pro Tips

1. **Batch additions** - Add multiple files, rebuild once
2. **Use metadata** - Rich file headers help relationship detection
3. **Cross-reference** - Mention related protocols/vulnerabilities in content
4. **Version tracking** - Use numbered versions (v1, v2, v3)
5. **Keep backups** - Rebuild script auto-backs up database
6. **Monitor stats** - Check node/edge counts after updates
7. **Query early** - Test search before committing large additions

## 📝 Change Log Template

After adding content, document what you added:

```markdown
## [Date] - New Content Added

### Added
- 3 new protocols: Compound, Aave V3, MakerDAO
- 2 new vulnerabilities: Oracle Manipulation, Governor Bravo Attacks
- 5 new templates: Lending, Governance, Staking V2

### Graph Updates
- Nodes: 45 → 63 (+18)
- Edges: 78 → 142 (+64)
- Connectivity: 97.8% → 98.4%

### Domains Expanded
- DeFi: 15 → 25 nodes
- Governance: 0 → 8 nodes (new domain!)
```

---

**Remember**: The system is designed to be smart! Just add your content following reasonable conventions, run the rebuild script, and the knowledge graph will adapt automatically. 🚀
