# Yearn Finance Vaults - Deep Dive

**Source:** https://github.com/yearn/yearn-vaults
**Purpose:** Automated yield farming with composable strategies
**TVL:** $5B+
**Architecture:** Modular strategy system

---

## Core Philosophy

**Goal:** Automate yield optimization so users don't have to

```
Manual Yield Farming:
├─ Monitor multiple protocols daily
├─ Rebalance allocations based on APY
├─ Compound rewards manually
├─ Pay gas for frequent transactions
├─ High technical knowledge required
└─ Very inefficient

Yearn Solution:
├─ Single deposit
├─ Strategies handle rebalancing
├─ Automatic compounding
├─ Batched operations (gas efficient)
└─ Set and forget
```

---

## Architecture

### Vault Structure

```
┌─────────────────────────────────────────┐
│         Yearn Vault (yUSDC)              │
├─────────────────────────────────────────┤
│                                         │
│  User Functions:                        │
│  ├─ deposit(amount)                     │
│  ├─ withdraw(shares)                    │
│  └─ pricePerShare()                     │
│                                         │
│  Management:                            │
│  ├─ Strategy[] strategies               │
│  ├─ debt management                     │
│  ├─ reward collection                   │
│  └─ share mechanics                     │
│                                         │
│  Internal:                              │
│  ├─ Allocate tokens to strategies      │
│  ├─ Report strategy returns             │
│  ├─ Handle losses                       │
│  └─ Rebalance allocations               │
│                                         │
└─────────────────────────────────────────┘
         ↓          ↓          ↓
    Strategy1   Strategy2   Strategy3
    (Aave)      (Curve)     (Compound)
```

### Strategy Components

Each strategy consists of:

```solidity
interface Strategy {
  // Core functions
  function deposit() external;                    // Put tokens to work
  function withdraw(uint256 amount) external;     // Get tokens back
  function withdrawAll() external;                // Emergency exit

  // Reporting
  function estimatedTotalAssets() external view returns (uint256);
  function harvestTrigger() external view returns (bool);
  function harvest() external;                    // Claim rewards

  // Management
  function setDebtRatio(uint256 ratio) external;
  function migrate(address newStrategy) external;
}
```

---

## Strategy Types

### 1. Aave Lending Strategy

```solidity
contract AaveStrategy is Strategy {
  // Deposits USDC to Aave → Earns interest

  function deposit() external override {
    uint256 balance = token.balanceOf(address(this));
    aavePool.supply(token, balance, address(this), 0);
  }

  function estimatedTotalAssets() external override view returns (uint256) {
    // aToken balance in Aave
    uint256 aTokens = aToken.balanceOf(address(this));
    return aTokens;
  }

  function harvest() external override {
    // Claim AAVE rewards, sell for more USDC, reinvest
    aaveRewards.claimRewards();
    _swapRewardsForUSDC();
    deposit();
  }
}
```

### 2. Curve LP Strategy

```solidity
contract CurveLPStrategy is Strategy {
  // Supply liquidity to Curve 3Pool → Earn trading fees + CRV

  function deposit() external override {
    uint256 balance = token.balanceOf(address(this));

    // Deposit into 3Pool (balanced)
    curvePool.add_liquidity([balance, 0, 0], 0);

    // Stake LP tokens in gauge for CRV
    uint256 lpTokens = crvLP.balanceOf(address(this));
    gauge.deposit(lpTokens);
  }

  function harvest() external override {
    // Claim CRV rewards
    gauge.claim_rewards();

    // Sell CRV for USDC
    _swapCRVforUSDC();

    // Reinvest
    deposit();
  }
}
```

### 3. Multi-Protocol Strategy

```solidity
contract OptimizedStrategy is Strategy {
  // Switch capital between protocols based on APY

  function harvest() external override {
    // Check current APYs
    uint256 aaveAPY = _getAaveAPY();
    uint256 curveAPY = _getCurveAPY();

    if (curveAPY > aaveAPY) {
      // Rebalance: Aave → Curve
      _withdrawFromAave();
      _depositToCurve();
    }

    // Claim and reinvest rewards
    _claimRewards();
    _reinvest();
  }
}
```

---

## Vault Economics: Share Mechanics

### Share Price Growth

```
Mechanism:
├─ Users deposit tokens → Get shares
├─ Shares represent % ownership of pool
├─ As vault earns, pricePerShare increases
└─ Shares don't increase, but value does

Example Timeline:
┌──────────────────────────────────────┐
│ Day 0: User deposits 1000 USDC       │
├──────────────────────────────────────┤
│ Gets: 1000 shares                    │
│ pricePerShare = 1000 USDC / 1000 = 1│
├──────────────────────────────────────┤
│ Day 365: Vault earned 50 USDC yield  │
├──────────────────────────────────────┤
│ Total value: 1050 USDC               │
│ pricePerShare = 1050 / 1000 = 1.05   │
│ User's shares: still 1000            │
│ User's value: 1000 × 1.05 = 1050 ✅ │
└──────────────────────────────────────┘
```

### Fee Mechanics

```solidity
Fees go to Yearn governance:
├─ Performance fee: % of gains (typical 20%)
│  Example: Strategy earned 100 → Yearn gets 20
│
└─ Management fee: % of TVL annually (typical 2%)
   Example: $100M TVL × 2% = $2M/year to Yearn

Deducted: From vault balance (all users pay proportionally)
```

---

## Debt & Capital Allocation

### Debt Ratio System

```
Each strategy has a debt ratio:
├─ 50% debt ratio → Can receive 50% of deposits
├─ 30% debt ratio → Can receive 30% of deposits
└─ 0% debt ratio → Receives no new capital

Rebalancing:
├─ Vault tracks expected vs actual debt
├─ Strategies report gains/losses
├─ Capital reallocated based on ratios
└─ Inefficient strategies drained
```

### Example Rebalancing

```
Initial state:
├─ Strategy A (Aave, 50% ratio): $500k
├─ Strategy B (Curve, 30% ratio): $300k
└─ Strategy C (Compound, 20% ratio): $200k

After harvest:
├─ Strategy A returned 5% → $525k
├─ Strategy B returned 2% → $306k
├─ Strategy C lost 1% → $198k

Vault adjusts:
├─ Takes $25k from A (exceeds allocation)
├─ Adds to B if needed
└─ Removes from C to cover loss
```

---

## Harvesting & Compounding

### Harvest Process

```
Triggered by:
├─ Time-based (X blocks since last harvest)
├─ Condition-based (rewards accumulated > threshold)
└─ Manual keeper call

Harvest Steps:
1. Strategy claims rewards (AAVE, CRV, COMP, etc)
2. Swap rewards for vault's base token (USDC)
3. Deposit USDC back to underlying protocol
4. Report gains/losses to vault
5. Vault updates share price
```

### Compounding Effect

```
Year 1: 100 USDC × 5% = 105 USDC
Year 2: 105 USDC × 5% = 110.25 USDC
Year 3: 110.25 USDC × 5% = 115.76 USDC
...
Year 10: ~162.89 USDC

Frequency matters:
├─ Daily harvest: ~162.89 (5% annual)
├─ Weekly harvest: ~161.90 (slightly less)
└─ Monthly harvest: ~159.38 (more slippage)
```

---

## Risk Management

### Loss Handling

```
Scenarios:
├─ Underlying protocol exploited (loses $10k)
├─ Smart contract bug (loses $5k)
├─ Liquidation due to collateral drop (loses $3k)

Vault's Response:
├─ Record loss in strategy report
├─ Distribute loss across all users (fair)
├─ pricePerShare decreases slightly
└─ Remove strategy from allocation

Example:
Before: pricePerShare = 1.05
Loss: $5k on $500k vault
New: pricePerShare = 1.049
```

### Safety Features

```
Protection Mechanisms:
├─ Strategy withdrawal limits (don't fully drain)
├─ Loss thresholds (warnings if loss > limit)
├─ Keeper jobs (separate trusted operators)
├─ Emergency pause (admin can freeze deposits)
└─ Multi-sig controls (significant changes need approval)
```

---

## Smart Contract Architecture

### Core Vault Contract

```solidity
contract Vault is ERC20 {
  IERC20 public token;                    // Underlying token
  Strategy[] public strategies;           // Active strategies
  uint256[] public debtRatios;            // % allocated to each

  function deposit(uint256 amount) external {
    uint256 shares = _issueSharesForAmount(amount);
    token.transferFrom(msg.sender, address(this), amount);

    // Allocate to strategies
    _allocateCapital();
  }

  function withdraw(uint256 shares) external {
    uint256 amount = _amountForShares(shares);

    // Gather tokens from strategies if needed
    _gatherFunds(amount);

    token.transfer(msg.sender, amount);
    _burn(msg.sender, shares);
  }

  function report() external onlyStrategy {
    // Strategy reports gains/losses
    // Vault adjusts internal accounting
  }

  function harvest() external {
    // Trigger all strategies to harvest
    for (uint i = 0; i < strategies.length; i++) {
      strategies[i].harvest();
    }
  }
}
```

---

## Integration Patterns

### Pattern 1: Game Treasury Vault

```solidity
contract GameTreasury {
  IVault public usdcVault;
  uint256 public treasuryShares;

  function depositTreasuryFunds(uint256 usdc) external onlyOwner {
    // Move game fees to Yearn vault
    USDC.approve(address(usdcVault), usdc);
    treasuryShares += usdcVault.deposit(usdc);
  }

  function claimTreasuryReturns() external onlyOwner {
    // Withdraw vault shares → Get USDC + yield
    uint256 usdc = usdcVault.withdraw(treasuryShares);
    treasuryShares = 0;
    // Use USDC for rewards, buybacks, etc
  }
}
```

### Pattern 2: AI Agent Auto-Funding

```solidity
contract AIAgentTreasuryVault {
  IVault public vault;

  // Agent operations funded by vault yield
  function fundAgentRound(uint256 deploymentBudget) external {
    uint256 vaultBalance = vault.balanceOf(address(this));
    uint256 usdc = vault.withdraw(vaultBalance);

    // Allocate to agents
    _distributeToAgents(usdc);
  }
}
```

---

## Comparison with Alternatives

| Protocol | Strategy | Gas | Yield | Risk |
|----------|----------|-----|-------|------|
| **Yearn** | Multi-strategy | Low | Highest | Medium |
| **Curve** | Trading fees only | Low | Medium | Low |
| **Aave** | Direct lending | Low | Medium | Medium |
| **Compound** | Direct lending | Low | Medium | Medium |
| **Uniswap V3** | Manual management | High | Variable | High |

---

## Resources

- **Docs:** https://docs.yearn.finance/
- **GitHub:** https://github.com/yearn/yearn-vaults
- **Dashboard:** https://yearn.finance/
- **Strategy Repo:** https://github.com/yearn/yearn-strategies

---

**Complexity:** High (strategy coordination)
**Security:** Excellent (audited, $5B TVL)
**Gas Efficiency:** Good (batch harvests)
**User Experience:** Best-in-class (set and forget)
**Best For:** Passive yield farming, automated treasury
