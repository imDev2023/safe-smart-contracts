# ReentrancyGuard

## Overview

`ReentrancyGuard` is a critical security contract that prevents reentrancy attacks - one of the most dangerous vulnerabilities in smart contract development. The infamous DAO hack in 2016 resulted in a $60 million loss due to a reentrancy vulnerability.

**Contract Path**: `@openzeppelin/contracts/utils/ReentrancyGuard.sol`
**Version**: 5.x
**License**: MIT

## What is a Reentrancy Attack?

A reentrancy attack occurs when a contract makes an external call to an untrusted contract before updating its own state. The untrusted contract can then call back into the original function, exploiting the stale state.

### Example Vulnerable Code
```solidity
contract VulnerableBank {
    mapping(address => uint256) public balances;

    function withdraw() public {
        uint256 balance = balances[msg.sender];

        // External call BEFORE state update (VULNERABLE!)
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success);

        // State update happens too late
        balances[msg.sender] = 0;
    }
}
```

### Attack Scenario
```solidity
contract Attacker {
    VulnerableBank bank;

    constructor(address _bank) {
        bank = VulnerableBank(_bank);
    }

    function attack() public payable {
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // This gets called during withdraw
    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw(); // Re-enter before balance is set to 0!
        }
    }
}
```

## How ReentrancyGuard Works

ReentrancyGuard uses a state variable to track whether a function is currently executing. If a reentrant call is detected, it reverts.

### Source Code
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StorageSlot} from "./StorageSlot.sol";

abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // Storage slot for reentrancy status (ERC-7201 namespaced)
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        _nonReentrantBeforeView();
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}
```

## Key Components

### 1. Storage Slot Pattern
Uses a specific storage slot (ERC-7201 compliant) to store the reentrancy status:
- **NOT_ENTERED** (1): Function is not currently executing
- **ENTERED** (2): Function is currently executing

```solidity
bytes32 private constant REENTRANCY_GUARD_STORAGE =
    0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;
```

This namespaced storage approach ensures compatibility with upgradeable contracts.

### 2. nonReentrant Modifier
The primary protection mechanism:
```solidity
modifier nonReentrant() {
    _nonReentrantBefore();  // Check and set ENTERED
    _;                       // Execute function
    _nonReentrantAfter();    // Reset to NOT_ENTERED
}
```

### 3. nonReentrantView Modifier
For view/pure functions that need reentrancy protection:
```solidity
modifier nonReentrantView() {
    _nonReentrantBeforeView();  // Only checks, doesn't modify state
    _;
}
```

### 4. Custom Error
Gas-efficient error handling:
```solidity
error ReentrancyGuardReentrantCall();
```

## Usage

### Basic Usage
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SafeBank is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        // Update state BEFORE external call
        balances[msg.sender] = 0;

        // External call protected by nonReentrant
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
```

### Advanced: Protecting Multiple Functions
```solidity
contract Vault is ReentrancyGuard {
    mapping(address => uint256) public shares;

    function withdraw(uint256 amount) external nonReentrant {
        // Withdrawal logic
    }

    function withdrawAll() external nonReentrant {
        // Will revert if withdraw() is called within this
        withdraw(shares[msg.sender]);
    }

    // Both functions share the same guard
}
```

### View Function Protection
```solidity
contract PriceOracle is ReentrancyGuard {
    // View function that calls external contract
    function getPrice() public view nonReentrantView returns (uint256) {
        // Prevents reentrancy during view calls
        return externalOracle.currentPrice();
    }
}
```

### Cross-Function Protection
```solidity
contract DeFiProtocol is ReentrancyGuard {
    function deposit() external nonReentrant {
        // Protected
    }

    function withdraw() external nonReentrant {
        // Protected
    }

    function swap() external nonReentrant {
        // All share the same guard
        // Calling deposit() here would revert
    }
}
```

## Security Considerations

### 1. State Updates Before External Calls
ReentrancyGuard is NOT a substitute for proper state management:

```solidity
// STILL VULNERABLE (wrong state update order)
function withdraw() public nonReentrant {
    uint256 balance = balances[msg.sender];
    (bool success, ) = msg.sender.call{value: balance}("");
    balances[msg.sender] = 0; // TOO LATE!
}

// CORRECT (checks-effects-interactions)
function withdraw() public nonReentrant {
    uint256 balance = balances[msg.sender];
    balances[msg.sender] = 0; // Update state first
    (bool success, ) = msg.sender.call{value: balance}("");
}
```

### 2. Gas Limitations
ReentrancyGuard adds gas overhead:
- First call (cold storage): ~20,000 gas
- Warm storage access: ~2,400 gas

This is negligible compared to external call costs.

### 3. Cross-Contract Reentrancy
ReentrancyGuard only protects within a single contract:

```solidity
contract ContractA is ReentrancyGuard {
    ContractB public contractB;

    function functionA() external nonReentrant {
        contractB.functionB(); // If B calls back to A, it's a NEW transaction
    }
}
```

For cross-contract protection, you need additional patterns.

### 4. Read-Only Reentrancy
Be careful with view functions in protocols with shared state:

```solidity
contract Vault is ReentrancyGuard {
    function getAssets(address user) public view returns (uint256) {
        // This view function might be called during reentrancy
        // Use nonReentrantView if it accesses external contracts
        return externalContract.balanceOf(user);
    }
}
```

## Gas Optimization

### Why Use 1 and 2 Instead of 0 and 1?
```solidity
uint256 private constant NOT_ENTERED = 1; // Not 0!
uint256 private constant ENTERED = 2;     // Not 1!
```

**Reason**: In the EVM, changing storage from 0 to non-zero costs 20,000 gas, while non-zero to non-zero costs only 5,000 gas. Using 1 and 2 saves ~15,000 gas per call after initialization.

### Storage Slot Pattern
Using a specific storage slot allows:
- Compatibility with upgradeable contracts
- No storage layout conflicts
- Predictable gas costs

## Common Patterns

### Pattern 1: DeFi Vault
```solidity
contract Vault is ReentrancyGuard, Ownable {
    mapping(address => uint256) public deposits;

    function deposit() external payable nonReentrant {
        deposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

### Pattern 2: Token Sale
```solidity
contract TokenSale is ReentrancyGuard {
    IERC20 public token;
    uint256 public rate;

    function buyTokens() external payable nonReentrant {
        uint256 tokenAmount = msg.value * rate;
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient tokens");

        // Transfer tokens (external call)
        require(token.transfer(msg.sender, tokenAmount), "Transfer failed");
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

### Pattern 3: NFT Minting with Callback
```solidity
contract NFTContract is ERC721, ReentrancyGuard {
    function mint(address to, uint256 tokenId) external nonReentrant {
        _safeMint(to, tokenId); // Calls onERC721Received on receiver
    }

    function burn(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _burn(tokenId);
    }
}
```

## Testing

### Test for Reentrancy Protection
```javascript
const { expect } = require("chai");

describe("ReentrancyGuard", function() {
    it("should prevent reentrancy attack", async function() {
        const [owner, attacker] = await ethers.getSigners();

        // Deploy vulnerable contract
        const Bank = await ethers.getContractFactory("SafeBank");
        const bank = await Bank.deploy();

        // Deploy attacker contract
        const Attacker = await ethers.getContractFactory("ReentrancyAttacker");
        const attackerContract = await Attacker.deploy(bank.address);

        // Deposit funds
        await bank.connect(attacker).deposit({ value: ethers.parseEther("1") });

        // Attempt attack
        await expect(
            attackerContract.attack({ value: ethers.parseEther("1") })
        ).to.be.revertedWithCustomError(bank, "ReentrancyGuardReentrantCall");
    });

    it("should allow sequential calls", async function() {
        const [user] = await ethers.getSigners();
        const bank = await Bank.deploy();

        await bank.deposit({ value: ethers.parseEther("1") });
        await bank.withdraw(); // First call

        await bank.deposit({ value: ethers.parseEther("1") });
        await bank.withdraw(); // Second call - should succeed
    });
});
```

### Attacker Contract for Testing
```solidity
contract ReentrancyAttacker {
    SafeBank public bank;
    uint256 public attackCount;

    constructor(address _bank) {
        bank = SafeBank(_bank);
    }

    function attack() external payable {
        bank.deposit{value: msg.value}();
        bank.withdraw();
    }

    receive() external payable {
        if (attackCount < 5 && address(bank).balance >= 1 ether) {
            attackCount++;
            bank.withdraw(); // Attempt reentrancy
        }
    }
}
```

## Comparison with Alternatives

### Manual Guard vs ReentrancyGuard

**Manual Implementation**:
```solidity
contract ManualGuard {
    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}
```

**Issues with Manual Approach**:
- Uses slot 0 (conflicts in upgradeable contracts)
- Higher gas cost (0→1→0 vs 1→2→1)
- More error-prone

**OpenZeppelin's Advantages**:
- ERC-7201 namespaced storage
- Gas-optimized (non-zero values)
- Well-tested and audited
- Custom errors for gas efficiency

### mutex vs ReentrancyGuard

Some protocols use mutex locks:
```solidity
uint256 private constant UNLOCKED = 1;
uint256 private constant LOCKED = 2;
uint256 private lockStatus = UNLOCKED;
```

ReentrancyGuard is essentially this pattern with:
- Better naming (NOT_ENTERED/ENTERED)
- Standardized implementation
- Community auditing

## Limitations

### 1. Single Contract Only
Doesn't protect against cross-contract reentrancy:
```solidity
ContractA → ContractB → ContractA (not protected)
```

### 2. Not a Silver Bullet
Still need proper state management:
- Follow checks-effects-interactions pattern
- Update state before external calls
- Validate inputs

### 3. View Function Edge Cases
View functions can still be called during reentrancy unless protected with `nonReentrantView`.

## Upgradeable Contracts

For upgradeable contracts, use `ReentrancyGuardUpgradeable`:

```solidity
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract VaultUpgradeable is Initializable, ReentrancyGuardUpgradeable {
    function initialize() public initializer {
        __ReentrancyGuard_init();
    }

    function withdraw() external nonReentrant {
        // Protected withdrawal logic
    }
}
```

## Best Practices

1. **Always use nonReentrant for functions that**:
   - Make external calls
   - Transfer ETH
   - Interact with untrusted contracts
   - Call token transfer functions

2. **Combine with other patterns**:
   ```solidity
   function withdraw() external nonReentrant whenNotPaused onlyOwner {
       // Triple protection
   }
   ```

3. **Update state before external calls**:
   ```solidity
   balances[msg.sender] = 0;  // State update
   msg.sender.call{value: balance}("");  // External call
   ```

4. **Use for both ETH and token transfers**:
   ```solidity
   function withdrawTokens(address token, uint256 amount) external nonReentrant {
       balances[msg.sender][token] -= amount;
       IERC20(token).transfer(msg.sender, amount);
   }
   ```

## Related Patterns

- **Checks-Effects-Interactions**: Always update state before external calls
- **Pull Payment**: Let users withdraw rather than pushing payments
- **SafeERC20**: Safe token transfer wrappers
- **Pausable**: Emergency stop mechanism

## Resources

- [OpenZeppelin ReentrancyGuard Docs](https://docs.openzeppelin.com/contracts/5.x/api/utils#ReentrancyGuard)
- [Reentrancy Attack Explanation](https://docs.openzeppelin.com/contracts/5.x/api/security)
- [The DAO Hack](https://www.gemini.com/cryptopedia/the-dao-hack-makerdao)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)

## Summary

**Key Takeaways**:
- ReentrancyGuard prevents reentrancy attacks with a simple modifier
- Gas-efficient implementation (1→2→1 pattern)
- Must be combined with proper state management
- Use `nonReentrant` on all functions making external calls
- Essential for contracts handling ETH or tokens
- Part of defense-in-depth security strategy
