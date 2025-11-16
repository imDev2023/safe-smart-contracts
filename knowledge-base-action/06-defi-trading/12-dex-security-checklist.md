# DEX Security Checklist

> Quick security verification for Uniswap V2/V3/V4 integration (3 min read)

## Pre-Integration Checks (8 items)

- [ ] **Router Version Confirmed**: Using correct Router contract
  - V2: `IUniswapV2Router02` or `IUniswapV2Router`
  - V3: `ISwapRouter` (not `IUniswapV3Router`)
  - V4: `IPoolManager` (singleton pattern)

- [ ] **Pool Liquidity Verified**: Pool has sufficient liquidity
  ```solidity
  uint256 liquidity = pool.liquidity();
  require(liquidity > MIN_LIQUIDITY, "Insufficient liquidity");
  ```

- [ ] **Fee Tiers Valid**: Only official fee tiers used
  ```
  V2: 0.30% (fixed)
  V3: 0.01%, 0.05%, 0.30%, 1.00%
  V4: Configurable via hooks
  ```

- [ ] **Token Path Verified**: No malicious tokens in swap route
  ```solidity
  // Check token addresses against whitelist
  require(isWhitelisted[path[0]], "Token not whitelisted");
  require(isWhitelisted[path[path.length - 1]], "Token not whitelisted");
  ```

- [ ] **Pool Exists**: Pool has been initialized
  ```solidity
  address pool = factory.getPool(tokenA, tokenB, fee);
  require(pool != address(0), "Pool doesn't exist");
  ```

- [ ] **Fork Functionality**: Protocol works on all intended chains
  - Mainnet
  - Arbitrum
  - Polygon
  - Optimism
  - Base

- [ ] **Contract Upgradeable**: Router is not proxy (or proxy verified)
  ```solidity
  // Verify router implementation
  require(router == EXPECTED_ROUTER, "Router changed");
  ```

- [ ] **ABI Compatibility**: Using latest contract ABIs
  ```solidity
  pragma solidity ^0.8.0;
  import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
  ```

## Slippage Protection (8 items)

- [ ] **amountOutMin Set**: Minimum output enforced
  ```solidity
  uint256 amountOutMin = calculateMinOutput(inputAmount, maxSlippage);
  require(amountOutMin > 0, "Invalid min output");
  ```

- [ ] **Slippage Calculation Correct**: Uses current exchange rate + buffer
  ```solidity
  // Current price from pool
  uint256 currentPrice = getCurrentPrice();
  // Apply slippage (e.g., 1%)
  uint256 minPrice = currentPrice * (100 - slippageBps) / 100;
  uint256 minOutput = inputAmount * minPrice / 1e18;
  ```

- [ ] **Dynamic Slippage**: Adjusts based on trade size
  ```solidity
  // Small trades: 0.5% slippage
  // Medium trades: 1% slippage
  // Large trades: 2-5% slippage
  uint256 slippageBps = inputAmount > threshold ? 500 : 50;
  ```

- [ ] **Deadline Enforced**: Transaction expires if too old
  ```solidity
  // Chainlink VRF / Automation: use block.timestamp + buffer
  uint256 deadline = block.timestamp + 300; // 5 min buffer
  ```

- [ ] **Price Impact Bounded**: Large trades protected
  ```solidity
  uint256 priceImpact = calculatePriceImpact(tokenIn, amountIn);
  require(priceImpact < MAX_PRICE_IMPACT, "Price impact too high");
  ```

- [ ] **TWAP Fallback**: If single pool unreliable, use TWAP
  ```solidity
  uint256 spotPrice = getSpotPrice();
  uint256 twapPrice = getTWAPPrice(5 minutes);
  // Verify they're within reasonable range
  require(abs(spotPrice - twapPrice) < tolerance);
  ```

- [ ] **Multi-Hop Routing Optimized**: Minimizes slippage across hops
  ```
  Best practice paths:
  - USDC → ETH → TOKEN (through major pools)
  - Avoid: OBSCURE → STABLECOIN → TOKEN (wide spreads)
  ```

- [ ] **Sandwich Attack Monitoring**: Alerts if transaction placed between attacker trades
  ```
  Monitor mempool:
  - Large buy before your swap → Price spike
  - Large sell after your swap → Price drop
  - Use private mempool if critical
  ```

## V2 Specific Checks (6 items)

- [ ] **Reserve Validation**: Reserves match pool state
  ```solidity
  (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
  require(reserve0 > 0 && reserve1 > 0, "Invalid reserves");
  ```

- [ ] **Constant Product Formula**: k invariant maintained
  ```solidity
  // Before: reserve0 * reserve1 = k
  // After swap: newReserve0 * newReserve1 >= k
  uint256 balanceAfter = token0.balanceOf(pair) * token1.balanceOf(pair);
  require(balanceAfter >= kBefore, "Invariant broken");
  ```

- [ ] **Reentrancy Guard**: No reentrancy to contract
  ```solidity
  // Uniswap V2 uses reserve-based checks, not reentrancy guard
  // Safe: swap first, then call external functions
  ```

- [ ] **SafeTransfer Used**: No raw transfer() calls
  ```solidity
  // ✓ SafeTransfer (handles non-standard ERC20)
  safeTransferFrom(token, msg.sender, address(pair), amount);
  // ✗ Raw transfer (fails on non-standard ERC20)
  IERC20(token).transfer(pair, amount);
  ```

- [ ] **TWAP Resistance**: TWAP oracle not manipulable
  ```solidity
  // TWAP uses cumulative prices over time
  // Single-block manipulation doesn't work
  // Safe for flash loan protection
  ```

- [ ] **Liquidity Pair Created**: Using Factory.createPair, not arbitrary address
  ```solidity
  address pair = factory.createPair(tokenA, tokenB);
  require(factory.getPair(tokenA, tokenB) == pair);
  ```

## V3 Specific Checks (7 items)

- [ ] **Tick Range Verified**: Position within valid tick range
  ```solidity
  // Current tick from pool
  int24 tick = pool.slot0().tick;
  // Position ticks
  require(tickLower < tick && tick < tickUpper, "Out of range");
  ```

- [ ] **Position Liquidity Calculated**: Using correct tick math
  ```solidity
  // LiquidityAmounts.getLiquidityForAmounts()
  uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
      sqrtRatioX96,
      sqrtRatioLowerX96,
      sqrtRatioUpperX96,
      amount0,
      amount1
  );
  ```

- [ ] **Fee Growth Tracked**: Position fees correctly calculated
  ```solidity
  // Fee growth inside position:
  // feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove
  uint256 feesOwed = calculateFeesOwed(position);
  ```

- [ ] **Tick Bitmap Understood**: O(1) next-tick lookup
  ```solidity
  // Tick bitmap enables efficient iteration
  // Each bit represents tick, 256 ticks per word
  // Used for fee accumulation calculation
  ```

- [ ] **Oracle Cardinality**: Sufficient observation slots for TWAP
  ```solidity
  // Pool must have grown observation cardinality
  require(pool.slot0().observationCardinalityNext > 100);
  ```

- [ ] **Slippage Per-Tick**: Account for slippage across tick range
  ```solidity
  // Price varies at each tick boundary
  // Use worst-case price within range for minAmount calculation
  uint256 worstCasePrice = getCurrentPrice() * (1 - maxTickDeviation);
  uint256 minOut = inputAmount * worstCasePrice / 1e18;
  ```

- [ ] **Position NFT Ownership**: Only NFT owner can modify position
  ```solidity
  require(nonfungiblePositionManager.ownerOf(tokenId) == msg.sender);
  ```

## V4 Specific Checks (6 items)

- [ ] **Singleton PoolManager**: One contract manages all pools
  ```solidity
  // All pools stored in single PoolManager
  // Single state, no separate pair contracts
  ```

- [ ] **Hook Validation**: Only trusted hooks executed
  ```solidity
  address hook = poolKey.hooks;
  require(isValidHook(hook), "Untrusted hook");
  require(hook.code.length > 0, "Hook not deployed");
  ```

- [ ] **Hook Permission Flags**: Understand which hooks execute
  ```solidity
  // 14 permission flags encoded in hook address
  // Hook address itself indicates capabilities
  // E.g., 0x...0004 = beforeSwap + afterSwap
  ```

- [ ] **Balance Delta Validation**: Encoded int256 understood
  ```solidity
  // Two int128 values packed in single int256
  // Upper 128 bits: amount0, Lower 128 bits: amount1
  int256 delta = encodeBalanceDelta(int128(amount0), int128(amount1));
  ```

- [ ] **Unlock/Lock Pattern**: Transient lock mechanism used
  ```solidity
  // V4 uses "lock until clear" transient storage
  // Called in sequence: enter → swap → callback → exit
  ```

- [ ] **ERC6909 Token Balance**: Position balance tracked correctly
  ```solidity
  // ERC6909 replaces LP tokens
  // Balance = uint256(currency) | (uint256(amount) << 160)
  uint256 balance = balanceOf(address(this), poolId);
  ```

## Flash Swap Protection (5 items)

- [ ] **Flash Swap Callback Implemented**: Correct interface
  ```solidity
  // IUniswapV2Callee (V2)
  function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external

  // IUniswapV3SwapCallback (V3)
  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external
  ```

- [ ] **Fee Repaid**: Flash swap fee included in repayment
  ```solidity
  // V2: 0.3% fee required
  uint256 fee = (amountBorrowed * 3) / 1000;
  uint256 repay = amountBorrowed + fee;
  ```

- [ ] **Callback Validation**: Only Uniswap router can call callback
  ```solidity
  require(msg.sender == address(uniswapPool), "Only pool");
  ```

- [ ] **State Consistency**: No reentrancy via callback
  ```solidity
  // Set state BEFORE flash swap
  uint256 balanceBefore = token.balanceOf(address(this));

  // Flash swap here
  // Callback executes

  // Verify state AFTER flash swap
  uint256 balanceAfter = token.balanceOf(address(this));
  require(balanceAfter >= expectedBalance, "Lost tokens");
  ```

- [ ] **Atomic Execution**: Swap succeeds or reverts completely
  ```solidity
  // No partial executions
  // If callback reverts, entire swap reverts
  ```

## Testing Verification (6 items)

- [ ] **Fork Test on Target Chain**: Test on actual mainnet state
  ```bash
  forge test --fork-url $MAINNET_RPC_URL --fork-block-number XXXX
  ```

- [ ] **Liquidity Pool Exists**: Verified on target chain
  ```solidity
  address pool = factory.getPool(tokenA, tokenB, fee);
  require(pool != address(0), "Pool missing");
  require(pool.code.length > 0, "Pool not deployed");
  ```

- [ ] **Token Decimals Correct**: Conversions work for all tokens
  ```solidity
  uint8 decimals0 = IERC20Metadata(token0).decimals();
  uint8 decimals1 = IERC20Metadata(token1).decimals();
  // Adjust amounts accordingly
  ```

- [ ] **Edge Cases Tested**:
  - [ ] Empty liquidity pool
  - [ ] Very large swap (price impact)
  - [ ] Very small swap (rounding)
  - [ ] Stale oracle price
  - [ ] Rapid consecutive swaps

- [ ] **Gas Optimization**: Swap transactions within reasonable gas
  ```solidity
  // V2 swap: ~40-80k gas
  // V3 swap: ~80-150k gas (depends on ticks)
  // V4 swap: ~100-200k gas (hook execution)
  ```

- [ ] **Mainnet Dry-Run**: Simulated on real chain before launch
  ```bash
  # Simulate the transaction
  cast call <target> "swap()" --from <sender>
  ```

## Production Deployment (5 items)

- [ ] **Router Address Double-Checked**: Against official docs
  ```
  V2 Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D (Mainnet)
  V3 Router:   0xE592427A0AEce92De3Edee1F18E0157C05861564 (Mainnet)
  V4 PoolMgr:  0x4D60a917d270512E89a6fcD0B2b282ccDE1b1a1F (V4 Testnet)
  ```

- [ ] **Approval Amounts Set**: Not unlimited except during testing
  ```solidity
  // Production: Set exact amount
  IERC20(token).approve(router, exactAmount);

  // NOT: type(uint256).max (unless absolutely necessary)
  ```

- [ ] **Pause Mechanism**: Can stop swaps if oracle fails
  ```solidity
  modifier onlyWhenActive() {
      require(!paused, "Swaps paused");
      _;
  }
  ```

- [ ] **Monitoring Active**: Alerts for:
  - Failed swaps
  - High slippage detections
  - Unusual liquidity changes
  - Fee accumulation anomalies

- [ ] **Upgrade Path**: Can upgrade oracle/slippage settings
  ```solidity
  // Upgradeable via proxy if needed
  // Or able to pause and migrate to new contract
  ```

---

**Slippage details**: See `02-slippage-protection.md`
**MEV protection**: See `05-mev-mitigation.md`
**Deep dives**: See `knowledge-base-research/repos/uniswap/`
