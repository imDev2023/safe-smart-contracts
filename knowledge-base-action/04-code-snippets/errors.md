# Custom Error Definitions Reference

Gas-efficient custom errors instead of require strings. Available in Solidity 0.8.4+, significantly cheaper than string errors.

---

## Why Custom Errors?

**Gas Savings:**
- String error: `require(condition, "Error message")` → ~50-100 gas + string length
- Custom error: `if (!condition) revert CustomError()` → ~24 gas

**Example:**
```solidity
// EXPENSIVE: ~100 gas
require(msg.sender == owner, "Caller is not the owner");

// CHEAP: ~24 gas
error NotOwner();
if (msg.sender != owner) revert NotOwner();
```

---

## 1. Access Control Errors

### InvalidCaller - Wrong Caller Address

```solidity
/**
 * @dev Caller is not authorized to perform this action
 * @param caller Address of the unauthorized caller
 */
error InvalidCaller(address caller);

// Usage
function restrictedFunction() public {
    if (!isAuthorized(msg.sender)) {
        revert InvalidCaller(msg.sender);
    }
    // Function logic
}
```

**Parameters:** `caller` - provides context about who tried to call
**Gas Savings:** ~50 gas vs string error
**When to Use:** When you need to know who made the invalid call

---

### Unauthorized - Generic Access Denial

```solidity
/**
 * @dev Caller lacks required authorization
 */
error Unauthorized();

// Usage
function adminOnly() public {
    if (msg.sender != admin) {
        revert Unauthorized();
    }
    // Function logic
}
```

**Parameters:** None (simplest form)
**Gas Savings:** ~80 gas vs string error
**When to Use:** Simple unauthorized access, no context needed

---

### InsufficientPermission - Missing Required Role

```solidity
/**
 * @dev Caller lacks required permission level
 * @param required Required permission level
 * @param actual Actual permission level of caller
 */
error InsufficientPermission(uint256 required, uint256 actual);

// Usage
function tieredAccess() public {
    uint256 required = 5;
    uint256 actual = userLevel[msg.sender];
    if (actual < required) {
        revert InsufficientPermission(required, actual);
    }
}
```

**Parameters:** `required`, `actual` - shows permission gap
**Gas Savings:** ~40 gas vs string error
**When to Use:** Tiered permission systems

---

### NotOwner - Owner-Only Function

```solidity
/**
 * @dev Caller is not the contract owner
 */
error NotOwner();

// Usage
function ownerOnly() public {
    if (msg.sender != owner) {
        revert NotOwner();
    }
    // Function logic
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs `require(msg.sender == owner, "Not owner")`
**When to Use:** Most common access control pattern

---

### NotAdmin - Admin-Only Function

```solidity
/**
 * @dev Caller is not an administrator
 */
error NotAdmin();

// Usage with role check
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

function adminFunction() public {
    if (!hasRole(ADMIN_ROLE, msg.sender)) {
        revert NotAdmin();
    }
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Admin-specific functions

---

### UnauthorizedRole - Missing Specific Role

```solidity
/**
 * @dev Caller lacks required role
 * @param role Required role identifier
 * @param account Address attempting access
 */
error UnauthorizedRole(bytes32 role, address account);

// Usage
function roleProtected(bytes32 requiredRole) public {
    if (!hasRole(requiredRole, msg.sender)) {
        revert UnauthorizedRole(requiredRole, msg.sender);
    }
}
```

**Parameters:** `role`, `account` - full context for debugging
**Gas Savings:** ~40 gas vs string error
**When to Use:** Role-based access control systems

---

## 2. Validation Errors

### ZeroAddress - Invalid Zero Address

```solidity
/**
 * @dev Address cannot be zero address
 */
error ZeroAddress();

// Usage
function setRecipient(address recipient) public {
    if (recipient == address(0)) {
        revert ZeroAddress();
    }
    _recipient = recipient;
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs `require(addr != address(0), "Zero address")`
**When to Use:** Most common validation, always check important addresses

---

### ZeroAmount - Invalid Zero Value

```solidity
/**
 * @dev Amount cannot be zero
 */
error ZeroAmount();

// Usage
function deposit(uint256 amount) public payable {
    if (amount == 0) {
        revert ZeroAmount();
    }
    balances[msg.sender] += amount;
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Prevent meaningless zero-value operations

---

### InvalidAmount - Amount Out of Bounds

```solidity
/**
 * @dev Amount is invalid or out of allowed range
 * @param amount Provided amount
 * @param min Minimum allowed amount
 * @param max Maximum allowed amount
 */
error InvalidAmount(uint256 amount, uint256 min, uint256 max);

// Usage
function mint(uint256 amount) public {
    uint256 min = 1;
    uint256 max = 1000000;
    if (amount < min || amount > max) {
        revert InvalidAmount(amount, min, max);
    }
}
```

**Parameters:** `amount`, `min`, `max` - shows valid range
**Gas Savings:** ~30 gas vs string error
**When to Use:** Range validation with context

---

### InvalidParameter - Generic Parameter Error

```solidity
/**
 * @dev Function parameter is invalid
 * @param parameter Name of invalid parameter
 */
error InvalidParameter(string parameter);

// Usage
function configure(uint256 feeRate, uint256 minStake) public {
    if (feeRate > 10000) {
        revert InvalidParameter("feeRate");
    }
    if (minStake == 0) {
        revert InvalidParameter("minStake");
    }
}
```

**Parameters:** `parameter` - identifies which parameter failed
**Gas Savings:** ~40 gas vs string error (still uses string but cheaper)
**When to Use:** Multiple parameter validation in one function

---

### ValueTooLarge - Exceeds Maximum

```solidity
/**
 * @dev Value exceeds maximum allowed
 * @param value Provided value
 * @param max Maximum allowed value
 */
error ValueTooLarge(uint256 value, uint256 max);

// Usage
uint256 public constant MAX_SUPPLY = 1000000 * 10**18;

function mint(uint256 amount) public {
    if (totalSupply + amount > MAX_SUPPLY) {
        revert ValueTooLarge(totalSupply + amount, MAX_SUPPLY);
    }
}
```

**Parameters:** `value`, `max` - shows limit exceeded
**Gas Savings:** ~40 gas vs string error
**When to Use:** Cap enforcement, limit checking

---

### ValueTooSmall - Below Minimum

```solidity
/**
 * @dev Value is below minimum required
 * @param value Provided value
 * @param min Minimum required value
 */
error ValueTooSmall(uint256 value, uint256 min);

// Usage
uint256 public constant MIN_STAKE = 0.1 ether;

function stake() public payable {
    if (msg.value < MIN_STAKE) {
        revert ValueTooSmall(msg.value, MIN_STAKE);
    }
}
```

**Parameters:** `value`, `min` - shows minimum requirement
**Gas Savings:** ~40 gas vs string error
**When to Use:** Minimum value enforcement

---

### ArrayLengthMismatch - Mismatched Array Sizes

```solidity
/**
 * @dev Array lengths do not match
 * @param length1 Length of first array
 * @param length2 Length of second array
 */
error ArrayLengthMismatch(uint256 length1, uint256 length2);

// Usage
function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
    if (recipients.length != amounts.length) {
        revert ArrayLengthMismatch(recipients.length, amounts.length);
    }
}
```

**Parameters:** `length1`, `length2` - shows size mismatch
**Gas Savings:** ~40 gas vs string error
**When to Use:** Batch operations with multiple arrays

---

## 3. State Errors

### InvalidState - Wrong Contract State

```solidity
/**
 * @dev Contract is in invalid state for this operation
 * @param current Current state
 * @param required Required state
 */
error InvalidState(State current, State required);

// State enum
enum State { Pending, Active, Paused, Completed }

// Usage
function execute() public {
    if (currentState != State.Active) {
        revert InvalidState(currentState, State.Active);
    }
}
```

**Parameters:** `current`, `required` - shows state mismatch
**Gas Savings:** ~40 gas vs string error
**When to Use:** State machine patterns

---

### AlreadyInitialized - Double Initialization

```solidity
/**
 * @dev Contract has already been initialized
 */
error AlreadyInitialized();

// Usage
bool private _initialized;

function initialize(address owner) public {
    if (_initialized) {
        revert AlreadyInitialized();
    }
    _initialized = true;
    _owner = owner;
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Initialization guards, upgradeable contracts

---

### NotInitialized - Missing Initialization

```solidity
/**
 * @dev Contract has not been initialized
 */
error NotInitialized();

// Usage
function operate() public {
    if (!_initialized) {
        revert NotInitialized();
    }
    // Operation logic
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Ensure initialization before operations

---

### ContractPaused - Operations Suspended

```solidity
/**
 * @dev Contract is currently paused
 */
error ContractPaused();

// Usage
bool private _paused;

function trade() public {
    if (_paused) {
        revert ContractPaused();
    }
    // Trading logic
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs `require(!paused, "Contract is paused")`
**When to Use:** Pausable contracts, circuit breakers

---

### ContractNotPaused - Expected Pause State

```solidity
/**
 * @dev Contract must be paused for this operation
 */
error ContractNotPaused();

// Usage
function emergencyWithdraw() public {
    if (!_paused) {
        revert ContractNotPaused();
    }
    // Emergency withdrawal
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Operations that require paused state

---

## 4. Math Errors

### Overflow - Arithmetic Overflow

```solidity
/**
 * @dev Arithmetic overflow detected
 * @param value Value that would overflow
 * @param max Maximum safe value
 */
error Overflow(uint256 value, uint256 max);

// Usage (if using unchecked blocks)
function add(uint256 a, uint256 b) public pure returns (uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) {
            revert Overflow(c, type(uint256).max);
        }
        return c;
    }
}
```

**Parameters:** `value`, `max` - overflow context
**Gas Savings:** ~40 gas vs string error
**When to Use:** Custom math operations in unchecked blocks
**Note:** Solidity 0.8+ has built-in overflow protection

---

### Underflow - Arithmetic Underflow

```solidity
/**
 * @dev Arithmetic underflow detected
 * @param value Value that would underflow
 */
error Underflow(uint256 value);

// Usage (if using unchecked blocks)
function subtract(uint256 a, uint256 b) public pure returns (uint256) {
    if (b > a) {
        revert Underflow(a);
    }
    return a - b;
}
```

**Parameters:** `value` - underflow context
**Gas Savings:** ~50 gas vs string error
**When to Use:** Manual underflow checks

---

### DivideByZero - Division by Zero

```solidity
/**
 * @dev Attempted division by zero
 */
error DivideByZero();

// Usage
function divide(uint256 a, uint256 b) public pure returns (uint256) {
    if (b == 0) {
        revert DivideByZero();
    }
    return a / b;
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Division operations
**Note:** Solidity reverts automatically on division by zero

---

## 5. Interaction Errors

### TransferFailed - Token Transfer Failed

```solidity
/**
 * @dev Token transfer failed
 * @param token Token address
 * @param from Sender address
 * @param to Recipient address
 * @param amount Transfer amount
 */
error TransferFailed(address token, address from, address to, uint256 amount);

// Usage
function safeTransfer(address token, address to, uint256 amount) internal {
    (bool success, ) = token.call(
        abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
    );
    if (!success) {
        revert TransferFailed(token, address(this), to, amount);
    }
}
```

**Parameters:** Full transfer context for debugging
**Gas Savings:** ~25 gas vs string error
**When to Use:** Token transfer operations

---

### CallFailed - External Call Failed

```solidity
/**
 * @dev External call failed
 * @param target Target contract address
 * @param data Call data
 */
error CallFailed(address target, bytes data);

// Usage
function externalCall(address target, bytes memory data) public {
    (bool success, ) = target.call(data);
    if (!success) {
        revert CallFailed(target, data);
    }
}
```

**Parameters:** `target`, `data` - call context
**Gas Savings:** ~30 gas vs string error
**When to Use:** Generic external calls

---

### InsufficientBalance - Not Enough Funds

```solidity
/**
 * @dev Insufficient balance for operation
 * @param available Available balance
 * @param required Required balance
 */
error InsufficientBalance(uint256 available, uint256 required);

// Usage
function withdraw(uint256 amount) public {
    uint256 balance = balances[msg.sender];
    if (balance < amount) {
        revert InsufficientBalance(balance, amount);
    }
    balances[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
}
```

**Parameters:** `available`, `required` - balance context
**Gas Savings:** ~40 gas vs string error
**When to Use:** Balance checks, withdrawal operations

---

### InsufficientAllowance - Not Enough Approval

```solidity
/**
 * @dev Insufficient allowance for transfer
 * @param available Current allowance
 * @param required Required allowance
 */
error InsufficientAllowance(uint256 available, uint256 required);

// Usage
function transferFrom(address from, address to, uint256 amount) public {
    uint256 currentAllowance = allowances[from][msg.sender];
    if (currentAllowance < amount) {
        revert InsufficientAllowance(currentAllowance, amount);
    }
    allowances[from][msg.sender] -= amount;
    // Transfer logic
}
```

**Parameters:** `available`, `required` - allowance context
**Gas Savings:** ~40 gas vs string error
**When to Use:** ERC20 transferFrom operations

---

## 6. Time-Based Errors

### TooEarly - Before Allowed Time

```solidity
/**
 * @dev Action attempted too early
 * @param current Current timestamp
 * @param required Required timestamp
 */
error TooEarly(uint256 current, uint256 required);

// Usage
uint256 public saleStartTime;

function buy() public payable {
    if (block.timestamp < saleStartTime) {
        revert TooEarly(block.timestamp, saleStartTime);
    }
}
```

**Parameters:** `current`, `required` - timing context
**Gas Savings:** ~40 gas vs string error
**When to Use:** Timelock, vesting, sale schedules

---

### TooLate - After Deadline

```solidity
/**
 * @dev Action attempted after deadline
 * @param current Current timestamp
 * @param deadline Deadline timestamp
 */
error TooLate(uint256 current, uint256 deadline);

// Usage
uint256 public saleEndTime;

function buy() public payable {
    if (block.timestamp >= saleEndTime) {
        revert TooLate(block.timestamp, saleEndTime);
    }
}
```

**Parameters:** `current`, `deadline` - timing context
**Gas Savings:** ~40 gas vs string error
**When to Use:** Deadlines, limited-time operations

---

### DeadlineExpired - Specific Deadline Passed

```solidity
/**
 * @dev Operation deadline has expired
 * @param deadline Expired deadline
 */
error DeadlineExpired(uint256 deadline);

// Usage
function executeWithDeadline(bytes memory data, uint256 deadline) public {
    if (block.timestamp > deadline) {
        revert DeadlineExpired(deadline);
    }
}
```

**Parameters:** `deadline` - expired deadline
**Gas Savings:** ~50 gas vs string error
**When to Use:** Time-sensitive operations

---

## 7. Reentrancy Errors

### ReentrancyGuardReentrantCall - Reentrancy Detected

```solidity
/**
 * @dev Reentrant call detected
 */
error ReentrancyGuardReentrantCall();

// Usage
uint256 private constant NOT_ENTERED = 1;
uint256 private constant ENTERED = 2;
uint256 private _status = NOT_ENTERED;

modifier nonReentrant() {
    if (_status == ENTERED) {
        revert ReentrancyGuardReentrantCall();
    }
    _status = ENTERED;
    _;
    _status = NOT_ENTERED;
}
```

**Parameters:** None
**Gas Savings:** ~80 gas vs string error
**When to Use:** Reentrancy protection (always use for external calls)

---

## Error Patterns & Best Practices

### Pattern 1: Simple Error (No Parameters)

```solidity
// Use when no context needed
error Unauthorized();
error ZeroAddress();
error AlreadyInitialized();

// Cheapest option: ~24 gas to revert
```

### Pattern 2: Error with Context (With Parameters)

```solidity
// Use when debugging context valuable
error InsufficientBalance(uint256 available, uint256 required);
error InvalidState(State current, State required);
error UnauthorizedRole(bytes32 role, address account);

// Slightly more expensive but provides valuable debugging info
```

### Pattern 3: Detailed Error (Multiple Parameters)

```solidity
// Use for complex operations requiring full context
error TransferFailed(address token, address from, address to, uint256 amount);

// Most expensive but provides complete debugging information
```

---

## Gas Cost Comparison

| Error Type | Gas Cost | Example |
|-----------|----------|---------|
| No error (success) | 0 gas | - |
| Simple custom error | ~24 gas | `revert Unauthorized()` |
| Custom error with params | ~24 + params | `revert InsufficientBalance(100, 200)` |
| String error (short) | ~50-100 gas | `require(false, "Error")` |
| String error (long) | ~100-200 gas | `require(false, "Long error message")` |

---

## Migration Guide

### Before (String Errors)

```solidity
require(msg.sender == owner, "Caller is not the owner");
require(amount > 0, "Amount must be greater than zero");
require(balance >= amount, "Insufficient balance");
```

### After (Custom Errors)

```solidity
error NotOwner();
error ZeroAmount();
error InsufficientBalance(uint256 available, uint256 required);

if (msg.sender != owner) revert NotOwner();
if (amount == 0) revert ZeroAmount();
if (balance < amount) revert InsufficientBalance(balance, amount);
```

**Gas Savings:** ~50-80 gas per revert

---

## Complete Example Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VaultWithCustomErrors {
    // Custom errors
    error NotOwner();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance(uint256 available, uint256 required);
    error TransferFailed();
    error ContractPaused();

    address public owner;
    bool public paused;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        if (msg.value == 0) revert ZeroAmount();
        if (paused) revert ContractPaused();

        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        if (amount == 0) revert ZeroAmount();
        if (paused) revert ContractPaused();
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function setOwner(address newOwner) public {
        if (msg.sender != owner) revert NotOwner();
        if (newOwner == address(0)) revert ZeroAddress();

        owner = newOwner;
    }

    function pause() public {
        if (msg.sender != owner) revert NotOwner();
        paused = true;
    }
}
```

---

**Total Error Definitions:** 30+
**Categories:** 7
**Average Gas Savings:** 50-80 gas per error vs string
**Solidity Version:** ^0.8.4+
**Recommendation:** Use custom errors in all new contracts
