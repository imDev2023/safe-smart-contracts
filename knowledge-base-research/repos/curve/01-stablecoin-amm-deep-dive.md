# Curve Finance - Stablecoin AMM Deep Dive

**Source:** https://github.com/curvefi/curve-contract
**Language:** Vyper (not Solidity)
**Purpose:** Optimized AMM for correlated assets (stablecoins)
**TVL:** $4B+
**Historical Note:** Created 2020, revolutionized stablecoin trading

---

## Problem Curve Solves

### Uniswap V2 Inefficiency for Stablecoins

**Constant Product Formula:** `x * y = k`

```
USDC → USDT swap on Uniswap:
Pool: 500k USDC, 500k USDT, k = 250B

Swap 1M USDC:
New x = 1.5M USDC
y = k / x = 250B / 1.5M = 166.67k USDT

Received: 500k - 166.67k = 333.33k USDT
Slippage: 33.3% ❌ (terrible for stablecoins!)
```

**Problem:** Formula assumes assets can have unlimited price variance, but stablecoins are pegged at 1:1

### Curve Solution: StableSwap Formula

**Hybrid Formula:** Constant-sum near equilibrium, constant-product at extremes

```
Formula: A(x + y) + xy = Ak^2

Where:
A = amplification coefficient (how aggressive to maintain 1:1 ratio)
x, y = token amounts
k = sum of tokens

High A = Aggressive peg maintenance (low slippage near 1:1)
Low A = More constant product behavior (high slippage)
```

**Result:**
```
Same swap on Curve 3Pool:
Slippage: < 0.5% ✅ (because USDC/USDT pegged)
```

---

## Architecture

### Pool Structure

```
CurvePool (for 3Pool)
├─ Token1: USDC (6 decimals)
├─ Token2: USDT (6 decimals)
├─ Token3: DAI (18 decimals)
│
├─ LPToken: 3CRV (18 decimals)
│
├─ Parameters:
│  ├─ A (amplification): controls slippage curve
│  ├─ fee: 0.04% (0.0004)
│  ├─ admin_fee: 50% of trading fees
│  └─ gamma: L2 parameter (newer pools)
│
└─ State:
   ├─ balances[i]: amount of each token
   ├─ D: invariant (sum-like)
   └─ price_oracle: EMA of prices
```

### Key Formulas

#### D Invariant (Pool Invariant)

```
D = Ideal pool value (sum of all tokens at market price)

Formula (simplified):
D = A*S + B*D^2 - B*S^3/D

Where:
S = sum of token amounts
A, B = functions of A (amplification)

Maintains: Near constant-sum when tokens equal
```

#### Exchange (Swap) Function

```
y_out = get_y(x_in)

Computes: How much y to give for x_in

Algorithm:
1. Calculate new x' = x + x_in
2. Solve for new y' using D equation
3. y_out = y - y'
4. Apply fees
```

---

## Pool Types

### 1. Plain Pools (2-4 assets)

```
3Pool: USDC, USDT, DAI
├─ Most TVL (>$1B)
├─ Most liquid
└─ Best spreads

Use: Daily stablecoin trading
```

### 2. Lending Pools

```
Compound: cUSDC, cDAI, cUSDT
├─ Underlying: USDC, DAI, USDT
├─ Earn lending interest + trading fees
└─ Smart contract risk (underlying protocol)
```

### 3. Metapool (Stable + Pool)

```
FRAX+3CRV: FRAX paired with 3Pool LP token
├─ Trade FRAX against basket of 3 stablecoins
├─ Lower slippage than bilateral pair
└─ Efficient capital use
```

### 4. Cryptopool (Non-stablecoins)

```
ETH/stETH
├─ Handles higher volatility
├─ Uses different A coefficient
├─ For correlated but non-pegged assets
```

---

## Governance & Revenue

### Fee Structure

```
Trading Fee: 0.04% (typical)

Distribution:
├─ Liquidity Providers: 50% (0.02%)
│  └─ Earn continuously on their share
│
└─ Protocol Revenue: 50% (0.02%)
   ├─ DAO treasury (Curve governance)
   └─ Voter-directed (veCRV voting)
```

### Liquidity Provider Revenue

```
Example: 3Pool with $2B TVL, $10B daily volume

Daily trading fees: $10B × 0.04% = $4M
LP share: $4M × 50% = $2M

Annual LP rewards: $2M × 365 = $730M ÷ $2B TVL = 36.5% APY

(Note: Actual varies with volume and competition)
```

---

## Curve DAO & CRV Governance

### veCRV: Vote Escrow Model

```
Mechanism:
├─ Lock CRV for 1-4 years → Get veCRV
├─ veCRV can vote on proposals
├─ Vote-directed incentives
└─ Voting power decays as lock expires

Voting Power:
veCRV = CRV locked × (time locked / max time)

Example:
Lock 1000 CRV for 4 years → 1000 veCRV
Lock 1000 CRV for 1 year → 250 veCRV
```

### Gauge System

**Gauge:** Contract that distributes CRV rewards to specific pool LPs

```
Process:
1. DAO votes to create gauge for pool X
2. LPs in pool X stake LP tokens in gauge
3. CRV rewards flow to gauge (% determined by votes)
4. LPs claim rewards proportional to stake

Incentive Alignment:
├─ veCRV holders vote for pools they like
├─ Rewards flow to voted pools
├─ High APY attracts LPs
└─ TVL/liquidity increases
```

---

## StableSwap Math Deep Dive

### The Invariant

```solidity
function get_D(xp: uint256[N_COINS], A: uint256) -> uint256:
    S: uint256 = 0
    for i in range(N_COINS):
        S += xp[i]

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = A * N_COINS

    for _ in range(256):
        D_P: uint256 = D
        for i in range(N_COINS):
            D_P = D_P * D / (xp[i] * N_COINS)

        Dprev = D
        D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P)

        if abs(D - Dprev) <= 1:
            break

    return D
```

### Get Y (Calculate Output)

```solidity
function get_y(i: uint256, j: uint256, x: uint256, xp: uint256[N_COINS]) -> uint256:
    // i = input token index
    // j = output token index
    // x = input amount
    // xp = adjusted balances

    D: uint256 = get_D(xp, A)
    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = A * N_COINS

    // Update xp with new x (remove old value, add new)
    xp[i] = x
    // Calculate what D should be

    // Iterate to find y
    Yprev: uint256 = 0
    Y: uint256 = D / N_COINS

    for _ in range(256):
        Yprev = Y
        Y = (Y*Y + c) / (2*Y + S_ - D)

        if abs(Y - Yprev) <= 1:
            break

    return Y
```

---

## Liquidity Provider Flow

### Add Liquidity

```
User deposits: 100 USDC, 100 USDT, 100 DAI

Process:
1. Check balances before/after
2. Calculate LP tokens to mint (using D invariant)
3. Transfer tokens
4. Mint LP tokens
5. Return LP token amount

Slippage Risk:
├─ If pool imbalanced, may lose value
├─ Specify min_mint_amount to protect
└─ Rebalancing earns from arbitrage
```

### Remove Liquidity

```
User burns: 100 LP tokens

Options:
├─ Remove balanced (all 3 tokens equally)
├─ Remove single token (all as USDC)
├─ Remove specific amounts (custom mix)

Each has different slippage characteristics
```

---

## Advanced: Concentrated Liquidity (v2)

### Native Liquidity Concentration

Unlike Uniswap V3, Curve pools don't support concentrated ranges natively. However:

```
Capital Efficiency Alternatives:
├─ Smaller pools (lower liquidity)
├─ Leverage via lending (borrow more to provide more)
└─ Exotic pool structures
```

---

## Smart Contract Structure

### Core Contracts

```
StableSwap (or similar)
├─ exchange(): Swap tokens
├─ add_liquidity(): Provide liquidity
├─ remove_liquidity(): Withdraw
├─ get_D(): Calculate invariant
├─ get_y(): Calculate output
└─ admin functions

ERC20 LP Token
├─ Standard ERC20 interface
├─ Minted on deposit
└─ Burned on withdrawal

Gauge (Optional)
├─ Staking contract for LP tokens
├─ Distributes CRV rewards
└─ Tracks gauge weight (voting)
```

---

## Security Considerations

### 1. Rounding Errors

```
Problem: Fixed-point arithmetic accumulation

Mitigation:
├─ Iterative solving (converges within 1 wei)
├─ Careful ordering of operations
└─ Test with extreme amounts
```

### 2. Oracle Attacks

```
Risk: If price_oracle is used for decisions

Mitigation:
├─ EMA (exponential moving average) is slow to change
├─ Not used for critical logic
└─ Always verify with external oracle
```

### 3. Slippage & Sandwich Attacks

```
Protection:
├─ min_dy parameter (set acceptable output)
├─ Mempool monitoring (MEV)
└─ Use private RPC if concerned
```

---

## Governance Attacks

### Vote Escrow Risks

```
Flash Loan Attack Scenario (prevented):
1. Attacker borrows 1M CRV via flash loan
2. Locks CRV → Gets veCRV voting power
3. Votes on malicious proposal
4. Repays CRV

Prevention:
├─ Voting power snapshot at block (not tx)
├─ Delegation tracked historically
└─ Flash loans can't increase voting power
```

---

## Resources

- **Docs:** https://docs.curve.fi/
- **GitHub:** https://github.com/curvefi/curve-contract
- **Vyper Contracts:** All written in Vyper (different from Solidity)
- **Audits:** Trail of Bits, others

---

**Complexity:** High (complex math)
**Security:** Excellent (audited, battle-tested)
**Decentralization:** Good (governance DAO)
**Gas Efficiency:** Good (lower than Uniswap for stablecoins)
**TVL:** $4B+ (largest stablecoin DEX)
