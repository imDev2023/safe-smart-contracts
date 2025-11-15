# Upgrade Patterns

## Overview

Smart contracts are immutable by default, but OpenZeppelin provides several proxy patterns that enable contract upgrades while preserving state and address. This is crucial for bug fixes, feature additions, and long-term protocol maintenance.

## Why Upgradeable Contracts?

### Benefits
- **Fix bugs** post-deployment
- **Add features** without redeployment
- **Preserve contract address** and state
- **Maintain integrations** (no address changes)

### Risks
- **Centralization**: Admin controls upgrades
- **Storage collisions**: Must preserve layout
- **Complexity**: More complex than regular contracts

## Proxy Patterns Covered

### 1. ERC1967Proxy
**File**: `ERC1967Proxy.md`

Standard upgradeable proxy following ERC-1967. Stores implementation address in a specific storage slot to avoid collisions.

**Key Features**:
- Standard storage slots (ERC-1967)
- Simple and gas-efficient
- Foundation for other patterns

**Use Cases**:
- Basic upgradeable contracts
- Building custom proxy systems

### 2. TransparentUpgradeableProxy
**File**: `TransparentProxy.md`

Separates admin and user interfaces to prevent function selector clashes.

**Key Features**:
- Separate admin interface
- Prevents selector collisions
- Admin can only call admin functions

**Use Cases**:
- Production deployments
- When admin and users call same proxy

### 3. UUPSUpgradeable
**File**: `UUPS.md`

Universal Upgradeable Proxy Standard where upgrade logic is in implementation, not proxy.

**Key Features**:
- Upgrade logic in implementation
- More gas-efficient than Transparent
- Smaller proxy contract

**Use Cases**:
- Gas-sensitive applications
- When you control implementation
- Modern upgradeable contracts

## Pattern Comparison

| Feature | ERC1967 | Transparent | UUPS |
|---------|---------|-------------|------|
| Upgrade Logic | External | Proxy | Implementation |
| Gas Cost | Low | Medium | Lowest |
| Complexity | Simple | Medium | Medium |
| Risk | Medium | Low | Medium |
| Proxy Size | Small | Large | Smallest |
| Use Case | Basic | Production | Gas-optimized |

## Storage Layout Rules

### Critical Rule: NEVER Change Storage Layout
```solidity
// Version 1
contract V1 {
    uint256 public value;  // Slot 0
    address public owner;  // Slot 1
}

// Version 2 - WRONG! (Changes layout)
contract V2Bad {
    address public owner;  // Slot 0 - WRONG!
    uint256 public value;  // Slot 1 - WRONG!
}

// Version 2 - CORRECT (Preserves layout)
contract V2Good {
    uint256 public value;  // Slot 0 - Same
    address public owner;  // Slot 1 - Same
    uint256 public newVar; // Slot 2 - New
}
```

### Namespaced Storage (ERC-7201)
OpenZeppelin 5.x uses namespaced storage to prevent collisions:

```solidity
/// @custom:storage-location erc7201:openzeppelin.storage.MyContract
struct MyContractStorage {
    uint256 value;
    address owner;
}

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.MyContract")) - 1)) & ~bytes32(uint256(0xff))
bytes32 private constant STORAGE_LOCATION = 0x...;

function _getStorage() private pure returns (MyContractStorage storage $) {
    assembly {
        $.slot := STORAGE_LOCATION
    }
}
```

## Basic Upgrade Workflow

### 1. Deploy Implementation
```solidity
const MyContract = await ethers.getContractFactory("MyContractV1");
const implementation = await MyContract.deploy();
```

### 2. Deploy Proxy
```solidity
const { upgrades } = require("hardhat");

const proxy = await upgrades.deployProxy(MyContract, [initArgs], {
    kind: "uups" // or "transparent"
});
```

### 3. Upgrade Implementation
```solidity
const MyContractV2 = await ethers.getContractFactory("MyContractV2");
const upgraded = await upgrades.upgradeProxy(proxy.address, MyContractV2);
```

## Security Considerations

### 1. Admin Key Management
```solidity
// Use multisig for admin
ProxyAdmin admin = new ProxyAdmin(gnosisSafeAddress);
```

### 2. Upgrade Timelock
```solidity
// Add delay before upgrades take effect
TimelockController timelock = new TimelockController(
    2 days,  // Minimum delay
    proposers,
    executors,
    address(0)
);
```

### 3. Storage Validation
```solidity
// Use OpenZeppelin Upgrades plugin
// Automatically validates storage layout
await upgrades.validateUpgrade(proxyAddress, NewImplementation);
```

## Testing Upgrades

```javascript
const { upgrades } = require("@openzeppelin/hardhat-upgrades");

describe("Upgrades", function() {
    it("should upgrade correctly", async function() {
        // Deploy V1
        const V1 = await ethers.getContractFactory("MyContractV1");
        const proxy = await upgrades.deployProxy(V1, [42]);

        // Set state in V1
        await proxy.setValue(100);
        expect(await proxy.value()).to.equal(100);

        // Upgrade to V2
        const V2 = await ethers.getContractFactory("MyContractV2");
        const upgraded = await upgrades.upgradeProxy(proxy.address, V2);

        // State should be preserved
        expect(await upgraded.value()).to.equal(100);

        // New functionality should work
        await upgraded.newFunction();
    });
});
```

## Best Practices

1. **Use OpenZeppelin Upgrades Plugin**
   - Validates storage layout
   - Prevents common mistakes
   - Handles deployments

2. **Prefer UUPS for New Projects**
   - More gas-efficient
   - Smaller proxy size
   - Modern standard

3. **Always Use Timelock**
   - Give users time to exit
   - Reduce centralization risk
   - Standard for DAOs

4. **Document Storage Layout**
   - Comment all state variables
   - Track version changes
   - Use namespaced storage

5. **Test Thoroughly**
   - Test upgrade process
   - Validate storage preservation
   - Check all functions work

## Common Patterns

### Pattern 1: Governance-Controlled Upgrades
```solidity
contract Governed is UUPSUpgradeable, AccessControl {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
```

### Pattern 2: Immutable After Deploy
```solidity
contract ImmutableAfterInit is UUPSUpgradeable {
    bool public upgradesDisabled;

    function disableUpgrades() external onlyOwner {
        upgradesDisabled = true;
    }

    function _authorizeUpgrade(address) internal override {
        require(!upgradesDisabled, "Upgrades disabled");
    }
}
```

### Pattern 3: Emergency Pause Before Upgrade
```solidity
contract SafeUpgrade is UUPSUpgradeable, Pausable {
    function _authorizeUpgrade(address) internal override whenPaused {
        // Can only upgrade when paused
    }
}
```

## Resources

- [OpenZeppelin Upgrades Docs](https://docs.openzeppelin.com/upgrades-plugins)
- [Proxy Patterns Guide](https://docs.openzeppelin.com/contracts/5.x/api/proxy)
- [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable)

## Next Steps

For detailed implementation guides, see:
- [ERC1967Proxy.md](./ERC1967Proxy.md)
- [TransparentProxy.md](./TransparentProxy.md)
- [UUPS.md](./UUPS.md)
