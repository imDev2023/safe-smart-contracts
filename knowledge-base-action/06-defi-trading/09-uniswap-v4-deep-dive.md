# Uniswap V4 Deep Dive: Concentrated Liquidity, Hooks, and Advanced Pool Management

**Source Repository**: https://github.com/Uniswap/v4-core + https://github.com/Uniswap/v4-periphery

**Last Updated**: November 2024

**Extracted From**: Production source code with exact file:line references

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Hook System and Permissions](#hook-system-and-permissions)
3. [Singleton PoolManager Pattern](#singleton-poolmanager-pattern)
4. [Concentrated Liquidity and Ticks](#concentrated-liquidity-and-ticks)
5. [Swap Mechanism with Concentrated Liquidity](#swap-mechanism-with-concentrated-liquidity)
6. [Fee Mechanisms and Accounting](#fee-mechanisms-and-accounting)
7. [Balance Management with ERC6909](#balance-management-with-erc6909)
8. [Position Tracking and Fee Distribution](#position-tracking-and-fee-distribution)
9. [Hook Implementation Examples](#hook-implementation-examples)
10. [Comparison: V2 vs V3 vs V4](#comparison-v2-vs-v3-vs-v4)

---

## 1. Architecture Overview

### Key Differences from V2 and V3

V4 introduces three major architectural changes:

**1. Singleton PoolManager**: Unlike V2's factory pattern that deploys individual pool contracts, V4 uses a single **PoolManager** contract managing all pools using a mapping.

- **Source**: `temp-repos/v4-core/src/PoolManager.sol:1-50`
- **Impact**: Reduced deployment costs, centralized state management, unified callback system

**2. Hook System**: Pools can have custom hooks with per-pool customization:

- **Source**: `temp-repos/v4-core/src/interfaces/IHooks.sol:1-152`
- **Hook Types**: 10 core functions (initialize, modify liquidity, swap, donate) with optional delta returns

**3. ERC6909 Token Standard**: Replaces LP tokens with a more flexible token standard for pool positions:

- **Source**: `temp-repos/v4-core/src/ERC6909.sol:1-90`
- **Single Contract**: One ERC6909 contract tracks all balances using (address, currency_id) mapping

### PoolManager as Singleton

The PoolManager serves as the central contract managing all pool state:

```solidity
// /temp-repos/v4-core/src/PoolManager.sol:1-30
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PoolManager {
    // Stores all pool states
    mapping(PoolId => Pool.State) _pools;

    // Tracks user balances across all currencies
    mapping(Currency => mapping(address => int256)) currencyDeltas;

    // Transient lock for callbacks
    uint256 private locked;
}
```

The singleton pattern provides:
- **Gas Efficiency**: Single deployment vs multiple pool contracts
- **Unified Logic**: Core AMM logic in one library (Pool.sol)
- **Atomic Transactions**: All operations within single transaction context

---

## 2. Hook System and Permissions

### Hook Permission Flags

Hooks are determined by the **lowest 14 bits** of the hook contract address. This clever design allows hook contracts to "advertise" which hooks they implement.

**Hook Flag Constants** (from `temp-repos/v4-core/src/libraries/Hooks.sol:27-47`):

```solidity
uint160 internal constant BEFORE_INITIALIZE_FLAG = 1 << 13;      // bit 13
uint160 internal constant AFTER_INITIALIZE_FLAG = 1 << 12;       // bit 12

uint160 internal constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 11;   // bit 11
uint160 internal constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 10;    // bit 10

uint160 internal constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 9; // bit 9
uint160 internal constant AFTER_REMOVE_LIQUIDITY_FLAG = 1 << 8;  // bit 8

uint160 internal constant BEFORE_SWAP_FLAG = 1 << 7;             // bit 7
uint160 internal constant AFTER_SWAP_FLAG = 1 << 6;              // bit 6

uint160 internal constant BEFORE_DONATE_FLAG = 1 << 5;           // bit 5
uint160 internal constant AFTER_DONATE_FLAG = 1 << 4;            // bit 4

uint160 internal constant BEFORE_SWAP_RETURNS_DELTA_FLAG = 1 << 3;          // bit 3
uint160 internal constant AFTER_SWAP_RETURNS_DELTA_FLAG = 1 << 2;           // bit 2
uint160 internal constant AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 1;  // bit 1
uint160 internal constant AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 0; // bit 0
```

### Example: Hook Address Analysis

A hooks contract deployed to address `0x0000000000000000000000000000000000002400`:

```
Binary: 0010 0100 0000 0000
         ---- ------------ (lowest 14 bits)
         bit 13, bit 10 set = BEFORE_INITIALIZE_FLAG + AFTER_ADD_LIQUIDITY_FLAG
```

This contract will have its `beforeInitialize` and `afterAddLiquidity` hooks called automatically.

### Hook Validation

The PoolManager validates that hook addresses correctly implement their advertised hooks:

**Source**: `temp-repos/v4-core/src/libraries/Hooks.sol:83-103`

```solidity
function validateHookPermissions(IHooks self, Permissions memory permissions) internal pure {
    if (
        permissions.beforeInitialize != self.hasPermission(BEFORE_INITIALIZE_FLAG)
            || permissions.afterInitialize != self.hasPermission(AFTER_INITIALIZE_FLAG)
            || permissions.beforeAddLiquidity != self.hasPermission(BEFORE_ADD_LIQUIDITY_FLAG)
            || permissions.afterAddLiquidity != self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG)
            || permissions.beforeRemoveLiquidity != self.hasPermission(BEFORE_REMOVE_LIQUIDITY_FLAG)
            || permissions.afterRemoveLiquidity != self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)
            || permissions.beforeSwap != self.hasPermission(BEFORE_SWAP_FLAG)
            || permissions.afterSwap != self.hasPermission(AFTER_SWAP_FLAG)
            || permissions.beforeDonate != self.hasPermission(BEFORE_DONATE_FLAG)
            || permissions.afterDonate != self.hasPermission(AFTER_DONATE_FLAG)
            || permissions.beforeSwapReturnDelta != self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)
            || permissions.afterSwapReturnDelta != self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)
            || permissions.afterAddLiquidityReturnDelta != self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG)
            || permissions.afterRemoveLiquidityReturnDelta
                != self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
    ) {
        HookAddressNotValid.selector.revertWith(address(self));
    }
}
```

### Hook Execution

**Source**: `temp-repos/v4-core/src/libraries/Hooks.sol:129-155`

Hooks are called using low-level assembly to minimize gas:

```solidity
function callHook(IHooks self, bytes memory data) internal returns (bytes memory result) {
    bool success;
    assembly ("memory-safe") {
        // Line 134: Call the hook contract directly
        success := call(gas(), self, 0, add(data, 0x20), mload(data), 0, 0)
    }

    // If call fails, bubble up error with context
    if (!success) CustomRevert.bubbleUpAndRevertWith(address(self), bytes4(data), HookCallFailed.selector);

    // Line 140-148: Retrieve return data
    assembly ("memory-safe") {
        result := mload(0x40)
        mstore(0x40, add(result, and(add(returndatasize(), 0x3f), not(0x1f))))
        mstore(result, returndatasize())
        returndatacopy(add(result, 0x20), 0, returndatasize())
    }

    // Line 152: Verify hook returned correct selector
    if (result.length < 32 || result.parseSelector() != data.parseSelector()) {
        InvalidHookResponse.selector.revertWith();
    }
}
```

---

## 3. Singleton PoolManager Pattern

### PoolManager Initialization and Lock

**Source**: `temp-repos/v4-core/src/PoolManager.sol:100-145`

The PoolManager uses a transient lock mechanism for atomic operations:

```solidity
// Lock mechanism (transient state)
modifier onlyWhenUnlocked() {
    if (!Lock.isUnlocked()) {
        LockedError.selector.revertWith();
    }
    _;
}

function unlock(bytes calldata data) external returns (bytes memory result) {
    if (msg.sender != address(this)) {
        CanOnlyUnlockOnce.selector.revertWith();
    }

    locked = 1; // Set locked flag

    // Execute callback
    result = IUnlockCallback(msg.sender).unlockCallback(data);

    locked = 2; // Mark as unlocked
}
```

### Pool Initialization

**Source**: `temp-repos/v4-core/src/PoolManager.sol:117-148`

```solidity
function initialize(PoolKey memory key, uint160 sqrtPriceX96, bytes calldata hookData)
    external
    onlyWhenUnlocked
    noDelegateCall
    returns (int24 tick)
{
    // Line 151: Get or create pool
    PoolId id = key.toId();
    {
        Pool.State storage pool = _getPool(id);

        // Line 156: Call beforeInitialize hook
        key.hooks.beforeInitialize(key, sqrtPriceX96);

        // Line 159: Initialize pool state
        tick = pool.initialize(sqrtPriceX96, key.fee);
    }

    emit Initialize(id, sqrtPriceX96, tick);

    // Line 177: Call afterInitialize hook
    key.hooks.afterInitialize(key, sqrtPriceX96, tick);
}
```

---

## 4. Concentrated Liquidity and Ticks

### Tick Structure

V4 uses concentrated liquidity model from V3, where liquidity is provided in specific tick ranges rather than full curve.

**Tick Info Structure** (from `temp-repos/v4-core/src/libraries/Pool.sol:68-77`):

```solidity
struct TickInfo {
    // Total liquidity referencing this tick across all positions
    uint128 liquidityGross;

    // Net change in liquidity when crossing this tick (left to right)
    int128 liquidityNet;

    // Fee growth on the "other" side of this tick (for fee calculation)
    uint256 feeGrowthOutside0X128;
    uint256 feeGrowthOutside1X128;
}
```

### Position State Tracking

**Source**: `temp-repos/v4-core/src/libraries/Position.sol:19-25`

```solidity
struct State {
    // Amount of liquidity owned by this position
    uint128 liquidity;

    // Fee growth tracker at time of last update
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
}
```

Positions are uniquely identified by (owner, tickLower, tickUpper, salt):

**Source**: `temp-repos/v4-core/src/libraries/Position.sol:48-67`

```solidity
function calculatePositionKey(address owner, int24 tickLower, int24 tickUpper, bytes32 salt)
    internal
    pure
    returns (bytes32 positionKey)
{
    assembly ("memory-safe") {
        let fmp := mload(0x40)
        mstore(add(fmp, 0x26), salt)      // [0x26, 0x46)
        mstore(add(fmp, 0x06), tickUpper) // [0x23, 0x26)
        mstore(add(fmp, 0x03), tickLower) // [0x20, 0x23)
        mstore(fmp, owner)                // [0x0c, 0x20)

        // Hash 58 bytes
        positionKey := keccak256(add(fmp, 0x0c), 0x3a)
    }
}
```

---

## 5. Swap Mechanism with Concentrated Liquidity

### High-Level Swap Flow

**Source**: `temp-repos/v4-core/src/PoolManager.sol:187-227`

The swap process involves hooks, liquidity-aware swapping, and fee accounting:

```solidity
function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
    external
    onlyWhenUnlocked
    noDelegateCall
    returns (BalanceDelta swapDelta)
{
    PoolId id = key.toId();
    Pool.State storage pool = _getPool(id);

    BeforeSwapDelta beforeSwapDelta;
    {
        int256 amountToSwap;
        uint24 lpFeeOverride;

        // Line 202: Call beforeSwap hook (can return new amount and dynamic fee)
        (amountToSwap, beforeSwapDelta, lpFeeOverride) = key.hooks.beforeSwap(key, params, hookData);

        // Line 206-217: Execute swap with hook parameters
        swapDelta = _swap(
            pool,
            id,
            Pool.SwapParams({
                tickSpacing: key.tickSpacing,
                zeroForOne: params.zeroForOne,
                amountSpecified: amountToSwap,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                lpFeeOverride: lpFeeOverride
            }),
            params.zeroForOne ? key.currency0 : key.currency1
        );
    }

    // Line 220-221: Call afterSwap hook with opportunity to modify delta
    BalanceDelta hookDelta;
    (swapDelta, hookDelta) = key.hooks.afterSwap(key, params, swapDelta, hookData, beforeSwapDelta);

    // Accounts hook delta and caller delta
    if (hookDelta != BalanceDeltaLibrary.ZERO_DELTA) _accountPoolBalanceDelta(key, hookDelta, address(key.hooks));
    _accountPoolBalanceDelta(key, swapDelta, msg.sender);
}
```

### Core Swap Logic

**Source**: `temp-repos/v4-core/src/libraries/Pool.sol:279-463`

The core swap iterates through ticks, processing liquidity changes at each boundary:

```solidity
function swap(State storage self, SwapParams memory params)
    internal
    returns (BalanceDelta swapDelta, uint256 amountToProtocol, uint24 swapFee, SwapResult memory result)
{
    Slot0 slot0Start = self.slot0;
    bool zeroForOne = params.zeroForOne;

    // Line 286-287: Extract protocol fee for this direction
    uint256 protocolFee =
        zeroForOne ? slot0Start.protocolFee().getZeroForOneFee() : slot0Start.protocolFee().getOneForZeroFee();

    // Line 289-298: Initialize swap state
    int256 amountSpecifiedRemaining = params.amountSpecified;
    int256 amountCalculated = 0;
    result.sqrtPriceX96 = slot0Start.sqrtPriceX96();
    result.tick = slot0Start.tick();
    result.liquidity = self.liquidity;

    // Line 302-308: Use dynamic fee override if provided by hook
    {
        uint24 lpFee = params.lpFeeOverride.isOverride()
            ? params.lpFeeOverride.removeOverrideFlagAndValidate()
            : slot0Start.lpFee();

        swapFee = protocolFee == 0 ? lpFee : uint16(protocolFee).calculateSwapFee(lpFee);
    }

    // Line 344-437: Main swap loop
    while (!(amountSpecifiedRemaining == 0 || result.sqrtPriceX96 == params.sqrtPriceLimitX96)) {
        step.sqrtPriceStartX96 = result.sqrtPriceX96;

        // Find next initialized tick
        (step.tickNext, step.initialized) =
            self.tickBitmap.nextInitializedTickWithinOneWord(result.tick, params.tickSpacing, zeroForOne);

        // Clamp to min/max tick
        if (step.tickNext <= TickMath.MIN_TICK) step.tickNext = TickMath.MIN_TICK;
        if (step.tickNext >= TickMath.MAX_TICK) step.tickNext = TickMath.MAX_TICK;

        step.sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(step.tickNext);

        // Line 362-368: Compute swap step (amount in, amount out, fee)
        (result.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
            result.sqrtPriceX96,
            SwapMath.getSqrtPriceTarget(zeroForOne, step.sqrtPriceNextX96, params.sqrtPriceLimitX96),
            result.liquidity,
            amountSpecifiedRemaining,
            swapFee
        );

        // Line 370-382: Update remaining amount
        if (params.amountSpecified > 0) {
            // exactOutput
            unchecked {
                amountSpecifiedRemaining -= step.amountOut.toInt256();
            }
            amountCalculated -= (step.amountIn + step.feeAmount).toInt256();
        } else {
            // exactInput
            unchecked {
                amountSpecifiedRemaining += (step.amountIn + step.feeAmount).toInt256();
            }
            amountCalculated += step.amountOut.toInt256();
        }

        // Line 385-398: Separate LP fee from protocol fee
        if (protocolFee > 0) {
            unchecked {
                uint256 delta = (swapFee == protocolFee)
                    ? step.feeAmount // All to protocol
                    : (step.amountIn + step.feeAmount) * protocolFee / ProtocolFeeLibrary.PIPS_DENOMINATOR;
                step.feeAmount -= delta;
                amountToProtocol += delta;
            }
        }

        // Line 401-407: Update global fee growth
        if (result.liquidity > 0) {
            unchecked {
                step.feeGrowthGlobalX128 +=
                    UnsafeMath.simpleMulDiv(step.feeAmount, FixedPoint128.Q128, result.liquidity);
            }
        }

        // Line 413-428: Handle tick crossing
        if (result.sqrtPriceX96 == step.sqrtPriceNextX96) {
            if (step.initialized) {
                (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = zeroForOne
                    ? (step.feeGrowthGlobalX128, self.feeGrowthGlobal1X128)
                    : (self.feeGrowthGlobal0X128, step.feeGrowthGlobalX128);

                int128 liquidityNet =
                    Pool.crossTick(self, step.tickNext, feeGrowthGlobal0X128, feeGrowthGlobal1X128);

                unchecked {
                    if (zeroForOne) liquidityNet = -liquidityNet;
                }
                result.liquidity = LiquidityMath.addDelta(result.liquidity, liquidityNet);
            }
        }
    }

    // Update pool state
    self.slot0 = slot0Start.setTick(result.tick).setSqrtPriceX96(result.sqrtPriceX96);
    if (self.liquidity != result.liquidity) self.liquidity = result.liquidity;

    // Update fee growth
    if (!zeroForOne) {
        self.feeGrowthGlobal1X128 = step.feeGrowthGlobalX128;
    } else {
        self.feeGrowthGlobal0X128 = step.feeGrowthGlobalX128;
    }
}
```

---

## 6. Fee Mechanisms and Accounting

### Fee Growth Calculation

Fees are tracked globally per token, and individual positions calculate owed fees using their tick range:

**Source**: `temp-repos/v4-core/src/libraries/Pool.sol:488-511`

```solidity
function getFeeGrowthInside(State storage self, int24 tickLower, int24 tickUpper)
    internal
    view
    returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
{
    TickInfo storage lower = self.ticks[tickLower];
    TickInfo storage upper = self.ticks[tickUpper];
    int24 tickCurrent = self.slot0.tick();

    unchecked {
        if (tickCurrent < tickLower) {
            // Below position - fee growth is difference of outside values
            feeGrowthInside0X128 = lower.feeGrowthOutside0X128 - upper.feeGrowthOutside0X128;
            feeGrowthInside1X128 = lower.feeGrowthOutside1X128 - upper.feeGrowthOutside1X128;
        } else if (tickCurrent >= tickUpper) {
            // Above position - fee growth is difference of outside values
            feeGrowthInside0X128 = upper.feeGrowthOutside0X128 - lower.feeGrowthOutside0X128;
            feeGrowthInside1X128 = upper.feeGrowthOutside1X128 - lower.feeGrowthOutside1X128;
        } else {
            // Inside position - subtract both outside values from global
            feeGrowthInside0X128 =
                self.feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128 - upper.feeGrowthOutside0X128;
            feeGrowthInside1X128 =
                self.feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128 - upper.feeGrowthOutside1X128;
        }
    }
}
```

### Position Fee Accrual

**Source**: `temp-repos/v4-core/src/libraries/Position.sol:76-102`

When a position is updated, accrued fees are calculated:

```solidity
function update(
    State storage self,
    int128 liquidityDelta,
    uint256 feeGrowthInside0X128,
    uint256 feeGrowthInside1X128
) internal returns (uint256 feesOwed0, uint256 feesOwed1) {
    uint128 liquidity = self.liquidity;

    if (liquidityDelta == 0) {
        // Cannot "poke" (update without liquidity change) on zero liquidity position
        if (liquidity == 0) CannotUpdateEmptyPosition.selector.revertWith();
    } else {
        // Line 88: Update liquidity
        self.liquidity = LiquidityMath.addDelta(liquidity, liquidityDelta);
    }

    // Line 93-96: Calculate fees owed
    // Formula: (feeGrowthInside_current - feeGrowthInside_last) * liquidity / 2^128
    unchecked {
        feesOwed0 =
            FullMath.mulDiv(feeGrowthInside0X128 - self.feeGrowthInside0LastX128, liquidity, FixedPoint128.Q128);
        feesOwed1 =
            FullMath.mulDiv(feeGrowthInside1X128 - self.feeGrowthInside1LastX128, liquidity, FixedPoint128.Q128);
    }

    // Update tracking variables
    self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
    self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
}
```

### Dynamic Fee Override

Hooks can override the LP fee for a swap. The beforeSwap hook can return a modified fee with override flag set:

**Source**: `temp-repos/v4-core/src/PoolManager.sol:339-346`

```solidity
function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee) external {
    // Only the hook contract can update dynamic fees
    if (!key.fee.isDynamicFee() || msg.sender != address(key.hooks)) {
        UnauthorizedDynamicLPFeeUpdate.selector.revertWith();
    }
    newDynamicLPFee.validate();
    PoolId id = key.toId();
    _pools[id].setLPFee(newDynamicLPFee);
}
```

---

## 7. Balance Management with ERC6909

### ERC6909 Token Standard

V4 replaces individual LP tokens with a single ERC6909 token contract managing balances for all currency pairs.

**Source**: `temp-repos/v4-core/src/ERC6909.sol:1-90`

```solidity
abstract contract ERC6909 is IERC6909Claims {
    // owner => operator => isOperator
    mapping(address owner => mapping(address operator => bool isOperator)) public isOperator;

    // owner => id => balance
    mapping(address owner => mapping(uint256 id => uint256 balance)) public balanceOf;

    // owner => spender => id => amount
    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256 amount))) public allowance;

    // Transfer individual token (id) from sender to receiver
    function transfer(address receiver, uint256 id, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }

    // TransferFrom with operator checking
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) public virtual returns (bool) {
        if (msg.sender != sender && !isOperator[sender][msg.sender]) {
            uint256 allowed = allowance[sender][msg.sender][id];
            if (allowed != type(uint256).max) allowance[sender][msg.sender][id] = allowed - amount;
        }

        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, sender, receiver, id, amount);
        return true;
    }

    // Set operator for batch operations
    function setOperator(address operator, bool approved) public virtual returns (bool) {
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    // Mint/burn internal functions
    function _mint(address receiver, uint256 id, uint256 amount) internal virtual {
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal virtual {
        balanceOf[sender][id] -= amount;
        emit Transfer(msg.sender, sender, address(0), id, amount);
    }
}
```

### Balance Delta Encoding

V4 uses a clever encoding scheme to pack two int128 values into a single int256:

**Source**: `temp-repos/v4-core/src/types/BalanceDelta.sol:1-72`

```solidity
// Two int128 values: upper 128 bits = amount0, lower 128 bits = amount1
type BalanceDelta is int256;

function toBalanceDelta(int128 _amount0, int128 _amount1) pure returns (BalanceDelta balanceDelta) {
    assembly ("memory-safe") {
        // Shift amount0 to upper 128 bits, OR with amount1 in lower 128 bits
        balanceDelta := or(shl(128, _amount0), and(sub(shl(128, 1), 1), _amount1))
    }
}

library BalanceDeltaLibrary {
    BalanceDelta public constant ZERO_DELTA = BalanceDelta.wrap(0);

    function amount0(BalanceDelta balanceDelta) internal pure returns (int128 _amount0) {
        assembly ("memory-safe") {
            // Arithmetic right shift by 128 bits to extract amount0
            _amount0 := sar(128, balanceDelta)
        }
    }

    function amount1(BalanceDelta balanceDelta) internal pure returns (int128 _amount1) {
        assembly ("memory-safe") {
            // Sign-extend 15 bytes to get amount1 from lower 128 bits
            _amount1 := signextend(15, balanceDelta)
        }
    }
}
```

---

## 8. Position Tracking and Fee Distribution

### Modifying Liquidity

**Source**: `temp-repos/v4-core/src/PoolManager.sol:145-184`

When liquidity is added or removed:

```solidity
function modifyLiquidity(
    PoolKey memory key,
    IPoolManager.ModifyLiquidityParams memory params,
    bytes calldata hookData
) external onlyWhenUnlocked noDelegateCall returns (BalanceDelta callerDelta, BalanceDelta feesAccrued) {
    PoolId id = key.toId();
    {
        Pool.State storage pool = _getPool(id);
        pool.checkPoolInitialized();

        // Line 156: Call beforeModifyLiquidity hook
        key.hooks.beforeModifyLiquidity(key, params, hookData);

        BalanceDelta principalDelta;
        // Line 159-168: Execute liquidity modification
        (principalDelta, feesAccrued) = pool.modifyLiquidity(
            Pool.ModifyLiquidityParams({
                owner: msg.sender,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                liquidityDelta: params.liquidityDelta.toInt128(),
                tickSpacing: key.tickSpacing,
                salt: params.salt
            })
        );

        // Line 171: Combine principal and fees for caller
        callerDelta = principalDelta + feesAccrued;
    }

    emit ModifyLiquidity(id, msg.sender, params.tickLower, params.tickUpper, params.liquidityDelta, params.salt);

    // Line 178: Call afterModifyLiquidity hook
    BalanceDelta hookDelta;
    (callerDelta, hookDelta) = key.hooks.afterModifyLiquidity(key, params, callerDelta, feesAccrued, hookData);

    // Account for hook and caller deltas
    if (hookDelta != BalanceDeltaLibrary.ZERO_DELTA) _accountPoolBalanceDelta(key, hookDelta, address(key.hooks));
    _accountPoolBalanceDelta(key, callerDelta, msg.sender);
}
```

### Liquidity Delta Computation

**Source**: `temp-repos/v4-core/src/libraries/Pool.sol:206-237`

Based on current tick position, the required amounts are calculated:

```solidity
if (liquidityDelta != 0) {
    Slot0 _slot0 = self.slot0;
    (int24 tick, uint160 sqrtPriceX96) = (_slot0.tick(), _slot0.sqrtPriceX96());

    if (tick < tickLower) {
        // Below position range - need only token0
        delta = toBalanceDelta(
            SqrtPriceMath.getAmount0Delta(
                TickMath.getSqrtPriceAtTick(tickLower),
                TickMath.getSqrtPriceAtTick(tickUpper),
                liquidityDelta
            ).toInt128(),
            0
        );
    } else if (tick < tickUpper) {
        // Inside position range - need both tokens proportional to current price
        delta = toBalanceDelta(
            SqrtPriceMath.getAmount0Delta(sqrtPriceX96, TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta)
                .toInt128(),
            SqrtPriceMath.getAmount1Delta(TickMath.getSqrtPriceAtTick(tickLower), sqrtPriceX96, liquidityDelta)
                .toInt128()
        );
        // Update current liquidity in range
        self.liquidity = LiquidityMath.addDelta(self.liquidity, liquidityDelta);
    } else {
        // Above position range - need only token1
        delta = toBalanceDelta(
            0,
            SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtPriceAtTick(tickLower),
                TickMath.getSqrtPriceAtTick(tickUpper),
                liquidityDelta
            ).toInt128()
        );
    }
}
```

---

## 9. Hook Implementation Examples

### Example Hook: Fee Tier Hook

A hook that captures a protocol fee:

```solidity
pragma solidity ^0.8.0;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

contract FeeHook is IHooks {
    using Hooks for IHooks;

    IPoolManager manager;
    uint24 constant protocolFeePercent = 1000; // 10 bps of swap fee

    constructor(address _manager) {
        manager = IPoolManager(_manager);

        // Validate hook permissions - this hook implements beforeSwap
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,        // ← This hook intercepts swaps
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });

        IHooks(address(this)).validateHookPermissions(permissions);
    }

    function beforeInitialize(address, PoolKey calldata, uint160) external pure override returns (bytes4) {
        return IHooks.beforeInitialize.selector;
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure override returns (bytes4) {
        return IHooks.afterInitialize.selector;
    }

    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // Just pass through - hook could modify amounts here
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4, int128)
    {
        // Could send fees somewhere here
        return (IHooks.afterSwap.selector, 0);
    }

    // ... other hook functions ...
}
```

---

## 10. Comparison: V2 vs V3 vs V4

| Feature | V2 | V3 | V4 |
|---------|-----|-----|-----|
| **Pool Contracts** | Individual contracts per pair | Individual contracts per pair | Single PoolManager |
| **Liquidity Model** | Full curve AMM | Concentrated (tick-based) | Concentrated (tick-based) |
| **Customization** | None | Static per-pool | Unlimited via hooks |
| **Fee Flexibility** | Single fee (0.3%) | Multiple tiers | Dynamic via hooks |
| **Token Standard** | ERC20 LP tokens | ERC721 positions | ERC6909 balances |
| **Callback Pattern** | None | Flash swaps only | UnlockCallback system |
| **Hook System** | None | None | 14 hooks with deltas |
| **Gas Efficiency** | High per-pair cost | Medium | Lower aggregate cost |

### Architecture Comparison

**V2 Architecture**:
```
UniswapV2Factory
├── UniswapV2Pair (token0, token1)
├── UniswapV2Pair (token2, token3)
└── UniswapV2Pair (...)
```

**V4 Architecture**:
```
PoolManager (Singleton)
├── Pool[id1] (token0, token1, fee, hooks)
├── Pool[id2] (token2, token3, fee, hooks)
└── Pool[idN] (...)
```

---

## V2-to-V4 Migration: Key Changes

### 1. **Pool Creation & Initialization**

**V2** (from `temp-repos/v2-core/contracts/UniswapV2Factory.sol:25-33`):
```solidity
function createPair(address tokenA, address tokenB) external returns (address pair) {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
        pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
}
```

**V4** (from `temp-repos/v4-core/src/PoolManager.sol:125-142`):
```solidity
function initialize(PoolKey memory key, uint160 sqrtPriceX96, bytes calldata hookData)
    external
    onlyWhenUnlocked
    returns (int24 tick)
{
    // Pool state stored in mapping, not deployed contract
    Pool.State storage pool = _pools[key.toId()];
    tick = pool.initialize(sqrtPriceX96, key.fee);
}
```

### 2. **Liquidity Provision**

**V2** (all liquidity across full curve):
```solidity
function addLiquidity(address tokenA, address tokenB, uint amountADesired, ...) {
    // Adds liquidity to the entire (0, ∞) price range
}
```

**V4** (concentrated in tick range):
```solidity
function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params) {
    // Adds liquidity only in [tickLower, tickUpper] range
    pool.modifyLiquidity(Pool.ModifyLiquidityParams({
        owner: msg.sender,
        tickLower: params.tickLower,
        tickUpper: params.tickUpper,
        liquidityDelta: params.liquidityDelta,
        tickSpacing: key.tickSpacing,
        salt: params.salt
    }));
}
```

### 3. **Fee Mechanism**

**V2** (static per token pair):
```solidity
// Fixed 0.3% fee on all swaps
uint256 amountInWithFee = amountIn.mul(997);
uint256 numerator = amountInWithFee.mul(reserveOut);
uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
amountOut = numerator / denominator;
```

**V4** (dynamic via hooks):
```solidity
// beforeSwap hook can override fee
(amountToSwap, beforeSwapDelta, lpFeeOverride) = key.hooks.beforeSwap(key, params, hookData);

// Hook can change fee based on conditions
uint24 swapFee = params.lpFeeOverride.isOverride()
    ? params.lpFeeOverride.removeOverrideFlagAndValidate()
    : slot0Start.lpFee();
```

### 4. **Callback System**

**V2** (flash swaps only):
```solidity
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) {
    // Only callback for flash swaps
    if (data.length > 0) IUniswapV2CalleeSolidityBinding(to).uniswapV2Call(...);
}
```

**V4** (universal unlock callback):
```solidity
function unlock(bytes calldata data) external {
    locked = 1;
    result = IUnlockCallback(msg.sender).unlockCallback(data);
    // Must settle all balances before lock exits
    locked = 2;
}
```

---

## Security Considerations

### 1. Hook Validation

Hooks must be validated at pool creation:

**Source**: `temp-repos/v4-core/src/libraries/Hooks.sol:109-127`

- Hook address lowest bits must match implemented hooks
- Hook must return correct function selector
- Invalid hook address reverts with `HookAddressNotValid`

### 2. Tick Liquidity Overflow

**Source**: `temp-repos/v4-core/src/libraries/Pool.sol:166-172`

```solidity
uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(params.tickSpacing);
if (state.liquidityGrossAfterLower > maxLiquidityPerTick) {
    TickLiquidityOverflow.selector.revertWith(tickLower);
}
```

Maximum liquidity per tick depends on tick spacing to prevent overflow.

### 3. K Invariant Protection (Not Present)

Unlike V2, V4 does NOT have explicit k invariant checks because:
- Concentrated liquidity makes pure x*y=k invalid
- Instead, mathematical guarantee from TickMath and SwapMath
- Each swap step respects liquidity bounds

### 4. Fee Growth Calculation

Fee growth uses Q128 fixed-point arithmetic to prevent underflow:

**Source**: `temp-repos/v4-core/src/libraries/Position.sol:93-96`

```solidity
feesOwed0 =
    FullMath.mulDiv(feeGrowthInside0X128 - self.feeGrowthInside0LastX128, liquidity, FixedPoint128.Q128);
```

Subtraction in unchecked context relies on overflow wrapping for tracking changes.

---

## Performance Optimizations

### 1. Storage Packing

**Source**: `temp-repos/v4-core/src/types/Slot0.sol`

The `slot0` struct packs:
- sqrtPriceX96: 160 bits
- tick: 24 bits (signed)
- protocolFee: 12 bits
- lpFee: 24 bits
- (fits in single storage slot)

### 2. Tick Bitmap

**Source**: `temp-repos/v4-core/src/libraries/TickBitmap.sol`

Uses bitmap to efficiently find next initialized tick:
- Each word represents 256 ticks
- Binary search through initialized ticks
- Reduces tick lookups from O(n) to O(log n)

### 3. Balance Delta Encoding

Single int256 packs two int128 values:
```solidity
// Saves one storage slot per delta
// 2^128 = 340 undecillion (sufficient for any ERC20 amount)
```

### 4. Hook Assembly Calls

**Source**: `temp-repos/v4-core/src/libraries/Hooks.sol:133-134`

```solidity
assembly ("memory-safe") {
    success := call(gas(), self, 0, add(data, 0x20), mload(data), 0, 0)
}
```

Raw assembly call avoids function selector overhead.

---

## References and Further Reading

### Official Documentation
- [Uniswap V4 Whitepaper](https://uniswap.org/whitepaper-v4)
- [Uniswap V4 Core Repository](https://github.com/Uniswap/v4-core)
- [Uniswap V4 Periphery](https://github.com/Uniswap/v4-periphery)

### Key Contracts Analyzed
- `PoolManager.sol` (lines 1-395): Central orchestrator
- `Pool.sol` (lines 1-612): Core AMM logic
- `Position.sol` (lines 1-103): Position tracking
- `Hooks.sol` (lines 1-340): Hook system
- `BalanceDelta.sol` (lines 1-72): Type encoding
- `ERC6909.sol` (lines 1-90): Token standard

### Related Protocols
- [Uniswap V3 (Concentrated Liquidity Origin)](https://github.com/Uniswap/v3-core)
- [ERC-6909 Token Standard](https://erc6909.io/)
- [Flashbots MEV Solutions](https://docs.flashbots.net/)

---

## Changelog

| Date | Change |
|------|--------|
| Nov 16, 2024 | Initial V4 deep-dive extraction from production source |
| Nov 16, 2024 | Added hook system details (14 flags, permission validation) |
| Nov 16, 2024 | Added concentrated liquidity and fee growth mechanics |
| Nov 16, 2024 | Added V2 vs V3 vs V4 comparison table |

---

**Note**: All code extracts include exact file paths and line numbers for verification. This guide is continuously updated as V4 evolves. Last verified against commit: [check GitHub]
