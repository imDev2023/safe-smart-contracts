# Flash Loan Attacks

## What It Is
Flash loans allow borrowing massive amounts of cryptocurrency without collateral, with the requirement that the loan is repaid within the same transaction. Attackers exploit this to manipulate prices, drain liquidity pools, exploit governance vulnerabilities, and execute complex multi-step attacks that would be impossible without significant capital. The attack combines flash loans with vulnerabilities in price oracles, AMM mechanics, or business logic.

## Why It Matters
Flash loan attacks represent some of the largest DeFi hacks in history, collectively costing over $500M in 2020-2023. bZx lost $600K+ in February 2020, Harvest Finance lost $34M in October 2020, Cream Finance was exploited for $130M+, and Warp Finance lost $8M. These attacks don't require initial capital, making them accessible to any attacker with technical knowledge. They expose fundamental weaknesses in DeFi protocols, particularly around price oracle manipulation and reliance on spot prices.

## Vulnerable Code Example

### Example 1: Price Oracle Manipulation

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract VulnerableLending {
    IUniswapV2Pair public priceFeed;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    // VULNERABILITY: Uses spot price from single DEX
    function getPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = priceFeed.getReserves();
        // Spot price - easily manipulated!
        return (uint256(reserve1) * 1e18) / uint256(reserve0);
    }

    function borrow(uint256 amount) public {
        uint256 price = getPrice();
        uint256 collateralValue = (collateral[msg.sender] * price) / 1e18;

        // Uses manipulated price!
        require(collateralValue >= amount * 150 / 100, "Insufficient collateral");

        borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }

    function depositCollateral() public payable {
        collateral[msg.sender] += msg.value;
    }
}
```

### Example 2: Vulnerable AMM

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract SimpleAMM {
    uint256 public reserveA;
    uint256 public reserveB;

    // VULNERABILITY: No protection against flash loan manipulation
    function swap(uint256 amountAIn, uint256 minAmountBOut) public returns (uint256 amountBOut) {
        require(amountAIn > 0, "Invalid amount");

        // Constant product formula: x * y = k
        uint256 k = reserveA * reserveB;
        reserveA += amountAIn;
        amountBOut = reserveB - (k / reserveA);

        require(amountBOut >= minAmountBOut, "Slippage too high");

        reserveB -= amountBOut;

        // Transfer tokens (simplified)
        // No protection against price manipulation within same transaction
    }

    function addLiquidity(uint256 amountA, uint256 amountB) public {
        reserveA += amountA;
        reserveB += amountB;
    }
}
```

## The Attack Scenario

**Classic Flash Loan Attack (bZx style):**

1. **Flash Loan**: Borrow 10,000 ETH from Aave (no collateral)
2. **Manipulate Price**: Swap 5,000 ETH → Token on low-liquidity DEX
3. **Price Impact**: Token price artificially inflated 10x
4. **Exploit**: Use inflated price to borrow maximum from vulnerable lending protocol
5. **Reverse Swap**: Sell borrowed tokens back for ETH
6. **Repay Flash Loan**: Return 10,000 ETH + fee (~0.09%)
7. **Profit**: Keep the difference from exploiting price manipulation

**Numerical Example:**
```
Initial State:
- Aave ETH available: 100,000 ETH
- DEX reserves: 1,000 ETH / 100,000 tokens (1 token = 0.01 ETH)
- Lending protocol accepts tokens as collateral

Attack Execution:

Step 1 - Flash Loan:
- Borrow 10,000 ETH from Aave
- Fee: 0.09% = 9 ETH

Step 2 - Manipulate Price:
- Swap 5,000 ETH for tokens on DEX
- New reserves: 6,000 ETH / 16,667 tokens
- New price: 1 token = 0.36 ETH (36x increase!)

Step 3 - Exploit Lending Protocol:
- Deposit 16,667 tokens as collateral
- Protocol values at manipulated price: 16,667 * 0.36 ETH = 6,000 ETH
- Borrow 4,000 ETH (150% collateralization)

Step 4 - Reverse Price Manipulation:
- Sell 16,667 tokens back to DEX
- Receive ~4,900 ETH
- Price returns to normal

Step 5 - Repay Flash Loan:
- Return 10,009 ETH to Aave
- Total ETH: 5,000 (remaining) + 4,000 (borrowed) + 4,900 (sold) = 13,900 ETH

Step 6 - Calculate Profit:
- Started with: 0 ETH
- Ended with: 13,900 - 10,009 = 3,891 ETH profit
- Attack cost: Only gas fees (~$500)

Final Result:
- Attacker profit: 3,891 ETH (~$7.8M)
- Lending protocol loss: 4,000 ETH
- DEX LPs: Lost from price manipulation
- Attack capital needed: $0 (flash loan)
```

## Prevention Methods

### Method 1: Time-Weighted Average Price (TWAP) Oracles

Use multi-block price averages instead of spot prices.

```solidity
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";

contract TWAPLending {
    address public pair; // Uniswap pair
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;

    uint256 public constant PERIOD = 1 hours;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    function update() public {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(pair);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        // Ensure minimum time passed
        require(timeElapsed >= PERIOD, "Too soon");

        // Calculate TWAP
        // ...

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    function getPrice() public view returns (uint256) {
        // Returns time-weighted price
        // Cannot be manipulated within single transaction!
        // ...
    }
}
```

**Gas Cost**: ~30,000 gas for update
**Pros**: Resistant to flash loan manipulation, decentralized
**Cons**: Requires regular updates, 1-block delay vulnerability

### Method 2: Chainlink Price Feeds

Use decentralized oracle networks with multiple data sources.

```solidity
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkLending {
    AggregatorV3Interface internal priceFeed;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Verify price freshness
        require(updatedAt > 0, "Invalid price");
        require(block.timestamp - updatedAt < 3600, "Stale price");
        require(answeredInRound >= roundId, "Stale answer");

        return uint256(price);
    }

    function borrow(uint256 amount) public {
        uint256 price = getPrice();
        uint256 collateralValue = (collateral[msg.sender] * price) / 1e18;

        require(collateralValue >= amount * 150 / 100, "Insufficient collateral");

        borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }
}
```

**Gas Cost**: ~2,000 gas per price read
**Pros**: Flash loan resistant, professional-grade, multiple sources
**Cons**: Centralization concerns, oracle dependency, requires LINK

### Method 3: Multiple Oracle Redundancy

Combine multiple price sources and use median/average.

```solidity
pragma solidity ^0.8.0;

contract MultiOracleLending {
    AggregatorV3Interface public chainlinkFeed;
    address public uniswapTWAP;
    address public sushiswapTWAP;

    uint256 public constant MAX_DEVIATION = 5; // 5%

    function getPrice() public view returns (uint256) {
        uint256 chainlinkPrice = getChainlinkPrice();
        uint256 uniswapPrice = getUniswapTWAP();
        uint256 sushiswapPrice = getSushiswapTWAP();

        // Calculate median
        uint256[] memory prices = new uint256[](3);
        prices[0] = chainlinkPrice;
        prices[1] = uniswapPrice;
        prices[2] = sushiswapPrice;

        uint256 median = getMedian(prices);

        // Verify no price deviates too much
        for (uint256 i = 0; i < prices.length; i++) {
            uint256 deviation = prices[i] > median
                ? ((prices[i] - median) * 100) / median
                : ((median - prices[i]) * 100) / median;

            require(deviation <= MAX_DEVIATION, "Price deviation too high");
        }

        return median;
    }

    function getMedian(uint256[] memory values) internal pure returns (uint256) {
        // Sort and return middle value
        // Implementation details...
    }
}
```

**Gas Cost**: ~10,000 gas (multiple reads)
**Pros**: Maximum security, no single point of failure
**Cons**: Higher gas costs, complex implementation

### Method 4: Flash Loan Detection and Blocking

Detect and prevent flash loan attacks.

```solidity
pragma solidity ^0.8.0;

contract FlashLoanProtection {
    mapping(address => uint256) public lastActionBlock;
    mapping(address => uint256) public balanceAtBlock;

    modifier noFlashLoan() {
        // Require actions in different blocks
        require(
            block.number > lastActionBlock[msg.sender],
            "Cannot perform multiple actions in same block"
        );

        // Record starting balance
        uint256 startBalance = msg.sender.balance;

        _;

        // After action, check balance didn't increase dramatically
        uint256 endBalance = msg.sender.balance;
        require(
            endBalance <= startBalance * 2,
            "Suspicious balance increase"
        );

        lastActionBlock[msg.sender] = block.number;
    }

    function borrow(uint256 amount) public noFlashLoan {
        // Safe from same-block flash loan attacks
    }

    function depositCollateral() public payable {
        lastActionBlock[msg.sender] = block.number;
    }
}
```

**Gas Cost**: ~5,000 gas overhead
**Pros**: Explicit protection, transparent
**Cons**: Poor UX (requires multiple transactions), can be bypassed

### Method 5: Transaction Size Limits

Limit maximum transaction size relative to liquidity.

```solidity
pragma solidity ^0.8.0;

contract ProtectedAMM {
    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant MAX_SWAP_PERCENT = 5; // 5% of reserves

    function swap(uint256 amountAIn, uint256 minAmountBOut) public returns (uint256 amountBOut) {
        // Limit swap size to prevent manipulation
        require(amountAIn <= reserveA * MAX_SWAP_PERCENT / 100, "Swap too large");

        uint256 k = reserveA * reserveB;
        reserveA += amountAIn;
        amountBOut = reserveB - (k / reserveA);

        require(amountBOut >= minAmountBOut, "Slippage too high");

        reserveB -= amountBOut;
    }
}
```

**Gas Cost**: Negligible
**Pros**: Simple, effective for small manipulations
**Cons**: Doesn't prevent all attacks, limits legitimate large trades

## Real-World Examples

| Incident | Date | Amount Lost | Attack Method |
|----------|------|-------------|---------------|
| **Harvest Finance** | Oct 2020 | $34M | Flash loan + Curve pool manipulation |
| **Cream Finance** | Oct 2021 | $130M | Flash loan + reentrancy |
| **bZx** | Feb 2020 | $600K | Flash loan + price oracle manipulation |
| **Warp Finance** | Dec 2020 | $8M | Flash loan + LP token manipulation |
| **Rari Capital** | May 2021 | $80M | Flash loan + cross-protocol attack |
| **Alpha Homora** | Feb 2021 | $37M | Flash loan + sUSD manipulation |

**Harvest Finance Attack Breakdown:**
- Borrowed $50M USDT/USDC via flash loans
- Manipulated Curve Y pool by swapping back/forth
- Exploited Harvest's reliance on Curve pool price
- Withdrew more value than deposited
- Profit: $34M

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

interface IFlashLoanProvider {
    function flashLoan(uint256 amount) external;
}

contract FlashLoanTest is Test {
    VulnerableLending public vulnerable;
    ChainlinkLending public secure;

    function setUp() public {
        vulnerable = new VulnerableLending();
        secure = new ChainlinkLending(address(0)); // Mock Chainlink
    }

    function testFlashLoanAttack() public {
        // Simulate flash loan attack
        vm.deal(address(this), 10000 ether);

        // 1. Borrow flash loan
        uint256 loanAmount = 5000 ether;

        // 2. Manipulate price on DEX
        // (implementation details)

        // 3. Exploit lending protocol
        vulnerable.depositCollateral{value: 100 ether}();

        uint256 balanceBefore = address(this).balance;
        vulnerable.borrow(1000 ether);
        uint256 balanceAfter = address(this).balance;

        // 4. Verify profit
        assertGt(balanceAfter, balanceBefore);
        console.log("Flash loan attack profitable!");
    }

    function testTWAPProtection() public {
        // TWAP cannot be manipulated in single transaction
        // Price updates require multiple blocks
    }

    function testFlashLoanDetection() public {
        FlashLoanProtection protected = new FlashLoanProtection();

        // Deposit in block N
        protected.depositCollateral{value: 1 ether}();

        // Try to borrow in same block - should fail
        vm.expectRevert("Cannot perform multiple actions in same block");
        protected.borrow(0.5 ether);

        // Mine new block
        vm.roll(block.number + 1);

        // Now borrow succeeds
        protected.borrow(0.5 ether);
    }
}
```

## Checklist

- [ ] Never use spot prices from single DEX as oracle
- [ ] Implement TWAP or Chainlink price feeds
- [ ] Use multiple oracle sources with deviation checks
- [ ] Require multi-block operations for sensitive actions
- [ ] Implement transaction size limits
- [ ] Monitor for unusual trading patterns
- [ ] Test flash loan attack scenarios
- [ ] Verify oracle freshness and validity
- [ ] Consider flash loan detection mechanisms
- [ ] Audit all price-dependent logic
- [ ] Implement circuit breakers for anomalies
- [ ] Use decentralized oracle networks
- [ ] Document oracle assumptions
- [ ] Test with forked mainnet state

## Additional Resources

**Documentation:**
- [Uniswap V2 TWAP Oracle](https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/building-an-oracle)
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- [Aave Flash Loans](https://docs.aave.com/developers/guides/flash-loans)

**Security:**
- [Flash Loan Attack Analysis](https://blog.openzeppelin.com/flash-loan-attacks/)
- [Harvest Finance Postmortem](https://medium.com/harvest-finance/harvest-flashloan-economic-attack-post-mortem-3cf900d65217)

**Research:**
- [SoK: Decentralized Finance (DeFi)](https://arxiv.org/abs/2101.08778)
- [Flash Loan Attack Vectors](https://eprint.iacr.org/2020/1347.pdf)

---

**Last Updated**: November 2025
**Severity**: Critical
**OWASP Category**: [A10: Price Oracle Manipulation](https://owasp.org/www-project-smart-contract-top-10/)
