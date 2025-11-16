# Oracle Selection Guide

> Quick decision matrix for choosing the right oracle for your DeFi protocol (2 min read)

## Oracle Comparison Matrix

| Feature | Chainlink | Band | Pyth | UMA |
|---------|-----------|------|------|-----|
| **Asset Coverage** | 1000+ | 500+ | 400+ | Any custom |
| **Chains** | 15+ EVM + non-EVM | 10+ | 4 (Sol, Aptos, Sui, Pyth) | 5+ EVM |
| **Update Frequency** | Seconds to hours | Minutes | Sub-second | On demand |
| **Decentralization** | 30+ nodes | 20+ validators | 60+ publishers | UMA holders vote |
| **Cost** | Gas intensive | Medium | Cheapest | Protocol pays |
| **Dispute Resolution** | None | Oracle voting | Arbitrage | Optimistic oracle |
| **Best For** | Price feeds, VRF, Automation | Emerging assets | High-frequency | Custom data |

## Decision Tree

```
Does your protocol need randomness?
├─ YES → Use Chainlink VRF
│        (proven, battle-tested, $$$)
│
└─ NO → Do you need price feeds?
   ├─ YES → How fast?
   │        ├─ Seconds (DeFi swaps) → Chainlink Data Feeds
   │        ├─ Minutes (yield farms) → Band Protocol
   │        └─ Sub-second (options) → Pyth Network
   │
   └─ NO → Do you need custom data?
      ├─ YES → UMA (customizable, but slower)
      └─ NO → Consider TWAP oracle (no external dependency)
```

## Cost Analysis (per update)

```
Chainlink:     500-5,000 gas
Band Protocol: 200-1,000 gas
Pyth Network:  20-100 gas
UMA:           2,000-10,000 gas (dispute overhead)
TWAP (DEX):    0 gas (internal accounting)
```

## Security Considerations

### Chainlink
✅ Longest track record (2017+)
✅ Multiple node operators
✅ Economic incentives (staking)
⚠️ Single oracle problem (adds only one feed)
⚠️ Centralized dispute resolution

### Band
✅ Lower cost than Chainlink
✅ Good for emerging chains
⚠️ Smaller validator set
⚠️ Less TVL secured

### Pyth
✅ Lowest gas cost
✅ Sub-second updates
⚠️ Newer (2021), less battle-tested
⚠️ Centralized publisher model initially
⚠️ Limited to 4 chains

### UMA
✅ Fully customizable
✅ No price feed limits
⚠️ Slowest (dispute delay)
⚠️ Only works for non-time-critical updates

### TWAP (Uniswap Internal)
✅ Zero gas cost
✅ No external dependency
⚠️ Can be manipulated with large trade
⚠️ Only works for pooled assets

## When to Use Each

### Use Chainlink If:
- You need prices for major assets (ETH, BTC, stables)
- You need VRF (randomness)
- You need Automation (Keepers)
- Security is critical (institutional grade)
- Cost is not the primary concern

### Use Band If:
- You need multiple obscure assets
- You're on a low-traffic chain
- Cost matters but not critical

### Use Pyth If:
- You need sub-second updates
- You're on Solana/Aptos/Sui
- You're doing high-frequency trading
- Gas cost is critical

### Use UMA If:
- You need truly custom data
- Update frequency can be slow (hours)
- You trust the UMA community governance

### Use TWAP If:
- Asset is liquid on a DEX
- You can tolerate manipulation risk
- Cost is absolutely critical
- Update frequency can be low (blocks/minutes)

## Recommendation Pattern

```
FOR price feed (ETH/USD, BTC/USD):
→ Chainlink (primary) + TWAP fallback

FOR emerging asset price:
→ Band Protocol

FOR high-frequency (options, futures):
→ Pyth Network

FOR custom data (sports, weather):
→ UMA

FOR internal liquidity pools:
→ TWAP only (no external oracle)
```

---

**Next**: See `chainlink-datafeed-integration.md` for step-by-step Chainlink setup.
