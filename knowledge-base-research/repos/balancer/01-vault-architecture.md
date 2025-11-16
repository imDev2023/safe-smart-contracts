# Balancer V2 - Generalized AMM with Vault Architecture

> Flexible AMM supporting weighted pools, stable coins, and custom pool types

**Repo:** https://github.com/balancer/balancer-v2-monorepo.git
**Purpose:** Multi-pool DEX with vault-based liquidity management
**Key Innovation:** Vault pattern (single contract holds all liquidity), custom pool types

---

## Architecture Overview

### Vault Concept (Core Innovation)

```
Traditional DEX (Uniswap):
├── Pool A (holds USDC + DAI)
├── Pool B (holds DAI + ETH)
└── Pool C (holds ETH + USDC)
     ↓
 Each pool has its own reserves, duplicates liquidity

Balancer Vault:
├── Single Vault contract holds ALL tokens
├── Pool A references Vault for USDC + DAI
├── Pool B references Vault for DAI + ETH
└── Pool C references Vault for ETH + USDC
     ↓
 Liquidity shared across pools, better capital efficiency
```

**Benefits:**
- Share liquidity across pools
- Single settlement point
- Batch processing of swaps
- Composability for custom pools

---

## Core Components

### 1. The Vault

```solidity
interface IVault {
    // Deposit tokens into vault
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    // Withdraw tokens from vault
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    // Swap tokens
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256);

    // Multiple swaps in sequence
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory);
}
```

**Key Feature:** `batchSwap` allows multiple swaps in one transaction

---

### 2. Pool Types

#### Weighted Pool
```
Most flexible: each token has independent weight

Example: 80/20 pool
├── 80% WETH, 20% DAI
├── Requires only 0.25 ETH to move to 80.25%
└── Can support unusual ratios (like LBP)

Formula: V = (x₁^w₁ * x₂^w₂) = K  (generalized constant product)
```

#### Stable Pool (StableSwap)
```
For correlated assets (stablecoins)

Example: USDC/USDT/USDC
├── Trades near 1:1 ratio
├── Deeper liquidity near peg
└── Low slippage for stable swaps

Formula: Similar to Curve, optimized for stables
```

#### Linear Pool
```
For assets with underlying yield

Example: aUSDC (Aave-wrapped USDC)
├── One side locked in yield protocol
├── Swaps against external protocol
└── Generate yield while providing liquidity
```

---

## Integration Pattern

### Swap on Balancer

```solidity
pragma solidity ^0.8.0;

import { IVault, IAsset } from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

contract BalancerSwapper {
    IVault constant VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);  // Ethereum

    function swapUSDCtoDAI(
        uint256 amountUSDC,
        uint256 minDAI
    ) external returns (uint256 daiOut) {
        // Approve vault
        IERC20(USDC).approve(address(VAULT), amountUSDC);

        // Single swap
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: 0x...,  // USDC/DAI pool ID
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(address(USDC)),
            assetOut: IAsset(address(DAI)),
            amount: amountUSDC,
            userData: ""
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: msg.sender,
            fromInternalBalance: false,
            recipient: payable(msg.sender),
            toInternalBalance: false
        });

        daiOut = VAULT.swap(singleSwap, funds, minDAI, block.timestamp + 300);
    }

    function batchSwapExample(
        bytes32[] memory poolIds,
        IAsset[] memory assets,
        int256[] memory limits
    ) external {
        IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](2);

        // Swap 1: USDC → DAI
        swaps[0] = IVault.BatchSwapStep({
            poolId: poolIds[0],
            assetInIndex: 0,      // USDC
            assetOutIndex: 1,      // DAI
            amount: 1000e6,        // 1000 USDC
            userData: ""
        });

        // Swap 2: DAI → USDT
        swaps[1] = IVault.BatchSwapStep({
            poolId: poolIds[1],
            assetInIndex: 1,       // DAI (output of swap 0)
            assetOutIndex: 2,      // USDT
            amount: 0,             // 0 = use all output from swap 0
            userData: ""
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: msg.sender,
            fromInternalBalance: false,
            recipient: payable(msg.sender),
            toInternalBalance: false
        });

        VAULT.batchSwap(
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            funds,
            limits,
            block.timestamp + 300
        );
    }
}
```

---

### Add Liquidity

```solidity
function joinWeightedPool(
    bytes32 poolId,
    uint256[] memory amounts,
    uint256[] memory tokens
) external {
    // Approve tokens
    for (uint i = 0; i < tokens.length; i++) {
        IERC20(tokens[i]).approve(address(VAULT), amounts[i]);
    }

    // Join pool
    bytes memory userData = abi.encode(
        IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
        amounts,
        0  // minBPT
    );

    IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
        assets: assets,
        maxAmountsIn: amounts,
        userData: userData,
        fromInternalBalance: false
    });

    VAULT.joinPool(poolId, msg.sender, msg.sender, request);
}
```

---

## Key Data Structures

### Pool ID
```
bytes32 poolId = keccak256(abi.encodePacked(poolAddress, poolSpecializedId))

Example: 0x0b09dea16768f0799065c475be02919503cb2a3502180004000000000000001e

Split into:
├── Pool address (20 bytes)
├── Specialized ID (2 bytes, pool-specific nonce)
└── Pool type (1 byte)
```

### SwapKind

```solidity
enum SwapKind {
    GIVEN_IN,   // Specify input amount, get output
    GIVEN_OUT   // Specify output amount, pay input
}
```

---

## Pool Discovery

### Finding Pool IDs

```javascript
// Use Balancer Subgraph
const query = `{
  pools(where: { tokensList_contains: ["0x...usdc", "0x...dai"] }) {
    id
    address
    poolType
    tokens { address symbol }
  }
}`;

// Or use Balancer JS SDK
const pools = await balancer.getPools({
  where: { tokensList_contains: ["0xUSDC", "0xDAI"] }
});
```

---

## Advantages vs Uniswap

| Feature | Balancer | Uniswap |
|---------|----------|---------|
| **Pool Types** | Weighted, stable, linear, custom | V2: constant product only, V3: concentrated |
| **Liquidity Sharing** | ✅ Vault pattern | ❌ Per-pool only |
| **Weights** | Variable (80/20, 60/40, etc.) | Fixed 50/50 (V2), concentrated (V3) |
| **Batch Swaps** | ✅ Multiple in one tx | ❌ Single swap only |
| **Capital Efficiency** | Good (via weights) | Better (V3 concentrated) |
| **Complexity** | Higher | Lower |

---

## Use Cases

### ✅ Good For Balancer

- Swapping between correlated assets (stablecoins)
- Complex LPs with custom weights (80/20, 60/40)
- Liquidity mining (veBAL incentives)
- Portfolio rebalancing (batch swaps)
- Custom pool types

### ✅ Good For Uniswap

- Deep liquidity in major pairs (ETH/USDC)
- Concentrated liquidity needed
- Simple integration required
- Highest swap volume

---

## Mainnet Addresses

| Contract | Address |
|----------|---------|
| **Vault** | 0xBA12222222228d8Ba445958a75a0704d566BF2C8 |
| **Router** | 0x152ce14da08fb53b30a42b2e17ce4b9a60e8a549 |
| **Weighted Factory** | 0x8e9aa87e45e92d1541433cb469c1a6b532cb12d5 |
| **Stable Factory** | 0xc7e5038f003203B3D2CFF01e9db0d0750B6221D6 |

---

## Integration Patterns

### Pattern 1: Direct Vault Interaction

```solidity
// Most gas-efficient, requires understanding pool encoding
```

### Pattern 2: Use Balancer Router

```solidity
// Higher-level abstraction, easier to use
IBalancerRouter.swap(...)
```

### Pattern 3: Balancer SDK (Off-Chain)

```javascript
// Recommended for complex routing logic
const { BalancerSDK } = require('@balancer-labs/sdk');
const balancer = new BalancerSDK({ network: 1 });
```

---

## Key Implementation Files

**Core:**
- `pkg/vault/contracts/Vault.sol` - Main vault contract
- `pkg/v2-interfaces/contracts/vault/IVault.sol` - Vault interface

**Pools:**
- `pkg/pool-weighted/contracts/WeightedPool.sol` - 80/20 type pool
- `pkg/pool-weighted/contracts/WeightedPoolFactory.sol` - Pool creation

**Utils:**
- `pkg/pool-utils/contracts/PoolBase.sol` - Base pool implementation
- `pkg/solidity-utils/contracts/math/` - Math utilities

---

## When NOT to Use Balancer

❌ Simple ERC20 ↔ ERC20 swap (use Uniswap V2)
❌ Need maximum gas efficiency (use Uniswap V3)
❌ Extremely deep liquidity in major pairs (use Uniswap)

---

**Status:** Ready to integrate for weighted AMM swaps
**Docs:** https://docs.balancer.fi
**Subgraph:** https://thegraph.com/hosted-service/subgraph/balancer-labs/balancer-v2
**SDK:** https://github.com/balancer/balancer-js
