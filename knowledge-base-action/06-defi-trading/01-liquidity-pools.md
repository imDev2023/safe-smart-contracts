# Liquidity Pool Management & Contract Patterns

**Status:** Essential Guide | **Level:** Intermediate-Advanced | **Security Focus:** LP Safety

## Liquidity Pool Fundamentals

A **liquidity pool** is a smart contract holding reserves of two tokens, enabling automated trading through mathematical formulas.

### Pool Creation & Initialization

```solidity
// Uniswap V3 Pool Creation
interface IUniswapV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

// Example
address pool = factory.createPool(
    address(USDC),
    address(USDT),
    3000  // 0.30% fee tier
);
```

**Critical Decisions:**
1. **Token Order**: Alphabetical (lowercase address comparison)
2. **Fee Tier**: 1, 5, 30, or 10,000 basis points
3. **Initial Price**: Set via `sqrtPriceX96` parameter

### Pool Structure (Constant Product, V2)

```solidity
contract UniswapV2Pair is ERC20 {
    address public token0;
    address public token1;

    uint112 private reserve0;           // Last known balance of token0
    uint112 private reserve1;           // Last known balance of token1
    uint32 private blockTimestampLast;  // Last block timestamp

    uint256 public price0CumulativeLast; // For TWAP calculation
    uint256 public price1CumulativeLast;

    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    // LP tokens represented by ERC20 balances
}
```

---

## Adding Liquidity

### Uniswap V2 Flow

```solidity
// Step 1: Approve tokens
tokenA.approve(address(router), amountA);
tokenB.approve(address(router), amountB);

// Step 2: Add liquidity with slippage protection
(uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
    address(tokenA),
    address(tokenB),
    amountADesired,    // How much you want to add
    amountBDesired,
    amountAMin,        // Minimum willing to accept (slippage protection)
    amountBMin,
    address(this),     // LP recipient
    block.timestamp + 300
);
```

**Key Detail:** Router adjusts amounts to maintain price balance:
```
Desired: 100 tokenA + 200 tokenB
Pool ratio: 1 tokenA = 1.5 tokenB

Actual: 100 tokenA + 150 tokenB
Excess 50 tokenB returned to user
```

### Uniswap V3 Concentrated Liquidity

```solidity
// More complex: Choose price range
IUniswapV3PositionManager.MintParams memory params = IUniswapV3PositionManager.MintParams({
    token0: address(USDC),
    token1: address(USDT),
    fee: 500,           // 0.05% (stablecoin pair)
    tickLower: -100,    // Price range lower bound
    tickUpper: 100,     // Price range upper bound
    amount0Desired: 1000e6,  // USDC amount
    amount1Desired: 1000e6,  // USDT amount
    amount0Min: 900e6,  // Slippage tolerance
    amount1Min: 900e6,
    recipient: msg.sender,
    deadline: block.timestamp + 300
});

(uint tokenId, uint128 liquidity, uint amount0, uint amount1) = positionManager.mint(params);
```

**V3 Advantages:**
- More capital efficient
- Higher returns on fees
- Better for narrow price ranges
- Worse for volatile pairs

---

## Removing Liquidity

### Safe Withdrawal Pattern

```solidity
function removeLiquidityAndSwap(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) internal {
    // Step 1: Get LP token balance proof
    uint lpBalance = lpToken.balanceOf(address(this));
    require(lpBalance >= liquidity, "Insufficient LP balance");

    // Step 2: Remove liquidity (burns LP tokens, returns token amounts)
    (uint amountA, uint amountB) = router.removeLiquidity(
        tokenA,
        tokenB,
        liquidity,
        amountAMin,      // Must receive at least this much
        amountBMin,
        to,
        deadline
    );

    // Step 3: Events for tracking
    emit LiquidityRemoved(tokenA, tokenB, amountA, amountB);

    return (amountA, amountB);
}
```

**Critical Protections:**
1. **Minimum Amounts**: Protect against MEV
2. **Deadline**: Prevent stale transactions
3. **Balance Check**: Verify LP tokens exist
4. **To Address**: Verify withdrawal destination

---

## Fee Collection

### How Fees Accumulate

```
Each swap charges 0.30% fee (example):

Swap: 100 tokenA → tokenB
Fee: 0.30 tokenA collected

Fee Distribution:
- 100% to LP token holders (distributed proportionally)
- Collected via uncollected fees or LP token appreciation
```

### Fee Claims (V3 Position-Based)

```solidity
// V3: Fees tied to specific positions
IUniswapV3PositionManager.CollectParams memory params =
    IUniswapV3PositionManager.CollectParams({
        tokenId: positionId,
        recipient: msg.sender,
        amount0Max: type(uint128).max,  // Collect all token0 fees
        amount1Max: type(uint128).max
    });

(uint amount0, uint amount1) = positionManager.collect(params);
```

### Compounding Fees

Advanced LPs reinvest fees for compound returns:

```solidity
contract AutoCompoundingLP {
    function compoundFees(uint tokenId) external {
        // 1. Collect fees
        (uint amount0, uint amount1) = positionManager.collect(params);

        // 2. Swap excess to maintain ratio (if needed)
        if (amount0 > amount1) {
            // Swap half of excess amount0 for amount1
        }

        // 3. Add liquidity back to position
        positionManager.increaseLiquidity({
            tokenId: tokenId,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 300
        });
    }
}
```

---

## Pool Health & Monitoring

### Key Metrics to Track

```solidity
contract PoolMonitor {
    function getPoolMetrics(address pool) external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestamp,
        uint price0Cumulative,
        uint price1Cumulative,
        uint kLast
    ) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);

        (reserve0, reserve1, blockTimestamp) = pair.getReserves();
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();
        kLast = pair.kLast();

        // k invariant check
        uint k = uint(reserve0) * uint(reserve1);
        require(k >= kLast, "Pool invariant violated");
    }

    function calculateTWAP(
        address pool,
        address tokenA,
        address tokenB,
        uint timeWeighting
    ) external view returns (uint price) {
        // Price = (token1Value / token0Value) * 2^96
        // TWAP protects against price flash loan attacks

        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // Current price
        uint currentPrice = (uint(reserve1) << 112) / uint(reserve0);

        return currentPrice;
    }
}
```

### Liquidity Depth Analysis

```solidity
// Check if pool has enough liquidity for safe trading
function checkLiquidityDepth(
    address pool,
    address tokenIn,
    uint amountIn
) external view returns (bool isSafe) {
    IUniswapV2Pair pair = IUniswapV2Pair(pool);
    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

    uint reserveIn = (tokenIn == pair.token0()) ? reserve0 : reserve1;

    // Slippage = amountIn / (reserveIn + amountIn)
    uint slippage = (amountIn * 10000) / (reserveIn + amountIn);

    // Safe if slippage < 5%
    return slippage < 500;
}
```

---

## Common Pitfalls & Solutions

### ⚠️ Pitfall 1: Burning LP Tokens in Pool

**Problem:** Some pools burn 1 LP token at initialization to prevent empty pool attacks.

```solidity
// Bad: Locked liquidity
constructor(address token0, address token1) {
    // Mints MINIMUM_LIQUIDITY and burns it
    uint liquidity = Math.sqrt(amount0 * amount1);
    _mint(address(0), MINIMUM_LIQUIDITY);  // 1000 wei
    _mint(msg.sender, liquidity - MINIMUM_LIQUIDITY);
}

// Result: First liquidity provider's returns slightly diluted
```

**Solution:** Expected behavior in Uniswap V2/V3. Just accept 0.1% dilution.

### ⚠️ Pitfall 2: Not Updating LP Token Balance on Transfer

**Problem:** Pool doesn't track when LP tokens are transferred, causing fee calculation errors.

```solidity
// Bad: No transfer hook
function transfer(address to, uint value) external returns (bool) {
    balanceOf[msg.sender] -= value;
    balanceOf[to] += value;
    // Missing: Update fee accounting!
    return true;
}
```

**Solution:** Uniswap V3 uses NFTs (ERC-721) for positions instead, eliminating this issue.

### ⚠️ Pitfall 3: Slippage from Poor Estimation

**Problem:** Setting `amountMin` too low exposes you to MEV.

```solidity
// Bad: No protection
router.removeLiquidity(
    tokenA,
    tokenB,
    liquidity,
    0,          // Accept ANY amount of tokenA (disaster!)
    0,          // Accept ANY amount of tokenB
    msg.sender,
    deadline
);

// Example loss: Attacker MEV costs you $10,000
```

**Solution:** Calculate expected amounts first, then apply 1-2% buffer.

```solidity
// Good: Protected with slippage
uint expectedAmountA = (liquidity * reserve0) / totalSupply;
uint expectedAmountB = (liquidity * reserve1) / totalSupply;

uint amountAMin = (expectedAmountA * 99) / 100;  // 1% slippage buffer
uint amountBMin = (expectedAmountB * 99) / 100;

router.removeLiquidity(
    tokenA,
    tokenB,
    liquidity,
    amountAMin,
    amountBMin,
    msg.sender,
    deadline
);
```

---

## LP Position Management Pattern

### Recommended Pattern (Safe)

```solidity
contract ProtectedLP {
    mapping(bytes32 => Position) positions;

    struct Position {
        address lp;
        address tokenA;
        address tokenB;
        uint liquidity;
        uint addedAt;
        bool active;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) external {
        // 1. Validate inputs
        require(amountA > 0 && amountB > 0, "Zero amounts");
        require(tokenA != tokenB, "Same token");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");

        // 2. Transfer tokens
        IERC20(tokenA).transferFrom(msg.sender, address(router), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(router), amountB);

        // 3. Add liquidity with protection
        (uint actualA, uint actualB, uint liquidity) = router.addLiquidity(
            tokenA, tokenB,
            amountA, amountB,
            (amountA * 95) / 100,  // 5% slippage tolerance
            (amountB * 95) / 100,
            address(this),
            block.timestamp + 300
        );

        // 4. Track position
        bytes32 posId = keccak256(abi.encode(msg.sender, tokenA, tokenB));
        positions[posId] = Position({
            lp: msg.sender,
            tokenA: tokenA,
            tokenB: tokenB,
            liquidity: liquidity,
            addedAt: block.timestamp,
            active: true
        });

        emit LiquidityAdded(msg.sender, tokenA, tokenB, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB
    ) external {
        bytes32 posId = keccak256(abi.encode(msg.sender, tokenA, tokenB));
        Position storage pos = positions[posId];

        require(pos.active, "No active position");
        require(pos.liquidity > 0, "No liquidity");

        // Remove with protection
        (uint amountA, uint amountB) = router.removeLiquidity(
            tokenA, tokenB,
            pos.liquidity,
            0,  // Caller accepts responsibility for slippage
            0,
            msg.sender,
            block.timestamp + 300
        );

        // Mark as inactive
        pos.active = false;

        emit LiquidityRemoved(msg.sender, tokenA, tokenB, amountA, amountB);
    }
}
```

---

## Gas Optimization for Pool Operations

```solidity
// Instead of multiple external calls:
// ❌ INEFFICIENT
uint res0 = pair.reserve0();
uint res1 = pair.reserve1();
(uint r0, uint r1, uint ts) = pair.getReserves();

// ✅ EFFICIENT
(uint r0, uint r1, uint ts) = pair.getReserves();  // Single call
```

### Batch Operations

```solidity
// Multi-pool operations
function batchAddLiquidity(
    address[] memory pools,
    uint[] memory amounts
) external {
    for (uint i = 0; i < pools.length; i++) {
        // Process each pool
    }
    // Save gas by batching approval
}
```

---

## Integration Checklist

- [ ] Pool exists and has sufficient liquidity?
- [ ] Fee tier appropriate for pair?
- [ ] Slippage tolerances set (1-5%)?
- [ ] Deadline enforcement active?
- [ ] LP balance verified before removal?
- [ ] Fee collection implemented?
- [ ] Impermanent loss understood?
- [ ] Gas costs factored into strategy?
- [ ] Pool events monitored for anomalies?
- [ ] Tests cover MEV scenarios?

---

## Resources

- **Uniswap V2 Documentation**: https://docs.uniswap.org/
- **Uniswap V3-Periphery**: https://github.com/Uniswap/v3-periphery
- **LP Token Standard**: https://eips.ethereum.org/EIPS/eip-20

---

**Next:** Read `02-slippage-protection.md` for advanced slippage mitigation patterns.
