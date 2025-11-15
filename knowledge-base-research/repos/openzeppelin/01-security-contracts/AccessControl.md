# AccessControl

## Overview

`AccessControl` implements Role-Based Access Control (RBAC), allowing you to define multiple roles with different permissions. It's the go-to solution for contracts needing granular permission management.

**Contract Path**: `@openzeppelin/contracts/access/AccessControl.sol`
**Version**: 5.x
**License**: MIT

## Core Concepts

### Roles as bytes32
Roles are identified by `bytes32` values, typically created using `keccak256`:

```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```

### Role Hierarchy
Every role has an admin role that can grant/revoke it:
- `DEFAULT_ADMIN_ROLE` (0x00) is the default admin for all roles
- Can create custom admin hierarchies

## Basic Usage

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("MyToken", "MTK") {
        // Grant DEFAULT_ADMIN_ROLE to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant MINTER_ROLE to deployer
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}
```

## Key Functions

### Checking Roles
```solidity
// Check if account has role
function hasRole(bytes32 role, address account) public view returns (bool)

// Modifier to restrict function access
modifier onlyRole(bytes32 role)
```

### Granting and Revoking
```solidity
// Grant role (must be called by role admin)
function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role))

// Revoke role (must be called by role admin)
function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role))

// Self-renounce role
function renounceRole(bytes32 role, address callerConfirmation) public
```

### Role Administration
```solidity
// Get admin role for a role
function getRoleAdmin(bytes32 role) public view returns (bytes32)

// Set admin role (internal function)
function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal
```

### Role Enumeration
```solidity
// Get number of accounts with role
function getRoleMemberCount(bytes32 role) public view returns (uint256)

// Get account at index
function getRoleMember(bytes32 role, uint256 index) public view returns (address)
```

## Advanced Patterns

### Multi-Role System
```solidity
contract DeFiProtocol is AccessControl {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateProtocolParams(uint256 newValue)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        // Governance-only function
    }

    function executeStrategy()
        external
        onlyRole(OPERATOR_ROLE)
    {
        // Operator-only function
    }

    function harvest()
        external
        onlyRole(KEEPER_ROLE)
    {
        // Keeper-only function
    }
}
```

### Custom Role Hierarchies
```solidity
contract HierarchicalAccess is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant EMPLOYEE_ROLE = keccak256("EMPLOYEE_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Set MANAGER_ROLE as admin of EMPLOYEE_ROLE
        _setRoleAdmin(EMPLOYEE_ROLE, MANAGER_ROLE);

        // Only managers can grant/revoke employee role
    }
}
```

### Multiple Roles Per Account
```solidity
// One account can have multiple roles
contract.grantRole(MINTER_ROLE, alice);
contract.grantRole(BURNER_ROLE, alice);
contract.grantRole(PAUSER_ROLE, alice);

// Alice can now mint, burn, and pause
```

## Security Considerations

### 1. DEFAULT_ADMIN_ROLE is Powerful
The `DEFAULT_ADMIN_ROLE` can grant/revoke ANY role:

```solidity
// Super admin has complete control
_grantRole(DEFAULT_ADMIN_ROLE, superAdmin);

// Can grant any role to anyone
grantRole(MINTER_ROLE, anyone);
grantRole(BURNER_ROLE, anyone);
```

**Mitigation**: Use `AccessControlDefaultAdminRules` for additional safety:
```solidity
import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract SafeContract is AccessControlDefaultAdminRules {
    constructor(address initialAdmin)
        AccessControlDefaultAdminRules(
            3 days,      // Transfer delay
            initialAdmin
        )
    {}
}
```

### 2. Role Admin Compromise
If a role admin is compromised, they can grant that role to attackers:

```solidity
// If MANAGER_ROLE is compromised
// Attacker can grant EMPLOYEE_ROLE to malicious addresses
contract.connect(compromisedManager).grantRole(EMPLOYEE_ROLE, attacker);
```

**Mitigation**:
- Use multisig for role admins
- Implement timelocks for role changes
- Monitor role grant/revoke events

### 3. Role Enumeration Gas Costs
Enumerating roles costs gas:

```solidity
// Expensive for many role members
for (uint256 i = 0; i < getRoleMemberCount(MINTER_ROLE); i++) {
    address minter = getRoleMember(MINTER_ROLE, i);
    // Process minter
}
```

**Best Practice**: Use off-chain indexing of `RoleGranted`/`RoleRevoked` events.

## Gas Costs

- **hasRole check**: ~2,000-3,000 gas
- **grantRole**: ~50,000 gas (first time), ~25,000 gas (subsequent)
- **revokeRole**: ~25,000 gas
- **Role enumeration**: Expensive, use events instead

## Testing

```javascript
describe("AccessControl", function() {
    let token, admin, minter, burner, user;

    beforeEach(async function() {
        [admin, minter, burner, user] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("MyToken");
        token = await Token.deploy();

        const MINTER_ROLE = await token.MINTER_ROLE();
        const BURNER_ROLE = await token.BURNER_ROLE();

        await token.grantRole(MINTER_ROLE, minter.address);
        await token.grantRole(BURNER_ROLE, burner.address);
    });

    it("should allow minter to mint", async function() {
        await token.connect(minter).mint(user.address, 1000);
        expect(await token.balanceOf(user.address)).to.equal(1000);
    });

    it("should prevent non-minter from minting", async function() {
        await expect(
            token.connect(user).mint(user.address, 1000)
        ).to.be.revertedWithCustomError(token, "AccessControlUnauthorizedAccount");
    });

    it("should allow admin to grant roles", async function() {
        await token.grantRole(await token.MINTER_ROLE(), user.address);
        expect(await token.hasRole(await token.MINTER_ROLE(), user.address)).to.be.true;
    });
});
```

## Comparison: AccessControl vs Ownable

| Feature | AccessControl | Ownable |
|---------|---------------|---------|
| Permission Model | Multi-role | Single owner |
| Gas Cost | ~2,000-3,000 gas | ~400 gas |
| Flexibility | High | Low |
| Complexity | Moderate | Very Simple |
| Role Enumeration | Yes | No |
| Hierarchical Roles | Yes | No |
| Use Case | Complex systems | Simple admin |

## Best Practices

1. **Use Descriptive Role Names**
   ```solidity
   bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
   bytes32 public constant PROTOCOL_PAUSER_ROLE = keccak256("PROTOCOL_PAUSER_ROLE");
   ```

2. **Grant DEFAULT_ADMIN_ROLE to Multisig**
   ```solidity
   constructor(address multisig) {
       _grantRole(DEFAULT_ADMIN_ROLE, multisig);
   }
   ```

3. **Document Role Capabilities**
   ```solidity
   /// @notice MINTER_ROLE can mint unlimited tokens
   /// @notice Only DEFAULT_ADMIN_ROLE can grant MINTER_ROLE
   bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
   ```

4. **Use AccessControlDefaultAdminRules for Production**
   ```solidity
   // Adds 2-step transfer with delay for DEFAULT_ADMIN_ROLE
   contract Production is AccessControlDefaultAdminRules {
       constructor(address admin)
           AccessControlDefaultAdminRules(7 days, admin)
       {}
   }
   ```

5. **Monitor Role Changes**
   ```solidity
   event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
   event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
   ```

## Summary

**AccessControl is ideal for**:
- Multi-administrator systems
- Granular permission requirements
- Separating concerns (principle of least privilege)
- Complex governance structures

**Key Takeaways**:
- Define roles as `bytes32` constants
- Use `onlyRole` modifier to protect functions
- `DEFAULT_ADMIN_ROLE` is powerful (use multisig)
- More gas-intensive than Ownable but more flexible
- Supports role enumeration and hierarchies
- Consider AccessControlDefaultAdminRules for production
