# tx.origin Authentication Vulnerability

## What It Is
`tx.origin` is a global variable that returns the address that originally initiated the transaction, whereas `msg.sender` returns the immediate caller. Using `tx.origin` for authentication allows phishing attacks where malicious contracts trick legitimate users into calling vulnerable contracts, bypassing authorization checks because `tx.origin` still shows the user's address.

## Why It Matters
`tx.origin` vulnerabilities enable phishing attacks that can drain user wallets without direct compromise. Multiple wallet contracts have been exploited through this vector. The attack is particularly dangerous because it exploits user trust - victims willingly interact with malicious contracts thinking they're safe, while the malicious contract silently drains their authenticated contracts.

## Vulnerable Code Example

### Example 1: Wallet with tx.origin Auth

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // VULNERABILITY: Uses tx.origin for authorization
    function transfer(address payable to, uint256 amount) public {
        require(tx.origin == owner, "Not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}

// Malicious contract that exploits tx.origin
contract PhishingAttack {
    VulnerableWallet public target;
    address payable public attacker;

    constructor(address _target) {
        target = VulnerableWallet(_target);
        attacker = payable(msg.sender);
    }

    // Victim calls this thinking it's harmless
    function claimReward() public {
        // tx.origin = victim (passes the check!)
        // msg.sender = this contract
        target.transfer(attacker, address(target).balance);
    }

    receive() external payable {}
}
```

**Attack:** Attacker tricks wallet owner into calling `claimReward()`, draining their wallet.

### Example 2: Access Control with tx.origin

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract VulnerableVault {
    address public admin;
    mapping(address => uint256) public balances;

    constructor() {
        admin = msg.sender;
    }

    // VULNERABILITY: tx.origin bypassed through intermediate contract
    function emergencyWithdraw() public {
        require(tx.origin == admin, "Not admin");
        payable(admin).transfer(address(this).balance);
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}
```

## The Attack Scenario

**Phishing Attack Flow:**

1. **Setup**: Attacker deploys PhishingAttack contract
2. **Lure**: Attacker tricks victim (wallet owner) via fake airdrop/game
3. **Interaction**: Victim calls `claimReward()` on malicious contract
4. **Exploitation**: Inside claimReward():
   - `tx.origin` = victim's address (original transaction sender)
   - Malicious contract calls `target.transfer()`
   - Vulnerable wallet checks: `tx.origin == owner` ✓ PASSES
5. **Drain**: Wallet funds transferred to attacker
6. **Result**: Victim's wallet emptied without private key compromise

**Numerical Example:**
```
Initial State:
- VulnerableWallet balance: 100 ETH
- Owner: Alice (0xABCD)
- Attacker: Eve (0x1337)

Attack Execution:
1. Eve deploys PhishingAttack(VulnerableWallet address)
2. Eve sends Alice fake message: "Claim 10 ETH airdrop!"
3. Alice visits attacker's site and calls claimReward()

Transaction Call Stack:
Alice → PhishingAttack.claimReward()
        → VulnerableWallet.transfer(Eve, 100 ETH)

Inside VulnerableWallet.transfer():
- tx.origin = 0xABCD (Alice)
- msg.sender = 0x...PhishingAttack
- Check: tx.origin == owner → TRUE (Alice == Alice)
- Transfer succeeds!

Final State:
- VulnerableWallet balance: 0 ETH
- Eve's balance: 100 ETH
- Alice lost: 100 ETH
```

## Prevention Methods

### Method 1: Use msg.sender (Recommended)

Always use `msg.sender` for authorization checks.

```solidity
pragma solidity ^0.8.0;

contract SecureWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // SAFE: Uses msg.sender
    function transfer(address payable to, uint256 amount) public {
        require(msg.sender == owner, "Not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}
```

**Gas Cost**: Identical to tx.origin
**Pros**: Prevents phishing, standard practice
**Cons**: None

### Method 2: OpenZeppelin Ownable

Use battle-tested access control patterns.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SecureVault is Ownable {
    mapping(address => uint256) public balances;

    function emergencyWithdraw() public onlyOwner {
        // Uses msg.sender internally
        payable(owner()).transfer(address(this).balance);
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}
```

**Gas Cost**: ~2,300 gas overhead
**Pros**: Industry standard, well-tested, clear
**Cons**: Small gas overhead

### Method 3: Prevent Contract Calls

Explicitly reject calls from contracts (extreme measure).

```solidity
pragma solidity ^0.8.0;

contract OnlyEOA {
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Contracts not allowed");
        _;
    }

    function sensitiveFunction() public onlyEOA {
        // Only callable by externally owned accounts
        // Prevents contract-based attacks BUT limits composability
    }
}
```

**Gas Cost**: ~200 gas for check
**Pros**: Prevents contract interactions entirely
**Cons**: Breaks composability, not recommended for DeFi

### Method 4: Multi-Signature Verification

Require multiple authorization layers.

```solidity
pragma solidity ^0.8.0;

contract MultiSigSafe {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    mapping(bytes32 => mapping(address => bool)) public confirmations;
    mapping(bytes32 => uint256) public confirmationCount;

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length >= _required && _required > 0);

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(!isOwner[owner] && owner != address(0));

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    function submitTransaction(address to, uint256 value, bytes memory data)
        public
        returns (bytes32 txHash)
    {
        require(isOwner[msg.sender], "Not owner");

        txHash = keccak256(abi.encodePacked(to, value, data));

        if (!confirmations[txHash][msg.sender]) {
            confirmations[txHash][msg.sender] = true;
            confirmationCount[txHash]++;
        }

        if (confirmationCount[txHash] >= required) {
            (bool success,) = to.call{value: value}(data);
            require(success, "Transaction failed");
        }
    }

    function confirm(bytes32 txHash) public {
        require(isOwner[msg.sender], "Not owner");
        require(!confirmations[txHash][msg.sender], "Already confirmed");

        confirmations[txHash][msg.sender] = true;
        confirmationCount[txHash]++;
    }
}
```

**Gas Cost**: High (~100K+ gas for multi-sig)
**Pros**: Maximum security, prevents single-point compromise
**Cons**: Complex, expensive, slower UX

## tx.origin vs msg.sender Comparison

| Property | tx.origin | msg.sender |
|----------|-----------|------------|
| **Value** | Original transaction sender | Immediate caller |
| **Type** | address | address |
| **Constant?** | Yes (throughout call chain) | No (changes with each call) |
| **Authentication** | NEVER use | Always use |
| **Phishing Risk** | HIGH | None |
| **Call Stack** | Always EOA address | Can be contract or EOA |

**Example Call Chain:**
```
Alice → ContractA → ContractB → ContractC

In ContractC:
- tx.origin = Alice (always)
- msg.sender = ContractB (immediate caller)
```

## Real-World Examples

| Type | Impact | Attack Vector |
|------|--------|---------------|
| **Wallet Phishing** | Multiple incidents | tx.origin auth bypass |
| **DApp Exploits** | Varies | Malicious contract interactions |
| **Smart Contract Games** | Fund losses | Auth bypass via intermediary |

**Common Attack Pattern:**
1. Deploy "Free NFT Mint" contract
2. Mint function calls victim's wallet
3. tx.origin check passes (victim initiated)
4. Wallet drains funds to attacker

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract TxOriginTest is Test {
    VulnerableWallet public vulnerable;
    SecureWallet public secure;
    PhishingAttack public attack;

    address public alice = address(0xABCD);

    function setUp() public {
        vm.deal(alice, 100 ether);

        vm.prank(alice);
        vulnerable = new VulnerableWallet();
        vm.deal(address(vulnerable), 50 ether);

        vm.prank(alice);
        secure = new SecureWallet();
        vm.deal(address(secure), 50 ether);

        attack = new PhishingAttack(address(vulnerable));
    }

    function testTxOriginExploit() public {
        assertEq(address(vulnerable).balance, 50 ether);

        // Alice innocently calls the phishing contract
        vm.prank(alice);
        attack.claimReward();

        // Wallet drained!
        assertEq(address(vulnerable).balance, 0);
        console.log("Wallet drained via tx.origin exploit!");
    }

    function testMsgSenderProtection() public {
        assertEq(address(secure).balance, 50 ether);

        // Create phishing attack for secure wallet
        PhishingAttack secureAttack = new PhishingAttack(address(secure));

        // Alice calls phishing contract
        vm.prank(alice);
        vm.expectRevert("Not owner");
        secureAttack.claimReward();

        // Wallet protected!
        assertEq(address(secure).balance, 50 ether);
        console.log("msg.sender protection successful!");
    }

    function testCallChain() public {
        // Demonstrate tx.origin vs msg.sender in call chain
        assertEq(tx.origin, address(this));
        console.log("tx.origin:", tx.origin);
        console.log("msg.sender:", msg.sender);
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("tx.origin Vulnerability Tests", function () {
  let vulnerable, secure, attack, alice;

  beforeEach(async function () {
    [_, alice] = await ethers.getSigners();

    const VulnerableWallet = await ethers.getContractFactory("VulnerableWallet");
    vulnerable = await VulnerableWallet.connect(alice).deploy();

    const SecureWallet = await ethers.getContractFactory("SecureWallet");
    secure = await SecureWallet.connect(alice).deploy();

    // Fund wallets
    await alice.sendTransaction({
      to: await vulnerable.getAddress(),
      value: ethers.parseEther("50")
    });

    await alice.sendTransaction({
      to: await secure.getAddress(),
      value: ethers.parseEther("50")
    });

    const PhishingAttack = await ethers.getContractFactory("PhishingAttack");
    attack = await PhishingAttack.deploy(await vulnerable.getAddress());
  });

  it("Should demonstrate tx.origin phishing attack", async function () {
    const initialBalance = await ethers.provider.getBalance(await vulnerable.getAddress());

    // Alice calls malicious contract
    await attack.connect(alice).claimReward();

    const finalBalance = await ethers.provider.getBalance(await vulnerable.getAddress());
    expect(finalBalance).to.equal(0);
    expect(initialBalance).to.equal(ethers.parseEther("50"));

    console.log("Attack successful: wallet drained via tx.origin");
  });

  it("Should prevent attack with msg.sender", async function () {
    const PhishingAttack = await ethers.getContractFactory("PhishingAttack");
    const secureAttack = await PhishingAttack.deploy(await secure.getAddress());

    await expect(
      secureAttack.connect(alice).claimReward()
    ).to.be.revertedWith("Not owner");

    const balance = await ethers.provider.getBalance(await secure.getAddress());
    expect(balance).to.equal(ethers.parseEther("50"));

    console.log("Protection successful: msg.sender prevented attack");
  });
});
```

## Checklist

- [ ] Never use `tx.origin` for authorization
- [ ] All access control uses `msg.sender`
- [ ] OpenZeppelin Ownable or AccessControl used
- [ ] Multi-sig considered for high-value contracts
- [ ] Phishing scenarios tested
- [ ] Call chain behavior documented
- [ ] Static analysis run (Slither detects tx.origin)
- [ ] User education about phishing risks
- [ ] Contract interactions audited
- [ ] Alternative authentication methods evaluated
- [ ] No assumptions about caller being EOA

## Additional Resources

**Documentation:**
- [Solidity Security Considerations - tx.origin](https://docs.soliditylang.org/en/latest/security-considerations.html#tx-origin)
- [OpenZeppelin Access Control](https://docs.openzeppelin.com/contracts/4.x/access-control)

**Security:**
- [SWC-115: Authorization through tx.origin](https://swcregistry.io/docs/SWC-115)
- [ConsenSys Best Practices - tx.origin](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/tx-origin/)

**Tools:**
- [Slither tx.origin Detector](https://github.com/crytic/slither)

---

**Last Updated**: November 2025
**Severity**: High
**OWASP Category**: [A5: Improper Access Control](https://owasp.org/www-project-smart-contract-top-10/)
