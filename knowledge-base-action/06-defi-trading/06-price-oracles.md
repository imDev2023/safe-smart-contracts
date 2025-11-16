# Price Oracles for Trading & DeFi

**Status:** Essential Integration Guide | **Level:** Intermediate-Advanced | **Safety:** Critical

## The Oracle Problem

**"The Oracle Problem"**: Blockchain can't access real-world data (prices, weather, etc.) directly.

### Issue: Price Manipulation

```
Without proper oracle:

Attacker uses flash loan:
1. Borrow $50M from lending pool
2. Buy token in Uniswap (moves price up 20%)
3. Protocol reads inflated price from same DEX
4. Uses inflated price for liquidations
5. Liquidate victims at unfair prices
6. Keep the MEV, repay loan + fee

Result: $34M+ profit (Harvest Finance attack, 2020)

Solution: Use time-weighted average price (TWAP) or trusted oracle
```

---

## Oracle Types & Trade-offs

### Type 1: Decentralized Exchange (DEX) Prices

**Source:** On-chain DEX reserves

```solidity
contract DEXOracle {
    // Price from Uniswap directly
    function getPrice(
        address tokenA,
        address tokenB,
        uint amountA
    ) external view returns (uint amountB) {
        // Query Uniswap V3 pool
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(tokenA, tokenB, 3000)  // 0.30% fee tier
        );

        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        // Calculate price from sqrtPrice
        // Math: amountB = amountA * (sqrtPrice / 2^96)^2
        // Simplified: Use Uniswap's QuoterV2

        // Problems:
        // ❌ Single block snapshot vulnerable to flash attacks
        // ❌ Can be manipulated with large swaps
        // ❌ Doesn't account for time
    }
}
```

**Pros:**
- Decentralized, no trusted intermediary
- Real-time, responsive to markets
- Multiple DEX options create competition

**Cons:**
- Vulnerable to flash loan attacks
- Susceptible to large position manipulation
- Requires gas to query

### Type 2: Time-Weighted Average Price (TWAP)

**Source:** On-chain DEX prices over time

```solidity
contract TWAPOracle {
    // Uniswap V3 provides accumulated prices
    // Compute average over time period

    function getTWAP(
        address pool,
        uint32 timeWindow
    ) external view returns (uint256 twap) {
        // Get current cumulative price
        (, , , , , , uint256 observationIndex, uint256 cardinality) = IUniswapV3Pool(pool).slot0();

        // Get historical observation
        (uint32 blockTimestamp, uint256 tickCumulative, , ) =
            IUniswapV3Pool(pool).observations((observationIndex + 1) % cardinality);

        // TWAP is average tick over timeWindow
        uint256 tickCumulativeNew = IUniswapV3Pool(pool).tickCumulative(block.timestamp - timeWindow);

        uint256 tickAverage = (tickCumulativeNew - tickCumulative) / int256(timeWindow);

        // Convert tick to price
        // price = 1.0001^tick
        // Uniswap provides: sqrtPrice = 1.0001^(tick/2)

        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(int24(tickAverage));

        // Convert sqrtPrice to price
        twap = (uint256(sqrtPrice) ** 2) / (2 ** 96);

        return twap;
    }

    // Benefits:
    // ✅ Immune to single-block manipulation
    // ✅ Flash loan attacks impossible
    // ✅ Time-averaged = smooths volatility
    // ✅ Decentralized

    // Drawbacks:
    // ❌ Delayed price discovery (1 hour+ lag)
    // ❌ Still vulnerable to sustained attacks
    // ❌ Requires historical observation data
}
```

**Use Case:** Liquidations, collateral valuation, long-term pricing

### Type 3: Centralized Price Feeds (Chainlink)

**Source:** Off-chain price data from aggregated sources

```solidity
contract ChainlinkOracle {
    AggregatorV3Interface internal priceFeed;

    constructor(address feedAddress) {
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Validations
        require(answeredInRound >= roundID, "Stale price");
        require(price > 0, "Invalid price");
        require(timeStamp > 0, "Timestamp invalid");
        require(
            block.timestamp - timeStamp <= 1 hours,
            "Price too old"
        );

        return uint256(price);
    }

    // Benefits:
    // ✅ Decentralized aggregation (multiple data sources)
    // ✅ Professional data providers
    // ✅ Real-time pricing
    // ✅ Battle-tested (Aave, Compound rely on it)

    // Risks:
    // ❌ Depends on Chainlink validator set
    // ❌ Can be delayed by network issues
    // ❌ Requires feed subscription costs
    // ❌ Single feed single point of failure
}
```

**Use Case:** Lending protocols, options pricing, liquidations

### Type 4: Hybrid Oracle (TWAP + Chainlink)

**Concept:** Use both for robustness

```solidity
contract HybridOracle {
    AggregatorV3Interface chainlinkFeed;
    IUniswapV3Pool uniswapPool;

    function getPriceWithFallback() external view returns (uint256) {
        // 1. Try Chainlink first (cheapest, most reliable)
        try this.getChainlinkPrice() returns (uint256 price) {
            return price;
        } catch {
            // 2. Fallback to TWAP if Chainlink fails
            return getTWAPPrice();
        }
    }

    function getChainlinkPrice() internal view returns (uint256) {
        (uint80 roundID, int256 price, , uint256 timeStamp, uint80 answeredInRound) =
            chainlinkFeed.latestRoundData();

        require(answeredInRound >= roundID, "Stale data");
        require(timeStamp > block.timestamp - 1 hours, "Too old");
        require(price > 0, "Invalid price");

        return uint256(price);
    }

    function getTWAPPrice() internal view returns (uint256) {
        // TWAP calculation from Uniswap V3
        // See previous example
        return 0;  // Simplified
    }

    // Benefits:
    // ✅ Reliability: Chainlink with TWAP fallback
    // ✅ Resilience: If one fails, use other
    // ✅ Best of both worlds
    // ✅ Attacks harder to coordinate

    // Cost:
    // - Chainlink subscription + gas
    // - Slightly higher gas (fallback logic)
}
```

---

## Chainlink Integration (Comprehensive Guide)

### Basic Data Feed Integration

```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceFeed {
    AggregatorV3Interface public dataFeed;

    constructor() {
        // Polygon mainnet: MATIC/USD
        dataFeed = AggregatorV3Interface(0xAB594600146Bf17C3B631f89ED7ca36B81119e43);
    }

    function getLatestPrice() public view returns (uint256) {
        // prettier-ignore
        (
            uint80 roundID,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();

        // Check data is fresh
        require(
            block.timestamp - updatedAt <= 1 hours,
            "Stale price"
        );

        // Check round completed
        require(answeredInRound >= roundID, "Incomplete round");

        // Return positive price (cast from int256)
        return uint256(answer);
    }

    function getDecimalPlaces() public view returns (uint8) {
        return dataFeed.decimals();
    }

    // Polygon Chainlink feeds:
    // MATIC/USD: 0xAB594600146Bf17C3B631f89ED7ca36B81119e43
    // ETH/USD: 0x0715A7794a1dc8e42615F059dD6e406A6A0d69d0
    // USDC/USD: 0xfE4A8cc5b5B2366BA244cdFF3D5de6339a297495
    // USDT/USD: 0x0A6513e40db6eb1b165753AD52E80663aeA50545
}
```

### Chainlink Automation (Keeper Network)

```solidity
// Automatically update prices or trigger liquidations

import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract KeeperPriceUpdater is AutomationCompatible {
    uint256 public lastUpdateTime;
    uint256 public updateInterval = 1 hours;

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        // Check if update needed
        upkeepNeeded = (block.timestamp - lastUpdateTime) > updateInterval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // Chainlink keeper calls this automatically
        if ((block.timestamp - lastUpdateTime) > updateInterval) {
            lastUpdateTime = block.timestamp;
            updateAllPrices();  // Your implementation
        }
    }

    // Benefits:
    // ✅ Automatic price updates
    // ✅ Liquidations triggered automatically
    // ✅ No manual intervention needed
    // ✅ Decentralized (keeper network)
}
```

### Chainlink SVR Feeds (OEV Mitigation)

```solidity
// Shared Value Recapture (SVR) feeds capture MEV for users

contract SVRFeedIntegration {
    // Standard Chainlink feed
    AggregatorV3Interface standardFeed;

    // SVR-enabled feed (captures OEV)
    IFeeManager feeManager;
    IEACAggregatorProxy svrFeed;

    function getPriceWithOEV() external view returns (uint256) {
        // SVR feeds automatically:
        // 1. Capture MEV from liquidations
        // 2. Redistribute to users
        // 3. Improve price quality

        // Using SVR feed:
        (uint80 roundID, int256 price, , uint256 timeStamp, ) =
            svrFeed.latestRoundData();

        require(
            block.timestamp - timeStamp <= 30 minutes,
            "Stale SVR price"
        );

        return uint256(price);
    }

    // SVR Benefits:
    // ✅ MEV captured and returned to users
    // ✅ Better liquidation prices
    // ✅ Reduced slippage
    // ✅ Protocol-level fairness
}
```

---

## Oracle Attack Vectors & Mitigations

### Attack 1: Stale Price Data

```solidity
// ❌ VULNERABLE
function depositCollateral(uint amount) external {
    uint price = oracle.getPrice();  // What if last update was 2 hours ago?
    uint value = amount * price;
    collateral[msg.sender] += value;
}

// ✅ PROTECTED
function depositCollateral(uint amount) external {
    (uint price, uint timestamp) = oracle.getPriceWithTimestamp();

    require(
        block.timestamp - timestamp <= 1 hours,
        "Price too old"
    );

    uint value = amount * price;
    collateral[msg.sender] += value;
}
```

### Attack 2: Flash Loan Price Spike

```solidity
// ❌ VULNERABLE
function liquidate(address account) external {
    uint price = uniswapPool.getPrice();  // Current price (flashable)
    uint debt = debts[account];

    if (debt * price / collateral[account] > 150%) {
        executeL iquidation();  // Attacker can move price with flash loan!
    }
}

// ✅ PROTECTED: Use TWAP
function liquidate(address account) external {
    uint price = oracle.getTWAPPrice();  // 1-hour average (not flashable)
    uint debt = debts[account];

    if (debt * price / collateral[account] > 150%) {
        executeL iquidation();  // Safe from flash attacks
    }
}
```

### Attack 3: Multiple Feed Manipulation

```solidity
// ❌ VULNERABLE: Single feed
contract BadOracle {
    AggregatorV3Interface feed;

    function getPrice() external view returns (uint256) {
        (uint80 roundID, int256 price, , , uint80 answeredInRound) =
            feed.latestRoundData();
        return uint256(price);
    }
    // If feed is compromised, entire protocol fails
}

// ✅ PROTECTED: Multiple feeds with consensus
contract GoodOracle {
    AggregatorV3Interface[3] feeds;  // 3 independent feeds

    function getPrice() external view returns (uint256) {
        uint256[] memory prices = new uint256[](3);

        for (uint i = 0; i < 3; i++) {
            (uint80 roundID, int256 price, , uint256 timeStamp, ) =
                feeds[i].latestRoundData();

            require(block.timestamp - timeStamp <= 1 hours, "Stale");
            prices[i] = uint256(price);
        }

        // Return median of 3 feeds
        return median(prices);
    }

    function median(uint256[] memory prices) internal pure returns (uint256) {
        // Sort and return middle value
        // Attacks need to compromise 2/3 feeds
    }
}
```

---

## Safe Oracle Patterns

### Pattern 1: Price with Confidence Interval

```solidity
contract ConfidentOracle {
    struct PriceData {
        uint256 price;
        uint256 confidence;  // ±% deviation
        uint256 timestamp;
    }

    function getPriceWithConfidence() external view returns (PriceData memory) {
        uint256 price = getFeedPrice();
        uint256 confidence = calculateConfidence();  // Based on update frequency, etc.
        uint256 timestamp = block.timestamp;

        return PriceData(price, confidence, timestamp);
    }

    function isConfidentPrice(uint256 confidenceThreshold) external view returns (bool) {
        PriceData memory data = getPriceWithConfidence();
        return data.confidence <= confidenceThreshold;  // ±0.1%
    }
}
```

### Pattern 2: Price Range Validation

```solidity
contract RangeValidatedOracle {
    uint256 public minPrice = 1 * 10**18;  // $1
    uint256 public maxPrice = 10000 * 10**18;  // $10,000

    function getPriceWithValidation() external view returns (uint256) {
        uint256 price = oracle.getPrice();

        require(price >= minPrice && price <= maxPrice, "Price out of range");

        // Additional check: Compare to historical average
        uint256 historicalAvg = getHistoricalAverage(24 hours);
        uint256 maxDeviation = (historicalAvg * 20) / 100;  // ±20%

        require(
            price >= historicalAvg - maxDeviation &&
            price <= historicalAvg + maxDeviation,
            "Price moved too far"
        );

        return price;
    }
}
```

### Pattern 3: Oracle Aggregation

```solidity
contract AggregateOracle {
    AggregatorV3Interface[] feeds;
    string[] feedNames;

    constructor(address[] memory _feeds, string[] memory _names) {
        // Register multiple feeds
        for (uint i = 0; i < _feeds.length; i++) {
            feeds.push(AggregatorV3Interface(_feeds[i]));
            feedNames.push(_names[i]);
        }
    }

    function getPriceFromAggregation() external view returns (uint256) {
        uint256[] memory prices = new uint256[](feeds.length);

        for (uint i = 0; i < feeds.length; i++) {
            (uint80 roundID, int256 price, , uint256 timeStamp, ) =
                feeds[i].latestRoundData();

            require(block.timestamp - timeStamp <= 1 hours, "Stale");
            prices[i] = uint256(price);
        }

        // Median of aggregated prices
        return median(prices);
    }

    function getWeightedPrice() external view returns (uint256) {
        // Alternative: Weighted average based on feed reliability
        // feeds[0]: Chainlink (40% weight - most reliable)
        // feeds[1]: Uniswap TWAP (30% weight)
        // feeds[2]: Balancer TWAP (30% weight)

        uint256 price1 = getFeedPrice(0);
        uint256 price2 = getFeedPrice(1);
        uint256 price3 = getFeedPrice(2);

        return (price1 * 40 + price2 * 30 + price3 * 30) / 100;
    }
}
```

---

## Oracle Integration Checklist

- [ ] Using Chainlink Data Feeds for primary pricing?
- [ ] Freshness check implemented (staleness timeout)?
- [ ] Round completion validation?
- [ ] Multiple feeds used (3+ for critical protocols)?
- [ ] TWAP for liquidation pricing?
- [ ] Price range validation in place?
- [ ] Historical average comparison?
- [ ] Flash loan immunity verified?
- [ ] Fallback oracle if primary fails?
- [ ] Heartbeat monitoring (Chainlink)?
- [ ] Deviation threshold configured?
- [ ] Tests cover stale price scenarios?
- [ ] Tests cover flash loan scenarios?
- [ ] Monitor for unusual price movements?
- [ ] Admin pause if price feed anomalies?

---

## Available Chainlink Feeds

### Polygon Mainnet

| Pair | Address | Decimals |
|------|---------|----------|
| **MATIC/USD** | 0xAB594600146Bf17C3B631f89ED7ca36B81119e43 | 8 |
| **ETH/USD** | 0x0715A7794a1dc8e42615F059dD6e406A6A0d69d0 | 8 |
| **USDC/USD** | 0xfE4A8cc5b5B2366BA244cdFF3D5de6339a297495 | 8 |
| **USDT/USD** | 0x0A6513e40db6eb1b165753AD52E80663aeA50545 | 8 |
| **DAI/USD** | 0x4746DeC9e833A82EC7C2C1356372CcF2cfEA8c0D | 8 |
| **WBTC/USD** | 0xde31F8bFBD8c84b5360CFACCa3539B938dd24CB57 | 8 |

### Ethereum Mainnet

| Pair | Address |
|------|---------|
| **ETH/USD** | 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419 |
| **USDC/USD** | 0x8ffffd4afb6115b954bd242c08fce4cc3573e9b9 |
| **USDT/USD** | 0x3e7d1eab13ad0104d2750b8863b489d65364e32d |
| **DAI/USD** | 0xaed0c38402a5d19df6e4c03f4e2dced6e378c21f |

---

## Resources

- **Chainlink Docs**: https://docs.chain.link/data-feeds
- **Chainlink SVR Feeds**: https://docs.chain.link/data-feeds/sv-feeds
- **Chainlink Automation**: https://docs.chain.link/chainlink-automation
- **Uniswap TWAP**: https://docs.uniswap.org/concepts/core-concepts/oracles

---

**Next:** Read `07-trading-bot-security.md` for automated trading safety patterns.
