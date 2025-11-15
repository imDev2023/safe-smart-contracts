# ERC20 - Fungible Token Standard

## Overview

ERC20 is the most widely-used token standard on Ethereum, defining a common interface for fungible tokens. "Fungible" means all tokens are identical and interchangeable, like traditional currencies.

**Contract Path**: `@openzeppelin/contracts/token/ERC20/ERC20.sol`
**Standard**: [EIP-20](https://eips.ethereum.org/EIPS/eip-20)
**Version**: 5.x

## Core Functions

### View Functions
```solidity
function name() public view returns (string memory)
function symbol() public view returns (string memory)
function decimals() public view returns (uint8)
function totalSupply() public view returns (uint256)
function balanceOf(address account) public view returns (uint256)
function allowance(address owner, address spender) public view returns (uint256)
```

### Transfer Functions
```solidity
function transfer(address to, uint256 value) public returns (bool)
function transferFrom(address from, address to, uint256 value) public returns (bool)
function approve(address spender, uint256 value) public returns (bool)
```

### Events
```solidity
event Transfer(address indexed from, address indexed to, uint256 value)
event Approval(address indexed owner, address indexed spender, uint256 value)
```

## Basic Implementation

```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}
```

## Common Extensions

### 1. Mintable
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintableToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("MintableToken", "MINT")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

### 2. Burnable
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BurnableToken is ERC20Burnable {
    constructor() ERC20("BurnableToken", "BURN") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

// Usage
token.burn(100); // Burn own tokens
token.burnFrom(account, 100); // Burn with allowance
```

### 3. Capped Supply
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract CappedToken is ERC20Capped {
    constructor()
        ERC20("CappedToken", "CAP")
        ERC20Capped(1000000 * 10**18) // 1 million max
    {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount); // Reverts if exceeds cap
    }
}
```

### 4. Pausable
```solidity
contract PausableToken is ERC20, Pausable, Ownable {
    constructor(address initialOwner)
        ERC20("PausableToken", "PAUSE")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }
}
```

### 5. Snapshot
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract SnapshotToken is ERC20Snapshot, Ownable {
    constructor(address initialOwner)
        ERC20("SnapshotToken", "SNAP")
        Ownable(initialOwner)
    {}

    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }

    // Query historical balance
    function balanceOfAt(address account, uint256 snapshotId)
        public
        view
        returns (uint256)
    {}
}
```

### 6. Votes (Governance)
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovernanceToken is ERC20Votes {
    constructor()
        ERC20("GovernanceToken", "GOV")
        EIP712("GovernanceToken", "1")
    {}

    // Voting power based on token holdings
    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    function getVotes(address account) public view returns (uint256) {
        return _getVotingUnits(account);
    }
}
```

### 7. Permit (Gasless Approvals)
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract PermitToken is ERC20Permit {
    constructor()
        ERC20("PermitToken", "PERMIT")
        ERC20Permit("PermitToken")
    {}

    // Users can approve via signature (EIP-2612)
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {}
}
```

## Understanding Decimals

```solidity
// Most tokens use 18 decimals (like ETH)
uint8 public decimals = 18;

// 1 token = 1 * 10^18 wei
// 0.5 tokens = 5 * 10^17 wei

// Example: Mint 1000 tokens
_mint(msg.sender, 1000 * 10**decimals());

// USDC uses 6 decimals
// 1 USDC = 1 * 10^6 = 1,000,000
```

## Security Considerations

### 1. Integer Overflow (Solved in Solidity 0.8+)
```solidity
// Pre-0.8: Needed SafeMath
// Post-0.8: Built-in overflow protection
uint256 balance = balances[msg.sender] + amount; // Safe in 0.8+
```

### 2. Allowance Approval Race Condition
```solidity
// VULNERABLE to front-running
token.approve(spender, 100);
// Later...
token.approve(spender, 200); // Spender can spend 300!

// SAFE: Use increaseAllowance/decreaseAllowance
token.increaseAllowance(spender, 100);
```

### 3. Transfer Return Values
```solidity
// UNSAFE: Doesn't check return value
token.transfer(to, amount);

// SAFE: Use SafeERC20
using SafeERC20 for IERC20;
token.safeTransfer(to, amount);
```

## Complete Production Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ProductionToken is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    AccessControl,
    ERC20Permit
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1B tokens

    constructor(address defaultAdmin, address pauser, address minter)
        ERC20("ProductionToken", "PROD")
        ERC20Permit("ProductionToken")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    // Required overrides
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
```

## Best Practices

1. **Set realistic max supply**
2. **Use access control for minting**
3. **Implement pause for emergencies**
4. **Use 18 decimals (standard)**
5. **Add permit for gasless approvals**
6. **Document token economics**
7. **Audit before mainnet deployment**

## Summary

- ERC20 is the standard for fungible tokens
- 18 decimals is standard (but configurable)
- Use extensions for additional functionality
- Always use SafeERC20 when interacting with external tokens
- Combine with access control and pausable for security
- Consider permit for better UX (gasless approvals)
