# Chainlink Data Feed Integration Guide

> Step-by-step integration of Chainlink price feeds (5 min read)

## Quick Integration (3 steps)

### Step 1: Import Interface
```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        // ETH/USD on Ethereum mainnet
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }
}
```

### Step 2: Fetch Latest Price
```solidity
function getLatestPrice() public view returns (uint256) {
    (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();

    // Validate price is fresh (not stale)
    require(block.timestamp - updatedAt < 1 hours, "Price too old");

    // Convert to 18 decimals (Chainlink uses 8)
    return uint256(price) * 10**10;
}
```

### Step 3: Use In Your Protocol
```solidity
function swapWithPriceProtection(uint256 tokenAmount) external {
    uint256 ethPrice = getLatestPrice();
    uint256 minOutput = (tokenAmount * ethPrice) / 100; // 1% slippage

    // Your swap logic here
    uniswapRouter.swapExactTokensForTokens(
        tokenAmount,
        minOutput,  // Protected by Chainlink price
        path,
        msg.sender,
        block.timestamp
    );
}
```

## Feed Address Lookup

### Ethereum Mainnet
```
ETH/USD:  0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
BTC/USD:  0xF4030086dA0D855c2C51EB4Eff1ab1AFAE72C51F
USDC/USD: 0x8fFfFfd4AfB6115b954Bd29bda9424015F7C1EB6
DAI/USD:  0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1235
```

### Arbitrum
```
ETH/USD:  0x639Fe6ab55C921f74e7fac19EEa543D3497e63A8
BTC/USD:  0x6550bc2bE56603510962200243A249FB32fEb11
USDC/USD: 0x50834F3e0744f40f628f86e6a7F30f0D4d71f5d5
```

### Polygon
```
ETH/USD:  0xF9680D99D6C9589e2a93a78A04A279e387394313
BTC/USD:  0xDE31F8bFBD8c84b5360CFACCa3539B938dd24C0D
USDC/USD: 0xfE4161d60edd064A04631Db0F81Ff20FaD5957cF
```

**Full address list**: https://docs.chain.link/data-feeds/price-feeds/addresses

## Complete Working Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StableSwap {
    AggregatorV3Interface public ethPriceFeed;
    AggregatorV3Interface public btcPriceFeed;

    mapping(address => uint256) public maxDeviation; // Max 2% = 200

    event PriceChecked(uint256 ethPrice, uint256 btcPrice);

    constructor(address _ethFeed, address _btcFeed) {
        ethPriceFeed = AggregatorV3Interface(_ethFeed);
        btcPriceFeed = AggregatorV3Interface(_btcFeed);
        maxDeviation[address(this)] = 200; // 2%
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 price, , uint256 updatedAt, ) = ethPriceFeed.latestRoundData();
        require(block.timestamp - updatedAt < 1 hours, "ETH price stale");
        return uint256(price) * 10**10; // Convert to 18 decimals
    }

    function getBTCPrice() public view returns (uint256) {
        (, int256 price, , uint256 updatedAt, ) = btcPriceFeed.latestRoundData();
        require(block.timestamp - updatedAt < 1 hours, "BTC price stale");
        return uint256(price) * 10**10;
    }

    function swap(uint256 ethAmount) external returns (uint256) {
        uint256 ethPrice = getETHPrice();
        uint256 btcPrice = getBTCPrice();

        uint256 ethInUSD = (ethAmount * ethPrice) / 1e18;
        uint256 btcOut = (ethInUSD * 1e18) / btcPrice;

        emit PriceChecked(ethPrice, btcPrice);
        return btcOut;
    }
}
```

## Best Practices

### ✅ DO:
```solidity
// 1. Check price freshness
require(block.timestamp - updatedAt < maxDelay, "Price too old");

// 2. Check for zero price
require(price > 0, "Invalid price");

// 3. Add fallback oracle
if (priceFeedPrimary.sequencerUp() == false) {
    return priceFeedFallback.latestPrice();
}

// 4. Use TWAP as secondary check
uint256 twapPrice = getTWAPPrice();
require(price < twapPrice * 1.02, "Price deviation too high");
```

### ❌ DON'T:
```solidity
// 1. Don't trust latest price without staleness check
uint256 price = priceFeed.latestPrice(); // ⚠️ Could be 1 hour old

// 2. Don't ignore zero prices
// On network outages, Chainlink can return stale prices

// 3. Don't use only Chainlink
// Single oracle is a single point of failure

// 4. Don't convert price incorrectly
// Chainlink uses 8 decimals, not 18!
```

## Common Issues & Solutions

### Issue: "Price Aggregator Unavailable"
```
Cause: Sequencer down on L2 (Arbitrum, Optimism)
Fix:   Check sequencer status before using price
```

```solidity
function isSequencerUp() internal view returns (bool) {
    AggregatorV3Interface sequencerFeed =
        AggregatorV3Interface(0x...(sequencer health address));
    (, int256 answer, , uint256 updatedAt, ) = sequencerFeed.latestRoundData();
    require(answer == 1, "Sequencer down");
    require(block.timestamp - updatedAt < 60 seconds, "Sequencer status stale");
    return true;
}
```

### Issue: "Price Too Old"
```
Cause: Chainlink stopped updating (protocol issue, feed misconfiguration)
Fix:   Implement multi-oracle fallback
```

### Issue: "Flash Loan Price Manipulation"
```
Cause: Chainlink can be manipulated if it only uses DEX prices
Fix:   Chainlink uses on-chain and off-chain sources (resistant)
       Use TWAP as secondary check
```

## Testing

```solidity
// Mock for testing
contract MockPriceFeed is AggregatorV3Interface {
    int256 public mockPrice = 2000e8;
    uint256 public mockTimestamp;

    function setPrice(int256 _price) external {
        mockPrice = _price;
        mockTimestamp = block.timestamp;
    }

    function latestRoundData() external view returns (
        uint80, int256, uint256, uint256, uint80
    ) {
        return (0, mockPrice, 0, mockTimestamp, 0);
    }
}
```

---

**For randomness**: See `08-chainlink-vrf-integration.md`
**For automation**: See `09-chainlink-automation-integration.md`
**Deep dive**: See `knowledge-base-research/repos/chainlink/11-chainlink-oracle-deep-dive.md`
