# Uniswap V3 Integration Guide

> Step-by-step Uniswap V3 concentrated liquidity integration (5 min read)

## Quick Integration (3 steps)

### Step 1: Import V3 Router & Position Manager
```solidity
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract V3Example {
    ISwapRouter public constant SWAP_ROUTER =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    INonfungiblePositionManager public constant POSITION_MANAGER =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBE3E5A83DCCB93);
}
```

### Step 2: Execute Swap
```solidity
function swapTokens(
    address tokenIn,
    address tokenOut,
    uint24 fee,
    uint256 amountIn,
    uint256 minAmountOut
) external returns (uint256 amountOut) {
    // Approve tokens
    IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    IERC20(tokenIn).approve(address(SWAP_ROUTER), amountIn);

    // Execute swap
    ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + 60,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut,
            sqrtPriceLimitX96: 0
        });

    amountOut = SWAP_ROUTER.exactInputSingle(params);
    return amountOut;
}
```

### Step 3: Add Liquidity Position
```solidity
function mintPosition(
    address token0,
    address token1,
    uint24 fee,
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0,
    uint256 amount1
) external returns (uint256 tokenId) {
    // Approve tokens
    IERC20(token0).transferFrom(msg.sender, address(this), amount0);
    IERC20(token1).transferFrom(msg.sender, address(this), amount1);
    IERC20(token0).approve(address(POSITION_MANAGER), amount0);
    IERC20(token1).approve(address(POSITION_MANAGER), amount1);

    // Mint position
    (tokenId, , , ) = POSITION_MANAGER.mint(
        INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 60
        })
    );

    return tokenId;
}
```

## Fee Tiers

```solidity
// Standard fee tiers
uint24 public constant FEE_LOW = 500;       // 0.05% (stable pairs)
uint24 public constant FEE_MEDIUM = 3000;   // 0.30% (standard)
uint24 public constant FEE_HIGH = 10000;    // 1.00% (volatile)

// Fee tier selection
function selectFeeTier(address token0, address token1)
    internal
    pure
    returns (uint24 fee)
{
    // USDC/USDT, USDC/DAI → 0.05%
    // ETH/USDC, BTC/USDC → 0.30%
    // Exotic tokens → 1.00%

    return FEE_MEDIUM; // Default
}
```

## Tick Calculation

```solidity
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract TickExample {
    // Get current tick from pool
    function getCurrentTick(address poolAddress)
        external
        view
        returns (int24 tick)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        (,tick,,,,) = pool.slot0();
        return tick;
    }

    // Set tick range (±2% from current price)
    function getTickRange(address poolAddress, int24 tickSpacing)
        external
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        int24 currentTick = getCurrentTick(poolAddress);

        // Example: ±4 ticks from current with spacing of 60
        int24 offset = 4 * tickSpacing;
        tickLower = currentTick - offset;
        tickUpper = currentTick + offset;

        return (tickLower, tickUpper);
    }
}
```

## Complete Working Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract V3SwapAndLP {
    ISwapRouter public constant SWAP_ROUTER =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    INonfungiblePositionManager public constant POSITION_MANAGER =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBE3E5A83DCCB93);

    uint24 private constant FEE = 3000; // 0.30%

    // Swap token0 for token1
    function exactInputSingle(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        IERC20(token0).transferFrom(msg.sender, address(this), amountIn);
        IERC20(token0).approve(address(SWAP_ROUTER), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: FEE,
                recipient: msg.sender,
                deadline: block.timestamp + 60,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        amountOut = SWAP_ROUTER.exactInputSingle(params);
    }

    // Multi-hop swap (token0 → token1 → token2)
    function exactInputMultiple(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        // Build bytes path: address(token0) + fee + address(token1) + fee + address(token2)
        bytes memory bytesPath = abi.encodePacked(path[0], FEE, path[1], FEE, path[2]);

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(SWAP_ROUTER), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: bytesPath,
                recipient: msg.sender,
                deadline: block.timestamp + 60,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            });

        amountOut = SWAP_ROUTER.exactInput(params);
    }

    // Add liquidity to a position
    function addLiquidity(
        address token0,
        address token1,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256 tokenId
    ) external returns (uint128 liquidity, uint256 amount0Used, uint256 amount1Used) {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        IERC20(token0).approve(address(POSITION_MANAGER), amount0);
        IERC20(token1).approve(address(POSITION_MANAGER), amount1);

        (liquidity, amount0Used, amount1Used, ) = POSITION_MANAGER.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 60
            })
        );
    }

    // Collect fees from position
    function collectFees(uint256 tokenId) external returns (uint256 fee0, uint256 fee1) {
        (fee0, fee1) = POSITION_MANAGER.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }
}
```

## Best Practices

### ✅ DO:
```solidity
// 1. Use reasonable tick ranges to avoid impermanent loss
// Current tick ± 2% is safe
int24 safeOffset = 100; // Depends on tickSpacing

// 2. Collect fees periodically
if (block.timestamp - lastCollect > 1 days) {
    POSITION_MANAGER.collect(...);
    lastCollect = block.timestamp;
}

// 3. Check pool liquidity before adding
uint128 poolLiquidity = IUniswapV3Pool(poolAddress).liquidity();
require(poolLiquidity > MIN_LIQUIDITY, "Low liquidity");

// 4. Use multi-hop for better pricing
bytes memory path = abi.encodePacked(token0, fee, token1, fee, token2);
```

### ❌ DON'T:
```solidity
// 1. Don't use extreme tick ranges (full range like V2)
// Loses capital efficiency benefit of V3

// 2. Don't ignore impermanent loss
// V3 concentrates it more than V2

// 3. Don't use 0 for min amounts
POSITION_MANAGER.mint(..., 0, 0, ...); // ⚠️ Accept any slippage

// 4. Don't forget to collect fees
// Fees expire or get stuck
```

## Slippage on V3

```solidity
// V3 has per-tick slippage, not just at endpoints
function getMinAmountV3(
    uint256 amountIn,
    address[] memory path,
    uint256 slippageBps
) internal view returns (uint256 minAmountOut) {
    // Use oracle-based price instead of spot
    uint256 fairPrice = getTWAPPrice(path);

    // Apply slippage to oracle price
    minAmountOut = (amountIn * fairPrice * (10000 - slippageBps)) / (1e18 * 10000);

    return minAmountOut;
}
```

## Pool Addresses (Mainnet)

```solidity
// WETH/USDC (0.30%)
address constant ETH_USDC_POOL = 0x8ad599c3A0ff1de082011EFDDc58f1908eb6e6D8;

// USDC/USDT (0.05%)
address constant USDC_USDT_POOL = 0x7858E59e0C01EA06Df3aF3D20aC7B0003F0637A8;

// DAI/USDC (0.05%)
address constant DAI_USDC_POOL = 0x6c6Bc977E619592067NbC6cF763c4677f5c73B45;
```

---

**For V2**: See `13-uniswap-v2-integration.md`
**For V4 hooks**: See `15-uniswap-v4-integration.md`
**Deep dive**: See `knowledge-base-research/repos/uniswap/09-uniswap-v3-deep-dive.md`
