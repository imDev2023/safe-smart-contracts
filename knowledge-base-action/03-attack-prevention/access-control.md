# Access Control Vulnerabilities

## What It Is
Access control vulnerabilities occur when smart contracts fail to properly restrict who can execute sensitive functions, allowing unauthorized users to perform privileged operations. This includes missing modifiers, improper role checks, default visibility issues, and flawed ownership mechanisms.

## Why It Matters
Access control failures are among the most common and costly smart contract vulnerabilities. The Rubixi contract lost ownership to anyone who called its constructor-like function, resulting in complete loss of control. Multiple token hacks, DeFi protocol exploits, and governance attacks stem from improper access controls. These vulnerabilities can lead to complete protocol takeover, fund theft, and permanent loss of administrative capabilities.

## Vulnerable Code Example

### Example 1: Missing Access Control

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableToken {
    string public name = "Vulnerable Token";
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
        totalSupply = 1000000;
        balances[owner] = totalSupply;
    }

    // VULNERABILITY: Anyone can mint tokens!
    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balances[to] += amount;
    }

    // VULNERABILITY: Anyone can change critical parameters!
    function setOwner(address newOwner) public {
        owner = newOwner;
    }

    // VULNERABILITY: Anyone can pause the contract!
    function emergencyStop() public {
        // Critical functionality anyone can call
        selfdestruct(payable(msg.sender));
    }
}
```

### Example 2: Default Visibility

```solidity
// INSECURE - Solidity < 0.5.0
pragma solidity ^0.4.24;

contract DefaultVisibility {
    address owner;
    uint256 private secretValue;

    constructor() public {
        owner = msg.sender;
    }

    // VULNERABILITY: No visibility specified = public in old Solidity
    function setSecretValue(uint256 _value) {
        secretValue = _value;
    }

    // Should be private/internal
    function _internalHelper() {
        // Sensitive logic
    }
}
```

### Example 3: Incorrect Constructor Name (Rubixi Vulnerability)

```solidity
// INSECURE - Old Solidity versions
pragma solidity ^0.4.22;

contract DynamicPyramid {
    address public creator;

    // VULNERABILITY: Function name doesn't match contract name!
    // This is NOT a constructor - anyone can call it!
    function DynamicPyramid() public {
        creator = msg.sender;
    }

    function collectFees() public {
        require(msg.sender == creator);
        // Attacker can become creator by calling DynamicPyramid()
        payable(creator).transfer(address(this).balance);
    }
}
```

## The Attack Scenario

**Attack on Missing Access Control:**

1. **Reconnaissance**: Attacker scans contract, finds `mint()` has no access control
2. **Exploitation**: Calls `mint(attackerAddress, 1000000000)`
3. **Token Flood**: Mints unlimited tokens to their address
4. **Market Manipulation**: Dumps tokens on DEX, crashes price
5. **Total Loss**: Protocol reputation destroyed, token value = 0

**Numerical Example:**
```
Initial State:
- Total Supply: 1,000,000 tokens
- Token Price: $1.00
- Market Cap: $1,000,000

Attack Execution:
1. Attacker calls mint(attacker, 999,000,000)
2. New Total Supply: 1,000,000,000 tokens
3. Attacker owns 99.9% of supply

Market Impact:
4. Attacker sells 100M tokens on DEX
5. Price crashes to $0.001
6. Attacker profits: ~$100K
7. All legitimate holders lose 99.9% value

Final State:
- Protocol market cap: $1,000
- Legitimate users lost: $999,000
- Attacker gained: ~$100,000
```

## Prevention Methods

### Method 1: OpenZeppelin Ownable

Simple single-owner access control for straightforward contracts.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SecureToken is Ownable {
    string public name = "Secure Token";
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    constructor() {
        totalSupply = 1000000;
        balances[msg.sender] = totalSupply;
    }

    // Only owner can mint
    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[to] += amount;
    }

    // Ownership transfer with two-step verification
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        super.transferOwnership(newOwner);
    }

    // Critical function protected
    function emergencyStop() public onlyOwner {
        // Only owner can call
    }
}
```

**Gas Cost**: ~2,300 gas per `onlyOwner` check
**Pros**: Simple, battle-tested, clear ownership
**Cons**: Single point of failure, not suitable for complex permissions

**How it works:**
```solidity
// Simplified Ownable
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
```

### Method 2: Role-Based Access Control (OpenZeppelin)

Multi-role system for complex permission structures.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleBasedToken is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    bool public paused;

    constructor() {
        // Grant deployer all roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    // Only minters can mint
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(!paused, "Contract paused");
        totalSupply += amount;
        balances[to] += amount;
    }

    // Only burners can burn
    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        require(balances[from] >= amount, "Insufficient balance");
        totalSupply -= amount;
        balances[from] -= amount;
    }

    // Only pausers can pause
    function pause() public onlyRole(PAUSER_ROLE) {
        paused = true;
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        paused = false;
    }

    // Admin can grant/revoke roles
    function grantMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }
}
```

**Gas Cost**: ~24,000 gas per role grant, ~2,800 gas per role check
**Pros**: Flexible, multiple roles, granular permissions, role delegation
**Cons**: More complex, higher gas costs, requires careful role management

### Method 3: Custom Access Control with Time Locks

Combining access control with time-delayed execution for critical functions.

```solidity
pragma solidity ^0.8.0;

contract TimeLockAccess {
    address public owner;
    address public pendingOwner;
    uint256 public transferInitiated;
    uint256 public constant TIMELOCK_DURATION = 2 days;

    mapping(address => bool) public admins;
    mapping(bytes32 => uint256) public timelocks;

    event OwnershipTransferInitiated(address indexed newOwner, uint256 effectiveTime);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "Not admin");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Initiate ownership transfer with timelock
    function initiateOwnershipTransfer(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        pendingOwner = newOwner;
        transferInitiated = block.timestamp;
        emit OwnershipTransferInitiated(newOwner, block.timestamp + TIMELOCK_DURATION);
    }

    // Complete ownership transfer after timelock
    function completeOwnershipTransfer() public {
        require(msg.sender == pendingOwner, "Not pending owner");
        require(block.timestamp >= transferInitiated + TIMELOCK_DURATION, "Timelock not expired");

        address previousOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);
        transferInitiated = 0;

        emit OwnershipTransferred(previousOwner, owner);
    }

    // Cancel pending transfer
    function cancelOwnershipTransfer() public onlyOwner {
        pendingOwner = address(0);
        transferInitiated = 0;
    }

    // Admin management
    function addAdmin(address admin) public onlyOwner {
        require(admin != address(0), "Invalid address");
        admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) public onlyOwner {
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    // Critical function with timelock
    function criticalOperation(bytes memory data) public onlyOwner {
        bytes32 operationId = keccak256(data);

        if (timelocks[operationId] == 0) {
            // First call - set timelock
            timelocks[operationId] = block.timestamp;
            return;
        }

        // Second call - check timelock expired
        require(block.timestamp >= timelocks[operationId] + TIMELOCK_DURATION, "Timelock not expired");

        // Execute critical operation
        timelocks[operationId] = 0; // Reset
        // ... actual operation ...
    }
}
```

**Gas Cost**: ~30,000-50,000 gas for timelock operations
**Pros**: Maximum security for sensitive operations, time to detect malicious changes
**Cons**: Complex, requires two transactions, delays legitimate operations

## Common Vulnerabilities

### 1. Function Visibility Issues

```solidity
// INSECURE - Old Solidity
contract VisibilityBug {
    uint256 balance;

    // Missing visibility = public (pre-0.5.0)
    function withdraw() {
        msg.sender.call{value: balance}("");
        balance = 0;
    }
}

// SECURE
contract VisibilityFixed {
    uint256 private balance;

    function withdraw() external {
        msg.sender.call{value: balance}("");
        balance = 0;
    }
}
```

### 2. Unprotected Initializers

```solidity
// INSECURE - Proxy pattern
contract ProxyVulnerable {
    address public owner;
    bool public initialized;

    // Anyone can call if not initialized!
    function initialize(address _owner) public {
        require(!initialized, "Already initialized");
        owner = _owner;
        initialized = true;
    }
}

// SECURE - Use initializer modifier
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ProxySecure is Initializable {
    address public owner;

    function initialize(address _owner) public initializer {
        owner = _owner;
    }
}
```

### 3. Delegate Call to User-Controlled Address

```solidity
// INSECURE
contract DelegateVuln {
    address public owner;

    function execute(address target, bytes memory data) public {
        // Anyone can delegatecall to modify storage!
        target.delegatecall(data);
    }
}

// SECURE - Whitelist or owner-only
contract DelegateSecure {
    address public owner;
    mapping(address => bool) public allowedTargets;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function execute(address target, bytes memory data) public onlyOwner {
        require(allowedTargets[target], "Target not allowed");
        target.delegatecall(data);
    }
}
```

## Real-World Examples

| Incident | Date | Amount Lost | Vulnerability Type |
|----------|------|-------------|-------------------|
| **Rubixi** | 2016 | $1M+ | Incorrect constructor name |
| **Parity Wallet** | Nov 2017 | $280M frozen | Unprotected initializer |
| **Poly Network** | Aug 2021 | $611M (returned) | Missing access control on critical function |
| **Compound** | Sept 2021 | $90M at risk | Governance access control bug |
| **Uranium Finance** | Apr 2021 | $50M | Missing access control on migration |

**Rubixi Case Study:**
```solidity
// Original vulnerable code
contract Rubixi {
    address private creator;

    // Intended as constructor but typo in contract name!
    function DynamicPyramid() public {
        creator = msg.sender;
    }

    function collectFees() public {
        require(msg.sender == creator);
        creator.transfer(address(this).balance);
    }
}

// Attack: Anyone called DynamicPyramid() and became creator
```

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract AccessControlTest is Test {
    VulnerableToken public vulnerable;
    SecureToken public secure;
    address public owner;
    address public attacker;

    function setUp() public {
        owner = address(this);
        attacker = address(0x1234);

        vulnerable = new VulnerableToken();
        secure = new SecureToken();
    }

    function testVulnerableTokenAttack() public {
        // Attacker can mint without permission
        vm.prank(attacker);
        vulnerable.mint(attacker, 1000000);

        assertEq(vulnerable.balances(attacker), 1000000);
        console.log("Vulnerability: Attacker minted tokens");
    }

    function testVulnerableOwnershipTakeover() public {
        // Attacker can steal ownership
        vm.prank(attacker);
        vulnerable.setOwner(attacker);

        assertEq(vulnerable.owner(), attacker);
        console.log("Vulnerability: Attacker stole ownership");
    }

    function testSecureTokenProtection() public {
        // Attacker cannot mint
        vm.prank(attacker);
        vm.expectRevert("Ownable: caller is not the owner");
        secure.mint(attacker, 1000000);

        assertEq(secure.balances(attacker), 0);
        console.log("Protection: Mint attempt blocked");
    }

    function testRoleBasedAccess() public {
        RoleBasedToken rbToken = new RoleBasedToken();

        // Grant minter role
        rbToken.grantMinterRole(attacker);

        // Attacker can now mint (authorized)
        vm.prank(attacker);
        rbToken.mint(attacker, 1000);
        assertEq(rbToken.balances(attacker), 1000);

        // Revoke role
        rbToken.revokeMinterRole(attacker);

        // Attacker cannot mint anymore
        vm.prank(attacker);
        vm.expectRevert();
        rbToken.mint(attacker, 1000);
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Access Control Security Tests", function () {
  let vulnerable, secure, owner, attacker;

  beforeEach(async function () {
    [owner, attacker] = await ethers.getSigners();

    const VulnerableToken = await ethers.getContractFactory("VulnerableToken");
    vulnerable = await VulnerableToken.deploy();

    const SecureToken = await ethers.getContractFactory("SecureToken");
    secure = await SecureToken.deploy();
  });

  it("Should demonstrate missing access control", async function () {
    // Attacker can mint tokens
    await vulnerable.connect(attacker).mint(attacker.address, ethers.parseEther("1000000"));

    const balance = await vulnerable.balances(attacker.address);
    expect(balance).to.equal(ethers.parseEther("1000000"));
    console.log("Vulnerability: Unauthorized minting successful");
  });

  it("Should prevent unauthorized minting in secure contract", async function () {
    await expect(
      secure.connect(attacker).mint(attacker.address, ethers.parseEther("1000"))
    ).to.be.revertedWith("Ownable: caller is not the owner");

    console.log("Protection: Unauthorized minting blocked");
  });

  it("Should test role-based access control", async function () {
    const RoleBasedToken = await ethers.getContractFactory("RoleBasedToken");
    const rbToken = await RoleBasedToken.deploy();

    // Should fail without role
    await expect(
      rbToken.connect(attacker).mint(attacker.address, 1000)
    ).to.be.reverted;

    // Grant role
    await rbToken.grantMinterRole(attacker.address);

    // Should succeed with role
    await rbToken.connect(attacker).mint(attacker.address, 1000);
    expect(await rbToken.balances(attacker.address)).to.equal(1000);
  });
});
```

### Static Analysis

```bash
# Slither detection
slither . --detect unprotected-upgrade,suicidal,arbitrary-send

# Check for access control issues
slither . --detect missing-zero-check,locked-ether

# Mythril
myth analyze contracts/VulnerableToken.sol --solv 0.8.0
```

## Checklist

- [ ] All sensitive functions have access control modifiers
- [ ] Ownership transfer includes two-step verification
- [ ] Function visibility explicitly declared (external/public/internal/private)
- [ ] Constructor properly defined (not function with contract name)
- [ ] Initializers protected in upgradeable contracts
- [ ] Role-based access control for multi-permission systems
- [ ] Critical functions include timelock delays
- [ ] Zero address checks on all address parameters
- [ ] Access control events emitted for transparency
- [ ] Tests verify unauthorized access is blocked
- [ ] Admin functions cannot be called by regular users
- [ ] Default admin role properly configured
- [ ] Static analysis tools executed
- [ ] Multi-sig considered for critical operations
- [ ] Access control documented in NatSpec comments

## Additional Resources

**Documentation:**
- [OpenZeppelin Ownable](https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable)
- [OpenZeppelin AccessControl](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl)
- [OpenZeppelin Ownable2Step](https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable2Step)

**Guides:**
- [Access Control Best Practices](https://docs.openzeppelin.com/contracts/4.x/access-control)
- [SWC-105: Unprotected Ether Withdrawal](https://swcregistry.io/docs/SWC-105)
- [SWC-106: Unprotected SELFDESTRUCT](https://swcregistry.io/docs/SWC-106)

**Tools:**
- [Slither Access Control Detectors](https://github.com/crytic/slither)
- [Defender Admin](https://docs.openzeppelin.com/defender/admin)

---

**Last Updated**: November 2025
**Severity**: Critical
**OWASP Category**: [A5: Broken Access Control](https://owasp.org/www-project-smart-contract-top-10/)
