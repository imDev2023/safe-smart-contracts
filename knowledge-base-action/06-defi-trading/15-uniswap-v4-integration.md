# Uniswap V4 Integration Guide

> Step-by-step Uniswap V4 swap integration with hooks (5 min read)

## Quick Integration (4 steps)

### Step 1: Import PoolManager Interface
```solidity
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/types/PoolId.sol";

contract V4Example {
    IPoolManager public poolManager;

    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }
}
```

### Step 2: Define Pool Key
```solidity
function createPoolKey(
    address token0,
    address token1,
    uint24 fee,
    int24 tickSpacing,
    address hooks
) external pure returns (PoolKey memory) {
    return PoolKey({
        currency0: Currency.wrap(token0),
        currency1: Currency.wrap(token1),
        fee: fee,
        tickSpacing: tickSpacing,
        hooks: IHooks(hooks)
    });
}
```

### Step 3: Execute Swap with Callback
```solidity
import {BalanceDelta} from "@uniswap/v4-core/types/BalanceDelta.sol";

function swapSingle(
    PoolKey calldata poolKey,
    IPoolManager.SwapParams calldata params
) external returns (BalanceDelta delta) {
    delta = poolManager.swap(poolKey, params, "");

    // Handle balance delta
    int128 amount0 = delta.amount0();
    int128 amount1 = delta.amount1();

    // Settle balance
    if (amount0 > 0) {
        IERC20(Currency.unwrap(poolKey.currency0)).transfer(
            address(poolManager),
            uint256(int256(amount0))
        );
    }
    if (amount1 > 0) {
        IERC20(Currency.unwrap(poolKey.currency1)).transfer(
            address(poolManager),
            uint256(int256(amount1))
        );
    }
}
```

### Step 4: Implement Unlock Callback
```solidity
function lockAcquired(bytes calldata data) external returns (bytes memory) {
    // Parse swap params from data
    // Execute swap
    // Settle balances
    return "";
}
```

## Hook Permission Flags

```solidity
// V4 hooks use address-based permission encoding
// Lowest 14 bits of hook address determine which hooks execute

uint160 private constant BEFORE_INITIALIZE_FLAG = 1 << 13;    // Bit 13
uint160 private constant AFTER_INITIALIZE_FLAG = 1 << 12;     // Bit 12
uint160 private constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 11; // Bit 11
uint160 private constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 10;  // Bit 10
uint160 private constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 9;
uint160 private constant AFTER_REMOVE_LIQUIDITY_FLAG = 1 << 8;
uint160 private constant BEFORE_SWAP_FLAG = 1 << 7;
uint160 private constant AFTER_SWAP_FLAG = 1 << 6;

// Example: Hook at 0x0000000000000000000000000000000000000440
// Binary: 0100 0100 0000 = beforeSwap + afterAddLiquidity enabled
```

## Complete Working Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/types/BalanceDelta.sol";
import {Currency} from "@uniswap/v4-core/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract V4Router {
    IPoolManager public poolManager;

    // Example pool configuration
    PoolKey public constant WETH_USDC_POOL = PoolKey({
        currency0: Currency.wrap(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
        currency1: Currency.wrap(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), // USDC
        fee: 3000, // 0.30%
        tickSpacing: 60,
        hooks: IHooks(address(0)) // No hooks
    });

    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }

    // Simple swap: WETH → USDC
    function swapWETHForUSDC(uint256 amountWETH) external returns (uint256 amountUSDC) {
        // Prepare swap
        bool zeroForOne = true; // WETH to USDC
        int256 amountSpecified = int256(amountWETH);

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: 0 // No price limit
        });

        // Transfer WETH to PoolManager first
        IERC20(Currency.unwrap(WETH_USDC_POOL.currency0)).transferFrom(
            msg.sender,
            address(poolManager),
            amountWETH
        );

        // Execute swap via unlock pattern
        BalanceDelta delta = poolManager.swap(WETH_USDC_POOL, params, "");

        // Collect output tokens
        amountUSDC = uint256(int256(-delta.amount1()));

        // Return excess WETH if any
        int256 wethDelta = delta.amount0();
        if (wethDelta > 0) {
            IERC20(Currency.unwrap(WETH_USDC_POOL.currency0)).transfer(
                msg.sender,
                uint256(wethDelta)
            );
        }

        return amountUSDC;
    }

    // Swap with custom hook
    function swapWithHook(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata params,
        uint256 amountIn,
        address tokenIn
    ) external returns (uint256 amountOut) {
        // Transfer input tokens
        IERC20(tokenIn).transferFrom(msg.sender, address(poolManager), amountIn);

        // Execute swap (hook executes if registered)
        BalanceDelta delta = poolManager.swap(poolKey, params, "");

        // Determine output amount
        bool zeroForOne = params.zeroForOne;
        amountOut = zeroForOne
            ? uint256(int256(-delta.amount1()))
            : uint256(int256(-delta.amount0()));

        return amountOut;
    }

    // Get amount out (estimate)
    function quoteSwap(
        PoolKey calldata poolKey,
        int256 amountSpecified
    ) external returns (BalanceDelta delta) {
        // This would require oracle-based TWAP pricing in V4
        // Direct quote not available like V3, use TWAP oracle instead
        revert("Use TWAP oracle for V4 quotes");
    }
}
```

## ERC6909 Token Tracking

```solidity
// V4 uses ERC6909 (multi-token standard) instead of ERC20 LP tokens

import {IERC6909} from "@uniswap/v4-core/interfaces/IERC6909.sol";

contract ERC6909Example {
    IERC6909 public poolManager;

    // Get balance of LP tokens for a pool
    function getLPTokenBalance(PoolId poolId, address owner)
        external
        view
        returns (uint256 balance)
    {
        // Convert poolId to ERC6909 token ID
        uint256 tokenId = uint256(PoolId.unwrap(poolId));
        balance = poolManager.balanceOf(owner, tokenId);
    }

    // Transfer LP tokens
    function transferLP(PoolId poolId, address to, uint256 amount) external {
        uint256 tokenId = uint256(PoolId.unwrap(poolId));
        poolManager.transfer(to, tokenId, amount);
    }
}
```

## Hook Example (Custom Fee Multiplier)

```solidity
import {IHooks} from "@uniswap/v4-core/interfaces/IHooks.sol";

// Minimal hook that doubles fees on certain conditions
contract CustomFeeHook is IHooks {
    IPoolManager public poolManager;

    // Declare which hooks are enabled (bits 0-13)
    function getHookPermissions() external pure returns (Permissions memory) {
        return Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,  // Only beforeSwap enabled
            afterSwap: false
        });
    }

    // Called before every swap
    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        returns (bytes4)
    {
        // Custom logic: could modify fees, check conditions, etc.
        // Must return selector to indicate hook completed
        return IHooks.beforeSwap.selector;
    }

    // Other hooks return false to indicate they're disabled
    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        returns (bytes4)
    {
        return IHooks.NO_HOOKS_SELECTOR;
    }
}
```

## Balance Delta Encoding

```solidity
// V4 packs two int128 values into one int256

library BalanceDeltaHelper {
    // Encode two int128 into int256
    function encode(int128 amount0, int128 amount1)
        internal
        pure
        returns (int256 delta)
    {
        // amount0 in upper 128 bits, amount1 in lower 128 bits
        delta = (int256(amount0) << 128) | (int256(uint128(amount1)));
    }

    // Decode int256 into two int128
    function decode(int256 delta)
        internal
        pure
        returns (int128 amount0, int128 amount1)
    {
        amount0 = int128(delta >> 128);
        amount1 = int128(uint128(uint256(delta))); // Handle sign extension
    }
}
```

## Best Practices

### ✅ DO:
```solidity
// 1. Always implement proper hook permission checking
if (hook.address().code.length == 0) {
    revert("Hook not deployed");
}

// 2. Verify swap direction (zeroForOne)
bool zeroForOne = token0Price < token1Price;

// 3. Handle balance delta properly
BalanceDelta delta = poolManager.swap(poolKey, params, "");
require(delta.amount0() != 0 || delta.amount1() != 0, "No swap executed");

// 4. Use TWAP for V4 pricing (no direct quotes)
uint256 twapPrice = getTWAPPrice(poolKey);
uint256 minOut = amountIn * twapPrice * (10000 - slippageBps) / 1e18 / 10000;
```

### ❌ DON'T:
```solidity
// 1. Don't forget to handle hook state changes
// Hooks can modify fees, block swaps, etc.

// 2. Don't use spot prices directly in V4
// Same flash loan risk as V3
uint256 spotPrice = getSpotPrice(poolKey); // ⚠️ Manipulable

// 3. Don't ignore ERC6909 balance tracking
// LP tokens are now ERC6909, not ERC20
```

## V4 vs V3 vs V2 Comparison

| Feature | V2 | V3 | V4 |
|---------|----|----|-----|
| **Swap Pattern** | Direct call | Router callback | PoolManager unlock |
| **LP Tokens** | ERC20 | ERC721 NFT | ERC6909 |
| **Hooks** | None | Limited | 14 types |
| **Pool Design** | Individual contracts | Individual contracts | Singleton manager |
| **Balance Tracking** | Manual | Manual | ERC6909 built-in |
| **Fee Structure** | Fixed 0.3% | Tiered | Dynamic via hooks |

---

**For V2**: See `13-uniswap-v2-integration.md`
**For V3**: See `14-uniswap-v3-integration.md`
**Deep dive**: See `knowledge-base-research/repos/uniswap/10-uniswap-v4-deep-dive.md`
