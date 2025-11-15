# Ownable

## Overview

`Ownable` is the simplest and most widely-used access control pattern in Solidity. It restricts certain functions to a single owner account, making it perfect for contracts with straightforward administrative needs.

**Contract Path**: `@openzeppelin/contracts/access/Ownable.sol`
**Version**: 5.x
**License**: MIT

## Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
```

## Key Features

### 1. Single Owner
One address has complete control:
```solidity
address private _owner;
```

### 2. onlyOwner Modifier
Restrict function access to the owner:
```solidity
modifier onlyOwner() {
    _checkOwner();
    _;
}
```

### 3. Ownership Transfer
Change ownership to another address:
```solidity
function transferOwnership(address newOwner) public virtual onlyOwner
```

### 4. Ownership Renunciation
Remove owner completely (irreversible):
```solidity
function renounceOwnership() public virtual onlyOwner
```

### 5. Custom Errors
Gas-efficient error handling:
```solidity
error OwnableUnauthorizedAccount(address account);
error OwnableInvalidOwner(address owner);
```

## Usage

### Basic Implementation
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    uint256 public value;

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Anyone can call this
    function getValue() public view returns (uint256) {
        return value;
    }

    // Only owner can call this
    function setValue(uint256 newValue) public onlyOwner {
        value = newValue;
    }
}
```

### Token Contract Example
```solidity
contract MyToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }
}
```

### With Pausable
```solidity
contract PausableContract is Ownable, Pausable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sensitiveOperation() public whenNotPaused {
        // Only when not paused
    }
}
```

## Ownership Transfer Patterns

### Two-Step Transfer (Ownable2Step)
Safer ownership transfer requiring acceptance:

```solidity
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract SafeContract is Ownable2Step {
    constructor(address initialOwner) Ownable(initialOwner) {}

    // Step 1: Current owner proposes new owner
    // transferOwnership(newOwner) - inherited

    // Step 2: New owner must accept
    // newOwner calls acceptOwnership()
}
```

**Why use Ownable2Step?**
- Prevents accidental transfer to wrong address
- New owner must explicitly accept
- Reduces risk of irreversible mistakes

### Transferring to Multisig
```solidity
// Transfer to Gnosis Safe multisig
contract.transferOwnership(gnosisSafeAddress);
```

### Transferring to DAO
```solidity
// Transfer to governance contract
contract.transferOwnership(governorAddress);
```

## Security Considerations

### 1. Single Point of Failure
Owner has complete control:
```solidity
// Owner can do ANYTHING marked onlyOwner
function emergencyWithdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
}
```

**Mitigation**:
- Use multisig wallet as owner
- Consider AccessControl for granular permissions
- Implement timelock for sensitive operations

### 2. Owner Key Compromise
If private key is lost/stolen:
- Lost: Contract becomes immutable (if renounced)
- Stolen: Attacker has full control

**Mitigation**:
- Use hardware wallet for owner
- Use multisig (2-of-3, 3-of-5, etc.)
- Transfer to governance contract

### 3. Renouncement is Permanent
```solidity
contract.renounceOwnership(); // Can NEVER be undone!
```

**Use Cases for Renouncement**:
- Fully decentralized protocols
- No more upgrades needed
- Immutable rules

**Risks**:
- Can't pause in emergency
- Can't fix bugs
- Can't upgrade

### 4. Constructor Initialization
Must provide initial owner:
```solidity
constructor(address initialOwner) Ownable(initialOwner) {
    // initialOwner cannot be address(0)
}
```

## Common Patterns

### Pattern 1: Admin Functions
```solidity
contract ConfigurableContract is Ownable {
    uint256 public fee;
    address public treasury;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // 10% max
        fee = newFee;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        treasury = newTreasury;
    }
}
```

### Pattern 2: Emergency Controls
```solidity
contract EmergencyContract is Ownable, Pausable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function emergencyPause() external onlyOwner {
        _pause();
    }

    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
```

### Pattern 3: Minting Control
```solidity
contract NFTCollection is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor(address initialOwner)
        ERC721("MyNFT", "MNFT")
        Ownable(initialOwner)
    {}

    function mint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
    }
}
```

## Migration to AccessControl

When you need more granular permissions:

```solidity
// Old: Single owner
contract OldContract is Ownable {
    function mint() public onlyOwner { }
    function pause() public onlyOwner { }
    function withdraw() public onlyOwner { }
}

// New: Multiple roles
contract NewContract is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    function mint() public onlyRole(MINTER_ROLE) { }
    function pause() public onlyRole(PAUSER_ROLE) { }
    function withdraw() public onlyRole(TREASURER_ROLE) { }
}
```

## Gas Costs

- **Owner check**: ~400 gas (single SLOAD)
- **Ownership transfer**: ~25,000 gas
- **Renounce ownership**: ~25,000 gas

Extremely cheap compared to AccessControl (~2,000-3,000 gas per check).

## Testing

```javascript
const { expect } = require("chai");

describe("Ownable", function() {
    let contract, owner, addr1, addr2;

    beforeEach(async function() {
        [owner, addr1, addr2] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory("MyContract");
        contract = await Contract.deploy(owner.address);
    });

    it("should set the right owner", async function() {
        expect(await contract.owner()).to.equal(owner.address);
    });

    it("should restrict onlyOwner functions", async function() {
        await expect(
            contract.connect(addr1).setValue(100)
        ).to.be.revertedWithCustomError(contract, "OwnableUnauthorizedAccount");
    });

    it("should allow owner to call protected functions", async function() {
        await contract.setValue(100);
        expect(await contract.value()).to.equal(100);
    });

    it("should transfer ownership", async function() {
        await contract.transferOwnership(addr1.address);
        expect(await contract.owner()).to.equal(addr1.address);

        // Old owner can't call anymore
        await expect(
            contract.setValue(200)
        ).to.be.revertedWithCustomError(contract, "OwnableUnauthorizedAccount");

        // New owner can call
        await contract.connect(addr1).setValue(200);
        expect(await contract.value()).to.equal(200);
    });

    it("should renounce ownership", async function() {
        await contract.renounceOwnership();
        expect(await contract.owner()).to.equal(ethers.ZeroAddress);

        // No one can call onlyOwner functions
        await expect(
            contract.setValue(100)
        ).to.be.revertedWithCustomError(contract, "OwnableUnauthorizedAccount");
    });

    it("should prevent zero address ownership", async function() {
        await expect(
            contract.transferOwnership(ethers.ZeroAddress)
        ).to.be.revertedWithCustomError(contract, "OwnableInvalidOwner");
    });
});
```

## Best Practices

1. **Use Multisig as Owner**
   ```solidity
   // Deploy with multisig address
   MyContract contract = new MyContract(gnosisSafeAddress);
   ```

2. **Consider Ownable2Step for High-Value Contracts**
   ```solidity
   contract HighValueContract is Ownable2Step {
       // Safer ownership transfer
   }
   ```

3. **Document Owner Capabilities**
   ```solidity
   /// @notice Owner can mint unlimited tokens
   function mint(address to, uint256 amount) public onlyOwner {
       _mint(to, amount);
   }
   ```

4. **Plan for Decentralization**
   ```solidity
   // Phase 1: Team owns contract
   // Phase 2: Transfer to multisig
   // Phase 3: Transfer to DAO
   // Phase 4: Renounce if fully decentralized
   ```

5. **Combine with Other Patterns**
   ```solidity
   contract SecureContract is Ownable, Pausable, ReentrancyGuard {
       // Defense in depth
   }
   ```

## Comparison: Ownable vs AccessControl

| Feature | Ownable | AccessControl |
|---------|---------|---------------|
| Complexity | Very Simple | Moderate |
| Gas Cost | ~400 gas | ~2,000 gas |
| Flexibility | Single admin | Multiple roles |
| Use Case | Simple contracts | Complex systems |
| Role Management | No | Yes |
| Enumeration | No | Yes |

## Common Pitfalls

### 1. Forgetting to Set Initial Owner
```solidity
// WRONG - won't compile
contract Bad is Ownable {
    constructor() {} // Missing initialOwner parameter
}

// CORRECT
contract Good is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}
}
```

### 2. Transferring to EOA Instead of Multisig
```solidity
// RISKY - single private key
contract.transferOwnership(myWalletAddress);

// BETTER - multisig
contract.transferOwnership(gnosisSafeAddress);
```

### 3. Renouncing Too Early
```solidity
// Be 100% sure before doing this!
contract.renounceOwnership(); // PERMANENT!
```

## Integration Examples

### With OpenZeppelin Wizard
```solidity
// Generated by OpenZeppelin Contracts Wizard
contract MyToken is ERC20, Ownable, Pausable {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

### With Upgradeable Contracts
```solidity
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyUpgradeableContract is Initializable, OwnableUpgradeable {
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function protectedFunction() public onlyOwner {
        // Only owner can call
    }
}
```

## Summary

**Ownable is ideal for**:
- Simple admin functions
- Single-administrator contracts
- Quick prototyping
- Contracts with straightforward access needs

**Not ideal for**:
- Complex permission systems
- Multiple administrators with different roles
- High-security production systems (use multisig)
- Contracts requiring granular access control

**Key Takeaways**:
- Simplest access control pattern
- Very gas-efficient (~400 gas per check)
- Single point of failure (use multisig!)
- Use Ownable2Step for safer transfers
- Renouncement is permanent
- Migrate to AccessControl when you need more flexibility
