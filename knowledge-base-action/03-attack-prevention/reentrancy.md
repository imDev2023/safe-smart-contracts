# Reentrancy Attack

## What It Is
Reentrancy is a vulnerability that allows a malicious contract to recursively call back into a vulnerable contract before the first invocation completes, potentially draining funds or manipulating state. This occurs when external calls transfer control flow to untrusted contracts before updating critical state variables.

## Why It Matters
Reentrancy is the single most devastating attack vector in smart contract history. The DAO hack in 2016 resulted in $60M stolen (3.6M ETH at the time), leading to Ethereum's controversial hard fork into ETH and ETC. More recent attacks include Curve Finance reentrancy exploits and the Alchemix incident, collectively costing tens of millions of dollars.

## Vulnerable Code Example

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];

        // VULNERABILITY: External call before state update
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State update happens AFTER external call
        balances[msg.sender] = 0;
    }
}
```

**Attacker Contract:**
```solidity
contract ReentrancyAttacker {
    VulnerableBank public bank;
    uint256 public attackCount;

    constructor(address _bank) {
        bank = VulnerableBank(_bank);
    }

    function attack() external payable {
        require(msg.value >= 1 ether);
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // Fallback function exploits reentrancy
    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            attackCount++;
            bank.withdraw(); // Recursive call
        }
    }
}
```

## The Attack Scenario

**Step-by-step exploitation:**

1. **Setup**: Attacker deploys malicious contract with 1 ETH
2. **Initial Deposit**: Attacker calls `attack()`, depositing 1 ETH into VulnerableBank
3. **First Withdrawal**: Attacker calls `withdraw()`
4. **External Call**: Bank sends 1 ETH to attacker's contract
5. **Reentrancy Trigger**: Attacker's `receive()` function executes
6. **Recursive Call**: Before balance is zeroed, attacker calls `withdraw()` again
7. **Repeat**: Steps 4-6 repeat until bank is drained
8. **Final State**: Bank balance is 0, attacker has withdrawn multiple times

**Numerical Example:**
```
Initial State:
- Bank balance: 10 ETH (from other users)
- Attacker balance: 1 ETH deposited
- Attacker's balances[attacker]: 1 ETH

Attack Execution:
Call 1: withdraw() → send 1 ETH → balance still 1 ETH → reenter
Call 2: withdraw() → send 1 ETH → balance still 1 ETH → reenter
Call 3: withdraw() → send 1 ETH → balance still 1 ETH → reenter
...continues until bank.balance < 1 ETH

Final State:
- Bank balance: 0 ETH
- Attacker gained: 10 ETH (10x initial deposit)
```

## Prevention Methods

### Method 1: Checks-Effects-Interactions Pattern

The gold standard for reentrancy prevention. Always follow this order:
1. **Checks**: Validate conditions (require statements)
2. **Effects**: Update state variables
3. **Interactions**: Make external calls

```solidity
pragma solidity ^0.8.0;

contract SecureBank {
    mapping(address => uint256) public balances;

    function withdraw() public {
        // 1. CHECKS
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        // 2. EFFECTS - Update state BEFORE external call
        balances[msg.sender] = 0;

        // 3. INTERACTIONS - External call comes last
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**Gas Cost**: No additional cost (just reordering)
**Pros**: Zero overhead, best practice pattern
**Cons**: Requires careful code review, easy to miss

### Method 2: ReentrancyGuard (OpenZeppelin)

Use a mutex (mutual exclusion) lock to prevent recursive calls.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GuardedBank is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**Gas Cost**: ~2,100-2,400 gas overhead per function call
**Pros**: Easy to implement, explicit protection, works across functions
**Cons**: Small gas cost, still requires proper state management

**How it works:**
```solidity
// Simplified ReentrancyGuard implementation
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
```

### Method 3: Pull Payment Pattern

Instead of pushing funds to users, let them pull (withdraw) funds themselves.

```solidity
pragma solidity ^0.8.0;

contract PullPaymentBank {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public pendingWithdrawals;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Mark funds for withdrawal instead of sending immediately
    function initiateWithdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;
        pendingWithdrawals[msg.sender] += amount;
    }

    // Separate pull function
    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawal");

        pendingWithdrawals[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**Gas Cost**: Higher total (two transactions instead of one)
**Pros**: Maximum security, clear separation of concerns
**Cons**: Poor UX (requires two transactions), higher total gas

## Advanced Attack Vectors

### Cross-Function Reentrancy

Attacker exploits shared state between different functions:

```solidity
// INSECURE
contract CrossFunctionVulnerable {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount);
        balances[to] += amount;
        balances[msg.sender] -= amount;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] = 0; // Too late!
    }
}
```

**Attack**: During `withdraw()` callback, call `transfer()` to move already-withdrawn funds.

**Fix**: Apply `nonReentrant` to ALL functions sharing state:
```solidity
function transfer(address to, uint256 amount) public nonReentrant { ... }
function withdraw() public nonReentrant { ... }
```

### Read-Only Reentrancy

Attacker reenters a different contract that reads stale state:

```solidity
// Contract A - Has reentrancy guard
contract VaultA is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] = 0; // Updated AFTER callback
    }
}

// Contract B - Reads from A
contract RewardB {
    VaultA public vaultA;
    mapping(address => bool) public claimed;

    function claimReward() external {
        require(!claimed[msg.sender]);
        // Reads stale balance from VaultA during callback
        uint256 reward = vaultA.balances(msg.sender);
        claimed[msg.sender] = true;
        // Reward calculated on pre-withdrawal balance!
    }
}
```

**Fix**: Use Checks-Effects-Interactions even with ReentrancyGuard.

## Real-World Examples

| Incident | Date | Amount Lost | Attack Type |
|----------|------|-------------|-------------|
| **The DAO** | June 2016 | $60M (3.6M ETH) | Classic reentrancy |
| **Curve Finance** | July 2023 | $73M | Read-only reentrancy on Vyper compiler bug |
| **Lendf.Me** | April 2020 | $25M | ERC777 reentrancy hook |
| **Cream Finance** | Aug 2021 | $19M | Flash loan + reentrancy combo |
| **Alchemix** | June 2021 | $4.2M | Cross-contract reentrancy |

**The DAO Attack Details:**
- Exploited vulnerable `splitDAO` function
- Attacker called recursively 300+ times in a single transaction
- Led to Ethereum hard fork at block 1,920,000
- Created Ethereum Classic (ETC) as unforked chain

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract ReentrancyTest is Test {
    VulnerableBank public bank;
    ReentrancyAttacker public attacker;

    function setUp() public {
        bank = new VulnerableBank();
        attacker = new ReentrancyAttacker(address(bank));

        // Fund bank with victims' deposits
        vm.deal(address(1), 10 ether);
        vm.prank(address(1));
        bank.deposit{value: 10 ether}();
    }

    function testReentrancyAttack() public {
        uint256 bankBalanceBefore = address(bank).balance;
        uint256 attackerBalanceBefore = address(attacker).balance;

        // Execute attack
        vm.deal(address(attacker), 1 ether);
        attacker.attack{value: 1 ether}();

        // Assert bank was drained
        assertEq(address(bank).balance, 0);
        assertGt(address(attacker).balance, attackerBalanceBefore);

        console.log("Bank drained:", bankBalanceBefore);
        console.log("Attacker gained:", address(attacker).balance - attackerBalanceBefore);
    }

    function testSecureImplementation() public {
        SecureBank secureBank = new SecureBank();

        vm.deal(address(1), 10 ether);
        vm.prank(address(1));
        secureBank.deposit{value: 10 ether}();

        // Try to attack secure version
        ReentrancyAttacker secureAttacker = new ReentrancyAttacker(address(secureBank));
        vm.deal(address(secureAttacker), 1 ether);

        // Should only withdraw once
        secureAttacker.attack{value: 1 ether}();
        assertEq(address(secureAttacker).balance, 1 ether); // Only original amount
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy Attack Tests", function () {
  it("Should demonstrate reentrancy vulnerability", async function () {
    const [victim1, attacker] = await ethers.getSigners();

    // Deploy vulnerable bank
    const VulnerableBank = await ethers.getContractFactory("VulnerableBank");
    const bank = await VulnerableBank.deploy();

    // Victim deposits 10 ETH
    await bank.connect(victim1).deposit({ value: ethers.parseEther("10") });

    // Deploy attacker contract
    const Attacker = await ethers.getContractFactory("ReentrancyAttacker");
    const attackerContract = await Attacker.deploy(await bank.getAddress());

    // Execute attack with 1 ETH
    const attackTx = await attackerContract.attack({
      value: ethers.parseEther("1")
    });
    await attackTx.wait();

    // Bank should be drained
    expect(await ethers.provider.getBalance(bank.getAddress())).to.equal(0);
    console.log("Attack successful - bank drained");
  });
});
```

### Static Analysis Detection

```bash
# Slither detection
slither . --detect reentrancy-eth,reentrancy-no-eth,reentrancy-benign

# Mythril detection
myth analyze contracts/VulnerableBank.sol --solv 0.8.0
```

## Checklist

- [ ] All functions follow Checks-Effects-Interactions pattern
- [ ] `nonReentrant` modifier applied to functions with external calls
- [ ] State changes occur BEFORE external calls
- [ ] Cross-function reentrancy reviewed (shared state between functions)
- [ ] Read-only reentrancy considered (contracts reading your state)
- [ ] Tests written simulating reentrancy attacks
- [ ] Static analysis tools (Slither, Mythril) executed
- [ ] Functions with external calls marked as "untrusted"
- [ ] Pull payment pattern considered for complex scenarios
- [ ] ERC777 hooks and callbacks reviewed
- [ ] `safeMint` and `safeTransfer` usage audited
- [ ] Code audited by security professionals

## Additional Resources

**Documentation:**
- [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)
- [Solidity Patterns - Checks Effects Interactions](https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)

**Historical Analysis:**
- [The DAO Hack Explained](http://hackingdistributed.com/2016/06/18/analysis-of-the-dao-exploit/)
- [List of Reentrancy Attacks](https://github.com/pcaversaccio/reentrancy-attacks)

**Tools:**
- [Slither Reentrancy Detection](https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities)
- [Echidna Fuzzing for Reentrancy](https://github.com/crytic/echidna)

---

**Last Updated**: November 2025
**Severity**: Critical
**OWASP Category**: [A1: Access Control](https://owasp.org/www-project-smart-contract-top-10/)
