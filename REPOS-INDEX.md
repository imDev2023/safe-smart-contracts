# Git Repositories Index

> All repositories ingested into the knowledge base - save this to avoid re-pasting

**Last Updated:** 2025-11-16
**Total Repos:** 20 (Phase 1: 15 + Phase 2: 5)
**Status:** Phase 1 ✅ Complete | Phase 2 🚀 In Progress

---

## Complete Repository List

### Core DEX & AMM

#### 1. Uniswap V2

```bash
https://github.com/Uniswap/v2-core.git
https://github.com/Uniswap/v2-periphery.git
```

**Purpose:** Constant product AMM with factory pattern
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/uniswap/08-uniswap-v2-deep-dive.md`
**KB Guide:** `06-defi-trading/13-uniswap-v2-integration.md`

#### 2. Uniswap V3

```bash
https://github.com/Uniswap/v3-core.git
https://github.com/Uniswap/v3-periphery.git
```

**Purpose:** Concentrated liquidity with ticks
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/uniswap/10-uniswap-v3-deep-dive.md`
**KB Guide:** `06-defi-trading/14-uniswap-v3-integration.md`

#### 3. Uniswap V4

```bash
https://github.com/Uniswap/v4-core.git
```

**Purpose:** Singleton PoolManager with hooks
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/uniswap/09-uniswap-v4-deep-dive.md`
**KB Guide:** `06-defi-trading/15-uniswap-v4-integration.md`

#### 4. Balancer V2

```bash
https://github.com/balancer/balancer-v2-monorepo.git
```

**Purpose:** Generalized AMM with vault pattern
**Status:** ✅ Ingested - Deep-dive only
**Location:** `repos/balancer/01-vault-architecture.md`

#### 5. Curve Finance

```bash
https://github.com/curvefi/curve-contract.git
```

**Purpose:** Stablecoin AMM (low-slippage for correlated assets)
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/curve/01-stablecoin-amm-deep-dive.md`
**KB Guide:** `06-defi-trading/24-curve-stablecoin-amm.md`

---

## Oracles & Price Feeds

#### 5. Chainlink

```bash
https://github.com/smartcontractkit/chainlink.git
```

**Purpose:** Decentralized oracle network (feeds, VRF, automation)
**Status:** ✅ Ingested - Deep-dive + 3 quick guides
**Location:** `repos/chainlink/11-chainlink-oracle-deep-dive.md`

**Quick Guides:**

- `06-defi-trading/08-chainlink-datafeed-integration.md`
- `06-defi-trading/09-chainlink-vrf-integration.md`
- `06-defi-trading/10-chainlink-automation-integration.md`

#### 6. Pyth Network

```bash
https://github.com/pyth-network/pyth-crosschain.git
```

**Purpose:** Pull-based oracle with low latency
**Status:** ✅ Ingested - Deep-dive only
**Location:** `repos/pyth/01-oracle-network.md`

---

## Lending & Yield Optimization

#### 7. Aave V3

```bash
https://github.com/aave/aave-v3-core.git
https://github.com/aave/aave-v3-periphery.git
```

**Purpose:** Decentralized lending/borrowing with flash loans
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/aave/01-v3-lending-deep-dive.md`
**KB Guide:** `06-defi-trading/18-aave-v3-integration.md`

#### 8. Compound Comet (V3)

```bash
https://github.com/compound-finance/comet.git
```

**Purpose:** Simplified lending with single base asset
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/compound/01-comet-deep-dive.md`
**KB Guide:** `06-defi-trading/19-compound-comet-integration.md`

#### 9. Yearn Finance

```bash
https://github.com/yearn/yearn-vaults.git
```

**Purpose:** Automated yield farming with composable strategies
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/yearn/01-vault-automation-deep-dive.md`
**KB Guide:** `06-defi-trading/25-yearn-vault-yield.md`

---

## Governance & Voting

#### 9. Governor (OpenZeppelin)

```bash
https://github.com/OpenZeppelin/openzeppelin-contracts.git
```

**Purpose:** Standard DAO voting and proposal system
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/governance/01-governor-voting-deep-dive.md`
**KB Guide:** `06-defi-trading/20-governance-voting.md`

---

## Staking & Rewards

#### 10. Lido

```bash
https://github.com/lidofinance/lido-dao.git
```

**Purpose:** Liquid ETH staking with stETH derivatives
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/lido/01-staking-protocol-deep-dive.md`
**KB Guide:** `06-defi-trading/21-lido-staking.md`

---

## Token Standards & Wrappers

#### 11. WETH (Wrapped Ether)

```bash
https://github.com/gnosis/canonical-weth.git
```

**Purpose:** ERC20 wrapper for native ETH
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/weth/01-wrapped-token-deep-dive.md`
**KB Guide:** `06-defi-trading/22-weth-wrapping.md`

---

## Stablecoins & Borrowing

#### 12. Liquity

```bash
https://github.com/liquity/dev.git
```

**Purpose:** Interest-free borrowing protocol (ETH → LUSD)
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/liquity/01-protocol-architecture.md`
**KB Guide:** `06-defi-trading/16-liquity-integration.md`

#### 13. Alchemix Finance

```bash
https://github.com/alchemix-finance/alchemix-protocol.git
```

**Purpose:** Self-paying loans (collateral yield repays debt)
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/alchemix/01-self-paying-loans-deep-dive.md`
**KB Guide:** `06-defi-trading/26-alchemix-self-paying.md`

---

## Derivatives & Synthetic Assets

#### 14. Synthetix

```bash
https://github.com/Synthetixio/synthetix.git
```

**Purpose:** Decentralized derivatives platform with synthetic assets
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/synthetix/01-derivatives-protocol-deep-dive.md`
**KB Guide:** `06-defi-trading/27-synthetix-derivatives.md`

---

## Math & Utilities

#### 8. PRB Math

```bash
https://github.com/PaulRBerg/prb-math.git
```

**Purpose:** Fixed-point arithmetic (SD59x18, UD60x18)
**Status:** ✅ Ingested - Deep-dive only
**Location:** `repos/prb-math/01-fixed-point-arithmetic.md`

#### 10. Solady

```bash
https://github.com/Vectorized/solady.git
```

**Purpose:** Gas-optimized utilities (50+ contracts)
**Status:** ✅ Ingested - Deep-dive only
**Location:** `repos/solady/01-utilities-reference.md`

---

## NFT Marketplaces

#### 15. Seaport

```bash
https://github.com/ProjectOpenSea/seaport.git
```

**Purpose:** Efficient NFT marketplace protocol with flexible order system
**Status:** ✅ Ingested - Deep-dive + quick guide
**Location:** `repos/seaport/01-nft-marketplace-deep-dive.md`
**KB Guide:** `06-defi-trading/23-seaport-nft-marketplace.md`

---

## Gaming & NFTs

#### 16. Game ERC-721 Template

```bash
https://github.com/IDouble/Simple-Game-ERC-721-Token-Template.git
```

**Purpose:** Educational template for game items (unique NFTs)
**Status:** ✅ Ingested - Quick guide only
**KB Guide:** `06-defi-trading/17-nft-game-templates.md` (Template 1)

#### 17. Game ERC-1155 Template

```bash
https://github.com/IDouble/Simple-ERC-1155-Multi-Token-Template.git
```

**Purpose:** Educational template for mixed fungible/NFT tokens
**Status:** ✅ Ingested - Quick guide only
**KB Guide:** `06-defi-trading/17-nft-game-templates.md` (Template 2)

---

## AI & Agent Economics

#### 18. Virtual Protocol

```bash
https://github.com/Virtual-Protocol/protocol-contracts.git
```

**Purpose:** Multi-DAO AI agent economics with reward distribution
**Status:** ✅ Ingested - Deep-dive only
**Location:** `repos/virtual-protocol/01-ai-agent-economics.md`

---

## Quick Copy-Paste Block

If adding more repos, use this format:

```bash
https://github.com/[ORG]/[REPO].git
```

Then create entry:
- Purpose: [What it does]
- Status: [Ingested/Pending]
- Location: `repos/[name]/01-*.md`
- KB Guide: `06-defi-trading/[number]-*.md` (if applicable)

---

## Repo Organization by Category

### By Type

**DEX/AMM** (5 repos):

- Uniswap V2
- Uniswap V3
- Uniswap V4
- Balancer V2
- Curve Finance ✨ (Phase 2)

**Oracles** (2 repos):

- Chainlink
- Pyth

**Lending & Yield** (3 repos):

- Aave V3
- Compound Comet
- Yearn Finance ✨ (Phase 2)

**Governance** (1 repo):

- Governor (OpenZeppelin)

**Staking & Rewards** (1 repo):

- Lido

**Token Standards** (1 repo):

- WETH

**Stablecoins & Borrowing** (2 repos):

- Liquity
- Alchemix Finance ✨ (Phase 2)

**Derivatives** (1 repo):

- Synthetix ✨ (Phase 2)

**NFT Marketplaces** (1 repo):

- Seaport ✨ (Phase 2)

**Math/Utils** (2 repos):

- PRB Math
- Solady

**Gaming** (2 repos):

- Game ERC-721
- Game ERC-1155

**AI/Agents** (1 repo):

- Virtual Protocol

---

## Repo Status Summary

| Status | Count | Repos |
|--------|-------|-------|
| ✅ Deep-dive only | 6 | PRB Math, Solady, Pyth, Balancer, Virtual Protocol, Pyth |
| ✅ Quick guide only | 2 | Game ERC-721, Game ERC-1155 |
| ✅ Both (deep + quick) | 12 | **Phase 1:** Uniswap V2, V3, V4, Chainlink, Aave V3, Compound, Governor, Lido, WETH, Liquity **Phase 2:** Curve, Yearn, Alchemix, Synthetix, Seaport |

---

## How to Use This File

**When finding repos:**

1. Search this file for repo name
2. Copy GitHub URL
3. Check KB location
4. Read guide or deep-dive

**When someone asks you later:**

- "Have you ingested Uniswap?" → Check REPOS-INDEX.md
- "Show me the Liquity repo" → Reference line with GitHub URL + KB location
- "Add this new repo..." → Compare with existing format

**To add new repos:**

1. Add entry to this file
2. Clone to `temp-repos/[name]`
3. Create documentation files
4. Update `KB-REPOSITORY-MAP.md`
5. Update this file with new status

---

## Notes

- All repos have been cloned locally to `temp-repos/[name]` for reference
- Documentation extracted to `knowledge-base-action/` (quick guides) and `knowledge-base-research/repos/` (deep dives)
- Total: 20 unique repos documented (15 Phase 1 + 5 Phase 2)
- Quick-action guides: 27 files (22 Phase 1 + 5 Phase 2)
- Deep-dive research: 24 files (19 Phase 1 + 5 Phase 2)
- Total KB size: ~5 MB across 400+ files

**Phase 1 (Completed 2025-11-16):**
- Aave V3 (Lending)
- Compound Comet (Lending)
- Governor (Governance)
- Lido (Staking)
- WETH (Token Wrapping)

**Phase 2 (Completed 2025-11-16):**

- Seaport (NFT Marketplace)
- Curve Finance (Stablecoin AMM)
- Yearn Finance (Vault Automation)
- Alchemix Finance (Self-paying Loans)
- Synthetix (Derivatives Platform)

## Phase 3: Gaming & AI Integration (Upcoming)

- Loot Project (On-chain loot generation)
- Seaport extensions (NFT game mechanics)
- Additional AI/DAO protocols as needed

**Last synced with KB:** 2025-11-16
