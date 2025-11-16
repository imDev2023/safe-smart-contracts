# DEX/AMM Implementation Overview

**Status:** Essential Guide | **Level:** Intermediate | **Last Updated:** November 2025

## What is a DEX (Decentralized Exchange)?

A **Decentralized Exchange (DEX)** is a smart contract-based trading platform where users can trade directly from their wallets without intermediaries. Unlike centralized exchanges (CEXs), DEXs use **Automated Market Makers (AMMs)** - algorithms that determine token prices based on pool balances.

### Key Characteristics
- ✅ Non-custodial (users control private keys)
- ✅ Transparent on-chain pricing
- ✅ Liquidity pooling model
- ✅ Anyone can add/remove liquidity
- ✅ Algorithmic pricing via bonding curves
- ✅ Vulnerable to MEV (Maximal Extractable Value)

---

## AMM (Automated Market Maker) Fundamentals

### The Constant Product Formula (Uniswap V2)

The most common AMM model uses: **x × y = k**

Where:
- `x` = reserve of token A
- `y` = reserve of token B
- `k` = constant product (invariant)

**Example:**
```
Initial state:
- ETH reserve: 100
- USDC reserve: 300,000
- k = 100 × 300,000 = 30,000,000

User swaps 10 ETH:
- New ETH reserve: 100 + 10 = 110
- Required USDC: 30,000,000 / 110 = 272,727
- USDC output: 300,000 - 272,727 = 27,273
- Effective price: 27,273 / 10 = 2,727.3 USDC/ETH
- Slippage: Paid 2,727 instead of base price
```

### Liquidity Pool Structure

```solidity
contract UniswapV2Pair {
    address token0;          // Token A
    address token1;          // Token B
    uint112 reserve0;        // Balance of token A
    uint112 reserve1;        // Balance of token B
    uint32 blockTimestampLast; // For TWAP oracles

    uint256 totalSupply;     // LP token supply
    mapping(address => uint256) balanceOf; // LP token shares
}
```

### LP Tokens (Liquidity Provider Tokens)

When you add liquidity to a pool, you receive **LP tokens** representing your share:

```
Initial pool state:
- ETH reserve: 100
- USDC reserve: 300,000
- Total LP tokens issued: sqrt(100 × 300,000) = 5,477

User adds liquidity:
- Adds 10 ETH + 30,000 USDC
- New reserves: 110 ETH, 330,000 USDC
- LP tokens minted: 547 (10% share of pool growth)
- Can withdraw any time: 10 ETH + 30,000 USDC + fees earned
```

---

## Uniswap V3 Architecture (Advanced)

Uniswap V3 introduced **concentrated liquidity**, allowing LPs to provide liquidity within specific price ranges.

### Key Concepts

#### 1. **Ticks and Ranges**
- Price ranges divided into discrete tick intervals
- LP chooses: `lower_tick` and `upper_tick`
- Only earns fees within that range
- Capital is more efficient (higher returns potential)

```solidity
// Uniswap V3: Concentrated Liquidity
struct Position {
    uint96 nonce;
    address operator;
    address token0;
    address token1;
    uint24 fee;              // Fee tier: 0.01%, 0.05%, 0.30%, 1.00%
    int24 tickLower;         // Lower bound of range
    int24 tickUpper;         // Upper bound of range
    uint128 liquidity;       // Amount of liquidity
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    uint128 tokensOwed0;     // Uncollected fees
    uint128 tokensOwed1;
}
```

#### 2. **Fee Tiers**
V3 pools support multiple fee tiers per pair:
- **0.01%** (stablecoin pairs, USDC/USDT)
- **0.05%** (stablecoin pairs)
- **0.30%** (most common, ETH/USDC)
- **1.00%** (volatile pairs, emerging tokens)

#### 3. **Price Math**
V3 uses logarithmic price representation:
```
sqrtPrice = sqrt(token1 / token0) * 2^96
```

This allows precise pricing across huge ranges (1 Satoshi to millions of dollars).

---

## Trading Flow (Constant Product Model)

### Basic Swap Flow

```
User: "I want to trade 1 ETH for USDC"

1. Approve: Grant swap contract permission to transfer ETH
   contract.approve(router, 1 ether)

2. Call swap:
   router.swapExactTokensForTokens(
       amountIn: 1 ether,
       amountOutMin: 2700 USDC,  // Slippage protection
       path: [ETH, USDC],
       to: user,
       deadline: block.timestamp + 1200  // Deadline protection
   )

3. Router:
   a) Calculate output using x × y = k
   b) Transfer 1 ETH from user to pool
   c) Transfer USDC back to user
   d) Verify k invariant maintained

4. Pool state after swap:
   - ETH reserve: 101 (↑1)
   - USDC reserve: 297,030 (↓2,970)
   - LP fee: 2,970 × 0.003 = 8.91 USDC (0.3% fee)
   - Effective fee goes to liquidity providers
```

### Multi-hop Swaps

For less liquid pairs, swaps route through multiple pools:

```
User wants: BAT → USDC (no direct pool)
Route: BAT → ETH → USDC

1. Swap BAT for ETH in BAT/ETH pool
2. Swap ETH for USDC in ETH/USDC pool
3. Each hop adds slippage

Price impact compounds across hops.
```

---

## Liquidity Provider Economics

### Earning Fees

LPs earn trading fees automatically. With 100 ETH + 300,000 USDC (initial):

```
Over 30 days:
- Daily volume: $10M
- Daily fees at 0.30%: 10M × 0.003 = $30,000
- Pool share (assume 1%): $300
- Annualized: $300 × 365 = $109,500
- Return on capital: $109,500 / $30,000,000 = 0.365% (very thin!)

Key insight: Most pools are NOT profitable. Fees must exceed:
1. Impermanent loss
2. Slippage when exiting
3. Gas costs
```

### Impermanent Loss (IL)

**Definition:** Loss incurred when prices diverge from entry point.

```
Initial position:
- 100 ETH @ $3,000 = $300,000
- 100,000 USDC = $100,000
- Total: $400,000
- Price ratio: 3,000 USDC/ETH

After 6 months (ETH rises to $6,000):
- If you held: $300,000 + $100,000 = $400,000 × 1.5 = $600,000
- If in LP pool with same ratio:
  - To maintain x*y=k with 100 ETH purchase
  - 100 × 400,000 = 40,000,000
  - New reserves: ~66.67 ETH, 600,000 USDC
  - Your share (50%): 33.33 ETH + 300,000 USDC
  - Value: (33.33 × $6,000) + $300,000 = $499,980
  - Loss: $600,000 - $499,980 = $100,020 (16.7%)

IL% = 2√(1+x)/(1+x) - 1, where x = price ratio change

50% price change → ~5.72% IL
100% price change → ~20.01% IL
200% price change → ~49.75% IL
```

**Key:** IL is only realized when you withdraw. While in pool, IL is unrealized and offset by fees.

---

## Core Attack Vectors

### 1. **Sandwich Attacks (Front-running)**
Attacker sees pending swap, submits transaction with higher gas, takes profit.
**Protection:** Deadline, slippage parameters (see 02-slippage-protection.md)

### 2. **Sniper Bots**
Bots monitor pending transactions and execute favorable trades immediately.
**Protection:** See 03-sniper-bot-prevention.md

### 3. **Flash Loan Attacks**
Attacker borrows large amount in same transaction, manipulates pool.
**Protection:** See 04-flash-swaps.md

### 4. **MEV Extraction**
Miners/validators reorder transactions for profit.
**Protection:** See 05-mev-mitigation.md

### 5. **Oracle Manipulation**
Attacker uses flash loan to temporarily move price, manipulates oracles.
**Protection:** See 06-price-oracles.md

---

## Uniswap V4 (Latest Evolution)

**Status:** Live on mainnet (2024)

### Key Improvements

| Feature | V2 | V3 | V4 |
|---------|----|----|-----|
| **Concentrated Liquidity** | ❌ | ✅ | ✅ |
| **Custom Hooks** | ❌ | ❌ | ✅ |
| **Singleton Pattern** | ❌ | ❌ | ✅ |
| **ERC-1155 LP Tokens** | N/A | ERC-721 | ✅ |
| **Gas Efficiency** | Baseline | -20% | -30% |

#### Custom Hooks (Game Changer)
V4 allows pools to execute custom logic:
- Dynamic fees based on volatility
- Time-weighted average prices (TWAP)
- Automated LP management
- Cross-chain features

```solidity
contract DynamicFeeHook is BaseHook {
    function beforeSwap(
        address sender,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4) {
        // Set fee dynamically based on volatility
        if (isHighVolatility) {
            setFee(1.00%);  // Higher fee in volatile markets
        } else {
            setFee(0.05%);  // Lower fee in stable markets
        }
        return BaseHook.beforeSwap.selector;
    }
}
```

---

## Integration Checklist

When integrating a DEX into your protocol:

- [ ] **Liquidity Assessment**: Is there sufficient liquidity?
- [ ] **Slippage Protection**: Set reasonable limits
- [ ] **Oracle Setup**: Use TWAP for price feeds
- [ ] **Flash Loan Safety**: Validate state changes
- [ ] **MEV Awareness**: Use batching or dark pools
- [ ] **Reentrancy**: Use checks-effects-interactions pattern
- [ ] **Deadline**: Always set transaction deadline
- [ ] **Tests**: Unit + integration + simulation

---

## Quick Reference

| Concept | Impact | Details |
|---------|--------|---------|
| **k = x × y** | Core AMM formula | x*y product always constant |
| **IL% = 2√(1+x)/(1+x) - 1** | LP risk metric | Unrealized loss if prices diverge |
| **Slippage** | Trade cost | Price movement during execution |
| **MEV** | Validator profit | Value extracted by reordering txs |
| **Flash Loan** | Attack vector | Uncollateralized borrow + repay in 1 tx |
| **Sandwich Attack** | Trade hazard | Front/back-running by attackers |
| **TWAP** | Oracle mechanism | Time-weighted average price |

---

## Resources

- **Uniswap V3 Technical Whitepaper**: https://uniswap.org/whitepaper-v3.pdf
- **Uniswap V3-Core Repo**: https://github.com/Uniswap/v3-core
- **Uniswap Official Docs**: https://docs.uniswap.org/
- **Uniswap V4**: https://uniswap.org/blog/uniswap-v4

---

**Next Section:** Read `01-liquidity-pools.md` for detailed LP contract patterns and management strategies.
