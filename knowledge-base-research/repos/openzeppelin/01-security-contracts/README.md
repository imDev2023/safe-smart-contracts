# Security Contracts

This directory documents OpenZeppelin's core security contracts and patterns that are essential for building secure smart contracts.

## Overview

Security contracts provide protection against common vulnerabilities and attack vectors in smart contract development. These are the most critical contracts for preventing exploits and managing access control.

## Core Security Contracts

### 1. ReentrancyGuard
**File**: `ReentrancyGuard.md`

Prevents reentrancy attacks - one of the most dangerous vulnerabilities in smart contracts. This attack occurs when an external call to an untrusted contract allows it to call back into the original function before the first execution completes.

**Key Features**:
- Simple `nonReentrant` modifier
- Minimal gas overhead
- Works with view functions via `nonReentrantView`
- Uses storage slots for compatibility with upgradeable contracts

**Use Cases**:
- Protecting withdraw/transfer functions
- Safeguarding any function making external calls
- DeFi protocols handling token transfers

### 2. AccessControl
**File**: `AccessControl.md`

Implements role-based access control (RBAC) for granular permission management. Allows defining multiple roles with different permissions.

**Key Features**:
- Define unlimited custom roles
- Hierarchical role administration
- Role granting and revoking
- Role enumeration support
- `DEFAULT_ADMIN_ROLE` for super-admin privileges

**Use Cases**:
- Multi-role permission systems (minter, burner, pauser)
- DAO governance structures
- Complex authorization schemes
- Separating concerns in large systems

### 3. Ownable
**File**: `Ownable.md`

Simple single-owner access control pattern. The most basic and commonly used access control mechanism.

**Key Features**:
- Single owner account
- `onlyOwner` modifier for protected functions
- Ownership transfer capability
- Ownership renunciation for decentralization
- `Ownable2Step` variant for safer transfers

**Use Cases**:
- Simple admin functions
- Quick prototyping
- Single-administrator contracts
- Foundation for more complex patterns

### 4. Pausable
**File**: `Pausable.md`

Emergency stop mechanism (circuit breaker pattern) that can halt contract operations in case of emergencies.

**Key Features**:
- `pause()` and `unpause()` functions
- `whenNotPaused` and `whenPaused` modifiers
- Events for pause state changes
- Lightweight implementation

**Use Cases**:
- Emergency response to exploits
- Controlled maintenance windows
- Risk mitigation during upgrades
- DeFi protocol safety mechanisms

### 5. SafeERC20
**File**: `SafeERC20.md`

Library providing safe wrappers around ERC20 operations. Handles non-standard ERC20 implementations that don't return boolean values or revert on failure.

**Key Features**:
- Safe transfer operations
- Handles missing return values
- Works with non-compliant tokens
- Prevents common token interaction pitfalls
- ERC-1363 integration support

**Use Cases**:
- Interacting with external tokens
- DeFi protocols handling multiple token types
- Safe allowance management
- Protection against malicious tokens

## Security Patterns Summary

| Contract | Primary Protection | Complexity | Gas Overhead | Common Use |
|----------|-------------------|------------|--------------|------------|
| ReentrancyGuard | Reentrancy attacks | Low | ~2.4k gas | External calls |
| AccessControl | Unauthorized access (multi-role) | Medium | ~2-5k gas | Complex permissions |
| Ownable | Unauthorized access (single admin) | Very Low | ~0.4k gas | Admin functions |
| Pausable | Emergency situations | Low | ~0.3k gas | Circuit breaker |
| SafeERC20 | Token interaction failures | Low | ~0.5k gas | Token operations |

## Combining Security Patterns

Security contracts are designed to work together. Common combinations:

### Pattern 1: Protected Token Contract
```solidity
contract MyToken is ERC20, Ownable, Pausable {
    function mint(address to, uint256 amount)
        public
        onlyOwner
        whenNotPaused
    {
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }
}
```

### Pattern 2: DeFi Vault with Multiple Protections
```solidity
contract Vault is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    function withdraw(uint256 amount)
        public
        onlyRole(WITHDRAWER_ROLE)
        nonReentrant
        whenNotPaused
    {
        // Safe withdrawal logic
    }
}
```

### Pattern 3: Upgradeable Contract with Access Control
```solidity
contract UpgradeableVault is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    function initialize() initializer public {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
```

## Security Best Practices

### 1. Defense in Depth
Layer multiple security mechanisms:
- Use `ReentrancyGuard` on functions making external calls
- Add `Pausable` for emergency stops
- Implement `AccessControl` or `Ownable` for admin functions
- Use `SafeERC20` for all token interactions

### 2. Checks-Effects-Interactions Pattern
Always follow this order:
1. **Checks**: Validate conditions and inputs
2. **Effects**: Update state variables
3. **Interactions**: Make external calls (with `nonReentrant`)

```solidity
function withdraw(uint256 amount) public nonReentrant {
    // 1. Checks
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // 2. Effects
    balances[msg.sender] -= amount;

    // 3. Interactions
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

### 3. Principle of Least Privilege
- Use `AccessControl` to grant only necessary permissions
- Separate roles for different operations
- Avoid giving `DEFAULT_ADMIN_ROLE` to multiple addresses
- Consider using `AccessControlDefaultAdminRules` for sensitive roles

### 4. Emergency Preparedness
- Implement `Pausable` in contracts handling value
- Plan for upgrade scenarios with proxy patterns
- Monitor events for suspicious activity
- Have incident response procedures

### 5. Safe Token Handling
- Always use `SafeERC20` library for token operations
- Never assume ERC20 tokens return boolean values
- Check token balances before and after transfers when necessary
- Be aware of fee-on-transfer and rebasing tokens

## Common Vulnerabilities Prevented

### Reentrancy Attack
**Prevention**: `ReentrancyGuard`
```solidity
// Vulnerable code
function withdraw() public {
    uint256 amount = balances[msg.sender];
    (bool success, ) = msg.sender.call{value: amount}("");
    balances[msg.sender] = 0; // Too late! Can be re-entered
}

// Protected code
function withdraw() public nonReentrant {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0; // Update state first
    (bool success, ) = msg.sender.call{value: amount}("");
}
```

### Unauthorized Access
**Prevention**: `Ownable` or `AccessControl`
```solidity
// Vulnerable code
function setPrice(uint256 newPrice) public {
    price = newPrice; // Anyone can call!
}

// Protected code
function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
}
```

### Token Transfer Failures
**Prevention**: `SafeERC20`
```solidity
// Vulnerable code
IERC20(token).transfer(to, amount); // Ignores return value

// Protected code
using SafeERC20 for IERC20;
IERC20(token).safeTransfer(to, amount); // Reverts on failure
```

## Testing Security Patterns

### Testing ReentrancyGuard
```javascript
it("should prevent reentrancy attacks", async function() {
    const attacker = await AttackerContract.deploy(vault.address);
    await expect(
        attacker.attack()
    ).to.be.revertedWithCustomError(vault, "ReentrancyGuardReentrantCall");
});
```

### Testing AccessControl
```javascript
it("should restrict function to role holders", async function() {
    await expect(
        contract.connect(user).restrictedFunction()
    ).to.be.revertedWithCustomError(contract, "AccessControlUnauthorizedAccount");

    await contract.grantRole(ROLE, user.address);
    await contract.connect(user).restrictedFunction(); // Now succeeds
});
```

### Testing Pausable
```javascript
it("should block operations when paused", async function() {
    await contract.pause();
    await expect(
        contract.protectedFunction()
    ).to.be.revertedWithCustomError(contract, "EnforcedPause");

    await contract.unpause();
    await contract.protectedFunction(); // Now succeeds
});
```

## Gas Considerations

### ReentrancyGuard
- First call: ~20,000 gas (cold storage access)
- Subsequent calls: ~2,400 gas (warm storage)
- Negligible overhead compared to external calls

### AccessControl
- Role check: ~2,000-3,000 gas
- Role grant/revoke: ~20,000-30,000 gas
- Worth the cost for complex permission systems

### Ownable
- Owner check: ~400 gas (reading owner address)
- Minimal overhead, use liberally

### Pausable
- Pause state check: ~300 gas
- Extremely cheap safety mechanism

## Migration & Upgrade Paths

### From Ownable to AccessControl
When you outgrow single-owner pattern:
```solidity
// Phase 1: Deploy new AccessControl version
// Phase 2: Grant DEFAULT_ADMIN_ROLE to old owner
// Phase 3: Set up granular roles
// Phase 4: Transfer ownership/remove admin as needed
```

### Adding ReentrancyGuard
Can be added to existing contracts:
```solidity
// Add inheritance
contract MyContract is MyBaseContract, ReentrancyGuard {
    // Add modifier to vulnerable functions
    function vulnerableFunction() public nonReentrant {
        // existing code
    }
}
```

## Resources

- [OpenZeppelin Access Control Guide](https://docs.openzeppelin.com/contracts/5.x/access-control)
- [Security Best Practices](https://docs.openzeppelin.com/contracts/5.x/learn/developing-smart-contracts)
- [API Documentation](https://docs.openzeppelin.com/contracts/5.x/api/security)
- [SWC Registry](https://swcregistry.io/) - Smart Contract Weakness Classification

## Next Steps

For detailed implementation guides, see individual contract documentation:
- [ReentrancyGuard.md](./ReentrancyGuard.md)
- [AccessControl.md](./AccessControl.md)
- [Ownable.md](./Ownable.md)
- [Pausable.md](./Pausable.md)
- [SafeERC20.md](./SafeERC20.md)
