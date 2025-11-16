# Yearn Finance Vaults - Quick Integration Guide

**Protocol:** Yearn Finance
**Purpose:** Automated yield optimization for crypto assets
**Key Token:** yToken (vault shares)
**TVL:** $5B+
**Time to Read:** 7 minutes

---

## What is Yearn?

Yearn automates yield farming:
- Deposit your tokens (USDC, ETH, DAI, etc)
- Yearn deploys to best yield sources (Aave, Compound, Curve, etc)
- Earn optimized APY without managing yourself
- Withdraw anytime

---

## Core Concept: Vaults

### Vault = Smart Yield Harvester

```
User Deposit (USDC)
        ↓
    yUSDC Vault
        ↓
├─ Allocate to Aave (30%) → Earn lending fees
├─ Allocate to Curve (40%) → Earn LP fees
├─ Allocate to Compound (30%) → Earn interest
        ↓
Harvest rewards periodically
        ↓
Reinvest gains (compounding)
        ↓
User withdraws yUSDC → Get more USDC than deposited
```

---

## Basic Integration: Deposit & Earn

### Step 1: Deposit USDC to Earn ~5% APY

```solidity
pragma solidity ^0.8.17;

interface IVault {
  // Get vault token
  function token() external view returns (address);

  // Deposit tokens, receive vault shares
  function deposit(uint256 amount) external returns (uint256);

  // Withdraw tokens using shares
  function withdraw(uint256 shares) external returns (uint256);

  // Get current APY (varies)
  function pricePerShare() external view returns (uint256);

  // Total assets under management
  function totalAssets() external view returns (uint256);
}

contract YearnDepositor {
  // USDC Vault (Ethereum)
  IVault public usdcVault = IVault(0xa354F35829E3B34e78ECC1B7fcFe22b8424d0604);

  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  // Deposit USDC and earn yield
  function depositUSDC(uint256 usdcAmount) external returns (uint256 yTokensReceived) {
    // Step 1: Approve vault to spend USDC
    IERC20(USDC).approve(address(usdcVault), usdcAmount);

    // Step 2: Deposit USDC → Get yUSDC
    yTokensReceived = usdcVault.deposit(usdcAmount);

    // User now owns yTokens that earn yield
  }

  // Withdraw USDC (gets original + yield)
  function withdrawUSDC(uint256 yTokenAmount) external returns (uint256 usdcReceived) {
    // Burn yTokens → Get USDC back (+ earned yield)
    usdcReceived = usdcVault.withdraw(yTokenAmount);
    IERC20(USDC).transfer(msg.sender, usdcReceived);
  }
}
```

### Step 2: Check Balance & Earnings

```solidity
function checkEarnings(uint256 yTokenBalance) external view returns (uint256 usdcValue) {
  // yToken price increases as vault earns
  uint256 pricePerShare = usdcVault.pricePerShare();

  // Convert yTokens to USDC value
  usdcValue = (yTokenBalance * pricePerShare) / 1e18;
}
```

---

## Popular Vaults

| Asset | Vault Address | Est. APY | Strategy |
|-------|---------------|----------|----------|
| **USDC** | `0xa354F35829E3B34e78ECC1B7fcFe22b8424d0604` | 5-8% | Multi-lending |
| **USDT** | `0x7Da96a3891Add058AdA2E826306D812C23a2e35` | 5-8% | Multi-lending |
| **DAI** | `0x19B3Eb3Af5D81B06e37500F8B5fc39FB7F6146F2` | 5-8% | Multi-lending |
| **ETH** | `0xC5d95f81981987f08343000Fc6476f64347E72b6` | 3-5% | Staking + yield |
| **WBTC** | `0xA696a63539f5a04852c6b4fa45713b202B1f1dF7` | 3-6% | Lending pools |

---

## Advanced: Custom Strategy Integration

### Use Yearn Vault in Your Protocol

```solidity
// Game or AI contract that needs to generate yield
contract GameWithYield {
  // Treasury earns yield on reserved tokens
  IVault public yUSDC;
  uint256 public treasuryYTokens;

  constructor(address _yUSDCVault) {
    yUSDC = IVault(_yUSDCVault);
  }

  // Game charges 5% fee on transactions
  function processTransaction(
    uint256 transactionAmount,
    address player
  ) external {
    // 5% goes to treasury
    uint256 fee = (transactionAmount * 5) / 100;

    // Treasury deposits fee into Yearn
    IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(address(yUSDC), fee);
    uint256 yTokensReceived = yUSDC.deposit(fee);
    treasuryYTokens += yTokensReceived;

    // Rest of game logic...
  }

  // Withdraw treasury earnings anytime
  function withdrawTreasuryEarnings(uint256 yTokenAmount) external onlyOwner {
    uint256 usdc = yUSDC.withdraw(yTokenAmount);
    treasuryYTokens -= yTokenAmount;
    // Use USDC for rewards, buybacks, etc
  }
}
```

---

## Vault Mechanics Explained

### yToken Share Price

**Day 0:** Deposit 1000 USDC → Get 1000 yUSDC
**Day 365:** 1000 yUSDC = 1050 USDC (pricePerShare increased)

```solidity
// Price increases due to yield
pricePerShare = totalAssets / totalSupply

// Example:
// totalAssets = 105,000 USDC (original 100k + 5k yield)
// totalSupply = 100,000 yTokens
// pricePerShare = 1.05

// Your 1000 yTokens = 1000 * 1.05 = 1050 USDC
```

---

## Security Checklist

- ✅ Check vault strategy (what's it investing in?)
- ✅ Verify vault is audited (look at docs)
- ✅ Monitor APY (it changes based on yield sources)
- ✅ Check asset allocation (is it diversified?)
- ✅ Understand withdrawal limits (may have delays)
- ✅ Know TVL and age of vault (older = more tested)
- ✅ Check liquidation risks (if yield source fails)

---

## Risks & Considerations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Strategy Risk** | Underlying protocol exploited | Vault is audited + diversified |
| **Smart Contract Bug** | Funds lost | Choose established vaults |
| **Slashing/Impermanent Loss** | Yield reduced | Monitor APY + allocations |
| **Withdrawal Delay** | Can't exit instantly | Check withdrawal terms |

---

## Integration Pattern: Game Treasury

```solidity
// Example: Web3 game stores players' earned tokens in Yearn

contract GameTreasury {
  IVault public yUSDC = IVault(0xa354F35829E3B34e78ECC1B7fcFe22b8424d0604);
  uint256 public yTokenBalance;

  // Player rewards accumulate in Yearn vault
  function rewardPlayer(address player, uint256 usdcAmount) external {
    // Deposit to vault (gets yToken interest)
    IERC20(USDC).approve(address(yUSDC), usdcAmount);
    yTokenBalance += yUSDC.deposit(usdcAmount);
  }

  // Player claims rewards (with yield)
  function claimRewards(address player) external {
    uint256 claimableUSDC = (yTokenBalance * yUSDC.pricePerShare()) / 1e18;
    yUSDC.withdraw(yTokenBalance);
    IERC20(USDC).transfer(player, claimableUSDC);
  }
}
```

---

## Gas Efficiency

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Deposit | 120-150K | Depends on vault strategy |
| Withdraw | 150-200K | May interact with multiple protocols |
| Harvest | 500K+ | Done by Yearn operators (not users) |

---

## Key Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| Vault Registry | `0x50c1a2ea00a94e4faf938e343b9c76e90c4fee09` |
| USDC Vault | `0xa354F35829E3B34e78ECC1B7fcFe22b8424d0604` |
| ETH Vault | `0xC5d95f81981987f08343000Fc6476f64347E72b6` |

---

## Resources

- **Docs:** https://docs.yearn.finance/
- **GitHub:** https://github.com/yearn/yearn-vaults
- **Vault List:** https://yearn.finance/
- **Strategy Code:** Open-source on GitHub

---

**Complexity:** Low-Medium
**Gas Cost:** 120-200K
**Audited:** Yes (audited per vault)
**Battle-tested:** Yes ($5B+ TVL)
**Best For:** Passive yield farming, treasury automation
