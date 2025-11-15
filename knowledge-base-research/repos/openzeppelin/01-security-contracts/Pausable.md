# Pausable

## Overview

`Pausable` implements the circuit breaker pattern, allowing contracts to be paused in emergency situations. It's essential for incident response and risk management in production smart contracts.

**Contract Path**: `@openzeppelin/contracts/utils/Pausable.sol`
**Version**: 5.x
**License**: MIT

## Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

abstract contract Pausable is Context {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    error EnforcedPause();
    error ExpectedPause();

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
```

## Basic Usage

```solidity
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable, Pausable {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    // Pause all transfers
    function pause() public onlyOwner {
        _pause();
    }

    // Resume operations
    function unpause() public onlyOwner {
        _unpause();
    }

    // Only works when not paused
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }
}
```

## Key Features

### 1. whenNotPaused Modifier
Restrict functions to operate only when not paused:
```solidity
function criticalOperation() public whenNotPaused {
    // Only executes when contract is not paused
}
```

### 2. whenPaused Modifier
Restrict functions to operate only when paused:
```solidity
function emergencyWithdraw() public whenPaused {
    // Only executes during emergency pause
}
```

### 3. Internal Pause/Unpause
Protected functions for state changes:
```solidity
function _pause() internal virtual whenNotPaused
function _unpause() internal virtual whenPaused
```

### 4. Events
Track pause state changes:
```solidity
event Paused(address account);
event Unpaused(address account);
```

## Common Patterns

### Pattern 1: DeFi Protocol Pause
```solidity
contract DeFiVault is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function deposit(uint256 amount) external whenNotPaused {
        // Deposit logic
    }

    function withdraw(uint256 amount) external whenNotPaused {
        // Withdrawal logic
    }

    function emergencyPause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Only admin can unpause
        _unpause();
    }
}
```

### Pattern 2: Partial Pause
```solidity
contract PartialPause is Pausable, Ownable {
    // Regular operations are paused
    function trade() external whenNotPaused {
        // Trading paused during emergency
    }

    // Emergency withdrawals always available
    function emergencyWithdraw() external {
        // NOT using whenNotPaused - always available
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }
}
```

### Pattern 3: Scheduled Maintenance
```solidity
contract MaintenanceContract is Pausable, Ownable {
    uint256 public maintenanceEnd;

    function scheduleMaintenance(uint256 duration) external onlyOwner {
        _pause();
        maintenanceEnd = block.timestamp + duration;
    }

    function endMaintenance() external {
        require(block.timestamp >= maintenanceEnd, "Maintenance not finished");
        _unpause();
    }
}
```

## Security Considerations

### 1. Centralization Risk
Pause control is centralized:
```solidity
function pause() public onlyOwner {
    _pause(); // Single point of control
}
```

**Mitigation**:
- Use multisig for pause authority
- Implement timelock for unpause
- Consider automated unpause after delay

### 2. Accidental Permanent Pause
If pause authority is lost:
```solidity
contract Risk is Pausable, Ownable {
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
// If ownership is lost while paused, contract is permanently paused!
```

**Mitigation**:
```solidity
uint256 public pausedUntil;

function pause(uint256 duration) public onlyOwner {
    _pause();
    pausedUntil = block.timestamp + duration;
}

function autoUnpause() public {
    require(paused(), "Not paused");
    require(block.timestamp >= pausedUntil, "Too early");
    _unpause();
}
```

### 3. Front-Running Pause
Malicious actors can front-run pause transactions:
```solidity
// Admin sees exploit, broadcasts pause()
// Attacker front-runs with exploit transaction
```

**Mitigation**:
- Use flashbots or private relayers
- Monitor mempool
- Have automated pause triggers

## Gas Costs

- **Pause check**: ~300 gas (single SLOAD)
- **pause()**: ~25,000 gas
- **unpause()**: ~8,000 gas

Extremely cheap safety mechanism.

## Testing

```javascript
describe("Pausable", function() {
    let contract, owner, user;

    beforeEach(async function() {
        [owner, user] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory("MyToken");
        contract = await Contract.deploy(owner.address);
    });

    it("should start unpaused", async function() {
        expect(await contract.paused()).to.be.false;
    });

    it("should pause when owner calls pause", async function() {
        await contract.pause();
        expect(await contract.paused()).to.be.true;
    });

    it("should block operations when paused", async function() {
        await contract.pause();
        await expect(
            contract.transfer(user.address, 100)
        ).to.be.revertedWithCustomError(contract, "EnforcedPause");
    });

    it("should resume operations after unpause", async function() {
        await contract.pause();
        await contract.unpause();

        // Should work now
        await contract.transfer(user.address, 100);
    });

    it("should emit events", async function() {
        await expect(contract.pause())
            .to.emit(contract, "Paused")
            .withArgs(owner.address);

        await expect(contract.unpause())
            .to.emit(contract, "Unpaused")
            .withArgs(owner.address);
    });
});
```

## Best Practices

1. **Combine with Access Control**
   ```solidity
   contract Secure is Pausable, AccessControl {
       bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

       function pause() public onlyRole(PAUSER_ROLE) {
           _pause();
       }

       function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
           _unpause();  // Higher privilege required
       }
   }
   ```

2. **Implement Auto-Unpause**
   ```solidity
   uint256 public constant MAX_PAUSE_DURATION = 7 days;
   uint256 public pauseTimestamp;

   function pause() public onlyOwner {
       _pause();
       pauseTimestamp = block.timestamp;
   }

   function autoUnpause() public {
       require(paused(), "Not paused");
       require(
           block.timestamp >= pauseTimestamp + MAX_PAUSE_DURATION,
           "Too early"
       );
       _unpause();
   }
   ```

3. **Document What Gets Paused**
   ```solidity
   /// @notice Pauses deposits, withdrawals, and trades
   /// @notice Emergency withdrawals remain available
   function pause() public onlyOwner {
       _pause();
   }
   ```

4. **Monitor Pause Events**
   ```javascript
   contract.on("Paused", (account) => {
       console.log(`Contract paused by ${account}`);
       notifyTeam("URGENT: Contract paused!");
   });
   ```

## Summary

**Pausable is essential for**:
- Emergency response to exploits
- Scheduled maintenance
- Risk mitigation during upgrades
- DeFi protocols with high TVL

**Key Takeaways**:
- Simple circuit breaker pattern
- Very gas-efficient (~300 gas per check)
- Use `whenNotPaused` for normal operations
- Combine with Ownable or AccessControl
- Consider auto-unpause mechanisms
- Separate pause and unpause authorities
- Essential for production contracts handling value
