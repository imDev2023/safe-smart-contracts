# Curve Stablecoin AMM - Quick Integration Guide

**Protocol:** Curve Finance
**Purpose:** Low-slippage trading for correlated assets (stablecoins)
**Language:** Vyper (not Solidity)
**TVL:** $4B+
**Time to Read:** 8 minutes

---

## What is Curve?

Curve is an AMM designed specifically for stablecoin/low-risk trades:
- **StableSwap formula:** Optimized for assets with similar values
- **Low slippage:** Trades within ±1% stay nearly flat
- **Deep liquidity:** Billions in stablecoin pools
- **Yield:** Liquidity providers earn trading fees (~1-5% APY)

---

## Core Formula: StableSwap

### vs Uniswap's Constant Product

**Uniswap:** `x * y = k` (simple, high slippage for stablecoins)
**Curve:** Hybrid formula (near-constant-sum near equilibrium, constant-product at extremes)

**Result:**
```
USDC → USDT on Curve:  0.5% slippage on $1M
USDC → USDT on Uniswap: 5% slippage on $1M
```

---

## Basic Integration: Swap Stablecoins

### Step 1: Swap USDC for USDT

```solidity
pragma solidity ^0.8.17;

interface ICurvePool {
  // Swap function
  // return: amount of tokens received
  function exchange(
    int128 i,                // Input token index (0 = USDC)
    int128 j,                // Output token index (1 = USDT)
    uint256 dx,              // Amount in (USDC)
    uint256 min_dy           // Min amount out (slippage tolerance)
  ) external returns (uint256);

  // Get output amount (read-only)
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
}

contract StableSwapper {
  // 3Pool: USDC (0), USDT (1), DAI (2)
  // Mainnet: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
  ICurvePool public curvePool =
    ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  // USDC address
  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  // USDT address
  address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  function swapUSDCforUSDT(uint256 amountIn) external {
    // Step 1: Get expected output
    uint256 expectedOut = curvePool.get_dy(0, 1, amountIn);
    uint256 minOut = (expectedOut * 99) / 100; // 1% slippage tolerance

    // Step 2: Approve Curve to spend USDC
    IERC20(USDC).approve(address(curvePool), amountIn);

    // Step 3: Execute swap
    uint256 received = curvePool.exchange(0, 1, amountIn, minOut);

    // Step 4: Send to user
    IERC20(USDT).transfer(msg.sender, received);
  }
}
```

---

## Popular Curve Pools

| Pool | Assets | Pool Address | TVL |
|------|--------|--------------|-----|
| **3Pool** | USDC/USDT/DAI | `0xbEbc44...` | $1B+ |
| **Steth** | ETH/stETH | `0xDC24...` | $500M |
| **4Pool** | USDC/USDT/DAI/FRAX | `0xDcEF...` | $500M |
| **Frax** | FRAX/USDC | `0x2b2...` | $300M |

---

## Adding Liquidity

### Become LP and Earn Fees

```solidity
interface ICurvePoolLP {
  // Add liquidity to 3Pool
  function add_liquidity(
    uint256[3] calldata amounts,  // [USDC, USDT, DAI] amounts
    uint256 min_mint_amount       // Slippage tolerance for LP tokens
  ) external returns (uint256);   // Returns LP tokens minted

  // Remove liquidity
  function remove_liquidity(
    uint256 burn_amount,          // LP tokens to burn
    uint256[3] calldata min_amounts // Min amounts to receive
  ) external returns (uint256[3] memory);
}

contract CurveLiquidityProvider {
  ICurvePoolLP public curvePool =
    ICurvePoolLP(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  function addLiquidity(
    uint256 usdcAmount,
    uint256 usdtAmount,
    uint256 daiAmount
  ) external returns (uint256 lpTokens) {
    // Approve all tokens
    IERC20(USDC).approve(address(curvePool), usdcAmount);
    IERC20(USDT).approve(address(curvePool), usdtAmount);
    IERC20(DAI).approve(address(curvePool), daiAmount);

    // Add liquidity (balanced)
    lpTokens = curvePool.add_liquidity(
      [usdcAmount, usdtAmount, daiAmount],
      0  // Accept any amount (for example; normally use slippage calc)
    );
  }

  // Remove liquidity after earning fees
  function removeLiquidity(uint256 lpTokensToBurn) external {
    curvePool.remove_liquidity(lpTokensToBurn, [uint256(0), 0, 0]);
  }
}
```

---

## Advanced: Gauge & CRV Rewards

Curve LPs can earn additional **CRV** token rewards:

```solidity
interface ICurveGauge {
  // Deposit LP tokens to earn CRV
  function deposit(uint256 amount) external;

  // Withdraw LP tokens (claims CRV automatically)
  function withdraw(uint256 amount) external;

  // Claim CRV rewards
  function claim_rewards() external;

  // Check pending rewards
  function claimable_reward(address account) external view returns (uint256);
}

contract CurveGaugeStaker {
  // 3Pool Gauge (claims CRV)
  ICurveGauge public gauge =
    ICurveGauge(0xbFa4D092C3b5D2cf135e138c9a2a7Ff89190cAd6);

  address public curveLP = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

  function stakeLP(uint256 lpAmount) external {
    IERC20(curveLP).approve(address(gauge), lpAmount);
    gauge.deposit(lpAmount);
  }

  function unstakeAndClaimCRV(uint256 lpAmount) external {
    gauge.withdraw(lpAmount);
    // CRV automatically claimed on withdraw
  }
}
```

---

## Pool Topology & Routing

### Find Best Swap Path

Curve pools connect at tokens. To swap assets:

```solidity
// Example: Swap 1000 USDC → DAI

// Direct path (3Pool): USDC → DAI (1 hop)
curvePool3.exchange(0, 2, 1000e6, minOut);

// Multi-hop path: DAI → ETH → stETH (if needed)
// Use Curve router for complex paths
```

---

## Security Checklist

- ✅ Verify pool balance before swapping (avoid sandwich attacks)
- ✅ Set reasonable slippage tolerance (0.1%-2% for stablecoins)
- ✅ Check pool token composition (is it what you expect?)
- ✅ Use `get_dy()` to estimate output before swap
- ✅ Monitor stablecoin pegs (USDC/USDT should be ~1.0)
- ✅ Gauge rewards can change (check documentation)

---

## Gas Efficiency

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Exchange | 80-100K | Direct swap |
| Add Liquidity | 150-200K | Depends on tokens |
| Remove Liquidity | 100-150K | Depends on tokens |
| Claim Rewards | 80-120K | CRV claim |

---

## Key Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| 3Pool | `0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7` |
| 3Pool LP Token | `0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490` |
| 3Pool Gauge | `0xbFa4D092C3b5D2cf135e138c9a2a7Ff89190cAd6` |
| CRV Token | `0xD533a949740bb3306d119CC777fa900bA034cd52` |

---

## Resources

- **Docs:** https://docs.curve.fi/
- **GitHub:** https://github.com/curvefi/curve-contract
- **Pool List:** https://curve.fi/#/ethereum/pools
- **On-Chain Routing:** Use Curve Router for multi-hop swaps

---

**Complexity:** Medium
**Gas Cost:** 80-200K (lower than Uniswap)
**Audited:** Yes (Trail of Bits)
**Battle-tested:** Yes ($4B+ TVL)
**Best For:** Stablecoin trading, low-volatility yield
