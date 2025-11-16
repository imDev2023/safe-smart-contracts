# Smart Contract Generator - Domain Examples

This guide provides complete examples for generating production-ready smart contracts across all supported domains using your knowledge base.

---

## 🎮 Gaming Domain Examples

### Example 1: RPG Character NFTs with VRF

**Use Case:** Gaming NFTs with random attributes and achievement tracking

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC721 \
  --domain gaming \
  --features vrf,achievements,anti-cheat \
  --output contracts/gaming/rpg-characters/
```

**Generated Features:**
- ✅ Chainlink VRF for random attribute generation
- ✅ Achievement system (tracks XP, levels, milestones)
- ✅ Anti-cheat protection (rate limiting, spam prevention)
- ✅ Reentrancy guard on all mint/transfer functions
- ✅ Owner access control
- ✅ Pausable for emergency stops
- ✅ Gas-optimized storage packing

**Example Use Cases:**
- RPG character NFTs with random stats
- Trading card games with random card packs
- Loot box systems with provably fair randomness
- Achievement-based progression systems
- Gaming items with anti-bot protection

---

### Example 2: Simple Gaming NFT (Minimal Features)

**Use Case:** Basic gaming NFT without randomness

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC721 \
  --domain gaming \
  --features anti-cheat \
  --output contracts/gaming/simple-items/
```

**Generated Features:**
- ✅ Anti-spam protection
- ✅ Basic security (reentrancy, access control)
- ✅ Gas optimizations

---

## 🖼️ NFT Domain Examples

### Example 3: PFP Collection with Full Features

**Use Case:** Profile picture NFT collection with royalties and allowlist

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC721 \
  --domain nft \
  --features royalties,reveal,allowlist \
  --output contracts/nft/pfp-collection/
```

**Generated Features:**
- ✅ ERC2981 royalty standard (configurable %)
- ✅ Metadata reveal system (prevents rarity sniping)
- ✅ Merkle tree allowlist (gas-efficient presale)
- ✅ Batch minting (save gas on multi-mint)
- ✅ All security protections
- ✅ Pausable during reveal

**Example Use Cases:**
- 10k PFP collections
- Generative art projects
- Membership pass NFTs
- Allowlist/presale mints
- Collections requiring royalties on secondary sales

---

### Example 4: Art Collection with Royalties Only

**Use Case:** Art NFTs with creator royalties

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC721 \
  --domain nft \
  --features royalties \
  --output contracts/nft/art-collection/
```

**Generated Features:**
- ✅ ERC2981 royalty support (5-10% typical)
- ✅ Security protections
- ✅ Owner-only minting

---

## 🤖 AI Integration Domain Examples

### Example 5: AI Agent with Usage Metering

**Use Case:** AI-powered token with off-chain computation and usage tracking

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC20 \
  --domain ai \
  --features oracle,usage-tracking,payments \
  --output contracts/ai/agent-token/
```

**Generated Features:**
- ✅ Chainlink Functions integration (off-chain AI computation)
- ✅ Usage metering system (credit-based)
- ✅ Payment splits (multi-party distribution)
- ✅ Request/response tracking
- ✅ All security protections
- ✅ Gas optimizations

**Example Use Cases:**
- AI agent economy tokens
- Usage-based pricing models
- Multi-stakeholder payment systems
- Oracle-backed AI inference
- Decentralized AI marketplaces

---

### Example 6: Simple Oracle Integration

**Use Case:** Basic oracle integration without usage tracking

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC20 \
  --domain ai \
  --features oracle \
  --output contracts/ai/oracle-token/
```

**Generated Features:**
- ✅ Chainlink Functions for off-chain computation
- ✅ Security protections

---

## 💰 DeFi Domain Examples

### Example 7: Trading Token with Maximum Protection

**Use Case:** DeFi token with all anti-bot and slippage protections

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC20 \
  --domain defi \
  --features anti-sniper,slippage,oracle \
  --output contracts/defi/trading-token/
```

**Generated Features:**
- ✅ Anti-sniper bot detection (first 3 blocks)
- ✅ Slippage protection (max 3% price impact)
- ✅ Chainlink price feed integration
- ✅ Buy/wallet limits (prevent whale dumps)
- ✅ Trading enable/disable control
- ✅ All security protections
- ✅ Custom errors (50% gas savings)

**Example Use Cases:**
- Trading tokens on DEXs
- Liquidity pool tokens
- Reward tokens with anti-bot protection
- Staking tokens
- DeFi protocol tokens

---

### Example 8: Basic DeFi Token

**Use Case:** Simple DeFi token with oracle

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC20 \
  --domain defi \
  --features oracle \
  --output contracts/defi/basic-token/
```

**Generated Features:**
- ✅ Chainlink oracle integration
- ✅ Security protections
- ✅ Gas optimizations

---

## 🔀 Multi-Feature Combinations

### Example 9: Gaming + Achievements (Focused)

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC721 \
  --domain gaming \
  --features achievements \
  --output contracts/gaming/achievement-nfts/
```

**Best For:** Games focused on progression without randomness

---

### Example 10: NFT + Reveal Only

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC721 \
  --domain nft \
  --features reveal \
  --output contracts/nft/reveal-collection/
```

**Best For:** Public mint collections wanting to prevent rarity sniping

---

### Example 11: AI + Payments Only

```bash
python scripts/cocoindex/contract_builder.py \
  --type ERC20 \
  --domain ai \
  --features payments \
  --output contracts/ai/payment-token/
```

**Best For:** Multi-party payment distribution without usage tracking

---

## 📊 Feature Matrix

| Domain | Available Features | Description |
|--------|-------------------|-------------|
| **DeFi** | `anti-sniper` | Blocks bots in first N blocks |
| | `slippage` | Max 3% price impact protection |
| | `oracle` | Chainlink price feed integration |
| **Gaming** | `vrf` | Chainlink VRF for randomness |
| | `achievements` | Achievement tracking system |
| | `anti-cheat` | Rate limiting & spam prevention |
| **NFT** | `royalties` | ERC2981 royalty standard |
| | `reveal` | Metadata reveal system |
| | `allowlist` | Merkle tree presale |
| **AI** | `oracle` | Chainlink Functions integration |
| | `usage-tracking` | Credit-based metering |
| | `payments` | Multi-party payment splits |

---

## 🔍 All Contracts Include (Automatically)

Regardless of domain or features selected, **every generated contract includes:**

### Security Protections
- ✅ **ReentrancyGuard** - Prevents The DAO ($60M) attack
- ✅ **Access Control** (Ownable) - Prevents Parity ($280M) attack
- ✅ **Pausable** - Emergency stop mechanism
- ✅ **SafeERC20** - Prevents silent transfer failures (ERC20 only)

### Gas Optimizations
- ✅ **Custom Errors** - 50% gas savings vs require strings
- ✅ **Storage Packing** - 20-40% gas savings
- ✅ **Immutable Variables** - 21,000 gas per access saved

### Testing & Deployment
- ✅ **Comprehensive Test Suite** - Security, functionality, gas tests
- ✅ **Pre-Deployment Checklist** - 400+ security checks
- ✅ **Inline Documentation** - Every function documented with KB references

---

## 💡 Tips & Best Practices

### Choosing Features

**Gaming Projects:**
- Use `vrf` for any randomness (loot, attributes, etc.)
- Use `achievements` for progression systems
- Use `anti-cheat` for competitive games

**NFT Projects:**
- Use `royalties` if you want marketplace royalties
- Use `reveal` for surprise/fair minting
- Use `allowlist` for presale/whitelist minting

**DeFi Projects:**
- Use `anti-sniper` for tokens launching on DEXs
- Use `slippage` for tokens used in swaps
- Use `oracle` for price-dependent functionality

**AI Projects:**
- Use `oracle` for off-chain AI computation
- Use `usage-tracking` for pay-per-use models
- Use `payments` for revenue sharing

### Output Organization

Organize by project:
```bash
# Good structure
contracts/
├── my-game/
│   ├── characters/SecureERC721Contract.sol
│   └── items/SecureERC721Contract.sol
├── my-nft/
│   └── collection/SecureERC721Contract.sol
└── my-defi/
    └── token/SecureERC20Contract.sol
```

---

## 🚀 Quick Start Commands

### For Gaming:
```bash
# Full-featured gaming NFT
python scripts/cocoindex/contract_builder.py --type ERC721 --domain gaming --features vrf,achievements,anti-cheat

# Simple gaming NFT
python scripts/cocoindex/contract_builder.py --type ERC721 --domain gaming --features anti-cheat
```

### For NFT:
```bash
# Full-featured NFT collection
python scripts/cocoindex/contract_builder.py --type ERC721 --domain nft --features royalties,reveal,allowlist

# Art collection
python scripts/cocoindex/contract_builder.py --type ERC721 --domain nft --features royalties
```

### For AI:
```bash
# Full AI integration
python scripts/cocoindex/contract_builder.py --type ERC20 --domain ai --features oracle,usage-tracking,payments

# Simple oracle
python scripts/cocoindex/contract_builder.py --type ERC20 --domain ai --features oracle
```

### For DeFi:
```bash
# Trading token with protection
python scripts/cocoindex/contract_builder.py --type ERC20 --domain defi --features anti-sniper,slippage,oracle

# Basic DeFi token
python scripts/cocoindex/contract_builder.py --type ERC20 --domain defi --features oracle
```

---

## 📚 Next Steps

1. **Generate your contract** using examples above
2. **Review generated code** in the output directory
3. **Run tests:** `forge test`
4. **Complete checklist:** `PRE_DEPLOYMENT_CHECKLIST.md`
5. **Deploy to testnet** for testing
6. **Get security audit** before mainnet deployment

---

**Generated by:** Safe Smart Contract Builder v1.0
**Total Domains:** 4 (DeFi, Gaming, NFT, AI)
**Total Features:** 12
**Security Checks:** 400+
**Knowledge Base:** 284 files, 92,800+ lines
