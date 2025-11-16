# Synthetix Derivatives Protocol - Deep Dive

**Source:** https://github.com/Synthetixio/synthetix
**Purpose:** Decentralized derivatives platform with synthetic assets
**TVL:** $500M+
**Latest:** Synthetix V3 (major redesign)

---

## Unique Architecture

**Traditional DEX:** Token A ↔ Token B (direct swap)
**Synthetix:** Synthetic representation of any asset

```
Without Synthetix:
├─ Want sGOLD exposure?
├─ Need real gold or futures (centralized)
└─ Limited by liquidity

With Synthetix:
├─ Mint sGOLD synthetic
├─ Price feed from oracle
├─ Trade against SNX stakers
└─ 24/7 decentralized
```

---

## Core Concept: Synthetic Assets

### Synth Creation

```solidity
// SNX staker mints synths
struct SynthPosition {
  address owner;
  uint256 stakedSNX;              // Collateral
  uint256 collateralValue;        // USD equivalent
  mapping(bytes32 => int256) debt; // Synth debts
}

// User stakes 1000 SNX ($5000)
// Can mint synths up to C-Ratio (e.g., 600%)
// Max synths = $5000 / 600% = $8333 worth

// Can mint:
// - 8333 sUSD (stablecoin)
// - 1.0 sETH (if ETH = $2000)
// - 10 sGBP (if GBP = $1.25)
// Mix and match, total ≤ $8333
```

### Pooled Liquidity Model

```
Traditional Order Book:
├─ Buyer: I want 1 BTC at $45k
├─ Seller: I have 1 BTC for $46k
└─ No match = No trade

Synthetix Pooled Model:
├─ SNX stakers = Liquidity pool
├─ User trades against the pool
├─ Pool takes opposite side
└─ Always liquid
```

---

## Architecture

### Synthetix Core System

```
┌─────────────────────────────────────┐
│     SNX Token Holder (Staker)        │
├─────────────────────────────────────┤
│                                     │
│  1. Stake SNX                       │
│  └─ Deposit to staking contract     │
│                                     │
│  2. Earn C-Ratio right              │
│  └─ Can mint synths                 │
│                                     │
│  3. Mint Synths                     │
│  ├─ sUSD (stablecoin)               │
│  ├─ sETH (Ethereum derivative)      │
│  ├─ sGOLD (Gold derivative)         │
│  └─ Up to C-Ratio limit             │
│                                     │
│  4. Participate in liquidations     │
│  └─ Earn fees from liquidations     │
│                                     │
│  5. Claim rewards                   │
│  ├─ Inflation rewards (SNX)         │
│  ├─ Trading fees (sUSD)             │
│  └─ Liquidation fees (sUSD)         │
│                                     │
└─────────────────────────────────────┘

Synth Trader:
├─ Exchanges sUSD ↔ sETH
├─ No price slippage (oracle-based)
├─ Pays 0.3% trading fee
└─ SNX stakers receive fees
```

### Debt Pool Mechanics

```
Key Insight: All stakers share a single debt pool

User A:
├─ Stake 1000 SNX
├─ Mint 5000 sUSD
└─ Owes: 5000 sUSD

User B:
├─ Stake 1000 SNX
├─ Mint 0.5 sETH (=$1000)
└─ Owes: 0.5 sETH + pro-rata share of User A's debt

Pool Debt:
├─ sUSD: 5000 (User A)
├─ sETH: 0.5 (User B)
└─ Total Debt Value: $7000 (if ETH=$2000)

If sETH price rises to $3000:
├─ sETH debt = 0.5 × $3000 = $1500
├─ Pool debt = $5000 + $1500 = $6500
├─ User A's debt: $5000 + $250 (share of price impact)
└─ User B's debt: 0.5 sETH (unchanged amount, increased value)
```

---

## C-Ratio & Collateralization

### Collateralization Ratio

```
C-Ratio = Staked SNX Value / Total Debt Value

Minimum C-Ratio: 600% (industry best)
├─ If C-Ratio < 600%, can't unstake
├─ If C-Ratio < 400%, liquidation eligible
└─ Must maintain ratio or face penalties

Formula:
C-Ratio = (1000 SNX × $5/SNX) / ($8333 total synths)
C-Ratio = $5000 / $8333 = 60% = 600% ratio

Inverse: Debt Ratio = 1 / C-Ratio = 16.6%
```

### Mint Limits

```solidity
maxSynthValue = (stakedSNX × snxPrice) / minimumCRatio

Example:
├─ Staked: 1000 SNX
├─ SNX Price: $5
├─ Min C-Ratio: 600%
├─ Max Synths: (1000 × $5) / 6 = $8333
```

---

## Price Feed System (Oracle)

### Chainlink Oracle Integration

```solidity
interface IExchangeRates {
  function rateForCurrency(bytes32 currencyKey)
    external
    view
    returns (uint256 rate);

  // Example rates maintained by Chainlink
  // sETH: $2500
  // sBTC: $45000
  // sGOLD: $2000/oz
  // sAUD: $0.75
}
```

### Price Accuracy

```
Impacts:
├─ C-Ratio calculations (liquidation trigger)
├─ Mint/burn amounts (what's the debt value?)
├─ Trading prices (synth exchange rates)
└─ Liquidation penalties (what's fair?)

Risk: Oracle manipulation
├─ Chainlink is decentralized
├─ Multiple nodes submit prices
├─ Aggregated into median
└─ Historical data prevents manipulation
```

---

## Synth Mechanics

### Available Synths

```
Stable Assets:
├─ sUSD: US Dollar
├─ sEUR: Euro
├─ sGBP: British Pound
└─ sAUD: Australian Dollar

Commodities:
├─ sGOLD: Gold
├─ sOIL: Crude Oil (price tracks)
└─ sSILVER: Silver

Crypto:
├─ sETH: Ethereum
├─ sBTC: Bitcoin
├─ sADA: Cardano
└─ sLINK: Chainlink

Indexes:
├─ sDEFI: DeFi index
├─ sCEX: Centralized Exchange index
└─ sINVERSES: Inverse (short) positions

Inverse Synths (Shorts):
├─ iBTC: Inverse Bitcoin (gains when BTC falls)
├─ iETH: Inverse Ethereum
└─ Lose value when underlying rises
```

### Synth Exchange

```solidity
interface ISynthetix {
  function exchange(
    bytes32 sourceCurrencyKey,  // sETH
    uint256 sourceAmount,        // 1 ETH
    bytes32 destinationCurrencyKey // sUSD
  ) external returns (uint256 amountReceived);

  // Example:
  // exchange(sETH, 1e18, sUSD)
  // Input: 1 sETH (worth $2500)
  // Output: 2500 sUSD
  // Fee: $7.50 (0.3%)
  // Received: 2492.5 sUSD
}
```

---

## Incentive System

### Staker Rewards

```
Revenue Sources:
├─ Trading Fees: 0.3% on all synth swaps
├─ Liquidation Fees: 5-10% from liquidations
└─ Inflation: New SNX minted (decreasing over time)

Distribution:
├─ Weekly snapshot of C-Ratio
├─ Rewards distributed pro-rata
├─ Stakers must claim (not auto-distributed)
└─ Unclaimed rewards expire after 52 weeks

Example:
├─ Total SNX staked: 100M
├─ Weekly trading volume: $1B
├─ Trading fees: $1B × 0.3% = $3M
├─ Your stake: 1M SNX (1%)
├─ Your share: $3M × 1% = $30k/week
└─ 1-year return: $30k × 52 = $1.56M annually
```

---

## Liquidation System

### When Liquidation Occurs

```
Triggers:
├─ C-Ratio drops below 400%
│  └─ Account flagged
│
├─ Account remains below 400% for 7 days
│  └─ Becomes liquidation-eligible
│
└─ Liquidator calls liquidation
   └─ Account collateral/debt restructured
```

### Liquidation Process

```solidity
function liquidateAccount(
  address account
) external {
  // 1. Verify account C-Ratio < 400%
  require(getAccountCRatio(account) < 4e18);

  // 2. Calculate liquidation penalty
  // Typically 5-10% of collateral
  uint256 penalty = (collateral * 10) / 100;

  // 3. Transfer penalty to liquidator
  snx.transfer(msg.sender, penalty);

  // 4. Burn synths to reduce debt
  // Remaining SNX collateral reduced
}
```

### Liquidation Rewards

```
Incentive: 10% liquidation fee

Example:
├─ Account has: 1000 SNX ($5000)
├─ Account owes: 8333 sUSD
├─ C-Ratio: 60% (< 400% threshold)
├─ Liquidation penalty: 1000 × 10% = 100 SNX
├─ Liquidator earns: 100 SNX ($500)
└─ Remaining account: 900 SNX + debt restructure
```

---

## Advanced: SIP (Synthetix Improvement Proposals)

### Governance

```
Changes via SIP:
├─ C-Ratio adjustments
├─ New synths
├─ Fee changes
├─ Smart contract upgrades
└─ Liquidation parameters

Process:
1. Draft SIP (community discussion)
2. SNX stakers vote (weighted by stake)
3. If approved, protocol council executes
4. Implemented via proxy upgrade
```

---

## Recursive Staking & Leverage

### Dangerous but possible

```solidity
contract HighRiskLeverage {
  ISynthetix synthetix;

  // 5x leverage strategy (very risky)
  function executeRecursiveLeverage() external {
    for (uint i = 0; i < 5; i++) {
      // Stake SNX, mint synths, buy SNX with synths
      uint256 snx = msg.value;
      synthetix.stake(snx);

      // Mint at 600% C-Ratio
      uint256 canMint = (snx * 5 / 6);  // Max borrow 5/6
      synthetix.mint(canMint);

      // Buy more SNX with minted synths
      snx = dex.swap(canMint, sUSD, SNX);
    }
  }
}
```

**Risks:**
- If SNX drops 20%, liquidation cascades
- Each loop adds more liquidation risk
- Only viable with 30%+ C-Ratio buffer
- **Recommended: Don't do this**

---

## Smart Contract Structure

### Core Contracts

```solidity
Synthetix (Main)
├─ stake(): Lock SNX
├─ unstake(): Unlock SNX (if C-Ratio safe)
├─ mint(): Issue synths
├─ burn(): Repay synth debt
└─ liquidateAccount(): Force liquidation

SynthToken (Each synth)
├─ ERC20 compatible
├─ Can't be transferred (synthetix.exchange instead)
├─ Tracks position for each user
└─ Redenominates on synth changes

ExchangeRates
├─ Chainlink oracle integration
├─ Stores latest prices for all synths
├─ Used for C-Ratio and exchange calcs
└─ Historical data for liquidation

FeePool
├─ Collects 0.3% trading fees
├─ Distributes to SNX stakers
├─ Weekly rewards distribution
└─ Liquidation fee handling
```

---

## Comparison with Other Derivatives

| Platform | Type | Leverage | Liquidity | Decentralized |
|----------|------|----------|-----------|--------------|
| **Synthetix** | Synthetic | 6x (600% C-Ratio) | ✅ Always | ✅ Full |
| **dYdX** | Lending | 4x (150% C-Ratio) | ⚠️ Pool-based | ✅ Full |
| **Aave** | Lending | 3x (100% C-Ratio) | ✅ Good | ✅ Full |
| **Binance Futures** | Derivatives | 125x | ✅ Excellent | ❌ Centralized |
| **Kwenta (on Synthetix)** | UI Layer | Customizable | ✅ Good | ✅ Full |

---

## Security Considerations

### 1. Oracle Risk

```
Risk: Chainlink compromise
├─ Multiple node operators vote
├─ Median price selected
├─ Anomalies detected
└─ Hard to manipulate

Mitigation:
├─ Synthetix DAO monitors closely
├─ Circuit breakers for extreme moves
└─ Community can fork if needed
```

### 2. Liquidation Risk

```
Risk: Unexpected price drop
├─ sETH drops 30% → Many liquidations
├─ Liquidators may not have capital
├─ System becomes insolvent
└─ Remaining stakers lose funds

Mitigation:
├─ C-Ratio buffer (don't go to limit)
├─ Monitoring tools
├─ Insurance fund (future)
└─ Liquidation rewards incentivize participation
```

### 3. Smart Contract Risk

```
Risk: Bug in contract logic
├─ Incorrect liquidation
├─ C-Ratio calculation error
├─ Fee distribution bug
└─ Lost funds

Mitigation:
├─ Multiple audits (ConsenSys, etc)
├─ Automated testing (100%+ coverage)
├─ Bug bounties
└─ Emergency pause capability
```

---

## Integration Patterns

### Pattern 1: Leverage Trading Bot

```solidity
contract LeveragedTrader {
  ISynthetix snx;

  // Leveraged BTC short
  function shortBTC() external {
    // Stake SNX → Mint sUSD
    snx.stake(1000 SNX);
    snx.mint(5000 sUSD);

    // Buy inverse Bitcoin (iBTC)
    // iBTC gains when BTC falls
    exchange(sUSD, iBTC);
  }
}
```

### Pattern 2: Hedged Yield Farm

```solidity
contract HedgedYield {
  // Long stETH, short ETH (hedge)
  // Captures stETH APY without price risk

  function executeHedge() external {
    // Long: Deposit stETH in Aave
    aave.supply(stETH);

    // Short: Use Synthetix to short ETH
    snx.stake(snx);
    snx.mint(sUSD);
    exchange(sUSD, iETH);  // Inverse ETH

    // Net: stETH yield gains, ETH short cancels price risk
  }
}
```

---

## Resources

- **Docs:** https://docs.synthetix.io
- **GitHub:** https://github.com/Synthetixio/synthetix
- **Dashboard:** https://staking.synthetix.io
- **Trade:** https://kwenta.io (DEX for Synths)

---

**Complexity:** Very High (leverage + complex debt pool)
**Security:** Good (audited, but high-risk system)
**Gas Efficiency:** Medium (complex calculations)
**Best For:** Advanced derivatives, hedging, leverage
**Warning:** High-risk, requires careful C-Ratio management
