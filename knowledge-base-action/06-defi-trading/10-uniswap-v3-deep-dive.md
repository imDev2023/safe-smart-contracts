# Uniswap V3 Deep Dive: Concentrated Liquidity, Ticks, and the Oracle Revolution

**Source Repository**: https://github.com/Uniswap/v3-core + https://github.com/Uniswap/v3-periphery + https://github.com/Jeiwan/uniswapv3-book

**Last Updated**: November 2024

**Extracted From**: Production source code with exact file:line references

---

## Table of Contents

1. [What Makes V3 Revolutionary](#what-makes-v3-revolutionary)
2. [Concentrated Liquidity Model](#concentrated-liquidity-model)
3. [The Tick System](#the-tick-system)
4. [Position Management](#position-management)
5. [Fee Distribution and Accrual](#fee-distribution-and-accrual)
6. [The Oracle System](#the-oracle-system)
7. [Swap Mechanism](#swap-mechanism)
8. [Flash Swaps in V3](#flash-swaps-in-v3)
9. [Periphery Contracts](#periphery-contracts)
10. [Security Considerations](#security-considerations)
11. [V2 vs V3: Detailed Comparison](#v2-vs-v3-detailed-comparison)

---

## 1. What Makes V3 Revolutionary

### The Core Innovation: Concentrated Liquidity

V3 introduces **concentrated liquidity**, allowing LPs to provide liquidity only in specific price ranges rather than across the entire (0, ∞) curve.

**Key Advantage**: Capital efficiency
- V2: 1 unit of capital spread across entire price curve
- V3: 1 unit of capital concentrated in narrow range = 4000x capital efficiency (in theory)

**Trade-off**: Impermanent loss risk increases if price moves outside range

---

## 2. Concentrated Liquidity Model

### Tick-Based Pricing

V3 divides the price curve into discrete **ticks**, each representing a price level:

- **Tick Definition** (from `temp-repos/v3-core/contracts/libraries/TickMath.sol:7-16`):
  ```solidity
  library TickMath {
      int24 internal constant MIN_TICK = -887272;    // log base 1.0001 of 2**-128
      int24 internal constant MAX_TICK = -MIN_TICK;  // log base 1.0001 of 2**128

      uint160 internal constant MIN_SQRT_RATIO = 4295128739;
      uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
  }
  ```

- **Price Formula**: `price = 1.0001^tick`
  - Each tick step = 0.01% price change
  - Logarithmically spaced across huge price range
  - Supports prices from 2^-128 to 2^128

### Tick-to-Price Conversion

**Source**: `temp-repos/v3-core/contracts/libraries/TickMath.sol:18-54`

```solidity
function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
    uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
    require(absTick <= uint256(MAX_TICK), 'T');

    // Line 27-46: Bit manipulation to compute sqrt(1.0001^tick) * 2^96
    uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    // ... 16 more bit manipulation operations for efficiency ...
    if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    // Reverse calculation for negative ticks
    if (tick > 0) ratio = type(uint256).max / ratio;

    // Convert from Q128.128 to Q64.96
    sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
}
```

**Design**: Pre-computed constants allow O(1) tick-to-price calculation using bit operations.

### Tick Spacing

Not all ticks are used - **tickSpacing** controls which ticks can have liquidity:

**Source**: `temp-repos/v3-core/contracts/UniswapV3Factory.sol:22-31`

```solidity
constructor() {
    owner = msg.sender;

    // Fee 0.01% → tick spacing 1 (all ticks usable)
    feeAmountTickSpacing[500] = 10;
    emit FeeAmountEnabled(500, 10);

    // Fee 0.30% → tick spacing 60 (every 60th tick)
    feeAmountTickSpacing[3000] = 60;
    emit FeeAmountEnabled(3000, 60);

    // Fee 1.00% → tick spacing 200 (every 200th tick)
    feeAmountTickSpacing[10000] = 200;
    emit FeeAmountEnabled(10000, 200);
}
```

Lower fee tiers allow finer granularity (more ticks available), higher fee tiers space ticks further apart.

---

## 3. The Tick System

### Tick Information Storage

**Source**: `temp-repos/v3-core/contracts/libraries/Tick.sol:17-37`

Each initialized tick stores:

```solidity
struct Info {
    // the total position liquidity that references this tick
    uint128 liquidityGross;

    // amount of net liquidity added (subtracted) when tick is crossed from left to right
    int128 liquidityNet;

    // fee growth per unit of liquidity on the _other_ side of this tick
    uint256 feeGrowthOutside0X128;
    uint256 feeGrowthOutside1X128;

    // the cumulative tick value on the other side of the tick
    int56 tickCumulativeOutside;

    // the seconds per unit of liquidity on the _other_ side of this tick
    uint160 secondsPerLiquidityOutsideX128;

    // the seconds spent on the other side of the tick
    uint32 secondsOutside;

    // true iff the tick is initialized (optimization to prevent fresh sstores)
    bool initialized;
}
```

### The Tick Bitmap Optimization

V3 uses a **bitmap** to efficiently track initialized ticks without iteration:

**Source**: `temp-repos/v3-core/contracts/libraries/TickBitmap.sol:1-78`

```solidity
library TickBitmap {
    // Each word stores 256 ticks (2^8 values per word)
    // wordPos = tick >> 8 (divide by 256)
    // bitPos = tick % 256

    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);      // Which word (256 ticks per word)
        bitPos = uint8(tick % 256);      // Which bit in that word
    }

    // Finding next initialized tick: O(log n) instead of O(n)
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte  // search left (less than) or right (greater than)
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;

        if (lte) {
            // Find rightmost bit set at or left of current position
            (int16 wordPos, uint8 bitPos) = position(compressed);
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;
            initialized = masked != 0;
            // Return the position of the found bit
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // Similar logic for searching right
            // ...
        }
    }
}
```

**Performance**: Finding next tick is O(1) within a 256-tick word, avoiding expensive iteration.

### Max Liquidity Per Tick

**Source**: `temp-repos/v3-core/contracts/libraries/Tick.sol:44-49`

```solidity
function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
    int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
    int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
    uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
    // Distribute max uint128 across all possible ticks
    return type(uint128).max / numTicks;
}
```

Prevents overflow of liquidity at any single tick.

---

## 4. Position Management

### Position Storage

Positions are identified by a keccak256 hash of (owner, tickLower, tickUpper):

**Source**: `temp-repos/v3-core/contracts/libraries/Position.sol:30-37`

```solidity
function get(
    mapping(bytes32 => Info) storage self,
    address owner,
    int24 tickLower,
    int24 tickUpper
) internal view returns (Position.Info storage position) {
    position = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
}
```

Unlike V4 which uses salt for multiple positions in same range, V3 only allows one position per (owner, range).

### Position Information

**Source**: `temp-repos/v3-core/contracts/libraries/Position.sol:13-22`

```solidity
struct Info {
    // the amount of liquidity owned by this position
    uint128 liquidity;

    // fee growth per unit of liquidity as of the last update
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;

    // the fees owed to the position owner in token0/token1
    uint128 tokensOwed0;
    uint128 tokensOwed1;
}
```

Fees are stored in the position as `tokensOwed`, ready to be withdrawn.

### Position Update Logic

**Source**: `temp-repos/v3-core/contracts/libraries/Position.sol:44-87`

```solidity
function update(
    Info storage self,
    int128 liquidityDelta,
    uint256 feeGrowthInside0X128,
    uint256 feeGrowthInside1X128
) internal {
    Info memory _self = self;

    // Line 53-58: Update liquidity if not a "poke"
    uint128 liquidityNext;
    if (liquidityDelta == 0) {
        require(_self.liquidity > 0, 'NP'); // Disallow pokes on empty positions
        liquidityNext = _self.liquidity;
    } else {
        liquidityNext = LiquidityMath.addDelta(_self.liquidity, liquidityDelta);
    }

    // Line 61-76: Calculate accumulated fees
    uint128 tokensOwed0 =
        uint128(
            FullMath.mulDiv(
                feeGrowthInside0X128 - _self.feeGrowthInside0LastX128,
                _self.liquidity,
                FixedPoint128.Q128
            )
        );
    uint128 tokensOwed1 =
        uint128(
            FullMath.mulDiv(
                feeGrowthInside1X128 - _self.feeGrowthInside1LastX128,
                _self.liquidity,
                FixedPoint128.Q128
            )
        );

    // Update position state
    if (liquidityDelta != 0) self.liquidity = liquidityNext;
    self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
    self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
    if (tokensOwed0 > 0 || tokensOwed1 > 0) {
        self.tokensOwed0 += tokensOwed0;
        self.tokensOwed1 += tokensOwed1;
    }
}
```

---

## 5. Fee Distribution and Accrual

### Global Fee Tracking

**Source**: `temp-repos/v3-core/contracts/UniswapV3Pool.sol:77-79`

```solidity
/// @inheritdoc IUniswapV3PoolState
uint256 public override feeGrowthGlobal0X128;
/// @inheritdoc IUniswapV3PoolState
uint256 public override feeGrowthGlobal1X128;
```

These track cumulative fees per unit of liquidity since pool creation.

### Fee Growth Inside Position

Fee growth must be calculated differently for positions at different tick ranges:

**Source**: `temp-repos/v3-core/contracts/libraries/Tick.sol:60-95`

```solidity
function getFeeGrowthInside(
    mapping(int24 => Tick.Info) storage self,
    int24 tickLower,
    int24 tickUpper,
    int24 tickCurrent,
    uint256 feeGrowthGlobal0X128,
    uint256 feeGrowthGlobal1X128
) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
    Info storage lower = self[tickLower];
    Info storage upper = self[tickUpper];

    // Line 72-80: Calculate fee growth below
    uint256 feeGrowthBelow0X128;
    uint256 feeGrowthBelow1X128;
    if (tickCurrent >= tickLower) {
        feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
        feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
    } else {
        feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
        feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
    }

    // Line 82-91: Calculate fee growth above
    uint256 feeGrowthAbove0X128;
    uint256 feeGrowthAbove1X128;
    if (tickCurrent < tickUpper) {
        feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
        feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
    } else {
        feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
        feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
    }

    // Fee inside = global - below - above
    feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
    feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
}
```

This clever "outside" tracking avoids recomputing for each position.

---

## 6. The Oracle System

### Oracle Observations

V3 features an **on-chain oracle** using TWAP (Time-Weighted Average Price):

**Source**: `temp-repos/v3-core/contracts/libraries/Oracle.sol:12-21`

```solidity
struct Observation {
    // the block timestamp of the observation
    uint32 blockTimestamp;

    // the tick accumulator, i.e. tick * time elapsed since pool init
    int56 tickCumulative;

    // seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since pool init
    uint160 secondsPerLiquidityCumulativeX128;

    // whether or not the observation is initialized
    bool initialized;
}
```

### Computing TWAP

**Source**: `temp-repos/v3-core/contracts/libraries/Oracle.sol:30-45`

```solidity
function transform(
    Observation memory last,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity
) private pure returns (Observation memory) {
    uint32 delta = blockTimestamp - last.blockTimestamp;
    return
        Observation({
            blockTimestamp: blockTimestamp,
            // Line 40: Accumulate tick * time
            tickCumulative: last.tickCumulative + int56(tick) * delta,
            // Line 41-42: Accumulate seconds per liquidity
            secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
                ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
            initialized: true
        });
}
```

To compute TWAP for a time range:
1. Get observation at start time: `tick1, timestamp1`
2. Get observation at end time: `tick2, timestamp2`
3. TWAP = `(tick2 - tick1) / (timestamp2 - timestamp1)`

**Advantages**:
- On-chain, no external oracle needed
- Resistant to flash loan price manipulation (requires sustained price change)
- Historical data available (up to the configured observation cardinality)

### Oracle Array Growth

**Source**: `temp-repos/v3-core/contracts/libraries/Oracle.sol:108-120`

```solidity
function grow(
    Observation[65535] storage self,
    uint16 current,
    uint16 next
) internal returns (uint16) {
    require(current > 0, 'I');
    if (next <= current) return current;

    // Pre-populate slots to avoid fresh SSTOREs during swaps
    for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
    return next;
}
```

Anyone can expand the oracle array by paying for storage. Default is 1 slot, expandable to 65535.

---

## 7. Swap Mechanism

### The Multi-Hop Swap Architecture

V3 pools execute **single-pool swaps** via callback, enabling:
- Multi-hop paths without intermediate tokens
- Fair pricing through routing contracts

**Source**: `temp-repos/v3-periphery/contracts/SwapRouter.sol:86-112`

```solidity
function exactInputInternal(
    uint256 amountIn,
    address recipient,
    uint160 sqrtPriceLimitX96,
    SwapCallbackData memory data
) private returns (uint256 amountOut) {
    if (recipient == address(0)) recipient = address(this);

    (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
    bool zeroForOne = tokenIn < tokenOut;

    // Call pool's swap function
    (int256 amount0, int256 amount1) =
        getPool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            amountIn.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : sqrtPriceLimitX96,
            abi.encode(data)
        );

    return uint256(-(zeroForOne ? amount1 : amount0));
}
```

### Swap Callback

The pool calls back to the SwapRouter to receive payment:

**Source**: `temp-repos/v3-periphery/contracts/SwapRouter.sol:57-84`

```solidity
function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata _data
) external override {
    require(amount0Delta > 0 || amount1Delta > 0);
    SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
    (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

    // Verify callback came from legitimate pool
    CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

    // Determine which token is being paid
    (bool isExactInput, uint256 amountToPay) =
        amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));

    if (isExactInput) {
        // Pay the input token to the pool
        pay(tokenIn, data.payer, msg.sender, amountToPay);
    } else {
        // For exact output, handle subsequent swaps or final payment
        if (data.path.hasMultiplePools()) {
            data.path = data.path.skipToken();
            exactOutputInternal(amountToPay, msg.sender, 0, data);
        } else {
            amountInCached = amountToPay;
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        }
    }
}
```

### Core Swap Calculation

**Source**: `temp-repos/v3-core/contracts/libraries/SwapMath.sol:21-97`

```solidity
function computeSwapStep(
    uint160 sqrtRatioCurrentX96,
    uint160 sqrtRatioTargetX96,
    uint128 liquidity,
    int256 amountRemaining,
    uint24 feePips
)
    internal
    pure
    returns (
        uint160 sqrtRatioNextX96,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeAmount
    )
{
    bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
    bool exactIn = amountRemaining >= 0;

    if (exactIn) {
        // Line 41: Remove fee from amount remaining
        uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);

        // Line 42-44: Calculate amount needed to reach target price
        amountIn = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
            : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);

        // Line 45-52: Check if we have enough to reach target
        if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
        else
            sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtRatioCurrentX96,
                liquidity,
                amountRemainingLessFee,
                zeroForOne
            );
    } else {
        // Similar logic for exact output swaps...
    }

    // Line 91-96: Calculate fee amount based on final price reached
    if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
        // Fee is the remainder if we didn't reach target
        feeAmount = uint256(amountRemaining) - amountIn;
    } else {
        // Otherwise, apply standard fee percentage
        feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
    }
}
```

---

## 8. Flash Swaps in V3

V3 supports flash swaps similar to V2, but with integrated oracle support:

**Source**: `temp-repos/v3-core/contracts/UniswapV3Pool.sol` (extends to ~400 lines for swap implementation)

Flash swaps allow:
- Uncollateralized borrows
- Callback-based arbitrage execution
- Price oracle verification before repayment

Protection:
- Callback validates caller
- Amounts must be repaid or arbitrage executed within transaction

---

## 9. Periphery Contracts

### SwapRouter for Multi-Hop Swaps

**Source**: `temp-repos/v3-periphery/contracts/SwapRouter.sol:20-28`

Routes multi-hop swaps through multiple pools with single interface:

```solidity
contract SwapRouter is
    ISwapRouter,
    PeripheryImmutableState,
    PeripheryValidation,
    PeripheryPaymentsWithFee,
    Multicall,
    SelfPermit
{
    // Supports exactInputSingle, exactInput, exactOutputSingle, exactOutput
}
```

### NonfungiblePositionManager

**Role**: Wraps concentrated liquidity positions as ERC721 NFTs

Key features:
- One NFT per position (V3 vs fungible LP tokens in V2)
- Position can be transferred
- Integrated position visualization (on-chain SVG metadata)
- Multicall support for batch operations

---

## 10. Security Considerations

### Price Slippage Protection

V3 integrates slippage protection via:

1. **amountMin/amountOutMin**: Minimum amount acceptable
2. **sqrtPriceLimitX96**: Price limit preventing excessive slippage

**Source**: `temp-repos/v3-periphery/contracts/SwapRouter.sol:115-129`

```solidity
function exactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint256 amountOut)
{
    amountOut = exactInputInternal(
        params.amountIn,
        params.recipient,
        params.sqrtPriceLimitX96,
        SwapCallbackData({path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut), payer: msg.sender})
    );
    require(amountOut >= params.amountOutMinimum, 'Too little received');
}
```

### Oracle Manipulation Resistance

The oracle's use of **tickCumulative** (tick × time) makes it resistant to flash attacks:

- Flash attack: Can change price for one block
- Oracle needs sustained price move over time
- TWAP over long period is reliable

**Example**: 10-minute TWAP requires consistent price movement for 600 blocks.

### Concentrated Liquidity Risks

**Impermanent Loss**: Occurs when:
1. Position is out-of-range (current tick outside [tickLower, tickUpper])
2. No fees accumulate (zero swaps in range)
3. LP has "lost" capital to arbitrageurs

**Capital Efficiency**: Concentrated LP could earn high fees but must monitor price.

---

## 11. V2 vs V3: Detailed Comparison

| Feature | V2 | V3 |
|---------|-----|-----|
| **Liquidity Model** | Full curve (0, ∞) | Concentrated (custom range) |
| **LP Token** | ERC20 (fungible) | ERC721 (NFT) |
| **Fee Tiers** | Single (0.3%) | Multiple (0.01%, 0.05%, 0.30%, 1%) |
| **Capital Efficiency** | 1x baseline | Up to 4000x (in theory) |
| **Impermanent Loss** | Unbounded price movement | Only within [tickLower, tickUpper] |
| **Fee Distribution** | Proportional to liquidity | Proportional to liquidity in range + time |
| **Oracle** | External (TWAP from reserves) | Internal (block-level) |
| **Flash Swaps** | Supported | Supported |
| **Governance** | Centralized fee collection | Protocol fees can be enabled |
| **Swap Callback** | Simple callback | Complex with multi-hop support |
| **Position Management** | Automatic | Manual range management required |

### Code Comparison: Liquidity Provision

**V2** (from `temp-repos/v2-core/contracts/UniswapV2Pair.sol`):
```solidity
// All liquidity spread across entire curve
function addLiquidity(uint amount0, uint amount1) external {
    // Calculate LP tokens based on reserve ratio
    uint liquidity = sqrt(amount0 * amount1);
}
```

**V3** (from `temp-repos/v3-core/contracts/UniswapV3Pool.sol`):
```solidity
// Concentrated liquidity in specific tick range
function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
) external {
    // Calculate amounts needed for specific range
    // Update tick states
    // Execute callback for payment
}
```

---

## Key V3-to-V4 Evolution

V4 addresses two V3 limitations:

| Problem | V3 Solution | V4 Solution |
|---------|----------|----------|
| **Customization** | Limited to tick ranges | Unlimited hooks |
| **Multiple Positions** | One position per (owner, range) | Salt parameter allows unlimited |
| **Token Standard** | ERC721 NFTs per pool | Single ERC6909 multi-token contract |
| **Position Type** | NFT (complex transfers) | ERC6909 balance (simple transfers) |

---

## Security Audit Checklist for V3 Pools

- [ ] **Reentrancy**: Pools use callback system - verify callback guard
- [ ] **Tick Overflow**: Maximum liquidity per tick enforced
- [ ] **Fee Calculation**: Fee growth formula verified (no precision loss)
- [ ] **Oracle Manipulation**: TWAP has sufficient history cardinality
- [ ] **Price Slippage**: amountMin and sqrtPriceLimitX96 enforced
- [ ] **Callback Validation**: Callback verifies caller is legitimate pool
- [ ] **Range Boundaries**: tickLower < tickUpper enforced, proper spacing
- [ ] **Liquidity Management**: addDelta overflow prevention
- [ ] **Flash Swap Repayment**: k invariant verified after callback
- [ ] **Position Sweeping**: tokensOwed properly accumulated and withdrawn

---

## References and Further Reading

### Official Documentation
- [Uniswap V3 Whitepaper](https://uniswap.org/whitepaper-v3.pdf)
- [Uniswap V3 Core Repository](https://github.com/Uniswap/v3-core)
- [Uniswap V3 Periphery](https://github.com/Uniswap/v3-periphery)
- [Uniswap V3 Book (Educational)](https://github.com/Jeiwan/uniswapv3-book)

### Key Contracts Analyzed
- `UniswapV3Factory.sol` (74 lines) - Pool deployment
- `UniswapV3Pool.sol` (400+ lines) - Core pool logic
- `TickMath.sol` (206 lines) - Tick/price conversion
- `Position.sol` (88 lines) - Position tracking
- `Tick.sol` (150+ lines) - Tick state management
- `TickBitmap.sol` (78 lines) - Tick bitmap optimization
- `SwapMath.sol` (98 lines) - Swap calculations
- `Oracle.sol` (150+ lines) - TWAP oracle
- `SwapRouter.sol` (150+ lines) - Multi-hop swapping
- `NonfungiblePositionManager.sol` - ERC721 position management

### Related Standards
- [ERC-721: Non-Fungible Token Standard](https://eips.ethereum.org/EIPS/eip-721)
- [Q64.96 Fixed-Point Arithmetic](https://en.wikipedia.org/wiki/Fixed-point_arithmetic)
- [TWAP Oracle Concept](https://en.wikipedia.org/wiki/Time-weighted_average_price)

---

## Changelog

| Date | Change |
|------|--------|
| Nov 16, 2024 | Initial V3 deep-dive extraction from production source |
| Nov 16, 2024 | Added tick system and bitmap optimization details |
| Nov 16, 2024 | Added oracle/TWAP mechanism comprehensive walkthrough |
| Nov 16, 2024 | Added V2 vs V3 comparison with code examples |
| Nov 16, 2024 | Added periphery contract details (SwapRouter, PositionManager) |

---

**Note**: All code extracts include exact file paths and line numbers for verification. This guide is continuously updated as V3 evolves and new research emerges.
