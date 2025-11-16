# Knowledge Base Lookup - For Fast Access During Development

> Quick reference map to find KB files by feature/problem/keyword

## By Feature

### Uniswap Integration

| Feature | Quick Guide | Code Example | Security | Deep Dive |
|---------|------------|--------------|----------|-----------|
| **V2 Swap** | `06-defi-trading/13-uniswap-v2-integration.md` | Lines 90-180 | `12-dex-checklist.md` | `repos/uniswap/08-*.md` |
| **V3 Swap** | `06-defi-trading/14-uniswap-v3-integration.md` | Lines 115-220 | `12-dex-checklist.md` | `repos/uniswap/09-*.md` |
| **V3 LP** | `06-defi-trading/14-uniswap-v3-integration.md` | Lines 240-300 | `12-dex-checklist.md` | `repos/uniswap/09-*.md` |
| **V4 Swap** | `06-defi-trading/15-uniswap-v4-integration.md` | Lines 105-180 | `12-dex-checklist.md` | `repos/uniswap/10-*.md` |
| **V4 Hooks** | `06-defi-trading/15-uniswap-v4-integration.md` | Lines 280-340 | `12-dex-checklist.md` | `repos/uniswap/10-*.md` |

### Chainlink Integration

| Feature | Quick Guide | Code Example | Security | Deep Dive |
|---------|------------|--------------|----------|-----------|
| **Data Feeds** | `06-defi-trading/08-chainlink-datafeed-integration.md` | Lines 75-145 | `11-oracle-checklist.md` | `repos/chainlink/11-*.md` |
| **VRF** | `06-defi-trading/09-chainlink-vrf-integration.md` | Lines 120-180 | `11-oracle-checklist.md` | `repos/chainlink/11-*.md` |
| **Automation** | `06-defi-trading/10-chainlink-automation-integration.md` | Lines 140-220 | `11-oracle-checklist.md` | `repos/chainlink/11-*.md` |
| **Oracle Selection** | `06-defi-trading/00-oracle-selection.md` | Lines 40-80 | `11-oracle-checklist.md` | `repos/chainlink/11-*.md` |

### Security & Protection

| Feature | Guide | Type | Time |
|---------|-------|------|------|
| **Slippage Protection** | `06-defi-trading/02-slippage-protection.md` | Pattern | 5 min |
| **MEV Mitigation** | `06-defi-trading/05-mev-mitigation.md` | Strategy | 5 min |
| **Sniper Bot Prevention** | `06-defi-trading/03-sniper-bot-prevention.md` | Detection | 5 min |
| **Flash Swap Safety** | `06-defi-trading/04-flash-swaps.md` | Pattern | 5 min |
| **Oracle Security Checklist** | `06-defi-trading/11-oracle-security-checklist.md` | Checklist | 3 min |
| **DEX Security Checklist** | `06-defi-trading/12-dex-security-checklist.md` | Checklist | 3 min |

---

## By Problem Type

### "Code is Reverting"

```
Common swap failures:

Uniswap: See "Common Issues & Solutions" in:
  → 13-uniswap-v2-integration.md:170-180
  → 14-uniswap-v3-integration.md:195-210
  → 15-uniswap-v4-integration.md:220-240

Chainlink: See "Testing" section in:
  → 08-chainlink-datafeed-integration.md:190-210
  → 09-chainlink-vrf-integration.md:240-260
  → 10-chainlink-automation-integration.md:280-300

Flash revert checklist:
  → 04-flash-swaps.md:280-320
```

### "Not Protecting Against Slippage"

```
Solution:

1. Quick fix: 02-slippage-protection.md
   - Lines 50-80: amountOutMin calculation
   - Lines 95-120: Deadline enforcement

2. Advanced: 05-mev-mitigation.md
   - Lines 40-70: Dynamic slippage based on volatility
   - Lines 85-110: Multi-hop optimization

3. Code example:
   - 13-uniswap-v2-integration.md:120-140
   - 14-uniswap-v3-integration.md:150-170
```

### "Oracle Price Seems Wrong"

```
Solution:

1. Staleness check: 11-oracle-security-checklist.md:10-20
2. Decimal handling: 11-oracle-security-checklist.md:25-35
3. Multi-oracle consensus: 11-oracle-security-checklist.md:45-65
4. TWAP fallback: 02-slippage-protection.md:130-150
5. Deep understanding: repos/chainlink/11-chainlink-deep-dive.md
```

### "Can't Integrate Chainlink"

```
Check integration guide for your feature:

Data Feeds:
  → Start: 08-chainlink-datafeed-integration.md:20-60
  → Code: 08-chainlink-datafeed-integration.md:115-180
  → Issue? → Search "Chainlink" in KB

VRF:
  → Start: 09-chainlink-vrf-integration.md:20-60
  → Code: 09-chainlink-vrf-integration.md:130-210
  → Issue? → Check "Common Issues" section

Automation:
  → Start: 10-chainlink-automation-integration.md:20-50
  → Code: 10-chainlink-automation-integration.md:145-240
  → Issue? → Check "Best Practices" section
```

### "Contract Fails Security Audit"

```
Run through checklists:

Oracle integration:
  → 11-oracle-security-checklist.md (28 items, 3 min)

DEX integration:
  → 12-dex-security-checklist.md (51 items, 3 min)

Specific vulnerability:
  → knowledge-base-action/03-attack-prevention/ (10 files)

Then deep dive:
  → repos/uniswap/ or repos/chainlink/ as needed
```

---

## By Keyword Search

### Use ./search.sh with these keywords:

```bash
# DEX queries
./search.sh "uniswap v2"           # V2 mechanics
./search.sh "uniswap v3 tick"      # V3 concentrated liquidity
./search.sh "uniswap v4 hook"      # V4 hooks
./search.sh "constant product"     # AMM fundamentals
./search.sh "pool"                 # Liquidity pools

# Oracle queries
./search.sh "chainlink"            # All Chainlink content
./search.sh "price feed"           # Price oracle patterns
./search.sh "VRF"                  # Randomness
./search.sh "aggregator"           # Aggregation mechanism
./search.sh "oracle security"      # Security checklist

# Security queries
./search.sh "slippage"             # Price slippage
./search.sh "MEV"                  # Extractable value
./search.sh "sniper"               # Bot prevention
./search.sh "flash"                # Flash loan/swap attacks
./search.sh "staleness"            # Oracle staleness

# Architecture queries
./search.sh "factory pattern"       # Factory design pattern
./search.sh "callback"             # Callback execution
./search.sh "singleton"            # Singleton pattern
./search.sh "decimal"              # Token decimals
```

---

## Code Pattern Quick Links

### Copy-Paste Ready Code

**Uniswap V2 Full Example:**
```
File: kba/06-defi-trading/13-uniswap-v2-integration.md
Section: "Complete Working Example"
Lines: 145-220 (SimpleV2Swap contract)
Use: Copy entire contract, replace constants, deploy
```

**Uniswap V3 Full Example:**
```
File: kba/06-defi-trading/14-uniswap-v3-integration.md
Section: "Complete Working Example"
Lines: 180-320 (V3SwapAndLP contract)
Use: Copy methods you need, extend as needed
```

**Uniswap V4 Full Example:**
```
File: kba/06-defi-trading/15-uniswap-v4-integration.md
Section: "Complete Working Example"
Lines: 190-340 (V4Router contract)
Use: Adapt unlock/swap pattern to your needs
```

**Chainlink Data Feeds Full Example:**
```
File: kba/06-defi-trading/08-chainlink-datafeed-integration.md
Section: "Complete Working Example"
Lines: 150-240 (StableSwap contract)
Use: Copy constructor + swap method
```

**Chainlink VRF Full Example:**
```
File: kba/06-defi-trading/09-chainlink-vrf-integration.md
Section: "Complete Working Example"
Lines: 160-280 (SimpleRaffle contract)
Use: Copy request + fulfill pattern
```

**Chainlink Automation Full Example:**
```
File: kba/06-defi-trading/10-chainlink-automation-integration.md
Section: "Complete Working Example"
Lines: 180-320 (LiquidationBot contract)
Use: Copy checkUpkeep + performUpkeep pattern
```

---

## File Size & Read Time Reference

```
QUICK GUIDES (2-5 min to read):
  00-oracle-selection.md ............... 8 KB
  08-chainlink-datafeed-integration.md  18 KB
  09-chainlink-vrf-integration.md ....... 20 KB
  10-chainlink-automation-integration.. 22 KB
  13-uniswap-v2-integration.md ........ 22 KB
  14-uniswap-v3-integration.md ........ 24 KB
  15-uniswap-v4-integration.md ........ 26 KB

SECURITY CHECKLISTS (3 min to check):
  11-oracle-security-checklist.md ..... 16 KB
  12-dex-security-checklist.md ........ 18 KB

PROTECTION GUIDES (5 min to read):
  02-slippage-protection.md ........... 22 KB
  03-sniper-bot-prevention.md ......... 25 KB
  04-flash-swaps.md .................. 21 KB
  05-mev-mitigation.md ............... 24 KB

DEEP DIVES (30-60 min to read):
  repos/uniswap/08-v2-deep-dive.md ... 50 KB
  repos/uniswap/09-v3-deep-dive.md ... 65 KB
  repos/uniswap/10-v4-deep-dive.md ... 60 KB
  repos/chainlink/11-oracle-deep-dive  70 KB
```

---

## Development Workflow Map

```
┌─ IDENTIFY FEATURE ──────────────────────────────────┐
│                                                      │
│  "Need to add Uniswap V3 swap?"                    │
│                                                      │
└──────────────────┬─────────────────────────────────┘
                   │
         ┌─────────┴──────────┐
         │                    │
         v                    v
    QUICK START          SECURITY FIRST
    (5 min)              (3 min)
         │                    │
    14-uniswap-v3-*.md    12-dex-checklist.md
    [Copy example]        [51 items]
         │                    │
         └─────────┬──────────┘
                   │
                   v
            WRITE & DEPLOY
                   │
         ┌─────────┴──────────┐
         │                    │
    Still confused?      Working?
         │                    │
         v                    v
    repos/uniswap/09-*   ✅ SUCCESS
    [30 min deep dive]
```

---

## How Claude Code Uses This File

When Claude Code needs to help with development:

```
1. User says: "Add Uniswap V3 concentrated liquidity to our swap"

2. Claude checks KB-LOOKUP.md:
   - Finds: "V3 LP" row
   - Gets: Quick guide + code example
   - Gets: Security checklist reference
   - Gets: Deep dive file (if needed later)

3. Claude reads: 14-uniswap-v3-integration.md:240-300
   - Gets complete working example
   - Explains what each part does
   - Writes code based on pattern

4. User asks: "Is this secure?"

5. Claude checks: 11-oracle-security-checklist.md:45-65
   - Finds multi-oracle consensus pattern
   - Validates user's code
   - Suggests improvements

6. User confused about tick math

7. Claude reads: repos/uniswap/09-*.md:180-220
   - Explains tick system in detail
   - Shows math examples
   - References protocol specs
```

---

## Summary

**This file (KB-LOOKUP.md)** is the **master index for fast KB access** during development.

**The three-tier structure:**
1. **Quick guides (kba)** - 5-10 min, ready to code
2. **Security checklists (kba)** - 3 min, verify quality
3. **Deep dives (kbr)** - 30+ min, understand internals

**Use pattern:**
```
Develop → Check quick guide → Apply security checklist → Test
If confused → Read deep dive → Understand fundamentals → Test
If fails → Run checklist → Fix issue → Test again
```

**Result:** Fast development without knowledge loss. ⚡
