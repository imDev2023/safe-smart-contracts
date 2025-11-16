# Pyth Oracle Network - Price Feed Alternative to Chainlink

> High-frequency oracle network with pull-based price updates

**Repo:** https://github.com/pyth-network/pyth-crosschain.git
**Purpose:** Low-latency price feeds across 20+ blockchains
**Key Advantage:** Cheaper than Chainlink, faster updates (1s latency), pull-based model

---

## How Pyth Works (vs Chainlink)

### Chainlink (Push Model)
```
Node Operator → Aggregation → Smart Contract
         ↓
    Automatic updates every X time/price change
         ↓
    High gas cost per update (~3,000-5,000 gas)
```

### Pyth (Pull Model)
```
Pythnet → Wormhole → User submits price on-chain
     ↓
 User-triggered updates only (when needed)
     ↓
 Cheaper: Gas only if you read price (~200-500 gas)
```

---

## Core Concepts

### Pythnet (L1 Blockchain)

Pyth operates its own blockchain (`Pythnet`) where:
- 80+ data providers submit price information
- Consensus mechanism aggregates prices
- Updates every ~350ms (vs Chainlink's variable intervals)

### Price Feed Structure

```solidity
struct PriceFeed {
    bytes32 id;              // Unique feed ID
    int64 price;             // Current price
    uint64 conf;             // Confidence interval
    int32 expo;              // Exponent (price * 10^expo)
    uint64 publish_time;     // Last update timestamp
}

// Example: ETH/USD
// price = 3200 * 10^8
// expo = -8
// Result: $3,200.00000000
```

---

## Integration Pattern

### Option 1: Pull Price On-Demand

```solidity
pragma solidity ^0.8.0;

import { PythStructs, IPyth } from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

contract MyDeFiProtocol {
    IPyth pyth;  // Pyth contract on your chain
    bytes32 ETH_USD_FEED_ID = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;

    // Update price on-chain by submitting Pyth price update
    function swapWithPythPrice(bytes[] memory priceUpdateData) external {
        // Submit price update (pay Pyth relayer fee)
        pyth.updatePriceFeeds(priceUpdateData);

        // Now read price (no additional cost)
        PythStructs.Price memory price = pyth.getPrice(ETH_USD_FEED_ID);

        uint256 ethPrice = _convertPrice(price);
        _executeSwap(ethPrice);
    }

    function _convertPrice(PythStructs.Price memory price)
        internal
        pure
        returns (uint256)
    {
        if (price.expo >= 0) {
            return uint64(price.price) * 10 ** uint32(price.expo);
        } else {
            return uint64(price.price) / 10 ** uint32(-price.expo);
        }
    }
}
```

### Option 2: Read Latest Price (Without Update)

```solidity
function getLivePrice() external view returns (int64) {
    PythStructs.Price memory price = pyth.getPrice(ETH_USD_FEED_ID);
    return price.price;
}
```

---

## Price Update Fee Model

### Cost Structure

```
Base Fee: ~0.0001 USD per price update

Factors:
├── Fixed base cost (relayer operational cost)
├── Scales with Pythnet demand
└── Payable in stablecoin or native token

Example (Ethereum):
├── Single price update: ~$0.01 - $0.10
├── Multi-price update: Amortized cost per feed
└── vs Chainlink: $0.50 - $5.00 per update (push-based)
```

### How to Submit Updates

**Option A: Hermes API (Recommended)**
```javascript
// Off-chain: Fetch signed price update from Hermes
const hermes = "https://hermes.pyth.network";
const priceUpdate = await fetch(
  `${hermes}/api/latest_price_feeds?ids[]=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace`
);

// On-chain: Submit to smart contract (bot service does this)
contract.swapWithPythPrice(priceUpdate.vaa);
```

**Option B: Manual Update (Advanced)**
```solidity
// Subscribe to price updates from Hermes API
// Submit periodic updates for your price feed
```

---

## Supported Chains & Contracts

### EVM Chains

| Chain | Pyth Contract | Status |
|-------|---|--------|
| **Ethereum** | 0x4305FB0885e50B68C51267f502327f22dD0c4068 | ✅ Mainnet |
| **Arbitrum** | 0xff1a0f4744e8582DF1aFE1a146b65B42148ce2d3 | ✅ Mainnet |
| **Optimism** | 0xff1a0f4744e8582DF1aFE1a146b65B42148ce2d3 | ✅ Mainnet |
| **Polygon** | 0xff1a0f4744e8582DF1aFE1a146b65B42148ce2d3 | ✅ Mainnet |
| **Base** | 0x8250f4aF4B972684F7b336503E2D6dAC3547701a | ✅ Mainnet |

Plus Solana, Sui, Aptos, Starknet, etc.

---

## Key Differences: Pyth vs Chainlink

| Feature | Pyth | Chainlink |
|---------|------|-----------|
| **Update Model** | Pull (user-triggered) | Push (automated) |
| **Latency** | ~1 second (Pythnet) | 15-60 seconds |
| **Cost** | $0.01-$0.10 per update | $0.50-$5.00 per update |
| **Update Frequency** | On-demand | Fixed interval + price deviation |
| **Coverage** | 100+ price feeds | 500+ price feeds |
| **Chains** | 20+ (and growing) | 15+ |
| **Confidence Intervals** | ✅ Included | ❌ Manual setup |

---

## When to Use Pyth vs Chainlink

### Use Pyth When:

✅ Low-frequency reads (not every block)
✅ Gas optimization critical
✅ High-frequency data (1s updates useful)
✅ Want cheaper oracle calls
✅ Building liquidation bots (on-demand checks)

### Use Chainlink When:

✅ Guaranteed automatic updates needed
✅ High-frequency continuous monitoring
✅ Want established, battle-tested oracle
✅ Complex data aggregation (TWAP, etc.)
✅ Maximum decentralization required

---

## Integration Best Practices

### ✅ DO

- **Cache prices** - Store latest price locally to minimize reads
- **Check staleness** - Verify `publish_time` before using price
- **Validate confidence** - Check confidence interval for accuracy
- **Use Hermes API** - Reliable, free price data service
- **Submit off-chain** - Bot submits updates, you execute transactions
- **Combine with Chainlink** - Use both for cross-oracle consensus

### ❌ DON'T

- **Trust price without staleness check** - Can be hours old
- **Ignore confidence interval** - Large spreads in volatile times
- **Rely on price in same transaction** - Need update in separate call
- **Assume price persists** - Updates expire after timeout

---

## Code Example: Safe Price Reading

```solidity
pragma solidity ^0.8.0;

import { PythStructs, IPyth } from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

contract SafePythIntegration {
    IPyth pyth = IPyth(0x4305FB0885e50B68C51267f502327f22dD0c4068);  // Ethereum
    bytes32 ETH_USD = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;

    uint256 constant PRICE_STALENESS_THRESHOLD = 60 seconds;
    uint256 constant MAX_PRICE_CHANGE_BPS = 1000;  // 10%

    function getPriceSafely() external view returns (uint256) {
        PythStructs.Price memory price = pyth.getPrice(ETH_USD);

        // Check 1: Price not negative
        require(price.price > 0, "Invalid price");

        // Check 2: Not stale
        require(
            block.timestamp - price.publish_time < PRICE_STALENESS_THRESHOLD,
            "Price stale"
        );

        // Check 3: Confidence acceptable
        require(
            uint64(price.conf) < uint64(price.price) / 100,  // < 1%
            "Confidence too low"
        );

        // Convert to 18 decimals
        if (price.expo >= 0) {
            return uint64(price.price) * 10 ** uint32(price.expo);
        } else {
            return uint64(price.price) / 10 ** uint32(-price.expo);
        }
    }
}
```

---

## Hermes API Usage

### Fetch Latest Prices

```bash
# Single feed
curl "https://hermes.pyth.network/api/latest_price_feeds?ids[]=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"

# Multiple feeds
curl "https://hermes.pyth.network/api/latest_price_feeds?ids[]=0xff61...&ids[]=0xab12..."
```

### Response Format

```json
{
  "parsed": [
    {
      "id": "0xff61...",
      "price": {
        "price": "320000000000",
        "conf": "1000000",
        "expo": -8,
        "publish_time": 1700000000
      }
    }
  ],
  "raw": {
    "vaa": "01..."  // Signed attestation for on-chain submission
  }
}
```

---

## Feed IDs (Common Pairs)

| Pair | Feed ID |
|------|---------|
| ETH/USD | 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace |
| BTC/USD | 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43 |
| SOL/USD | 0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8765c9ac0e3a41eacc87bf3e58 |
| USDC/USD | 0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a |
| USDT/USD | 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0d5b0d0e6eb7f10c9ec |

Full list: https://pyth.network/developers/price-feeds

---

## When to Reference Pyth

1. **Oracle Comparison** - Alternative to Chainlink with different tradeoffs
2. **Low-Frequency Liquidations** - On-demand price checks cheaper than Chainlink
3. **Multi-Chain Pricing** - Need consistent prices across chains
4. **High-Frequency Data** - 1s updates useful for bot strategies
5. **Cost Optimization** - ~99% cheaper than Chainlink push model

---

**Status:** Ready to integrate as oracle alternative
**Docs:** https://docs.pyth.network
**API:** https://hermes.pyth.network
