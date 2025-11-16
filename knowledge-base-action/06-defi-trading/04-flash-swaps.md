# Flash Swaps & Flash Loan Attack Prevention

**Status:** Critical Security Guide | **Level:** Advanced | **Risk Level:** CRITICAL

## What is a Flash Swap?

A **flash swap** (introduced by Uniswap V2) is a special type of swap that lets you borrow tokens **without collateral**, as long as you:
1. Pay back the loan in the same transaction, OR
2. Provide an equivalent value in the other token

### Flash Swap vs Flash Loan

| Aspect | Flash Swap | Flash Loan |
|--------|-----------|-----------|
| **Source** | DEX (Uniswap) | Lending pool (Aave, dYdX) |
| **Fee** | 0.3% or higher | Usually 0.09% |
| **Payback** | Tokens OR value | Must repay + fee |
| **Use Case** | Arbitrage, self-liquidation | Capital efficiency, liquidations |
| **Risk** | Medium | High |

### Example Flash Swap

```
User wants: 1000 USDC from USDC/ETH pool
Has: No ETH

Normal flow:
1. Get ETH from elsewhere
2. Swap ETH → USDC in pool
3. Cost: 0.3% fee + slippage

Flash swap flow:
1. Borrow 1000 USDC from pool immediately (no ETH needed!)
2. Execute business logic (arbitrage, etc.)
3. Provide 1000 USDC worth of ETH
4. Return to pool in same transaction
5. Cost: 0.3% fee only
```

---

## Flash Swap Mechanics

### Step-by-Step Execution

```solidity
// Flash swap flow in Uniswap V2

contract FlashSwapExample {
    IUniswapV2Pair pair;

    function initiateFlashSwap(
        uint amountOut0,  // ETH amount to borrow
        uint amountOut1   // USDC amount to borrow
    ) external {
        // Call swap on pair
        // Pass data != "" to trigger callback
        pair.swap(amountOut0, amountOut1, address(this), abi.encode("data"));
        // At this point, we have tokens but owe the pair
    }

    // This callback is AUTOMATICALLY called by the pair
    function uniswapV2Call(
        address sender,
        uint amount0,   // ETH received (if amountOut0 > 0)
        uint amount1,   // USDC received (if amountOut1 > 0)
        bytes calldata data
    ) external {
        // CRITICAL: Only pair can call this
        require(msg.sender == address(pair), "Unauthorized");

        // 1. We now have the borrowed tokens
        uint balance0 = IERC20(pair.token0()).balanceOf(address(this));
        uint balance1 = IERC20(pair.token1()).balanceOf(address(this));

        // 2. Do profitable operation here
        executeArbitrage(balance0, balance1);

        // 3. Calculate what we owe
        uint amount0owed = amount0 + (amount0 * 3) / 997 + 1;
        uint amount1owed = amount1 + (amount1 * 3) / 997 + 1;

        // 4. Repay the pair
        IERC20(pair.token0()).transfer(address(pair), amount0owed);
        IERC20(pair.token1()).transfer(address(pair), amount1owed);

        // 5. Keep profit
        uint profit0 = IERC20(pair.token0()).balanceOf(address(this));
        // profit0 is now ours!
    }
}
```

### Fee Calculation

```
Flash swap fee: 0.3% (same as normal swap)

Formula:
amountOut = 1000 USDC
fee = 0.3%

Required repayment = amountOut + (amountOut * 3) / 997 + 1
                  = 1000 + 3 + 1
                  = 1003 + 1 wei
                  ≈ 1003.01 USDC

The +1 wei is for rounding safety
```

---

## Flash Loan Attack Scenarios

### Attack 1: Price Oracle Manipulation

**Objective:** Temporarily move price to liquidate or get better rates

```solidity
contract FlashLoanPriceAttack {
    function attackLiquidationOracle(
        address lendingPool,
        address token,
        uint amount
    ) external {
        // 1. Flash borrow huge amount
        lendingPool.flashLoan(
            address(this),
            token,
            amount,
            abi.encode("manipulatePrice")
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    ) external override returns (bytes32) {
        // 2. Dump tokens into DEX (move price up dramatically)
        IUniswapV2Router router = IUniswapV2Router(ROUTER);
        IERC20(asset).approve(address(router), amount);

        address[] memory path = new address[](2);
        path[0] = asset;
        path[1] = address(USDC);

        router.swapExactTokensForTokens(
            amount,
            0,  // Accept any output
            path,
            address(this),
            block.timestamp + 300
        );

        // 3. This moved the price! Oracle now reads inflated price

        // 4. Target: Liquidate victim position at artificial price
        ILendingProtocol lending = ILendingProtocol(LENDING);
        lending.liquidate(VICTIM, asset, amount);

        // 5. Attacker profit: Liquidation penalty + price recovery
        uint victimCompensation = lending.getPenalty(amount);

        // 6. Repay flash loan
        uint repay = amount + fee;
        IERC20(asset).approve(address(lendingPool), repay);
        // Transfer repayment

        return keccak256("ERC3156FlashBorrower.executeOperation");
    }
}
```

**Real Example:** Harvest Finance Attack (2020)
- Attacker borrowed $50M worth of stablecoins
- Dumped into Curve to move price
- Liquidated victims at artificial prices
- Profit: $34M+
- Lesson: **Use TWAP oracle, not spot price**

### Attack 2: DEX Arbitrage Manipulation

```solidity
// Attacker manipulates price across multiple DEXs

contract DEXArbitrageAttack {
    function exploitPriceDifference(
        address token,
        address uniswap,
        address sushiswap
    ) external {
        // Uniswap: Token price = $100
        // Sushiswap: Token price = $101
        // Normal arbitrage profit: $1 per token

        // Attacker sees: $1M of liquidity on each side
        uint amountFlash = 100000 ether;

        // 1. Flash borrow $10M stablecoins
        // 2. Buy token on Sushiswap (cheaper)
        // 3. Dump into Uniswap (move price down to $95)
        // 4. Arb traders' transactions execute at worse price
        // 5. Attacker recovers, keeps profit from price movement

        // Victims lost: ~$500k from worse prices
        // Attacker profit: Portion of that extraction

        // Protection: Minimum slippage checks on all trades
    }
}
```

### Attack 3: Collateral Theft via Flash Loan

```solidity
// More direct: Use borrowed tokens to steal collateral

contract FlashCollateralTheft {
    function stealCollateral(
        address lendingPool,
        address collateralToken,
        address borrowToken,
        uint amount
    ) external {
        // 1. Flash borrow collateral tokens
        lendingPool.flashLoan(
            address(this),
            collateralToken,
            amount,
            abi.encode("steal")
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    ) external override returns (bytes32) {
        // 2. Deposit into victim's lending protocol
        ILendingProtocol(LENDING).deposit(asset, amount);

        // 3. Take out max loan against collateral
        uint borrowed = ILendingProtocol(LENDING).borrow(USDC, amount * 95 / 100);

        // 4. Withdraw original collateral + profit
        uint profit = borrowed - (amount + fee);

        // 5. Repay flash loan
        // 6. Attacker keeps profit, collateral gone!

        // Protection: Rate limiting on deposits/borrows
        return keccak256("ERC3156FlashBorrower.executeOperation");
    }
}
```

---

## Defense Mechanisms

### Defense 1: Reentrancy Guards + State Validation

```solidity
contract SafeLendingPool {
    bool private locked;  // Reentrancy guard

    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    uint256 private lastCheckpoint;
    mapping(address => uint256) lastInteractionBlock;

    function flashLoan(
        address token,
        uint amount,
        bytes calldata data
    ) external nonReentrant {
        // 1. Record state before
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // 2. Transfer tokens
        IERC20(token).transfer(msg.sender, amount);

        // 3. Execute callback
        IFlashBorrower(msg.sender).executeOperation(
            token,
            amount,
            fee,
            address(0),
            data
        );

        // 4. Validate state after (CRITICAL)
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 feeAmount = (amount * 9) / 10000; // 0.09% fee

        require(
            balanceAfter >= balanceBefore + feeAmount,
            "Flash loan not repaid"
        );

        lastCheckpoint = block.timestamp;
    }

    // Additional: Prevent repeated flash loans in same block
    modifier oncePerBlock() {
        require(lastInteractionBlock[msg.sender] < block.number, "Already used");
        lastInteractionBlock[msg.sender] = block.number;
        _;
    }
}
```

### Defense 2: TWAP Oracle Instead of Spot Price

```solidity
// Problem: Spot price can be manipulated in single block

contract SafeOracle {
    struct OracleData {
        uint price;
        uint blockTimestamp;
    }

    mapping(address => OracleData[]) priceHistory;

    // Record price every block
    function updatePrice(address token, uint price) external {
        priceHistory[token].push(OracleData({
            price: price,
            blockTimestamp: block.timestamp
        }));
    }

    // Return time-weighted average price (immune to flash attacks!)
    function getTWAP(
        address token,
        uint timeWindow  // e.g., 1 hour
    ) external view returns (uint twap) {
        OracleData[] memory history = priceHistory[token];
        require(history.length > 0, "No price data");

        uint cumulativePrice = 0;
        uint totalWeight = 0;
        uint currentTime = block.timestamp;

        for (uint i = history.length - 1; i > 0; i--) {
            if (currentTime - history[i].blockTimestamp > timeWindow) {
                break;
            }

            uint weight = currentTime - history[i].blockTimestamp;
            cumulativePrice += history[i].price * weight;
            totalWeight += weight;
        }

        require(totalWeight > 0, "Insufficient history");
        return cumulativePrice / totalWeight;
    }

    // Usage: Use TWAP for critical operations, not spot price
    function getSafePrice(address token) external view returns (uint) {
        return getTWAP(token, 1 hours);  // Last 1 hour average
    }
}
```

### Defense 3: Minimum Balances & Rate Limiting

```solidity
contract RateLimitedFlashLoan {
    mapping(address => FlashActivity) userActivity;

    struct FlashActivity {
        uint256 totalBorrowed24h;
        uint256 lastFlashTime;
        uint256 flashCount24h;
    }

    uint256 constant MAX_BORROW_PER_24H = 1000000 * 10**18; // $1M max
    uint256 constant MAX_FLASHES_PER_24H = 10;
    uint256 constant MIN_INTERVAL = 300; // 5 minutes between flashes

    function flashLoan(
        address token,
        uint amount,
        bytes calldata data
    ) external {
        FlashActivity storage activity = userActivity[msg.sender];

        // Reset if 24 hours passed
        if (block.timestamp >= activity.lastFlashTime + 1 days) {
            activity.totalBorrowed24h = 0;
            activity.flashCount24h = 0;
        }

        // Rate limit checks
        require(
            activity.totalBorrowed24h + amount <= MAX_BORROW_PER_24H,
            "Daily limit exceeded"
        );
        require(
            activity.flashCount24h < MAX_FLASHES_PER_24H,
            "Flash count exceeded"
        );
        require(
            block.timestamp >= activity.lastFlashTime + MIN_INTERVAL,
            "Too frequent"
        );

        // Update activity
        activity.totalBorrowed24h += amount;
        activity.flashCount24h++;
        activity.lastFlashTime = block.timestamp;

        // Execute flash loan
        _executeFlash(token, amount, data);
    }
}
```

### Defense 4: Validation After Callback

```solidity
contract StrictValidationFlash {
    function flashLoan(
        address token,
        uint amount,
        bytes calldata data
    ) external returns (bool) {
        uint balanceBefore = IERC20(token).balanceOf(address(this));
        uint reserveBefore = totalReserves[token];

        // Execute callback
        IERC20(token).transfer(msg.sender, amount);

        IFlashBorrower(msg.sender).executeOperation(
            token, amount, fee, address(0), data
        );

        // STRICT validation
        uint balanceAfter = IERC20(token).balanceOf(address(this));
        uint fee = (amount * 9) / 10000;

        // 1. Check balance fully restored
        require(
            balanceAfter == balanceBefore + fee,
            "Balance not restored"
        );

        // 2. Check total reserves
        require(
            totalReserves[token] == reserveBefore,
            "Reserves corrupted"
        );

        // 3. Check system health metrics
        uint systemHealth = calculateHealth();
        require(systemHealth > 100, "System unhealthy");

        // 4. Check no critical state changes
        require(!hasUnauthorizedStateChanges(msg.sender), "State corrupted");

        return true;
    }
}
```

---

## Safe Flash Swap Usage Pattern

### Correct Implementation

```solidity
contract SafeFlashSwap {
    function arbitrageWithFlashSwap(
        address pair,
        uint amountOut,
        address[] memory path
    ) external {
        // 1. Verify pair legitimacy
        require(isValidPair(pair), "Invalid pair");

        // 2. Initiate flash swap
        IUniswapV2Pair(pair).swap(amountOut, 0, address(this), abi.encode(path));

        // 3. Profit transferred to msg.sender
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // 1. CRITICAL: Verify caller is legitimate pair
        require(msg.sender == address(PAIR), "Unauthorized caller");
        require(sender == address(this), "Invalid sender");

        address[] memory path = abi.decode(data, (address[]));

        // 2. Calculate repayment required
        uint borrowedAmount = amount1 > 0 ? amount1 : amount0;
        uint fee = (borrowedAmount * 3) / 997 + 1;
        uint repaymentRequired = borrowedAmount + fee;

        // 3. Execute profitable swap on different DEX
        address outputToken = path[path.length - 1];

        // e.g., borrowed 1000 USDC from Uniswap
        // Sell on Sushiswap for better price
        uint amountReceived = executeArbSwap(path, borrowedAmount);

        // 4. Validate profit exists
        require(amountReceived > repaymentRequired, "No profit");

        // 5. Repay exactly what's owed
        IERC20(outputToken).transfer(address(PAIR), repaymentRequired);

        // 6. Keep profit
        uint profit = amountReceived - repaymentRequired;
        IERC20(outputToken).transfer(msg.sender, profit);

        // 7. Log event
        emit ArbitrageExecuted(borrowedAmount, amountReceived, profit);
    }

    function isValidPair(address pair) internal view returns (bool) {
        // Verify pair is registered with Uniswap factory
        address factory = FACTORY;
        return IUniswapV2Factory(factory).getPair(token0, token1) == pair;
    }
}
```

---

## Prevention Checklist

- [ ] All lending functions have reentrancy guards?
- [ ] Using TWAP oracle (not spot price) for critical operations?
- [ ] Rate limiting on flash loans implemented?
- [ ] State validation after callbacks?
- [ ] Minimum balance checks in place?
- [ ] All critical operations in checks-effects-interactions pattern?
- [ ] Flash loan fee sufficient (>0.09%)?
- [ ] No cross-protocol atomic operations without safeguards?
- [ ] Time locks on critical functions?
- [ ] Emergency pause mechanisms active?
- [ ] Tests cover flash loan scenarios?
- [ ] External auditors reviewed flash logic?

---

## Resources

- **Uniswap Flash Swaps Docs**: https://docs.uniswap.org/protocol/concepts/core-concepts/swaps/flash-swaps
- **Aave Flash Loan Docs**: https://docs.aave.com/developers/guides/flash-loans
- **Harvest Finance Attack Analysis**: https://peckshield.medium.com/harvest-finance-audit-report-94ed4e4d4020
- **Flash Loan Protection Guide**: https://eips.ethereum.org/EIPS/eip-3156

---

**Next:** Read `05-mev-mitigation.md` for comprehensive MEV mitigation strategies.
