# Alchemix Self-Paying Loans - Deep Dive

**Source:** https://github.com/alchemix-finance/alchemix-protocol
**Concept:** Collateral yield repays debt automatically
**TVL:** $200M+
**Innovation:** First protocol with self-repaying loans

---

## Unique Innovation

**Traditional Loan:**
```
Borrow: 100k USDC
Interest Rate: 5%
Term: 1 year
Total Repay: 105k USDC

Problem: User pays 5k in interest
```

**Alchemix Loan:**
```
Deposit: 100k ETH
Collateral Yield: 3.5% (from Lido staking)
Borrow: 50k alUSD
Interest Rate: 0% (paid by yield!)
After 1-2 years: Debt fully repaid automatically
```

---

## Architecture

### Alchemist Contract (Core)

```solidity
interface IAlchemist {
  // Deposit collateral (yieldToken)
  function depositUnderlying(
    uint256 amount,
    address recipient,
    uint256 minimumAmountOut
  ) external returns (uint256 shares);

  // Withdraw collateral
  function withdrawUnderlying(
    uint256 shares,
    address recipient,
    uint256 minimumAmountOut
  ) external returns (uint256 amount);

  // Borrow debt tokens (alUSD)
  function mint(
    uint256 amount
  ) external returns (uint256 actualAmount);

  // Repay debt
  function burn(
    uint256 amount
  ) external returns (uint256 actualAmount);

  // Management
  function reportLoss(
    address strategy,
    uint256 loss
  ) external;
}
```

### Yield Token Integration

**Underlying Assets:**
- stETH: Staked ETH (earns 3.5% APY from Beacon Chain)
- Other yield-bearing assets (future)

**How Alchemix Gets Yield:**
```
Flow:
1. User deposits ETH
2. Alchemix wraps to stETH via Lido
3. stETH sent to yield strategy (Lido StakingStrategy)
4. Daily: Lido distributes staking rewards
5. Alchemix collects and applies to debt automatically
```

---

## Debt Repayment Mechanics

### Automatic Debt Reduction

```solidity
struct Account {
  uint256 shares;                    // Collateral shares
  mapping(address => int256) debt;   // Debt per asset
}

// Daily process (permissionless)
function harvestAndRepay() external {
  // 1. Collect yield from strategies
  uint256 yield = strategy.harvest();

  // 2. Calculate debt reduction
  uint256 accumulatedFees = 0;
  for (each account) {
    if (account.debt > 0) {
      uint256 accountShare = (account.debt / totalDebt);
      uint256 repayAmount = yield × accountShare;

      // 3. Reduce debt
      account.debt -= repayAmount;
    }
  }
}
```

### Share vs Debt Tracking

```
Alchemist separates:

Shares:
├─ Represents collateral ownership
├─ Stake increases via rewards compounding
└─ User can't directly control

Debt:
├─ stablecoin debt (alUSD, alETH)
├─ Decreases automatically via yield
└─ User can repay early if desired

Invariant:
├─ collateralValue ≥ debtValue × (1 / LTV)
├─ LTV ratio (e.g., 50%) prevents liquidation
└─ Maintained automatically via yield collection
```

---

## Yield Strategy System

### Strategy Architecture

```
IYieldStrategy:
├─ deposit(tokens): Put tokens to work
├─ withdraw(shares): Claim tokens
├─ harvest(): Get rewards
├─ estimatedTotalAssets(): Current value
└─ claimable(): Unclaimed rewards

LidoStakingStrategy (ETH → stETH):
├─ Deposits ETH to Lido
├─ Receives stETH (earning 3.5% APY)
├─ Accumulates daily rewards
└─ Reports to Alchemist
```

### Flow Diagram

```
User ETH (100)
      ↓
Alchemist (deposits)
      ↓
LidoStakingStrategy (invests)
      ↓
Lido (staking)
      ↓
Beacon Chain (earns 3.5% APY)
      ↓
Daily Rewards (3.5% accumulated)
      ↓
Strategy collects (harvest)
      ↓
Alchemist receives yield
      ↓
Automatically repays debt
      ↓
User's alUSD debt decreases
```

---

## LTV & Liquidation

### Loan-to-Value Ratio

```
LTV = Total Debt / Total Collateral Value

Example:
Collateral: 100 ETH ($200k)
Debt: 50k alUSD
LTV = 50k / 200k = 25% (very safe)

Max LTV: 50% (Alchemix limit)
└─ Can borrow up to 50% of collateral

Safe Range: 30-40%
└─ Leaves buffer for ETH price drops
```

### Liquidation Mechanics

```
Trigger:
├─ ETH price drops 40% → $120k collateral
├─ If borrowing max: 50k / 120k = 41.7% LTV
├─ Exceeds safe threshold
└─ LIQUIDATION

Liquidation Process:
1. Keepers identify unhealthy account
2. Liquidator buys debt discount (~5-10%)
3. Liquidator receives collateral
4. Account debt reduced
5. Collateral seized

Example:
├─ Account owes: 50k alUSD
├─ Liquidator buys: 50k alUSD - 2.5k discount
├─ Liquidator pays: 47.5k alUSD
├─ Liquidator gets: ~60 ETH collateral
└─ Account's remaining ETH: 40 ETH
```

---

## Fee Structure

### Minting Fee

```solidity
// When user borrows alUSD
function mint(uint256 amount) external {
  uint256 fee = (amount * mintingFeePercentage) / 1e18;
  // e.g., 1% fee = 100 alUSD borrowed → 1 alUSD fee

  // User needs: amount + fee
  // Example: Borrow 50k → Pay 50.5k
}
```

### Repayment Fee

```
When manually repaying:
├─ Small fee to protocol
├─ Incentivizes auto-repayment
└─ Automatic repayment has 0 fee
```

---

## Risk Management

### Collateral Risks

```
Risks:
├─ Lido key compromise
│  └─ Unlikely (well-separated operators)
│
├─ Beacon Chain bug
│  └─ Shared by all staking (not Alchemix-specific)
│
├─ ETH price drop
│  └─ Liquidation risk (requires 40%+ drop to danger)
│
└─ Smart contract bug
   └─ Insurance fund covers losses
```

### Insurance Fund

```
Mechanics:
├─ Funded by protocol fees
├─ Covers slashing + smart contract bugs
├─ Current size: $50M+
└─ Can cover worst-case scenarios

Protection Layers:
├─ Liquidation system (prevents bad debt)
├─ Yield buffer (covers small losses)
└─ Insurance (covers large losses)
```

---

## Recursive Staking Opportunities

### Leverage Strategies

```solidity
// Advanced: Use borrowed alUSD to get more collateral

contract RecursiveStakingBot {
  function executeRecursive(uint256 ethAmount) external {
    for (uint i = 0; i < iterations; i++) {
      // 1. Deposit ETH → Get yield capacity
      alchemist.depositUnderlying(ethAmount, address(this), 0);

      // 2. Borrow alUSD (50% ratio)
      uint256 borrowAmount = ethAmount / 2;
      alchemist.mint(borrowAmount);

      // 3. Swap alUSD → ETH (use DEX)
      ethAmount = dex.swap(borrowAmount, alUSD, ETH);

      // Loop: Use borrowed funds as collateral for more borrowing
    }
  }
}
```

**Risk:**
- Each iteration adds more leverage
- If ETH drops, liquidation cascades
- Only safe with significant buffer (20-30% LTV)

---

## Debt Token Mechanics

### alUSD Stablecoin

```
Properties:
├─ ERC20 stablecoin (like USDC/USDT)
├─ Backed by stETH collateral
├─ Soft peg maintained by arbitrage
└─ 1 alUSD ≈ 1 USD (not hard pegged)

Peg Maintenance:
├─ If alUSD > $1.01: Users mint (arb opportunity)
├─ If alUSD < $0.99: Users repay (discount)
└─ Market forces maintain ~$1 value

Supply:
├─ Total alUSD minted: ~150M
├─ Total collateral: ~300M+ stETH
├─ CR: ~200% (very safe)
```

---

## Integration Patterns

### Pattern 1: Self-Funding Treasury

```solidity
contract AutomatedTreasury {
  IAlchemist alchemist;
  IERC20 alUSD;

  // Funds treasury operations with self-repaying debt
  function initializeTreasury(uint256 stETH) external {
    // Deposit stETH (earning 3.5% APY)
    alchemist.depositUnderlying(stETH, address(this), 0);

    // Borrow operational funds
    uint256 alUSDAmount = (stETH * 50) / 100;  // 50% LTV
    alchemist.mint(alUSDAmount);

    // Debt repays itself from yield over 5-10 years
  }

  function sweepOperatingExpenses() external {
    // Monthly: Claim accrued treasury
    // Debt continues reducing automatically
  }
}
```

### Pattern 2: Leveraged Yield

```solidity
contract LeveragedYieldVault {
  IAlchemist alchemist;
  IYearnVault yearn;

  function depositAndLever(uint256 stETH) external {
    // Deposit stETH
    alchemist.depositUnderlying(stETH, address(this), 0);

    // Borrow alUSD
    uint256 alUSD = alchemist.mint((stETH * 40) / 100);

    // Supply alUSD to Yearn (earns 5%+)
    yearn.deposit(alUSD);

    // Net effect:
    // - Collateral earns 3.5% (stETH in Alchemix)
    // - Borrowed funds earn 5%+ (alUSD in Yearn)
    // - Debt gradually repays (yield auto-repayment)
  }
}
```

---

## Smart Contract Architecture

### Core Components

```solidity
Alchemist (Main Entry Point)
├─ Manages collateral
├─ Manages debt
├─ Routes to strategies
└─ Handles liquidations

YieldStrategy Interface
├─ deposit(amount): Invest tokens
├─ withdraw(shares): Get tokens back
├─ harvest(): Claim rewards
└─ Report gains/losses

alUSD Token (ERC20)
├─ Minted when user borrows
├─ Burned when user repays
└─ Transfers normally like USDC

Liquidation Module
├─ Identifies bad accounts
├─ Executes liquidation
├─ Distributes collateral
└─ Sends losses to insurance
```

---

## Comparison with Traditional Loans

| Feature | Traditional | Alchemix |
|---------|-----------|----------|
| **Interest Rate** | 5-10% | 0% (paid by yield) |
| **Collateral Required** | 150% (1.5x) | 200% (2x) |
| **Loan Duration** | 1-5 years | Until debt repaid (5-10y) |
| **Manual Repayment** | Required | Auto-repaying |
| **Complexity** | Low | Medium |
| **Best For** | Short-term | Long-term treasury |

---

## Resources

- **Docs:** https://docs.alchemix.fi/
- **GitHub:** https://github.com/alchemix-finance/alchemix-protocol
- **Dashboard:** https://app.alchemix.fi/
- **Audits:** ConsenSys, Trail of Bits

---

**Complexity:** Medium-High (novel concept)
**Security:** Excellent (audited, insurance fund)
**Innovation:** High (first of its kind)
**Best For:** Long-term self-funding, leveraged yield
