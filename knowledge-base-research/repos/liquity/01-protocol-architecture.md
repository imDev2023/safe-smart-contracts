# Liquity: Decentralized Borrowing Protocol Architecture

> Collateralized debt protocol without interest - ETH → LUSD stablecoin

**Repo:** https://github.com/liquity/dev.git
**Purpose:** Interest-free borrowing against ETH collateral with algorithmic stability
**Key Concept:** Stabilit y maintained via economic incentives, not governance

---

## Core System Overview

### What is Liquity?

- **User Action:** Deposit ETH → Mint LUSD (stablecoin pegged to $1)
- **Minimum Collateral:** 110% ICR (Individual Collateral Ratio)
- **No Interest:** Borrow at 0% interest (small upfront fee only)
- **Redemption Mechanism:** LUSD holder can redeem for ETH at $1 peg
- **Stability Pool:** Insurance mechanism for liquidations
- **LQTY Token:** Governance + staking rewards

---

## Architecture Components

### 1. Trove System (Position Management)

**What is a Trove?**
```
Trove = Individual collateralized debt position
├── Collateral (ETH amount)
├── Debt (LUSD amount)
└── ICR = Collateral Value / Debt (min 110%)
```

**Key Contracts:**
- `BorrowerOperations.sol` - Open/adjust/close troves
- `TroveManager.sol` - Liquidation, redemption logic
- `SortedTroves.sol` - Ordered list by ICR (linked list)

**Source:** `packages/contracts/contracts/BorrowerOperations.sol:1-100`

---

### 2. Individual Collateral Ratio (ICR)

```
ICR = (Collateral Value in USD) / (Debt in LUSD)

Examples:
├── ICR = 150% → Healthy trove, 1.5 ETH value per 1 LUSD debt
├── ICR = 110% → Minimum allowed, risky
├── ICR < 110% → Liquidation eligible
```

**Calculation:**
```solidity
ICR = (collateral * price) / debt

// In TroveManager.sol
uint ICR = LiquityMath.computeCR(coll, debt, price);
```

**Price Source:** Oracle (Chainlink feed fallback to Tellor)

---

### 3. Total Collateral Ratio (TCR)

```
TCR = (Total System Collateral Value) / (Total System Debt)

Normal Mode:   TCR >= 150%
Recovery Mode: TCR < 150%  (triggered to protect system)
```

**Significance:**
- TCR < 150% → System in stress, enters Recovery Mode
- Recovery Mode allows liquidations at lower ICR to protect solvency
- **Source:** `TroveManager.sol:getTCR()`

---

## Liquidation Mechanism

### Normal Mode Liquidations (TCR >= 150%)

**Trigger:** ICR < 110% AND TCR >= 150%

**Process:**
```
1. Bot detects ICR < 110%
2. Calls TroveManager.liquidate(troveOwner)
3. System liquidates trove via Stability Pool
```

**What Happens:**
```
Liquidated Trove:
├── Collateral (ETH) → Stability Pool
├── Debt (LUSD) → Burned against Stability Pool deposits
└── Trove closed

Stability Pool Depositors:
├── Lose LUSD (up to proportion of deposit)
└── Gain ETH (from liquidated collateral)
```

**Source:** `TroveManager.sol:_liquidateNormalMode()`

---

### Recovery Mode Liquidations (TCR < 150%)

**Trigger:** TCR < 150% (system-wide stress)

**Liquidation Allowed At:** ICR < 110% * TCR (lower threshold)

**Purpose:** Protect system solvency during price crashes

**Example:**
```
If TCR = 130% (recovery mode active)
Then liquidate if: ICR < 110% * (130% / 150%) = 95.3%
(More aggressive liquidations to raise TCR back to 150%)
```

---

## Stability Pool Mechanism

### How It Works

**Stability Pool = Insurance Pool for Liquidations**

```
Participants (Stability Pool Members):
1. Deposit LUSD (become protected)
2. When trove liquidated:
   a. LUSD burned to offset debt
   b. ETH collateral distributed to them
```

**Example:**
```
Scenario:
├── Stability Pool has 100,000 LUSD from 100 members
├── Liquidation: 500 LUSD debt, 2 ETH collateral
├── All members' shares:
│   ├── LUSD reduced by (500 / 100,000) = 0.5%
│   └── ETH gained = (2 ETH / 100,000 LUSD deposited) per LUSD
└── Members make profit on ETH/LUSD trade
```

**Source:** `StabilityPool.sol:100-200`

---

### Depositor Incentives

Stability Pool depositors earn:
1. **ETH gains** from liquidations (frontrunning discount)
2. **LQTY rewards** (staking yield)
3. **Price appreciation** of gained ETH (if ETH price rises)

**Risk:**
- Lose LUSD if liquidations exceed deposit
- Cannot withdraw during liquidation (temporary)

---

## LUSD Redemption Mechanism

### What is Redemption?

```
LUSD Holder Action:
├── "I will trade my 1,000 LUSD for $1,000 worth of ETH"
└── System finds troves and returns collateral in order

System Response:
├── Selects trove with lowest ICR
├── Redeems against its collateral
├── If 1,000 LUSD > trove debt, continue to next trove
└── Returns ETH to redeemer
```

**Source:** `TroveManager.sol:_redeemCollateral()`

---

### Redemption Fee

```
Redemption Fee = Dynamic fee based on system stress

Fee Formula:
├── Base: 0.5%
├── Increases when: TCR < 150%
└── Maximum: 50% (rare, prevents redemption spam)

Example:
├── Redeem 1,000 LUSD
├── Fee = 1,000 * 0.5% = 5 LUSD
├── Receive: 995 LUSD worth of ETH
```

**Why Dynamic?**
- When TCR low = need to protect system
- Redemptions increase debt (raise TCR)
- Higher fee discourages excessive redemptions

**Source:** `TroveManager.sol:_getRedemptionFee()`

---

### Price Floor Mechanism

Redemptions create LUSD price floor:

```
If LUSD trades below $1:
├── Arbitrageur redeems cheap LUSD for $1 ETH
├── Collects free arbitrage profit
├── Pushes LUSD price back to $1

Example:
├── LUSD = $0.99
├── Redeem 10,000 LUSD (pay $9,900)
├── Receive $10,000 worth ETH
├── Profit = $100 (arbitrage)
└── Repetition pushes price back to $1.00
```

---

## Recovery Mode

### When Triggered

```
TCR < 150% → Recovery Mode Activated
```

### Changes in Recovery Mode

| Aspect | Normal Mode | Recovery Mode |
|--------|------------|---------------|
| **Liquidation ICR Threshold** | 110% | 110% × (TCR / 150%) |
| **Borrow Fee** | ~0.5% | Increased |
| **Max LUSD Mint** | Unlimited | Capped |
| **Redemption** | Allowed | Allowed |
| **New Trove Creation** | Allowed | Blocked if low ICR |

**Goal:** Protect system by liquidating riskier positions when TCR drops

---

## LQTY Token Architecture

### Token Functions

1. **Governance** - Vote on system parameters
2. **Staking** - Earn LUSD/ETH from:
   - Issuance fees from new LUSD
   - Redemption fees
   - Borrowing fees

### Staking Rewards Flow

```
When User Borrows:
├── Pay 0.5% upfront fee (added to debt)
├── Fee collected → LQTY Staking contract
└── Stakers receive portion in LUSD

When User Redeems:
├── Pay dynamic fee (0.5% - 50%)
├── Fee paid in ETH
└── Stakers receive portion in ETH
```

**Source:** `LQTYStaking.sol:100-150`

---

## Token Flow

### LUSD Creation

```
User: "I want to borrow LUSD"
├── Deposit ETH collateral
├── Pay 0.5% upfront fee (in LUSD)
├── Mint LUSD (backed by ETH)
└── Collateral locked until debt repaid
```

### LUSD Destruction

```
User: "I want to repay"
├── Send LUSD to system
├── Collateral released
└── LUSD burned
```

---

## Sorted Trove List

### Why Ordering Matters

```
System needs to find liquidatable troves quickly
├── Iterate from lowest ICR
├── Liquidate all troves until TCR recovers
└── Avoid scanning entire list
```

### Implementation

```
SortedTroves = Doubly-Linked List sorted by ICR

Operations:
├── insert(troveOwner, icr, prevId, nextId)  O(log n)
├── remove(troveOwner)                        O(1)
├── getSize()                                 O(1)
└── getFirst() / getLast()                    O(1)

Search for insertion point: Off-chain, then pass hints
```

**Source:** `SortedTroves.sol:50-100`

**Gas Optimization:** Use hints from off-chain search to make insertion O(1)

---

## Fee Structure

| Fee Type | Amount | When |
|----------|--------|------|
| **Borrowing Fee** | ~0.5% | When minting LUSD |
| **Redemption Fee** | 0.5% - 50% | Dynamic, when redeeming |
| **Gas Compensation** | 150 LUSD | Fixed, for liquidation tx |

### Gas Compensation

```
Why Compensate?
├── Liquidation bots pay real gas (EOA transactions)
├── System compensates 150 LUSD for service
├── Ensures sufficient liquidation incentive

Implementation:
├── Trove debt increased by 150 LUSD
├── Liquidator receives 150 LUSD
└── Effective cost to borrower: ~$150 (150 * $1 LUSD)
```

---

## Core Contract Interfaces

### BorrowerOperations

```solidity
function openTrove(
    uint _maxFeePercentage,
    uint _LUSDAmount,
    address _upperHint,
    address _lowerHint
) payable returns (uint);

function adjustTrove(
    uint _maxFeePercentage,
    uint _collWithdrawal,
    uint _debtChange,
    bool _isDebtIncrease,
    address _upperHint,
    address _lowerHint
) payable;

function closeTrove();

function addColl(address _upperHint, address _lowerHint) payable;
function withdrawColl(uint _amount, address _upperHint, address _lowerHint);
function withdrawLUSD(uint _maxFeePercentage, uint _amount, address _upperHint, address _lowerHint);
function repayLUSD(uint _amount, address _upperHint, address _lowerHint);
```

---

### TroveManager

```solidity
function liquidate(address _borrower);

function redeemCollateral(
    uint _LUSDAmount,
    address _firstRedemptionHint,
    address _upperPartialRedemptionHint,
    address _lowerPartialRedemptionHint,
    uint _partialRedemptionHintNICR,
    uint _maxIterations,
    uint _maxFeePercentage
);

function getTrove(address _borrower)
    returns (uint coll, uint debt, uint stake);

function getCurrentICR(address _borrower, uint _price) returns (uint);
function getTCR(uint _price) returns (uint);
```

---

## Key Implementation Patterns

### Hint-Based Optimization

```solidity
// Without hints: O(n) to find sorted position
// With hints: O(1) if hints correct, O(log n) if wrong

function adjustTrove(..., address _upperHint, address _lowerHint) {
    // Verify hint positions or search around them
    // If correct hints: update O(1)
    // If wrong hints: search and update O(log n)
}
```

**Off-chain:** Bot finds correct positions off-chain, passes as hints
**On-chain:** Contract validates hints, proceeds accordingly

---

### Event-Driven Liquidations

```solidity
event TroveUpdated(
    address indexed _borrower,
    uint _debt,
    uint _coll,
    uint _stake,
    TroveManager.TroveManagerOperation _operation
);
```

**How bots liquidate:**
1. Listen to TroveUpdated events
2. Detect ICR < 110%
3. Call liquidate() transaction
4. Earn liquidation profit (liquidation discount)

---

## System Stability Mechanisms

| Mechanism | How It Works | Purpose |
|-----------|-------------|---------|
| **Stability Pool** | LUSD deposit + ETH gains | Offsets liquidations |
| **Redemption** | Trade LUSD for ETH at $1 | Enforce price peg |
| **Recovery Mode** | Aggressive liquidation at TCR < 150% | Protect solvency |
| **Fee Adjustment** | Dynamic redemption fee | Incentivize healthy TCR |
| **Liquidation Bot Incentive** | Liquidation profit | Encourage active liquidations |

---

## Gas Cost Patterns

**Typical Costs (Mainnet):**
- Open Trove: ~150,000 gas
- Adjust Trove: ~100,000 gas
- Liquidation: ~200,000+ gas
- Redemption: ~200,000+ gas (scales with troves redeemed)

**Optimization via Hints:**
- Without hints: Liquidation ~300,000+ gas
- With correct hints: ~200,000 gas (~33% savings)

---

## When to Integrate Liquity

1. **Stablecoin Swap:** LUSD is major liquid stablecoin
2. **Liquidation Bot:** Automated liquidation of underwater troves
3. **Flash Loan Source:** Borrow LUSD temporarily
4. **Price Feed:** Use LUSD price as stability indicator
5. **Collateral Feedback:** Monitor system health (TCR) for risk assessment

---

**Status:** Complete protocol architecture documented
**Key Files for Deep Understanding:**
- `BorrowerOperations.sol` - User trove operations
- `TroveManager.sol` - Liquidation & redemption logic
- `StabilityPool.sol` - Insurance mechanism
- `SortedTroves.sol` - ICR ordering
