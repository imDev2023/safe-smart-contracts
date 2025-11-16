# Slippage Protection Mechanisms

**Status:** Critical Security Guide | **Level:** Intermediate | **Risk Level:** HIGH

## What is Slippage?

**Slippage** = Difference between expected execution price and actual execution price.

### Types of Slippage

#### 1. **Price Impact Slippage** (Algorithmic)
The larger your trade relative to pool size, the worse your price.

```
Pool: 1000 ETH : 2,000,000 USDC (k = 2B)

Trade 1: 1 ETH
- Before: 1 ETH = 2000 USDC
- Formula: 2,000,000,000 / 1001 = 1,998,002
- You get: 2000 - 2 = 1998 USDC
- Slippage: 0.1% (acceptable)

Trade 2: 100 ETH
- Before: 100 ETH = 200,000 USDC
- Formula: 2,000,000,000 / 1100 = 1,818,182
- You get: 2,000,000 - 1,818,182 = 181,818 USDC
- Price per ETH: 181,818 / 100 = 1,818 USDC
- Slippage: 9.1% (bad!)

Trade 3: 500 ETH
- Formula: 2,000,000,000 / 1500 = 1,333,333
- You get: 666,667 USDC
- Price per ETH: 1,333.33 USDC
- Slippage: 33.3% (catastrophic!)
```

#### 2. **Volatility Slippage** (Market Conditions)
Price moves between transaction creation and execution.

```
You create swap transaction:
- Pool state: 1000 ETH, 2M USDC
- Expected output: 1998 USDC
- Your amountMin: 1900 USDC

12 seconds later (before block inclusion):
- Whale ETH deposit: 5000 ETH
- Pool now: 6000 ETH, 2M USDC
- Your output now: 333 USDC (catastrophic!)
- Your protection saves you: ✅ Transaction reverts
```

#### 3. **MEV Slippage** (Sandwich Attacks)
Attacker frontruns and backruns your transaction.

```
You broadcast: "Swap 100 USDC → 0.05 ETH"

Attacker's MEV:
1. Frontr un: Swap 50 ETH → 1M USDC (moves price against you)
2. Your swap: Now get worse price (0.03 ETH instead of 0.05)
3. Backrun: Swap 1M USDC → 100 ETH (exits the attack)

Attacker profit: ~3 ETH
Your loss: 0.02 ETH + gas

Graph:
                   /\
              Attacker peak
            /      \/
          /        Your swap
        /
```

---

## Slippage Protection Mechanisms

### 1. **AmountMin / AmountOutMin**

The most critical protection: specify minimum acceptable output.

```solidity
// Bad: No protection
uint[] memory amounts = router.swapExactTokensForTokens(
    100 ether,           // amountIn
    0,                   // amountOutMin ❌ ACCEPTS ANYTHING
    path,
    msg.sender,
    deadline
);

// Result: Sandwich attack takes 50% of your value!
```

```solidity
// Good: Protected
uint expectedOut = getAmountsOut(100 ether, path)[path.length - 1];
uint minOut = (expectedOut * 99) / 100;  // 1% slippage buffer

uint[] memory amounts = router.swapExactTokensForTokens(
    100 ether,
    minOut,              // amountOutMin ✅ PROTECTED
    path,
    msg.sender,
    deadline
);

// Result: Transaction reverts if MEV tries to take >1%
```

### 2. **Deadline**

Prevent stale transactions from executing in future blocks.

```solidity
// Bad: No deadline
router.swapExactTokensForTokens(
    100 ether,
    minOut,
    path,
    msg.sender,
    type(uint256).max    // ❌ NEVER EXPIRES
);

// Scenario:
// 1. You broadcast transaction
// 2. Block is full, queued for next block
// 3. ETH price drops 10% overnight
// 4. Your old tx executes, terrible price
```

```solidity
// Good: Deadline set
router.swapExactTokensForTokens(
    100 ether,
    minOut,
    path,
    msg.sender,
    block.timestamp + 600  // ✅ EXPIRES IN 10 MINUTES
);

// If not included in 10 minutes: Transaction reverts
```

### 3. **Multi-Hop Routing**

Smart routing reduces slippage on illiquid pairs.

```solidity
// Direct path (bad liquidity)
// BAT → USDC
// Small liquidity = 20% slippage

// Multi-hop path (better)
// BAT → ETH → USDC
// Each hop has deep liquidity = 2% + 1% = 3% slippage

// Algorithm checks multiple paths:
// 1. BAT → USDC (20%)
// 2. BAT → USDT → USDC (15%)
// 3. BAT → ETH → USDC (3%) ✅ CHOSEN
// 4. BAT → WETH → ETH → USDC (too many hops)
```

```solidity
interface IUniswapV3Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMinimum,
        bytes calldata path,  // Encoded route with fee tiers
        address recipient,
        uint deadline
    ) external payable returns (uint amountOut);
}

// V3 path encodes: token0 (20 bytes) + fee (3 bytes) + token1 + fee + token2
// Example: USDC (0.05%) USDT (0.01%) USDC
```

---

## Advanced Slippage Calculation Patterns

### Pattern 1: Dynamic Slippage Based on Volatility

```solidity
contract DynamicSlippageRouter {
    // High volatility = higher slippage tolerance needed
    function swapWithDynamicSlippage(
        uint amountIn,
        address[] memory path,
        uint minSlippageBps,  // Minimum in basis points (1 = 0.01%)
        uint maxSlippageBps
    ) external {
        // 1. Calculate expected output
        uint[] memory amounts = router.getAmountsOut(amountIn, path);
        uint expectedOut = amounts[amounts.length - 1];

        // 2. Measure current volatility
        uint volatility = calculateVolatility(path[0], path[path.length - 1]);

        // 3. Dynamically adjust slippage
        uint adjustedSlippageBps = minSlippageBps + (volatility / 100);
        require(adjustedSlippageBps <= maxSlippageBps, "Volatility too high");

        uint minOut = (expectedOut * (10000 - adjustedSlippageBps)) / 10000;

        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            msg.sender,
            block.timestamp + 300
        );
    }

    function calculateVolatility(
        address token0,
        address token1
    ) internal view returns (uint) {
        // Simplified: measure 24h price variance
        // Real implementation: use Chainlink or TWAP oracle
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(token0, token1, 3000));

        uint24[] memory timeWeights = new uint24[](6);
        uint[] memory prices = new uint[](6);

        for (uint i = 0; i < 6; i++) {
            // Query historical prices
            prices[i] = getHistoricalPrice(pool, i * 4 hours);
        }

        // Calculate variance
        uint variance = 0;
        uint meanPrice = calculateMean(prices);

        for (uint i = 0; i < prices.length; i++) {
            uint diff = prices[i] > meanPrice ? prices[i] - meanPrice : meanPrice - prices[i];
            variance += (diff * diff);
        }

        return variance / prices.length;
    }
}
```

### Pattern 2: Slippage Protected Batch Swaps

```solidity
contract BatchSwap {
    struct SwapOrder {
        uint amountIn;
        address[] path;
        uint minAmountOut;
        address recipient;
    }

    function executeBatchSwaps(
        SwapOrder[] calldata orders
    ) external {
        require(orders.length > 0, "No swaps");

        for (uint i = 0; i < orders.length; i++) {
            // Each swap protected individually
            router.swapExactTokensForTokens(
                orders[i].amountIn,
                orders[i].minAmountOut,  // Individual slippage protection
                orders[i].path,
                orders[i].recipient,
                block.timestamp + 300
            );

            emit SwapExecuted(i, orders[i].amountIn, orders[i].minAmountOut);
        }
    }

    // Gas optimized: Calculate all minimums first
    function calculateBatchMinimums(
        SwapOrder[] calldata orders,
        uint slippageBps  // Single slippage for all
    ) external view returns (uint[] memory minimums) {
        minimums = new uint[](orders.length);

        for (uint i = 0; i < orders.length; i++) {
            uint[] memory amounts = router.getAmountsOut(
                orders[i].amountIn,
                orders[i].path
            );

            uint expectedOut = amounts[amounts.length - 1];
            minimums[i] = (expectedOut * (10000 - slippageBps)) / 10000;
        }

        return minimums;
    }
}
```

### Pattern 3: Time-Weighted Slippage Adjustment

```solidity
contract TimeWeightedSwap {
    mapping(address => uint256) lastSwapTime;

    function swapWithTimeWeighting(
        uint amountIn,
        address[] memory path,
        address account
    ) external {
        uint timeSinceLastSwap = block.timestamp - lastSwapTime[account];

        // More recent activity = tighter slippage tolerance
        uint slippageBps;
        if (timeSinceLastSwap < 60) {
            slippageBps = 10;  // 0.10% - back-to-back swaps are risky
        } else if (timeSinceLastSwap < 300) {
            slippageBps = 25;  // 0.25%
        } else if (timeSinceLastSwap < 3600) {
            slippageBps = 50;  // 0.50%
        } else {
            slippageBps = 100; // 1.00% - safe, can be more aggressive
        }

        uint[] memory amounts = router.getAmountsOut(amountIn, path);
        uint expectedOut = amounts[amounts.length - 1];
        uint minOut = (expectedOut * (10000 - slippageBps)) / 10000;

        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            msg.sender,
            block.timestamp + 300
        );

        lastSwapTime[account] = block.timestamp;
    }
}
```

---

## Critical Slippage Scenarios

### ⚠️ Scenario 1: Flash Loan Attack During Swap

```solidity
// Attacker executes:
function flashLoanAttack(address pool, uint swapTarget) external {
    // 1. Borrow huge amount from flash loan provider
    lender.flashLoan(address(this), TOKEN, amount, data);
}

function executeOperation(
    address asset,
    uint256 amount,
    uint256 fee,
    address initiator,
    bytes calldata data
) external override returns (bytes32) {
    // 2. Dump token into target pool (massive slippage)
    pool.swap(amount);  // This moves price dramatically

    // 3. Victim's transaction executes at terrible price
    // 4. Attacker recovers loan + fee, pockets the difference

    return keccak256("ERC3156FlashBorrower.onFlashLoan");
}
```

**Protection:**
```solidity
// Use internal balance check before + after
function protectedSwap(uint amountIn, address[] memory path, uint minOut) external {
    uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));

    router.swapExactTokensForTokens(amountIn, minOut, path, address(this), deadline);

    uint balanceAfter = IERC20(path[path.length - 1]).balanceOf(address(this));
    uint actualOut = balanceAfter - balanceBefore;

    require(actualOut >= minOut, "Slippage exceeded");
}
```

### ⚠️ Scenario 2: MEV Sandwich on Large Order

```
Mempool: Your 1000 ETH swap (small DEX, poor liquidity)

Attacker sees:
- Will cause 30% slippage (normal for size)
- Front-runs: 500 ETH swap (pushes price further)
- Your swap executes: Gets 20% less ETH
- Back-runs: Exits with profit

Your slippage: 30% → 50% (-20% MEV extraction)
Your loss: $500,000+

Protection:
- Split into multiple swaps over time
- Use private mempool services (Flashbots)
- Use intent-based architecture (UniswapX)
```

---

## Slippage Protection Checklist

- [ ] All external swaps specify `amountOutMin` or equivalent?
- [ ] All transactions have `deadline` set?
- [ ] Slippage tolerance appropriate for liquidity depth?
- [ ] Multi-hop routing optimized?
- [ ] Flash loan attacks considered?
- [ ] MEV protection in place (Flashbots, MEV-Burn, etc.)?
- [ ] Volatility monitoring active?
- [ ] Tests cover sandwich attack scenarios?
- [ ] Emergency pause mechanism if slippage exceeds threshold?
- [ ] Admin can adjust slippage parameters?

---

## Slippage Calculation Reference

```solidity
/**
 * Uniswap V2 Slippage Formula
 *
 * Given: amountIn, reserveIn, reserveOut, fee (0.3%)
 *
 * amountInWithFee = amountIn * 997 (0.3% fee)
 * numerator = amountInWithFee * reserveOut
 * denominator = (reserveIn * 1000) + amountInWithFee
 * amountOut = numerator / denominator
 *
 * Slippage% = ((expectedPrice - actualPrice) / expectedPrice) * 100
 *           = ((amountIn / reserveIn) - (amountOut / amountIn)) / (amountIn / reserveIn)
 */

function getSlippagePercentage(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) public pure returns (uint slippageBps) {
    // Theoretical price without slippage
    uint theoreticalOut = (amountIn * reserveOut) / reserveIn;

    // Actual output with slippage
    uint amountInWithFee = amountIn * 997 / 1000;
    uint actualOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);

    // Slippage = (theoretical - actual) / theoretical
    slippageBps = ((theoreticalOut - actualOut) * 10000) / theoreticalOut;

    return slippageBps;
}
```

---

## Tools & Services for Slippage Prevention

| Tool | Purpose | Use Case |
|------|---------|----------|
| **Flashbots Protect** | Private mempool | Sandwich attack prevention |
| **MEV-Burn** | MEV sharing | Reduce MEV extraction |
| **UniswapX** | Intent-based | Superior slippage |
| **1inch** | DEX aggregation | Find best route |
| **CoW Protocol** | Batch auctions | Batch settlement |
| **Chainlink Keepers** | Conditional execution | Adjust slippage dynamically |

---

## Resources

- **Uniswap Router02 Docs**: https://docs.uniswap.org/
- **Flashbots Docs**: https://docs.flashbots.net/
- **MEV-Inspect** (research): https://github.com/flashbots/mev-inspect

---

**Next:** Read `03-sniper-bot-prevention.md` for MEV and bot protection patterns.
