# Alchemix Self-Paying Loans - Quick Integration Guide

**Protocol:** Alchemix Finance
**Purpose:** Self-paying loans (debt repays itself from yield)
**Key Concept:** Collateral generates yield → Automatically repays debt
**TVL:** $200M+
**Time to Read:** 7 minutes

---

## What is Alchemix?

Alchemix lets you **borrow against future yield**:
- Deposit ETH/stETH → Get alUSD loan
- ETH collateral earns 3.5% yield via Lido
- Yield automatically repays your debt
- No interest payments (yield covers it)

---

## Core Concept: Self-Repaying Loans

```
┌─────────────────────────────────────────┐
│ You deposit 100 ETH (worth $200k)       │
├─────────────────────────────────────────┤
│ Collateral goes to Lido staking         │
│ Earning ~3.5% APY = $7k/year            │
├─────────────────────────────────────────┤
│ You borrow 75k alUSD (37.5% LTV)        │
│ Borrow rate = 0% (paid by yield!)       │
├─────────────────────────────────────────┤
│ Lido rewards accumulate daily           │
│ Auto-repay 75k alUSD after 10-15 years  │
│ (You keep the ETH after debt repaid!)   │
└─────────────────────────────────────────┘
```

---

## Basic Integration: Get Loan Without Interest

### Step 1: Deposit Collateral & Borrow

```solidity
pragma solidity ^0.8.17;

interface IAlchemist {
  // Deposit collateral (ETH or stETH)
  function depositUnderlying(
    uint256 yieldTokenAmount,  // Amount of stETH
    address recipient,
    uint256 minimumAmountOut
  ) external returns (uint256);

  // Borrow alUSD against collateral
  function mint(
    uint256 amount  // alUSD to mint
  ) external returns (uint256);

  // Repay debt
  function burn(
    uint256 amount  // alUSD to repay
  ) external returns (uint256);

  // Get your debt balance
  function debts(address account) external view returns (int256);

  // Get your collateral value
  function balanceOf(address account) external view returns (uint256);
}

contract AlchemixBorrower {
  // Alchemist (Ethereum mainnet)
  IAlchemist public alchemist = IAlchemist(0x062Bf325d507458C81A7e06dEbed55e4716DEC8d);

  // stETH token
  address constant STETH = 0xae7ab96520DE3A18E5e111B5EaAc035201F51ec0;

  // alUSD stablecoin
  IERC20 public alUSD = IERC20(0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9);

  // Borrow against stETH collateral
  function borrowAlchemix(uint256 stETHAmount, uint256 borrowAmount) external {
    // Step 1: Approve stETH to Alchemist
    IERC20(STETH).approve(address(alchemist), stETHAmount);

    // Step 2: Deposit stETH as collateral
    alchemist.depositUnderlying(stETHAmount, msg.sender, 0);

    // Step 3: Mint alUSD loan
    alchemist.mint(borrowAmount);

    // Step 4: Send alUSD to user
    alUSD.transfer(msg.sender, borrowAmount);
  }

  // Repay debt (yield repays it over time automatically)
  function repayManually(uint256 alUSDAmount) external {
    // For quick repayment (optional)
    alUSD.approve(address(alchemist), alUSDAmount);
    alchemist.burn(alUSDAmount);
  }
}
```

### Step 2: Monitor Auto-Repayment

```solidity
function checkDebtStatus(address borrower) external view returns (
  int256 debt,
  uint256 collateralValue,
  uint256 yearsUntilRepaid
) {
  debt = alchemist.debts(borrower);
  collateralValue = alchemist.balanceOf(borrower);

  // Assume 3.5% APY yield
  uint256 dailyYield = (collateralValue * 35) / (365 * 1000);
  yearsUntilRepaid = uint256(debt) / (dailyYield * 365);
}
```

---

## Key Features

### 1. **0% Interest Loans**
- Traditional loans: Borrow 100k → Repay 110k (10% interest)
- Alchemix: Borrow 100k → Repay 100k (via yield, no interest!)

### 2. **Self-Repaying**
```
Yield Flow:
Collateral (stETH) → Earns 3.5% → Automatically repays debt
```

### 3. **LTV (Loan-to-Value)**
```
Max borrow = 50% of collateral value

Example:
100 ETH ($200k) → Can borrow max 100k alUSD
```

---

## Advanced: Recursive Staking (leveraged)

### Amplify Yield with Self-Repaying Debt

```solidity
// Advanced: Deposit ETH → Get stETH → Stake → Borrow alUSD → Deposit again
contract RecursiveStaking {
  IAlchemist public alchemist = IAlchemist(0x062Bf325d507458C81A7e06dEbed55e4716DEc8d);
  ILido public lido = ILido(0xae7ab96520DE3A18E5e111B5EaAc035201F51ec0);

  function recursiveBorrow(uint256 ethAmount, uint8 iterations) external payable {
    uint256 currentAmount = msg.value;

    for (uint8 i = 0; i < iterations; i++) {
      // Step 1: Wrap ETH to stETH via Lido
      uint256 stETHReceived = lido.submit{value: currentAmount}(address(0));

      // Step 2: Deposit stETH to Alchemist
      lido.approve(address(alchemist), stETHReceived);
      alchemist.depositUnderlying(stETHReceived, address(this), 0);

      // Step 3: Borrow alUSD (50% LTV)
      uint256 borrowAmount = (currentAmount * 25) / 100; // 25% per iteration
      alchemist.mint(borrowAmount);

      // Step 4: Use alUSD for next iteration
      // (Can swap back to ETH via DEX, then loop)
      currentAmount = borrowAmount;
    }
  }
}
```

---

## Debt Repayment Timeline

| Days | Accumulated Yield | Debt Remaining | Status |
|------|-------------------|-----------------|--------|
| 0 | 0% | 100% | Full debt |
| 365 | 3.5% | 96.5% | Slightly repaid |
| 1825 | 17.5% | 82.5% | 5 years in |
| 3650 | 35%+ | ~65%+ | 10 years (varies) |

**Note:** Actual repayment depends on yield source stability and rate changes.

---

## Integration Pattern: AI Agent Self-Funding

```solidity
// AI Agent Treasury Auto-Replenishing
contract AIAgentFund {
  IAlchemist public alchemist;
  IERC20 public alUSD;

  // Agent operations funded by self-repaying loan
  function fundAgentOperations(uint256 stETHCollateral) external {
    // Deposit stETH (earning 3.5% APY)
    alchemist.depositUnderlying(stETHCollateral, address(this), 0);

    // Borrow alUSD (repays itself from yield)
    uint256 borrowAmount = (stETHCollateral * 50) / 100; // 50% LTV
    alchemist.mint(borrowAmount);

    // Fund agent operations with zero-interest loan
    // Debt automatically repays over time!
  }

  // Agent earns commission, adds to treasury
  function agentEarnings(uint256 amount) external payable {
    // Additional earnings accelerate debt repayment
    alUSD.approve(address(alchemist), amount);
    alchemist.burn(amount); // Manually repay if surplus
  }
}
```

---

## Security Checklist

- ✅ Understand LTV limits (max borrow 50% of collateral)
- ✅ Monitor collateral value (ETH/stETH price changes)
- ✅ Know yield assumptions (3.5% from Lido, can change)
- ✅ Track debt status (can accelerate repayment)
- ✅ Check liquidation conditions (if collateral drops 30%+)
- ✅ Verify contract addresses (avoid fake Alchemix)

---

## Risks

| Risk | Severity | Details |
|------|----------|---------|
| **Collateral Drop** | Medium | If ETH price drops 30%, liquidation risk |
| **Yield Decrease** | Medium | If Lido APY drops, repayment slower |
| **Smart Contract Bug** | Low | Audited, but always possible |
| **Liquidation** | High | Breaking LTV triggers liquidation penalty |

---

## Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| Alchemist (V2) | `0x062Bf325d507458C81A7e06dEbed55e4716DEc8d` |
| alUSD | `0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9` |
| stETH Collateral | `0xae7ab96520DE3A18E5e111B5EaAc035201F51ec0` |

---

## Resources

- **Docs:** https://docs.alchemix.fi/
- **GitHub:** https://github.com/alchemix-finance/alchemix-protocol
- **Dashboard:** https://app.alchemix.fi/

---

**Complexity:** Medium
**Gas Cost:** 150-200K (deposit + borrow)
**Audited:** Yes
**Best For:** Interest-free borrowing, self-funding treasuries, leverage
