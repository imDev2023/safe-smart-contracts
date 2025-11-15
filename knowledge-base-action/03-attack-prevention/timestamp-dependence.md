# Timestamp Dependence

## What It Is
Timestamp dependence occurs when smart contracts rely on `block.timestamp` for critical logic like randomness generation, access control, or time-sensitive operations. Validators can manipulate timestamps within certain bounds, and using timestamps for randomness is fundamentally insecure since they're predictable and controllable.

## Why It Matters
While timestamp manipulation is less severe post-Ethereum Merge (Proof of Stake), timestamps can still vary by several seconds between validators. Historic exploits of timestamp-based randomness led to lottery and gambling contract hacks. The predictability of `block.timestamp` makes it unsuitable for any scenario requiring true randomness or precise timing. Note: This vulnerability is significantly reduced on modern Ethereum post-merge.

## Vulnerable Code Example

### Example 1: Randomness from Timestamp

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableLottery {
    address[] public players;
    uint256 public lotteryEnd;

    constructor() {
        lotteryEnd = block.timestamp + 1 days;
    }

    function enter() public payable {
        require(msg.value == 0.1 ether, "Entry fee is 0.1 ETH");
        require(block.timestamp < lotteryEnd, "Lottery ended");
        players.push(msg.sender);
    }

    // VULNERABILITY: Timestamp-based randomness
    function pickWinner() public {
        require(block.timestamp >= lotteryEnd, "Lottery not ended");
        require(players.length > 0, "No players");

        // Predictable and manipulable!
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp,  // Validator can control
            block.difficulty, // Now constant post-merge
            players.length
        ))) % players.length;

        address winner = players[randomIndex];
        payable(winner).transfer(address(this).balance);

        delete players;
        lotteryEnd = block.timestamp + 1 days;
    }
}
```

### Example 2: Time-Based Access Control

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract VulnerableSale {
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public price;

    constructor() {
        // VULNERABILITY: Precise timing allows manipulation
        saleStart = block.timestamp + 1 hours;
        saleEnd = saleStart + 24 hours;
        price = 1 ether;
    }

    function purchase() public payable {
        // Validator can manipulate timestamp by ~12 seconds
        require(block.timestamp >= saleStart, "Sale not started");
        require(block.timestamp <= saleEnd, "Sale ended");
        require(msg.value == price, "Incorrect payment");

        // Transfer tokens
    }

    // VULNERABILITY: Validator can trigger early
    function emergencyEnd() public {
        require(block.timestamp > saleEnd + 1 hours, "Too early");
        // Refund remaining tokens
    }
}
```

### Example 3: Block Number Misuse as Time

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract VulnerableVesting {
    uint256 public vestingStart;
    uint256 public constant BLOCKS_PER_DAY = 7200; // Assumes 12s blocks

    constructor() {
        vestingStart = block.number;
    }

    // VULNERABILITY: Block times can change
    function calculateVested() public view returns (uint256) {
        uint256 blocksPassed = block.number - vestingStart;

        // Assumes constant 12-second blocks - can be wrong!
        uint256 daysPassed = blocksPassed / BLOCKS_PER_DAY;

        return daysPassed * 100 ether; // 100 tokens per day
    }
}
```

## The Attack Scenario

**Lottery Manipulation Attack:**

1. **Observation**: Attacker monitors lottery contract
2. **Calculation**: Predicts winner based on timestamp
3. **Wait**: Monitors pending blocks
4. **Manipulation** (if validator): Adjusts timestamp to win
5. **Exploitation** (if user): Enters only when they'll win
6. **Profit**: Wins rigged lottery

**Numerical Example:**
```
Lottery Setup:
- Prize pool: 10 ETH
- Entry fee: 0.1 ETH
- Players: 100 addresses
- End time: block.timestamp = 1700000000

Attack Calculation:
1. Attacker calculates for each possible timestamp:
   - timestamp 1700000000: winner = players[42]
   - timestamp 1700000001: winner = players[17] (attacker!)
   - timestamp 1700000002: winner = players[88]

2. If attacker is validator:
   - Sets block.timestamp = 1700000001
   - Wins lottery

3. If attacker is not validator:
   - Enters lottery only in scenarios where they win
   - Uses multiple addresses to increase odds

Result:
- Attacker wins 10 ETH for 0.1 ETH entry
- Attack profit: 9.9 ETH
- Other players had no fair chance
```

## Prevention Methods

### Method 1: Chainlink VRF (Verifiable Random Function)

Use oracle-based provably fair randomness.

```solidity
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract SecureLottery is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    address[] public players;
    mapping(bytes32 => bool) public requestIds;

    constructor()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK
    }

    function enter() public payable {
        require(msg.value == 0.1 ether, "Entry fee is 0.1 ETH");
        players.push(msg.sender);
    }

    // Request randomness from Chainlink
    function pickWinner() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        requestId = requestRandomness(keyHash, fee);
        requestIds[requestId] = true;
    }

    // Callback from Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestIds[requestId], "Invalid request");

        randomResult = randomness;
        uint256 winnerIndex = randomness % players.length;
        address winner = players[winnerIndex];

        payable(winner).transfer(address(this).balance);
        delete players;
    }
}
```

**Gas Cost**: ~150,000 gas + LINK fee (~0.0001 LINK)
**Pros**: Provably fair, secure, verifiable
**Cons**: Requires LINK tokens, two-transaction process, oracle dependency

### Method 2: Commit-Reveal with Block Hash

Use future block hash for randomness (imperfect but better).

```solidity
pragma solidity ^0.8.0;

contract CommitRevealLottery {
    struct Commit {
        bytes32 commitment;
        uint256 blockNumber;
        bool revealed;
    }

    mapping(address => Commit) public commits;
    address[] public players;
    uint256 public revealDeadline;

    function commit(bytes32 commitment) public payable {
        require(msg.value == 0.1 ether, "Entry fee is 0.1 ETH");
        require(commits[msg.sender].commitment == 0, "Already committed");

        commits[msg.sender] = Commit({
            commitment: commitment,
            blockNumber: block.number,
            revealed: false
        });

        players.push(msg.sender);
    }

    function setRevealDeadline() public {
        require(players.length >= 10, "Need more players");
        require(revealDeadline == 0, "Already set");

        revealDeadline = block.number + 100; // ~20 minutes
    }

    function reveal(uint256 nonce) public {
        require(block.number >= revealDeadline, "Too early");
        require(block.number < revealDeadline + 256, "Too late");

        Commit storage userCommit = commits[msg.sender];
        require(userCommit.commitment != 0, "Not committed");
        require(!userCommit.revealed, "Already revealed");

        // Verify commitment
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce));
        require(hash == userCommit.commitment, "Invalid reveal");

        userCommit.revealed = true;
    }

    function pickWinner() public {
        require(block.number >= revealDeadline + 10, "Reveal period not ended");

        // Combine block hash with commits
        bytes32 entropy = blockhash(revealDeadline);

        for (uint256 i = 0; i < players.length; i++) {
            if (commits[players[i]].revealed) {
                entropy = keccak256(abi.encodePacked(entropy, commits[players[i]].commitment));
            }
        }

        uint256 winnerIndex = uint256(entropy) % players.length;
        address winner = players[winnerIndex];

        payable(winner).transfer(address(this).balance);

        // Reset
        for (uint256 i = 0; i < players.length; i++) {
            delete commits[players[i]];
        }
        delete players;
        revealDeadline = 0;
    }
}
```

**Gas Cost**: Moderate (~50,000 gas per participant)
**Pros**: No external dependency, harder to manipulate
**Cons**: Complex UX, vulnerable to last revealer attack, block hash only 256 blocks

### Method 3: Time Buffers for Time-Sensitive Operations

Add safety margins to timestamp checks.

```solidity
pragma solidity ^0.8.0;

contract SafeTimedSale {
    uint256 public saleStart;
    uint256 public saleEnd;

    // Add buffer to prevent edge-case manipulation
    uint256 public constant TIME_BUFFER = 15 seconds;

    constructor() {
        saleStart = block.timestamp + 1 hours;
        saleEnd = saleStart + 24 hours;
    }

    function purchase() public payable {
        // Use buffer to account for timestamp variation
        require(block.timestamp >= saleStart + TIME_BUFFER, "Sale not started");
        require(block.timestamp <= saleEnd - TIME_BUFFER, "Sale ended");

        // Safe within buffer zone
    }

    // Operations that can tolerate variation
    function checkExpiration() public view returns (bool) {
        // Acceptable for non-critical checks
        return block.timestamp > saleEnd;
    }
}
```

**Gas Cost**: Negligible
**Pros**: Simple, no dependencies
**Cons**: Only suitable when precision not critical

### Method 4: Block Number for Relative Time (Careful Use)

Use block numbers only when variation acceptable.

```solidity
pragma solidity ^0.8.0;

contract SafeBlockNumberVesting {
    uint256 public vestingStartBlock;

    // Don't assume exact block time - use for approximate durations
    uint256 public constant APPROX_BLOCKS_PER_WEEK = 50400; // ~12s blocks

    mapping(address => uint256) public allocation;
    mapping(address => uint256) public withdrawn;

    constructor() {
        vestingStartBlock = block.number;
    }

    function calculateVested(address beneficiary) public view returns (uint256) {
        uint256 blocksPassed = block.number - vestingStartBlock;

        // Calculate weeks (approximate)
        uint256 weeksPassed = blocksPassed / APPROX_BLOCKS_PER_WEEK;

        // Cap at allocation
        uint256 vested = weeksPassed * 100 ether;
        if (vested > allocation[beneficiary]) {
            vested = allocation[beneficiary];
        }

        return vested - withdrawn[beneficiary];
    }

    function withdraw() public {
        uint256 available = calculateVested(msg.sender);
        require(available > 0, "Nothing to withdraw");

        withdrawn[msg.sender] += available;
        payable(msg.sender).transfer(available);
    }
}
```

**Gas Cost**: Negligible
**Pros**: Simple, deterministic block counting
**Cons**: Block times can vary (8-20 seconds historically)

## Real-World Examples

| Incident | Date | Amount Lost | Issue |
|----------|------|-------------|-------|
| **Various Lotteries** | 2016-2017 | $50K+ | Timestamp randomness |
| **SmartBillions** | 2017 | Prevented | Weak randomness detected |
| **TheRun** | 2017 | Closed | Timestamp manipulation possible |

**Note**: Post-Ethereum Merge (Sept 2022), timestamp manipulation is significantly more limited. However, timestamps should still never be used for randomness.

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract TimestampTest is Test {
    VulnerableLottery public vulnerable;
    SecureLottery public secure;

    function setUp() public {
        vulnerable = new VulnerableLottery();
    }

    function testTimestampPredictability() public {
        // Enter lottery
        vm.deal(address(this), 1 ether);
        vulnerable.enter{value: 0.1 ether}();

        // Advance time
        vm.warp(block.timestamp + 1 days);

        // Predict winner before calling pickWinner
        uint256 predictedIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            uint256(1)
        ))) % 1;

        console.log("Predicted winner index:", predictedIndex);

        // Actually pick winner
        vulnerable.pickWinner();

        console.log("Timestamp-based randomness is predictable!");
    }

    function testTimestampManipulation() public {
        // Simulate validator manipulating timestamp
        vm.deal(address(this), 1 ether);
        vulnerable.enter{value: 0.1 ether}();

        vm.warp(block.timestamp + 1 days);

        // Try different timestamps to find winning one
        for (uint256 offset = 0; offset < 15; offset++) {
            vm.warp(block.timestamp + offset);

            uint256 index = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                uint256(1)
            ))) % 1;

            if (index == 0) {
                console.log("Found winning timestamp at offset:", offset);
                break;
            }
        }
    }

    function testTimeBufferProtection() public {
        SafeTimedSale sale = new SafeTimedSale();

        // Try to purchase immediately - should fail
        vm.expectRevert("Sale not started");
        sale.purchase{value: 1 ether}();

        // Advance to start time
        vm.warp(block.timestamp + 1 hours);

        // Still need buffer
        vm.expectRevert("Sale not started");
        sale.purchase{value: 1 ether}();

        // After buffer
        vm.warp(block.timestamp + 20 seconds);
        // Now would succeed (if purchase logic implemented)
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Timestamp Dependence Tests", function () {
  it("Should demonstrate timestamp predictability", async function () {
    const VulnerableLottery = await ethers.getContractFactory("VulnerableLottery");
    const lottery = await VulnerableLottery.deploy();

    await lottery.enter({ value: ethers.parseEther("0.1") });

    // Advance time
    await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
    await ethers.provider.send("evm_mine");

    // Timestamp is predictable in tests
    console.log("Timestamp-based randomness can be predicted");
  });

  it("Should test time buffer safety", async function () {
    const SafeSale = await ethers.getContractFactory("SafeTimedSale");
    const sale = await SafeSale.deploy();

    // Try immediate purchase - should fail
    await expect(
      sale.purchase({ value: ethers.parseEther("1") })
    ).to.be.revertedWith("Sale not started");

    console.log("Time buffer provides safety margin");
  });
});
```

## Checklist

- [ ] Never use `block.timestamp` for randomness
- [ ] Use Chainlink VRF or similar for random numbers
- [ ] Time-sensitive operations have buffer zones (±15 seconds)
- [ ] Block numbers not used as precise time measurements
- [ ] Commit-reveal for user-influenced randomness
- [ ] Time windows sufficiently large (>15 seconds)
- [ ] Tests simulate timestamp manipulation
- [ ] Critical logic doesn't depend on exact timing
- [ ] Post-merge timestamp behavior understood
- [ ] Alternative randomness sources evaluated
- [ ] Block hash randomness used carefully (256 block limit)
- [ ] Documentation warns about timestamp assumptions

## Additional Resources

**Documentation:**
- [Chainlink VRF](https://docs.chain.link/vrf/v2/introduction)
- [Solidity Timestamp](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties)
- [Ethereum Merge Impact](https://ethereum.stackexchange.com/a/140818)

**Security:**
- [SWC-116: Timestamp Dependence](https://swcregistry.io/docs/SWC-116)
- [ConsenSys - Timestamp Dependence](https://consensys.github.io/smart-contract-best-practices/attacks/timestamp-dependence/)

**Tools:**
- [Slither Timestamp Detector](https://github.com/crytic/slither)

---

**Last Updated**: November 2025
**Severity**: Medium (Post-merge), High (Pre-merge for randomness)
**OWASP Category**: [A8: Bad Randomness](https://owasp.org/www-project-smart-contract-top-10/)
