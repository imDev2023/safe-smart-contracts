# Uniswap V2 Integration Guide

> Step-by-step Uniswap V2 swap integration (5 min read)

## Quick Integration (4 steps)

### Step 1: Import Router Interface
```solidity
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract SwapExample {
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_V2_ROUTER);
}
```

### Step 2: Approve Tokens
```solidity
function approveTokens(address token, uint256 amount) external {
    IERC20(token).approve(UNISWAP_V2_ROUTER, amount);
}
```

### Step 3: Execute Swap
```solidity
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] calldata path,
    address to
) external returns (uint256[] memory amounts) {
    IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

    return uniswapRouter.swapExactTokensForTokens(
        amountIn,
        minAmountOut,
        path,
        to,
        block.timestamp + 60 minutes
    );
}
```

### Step 4: Calculate Min Output
```solidity
function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts)
{
    return uniswapRouter.getAmountsOut(amountIn, path);
}
```

## Swap Paths

### Ethereum Mainnet
```solidity
// ETH → USDC
address[] memory path = new address[](2);
path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
path[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

// USDC → DAI → USDT (3-hop)
address[] memory path = new address[](3);
path[0] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
path[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
path[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
```

### Arbitrum
```solidity
// ETH → USDC
address[] memory path = new address[](2);
path[0] = 0x82aF49447d8a07e3bd95BD0d56f35241523fBab1; // WETH
path[1] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5F86; // USDC
```

### Polygon
```solidity
// MATIC → USDC
address[] memory path = new address[](2);
path[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // WMATIC
path[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC
```

## Complete Working Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleV2Swap {
    IUniswapV2Router02 public uniswapRouter;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private constant SLIPPAGE_TOLERANCE = 100; // 1% in basis points

    constructor(address _router) {
        uniswapRouter = IUniswapV2Router02(_router);
    }

    // Swap exact tokens for tokens with slippage protection
    function swap(
        uint256 amountIn,
        uint256 slippageBps,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        // Get amounts out
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amountIn, path);
        uint256 amountOutMinimum = amountsOut[amountsOut.length - 1] * (10000 - slippageBps) / 10000;

        // Transfer tokens to contract
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapRouter), amountIn);

        // Execute swap
        amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMinimum,
            path,
            msg.sender,
            block.timestamp + 300 // 5 min deadline
        );

        return amounts;
    }

    // Swap ETH for tokens
    function swapETHForTokens(
        uint256 slippageBps,
        address[] calldata path
    ) external payable returns (uint256[] memory amounts) {
        require(path[0] == WETH, "Path must start with WETH");

        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(msg.value, path);
        uint256 amountOutMinimum = amountsOut[amountsOut.length - 1] * (10000 - slippageBps) / 10000;

        amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            amountOutMinimum,
            path,
            msg.sender,
            block.timestamp + 300
        );

        return amounts;
    }

    // Swap tokens for ETH
    function swapTokensForETH(
        uint256 amountIn,
        uint256 slippageBps,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "Path must end with WETH");

        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amountIn, path);
        uint256 amountOutMinimum = amountsOut[amountsOut.length - 1] * (10000 - slippageBps) / 10000;

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapRouter), amountIn);

        amounts = uniswapRouter.swapExactTokensForETH(
            amountIn,
            amountOutMinimum,
            path,
            msg.sender,
            block.timestamp + 300
        );

        return amounts;
    }

    receive() external payable {}
}
```

## Best Practices

### ✅ DO:
```solidity
// 1. Always set deadline (prevent pending transaction attacks)
uint256 deadline = block.timestamp + 5 minutes;

// 2. Calculate min output with slippage
uint256 minOut = expectedOut * (10000 - slippageBps) / 10000;
require(minOut > 0, "Slippage too high");

// 3. Check path is valid
require(path.length >= 2, "Invalid path");
require(path[0] != path[path.length - 1], "Path same token");

// 4. Use SafeERC20 for transfers
safeTransferFrom(path[0], msg.sender, address(this), amountIn);
```

### ❌ DON'T:
```solidity
// 1. Don't set minAmountOut to 0
uniswapRouter.swapExactTokensForTokens(amountIn, 0, path, to, deadline); // ⚠️ No slippage protection

// 2. Don't skip deadline
uniswapRouter.swapExactTokensForTokens(amountIn, minOut, path, to, type(uint256).max); // ⚠️ Stuck forever

// 3. Don't forget to approve
// Missing: IERC20(token).approve(router, amount);

// 4. Don't use spot price without checking
uint256 spotPrice = getAmountsOut(amountIn, path)[1];
// ⚠️ Can be manipulated via flash loans
```

## Common Issues & Solutions

| Issue | Cause | Fix |
|-------|-------|-----|
| "K" | Insufficient output after swap | Increase slippage tolerance |
| Transaction pending | Deadline too long ago | Use `block.timestamp + 60` |
| Wrong amount received | Bad path | Verify path tokens exist on chain |
| Transfer failed | ERC20 non-standard | Use SafeERC20 wrapper |
| Insufficient liquidity | Pool too small | Use multi-hop path |

## Testing

```solidity
// Mock getAmountsOut for testing
function testSwapPath() external {
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    path[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    uint256[] memory amounts = uniswapRouter.getAmountsOut(1 ether, path);
    require(amounts[1] > 0, "No liquidity");
    require(amounts.length == 2, "Wrong path length");
}
```

---

**For concentrated liquidity**: See `14-uniswap-v3-integration.md`
**For advanced hooks**: See `15-uniswap-v4-integration.md`
**Deep dive**: See `knowledge-base-research/repos/uniswap/08-uniswap-v2-deep-dive.md`
