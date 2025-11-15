# Safe Smart Contract Knowledge Base - Search Guide

> Everything you need to know about searching 238+ files in the Safe Smart Contract Knowledge Base efficiently

**Quick Answer**: Use `./search.sh` to search, or refer to `INDEX.md` for manual navigation.

---

## 🚀 Quick Start (TL;DR)

### Search from command line:
```bash
# Search by keyword
./search.sh "reentrancy"

# Search vulnerabilities
./search.sh --vulnerabilities

# List templates
./search.sh --templates

# Search in specific section
./search.sh "ERC20" --section templates

# Get stats
./search.sh --stats
```

### Manual navigation:
1. Open `INDEX.md` in your editor (Ctrl+F or Cmd+F to search)
2. Find "Quick Find by Problem" section
3. Go to the recommended file location

---

## 📋 Three Ways to Search

### **Method 1: Interactive CLI Search (Recommended)**

The `search.sh` script is the easiest way to search the knowledge base.

#### Basic Usage
```bash
./search.sh "your search term"
```

**Examples:**
```bash
# Find all mentions of reentrancy
./search.sh "reentrancy"

# Search for ERC20 with case-sensitive matching
./search.sh "ERC20" --case-sensitive

# Search only in templates
./search.sh "token" --section templates

# Count matches
./search.sh "gas" --count

# Show only matching filenames
./search.sh "modifier" --files-only
```

#### Search by Section
```bash
# Sections available:
#   quick-ref            Quick reference guides
#   templates            Contract templates
#   attack-prevention    Vulnerability guides
#   code-snippets        Code snippets
#   workflows            Development workflows
#   research             Research KB
#   all                  All sections

./search.sh "pattern" --section quick-ref
./search.sh "loop" --section attack-prevention
./search.sh "ERC" --section templates
```

#### List Content
```bash
# List all contract templates
./search.sh --templates

# List all 10 vulnerabilities
./search.sh --vulnerabilities

# List all 10 design patterns
./search.sh --patterns

# List quick references
./search.sh --quick-ref

# List code snippets
./search.sh --snippets

# Show statistics
./search.sh --stats
```

#### Advanced Options
```bash
# Case-sensitive search (default is insensitive)
./search.sh "AccessControl" --case-sensitive

# Show only count of matches
./search.sh "Ownable" --count

# Show only matching filenames
./search.sh "transfer" --files-only

# Search in specific file format
./search.sh "pragma" --format solidity
./search.sh "vulnerability" --format markdown
```

---

### **Method 2: Manual Index Navigation**

Open `INDEX.md` for a complete table of contents with descriptions.

#### Best for:
- Getting an overview of what exists
- Finding by category
- Understanding file organization
- Printing/saving a reference

#### How to use:
1. Open `INDEX.md` in any text editor
2. Use Ctrl+F (or Cmd+F on Mac) to search
3. Sections to browse:
   - **Quick Navigation by Role** - Start here
   - **Complete Contents by Section** - Full file listing
   - **Quick Find by Problem** - Problem-based lookup
   - **Search by Solidity Concept** - Concept lookup
   - **Search by Vulnerability** - 10 vulnerabilities listed

#### Example searches in INDEX.md:
```
Ctrl+F: "ERC20"              → Find ERC20 references
Ctrl+F: "reentrancy"         → Find reentrancy resources
Ctrl+F: "gas optimization"   → Find gas optimization content
Ctrl+F: "pre-deployment"     → Find deployment checklist
Ctrl+F: "design pattern"     → Find pattern resources
```

---

### **Method 3: Programmatic JSON Search**

For developers building tools, IDE plugins, or web interfaces.

Open `SEARCHINDEX.json` - a machine-readable index with:
- File metadata
- Keywords and descriptions
- File sizes and line counts
- Content mappings
- Task-to-file mappings
- Statistics

#### Use Cases:
- Building web-based knowledge base browser
- IDE plugin integration
- Automated documentation generation
- Knowledge base tools/scripts
- Content analysis

#### Example JSON queries:
```json
// Get all templates
searchIndex.sections.templates.files

// Get all vulnerabilities
searchIndex.sections.attack_prevention.files

// Get mappings by task
searchIndex.search_guide.by_task

// Get file metadata
searchIndex.sections.quick_reference.files[0]
```

---

## 🎯 Search by Problem

### "I need to build..."

| What | Where | How |
|------|-------|-----|
| **ERC20 Token** | `secure-erc20.sol` | `./search.sh --templates` |
| **NFT / ERC721** | `secure-erc721.sol` | `./search.sh --templates` |
| **Multi-sig Wallet** | `multisig-template.sol` | `./search.sh "multisig"` |
| **Staking Contract** | `staking-template.sol` | `./search.sh "staking"` |
| **Access Control** | `access-control-template.sol` | `./search.sh "rbac"` |
| **Upgradeable** | `upgradeable-template.sol` | `./search.sh "upgradeable"` |
| **Emergency Stop** | `pausable-template.sol` | `./search.sh "pausable"` |

### "I need to prevent..."

| Vulnerability | File | Command |
|---|---|---|
| **Reentrancy** | `reentrancy.md` | `./search.sh --vulnerabilities` |
| **Access Control Bug** | `access-control.md` | `./search.sh "access control"` |
| **Integer Overflow** | `integer-overflow.md` | `./search.sh "overflow"` |
| **Frontrunning** | `frontrunning.md` | `./search.sh "mempool"` |
| **DoS Attack** | `dos-attacks.md` | `./search.sh "unbounded loop"` |
| **Weak Randomness** | `timestamp-dependence.md` | `./search.sh "randomness"` |
| **Unsafe Delegatecall** | `unsafe-delegatecall.md` | `./search.sh "delegatecall"` |
| **Unchecked Returns** | `unchecked-returns.md` | `./search.sh "silent failure"` |
| **tx.origin Bug** | `tx-origin.md` | `./search.sh "tx.origin"` |
| **Flash Loan Exploit** | `flash-loan-attacks.md` | `./search.sh "flash loan"` |

### "I need code for..."

| Code Type | Section | Command |
|---|---|---|
| **Modifiers** | `04-code-snippets/modifiers.md` | `./search.sh "modifier"` |
| **Events** | `04-code-snippets/events.md` | `./search.sh "event"` |
| **Custom Errors** | `04-code-snippets/errors.md` | `./search.sh "custom error"` |
| **Library Functions** | `04-code-snippets/libraries.md` | `./search.sh "utility"` |
| **Imports** | `04-code-snippets/oz-imports.md` | `./search.sh "import"` |

### "I need to..."

| Task | Recommended File | Command |
|---|---|---|
| **Check before deployment** | `security-checklist.md` | `./search.sh "pre-deployment"` |
| **Optimize gas** | `gas-optimization-wins.md` | `./search.sh "gas" --count` |
| **Choose a pattern** | `pattern-catalog.md` | `./search.sh --patterns` |
| **Understand OpenZeppelin** | `oz-quick-ref.md` | `./search.sh "openzeppelin"` |
| **Learn vulnerabilities** | `03-attack-prevention/` | `./search.sh --vulnerabilities` |
| **Start a project** | `contract-development.md` | `./search.sh "development"` |

---

## 🔍 Search Examples

### Example 1: "How do I prevent reentrancy attacks?"

**Using CLI search:**
```bash
./search.sh "reentrancy"
# Output shows 465+ matches with file locations
```

**Using INDEX.md:**
1. Open INDEX.md
2. Ctrl+F search "reentrancy"
3. Find: `03-attack-prevention/reentrancy.md`
4. Open that file

**Result:** Both methods point you to `knowledge-base-action/03-attack-prevention/reentrancy.md`

---

### Example 2: "I need to build an ERC20 token"

**Using CLI search:**
```bash
./search.sh --templates
# Shows all 8 templates
# Pick: secure-erc20.sol
```

**Using INDEX.md:**
1. Open INDEX.md
2. Find section "02-CONTRACT-TEMPLATES"
3. Look for "secure-erc20.sol"
4. Copy the contract

**Result:** `knowledge-base-action/02-contract-templates/secure-erc20.sol`

---

### Example 3: "What gas optimization should I use?"

**Using CLI search:**
```bash
./search.sh "unchecked" --section quick-ref
# Find gas optimization tips
```

**Using INDEX.md:**
1. Ctrl+F search "gas-optimization-wins.md"
2. Open that file
3. Find technique ranked by impact

**Result:** See 21 techniques ranked by gas savings

---

### Example 4: "I need a modifier for access control"

**Using CLI search:**
```bash
./search.sh "onlyOwner" --section code-snippets
# Shows modifier examples
```

**Using INDEX.md:**
1. Find section "04-CODE-SNIPPETS"
2. Look for "modifiers.md"
3. Copy-paste the modifier you need

**Result:** 24 reusable modifiers available

---

## 📊 Search Command Reference

### Display Options
```bash
./search.sh "keyword"                    # Show matches with context
./search.sh "keyword" --count            # Show only match count
./search.sh "keyword" --files-only       # Show only filenames
./search.sh "keyword" --case-sensitive   # Case-sensitive search
```

### Section Filters
```bash
./search.sh "term" --section quick-ref
./search.sh "term" --section templates
./search.sh "term" --section attack-prevention
./search.sh "term" --section code-snippets
./search.sh "term" --section workflows
./search.sh "term" --section research
./search.sh "term" --section all
```

### Content Listings
```bash
./search.sh --templates              # All 8 contract templates
./search.sh --vulnerabilities        # All 10 vulnerabilities
./search.sh --patterns               # All 10 design patterns
./search.sh --quick-ref              # All 5 quick references
./search.sh --stats                  # Knowledge base statistics
./search.sh --help                   # Help and usage guide
```

### Format Filters
```bash
./search.sh "keyword" --format solidity   # Search only .sol files
./search.sh "keyword" --format markdown   # Search only .md files
./search.sh "keyword" --format json       # Search only .json files
```

---

## 🗺️ Directory Structure for Manual Navigation

```
knowledge-base-action/
├── 00-START-HERE.md              ← Start here for navigation
├── 01-quick-reference/           ← Fast lookup (5 min)
│   ├── vulnerability-matrix.md
│   ├── pattern-catalog.md
│   ├── gas-optimization-wins.md
│   ├── oz-quick-ref.md
│   └── security-checklist.md
│
├── 02-contract-templates/        ← Copy-paste ready (8 templates)
│   ├── secure-erc20.sol
│   ├── secure-erc721.sol
│   ├── access-control-template.sol
│   ├── upgradeable-template.sol
│   ├── staking-template.sol
│   ├── pausable-template.sol
│   ├── multisig-template.sol
│   └── README.md
│
├── 03-attack-prevention/         ← Vulnerability guides (10 files)
│   ├── reentrancy.md
│   ├── access-control.md
│   ├── integer-overflow.md
│   ├── frontrunning.md
│   ├── dos-attacks.md
│   ├── timestamp-dependence.md
│   ├── unsafe-delegatecall.md
│   ├── unchecked-returns.md
│   ├── tx-origin.md
│   └── flash-loan-attacks.md
│
├── 04-code-snippets/             ← Copy-paste code (172+ snippets)
│   ├── oz-imports.md
│   ├── modifiers.md
│   ├── events.md
│   ├── errors.md
│   └── libraries.md
│
└── 05-workflows/                 ← Step-by-step processes
    ├── contract-development.md
    └── pre-deployment.md

knowledge-base-research/          ← Deep research (200+ files)
└── repos/                         ← 8 source repositories
    ├── consensys/                ← Best practices (65 files)
    ├── vulnerabilities/          ← Vulnerabilities (42 files)
    ├── not-so-smart/             ← Real examples (45 files)
    ├── patterns/                 ← Design patterns (16 files)
    ├── gas-optimization/         ← Optimization (12 files)
    └── openzeppelin/             ← Reference (16 files)
```

---

## 💡 Search Tips & Tricks

### Tip 1: Start Broad, Then Narrow
```bash
# Too many results? Get a count first
./search.sh "erc" --count              # 2,000+ matches

# Narrow down by section
./search.sh "erc" --section templates  # 15 matches

# Search specific file
grep "erc" knowledge-base-action/02-contract-templates/secure-erc20.sol
```

### Tip 2: Use Case Sensitivity for Precise Matches
```bash
# Case-insensitive (default) - finds everything
./search.sh "event"                       # Finds "event", "Event", "EVENT"

# Case-sensitive - more precise
./search.sh "event" --case-sensitive      # Finds only "event"
./search.sh "Event" --case-sensitive      # Finds only "Event"
```

### Tip 3: Combine Multiple Approaches
```bash
# 1. Start with --stats to understand what exists
./search.sh --stats

# 2. List relevant content type
./search.sh --vulnerabilities

# 3. Search specifically
./search.sh "reentrancy" --count

# 4. View results
./search.sh "reentrancy"
```

### Tip 4: Use Grep for Power Users
```bash
# Search with grep for maximum control
grep -r "reentrancy" knowledge-base-action/

# Case-insensitive with grep
grep -ri "erc20" knowledge-base-action/

# Count matches
grep -r "gas" knowledge-base-action/ | wc -l

# Show filenames only
grep -rl "security" knowledge-base-action/
```

---

## 🎓 Learning Paths

### Path 1: "I'm a beginner, where do I start?"
1. Read: `00-START-HERE.md`
2. Read: `01-quick-reference/pattern-catalog.md` (understand patterns)
3. Read: `03-attack-prevention/reentrancy.md` (learn one attack)
4. Copy: `02-contract-templates/secure-erc20.sol` (see working code)
5. Study: `04-code-snippets/` (learn snippets)

**Search commands:**
```bash
./search.sh --patterns          # Learn patterns
./search.sh --vulnerabilities   # Learn attacks
./search.sh --templates         # See templates
./search.sh "best practice"     # Find guidance
```

---

### Path 2: "I need to audit a contract"
1. Use: `01-quick-reference/security-checklist.md`
2. Read: `03-attack-prevention/` (all 10 files)
3. Use: `05-workflows/pre-deployment.md`
4. Reference: `01-quick-reference/vulnerability-matrix.md`

**Search commands:**
```bash
./search.sh --vulnerabilities        # All attacks
./search.sh --stats                  # Know what exists
./search.sh "pre-deployment" --count # Check list size
grep -r "vulnerability" INDEX.md     # Find in index
```

---

### Path 3: "I need to build a contract"
1. Choose template: `02-contract-templates/`
2. Find snippets: `04-code-snippets/`
3. Reference: `01-quick-reference/oz-quick-ref.md`
4. Check security: `03-attack-prevention/`
5. Deploy: `05-workflows/pre-deployment.md`

**Search commands:**
```bash
./search.sh --templates              # Find template
./search.sh "modifier"               # Find modifier code
./search.sh "event"                  # Find event code
./search.sh --vulnerabilities        # Check for issues
```

---

## ❓ FAQs

### Q: "I can't find what I'm looking for"
**A:** Try these approaches in order:
1. Use `./search.sh --help`
2. Use `./search.sh --stats` to see what exists
3. Search INDEX.md with Ctrl+F
4. Try broader search terms
5. Search by section instead of keyword

### Q: "How many vulnerabilities are covered?"
**A:** Use search:
```bash
./search.sh --vulnerabilities          # Shows all 10
./search.sh --stats                    # Shows count: 10
```

### Q: "Can I search from my editor?"
**A:** Yes! Most editors have built-in search:
- VS Code: Ctrl+Shift+F (search all files)
- Sublime: Ctrl+Shift+F (project search)
- Most editors: Use project-wide find

### Q: "Can I integrate this with my IDE?"
**A:** Yes! Use `SEARCHINDEX.json` to build:
- IDE plugins
- Web-based viewer
- CLI tools
- Automated documentation

### Q: "I want to search programmatically"
**A:** Use `SEARCHINDEX.json`:
```python
import json
with open('SEARCHINDEX.json') as f:
    index = json.load(f)
    # Now you can query the index programmatically
```

---

## 📞 Getting Help

### Search isn't working?
```bash
# Verify search script is executable
ls -la search.sh     # Should show -rwxr-xr-x

# Test with basic search
./search.sh "the"    # Should find 1000+ matches

# Check help
./search.sh --help
```

### Can't find a file?
1. Check: `./search.sh --stats` (verify file count)
2. Search: `./search.sh "filename"`
3. Browse: Open `INDEX.md` and Ctrl+F search
4. Look in: `knowledge-base-research/00-RESEARCH-INDEX.md`

### Need more help?
- See: `knowledge-base-action/00-START-HERE.md`
- Check: `README.md` for project overview
- View: `INDEX.md` for complete file listing

---

## 🔄 Keeping Search Updated

The knowledge base updates monthly:

```bash
# Update the knowledge base (monthly)
./.knowledge-base-sync/update-action-kb.sh

# Review quarterly
./.knowledge-base-sync/quarterly-review.sh

# Search indices update automatically
# INDEX.md, search.sh, and SEARCHINDEX.json stay current
```

---

**Last Updated**: November 15, 2025
**Search Tools**: 3 (CLI, Index, JSON)
**Total Searchable Files**: 238
**Status**: Ready to use ✅

Happy searching! 🚀
