# Upgradeable Knowledge Graph System

Your knowledge graph system is now **fully upgradeable** and designed to grow with your knowledge bases!

## 🎯 Overview

The system automatically adapts when you add new:
- ✅ Protocol analyses (DeepDives)
- ✅ Integration guides
- ✅ Vulnerability patterns
- ✅ Contract templates
- ✅ Vulnerable contract examples
- ✅ Any markdown or Solidity files to either KB

## 🚀 Quick Usage

### Adding New Content (Automatic)

```bash
# 1. Add your new files to either knowledge base
cp -r /path/to/new-protocol knowledge-base-research/repos/
cp new-template.sol knowledge-base-action/02-contract-templates/

# 2. Run auto-rebuild (one command!)
./scripts/cocoindex/rebuild_graph.sh

# 3. Done! New content is indexed and relationships auto-detected
```

### Watching for Changes (Continuous)

```bash
# Start the watch daemon
./scripts/cocoindex/watch_kb.sh

# Now any file changes will trigger auto-rebuild
# Press Ctrl+C to stop
```

## 📁 New Tools & Scripts

### 1. Auto-Rebuild Script
**Location**: `scripts/cocoindex/rebuild_graph.sh`

**What it does**:
- Counts files in both knowledge bases
- Extracts metadata from all content
- Backs up existing database (keeps last 5)
- Builds new knowledge graph
- Auto-detects and adds relationships
- Updates version number
- Shows before/after statistics

**Usage**:
```bash
# Full rebuild
./scripts/cocoindex/rebuild_graph.sh

# Quick rebuild (skip metadata if unchanged)
./scripts/cocoindex/rebuild_graph.sh --quick
```

**Safety Features**:
- ✅ Automatic database backup before rebuild
- ✅ Rollback if build fails
- ✅ Keeps last 5 backups
- ✅ Shows detailed logs

---

### 2. Auto-Enhancement Script
**Location**: `scripts/cocoindex/auto_enhance.py`

**What it does**:
Automatically detects and creates relationships using:

**Pattern Detection**:
```
DEMONSTRATES:
  - Filename contains vulnerability name
  - Example: reentrancy_attack.sol → Reentrancy

PAIRS_WITH:
  - Matching protocol names
  - Example: uniswap-deep-dive.md ↔ uniswap-integration.md

PREVENTS:
  - Template imports prevention libraries
  - Example: imports ReentrancyGuard → PREVENTS → Reentrancy

EXPLAINS:
  - Content mentions vulnerability 2+ times
  - Example: DeepDive discusses MEV → EXPLAINS → Frontrunning

USES:
  - Integration mentions template type
  - Example: Integration uses ERC20 → USES → secure-erc20.sol

RELATES_TO:
  - Shared domain keywords
  - Example: NFT DeepDive → RELATES_TO → secure-erc721.sol
```

**Usage**:
```bash
# Run automatic enhancement
python3 scripts/cocoindex/auto_enhance.py
```

**Customizable**:
Edit the pattern libraries in the script to add your own detection rules!

---

### 3. Watch Script
**Location**: `scripts/cocoindex/watch_kb.sh`

**What it does**:
- Monitors both knowledge bases for changes
- Calculates MD5 checksum of all KB files
- Triggers auto-rebuild when changes detected
- Runs continuously in background

**Usage**:
```bash
# Watch mode (continuous)
./scripts/cocoindex/watch_kb.sh

# Check once and exit
./scripts/cocoindex/watch_kb.sh --once
```

**Perfect for**:
- Active development
- Continuous integration pipelines
- Batch importing multiple repos

---

## 🔢 Versioning System

The knowledge graph now tracks versions automatically!

### Version Format
```
major.minor.patch

Example: 1.2.3
```

### Automatic Version Bumping

**Patch**: Small changes (new files, minor edits)
```bash
# Auto-bumped by rebuild script
# 1.0.0 → 1.0.1
```

**Minor**: New features or significant additions
```python
kg = KnowledgeGraph()
kg.increment_version("minor")  # 1.0.0 → 1.1.0
```

**Major**: Breaking changes or major overhauls
```python
kg.increment_version("major")  # 1.0.0 → 2.0.0
```

### Checking Version

**CLI**:
```bash
python3 scripts/cocoindex/query_kb.py stats | grep version
```

**Web Interface**:
- Visit http://localhost:5000
- Version shown in statistics dashboard

**Programmatically**:
```python
from knowledge_graph import KnowledgeGraph

kg = KnowledgeGraph()
print(f"Current version: {kg.get_version()}")
kg.close()
```

---

## 📊 Metadata Tracking

The system tracks:

| Metadata Key | Description | Example |
|--------------|-------------|---------|
| `version` | Graph version | 1.0.0 |
| `kb_files_count` | Number of indexed files | 284 |
| `last_rebuild` | Last rebuild timestamp | 2025-01-15 10:30:00 |

### Setting Metadata

```python
kg = KnowledgeGraph()
kg.set_metadata_value("custom_key", "custom_value")
value = kg.get_metadata_value("custom_key")
kg.close()
```

---

## 🎨 Customization

### Adding Custom Relationship Types

Edit `scripts/cocoindex/auto_enhance.py`:

```python
# Add new vulnerability detection pattern
self.vulnerability_keywords = {
    'reentrancy': ['reentrancy', 'reentrant'],
    'your_new_vuln': ['keyword1', 'keyword2'],  # Add this!
}

# Add new prevention pattern
self.prevention_patterns = {
    'ReentrancyGuard': 'reentrancy',
    'YourNewGuard': 'your_new_vuln',  # Add this!
}
```

Then rebuild:
```bash
./scripts/cocoindex/rebuild_graph.sh
```

### Adding Custom Domains

```python
# In auto_enhance.py
domain_keywords = {
    'DeFi': ['defi', 'swap', 'amm'],
    'YourNewDomain': ['keyword1', 'keyword2'],  # Add this!
}
```

---

## 📚 Complete Workflow Examples

### Example 1: Adding Aave V3 Analysis

```bash
# 1. Create directory
mkdir -p knowledge-base-research/repos/aave-v3

# 2. Add deep dive
cat > knowledge-base-research/repos/aave-v3/01-aave-v3-architecture.md << 'EOF'
# Aave V3 Architecture Deep-Dive

## Overview
Aave V3 is a decentralized lending protocol...

## Key Features
- Portals for cross-chain liquidity
- Efficiency mode (E-Mode)
- Isolation mode
...
EOF

# 3. Add integration guide
cat > knowledge-base-research/repos/aave-v3/02-aave-integration.md << 'EOF'
# Aave V3 Integration Guide

## Setup
```solidity
import {IPool} from "@aave/v3/interfaces/IPool.sol";
...
```
EOF

# 4. Rebuild (automatic relationship detection!)
./scripts/cocoindex/rebuild_graph.sh

# ✅ Result:
# - 2 new nodes created (DeepDive, Integration)
# - PAIRS_WITH relationship auto-detected
# - DeFi domain auto-tagged
# - Available in web interface immediately
```

### Example 2: Adding New Vulnerability Pattern

```bash
# 1. Add vulnerability documentation
cat > knowledge-base-action/03-attack-prevention/sandwich-attacks.md << 'EOF'
# Sandwich Attacks

**Severity**: HIGH

## Description
Frontrunning + backrunning to profit from user transactions...

## Prevention
1. Use private mempools (Flashbots)
2. Slippage protection
3. MEV-resistant AMM designs
EOF

# 2. Add template that prevents it
cat > knowledge-base-action/02-contract-templates/mev-resistant-template.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MEVResistantSwap {
    // Anti-frontrunning mechanisms
    uint256 public constant MAX_SLIPPAGE = 100; // 1%

    function swap(
        uint256 amountIn,
        uint256 minAmountOut
    ) external {
        // Slippage protection
        require(amountOut >= minAmountOut, "Slippage exceeded");
        ...
    }
}
EOF

# 3. Rebuild
./scripts/cocoindex/rebuild_graph.sh

# ✅ Result:
# - New Vulnerability node: Sandwich Attacks
# - New Template node: MEV Resistant Template
# - PREVENTS relationship auto-detected
# - Mentioned in DeepDives that discuss MEV (auto-linked)
# - Usable in contract generator immediately
```

### Example 3: Batch Import Multiple Protocols

```bash
# 1. Add multiple protocols at once
cp -r /research/compound knowledge-base-research/repos/
cp -r /research/morpho knowledge-base-research/repos/
cp -r /research/euler knowledge-base-research/repos/
cp -r /research/radiant knowledge-base-research/repos/

# 2. Single rebuild (more efficient than 4 rebuilds)
./scripts/cocoindex/rebuild_graph.sh

# ✅ Result:
# - All protocols indexed together
# - Relationships between similar protocols detected
# - Version bumped once
# - Single backup created
```

### Example 4: Continuous Development

```bash
# Terminal 1: Start watch daemon
./scripts/cocoindex/watch_kb.sh

# Terminal 2: Start web interface
./start-web.sh

# Terminal 3: Add content as you work
vim knowledge-base-research/repos/new-protocol/analysis.md
# Save file
# Watch daemon auto-detects change
# Graph auto-rebuilds
# Refresh browser to see new content

# No manual intervention needed! 🎉
```

---

## 🔍 Verification & Debugging

### Check Current State

```bash
# View all statistics
python3 scripts/cocoindex/query_kb.py stats

# Search for specific content
python3 scripts/cocoindex/query_kb.py search "your protocol"

# Count files
find knowledge-base-* -type f \( -name "*.md" -o -name "*.sol" \) | wc -l
```

### Verify Relationships

```bash
# Check specific node
python3 << 'EOF'
from knowledge_graph import KnowledgeGraph

kg = KnowledgeGraph()

# Get relationships for a node
cursor = kg.conn.execute("""
    SELECT e.relationship_type, COUNT(*) as count
    FROM edges e
    WHERE e.source_id = 'your_node_id'
    GROUP BY e.relationship_type
""")

for row in cursor.fetchall():
    print(f"{row['relationship_type']}: {row['count']}")

kg.close()
EOF
```

### Database Backups

```bash
# List backups
ls -lht .cocoindex/knowledge_graph.db.backup.*

# Restore specific backup
cp .cocoindex/knowledge_graph.db.backup.20250115_103000 .cocoindex/knowledge_graph.db

# Clean old backups (keep last 5)
ls -t .cocoindex/knowledge_graph.db.backup.* | tail -n +6 | xargs rm
```

---

## 📈 Performance

### Optimization Tips

**For Large Knowledge Bases (1000+ files)**:

1. **Use quick mode** when only adding a few files:
   ```bash
   ./scripts/cocoindex/rebuild_graph.sh --quick
   ```

2. **Batch additions** instead of rebuilding after each file:
   ```bash
   # Add all files first
   cp file1.md file2.md file3.md knowledge-base-research/repos/

   # Single rebuild
   ./scripts/cocoindex/rebuild_graph.sh
   ```

3. **Adjust watch frequency** if needed:
   ```bash
   # Edit watch_kb.sh
   # Change: sleep 30  → sleep 60 (check every minute instead)
   ```

### Expected Performance

| KB Size | Files | Build Time | Enhancement Time |
|---------|-------|------------|------------------|
| Small   | <100  | ~5 sec     | ~2 sec           |
| Medium  | 100-500 | ~15 sec  | ~5 sec           |
| Large   | 500-1000 | ~30 sec | ~10 sec          |
| Huge    | 1000+ | ~60 sec    | ~20 sec          |

---

## 🎓 Best Practices

### 1. File Organization
```
knowledge-base-research/repos/[protocol]/
├── 01-architecture-deep-dive.md      # Theory
├── 02-security-analysis.md            # Security
├── 10-integration-guide.md            # Practice
└── contracts/                          # Examples
    └── example.sol
```

### 2. Naming Conventions
- **DeepDives**: `[number]-[protocol]-deep-dive.md`
- **Integrations**: `[number]-[protocol]-integration.md`
- **Templates**: `[type]-template.sol` or `secure-[standard].sol`
- **Vulnerabilities**: `[vulnerability-name].md`

### 3. Content Quality
- **Use keywords** - Mention vulnerabilities, protocols explicitly
- **Cross-reference** - Link related topics
- **Document examples** - Include both vulnerable and secure code
- **Tag domains** - Use "DeFi", "NFT", "Gaming", "AI" in content

### 4. Rebuild Frequency
- **After major additions**: Full rebuild
- **During development**: Watch mode
- **CI/CD pipelines**: Auto-rebuild on commit
- **Production**: Version-controlled rebuilds

---

## 🔄 Integration with CI/CD

### GitHub Actions Example

```yaml
name: Rebuild Knowledge Graph

on:
  push:
    paths:
      - 'knowledge-base-action/**'
      - 'knowledge-base-research/**'

jobs:
  rebuild-graph:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Rebuild knowledge graph
        run: ./scripts/cocoindex/rebuild_graph.sh

      - name: Commit updated database
        run: |
          git config user.name "KB Bot"
          git config user.email "bot@example.com"
          git add .cocoindex/knowledge_graph.db
          git commit -m "Auto-rebuild knowledge graph" || true
          git push
```

---

## 🆘 Troubleshooting

### Issue: New content not appearing

```bash
# 1. Check files exist
ls -la knowledge-base-*/path/to/new/content

# 2. Force full rebuild
rm .cocoindex/knowledge_graph.db
./scripts/cocoindex/rebuild_graph.sh

# 3. Check for errors in output
```

### Issue: Relationships not auto-detected

```bash
# 1. Verify file contains keywords
grep -i "keyword" knowledge-base-*/path/to/file.md

# 2. Check detection patterns
cat scripts/cocoindex/auto_enhance.py | grep -A5 "vulnerability_keywords"

# 3. Run enhancement manually with verbose output
python3 scripts/cocoindex/auto_enhance.py
```

### Issue: Watch script not triggering

```bash
# 1. Check checksum file
cat .cocoindex/kb_checksums.txt

# 2. Manually trigger check
./scripts/cocoindex/watch_kb.sh --once

# 3. Check file permissions
ls -l scripts/cocoindex/watch_kb.sh
chmod +x scripts/cocoindex/watch_kb.sh
```

---

## 📝 Change Log Format

Document your knowledge base updates:

```markdown
## 2025-01-15 - Added Lending Protocols

### Added
- Aave V3 architecture analysis
- Compound V3 deep dive
- Morpho integration guide
- 3 new vulnerability patterns

### Graph Updates
- Nodes: 45 → 58 (+13)
- Edges: 78 → 112 (+34)
- Version: 1.0.0 → 1.1.0

### Relationships Auto-Detected
- 3 PAIRS_WITH (DeepDive ↔ Integration)
- 8 EXPLAINS (DeepDive → Vulnerability)
- 5 USES (Integration → Template)
```

---

## 🎉 Summary

Your knowledge graph is now **production-ready** and **self-upgrading**!

**Key Features**:
- ✅ Automatic rebuild on content changes
- ✅ Intelligent relationship detection
- ✅ Version tracking
- ✅ Database backups
- ✅ Watch daemon for continuous updates
- ✅ Web interface with version display
- ✅ Customizable pattern detection
- ✅ CI/CD friendly

**Just add content and rebuild - the system handles the rest!** 🚀
