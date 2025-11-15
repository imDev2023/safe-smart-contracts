# Denial of Service (DoS) Attacks

## What It Is
Denial of Service attacks prevent legitimate users from accessing contract functionality by exploiting vulnerabilities like unexpected reverts, gas limit exhaustion, or block stuffing. These attacks don't necessarily steal funds but render contracts unusable, breaking critical business logic and causing economic damage.

## Why It Matters
DoS attacks are extremely common and can completely halt protocol operations. Auction contracts, payment systems, governance mechanisms, and withdrawal functions are frequent targets. Unlike traditional DoS attacks that flood servers, blockchain DoS exploits immutable contract logic flaws that can permanently brick contracts. The economic impact includes locked funds, missed liquidations, failed auctions, and complete protocol shutdown.

## Vulnerable Code Example

### Example 1: DoS with Revert

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableAuction {
    address public highestBidder;
    uint256 public highestBid;

    function bid() public payable {
        require(msg.value > highestBid, "Bid too low");

        // VULNERABILITY: Refund can be blocked by malicious contract
        if (highestBidder != address(0)) {
            // If this fails, entire function reverts
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}

// Attacker contract
contract MaliciousContract {
    VulnerableAuction auction;

    constructor(address _auction) {
        auction = VulnerableAuction(_auction);
    }

    function attack() public payable {
        auction.bid{value: msg.value}();
    }

    // Reject all payments - DoS the auction!
    receive() external payable {
        revert("I refuse payment!");
    }
}
```

### Example 2: Gas Limit DoS

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract VulnerableDistribution {
    address[] public recipients;
    mapping(address => uint256) public balances;

    function addRecipient(address recipient) public {
        recipients.push(recipient);
    }

    // VULNERABILITY: Unbounded loop can exceed gas limit
    function distributeRewards() public {
        uint256 reward = address(this).balance / recipients.length;

        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(reward);
        }
    }

    // VULNERABILITY: Attacker fills array with many addresses
    function attackBySpamming() public {
        for (uint256 i = 0; i < 1000; i++) {
            recipients.push(address(uint160(i)));
        }
        // Now distributeRewards() will run out of gas!
    }
}
```

### Example 3: Block Stuffing (Suppression Attack)

```solidity
// INSECURE - Time-sensitive operations vulnerable
pragma solidity ^0.8.0;

contract VulnerableTimedAuction {
    uint256 public auctionEnd;
    address public winner;
    uint256 public highestBid;

    constructor() {
        auctionEnd = block.timestamp + 1 hours;
    }

    function bid() public payable {
        require(block.timestamp < auctionEnd, "Auction ended");
        require(msg.value > highestBid, "Bid too low");

        winner = msg.sender;
        highestBid = msg.value;
    }

    function claimVictory() public {
        // VULNERABILITY: Can be blocked by stuffing blocks
        require(block.timestamp >= auctionEnd, "Auction not ended");
        require(msg.sender == winner, "Not winner");
        // Transfer prize
    }
}
```

## The Attack Scenario

**DoS with Revert Attack:**

1. **Setup**: Attacker deploys malicious contract with reverting fallback
2. **Initial Bid**: Attacker becomes highest bidder through malicious contract
3. **DoS Trigger**: Any subsequent bid attempts to refund attacker
4. **Revert**: Malicious fallback rejects payment, reverting entire transaction
5. **Lock**: No one can bid higher; auction is permanently stuck
6. **Victory**: Attacker wins by default when auction ends

**Numerical Example:**
```
Initial State:
- Highest Bid: 1 ETH (legitimate user)
- Auction Prize Value: 100 ETH

Attack Execution:
1. Attacker bids 2 ETH via malicious contract
2. Malicious contract becomes highest bidder
3. Next user tries to bid 3 ETH
4. Contract attempts: transfer 2 ETH to attacker
5. Attacker's receive() reverts: "I refuse payment!"
6. Entire bid() transaction reverts
7. No one can bid higher than attacker's 2 ETH

Final Outcome:
- Attacker wins 100 ETH prize for only 2 ETH
- Attack profit: 98 ETH
- Legitimate users locked out
```

## Prevention Methods

### Method 1: Pull Payment Pattern

Never push payments; let users withdraw themselves.

```solidity
pragma solidity ^0.8.0;

contract SecureAuction {
    address public highestBidder;
    uint256 public highestBid;

    // Pending withdrawals instead of direct transfers
    mapping(address => uint256) public pendingReturns;

    function bid() public payable {
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            // SAFE: Don't transfer, just mark for withdrawal
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // Users withdraw their refunds themselves
    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**Gas Cost**: No overhead for bid(), ~21,000 gas for withdraw()
**Pros**: Cannot be DoS'd, user controls timing
**Cons**: Requires separate withdrawal transaction

### Method 2: Bounded Iterations

Limit loop size or use pagination.

```solidity
pragma solidity ^0.8.0;

contract SafeDistribution {
    address[] public recipients;
    mapping(address => uint256) public pendingRewards;
    uint256 public lastProcessedIndex;

    uint256 public constant MAX_BATCH_SIZE = 50;

    function addRecipient(address recipient) public {
        require(recipients.length < 1000, "Too many recipients");
        recipients.push(recipient);
    }

    // Process in batches to avoid gas limit
    function distributeRewardsBatch(uint256 batchSize) public {
        require(batchSize <= MAX_BATCH_SIZE, "Batch too large");

        uint256 endIndex = lastProcessedIndex + batchSize;
        if (endIndex > recipients.length) {
            endIndex = recipients.length;
        }

        uint256 reward = 1 ether; // Example reward

        for (uint256 i = lastProcessedIndex; i < endIndex; i++) {
            pendingRewards[recipients[i]] += reward;
        }

        lastProcessedIndex = endIndex;

        // Reset if complete
        if (lastProcessedIndex >= recipients.length) {
            lastProcessedIndex = 0;
        }
    }

    function withdraw() public {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards");

        pendingRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
```

**Gas Cost**: Predictable, capped by MAX_BATCH_SIZE
**Pros**: Prevents gas limit DoS, scalable
**Cons**: Multiple transactions needed, more complex

### Method 3: Circuit Breaker (Emergency Stop)

Pause contract functionality when attacks detected.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CircuitBreakerAuction is Pausable, Ownable {
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;

    uint256 public failedTransferCount;
    uint256 public constant MAX_FAILED_TRANSFERS = 5;

    function bid() public payable whenNotPaused {
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() public whenNotPaused {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds");

        pendingReturns[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            // Restore balance on failure
            pendingReturns[msg.sender] = amount;
            failedTransferCount++;

            // Auto-pause if too many failures (potential attack)
            if (failedTransferCount >= MAX_FAILED_TRANSFERS) {
                _pause();
            }
        } else {
            failedTransferCount = 0; // Reset on success
        }
    }

    // Owner can pause/unpause
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
        failedTransferCount = 0;
    }
}
```

**Gas Cost**: ~2,400 gas overhead for pausable checks
**Pros**: Emergency response capability, attack mitigation
**Cons**: Centralized control, can be abused by owner

### Method 4: Gas-Efficient Withdrawal with Mapping

Avoid arrays entirely for withdrawals.

```solidity
pragma solidity ^0.8.0;

contract MappingOnlyDistribution {
    mapping(address => uint256) public balances;
    mapping(address => bool) public isRecipient;
    uint256 public recipientCount;

    function addRecipient(address recipient) public {
        require(!isRecipient[recipient], "Already a recipient");

        isRecipient[recipient] = true;
        recipientCount++;
    }

    // No loops - just set individual balances
    function allocateReward(address recipient, uint256 amount) public {
        require(isRecipient[recipient], "Not a recipient");
        balances[recipient] += amount;
    }

    // Pull payment - no DoS risk
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
```

**Gas Cost**: O(1) - constant regardless of recipient count
**Pros**: No gas limit issues, simple, efficient
**Cons**: Requires different allocation mechanism

## Real-World Examples

| Incident | Date | Impact | Attack Type |
|----------|------|--------|-------------|
| **GovernMental** | 2016 | 1,100 ETH locked | Gas limit DoS via unbounded loop |
| **Fomo3D** | 2018 | Game won unfairly | Block stuffing suppression |
| **King of Ether** | 2016 | Contract bricked | DoS with revert |
| **Various ICOs** | 2017-2018 | Multiple | Block stuffing during sales |

**Fomo3D Block Stuffing Details:**
- Attacker stuffed 13 consecutive blocks with high-gas transactions
- Each block: 7.9M gas consumed by attacker
- Prevented anyone from calling `buyKey()` (300K+ gas needed)
- Won jackpot by preventing timer extension
- Attack cost: ~$60K in gas
- Prize won: $3M+

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract DoSTest is Test {
    VulnerableAuction public vulnerable;
    SecureAuction public secure;
    MaliciousContract public attacker;

    function setUp() public {
        vulnerable = new VulnerableAuction();
        secure = new SecureAuction();
    }

    function testDoSWithRevert() public {
        // Deploy attacker
        attacker = new MaliciousContract(address(vulnerable));

        // Attacker bids
        attacker.attack{value: 1 ether}();
        assertEq(vulnerable.highestBidder(), address(attacker));

        // Legitimate user tries to bid higher
        vm.deal(address(this), 2 ether);
        vm.expectRevert("I refuse payment!");
        vulnerable.bid{value: 2 ether}();

        console.log("DoS successful - auction locked");
    }

    function testSecureAuctionPullPayment() public {
        // Attacker bids
        attacker = new MaliciousContract(address(secure));
        attacker.attack{value: 1 ether}();

        // Legitimate user can still bid!
        vm.deal(address(this), 2 ether);
        secure.bid{value: 2 ether}();

        assertEq(secure.highestBidder(), address(this));
        console.log("Protection works - auction continues");

        // Attacker can withdraw refund
        uint256 pending = secure.pendingReturns(address(attacker));
        assertEq(pending, 1 ether);
    }

    function testGasLimitDoS() public {
        VulnerableDistribution dist = new VulnerableDistribution();

        // Add many recipients
        for (uint256 i = 0; i < 300; i++) {
            dist.addRecipient(address(uint160(i)));
        }

        // Distribution runs out of gas
        vm.deal(address(dist), 100 ether);
        vm.expectRevert(); // Out of gas
        dist.distributeRewards();

        console.log("Gas limit DoS successful");
    }

    function testBoundedIteration() public {
        SafeDistribution safeDist = new SafeDistribution();

        // Add many recipients
        for (uint256 i = 0; i < 300; i++) {
            safeDist.addRecipient(address(uint160(i)));
        }

        // Can process in batches
        vm.deal(address(safeDist), 100 ether);

        uint256 batches = 0;
        while (safeDist.lastProcessedIndex() < 300 || batches == 0) {
            safeDist.distributeRewardsBatch(50);
            batches++;
            if (batches > 10) break; // Safety
        }

        console.log("Processed in", batches, "batches");
        assertGt(batches, 1);
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DoS Attack Tests", function () {
  it("Should demonstrate DoS with revert", async function () {
    const [owner, user] = await ethers.getSigners();

    const VulnerableAuction = await ethers.getContractFactory("VulnerableAuction");
    const auction = await VulnerableAuction.deploy();

    const MaliciousContract = await ethers.getContractFactory("MaliciousContract");
    const attacker = await MaliciousContract.deploy(await auction.getAddress());

    // Attacker bids
    await attacker.attack({ value: ethers.parseEther("1") });

    // User tries to bid - should fail
    await expect(
      auction.connect(user).bid({ value: ethers.parseEther("2") })
    ).to.be.revertedWith("I refuse payment!");

    console.log("DoS attack successful");
  });

  it("Should test pull payment protection", async function () {
    const [owner, user] = await ethers.getSigners();

    const SecureAuction = await ethers.getContractFactory("SecureAuction");
    const auction = await SecureAuction.deploy();

    // First bid
    await auction.bid({ value: ethers.parseEther("1") });

    // Second bid succeeds even if first bidder would revert
    await auction.connect(user).bid({ value: ethers.parseEther("2") });

    // First bidder can withdraw
    const pending = await auction.pendingReturns(owner.address);
    expect(pending).to.equal(ethers.parseEther("1"));

    await auction.withdraw();
    console.log("Pull payment successful");
  });
});
```

## Checklist

- [ ] Pull payment pattern used instead of push
- [ ] All loops have bounded size or use pagination
- [ ] No external calls in loops
- [ ] Circuit breaker / pause mechanism implemented
- [ ] Gas limit considered for all batch operations
- [ ] Failed transfers don't revert entire transaction
- [ ] No reliance on single transaction completing
- [ ] Time-sensitive operations have extended windows
- [ ] Block stuffing impact assessed
- [ ] Fallback functions cannot DoS other contracts
- [ ] Emergency withdrawal mechanism exists
- [ ] Tests include gas limit scenarios
- [ ] Array sizes limited or avoided
- [ ] Critical functionality not dependent on arrays

## Additional Resources

**Documentation:**
- [ConsenSys Best Practices - DoS](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/)
- [OpenZeppelin Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
- [Pull Payment Pattern](https://docs.openzeppelin.com/contracts/4.x/api/security#PullPayment)

**Security:**
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)
- [SWC-128: DoS with Block Gas Limit](https://swcregistry.io/docs/SWC-128)

**Case Studies:**
- [Fomo3D Block Stuffing Analysis](https://solmaz.io/2018/10/18/anatomy-block-stuffing/)
- [King of Ether Postmortem](https://www.kingoftheether.com/postmortem.html)

---

**Last Updated**: November 2025
**Severity**: High
**OWASP Category**: [A9: Denial of Service](https://owasp.org/www-project-smart-contract-top-10/)
