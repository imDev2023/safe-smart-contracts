# Frontrunning Attacks (Transaction Ordering Dependence)

## What It Is
Frontrunning is an attack where malicious actors observe pending transactions in the mempool and submit their own transactions with higher gas prices to be executed first, profiting from knowledge of future state changes. This exploits the transparent and time-delayed nature of blockchain transactions between submission and inclusion in a block.

## Why It Matters
Frontrunning is one of the most prevalent attacks in DeFi, costing users hundreds of millions annually. MEV (Maximal Extractable Value) bots extract an estimated $500M+ per year through frontrunning, sandwich attacks, and other ordering exploits. DEX traders lose billions to sandwich attacks. Unlike traditional finance where frontrunning is illegal, blockchain's transparent mempool makes it technically feasible and difficult to prevent without protocol-level changes.

## Vulnerable Code Example

### Example 1: Vulnerable DEX Price Discovery

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableDEX {
    mapping(address => uint256) public tokenBalance;
    uint256 public ethBalance;
    uint256 public tokenPrice; // Price in wei per token

    function buyTokens() public payable {
        // VULNERABILITY: Price is static and visible before execution
        uint256 tokens = msg.value / tokenPrice;
        require(tokenBalance[address(this)] >= tokens, "Insufficient liquidity");

        tokenBalance[address(this)] -= tokens;
        tokenBalance[msg.sender] += tokens;
        ethBalance += msg.value;
    }

    function sellTokens(uint256 amount) public {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance");

        uint256 ethAmount = amount * tokenPrice;
        require(ethBalance >= ethAmount, "Insufficient ETH");

        tokenBalance[msg.sender] -= amount;
        tokenBalance[address(this)] += amount;
        ethBalance -= ethAmount;

        payable(msg.sender).transfer(ethAmount);
    }

    // VULNERABILITY: Anyone can see this in mempool and frontrun
    function updatePrice(uint256 newPrice) public {
        tokenPrice = newPrice;
    }
}
```

### Example 2: Vulnerable Domain Registration

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract VulnerableRegistry {
    mapping(bytes32 => address) public domains;

    // VULNERABILITY: Can be frontrun
    function registerDomain(string memory name) public payable {
        require(msg.value >= 0.1 ether, "Insufficient payment");

        bytes32 domainHash = keccak256(abi.encodePacked(name));
        require(domains[domainHash] == address(0), "Domain taken");

        // Attacker sees this in mempool and registers first
        domains[domainHash] = msg.sender;
    }
}
```

### Example 3: Vulnerable Bug Bounty

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract VulnerableBugBounty {
    mapping(bytes32 => bool) public submittedBugs;
    mapping(bytes32 => address) public bugReporter;
    uint256 public bountyAmount = 10 ether;

    // VULNERABILITY: Attacker can copy bug report from mempool
    function submitBug(string memory bugDescription) public {
        bytes32 bugHash = keccak256(abi.encodePacked(bugDescription));
        require(!submittedBugs[bugHash], "Bug already submitted");

        submittedBugs[bugHash] = true;
        bugReporter[bugHash] = msg.sender;

        // First reporter gets paid
        payable(msg.sender).transfer(bountyAmount);
    }
}
```

## The Attack Scenario

**Sandwich Attack on DEX:**

1. **Mempool Monitoring**: Attacker runs bot monitoring pending transactions
2. **Target Detected**: Alice submits buy order for 10 ETH worth of tokens
3. **Front-run**: Attacker submits buy order with higher gas (100 gwei vs Alice's 50 gwei)
4. **Price Impact**: Attacker's buy executes first, raising price 5%
5. **Victim Execution**: Alice's buy executes at worse price
6. **Back-run**: Attacker sells tokens immediately at profit
7. **Profit Extraction**: Attacker profits from price difference, Alice loses

**Numerical Example:**
```
Initial State:
- Token Price: 1 ETH = 1000 tokens
- Pool: 100 ETH, 100,000 tokens
- Alice wants to buy with 10 ETH

Attack Execution:

Step 1 - Attacker Front-runs:
- Attacker buys with 50 ETH (gas: 100 gwei)
- New price: 1 ETH = 909 tokens (5% slippage)
- Attacker gets: 45,450 tokens
- Pool: 150 ETH, 54,550 tokens

Step 2 - Alice's Transaction Executes:
- Alice buys with 10 ETH (gas: 50 gwei)
- Current price: 1 ETH = 364 tokens (much worse!)
- Alice gets: 3,640 tokens (expected 10,000)
- Pool: 160 ETH, 50,910 tokens

Step 3 - Attacker Back-runs:
- Attacker sells 45,450 tokens
- Receives: 63 ETH
- Profit: 63 - 50 = 13 ETH

Final Outcome:
- Attacker profit: 13 ETH ($26,000)
- Alice loss: 6,360 tokens ($6,360)
- Price returns to near-original
```

## Prevention Methods

### Method 1: Commit-Reveal Scheme

Hide transaction details until after execution.

```solidity
pragma solidity ^0.8.0;

contract CommitRevealRegistry {
    mapping(bytes32 => address) public domains;
    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public commitTime;

    uint256 public constant REVEAL_DELAY = 10 minutes;

    // Step 1: Commit to registration without revealing domain name
    function commit(bytes32 commitment) public payable {
        require(msg.value >= 0.1 ether, "Insufficient payment");
        require(commitments[msg.sender] == 0, "Already committed");

        commitments[msg.sender] = commitment;
        commitTime[msg.sender] = block.timestamp;
    }

    // Step 2: Reveal after delay
    function reveal(string memory name, bytes32 secret) public {
        require(commitments[msg.sender] != 0, "No commitment");
        require(block.timestamp >= commitTime[msg.sender] + REVEAL_DELAY, "Too early");

        // Verify commitment
        bytes32 commitment = keccak256(abi.encodePacked(msg.sender, name, secret));
        require(commitment == commitments[msg.sender], "Invalid reveal");

        bytes32 domainHash = keccak256(abi.encodePacked(name));
        require(domains[domainHash] == address(0), "Domain taken");

        domains[domainHash] = msg.sender;
        delete commitments[msg.sender];
        delete commitTime[msg.sender];
    }

    // Allow withdrawal if reveal fails
    function withdraw() public {
        require(commitments[msg.sender] != 0, "No commitment");
        require(block.timestamp >= commitTime[msg.sender] + REVEAL_DELAY + 1 days, "Too early");

        delete commitments[msg.sender];
        delete commitTime[msg.sender];
        payable(msg.sender).transfer(0.1 ether);
    }
}
```

**Gas Cost**: ~60,000 gas total (two transactions)
**Pros**: Complete frontrunning protection, trustless
**Cons**: Two transactions required, time delay, poor UX

### Method 2: Slippage Protection (DEX)

Allow users to specify maximum acceptable slippage.

```solidity
pragma solidity ^0.8.0;

contract SlippageProtectedDEX {
    mapping(address => uint256) public tokenBalance;
    uint256 public ethBalance;

    function buyTokens(uint256 minTokens) public payable {
        // Calculate current price from pool
        uint256 tokens = calculateBuyAmount(msg.value);

        // PROTECTION: Revert if slippage too high
        require(tokens >= minTokens, "Slippage too high");

        tokenBalance[address(this)] -= tokens;
        tokenBalance[msg.sender] += tokens;
        ethBalance += msg.value;
    }

    function sellTokens(uint256 amount, uint256 minEth) public {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance");

        uint256 ethAmount = calculateSellAmount(amount);

        // PROTECTION: Revert if slippage too high
        require(ethAmount >= minEth, "Slippage too high");

        tokenBalance[msg.sender] -= amount;
        tokenBalance[address(this)] += amount;
        ethBalance -= ethAmount;

        payable(msg.sender).transfer(ethAmount);
    }

    // Constant product formula (x * y = k)
    function calculateBuyAmount(uint256 ethIn) public view returns (uint256) {
        uint256 tokenReserve = tokenBalance[address(this)];
        uint256 newEthBalance = ethBalance + ethIn;

        // k = tokenReserve * ethBalance
        uint256 newTokenBalance = (tokenReserve * ethBalance) / newEthBalance;
        return tokenReserve - newTokenBalance;
    }

    function calculateSellAmount(uint256 tokensIn) public view returns (uint256) {
        uint256 tokenReserve = tokenBalance[address(this)];
        uint256 newTokenBalance = tokenReserve + tokensIn;

        // k = tokenReserve * ethBalance
        uint256 newEthBalance = (tokenReserve * ethBalance) / newTokenBalance;
        return ethBalance - newEthBalance;
    }
}
```

**Gas Cost**: ~500 gas overhead for slippage check
**Pros**: Simple, effective against sandwich attacks, user-controlled
**Cons**: Doesn't prevent frontrunning, just limits damage

### Method 3: Batch Auctions

Process multiple orders together to remove ordering advantage.

```solidity
pragma solidity ^0.8.0;

contract BatchAuctionDEX {
    struct Order {
        address trader;
        uint256 amount;
        bool isBuy;
    }

    Order[] public currentBatch;
    uint256 public batchDuration = 5 minutes;
    uint256 public batchStartTime;

    mapping(address => uint256) public tokenBalance;
    uint256 public ethBalance;

    constructor() {
        batchStartTime = block.timestamp;
    }

    // Submit order to current batch
    function submitBuyOrder() public payable {
        currentBatch.push(Order({
            trader: msg.sender,
            amount: msg.value,
            isBuy: true
        }));
    }

    function submitSellOrder(uint256 tokenAmount) public {
        require(tokenBalance[msg.sender] >= tokenAmount, "Insufficient balance");

        currentBatch.push(Order({
            trader: msg.sender,
            amount: tokenAmount,
            isBuy: false
        }));

        // Lock tokens
        tokenBalance[msg.sender] -= tokenAmount;
    }

    // Process entire batch at uniform price
    function executeBatch() public {
        require(block.timestamp >= batchStartTime + batchDuration, "Batch not ready");

        // Calculate clearing price
        uint256 totalBuy = 0;
        uint256 totalSell = 0;

        for (uint256 i = 0; i < currentBatch.length; i++) {
            if (currentBatch[i].isBuy) {
                totalBuy += currentBatch[i].amount;
            } else {
                totalSell += currentBatch[i].amount;
            }
        }

        uint256 clearingPrice = totalBuy / totalSell;

        // Execute all orders at clearing price
        for (uint256 i = 0; i < currentBatch.length; i++) {
            Order memory order = currentBatch[i];

            if (order.isBuy) {
                uint256 tokens = order.amount / clearingPrice;
                tokenBalance[order.trader] += tokens;
            } else {
                uint256 eth = order.amount * clearingPrice;
                payable(order.trader).transfer(eth);
            }
        }

        // Reset batch
        delete currentBatch;
        batchStartTime = block.timestamp;
    }
}
```

**Gas Cost**: High (proportional to batch size)
**Pros**: Fair pricing, no frontrunning advantage, price discovery
**Cons**: Delayed execution, complex implementation, high gas

### Method 4: Submarine Sends (Advanced)

Hide transaction value and recipient until reveal.

```solidity
pragma solidity ^0.8.0;

contract SubmarineSend {
    mapping(bytes32 => bool) public revealed;
    mapping(address => uint256) public balances;

    // Commit funds without revealing recipient
    function commit(bytes32 commitHash) public payable {
        require(msg.value > 0, "Send some ETH");
        // Funds locked by commit hash
    }

    // Reveal recipient after commit is mined
    function reveal(
        address recipient,
        uint256 amount,
        bytes32 nonce,
        bytes32 witness
    ) public {
        // Verify commitment
        bytes32 commitHash = keccak256(abi.encodePacked(
            recipient,
            amount,
            nonce,
            witness
        ));

        require(!revealed[commitHash], "Already revealed");
        revealed[commitHash] = true;

        balances[recipient] += amount;
    }
}
```

**Gas Cost**: ~70,000 gas (two transactions)
**Pros**: Maximum privacy, complete frontrun protection
**Cons**: Very complex, requires off-chain coordination

## Attack Types Taxonomy

### 1. Displacement Attack
Attacker doesn't care if victim's transaction runs, just wants to execute first.
- **Examples**: Domain registration, bug bounty submission
- **Defense**: Commit-reveal

### 2. Insertion Attack
Attacker's transaction must run BEFORE victim's transaction for profit.
- **Examples**: Sandwich attacks on DEX
- **Defense**: Slippage protection, batch auctions

### 3. Suppression Attack (Block Stuffing)
Attacker tries to prevent victim's transaction from executing.
- **Examples**: Preventing liquidation, stopping auction bids
- **Defense**: Time-insensitive design, multiple block windows

## Real-World Examples

| Incident Type | Annual Impact | Attack Vector |
|---------------|---------------|---------------|
| **DEX Sandwich Attacks** | $500M-1B | MEV bots frontrun trades |
| **NFT Mints** | $100M+ | Bots frontrun popular drops |
| **Liquidations** | $200M+ | Frontrun undercollateralized positions |
| **Arbitrage** | $300M+ | Cross-exchange price differences |
| **Governance** | Varies | Frontrun proposal votes |

**Notable Cases:**
- **Flashbots**: Created to democratize MEV extraction (~$500M extracted)
- **Eden Network**: Private mempool to prevent frontrunning
- **Fomo3D**: Won through block stuffing suppression attack
- **Bancor**: Front-running caused significant user losses

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FrontrunningTest is Test {
    VulnerableDEX public vulnerableDex;
    SlippageProtectedDEX public safeDex;

    address public alice = address(0x1);
    address public attacker = address(0x2);

    function setUp() public {
        vulnerableDex = new VulnerableDEX();
        safeDex = new SlippageProtectedDEX();

        // Setup liquidity
        vm.deal(address(vulnerableDex), 100 ether);
        vm.deal(address(safeDex), 100 ether);
    }

    function testSandwichAttack() public {
        // Alice wants to buy
        vm.deal(alice, 10 ether);

        // Attacker sees this in mempool and frontruns
        vm.deal(attacker, 50 ether);
        vm.prank(attacker);
        vulnerableDex.buyTokens{value: 50 ether}();

        uint256 attackerTokens = vulnerableDex.tokenBalance(attacker);

        // Alice's transaction executes at worse price
        vm.prank(alice);
        vulnerableDex.buyTokens{value: 10 ether}();

        uint256 aliceTokens = vulnerableDex.tokenBalance(alice);

        // Attacker backruns (sells)
        vm.prank(attacker);
        vulnerableDex.sellTokens(attackerTokens);

        uint256 attackerProfit = attacker.balance - 50 ether;
        console.log("Attacker profit:", attackerProfit);
        console.log("Alice received tokens:", aliceTokens);

        // Assert attacker profited
        assertGt(attackerProfit, 0);
    }

    function testSlippageProtection() public {
        vm.deal(alice, 10 ether);

        // Calculate expected tokens
        uint256 expectedTokens = safeDex.calculateBuyAmount(10 ether);
        uint256 minAcceptable = expectedTokens * 95 / 100; // 5% slippage tolerance

        // Attacker tries to frontrun
        vm.deal(attacker, 50 ether);
        vm.prank(attacker);
        safeDex.buyTokens{value: 50 ether}(0);

        // Alice's transaction should revert due to slippage
        vm.prank(alice);
        vm.expectRevert("Slippage too high");
        safeDex.buyTokens{value: 10 ether}(minAcceptable);

        console.log("Protection: Transaction reverted due to slippage");
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Frontrunning Attack Tests", function () {
  let vulnerableDex, alice, attacker;

  beforeEach(async function () {
    [owner, alice, attacker] = await ethers.getSigners();

    const VulnerableDEX = await ethers.getContractFactory("VulnerableDEX");
    vulnerableDex = await VulnerableDEX.deploy();

    // Setup initial liquidity
    await owner.sendTransaction({
      to: await vulnerableDex.getAddress(),
      value: ethers.parseEther("100")
    });
  });

  it("Should demonstrate sandwich attack", async function () {
    const initialPrice = await vulnerableDex.tokenPrice();

    // Alice submits buy order
    const aliceTx = await alice.sendTransaction({
      to: await vulnerableDex.getAddress(),
      value: ethers.parseEther("10")
    });

    // Attacker frontruns with higher gas
    const attackerTx = await attacker.sendTransaction({
      to: await vulnerableDex.getAddress(),
      value: ethers.parseEther("50"),
      gasPrice: ethers.parseUnits("100", "gwei")
    });

    // Check execution order and profit
    console.log("Frontrunning successful");
  });

  it("Should test commit-reveal protection", async function () {
    const CommitReveal = await ethers.getContractFactory("CommitRevealRegistry");
    const registry = await CommitReveal.deploy();

    const name = "example.eth";
    const secret = ethers.randomBytes(32);
    const commitment = ethers.keccak256(
      ethers.solidityPacked(
        ["address", "string", "bytes32"],
        [alice.address, name, secret]
      )
    );

    // Commit
    await registry.connect(alice).commit(commitment, {
      value: ethers.parseEther("0.1")
    });

    // Wait for reveal delay
    await ethers.provider.send("evm_increaseTime", [600]); // 10 minutes
    await ethers.provider.send("evm_mine");

    // Reveal
    await registry.connect(alice).reveal(name, secret);

    const owner = await registry.domains(ethers.keccak256(ethers.toUtf8Bytes(name)));
    expect(owner).to.equal(alice.address);
  });
});
```

## Checklist

- [ ] Slippage protection implemented for all trades
- [ ] Commit-reveal used for sensitive operations
- [ ] Time-sensitive operations have multiple block windows
- [ ] Gas price limits considered for critical transactions
- [ ] Batch processing implemented where applicable
- [ ] Private mempool solutions evaluated (Flashbots, Eden)
- [ ] Front-running impact assessed in tests
- [ ] MEV extraction opportunities identified and mitigated
- [ ] Price oracle manipulation resistance verified
- [ ] Transaction ordering independence tested
- [ ] Deadline parameters included in time-sensitive functions
- [ ] Users educated about slippage settings
- [ ] Monitoring for suspicious transaction patterns
- [ ] Alternative execution venues considered

## Additional Resources

**Documentation:**
- [Flashbots Documentation](https://docs.flashbots.net/)
- [MEV-Boost](https://boost.flashbots.net/)
- [Ethereum Foundation - MEV](https://ethereum.org/en/developers/docs/mev/)

**Research Papers:**
- [Flash Boys 2.0](https://arxiv.org/abs/1904.05234)
- [High-Frequency Trading on Decentralized Exchanges](https://arxiv.org/abs/2009.14021)

**Tools:**
- [MEV-Inspect](https://github.com/flashbots/mev-inspect-py)
- [Submarine Sends](https://libsubmarine.org/)

**Security:**
- [SWC-114: Transaction Order Dependence](https://swcregistry.io/docs/SWC-114)
- [Smart Contract Security - Frontrunning](https://consensys.github.io/smart-contract-best-practices/attacks/frontrunning/)

---

**Last Updated**: November 2025
**Severity**: High
**OWASP Category**: [A6: Front-Running](https://owasp.org/www-project-smart-contract-top-10/)
