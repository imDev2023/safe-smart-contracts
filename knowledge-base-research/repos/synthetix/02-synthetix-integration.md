# Synthetix Derivatives - Quick Integration Guide

**Protocol:** Synthetix
**Purpose:** On-chain synthetic assets (derivatives)
**Key Concept:** Stake SNX → Mint synthetic assets (Synths)
**TVL:** $500M+
**Time to Read:** 8 minutes

---

## What is Synthetix?

Synthetix is a decentralized derivatives platform:
- SNX token holders stake SNX
- Stakers can mint synthetic assets (Synths)
- Trade sUSD, sETH, sAUDDI, sGOLD, etc
- Earn trading fees from Synth swaps

---

## Core Concept: Synthetic Assets

```
┌──────────────────────────────────────┐
│ SNX Staker (Collateral)              │
├──────────────────────────────────────┤
│                                      │
│ Stake 1000 SNX ($5k value)           │
│                                      │
│ Can mint Synths up to 500% ratio     │
│ (New V3: reduced collateral needs)   │
│                                      │
│ ├─ 2500 sUSD (stablecoin)            │
│ ├─ 1.0 sETH (ETH derivative)         │
│ ├─ 10 sAUD (AUD derivative)          │
│ └─ Earn 5-10% fees from trading      │
│                                      │
└──────────────────────────────────────┘
```

---

## Basic Integration: Stake & Mint Synths

### Step 1: Stake SNX

```solidity
pragma solidity ^0.8.17;

interface ISynthetix {
  // Stake SNX to earn rewards
  function stake(uint256 amount) external;

  // Unstake SNX (if debt closed)
  function unstake(uint256 amount) external;

  // Mint Synths against collateral
  function issueSynths(uint256 amount) external;

  // Burn Synths to repay debt
  function burnSynths(uint256 amount) external;

  // Get staker info
  function collateral(address account) external view returns (uint256);
  function debtBalanceOf(address account, bytes32 currencyKey)
    external view returns (uint256);
}

contract SynthetixStaker {
  // Synthetix (Mainnet)
  ISynthetix public synthetix = ISynthetix(0xC011a73ee3FB7F173F2176431Bda44b35120f4dF);

  // SNX token
  IERC20 public SNX = IERC20(0xC011a73ee3FB7F173F2176431Bda44b35120f4dF);

  // Step 1: Stake SNX
  function stakeSNX(uint256 snxAmount) external {
    // Approve SNX to Synthetix
    SNX.approve(address(synthetix), snxAmount);

    // Stake SNX
    synthetix.stake(snxAmount);
  }

  // Step 2: Mint sUSD (synthetic USD)
  function mintSynths(uint256 susdAmount) external {
    // Issue sUSD against SNX collateral
    synthetix.issueSynths(susdAmount);

    // User now has sUSD stablecoin
  }

  // Step 3: Trade Synths (swap sUSD → sETH, etc)
  // Use Synthetix exchange or DEX

  // Step 4: Repay debt
  function closeSynthDebt(uint256 susdAmount) external {
    // Get sUSD from user (approve first)
    // Burn sUSD to close debt
    synthetix.burnSynths(susdAmount);
  }

  // Unstake (only if all debt repaid)
  function unstakeSNX(uint256 snxAmount) external {
    synthetix.unstake(snxAmount);
  }
}
```

---

## Available Synths (Synthetic Assets)

| Synth | Underlying | Code | Use Case |
|-------|-----------|------|----------|
| **sUSD** | US Dollar | sUSD | Stablecoin |
| **sETH** | Ethereum | sETH | ETH exposure |
| **sBTC** | Bitcoin | sBTC | BTC exposure |
| **sAUD** | Australian Dollar | sAUD | AUD derivative |
| **sGOLD** | Gold | sGOLD | Commodity exposure |
| **sDEFI** | DeFi Index | sDEFI | DeFi exposure |
| **sInverseBTC** | Inverse BTC | iBTC | Short BTC |
| **sInverseETH** | Inverse ETH | iETH | Short ETH |

---

## Advanced: Leverage Trading with Shorts

### Short Bitcoin Using Synthetix

```solidity
contract ShortBitcoin {
  ISynthetix public synthetix;
  IERC20 public sUSD;
  IERC20 public iBTC; // Inverse BTC (shorts)

  function shortBTC(uint256 snxCollateral) external {
    // Step 1: Stake SNX
    SNX.approve(address(synthetix), snxCollateral);
    synthetix.stake(snxCollateral);

    // Step 2: Mint sUSD (collateral minting)
    synthetix.issueSynths(snxCollateral * 1000); // Assume $1000/SNX

    // Step 3: Trade sUSD → iBTC (inverse Bitcoin)
    // sUSD value increases when BTC price drops
    // This creates a short position

    // Step 4: If BTC drops 10%, iBTC worth +10%
    // Step 5: Swap iBTC back to sUSD → Profit
  }
}
```

---

## Fee Structure & Rewards

### Stakers Earn Fees

```
Total Trading Volume on Synthetix: $10B/day

Trading Fee: 0.3% per swap

Fee Distribution:
└─ SNX Stakers: 5-8% APY (shared)

Example:
Stake 1000 SNX
Total staked: 100M SNX
Daily trading: $10B × 0.3% = $30M fees
Your share: (1000 / 100M) × $30M × 365 = ~$110k/year
```

---

## Integration Pattern: Derivative Hedging

```solidity
// DeFi protocol that needs to hedge ETH exposure
contract DeFiHedge {
  ISynthetix public synthetix;
  IERC20 public SNX;
  IERC20 public sETH;

  // Hedge ETH position by shorting
  function hedgeETHPosition(uint256 ethExposure) external {
    // If we have $1M ETH exposure, short 100 sETH
    // If ETH drops, our short gains offset our loss

    uint256 sethAmount = ethExposure / 1 ether;

    // Use sUSD to buy sInverseETH
    // (If using inverse Synths)
  }
}
```

---

## Collateral Requirements

### C-Ratio: Collateralization Ratio

```
C-Ratio = Staked SNX Value / Minted Synths Value

Example:
Stake 1000 SNX ($5000 at $5/SNX)
Min C-Ratio: 600% (industry best)

Max Synths = $5000 / 600% = $8333
Can mint 8333 sUSD against 1000 SNX
```

**Note:** Synthetix V3 reduces this ratio significantly

---

## Liquidation Risk

```
If your C-Ratio falls below minimum:
├─ You're not liquidated immediately
├─ But can't unstake until ratio fixed
├─ Penalty fee applied
└─ Forced to repay debt

Example:
Staked: 1000 SNX ($5000)
Minted: 8333 sUSD
SNX drops to $2/token
New collateral: $2000
C-Ratio: 24% (below 600% min)
└─ LIQUIDATION ZONE
```

---

## Security Checklist

- ✅ Monitor C-Ratio constantly (use dashboard)
- ✅ Keep buffer above minimum (e.g., 700% instead of 600%)
- ✅ Understand price feeds (Chainlink oracles)
- ✅ Know collateral value fluctuates (SNX volatility)
- ✅ Plan repayment strategy (especially for shorts)
- ✅ Check debt balance regularly (includes staking rewards)

---

## Gas Efficiency

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Stake | 120K | Initial SNX approval + staking |
| Issue Synths | 100K | Mint sUSD |
| Trade Synths | 80K | DEX swap |
| Burn & Unstake | 150K | Close position |

---

## Key Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| Synthetix | `0xC011a73ee3FB7F173F2176431Bda44b35120f4dF` |
| Proxy | `0x9D5D4FCFdcCC7E6685FdbA5d7A630369bED27055` |
| SNX Token | `0xC011a73ee3FB7F173F2176431Bda44b35120f4dF` |
| sUSD | `0x57Ab1ec28D129707052df4dF418D58a2D46d5f51` |

---

## Resources

- **Docs:** https://docs.synthetix.io
- **GitHub:** https://github.com/Synthetixio/synthetix
- **Dashboard:** https://staking.synthetix.io
- **Trade:** https://kwenta.io (DEX for Synths)

---

**Complexity:** High (leverage + liquidation risk)
**Gas Cost:** 100-150K per operation
**Audited:** Yes (multiple audits)
**Best For:** Derivatives trading, hedging, leverage
**Warning:** High-risk leverage trading - use carefully
