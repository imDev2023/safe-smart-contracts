# SafeERC20

## Overview

`SafeERC20` is a library providing safe wrappers around ERC20 operations. It handles non-standard ERC20 tokens that don't follow the specification correctly, preventing common pitfalls in token interactions.

**Contract Path**: `@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol`
**Version**: 5.x
**License**: MIT

## The Problem

Many ERC20 tokens don't follow the standard correctly:

### Issue 1: Missing Return Values
Some tokens don't return `bool`:
```solidity
// Standard ERC20
function transfer(address to, uint256 amount) external returns (bool);

// Non-standard (e.g., USDT)
function transfer(address to, uint256 amount) external; // No return!
```

### Issue 2: Returning false Instead of Reverting
Some tokens return `false` on failure instead of reverting:
```solidity
bool success = token.transfer(to, amount);
// If success is false, you might not notice!
```

### Issue 3: Approval Race Condition
The `approve` function has a known race condition with front-running.

## SafeERC20 Solution

```solidity
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount) external {
        // Safe transfer - works with any ERC20
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(IERC20 token, uint256 amount) external {
        // Safe transfer - reverts on failure
        token.safeTransfer(msg.sender, amount);
    }
}
```

## Key Functions

### 1. safeTransfer
```solidity
function safeTransfer(IERC20 token, address to, uint256 value)
```
Safe version of `transfer`. Reverts if:
- Transfer fails
- Token doesn't return true
- Token has no return value (handles USDT)

### 2. safeTransferFrom
```solidity
function safeTransferFrom(IERC20 token, address from, address to, uint256 value)
```
Safe version of `transferFrom`. Same guarantees as `safeTransfer`.

### 3. safeIncreaseAllowance
```solidity
function safeIncreaseAllowance(IERC20 token, address spender, uint256 value)
```
Safely increases allowance without race conditions.

### 4. safeDecreaseAllowance
```solidity
function safeDecreaseAllowance(IERC20 token, address spender, uint256 value)
```
Safely decreases allowance. Reverts if current allowance is insufficient.

### 5. forceApprove
```solidity
function forceApprove(IERC20 token, address spender, uint256 value)
```
Sets approval to exact value, handling tokens that require resetting to 0 first (like USDT).

## Usage Examples

### Basic Token Handling
```solidity
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVault {
    using SafeERC20 for IERC20;

    mapping(address => mapping(IERC20 => uint256)) public balances;

    function deposit(IERC20 token, uint256 amount) external {
        balances[msg.sender][token] += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(IERC20 token, uint256 amount) external {
        require(balances[msg.sender][token] >= amount, "Insufficient balance");
        balances[msg.sender][token] -= amount;
        token.safeTransfer(msg.sender, amount);
    }
}
```

### DeFi Protocol Integration
```solidity
contract YieldFarm {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    function stake(uint256 amount) external {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        // Update staking logic
    }

    function claimRewards(uint256 rewardAmount) external {
        // Calculate rewards
        rewardToken.safeTransfer(msg.sender, rewardAmount);
    }

    function approveStrategy(address strategy, uint256 amount) external onlyOwner {
        stakingToken.forceApprove(strategy, amount);
    }
}
```

### Handling Multiple Tokens
```solidity
contract MultiTokenVault {
    using SafeERC20 for IERC20;

    function batchDeposit(
        IERC20[] calldata tokens,
        uint256[] calldata amounts
    ) external {
        require(tokens.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
        }
    }
}
```

## Approval Management

### The Approval Race Condition
```solidity
// UNSAFE: Approval race condition
token.approve(spender, 100);
// ... later ...
token.approve(spender, 200); // Spender can front-run and spend 300!
```

### Safe Alternative
```solidity
using SafeERC20 for IERC20;

// Safe: Increase allowance
token.safeIncreaseAllowance(spender, 100);

// Safe: Decrease allowance
token.safeDecreaseAllowance(spender, 50);

// Safe: Set to specific value (handles USDT)
token.forceApprove(spender, 200);
```

## Special Token Handling

### USDT and Similar Tokens
USDT requires setting allowance to 0 before changing it:

```solidity
// UNSAFE with USDT
token.approve(spender, 200); // Reverts if allowance is not 0!

// SAFE with SafeERC20
token.forceApprove(spender, 200); // Handles the reset automatically
```

### Tokens Without Return Values
```solidity
// SafeERC20 handles tokens that don't return bool
token.safeTransfer(to, amount); // Works even if transfer() doesn't return
```

### Fee-on-Transfer Tokens
Be careful with tokens that take fees on transfer:

```solidity
contract FeeTokenVault {
    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount) external {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));

        uint256 actualAmount = balanceAfter - balanceBefore; // Actual received
        balances[msg.sender] += actualAmount;
    }
}
```

## Gas Considerations

- **safeTransfer**: ~3,000 gas overhead vs regular transfer
- **safeTransferFrom**: ~3,000 gas overhead
- **forceApprove**: ~2 approvals if current allowance > 0 (~50,000 gas)

The safety is worth the minimal gas cost.

## Common Patterns

### Pattern 1: Escrow Contract
```solidity
contract Escrow {
    using SafeERC20 for IERC20;

    function createEscrow(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        // Store escrow details
    }

    function releaseEscrow(uint256 escrowId) external {
        // Verify conditions
        token.safeTransfer(beneficiary, amount);
    }
}
```

### Pattern 2: Token Swap
```solidity
contract SimpleSwap {
    using SafeERC20 for IERC20;

    function swap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external {
        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenOut.safeTransfer(msg.sender, amountOut);
    }
}
```

### Pattern 3: Staking with Rewards
```solidity
contract StakingRewards {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    function stake(uint256 amount) external {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] += amount;
    }

    function unstake(uint256 amount) external {
        stakes[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
    }

    function claimRewards() external {
        uint256 reward = calculateReward(msg.sender);
        rewardToken.safeTransfer(msg.sender, reward);
    }
}
```

## Testing

```javascript
describe("SafeERC20", function() {
    it("should safely transfer tokens", async function() {
        const amount = ethers.parseEther("100");

        await token.approve(vault.address, amount);
        await vault.deposit(token.address, amount);

        expect(await token.balanceOf(vault.address)).to.equal(amount);
    });

    it("should handle non-standard tokens", async function() {
        // Test with USDT-like token (no return value)
        const usdt = await NonStandardToken.deploy();

        await usdt.approve(vault.address, amount);
        await vault.deposit(usdt.address, amount); // Should work
    });

    it("should revert on failed transfer", async function() {
        await expect(
            vault.withdraw(token.address, tooMuchAmount)
        ).to.be.reverted;
    });
});
```

## Best Practices

1. **Always Use SafeERC20 for External Tokens**
   ```solidity
   // UNSAFE
   IERC20(unknownToken).transfer(to, amount);

   // SAFE
   IERC20(unknownToken).safeTransfer(to, amount);
   ```

2. **Use forceApprove for Changing Allowances**
   ```solidity
   token.forceApprove(spender, newAmount); // Handles all edge cases
   ```

3. **Check Balances for Fee-on-Transfer Tokens**
   ```solidity
   uint256 before = token.balanceOf(address(this));
   token.safeTransferFrom(msg.sender, address(this), amount);
   uint256 actualAmount = token.balanceOf(address(this)) - before;
   ```

4. **Combine with ReentrancyGuard**
   ```solidity
   function withdraw(IERC20 token, uint256 amount)
       external
       nonReentrant
   {
       token.safeTransfer(msg.sender, amount);
   }
   ```

## Summary

**SafeERC20 is essential for**:
- Interacting with external/unknown tokens
- DeFi protocols handling multiple token types
- Any contract accepting ERC20 tokens from users
- Production contracts where safety is critical

**Key Takeaways**:
- Handles non-standard ERC20 implementations
- Prevents approval race conditions
- Minimal gas overhead (~3,000 gas)
- Works with USDT, tokens without return values
- Always use for external token interactions
- Combine with ReentrancyGuard for maximum safety
- Essential for DeFi and multi-token contracts
