# Event Templates Reference

Standard event patterns for common contract scenarios. All events use proper indexing for efficient off-chain querying.

---

## 1. Transfer/Movement Events

### Transfer - Token Movement

```solidity
/**
 * @dev Emitted when tokens are moved from one account to another
 * @param from Address tokens are transferred from (indexed for filtering)
 * @param to Address tokens are transferred to (indexed for filtering)
 * @param value Amount of tokens transferred
 */
event Transfer(address indexed from, address indexed to, uint256 value);

// Usage
function transfer(address to, uint256 amount) public returns (bool) {
    address owner = msg.sender;
    balances[owner] -= amount;
    balances[to] += amount;

    emit Transfer(owner, to, amount);
    return true;
}
```

**Indexed Parameters:** `from`, `to` (allows filtering by sender/receiver)
**Why This Matters:** Essential for tracking token movements, wallet integrations
**Off-chain Indexing:** Filter by from/to addresses to get all transfers for a user
**Gas Cost:** ~375 gas per non-indexed topic, ~750 gas per indexed topic

---

### Approval - Spending Allowance

```solidity
/**
 * @dev Emitted when spending allowance is set
 * @param owner Address of token owner (indexed)
 * @param spender Address authorized to spend (indexed)
 * @param value Approved amount
 */
event Approval(address indexed owner, address indexed spender, uint256 value);

// Usage
function approve(address spender, uint256 amount) public returns (bool) {
    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
}
```

**Indexed Parameters:** `owner`, `spender`
**Why This Matters:** Track approval changes, detect approval attacks
**Off-chain Indexing:** Monitor approval events to detect suspicious patterns
**Security Note:** Emit on every approval change, even to zero

---

### Deposit - Value Received

```solidity
/**
 * @dev Emitted when user deposits value
 * @param user Address making deposit (indexed)
 * @param amount Amount deposited
 * @param timestamp Time of deposit
 */
event Deposit(address indexed user, uint256 amount, uint256 timestamp);

// Usage
function deposit() public payable {
    require(msg.value > 0, "Zero deposit");
    balances[msg.sender] += msg.value;

    emit Deposit(msg.sender, msg.value, block.timestamp);
}
```

**Indexed Parameters:** `user` (filter deposits by user)
**Why This Matters:** Track user deposits, calculate TVL
**Off-chain Indexing:** Sum all deposits to calculate total value locked
**Additional Data:** Consider adding token address for multi-token vaults

---

### Withdrawal - Value Sent

```solidity
/**
 * @dev Emitted when user withdraws value
 * @param user Address making withdrawal (indexed)
 * @param amount Amount withdrawn
 * @param timestamp Time of withdrawal
 */
event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);

// Usage
function withdraw(uint256 amount) public nonReentrant {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;

    emit Withdrawal(msg.sender, amount, block.timestamp);

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

**Indexed Parameters:** `user`
**Why This Matters:** Track withdrawals, detect bank run scenarios
**Off-chain Indexing:** Alert on large withdrawals, calculate net deposits
**Best Practice:** Emit before external call (checks-effects-interactions)

---

### Swap - Token Exchange

```solidity
/**
 * @dev Emitted when tokens are swapped
 * @param user Address performing swap (indexed)
 * @param tokenIn Input token address (indexed)
 * @param tokenOut Output token address (indexed)
 * @param amountIn Amount of input tokens
 * @param amountOut Amount of output tokens
 */
event Swap(
    address indexed user,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
);

// Usage
function swap(address tokenIn, address tokenOut, uint256 amountIn)
    public
    returns (uint256 amountOut)
{
    // Swap logic here
    amountOut = calculateSwapOutput(amountIn);

    emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
}
```

**Indexed Parameters:** `user`, `tokenIn`, `tokenOut` (3 indexed max)
**Why This Matters:** Track trading activity, calculate volume
**Off-chain Indexing:** Filter by token pair to get price history
**Note:** Maximum 3 indexed parameters per event

---

## 2. Access Control Events

### RoleGranted - Permission Added

```solidity
/**
 * @dev Emitted when role is granted to account
 * @param role Role identifier (indexed)
 * @param account Address receiving role (indexed)
 * @param sender Address granting role (indexed)
 */
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

// Usage
function grantRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _roles[role][account] = true;

    emit RoleGranted(role, account, msg.sender);
}
```

**Indexed Parameters:** `role`, `account`, `sender`
**Why This Matters:** Audit trail for permission changes
**Off-chain Indexing:** Monitor role grants to detect unauthorized access
**Security:** Alert on unexpected role grants

---

### RoleRevoked - Permission Removed

```solidity
/**
 * @dev Emitted when role is revoked from account
 * @param role Role identifier (indexed)
 * @param account Address losing role (indexed)
 * @param sender Address revoking role (indexed)
 */
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

// Usage
function revokeRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _roles[role][account] = false;

    emit RoleRevoked(role, account, msg.sender);
}
```

**Indexed Parameters:** `role`, `account`, `sender`
**Why This Matters:** Track permission removal, security audit
**Off-chain Indexing:** Verify role revocations match expectations
**Best Practice:** Cannot revoke own admin role accidentally

---

### OwnershipTransferred - Owner Change

```solidity
/**
 * @dev Emitted when contract ownership is transferred
 * @param previousOwner Address of previous owner (indexed)
 * @param newOwner Address of new owner (indexed)
 */
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// Usage
function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Zero address");
    address oldOwner = owner;
    owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
}
```

**Indexed Parameters:** `previousOwner`, `newOwner`
**Why This Matters:** Critical for governance, security monitoring
**Off-chain Indexing:** Alert on ownership changes immediately
**Security:** Always validate newOwner != address(0)

---

### OwnershipTransferStarted - Two-Step Transfer

```solidity
/**
 * @dev Emitted when ownership transfer is initiated
 * @param previousOwner Current owner (indexed)
 * @param newOwner Pending new owner (indexed)
 */
event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

/**
 * @dev Emitted when pending owner accepts ownership
 * @param previousOwner Previous owner (indexed)
 * @param newOwner New owner (indexed)
 */
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// Usage
function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
    emit OwnershipTransferStarted(owner, newOwner);
}

function acceptOwnership() public {
    require(msg.sender == pendingOwner, "Not pending owner");
    address oldOwner = owner;
    owner = pendingOwner;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
}
```

**Indexed Parameters:** `previousOwner`, `newOwner`
**Why This Matters:** Safer ownership transfer, prevents mistakes
**Off-chain Indexing:** Track two-step process completion
**Best Practice:** Preferred over single-step transfer

---

## 3. State Change Events

### StateChanged - State Machine Transition

```solidity
/**
 * @dev Emitted when contract state changes
 * @param from Previous state (indexed)
 * @param to New state (indexed)
 * @param timestamp Time of change
 */
event StateChanged(
    State indexed from,
    State indexed to,
    uint256 timestamp
);

// State enum
enum State { Pending, Active, Paused, Completed }

// Usage
function _transitionTo(State newState) internal {
    State oldState = currentState;
    currentState = newState;

    emit StateChanged(oldState, newState, block.timestamp);
}
```

**Indexed Parameters:** `from`, `to` (allows filtering state transitions)
**Why This Matters:** Track workflow progression, debug state issues
**Off-chain Indexing:** Build state machine diagram from events
**Best Practice:** Validate state transitions before emitting

---

### ParameterUpdated - Configuration Change

```solidity
/**
 * @dev Emitted when protocol parameter is updated
 * @param parameter Name of parameter (indexed)
 * @param oldValue Previous value
 * @param newValue New value
 * @param updatedBy Address making change (indexed)
 */
event ParameterUpdated(
    bytes32 indexed parameter,
    uint256 oldValue,
    uint256 newValue,
    address indexed updatedBy
);

// Usage
function setFeeRate(uint256 newRate) public onlyOwner {
    require(newRate <= MAX_FEE, "Fee too high");
    uint256 oldRate = feeRate;
    feeRate = newRate;

    emit ParameterUpdated(
        keccak256("FEE_RATE"),
        oldRate,
        newRate,
        msg.sender
    );
}
```

**Indexed Parameters:** `parameter`, `updatedBy`
**Why This Matters:** Audit configuration changes, detect parameter manipulation
**Off-chain Indexing:** Alert on critical parameter changes
**Best Practice:** Include old and new values for comparison

---

### Initialized - Initialization Complete

```solidity
/**
 * @dev Emitted when contract is initialized
 * @param version Initialization version
 * @param initializer Address performing initialization (indexed)
 */
event Initialized(uint8 version, address indexed initializer);

// Usage
function initialize(address owner) public {
    require(!_initialized, "Already initialized");
    _initialized = true;

    // Initialization logic
    _owner = owner;

    emit Initialized(1, msg.sender);
}
```

**Indexed Parameters:** `initializer`
**Why This Matters:** Track proxy initialization, verify correct setup
**Off-chain Indexing:** Verify initialization happened exactly once
**Upgradeable:** Include version for tracking upgrades

---

## 4. Economic Events

### RewardClaimed - User Reward Collection

```solidity
/**
 * @dev Emitted when user claims rewards
 * @param user Address claiming rewards (indexed)
 * @param rewardToken Token address (indexed)
 * @param amount Amount claimed
 * @param timestamp Time of claim
 */
event RewardClaimed(
    address indexed user,
    address indexed rewardToken,
    uint256 amount,
    uint256 timestamp
);

// Usage
function claimRewards() public {
    uint256 pending = calculateRewards(msg.sender);
    require(pending > 0, "No rewards");

    rewards[msg.sender] = 0;

    emit RewardClaimed(msg.sender, rewardToken, pending, block.timestamp);

    IERC20(rewardToken).transfer(msg.sender, pending);
}
```

**Indexed Parameters:** `user`, `rewardToken`
**Why This Matters:** Track reward distribution, calculate APY
**Off-chain Indexing:** Sum claims to verify total rewards distributed
**Analytics:** Calculate claim frequency, average claim size

---

### RewardDistributed - Batch Distribution

```solidity
/**
 * @dev Emitted when rewards are distributed to all users
 * @param rewardToken Token distributed (indexed)
 * @param totalAmount Total amount distributed
 * @param recipients Number of recipients
 * @param timestamp Distribution time
 */
event RewardDistributed(
    address indexed rewardToken,
    uint256 totalAmount,
    uint256 recipients,
    uint256 timestamp
);

// Usage
function distributeRewards(uint256 totalReward) public onlyOwner {
    require(totalReward > 0, "Zero reward");

    // Distribution logic
    uint256 recipients = 0;
    for (uint256 i = 0; i < users.length; i++) {
        uint256 userReward = calculateUserShare(users[i], totalReward);
        if (userReward > 0) {
            rewards[users[i]] += userReward;
            recipients++;
        }
    }

    emit RewardDistributed(rewardToken, totalReward, recipients, block.timestamp);
}
```

**Indexed Parameters:** `rewardToken`
**Why This Matters:** Track protocol-wide distributions
**Off-chain Indexing:** Calculate distribution intervals, total rewards over time
**Performance:** Include summary data (recipients count)

---

### FeeCollected - Protocol Revenue

```solidity
/**
 * @dev Emitted when protocol fees are collected
 * @param token Token in which fee was collected (indexed)
 * @param amount Fee amount
 * @param receiver Fee recipient (indexed)
 * @param source Source of fee (e.g., "swap", "withdrawal")
 */
event FeeCollected(
    address indexed token,
    uint256 amount,
    address indexed receiver,
    string source
);

// Usage
function _collectFee(address token, uint256 amount, string memory source) internal {
    fees[token] += amount;

    emit FeeCollected(token, amount, feeReceiver, source);
}
```

**Indexed Parameters:** `token`, `receiver`
**Why This Matters:** Track protocol revenue, fee sources
**Off-chain Indexing:** Calculate total fees by token, by source
**Analytics:** Identify most profitable features

---

### LiquidityAdded - Pool Liquidity Increase

```solidity
/**
 * @dev Emitted when liquidity is added to pool
 * @param provider Liquidity provider (indexed)
 * @param tokenA First token address (indexed)
 * @param tokenB Second token address (indexed)
 * @param amountA Amount of tokenA added
 * @param amountB Amount of tokenB added
 * @param liquidity LP tokens minted
 */
event LiquidityAdded(
    address indexed provider,
    address indexed tokenA,
    address indexed tokenB,
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
);

// Usage
function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB)
    public
    returns (uint256 liquidity)
{
    // Add liquidity logic
    liquidity = calculateLPTokens(amountA, amountB);

    emit LiquidityAdded(msg.sender, tokenA, tokenB, amountA, amountB, liquidity);
}
```

**Indexed Parameters:** `provider`, `tokenA`, `tokenB` (max 3 indexed)
**Why This Matters:** Track liquidity changes, calculate pool depth
**Off-chain Indexing:** Monitor liquidity provision patterns
**DeFi:** Essential for DEX analytics

---

## 5. Emergency Events

### Paused - Emergency Stop Activated

```solidity
/**
 * @dev Emitted when contract is paused
 * @param account Address that triggered pause (indexed)
 * @param timestamp Time of pause
 */
event Paused(address indexed account, uint256 timestamp);

// Usage
function pause() public onlyRole(PAUSER_ROLE) {
    require(!_paused, "Already paused");
    _paused = true;

    emit Paused(msg.sender, block.timestamp);
}
```

**Indexed Parameters:** `account`
**Why This Matters:** CRITICAL security event, requires immediate attention
**Off-chain Indexing:** Alert team immediately, notify users
**Response:** Should trigger incident response procedures

---

### Unpaused - Normal Operations Resumed

```solidity
/**
 * @dev Emitted when contract is unpaused
 * @param account Address that triggered unpause (indexed)
 * @param timestamp Time of unpause
 */
event Unpaused(address indexed account, uint256 timestamp);

// Usage
function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_paused, "Not paused");
    _paused = false;

    emit Unpaused(msg.sender, block.timestamp);
}
```

**Indexed Parameters:** `account`
**Why This Matters:** Signals return to normal operations
**Off-chain Indexing:** Calculate pause duration, notify users
**Best Practice:** Higher privilege required than pause

---

### EmergencyWithdrawal - Emergency Fund Recovery

```solidity
/**
 * @dev Emitted during emergency withdrawal
 * @param token Token withdrawn (indexed)
 * @param recipient Withdrawal recipient (indexed)
 * @param amount Amount withdrawn
 * @param reason Reason for emergency withdrawal
 */
event EmergencyWithdrawal(
    address indexed token,
    address indexed recipient,
    uint256 amount,
    string reason
);

// Usage
function emergencyWithdraw(address token, uint256 amount, string memory reason)
    public
    onlyOwner
    whenPaused
{
    emit EmergencyWithdrawal(token, msg.sender, amount, reason);

    IERC20(token).transfer(msg.sender, amount);
}
```

**Indexed Parameters:** `token`, `recipient`
**Why This Matters:** Emergency fund recovery, potential security incident
**Off-chain Indexing:** High-priority alert, manual review required
**Transparency:** Include reason for emergency action

---

## 6. Upgrade Events

### Upgraded - Implementation Changed

```solidity
/**
 * @dev Emitted when implementation is upgraded
 * @param implementation Address of new implementation (indexed)
 * @param version New version identifier
 * @param timestamp Upgrade time
 */
event Upgraded(address indexed implementation, string version, uint256 timestamp);

// Usage
function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    emit Upgraded(newImplementation, "v2.0.0", block.timestamp);
}
```

**Indexed Parameters:** `implementation`
**Why This Matters:** Critical contract change, affects all users
**Off-chain Indexing:** Track upgrade history, verify implementations
**Governance:** Should require timelock in production

---

## Event Best Practices

### 1. Use Indexed Parameters Wisely

```solidity
// GOOD: Index addresses and important identifiers
event Transfer(address indexed from, address indexed to, uint256 value);

// BAD: Indexing large data (arrays, strings)
event BadEvent(string indexed data); // Hashes string, can't filter effectively

// Maximum 3 indexed parameters per event
```

### 2. Include Timestamp for Time-Series Data

```solidity
event Deposit(
    address indexed user,
    uint256 amount,
    uint256 timestamp  // Include for analytics
);
```

### 3. Emit Before External Calls

```solidity
// GOOD: Emit before external call
emit Withdrawal(msg.sender, amount, block.timestamp);
(bool success, ) = msg.sender.call{value: amount}("");

// BAD: Emit after external call (reentrancy risk)
(bool success, ) = msg.sender.call{value: amount}("");
emit Withdrawal(msg.sender, amount, block.timestamp);
```

### 4. Include Context in Events

```solidity
// GOOD: Include relevant context
event Swap(
    address indexed user,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 fee,         // Include fee information
    uint256 timestamp    // Include time
);

// BAD: Missing context
event Swap(address user, uint256 amount);
```

### 5. Use Descriptive Event Names

```solidity
// GOOD: Clear, specific names
event RewardClaimed(address indexed user, uint256 amount);
event ParameterUpdated(bytes32 indexed param, uint256 oldValue, uint256 newValue);

// BAD: Generic names
event Action(address user, uint256 data);
event Updated(uint256 value);
```

---

## Gas Cost Reference

| Event Component | Gas Cost |
|----------------|----------|
| Base event | ~375 gas |
| Non-indexed topic | ~375 gas |
| Indexed topic | ~750 gas |
| Data word (32 bytes) | ~8 gas |

**Example:**
```solidity
// Cost: 375 (base) + 750*2 (indexed) + 8 (data) = 1,883 gas
event Transfer(address indexed from, address indexed to, uint256 value);
```

---

## Off-Chain Indexing Examples

### Using Ethers.js

```javascript
// Filter Transfer events for specific address
const filter = contract.filters.Transfer(userAddress, null);
const events = await contract.queryFilter(filter, fromBlock, toBlock);

// Listen for new events
contract.on("Transfer", (from, to, amount, event) => {
    console.log(`Transfer: ${from} -> ${to}: ${amount}`);
});
```

### Using The Graph

```graphql
# Query events
{
  transfers(where: { from: "0x..." }) {
    from
    to
    value
    timestamp
  }
}
```

---

**Total Event Templates:** 25+
**Categories:** 6
**All events include:** Proper indexing, documentation, usage examples
**Solidity Version:** ^0.8.20
