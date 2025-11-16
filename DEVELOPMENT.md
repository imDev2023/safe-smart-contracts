# Development Workflow Guide

> How to access the knowledge base while developing contracts

## Quick Access Patterns

### Pattern 1: Direct Search by Problem
```bash
# When developing Uniswap integration:
./search.sh "slippage"           # Get protection patterns
./search.sh "uniswap v3 tick"    # Get V3-specific details

# When adding Chainlink:
./search.sh "oracle"             # Get all oracle guides
./search.sh "chainlink vrf"      # Get VRF setup
```

### Pattern 2: Start with Integration Guide
When building **new feature**:

```
Feature: Uniswap V3 swap
  ↓
Check: kba/06-defi-trading/14-uniswap-v3-integration.md
  ↓
Find: Code template + step-by-step (5 min read)
  ↓
For deep understanding: kbr/repos/uniswap/09-uniswap-v3-deep-dive.md (30 min read)
```

When building **security-critical**:

```
Feature: Oracle price feed
  ↓
Check: kba/06-defi-trading/11-oracle-security-checklist.md (3 min)
  ↓
Review: All 28 items before deploying
  ↓
For full context: kbr/repos/chainlink/11-chainlink-oracle-deep-dive.md
```

---

## KB Navigation During Development

### Step 1: Identify What You're Building
| Building | Quick Start | Security | Deep Dive |
|----------|------------|----------|-----------|
| Uniswap swap | `13-uniswap-v2-integration.md` | `12-dex-checklist.md` | `08-v2-deep-dive.md` |
| Uniswap LP | `14-uniswap-v3-integration.md` | `12-dex-checklist.md` | `09-v3-deep-dive.md` |
| Uniswap hooks | `15-uniswap-v4-integration.md` | `12-dex-checklist.md` | `10-v4-deep-dive.md` |
| Price oracle | `08-chainlink-datafeed-integration.md` | `11-oracle-checklist.md` | `11-chainlink-deep-dive.md` |
| VRF | `09-chainlink-vrf-integration.md` | `11-oracle-checklist.md` | `11-chainlink-deep-dive.md` |
| Automation | `10-chainlink-automation-integration.md` | `11-oracle-checklist.md` | `11-chainlink-deep-dive.md` |
| Slippage | `02-slippage-protection.md` | `12-dex-checklist.md` | `02-slippage-protection.md` |

### Step 2: Reference Code Patterns
All integration guides have:
1. **Quick 3-4 step integration** (copy-paste ready)
2. **Complete working example** (full contract code)
3. **Best practices** (✅ DO, ❌ DON'T)
4. **Common issues** (troubleshooting table)
5. **Testing examples**

### Step 3: Security Review
Before deploying ANY DEX/Oracle integration:
1. Run through `11-oracle-security-checklist.md` (10 items)
2. Run through `12-dex-security-checklist.md` (51 items)
3. Review "Best Practices" section in relevant integration guide

### Step 4: Deep Learning (if needed)
For understanding **WHY** something works:
- `kbr/repos/uniswap/` - Architecture deep dives
- `kbr/repos/chainlink/` - Oracle network deep dives

---

## Fast Reference by Task

### "I need to integrate Uniswap"
```
Task: Add Uniswap V3 swaps to protocol

1. READ: kba/06-defi-trading/14-uniswap-v3-integration.md (5 min)
   → Get ISwapRouter interface
   → Get complete working example
   → See best practices

2. SECURITY: kba/06-defi-trading/12-dex-security-checklist.md
   → Check pre-integration items (8 items)
   → Check slippage protection (8 items)
   → Check V3 specific (7 items)

3. DEEP DIVE (if stuck): kbr/repos/uniswap/09-uniswap-v3-deep-dive.md
   → Understand tick math
   → Learn fee growth calculation
   → Study oracle cardinality

4. WRITE CODE: Copy example, adjust for your needs
```

### "I need to add Chainlink price feed"
```
Task: Add ETH/USD price feed to liquidation logic

1. READ: kba/06-defi-trading/08-chainlink-datafeed-integration.md (5 min)
   → Get AggregatorV3Interface
   → Get complete working example
   → See feed addresses for your chain

2. SECURITY: kba/06-defi-trading/11-oracle-security-checklist.md
   → Staleness check (1 item)
   → Decimal handling (1 item)
   → Multi-oracle consensus (1 item)
   → 10 total items

3. WRITE CODE: Copy example, connect to liquidation logic
```

### "I need to protect against MEV/slippage"
```
Task: Add MEV protection to swap

1. SELECT STRATEGY: kba/06-defi-trading/00-oracle-selection.md
   → Private mempool? → Flashbots Protect
   → Batch auction? → CoW Protocol
   → Intent-based? → UniswapX

2. READ: kba/06-defi-trading/02-slippage-protection.md (5 min)
   → Get amountOutMin calculation
   → Get deadline enforcement
   → See dynamic slippage patterns

3. IF MEV-FOCUSED: kba/06-defi-trading/05-mev-mitigation.md
   → Review all MEV categories
   → Pick mitigation strategy
   → See comparison table

4. WRITE CODE: Apply pattern to your swap
```

---

## File Quick Access

### Instant Copy-Paste Code

**Uniswap V2 swap:**
```
File: kba/06-defi-trading/13-uniswap-v2-integration.md
Section: "Complete Working Example"
Lines: Full contract ready to use
```

**Uniswap V3 swap:**
```
File: kba/06-defi-trading/14-uniswap-v3-integration.md
Section: "Complete Working Example"
Lines: V3SwapAndLP contract with multiple methods
```

**Uniswap V4 swap:**
```
File: kba/06-defi-trading/15-uniswap-v4-integration.md
Section: "Complete Working Example"
Lines: V4Router contract with hook support
```

**Chainlink price feed:**
```
File: kba/06-defi-trading/08-chainlink-datafeed-integration.md
Section: "Complete Working Example"
Lines: StableSwap contract using dual feeds
```

**Chainlink VRF:**
```
File: kba/06-defi-trading/09-chainlink-vrf-integration.md
Section: "Complete Working Example"
Lines: SimpleRaffle contract with fulfillment
```

**Chainlink Automation:**
```
File: kba/06-defi-trading/10-chainlink-automation-integration.md
Section: "Complete Working Example"
Lines: LiquidationBot with keeper integration
```

---

## How Claude Code Will Access KB During Development

### Scenario 1: User Describes Feature
```
User: "Add Uniswap V3 concentrated liquidity to our AMM"

Claude Code:
  1. Reads: kba/06-defi-trading/14-uniswap-v3-integration.md
  2. Extracts: ISwapRouter interface + complete example
  3. Searches: kbr/repos/uniswap/09-v3-deep-dive.md for tick math details
  4. Writes: Integration code based on pattern
  5. References: "See line 45-67 of integration guide for fee collection"
```

### Scenario 2: User Asks "Is This Secure?"
```
User: "Is my oracle integration safe?"

Claude Code:
  1. Reads: kba/06-defi-trading/11-oracle-security-checklist.md
  2. Reviews: Your code against all 28 items
  3. Reports: "Missing staleness check (item 1). See guide line XX."
  4. Suggests: Copy pattern from 08-chainlink-datafeed-integration.md
```

### Scenario 3: User Needs Slippage Protection
```
User: "How do we protect this swap from sandwich attacks?"

Claude Code:
  1. Reads: kba/06-defi-trading/02-slippage-protection.md
  2. Reads: kba/06-defi-trading/05-mev-mitigation.md
  3. Shows: Decision matrix (3 options)
  4. Recommends: Best fit based on your constraints
  5. Provides: Code pattern ready to integrate
```

### Scenario 4: Code is Failing
```
User: "Swap keeps reverting, what's wrong?"

Claude Code:
  1. Reads: kba/06-defi-trading/13-uniswap-v2-integration.md
  2. Section: "Common Issues & Solutions"
  3. Finds: Matching error
  4. Explains: Root cause + fix
  5. Shows: Working pattern from guide
```

---

## Pro Tips for Fast Development

### Tip 1: Always Start with Integration Guide
**Why:** 5-min guides are faster than scrolling through deep dives
**When stuck:** Then dive into deep-dive (kbr)

### Tip 2: Use Checklists Before Deploying
**Why:** Catch 80% of bugs in 3 minutes
**File:** `11-oracle-security-checklist.md` or `12-dex-security-checklist.md`

### Tip 3: Copy Working Examples
**Why:** Less chance of errors, patterns are proven
**Where:** Every integration guide has "Complete Working Example"

### Tip 4: Reference by File:Line
**Why:** You can quickly find code during review
**Format:** "See kba/06-defi-trading/14-uniswap-v3-integration.md:180-210"

### Tip 5: Use Search Script
**Why:** Find patterns across entire KB instantly
**Usage:** `./search.sh "tick math"` instead of manually opening files

---

## Sample Development Session

```
Time: 0:00 - User says: "Build Uniswap V3 swap with oracle protection"

Time: 0:05 - Claude Code:
  - Reads: 14-uniswap-v3-integration.md (quick template)
  - Reads: 08-chainlink-datafeed-integration.md (price feed)
  - Writes: Contract combining both patterns

Time: 0:15 - User asks: "Is this secure?"

Time: 0:18 - Claude Code:
  - Reads: 12-dex-security-checklist.md
  - Reviews: Code against 51 items
  - Reports: 3 issues found
  - Suggests: Fixes with references to guides

Time: 0:25 - User approves, deploys

Time: 0:26 - Done! Used KB efficiently without context loss
```

---

## Tools for KB Access

**Available to Claude Code:**
- `Read` - Pull specific files
- `Grep` - Search across files
- `Glob` - Find files by pattern
- `Task` - Complex multi-file searches
- `Bash` - ./search.sh script

**Recommended usage:**
- **Quick lookup** → ./search.sh (fastest)
- **Read entire guide** → Read tool
- **Search in specific section** → Grep tool
- **Find all related files** → Glob or Task

---

## Knowledge Base Access During Development: Summary

```
┌─────────────────────────────────────────────┐
│  User describes feature/problem              │
└────────────────┬────────────────────────────┘
                 │
                 ├─→ Quick integration guide (kba)
                 │   └─→ 5-10 min, copy-paste code
                 │
                 ├─→ Security checklist (kba)
                 │   └─→ 3 min, verify before deploying
                 │
                 ├─→ Deep dive research (kbr)
                 │   └─→ 30+ min, understand architecture
                 │
                 └─→ Code pattern + references
                     └─→ Ready to integrate
```

This structure allows **fast development** (quick guides) without losing **deep knowledge** (research files).
