# Chainlink Automation Integration Guide

> Set up Chainlink Keepers for automated contract execution (5 min read)

## Quick Integration (3 steps)

### Step 1: Register Upkeep
```
1. Go to https://automation.chain.link
2. Click "Register new upkeep"
3. Select trigger type:
   - Time-based: Fixed interval
   - Custom logic: checkUpkeep condition
   - Log-based: Event triggers
4. Set gas limit: 100,000-1,000,000
5. Fund with LINK tokens
```

### Step 2: Implement checkUpkeep + performUpkeep
```solidity
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract YieldFarm is AutomationCompatible {
    uint256 public lastCompoundTime;
    uint256 public compoundInterval = 1 days;

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastCompoundTime) >= compoundInterval;
        performData = abi.encode(msg.sender);
    }

    function performUpkeep(bytes calldata performData) external override {
        // Executed by Chainlink Keepers
        (address triggeredBy) = abi.decode(performData, (address));

        // Your compound logic
        _compoundRewards();
        lastCompoundTime = block.timestamp;
    }
}
```

### Step 3: Test Locally
```solidity
function test_upkeep() external {
    (bool upkeepNeeded, ) = checkUpkeep("");
    require(upkeepNeeded, "Upkeep not needed yet");

    performUpkeep(""); // Should execute without revert
}
```

## Trigger Types

### Time-Based (Simplest)
```
✅ Pros:
  - Simple to set up
  - Predictable execution
  - Low gas

❌ Cons:
  - Executes even if not needed
  - No custom logic
  - Wasteful
```

### Custom Logic (Most Flexible)
```solidity
function checkUpkeep(bytes calldata)
    external
    view
    returns (bool upkeepNeeded, bytes memory performData)
{
    // Check multiple conditions
    bool rewardsReady = pendingRewards > MIN_REWARD;
    bool timePassed = block.timestamp - lastCompound > 1 days;
    bool priceGood = oraclePrice < MAX_PRICE;

    upkeepNeeded = rewardsReady && timePassed && priceGood;

    if (upkeepNeeded) {
        performData = abi.encode(address(this), msg.sender);
    }
}
```

### Log-Based (Event-Triggered)
```solidity
event SwapExecuted(address indexed user, uint256 amount);

// Chainlink watches for this event
// When emitted, automatically calls performUpkeep
emit SwapExecuted(msg.sender, swapAmount);
```

## Full Working Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract LiquidationBot is AutomationCompatible {
    struct Position {
        address user;
        uint256 borrowed;
        uint256 collateral;
        uint256 liquidationPrice;
    }

    Position[] public positions;
    mapping(address => bool) public isLiquidatable;

    uint256 public lastCheckTime;
    uint256 public checkInterval = 5 minutes;

    event PositionLiquidated(address indexed user, uint256 amount);

    // Step 1: Keeper checks if liquidation needed
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (block.timestamp - lastCheckTime < checkInterval) {
            return (false, "");
        }

        // Find positions ready for liquidation
        uint256 count = 0;
        uint256[] memory liquidatableIds = new uint256[](positions.length);

        for (uint256 i = 0; i < positions.length; i++) {
            if (isPositionLiquidatable(i)) {
                liquidatableIds[count] = i;
                count++;
            }
        }

        if (count > 0) {
            upkeepNeeded = true;
            performData = abi.encode(liquidatableIds, count);
        }
    }

    // Step 2: Keeper executes liquidation
    function performUpkeep(bytes calldata performData) external override {
        (uint256[] memory liquidatableIds, uint256 count) = abi.decode(
            performData,
            (uint256[], uint256)
        );

        for (uint256 i = 0; i < count; i++) {
            uint256 posId = liquidatableIds[i];
            Position memory pos = positions[posId];

            // Liquidate position
            _liquidate(posId);
            emit PositionLiquidated(pos.user, pos.borrowed);
        }

        lastCheckTime = block.timestamp;
    }

    function isPositionLiquidatable(uint256 posId) internal view returns (bool) {
        Position memory pos = positions[posId];
        uint256 currentPrice = getCurrentPrice();
        return currentPrice <= pos.liquidationPrice;
    }

    function _liquidate(uint256 posId) internal {
        Position memory pos = positions[posId];
        // Transfer collateral, repay debt, etc.
        // ... liquidation logic ...
    }

    function getCurrentPrice() internal view returns (uint256) {
        // Get price from oracle
        return 1000e8; // Placeholder
    }
}
```

## Cost Analysis

```
Automation (per execution):
- Gas cost: User pays
- Keeper reward: 0.8 LINK (per execution)
- Premium gas: 20% gas cost surcharge

Total ≈ Gas fee + 0.8 LINK per upkeep execution
```

## Best Practices

### ✅ DO:

```solidity
// 1. Return early if not needed
if (block.timestamp - lastTime < interval) {
    return (false, "");
}

// 2. Limit loop iterations in checkUpkeep
// checkUpkeep has 5M gas limit
for (uint256 i = 0; i < array.length; i++) {
    if (i >= 100) break; // Max 100 items
}

// 3. Pass essential data only
performData = abi.encode(userId, amount);

// 4. Set reasonable gas limit
// Too low: execution fails
// Too high: costs more LINK
gasLimit = 500000; // Sweet spot

// 5. Have fallback mechanism
if (block.timestamp - lastExecution > maxInterval) {
    // Execute without Keepers
}
```

### ❌ DON'T:

```solidity
// 1. Don't loop through all positions every time
for (uint256 i = 0; i < 10000; i++) { // ⚠️ OOG
    if (shouldProcess[i]) process(i);
}

// 2. Don't call external contracts in checkUpkeep
// Takes too much gas, times out
oraclePrice = priceOracle.getPrice(); // ⚠️ Slow

// 3. Don't rely only on Automation
// Keepers can fail, network outages happen
require(keeper == msg.sender); // ⚠️ No fallback

// 4. Don't make performUpkeep non-payable without reason
function performUpkeep(bytes calldata) external { // ⚠️ Can't receive LINK
```

## Security Considerations

### Trigger Manipulation
```
Risk: Attacker structures transactions to prevent execution
Fix:  Use time-based + custom logic combination
```

### Replay Attacks
```
Risk: Same performData used twice
Fix:  Use nonce or block.timestamp in encoding
```

```solidity
function performUpkeep(bytes calldata performData) external override {
    (uint256 executionBlock, bytes32 dataHash) = abi.decode(
        performData,
        (uint256, bytes32)
    );

    require(executionBlock == block.number - 1, "Stale data");
    require(!executed[dataHash], "Already executed");

    executed[dataHash] = true;
    // Proceed with execution
}
```

## Configuration by Chain

### Ethereum Mainnet
```solidity
address REGISTRAR = 0xb8B4B5a1dCeAE5F6b1c6e1A2b2b3bC2d0c0c0c0c;
address REGISTRY = 0xE16Df59B887e3Cdf1249fa47b91D02DF599d7235;
```

### Arbitrum
```solidity
address REGISTRAR = 0x819B58A646CDd5130A6777993E4514faD4Df4D4d;
address REGISTRY = 0x86EFBD0b6736bed2a86A451d0B9101TBD;
```

### Polygon
```solidity
address REGISTRAR = 0xDb8e8e2B597Cbf53640C89865b64f76d5b08bDC;
address REGISTRY = 0x02777053d6764996e594738F360D7C3A2713f3aD;
```

## Monitoring & Alerts

```solidity
event UpkeepFailed(uint256 indexed upkeepId, string reason);
event UpkeepExecuted(uint256 indexed upkeepId, uint256 timestamp);

function checkUpkeep(bytes calldata)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
{
    try this.simulateUpkeep() {
        upkeepNeeded = true;
    } catch Error(string memory reason) {
        // Log failure for monitoring
        emit UpkeepFailed(block.number, reason);
        upkeepNeeded = false;
    }
}

function simulateUpkeep() external {
    // Simulate execution to ensure it won't revert
    performUpkeep("");
    revert("Simulation only");
}
```

---

**For price feeds**: See `08-chainlink-datafeed-integration.md`
**For VRF**: See `09-chainlink-vrf-integration.md`
**Deep dive**: See `knowledge-base-research/repos/chainlink/11-chainlink-oracle-deep-dive.md`
