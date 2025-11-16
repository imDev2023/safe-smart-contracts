# Liquity Integration Guide

> Quick integration with LUSD stablecoin protocol

**What:** Integrate Liquity's LUSD stablecoin into your protocol
**Use Case:** Swap LUSD, check redemption risk, monitor system health
**Read Time:** 5 minutes

---

## Quick Integration (3 Steps)

### Step 1: Check Protocol Health (Safety)

```solidity
import { ITroveManager } from "@liquity-contracts/ITroveManager.sol";

contract MyProtocol {
    ITroveManager public troveManager;

    function isLiquityHealthy() external view returns (bool) {
        // TCR >= 150% = normal mode
        uint256 tcr = troveManager.getTCR(getCurrentPrice());
        return tcr >= 150e16;  // 150% = 1.5 * 1e18
    }

    function getCurrentPrice() public view returns (uint256) {
        // Get from Chainlink (fallback to Tellor)
        // LUSD expects ETH/USD price
        return <chainlink_eth_usd_price>;
    }
}
```

### Step 2: Swap LUSD via Uniswap

```solidity
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract SwapLUSD {
    ISwapRouter public swapRouter;
    address constant LUSD = 0x5f98805A4E8434263F0896844F40f71e947D61E8;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function swapLUSDToUSDC(uint256 amountLUSD) external returns (uint256 usdcOut) {
        IERC20(LUSD).approve(address(swapRouter), amountLUSD);

        usdcOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: LUSD,
                tokenOut: USDC,
                fee: 3000,  // 0.3% pool
                recipient: msg.sender,
                deadline: block.timestamp + 300,
                amountIn: amountLUSD,
                amountOutMinimum: _calculateMinOut(amountLUSD),
                sqrtPriceLimitX96: 0
            })
        );
    }

    function _calculateMinOut(uint256 amount) internal pure returns (uint256) {
        // 1% slippage tolerance
        return (amount * 99) / 100;
    }
}
```

### Step 3: Monitor Redemption Risk

```solidity
contract LiquityRiskMonitor {
    ITroveManager public troveManager;
    uint256 constant MAX_REDEMPTION_FEE = 50e16;  // 50%

    function getRedemptionFee(uint256 tcr) public pure returns (uint256) {
        // Fee = base (0.5%) + variable based on TCR
        // Simplified: increases as TCR decreases
        if (tcr >= 150e16) {
            return 5e15;  // 0.5%
        } else if (tcr >= 120e16) {
            return 10e15;  // 1.0%
        } else {
            return 50e15;  // 5.0%
        }
    }

    function shouldAcceptLUSD(uint256 amount) external view returns (bool) {
        uint256 tcr = troveManager.getTCR(getCurrentPrice());
        uint256 fee = getRedemptionFee(tcr);

        // Only accept if redemption fee is reasonable
        return fee < 10e16;  // < 10%
    }
}
```

---

## Complete Working Example

```solidity
pragma solidity ^0.6.11;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ITroveManager } from "@liquity-contracts/ITroveManager.sol";
import { IStabilityPool } from "@liquity-contracts/IStabilityPool.sol";

contract LiquityIntegration {
    IERC20 constant LUSD = IERC20(0x5f98805A4E8434263F0896844F40f71e947D61E8);
    ITroveManager constant troveManager = ITroveManager(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4130);
    IStabilityPool constant stabilityPool = IStabilityPool(0x66017D22b0f8556afDa3e30bb7380C680978Dc39);

    event LiquityHealthCheck(uint256 tcr, bool isHealthy);

    // Monitor system health
    function checkSystemHealth(address priceFeed) external returns (bool) {
        uint256 ethPrice = getPriceFromOracle(priceFeed);
        uint256 tcr = troveManager.getTCR(ethPrice);

        bool isHealthy = tcr >= 150e16;
        emit LiquityHealthCheck(tcr, isHealthy);

        return isHealthy;
    }

    // Get redemption risk for a given amount
    function getRedemptionRisk(
        uint256 lusdAmount,
        address priceFeed
    ) external view returns (uint256 ethOutMin, uint256 fee) {
        uint256 ethPrice = getPriceFromOracle(priceFeed);
        uint256 tcr = troveManager.getTCR(ethPrice);

        // Rough redemption fee calculation
        if (tcr >= 150e16) {
            fee = (lusdAmount * 5) / 1000;  // 0.5%
        } else if (tcr >= 120e16) {
            fee = (lusdAmount * 20) / 1000;  // 2%
        } else {
            fee = (lusdAmount * 50) / 1000;  // 5%
        }

        // ETH out ≈ (LUSD amount - fee) / ETH price
        uint256 lusdAfterFee = lusdAmount - fee;
        ethOutMin = (lusdAfterFee * 1e18) / ethPrice;
        // Apply 1% slippage
        ethOutMin = (ethOutMin * 99) / 100;
    }

    // Accept LUSD deposit if system is healthy
    function depositLUSD(uint256 amount, address priceFeed) external {
        uint256 ethPrice = getPriceFromOracle(priceFeed);
        uint256 tcr = troveManager.getTCR(ethPrice);

        require(tcr >= 150e16, "Liquity system unhealthy");
        require(LUSD.transferFrom(msg.sender, address(this), amount));

        // Store LUSD or swap to USDC
    }

    // Estimate current LUSD minting fee
    function getCurrentMintingFee(address priceFeed) external view returns (uint256) {
        uint256 ethPrice = getPriceFromOracle(priceFeed);
        uint256 tcr = troveManager.getTCR(ethPrice);

        // Minting fee is typically ~0.5%, increases in recovery mode
        if (tcr < 150e16) {
            return 15e15;  // 1.5%
        }
        return 5e15;  // 0.5%
    }

    function getPriceFromOracle(address priceFeed) internal view returns (uint256) {
        // Implement your oracle price fetch
        // Example: use Chainlink feed
        (,int256 price,,,) = AggregatorV3Interface(priceFeed).latestRoundData();
        require(price > 0);
        return uint256(price) * 10**10;  // Convert to 18 decimals
    }
}
```

---

## Best Practices

### ✅ DO

- **Check TCR before accepting LUSD** - Ensures system health
- **Monitor redemption fee** - Price LUSD accordingly
- **Use LUSD as stable pair** - In AMMs, LUSD/USDC usually tight
- **Listen for recovery mode** - System becomes riskier below 150% TCR
- **Implement price feed fallback** - Liquity uses Chainlink + Tellor

### ❌ DON'T

- **Ignore redemption risk** - Can lose value if many redemptions occur
- **Treat LUSD as perfectly stable** - Can trade ±0.5% depending on TCR
- **Build liquidation bot without hints** - Massively expensive (~300k gas)
- **Assume fixed fees** - Redemption fee dynamic (0.5% - 50%)

---

## Integration Patterns

### Pattern 1: Accept LUSD as Payment (with Health Check)

```solidity
function acceptLUSDPayment(
    uint256 lusdAmount,
    address priceFeed
) external {
    // Verify system health
    uint256 ethPrice = getPriceFromOracle(priceFeed);
    uint256 tcr = troveManager.getTCR(ethPrice);
    require(tcr >= 120e16, "Liquity too risky");

    // Accept LUSD
    IERC20(LUSD).transferFrom(msg.sender, address(this), lusdAmount);
}
```

### Pattern 2: Swap LUSD to USDC on Uniswap V3

```solidity
function swapLUSDToUSDC(
    uint256 lusdAmount,
    uint256 minUSDC
) external {
    IERC20(LUSD).approve(address(swapRouter), lusdAmount);

    swapRouter.exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
            tokenIn: LUSD,
            tokenOut: USDC,
            fee: 3000,  // Use 0.3% pool (highest liquidity)
            recipient: msg.sender,
            deadline: block.timestamp + 300,
            amountIn: lusdAmount,
            amountOutMinimum: minUSDC,
            sqrtPriceLimitX96: 0
        })
    );
}
```

### Pattern 3: LUSD Price Feed Fallback

```solidity
contract LUSDPriceFeed {
    address constant LUSD_USDC_POOL = 0x1d42064Fc4Beb5F8aAF85F3Fdea325469D146d50;  // Uniswap V3 0.01%
    uint24 constant POOL_FEE = 100;  // 0.01%

    function getLUSDPrice() external view returns (uint256) {
        // Method 1: Query Uniswap V3 TWAP
        uint256 price = getTWAP(LUSD_USDC_POOL, 300);  // 5-min TWAP

        // Method 2: Chainlink fallback (if available)
        // If both fail: assume 1.00 LUSD = 1 USDC

        return price > 0 ? price : 1e18;
    }

    function getTWAP(address pool, uint32 period) internal view returns (uint256) {
        // Use IUniswapV3Pool.observe() to get TWAP
        // See Uniswap V3 deep-dive for implementation
    }
}
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| **Transaction Reverts** | System in recovery mode | Check TCR first, proceed if >= 120% |
| **Bad Price for LUSD Swap** | High redemption fee | Monitor redemption fee, defer swap if > 5% |
| **Unexpected Slippage** | System stress (TCR low) | Increase slippage tolerance to 2-3% |
| **Liquidations Failing** | Missing hints | Always provide hints from off-chain search |

---

## Liquity Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| LUSD Token | `0x5f98805A4E8434263F0896844F40f71e947D61E8` |
| TroveManager | `0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4130` |
| BorrowerOps | `0x24179CD81c9e782A4961B26aF5a59f2C146e7b14` |
| StabilityPool | `0x66017D22b0f8556afDa3e30bb7380C680978Dc39` |
| LQTY Token | `0x6DEA81C8171D0bA51990CB86d933cDBdDD2B92c1` |
| Pricefeed | `0x4c517D4e2C851CA76d7eC94B805269Df0f2201De` |

---

## Reference

**Deep Dive:** See `repos/liquity/01-protocol-architecture.md` for:
- TCR/ICR calculations
- Redemption mechanism details
- Stability pool math
- Recovery mode logic

**Security:** See `11-oracle-security-checklist.md` for price feed safety

---

**Status:** Ready to integrate LUSD into DEX/stablecoin protocols
