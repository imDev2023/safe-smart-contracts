# Solidity Design Pattern Catalog

Essential design patterns for secure and efficient smart contract development.

**Source:** fravoll/solidity-patterns + OpenZeppelin implementations
**Last Updated:** November 15, 2025

---

## Top 10 Essential Patterns

### 1. Checks-Effects-Interactions

**Category:** Security
**When to use:** Every function that makes external calls, especially those transferring value

**Problem it solves:** Prevents reentrancy attacks by ensuring state changes happen before external interactions.

**Code Template:**
```solidity
function withdraw(uint256 amount) external nonReentrant {
    // 1. CHECKS - Validate conditions
    require(balances[msg.sender] >= amount, "Insufficient balance");
    require(amount > 0, "Invalid amount");

    // 2. EFFECTS - Update state
    balances[msg.sender] -= amount;
    emit Withdrawal(msg.sender, amount);

    // 3. INTERACTIONS - External calls last
    (bool success,) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

**OZ Implementation:**
- Pattern enforced in all OZ contracts
- Use with `ReentrancyGuard` for extra safety

**Gas Cost:** No overhead (pattern, not code)

**Related Patterns:** Pull over Push, ReentrancyGuard

---

### 2. Access Restriction

**Category:** Security
**When to use:** Any privileged function that should only be callable by authorized addresses

**Problem it solves:** Prevents unauthorized users from executing admin or sensitive functions.

**Code Template:**
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    uint256 public value;

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Single owner restriction
    function setValue(uint256 newValue) external onlyOwner {
        value = newValue;
    }
}

// For multi-role systems
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MultiRole is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
```

**OZ Implementation:**
- `Ownable` - Single owner (400 gas per check)
- `Ownable2Step` - Safer ownership transfer
- `AccessControl` - Role-based access (2-3k gas per check)
- `AccessManager` - Centralized management

**Gas Cost:**
- Ownable: ~400 gas per check
- AccessControl: ~2,000-3,000 gas per check

**Related Patterns:** Guard Check, State Machine

---

### 3. Pull over Push

**Category:** Security
**When to use:** Distributing payments to multiple recipients or handling user withdrawals

**Problem it solves:** Prevents DoS attacks where one failed payment blocks all others.

**Code Template:**
```solidity
import "@openzeppelin/contracts/security/PullPayment.sol";

contract Auction is PullPayment {
    address public highestBidder;
    uint256 public highestBid;

    function bid() external payable {
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            // Don't push payment - record it for pulling
            _asyncTransfer(highestBidder, highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // Users call this to withdraw their refunds
    function withdrawPayments(address payable payee) public virtual override {
        super.withdrawPayments(payee);
    }
}

// Or implement manually
contract ManualPull {
    mapping(address => uint256) public pendingWithdrawals;

    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}
```

**OZ Implementation:**
- `PullPayment` contract with `_asyncTransfer()`
- Escrow pattern

**Gas Cost:** Higher per transaction (user pays withdrawal gas), but safer

**Related Patterns:** Checks-Effects-Interactions

---

### 4. Emergency Stop (Circuit Breaker)

**Category:** Security
**When to use:** Contracts handling value or having critical functions that might need emergency shutdown

**Problem it solves:** Provides ability to pause contract in case of discovered vulnerability or attack.

**Code Template:**
```solidity
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmergencyStop is Pausable, Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function deposit() external payable whenNotPaused {
        // Normal operation only when not paused
    }

    function withdraw(uint256 amount) external whenNotPaused {
        // Normal operation only when not paused
    }

    function emergencyWithdraw() external whenPaused {
        // Special recovery function only when paused
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
```

**OZ Implementation:**
- `Pausable` with `whenNotPaused` and `whenPaused` modifiers
- Emits `Paused` and `Unpaused` events

**Gas Cost:** ~300 gas per pause check (very cheap)

**Related Patterns:** Access Restriction

---

### 5. Guard Check

**Category:** Behavioral
**When to use:** Validating inputs, checking prerequisites, verifying state before execution

**Problem it solves:** Ensures contract behaves correctly by validating all assumptions before execution.

**Code Template:**
```solidity
contract GuardCheck {
    enum State { Pending, Active, Completed }
    State public state;
    address public owner;

    function execute(uint256 value, address recipient) external {
        // Input validation
        require(msg.sender == owner, "Not owner");
        require(recipient != address(0), "Invalid recipient");
        require(value > 0, "Value must be positive");
        require(value <= address(this).balance, "Insufficient balance");

        // State validation
        require(state == State.Active, "Not in active state");

        // Invariant checks (use assert for critical invariants)
        assert(totalSupply >= balances[recipient]);

        // Execute logic...
    }

    // Modern approach: Custom errors (saves gas)
    error InvalidRecipient();
    error InsufficientBalance();

    function modernExecute(uint256 value, address recipient) external {
        if (recipient == address(0)) revert InvalidRecipient();
        if (value > address(this).balance) revert InsufficientBalance();
        // Execute logic...
    }
}
```

**OZ Implementation:**
- Used throughout all OZ contracts
- Custom errors since Solidity 0.8.4

**Gas Cost:**
- `require()`: ~50 gas + string storage
- Custom errors: ~100 gas total (much cheaper)

**Related Patterns:** Access Restriction, State Machine

---

### 6. State Machine

**Category:** Behavioral
**When to use:** Contracts with distinct lifecycle stages (crowdfunding, auctions, governance)

**Problem it solves:** Manages contract lifecycle by restricting functions to specific stages.

**Code Template:**
```solidity
contract Crowdsale {
    enum Stage { Pending, Active, Ended, Finalized }
    Stage public stage = Stage.Pending;
    uint256 public endTime;

    modifier atStage(Stage required) {
        require(stage == required, "Invalid stage");
        _;
    }

    modifier timedTransitions() {
        if (stage == Stage.Active && block.timestamp >= endTime) {
            stage = Stage.Ended;
        }
        _;
    }

    function start() external atStage(Stage.Pending) {
        stage = Stage.Active;
        endTime = block.timestamp + 30 days;
    }

    function contribute() external payable atStage(Stage.Active) timedTransitions {
        // Accept contributions
    }

    function finalize() external atStage(Stage.Ended) {
        stage = Stage.Finalized;
        // Distribute funds
    }
}
```

**OZ Implementation:**
- Not directly implemented, but pattern used in Governor contracts
- Combine with `Ownable` or `AccessControl`

**Gas Cost:** ~200 gas per stage check

**Related Patterns:** Access Restriction, Guard Check

---

### 7. Proxy Delegate (Upgradeability)

**Category:** Upgradeability
**When to use:** Need to upgrade contract logic after deployment while preserving state and address

**Problem it solves:** Allows bug fixes and feature additions without redeployment or migration.

**Code Template:**
```solidity
// Using OpenZeppelin's UUPS pattern
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyContractV1 is UUPSUpgradeable, OwnableUpgradeable {
    uint256 public value;

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function setValue(uint256 newValue) external onlyOwner {
        value = newValue;
    }

    // Required for UUPS
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// Deploy proxy
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

ERC1967Proxy proxy = new ERC1967Proxy(
    address(implementation),
    abi.encodeCall(MyContractV1.initialize, (owner))
);
```

**OZ Implementation:**
- `ERC1967Proxy` - Standard proxy
- `TransparentUpgradeableProxy` - Separates admin/user
- `UUPSUpgradeable` - Upgrade logic in implementation
- `BeaconProxy` - Multiple proxies, one implementation

**Gas Cost:**
- Extra ~2,500 gas per call (delegatecall overhead)
- Deployment: Similar to regular contract

**Related Patterns:** Eternal Storage

---

### 8. Tight Variable Packing

**Category:** Economic (Gas Optimization)
**When to use:** Contracts with multiple state variables, especially structs

**Problem it solves:** Reduces storage costs by packing multiple variables into single 32-byte slots.

**Code Template:**
```solidity
// ❌ BAD: Each variable uses full slot
contract Unpacked {
    uint8 a;   // Slot 0 (wastes 31 bytes)
    uint8 b;   // Slot 1 (wastes 31 bytes)
    uint128 c; // Slot 2 (wastes 16 bytes)
    uint128 d; // Slot 3 (wastes 16 bytes)
    // Total: 4 slots = 80,000 gas
}

// ✅ GOOD: Packed into minimal slots
contract Packed {
    uint128 c; // Slot 0 (first 16 bytes)
    uint128 d; // Slot 0 (last 16 bytes)
    uint8 a;   // Slot 1 (first byte)
    uint8 b;   // Slot 1 (second byte)
    // Total: 2 slots = 40,000 gas (50% savings)
}

// Struct packing
struct User {
    address addr;      // 20 bytes - Slot 0
    uint64 lastActive; // 8 bytes  - Slot 0
    uint32 id;         // 4 bytes  - Slot 0
    // Total: 32 bytes = 1 slot!
}
```

**OZ Implementation:**
- All OZ contracts use optimal packing
- Check storage layout with Hardhat or Foundry

**Gas Cost:**
- Savings: ~20,000 gas per slot saved on first write
- ~5,000 gas per slot saved on updates
- ~64% savings possible with good packing

**Related Patterns:** Memory Array Building

---

### 9. ReentrancyGuard

**Category:** Security
**When to use:** Any function making external calls, especially involving value transfer

**Problem it solves:** Prevents reentrancy attacks through mutex locking mechanism.

**Code Template:**
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }

    // Also protects cross-function reentrancy
    function transfer(address to, uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    // Even view functions can be protected
    function getBalance() external view nonReentrantView returns (uint256) {
        return balances[msg.sender];
    }
}
```

**OZ Implementation:**
- `ReentrancyGuard` contract
- `nonReentrant` modifier for state-changing functions
- `nonReentrantView` for view functions

**Gas Cost:**
- First call: ~20,000 gas (cold storage)
- Subsequent calls: ~2,400 gas (warm storage)

**Related Patterns:** Checks-Effects-Interactions, Pull over Push

---

### 10. Safe ERC20 Operations

**Category:** Security
**When to use:** Any interaction with external ERC20 tokens

**Problem it solves:** Handles non-standard ERC20 tokens that don't return booleans or revert properly.

**Code Template:**
```solidity
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVault {
    using SafeERC20 for IERC20;

    // ❌ UNSAFE: Doesn't handle non-standard tokens
    function unsafeDeposit(IERC20 token, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        // Might silently fail with some tokens!
    }

    // ✅ SAFE: Handles all token types
    function safeDeposit(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        // Reverts if transfer fails
    }

    function safeWithdraw(IERC20 token, uint256 amount) external {
        token.safeTransfer(msg.sender, amount);
    }

    function safeApprove(IERC20 token, address spender, uint256 amount) external {
        token.safeApprove(spender, amount);
        // Or use forceApprove to handle tokens requiring 0 first
        token.forceApprove(spender, amount);
    }
}
```

**OZ Implementation:**
- `SafeERC20` library
- Methods: `safeTransfer`, `safeTransferFrom`, `safeApprove`, `forceApprove`, `safeIncreaseAllowance`, `safeDecreaseAllowance`

**Gas Cost:**
- Minimal overhead (~500 gas)
- Essential for security with external tokens

**Related Patterns:** Guard Check

---

## Pattern Selection Matrix

### By Use Case

| Need | Recommended Patterns | Priority |
|------|---------------------|----------|
| **Prevent reentrancy** | ReentrancyGuard + Checks-Effects-Interactions | CRITICAL |
| **Admin functions** | Access Restriction (Ownable/AccessControl) | CRITICAL |
| **Handle payments** | Pull over Push + Checks-Effects-Interactions | HIGH |
| **Emergency control** | Emergency Stop (Pausable) | HIGH |
| **External tokens** | Safe ERC20 Operations | CRITICAL |
| **Input validation** | Guard Check | HIGH |
| **Lifecycle management** | State Machine | MEDIUM |
| **Upgradeability** | Proxy Delegate (UUPS/Transparent) | MEDIUM |
| **Gas optimization** | Tight Variable Packing | LOW |
| **Contract stages** | State Machine + Access Restriction | MEDIUM |

### By Complexity

| Level | Patterns |
|-------|----------|
| **Beginner** | Guard Check, Access Restriction (Ownable), Safe ERC20 |
| **Intermediate** | Emergency Stop, Pull over Push, State Machine, Tight Packing |
| **Advanced** | Proxy Delegate, ReentrancyGuard (understanding internals), Cross-contract patterns |

### By Gas Impact

| Impact | Patterns | Effect |
|--------|----------|--------|
| **Reduces Gas** | Tight Variable Packing (-50%+ storage) | POSITIVE |
| **Minimal Overhead** | Guard Check (~100 gas), Emergency Stop (~300 gas), ReentrancyGuard (~2.4k gas) | NEUTRAL |
| **Increases Gas** | Pull over Push (users pay withdrawal), Proxy (~2.5k per call) | ACCEPTABLE |

---

## Combining Patterns

### Pattern 1: Secure Token Vault
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SecureVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount)
        external
        nonReentrant
        whenNotPaused
    {
        token.safeTransferFrom(msg.sender, address(this), amount);
    }
}
// Combines: Access Restriction, Emergency Stop, ReentrancyGuard, Safe ERC20
```

### Pattern 2: Staged Crowdsale
```solidity
contract Crowdsale is Ownable, ReentrancyGuard {
    enum Stage { Pending, Active, Ended }
    Stage public stage;

    modifier atStage(Stage required) {
        require(stage == required);
        _;
    }

    function contribute()
        external
        payable
        nonReentrant
        atStage(Stage.Active)
    {
        // Process contribution
    }
}
// Combines: State Machine, Access Restriction, ReentrancyGuard
```

---

## Anti-Patterns to Avoid

### ❌ Don't Do This

```solidity
// DON'T: External call before state update
function withdraw() external {
    (bool s,) = msg.sender.call{value: balance}("");
    balance = 0; // Too late!
}

// DON'T: Missing access control
function setOwner(address newOwner) external {
    owner = newOwner; // Anyone can call!
}

// DON'T: Unsafe token transfer
function withdrawToken(IERC20 token) external {
    token.transfer(msg.sender, amount); // Might fail silently
}

// DON'T: Unbounded loop
function payAll() external {
    for (uint i = 0; i < users.length; i++) { // Gas bomb
        users[i].transfer(amount);
    }
}
```

---

## Testing Patterns

```solidity
// Foundry test example
function testReentrancyProtection() public {
    vm.expectRevert("ReentrancyGuard: reentrant call");
    attacker.attack();
}

function testAccessControl() public {
    vm.prank(user);
    vm.expectRevert("Ownable: caller is not the owner");
    contract.adminFunction();
}

function testPauseUnpause() public {
    contract.pause();
    vm.expectRevert("Pausable: paused");
    contract.someFunction();
}
```

---

## Quick Reference Summary

**Always Use:**
1. `ReentrancyGuard` for external calls
2. `Ownable`/`AccessControl` for privileged functions
3. `SafeERC20` for token interactions
4. Checks-Effects-Interactions pattern

**Consider Using:**
5. `Pausable` for emergency stops
6. Pull over Push for payments
7. State Machine for lifecycle management
8. Tight Packing for gas optimization

**Advanced:**
9. Proxy patterns for upgradeability
10. Custom patterns for specific needs

---

## Resources

- **Pattern Repository**: https://fravoll.github.io/solidity-patterns/
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Smart Contract Security**: https://consensys.github.io/smart-contract-best-practices/

---

**Remember:** Patterns are tools, not rules. Understand the trade-offs and apply them appropriately to your specific use case.
