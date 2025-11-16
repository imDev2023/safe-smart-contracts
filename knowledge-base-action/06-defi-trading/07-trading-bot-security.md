# Trading Bot Security & Implementation

**Status:** Essential Security Guide | **Level:** Advanced | **Risk Level:** HIGH

## Trading Bot Fundamentals

A **trading bot** is an automated system that:
1. Monitors market conditions
2. Executes trades based on strategies
3. Manages positions and risks
4. Responds to price movements

### Bot Categories

| Type | Purpose | Risk | Example |
|------|---------|------|---------|
| **Arbitrage Bot** | Exploit price differences | Medium | Buy Uniswap, sell Sushiswap |
| **Market Maker** | Provide liquidity, earn fees | High | Mint LP positions, rebalance |
| **Liquidation Bot** | Execute liquidations | High | Monitor underwater positions |
| **MEV Bot** | Extract MEV | Critical | Sandwich attacks, frontrunning |
| **Trend Bot** | Follow price trends | Medium | Technical analysis, signals |

---

## Core Security Requirements

### Requirement 1: Private Key Management

**CRITICAL:** How you manage private keys determines if bot profits are stolen.

```solidity
// ❌ INSECURE
contract BadBot {
    // Private key in plaintext or hardcoded
    bytes32 privateKey = 0x123456...;  // DISASTER!
    // Any attacker can steal funds
    // Exposed in logs, blockchain analysis, etc.
}

// ✅ SECURE: Use dedicated signing service
contract GoodBot {
    // No private keys in contract
    // Use external signer (hardware wallet, KMS)
    address signer;

    function executeTrade(
        bytes calldata signature  // Signature from external signer
    ) external {
        // Verify signature came from authorized signer
        require(
            recoverSigner(signature) == signer,
            "Unauthorized"
        );

        // Execute trade
        router.swapExactTokensForTokens(...);
    }
}
```

**Best Practices:**
1. **Hardware Wallet** (Safest)
   - Ledger, Trezor
   - Keys never exposed to internet
   - Requires manual approval (slower)

2. **AWS KMS / Google Cloud HSM** (Very Safe)
   - Keys in managed service
   - Automatic signing
   - Enterprise-grade security
   - Monthly cost

3. **Encrypted Key in Database** (Less Safe)
   - Keys encrypted at rest
   - Decrypted only when signing
   - Requires secure password management

```solidity
// Example: External signer pattern
interface IExternalSigner {
    function signTransaction(
        bytes calldata transaction
    ) external returns (bytes calldata signature);
}

contract BotWithExternalSigner {
    IExternalSigner signer;

    function executeTrade(
        uint amountIn,
        address[] memory path
    ) external {
        // Build transaction
        bytes memory txData = abi.encodeWithSelector(
            router.swapExactTokensForTokens.selector,
            amountIn,
            0,  // Assume calculated separately
            path,
            address(this),
            block.timestamp + 300
        );

        // Get signature from external signer
        // (KMS, HSM, hardware wallet, etc.)
        bytes memory signature = signer.signTransaction(txData);

        // Execute
        (bool success, ) = address(router).call(txData);
        require(success, "Trade failed");
    }
}
```

### Requirement 2: Rate Limiting & Circuit Breakers

Prevent catastrophic losses from bugs or attacks.

```solidity
contract RateLimitedBot {
    mapping(address => DailyQuota) quotas;

    struct DailyQuota {
        uint256 maxLoss24h;         // Stop if losses exceed
        uint256 realizedLoss24h;    // Current 24h losses
        uint256 maxTrades24h;       // Maximum trades
        uint256 tradesExecuted24h;  // Current count
        uint256 lastResetTime;
    }

    function initializeQuota(
        address token,
        uint256 maxLoss,
        uint256 maxTrades
    ) external onlyOwner {
        quotas[token] = DailyQuota({
            maxLoss24h: maxLoss,
            realizedLoss24h: 0,
            maxTrades24h: maxTrades,
            tradesExecuted24h: 0,
            lastResetTime: block.timestamp
        });
    }

    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) external {
        DailyQuota storage quota = quotas[tokenIn];

        // Reset quota if day passed
        if (block.timestamp >= quota.lastResetTime + 1 days) {
            quota.realizedLoss24h = 0;
            quota.tradesExecuted24h = 0;
            quota.lastResetTime = block.timestamp;
        }

        // 1. Check trade count limit
        require(
            quota.tradesExecuted24h < quota.maxTrades24h,
            "Daily trade limit exceeded"
        );

        // 2. Get current balance before trade
        uint balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        // 3. Execute trade
        router.swapExactTokensForTokens(
            amountIn,
            0,  // No minimum (risky, but we have circuit breaker)
            path,
            address(this),
            block.timestamp + 300
        );

        // 4. Check if trade was profitable
        uint balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        if (balanceAfter < balanceBefore) {
            uint loss = balanceBefore - balanceAfter;
            quota.realizedLoss24h += loss;

            // 5. Check loss limit
            require(
                quota.realizedLoss24h <= quota.maxLoss24h,
                "Daily loss limit exceeded - circuit breaker triggered"
            );
        }

        // 6. Update trade count
        quota.tradesExecuted24h++;
    }
}
```

### Requirement 3: Slippage Validation

Every trade must have maximum acceptable slippage.

```solidity
contract SlippageValidatedBot {
    uint256 constant SLIPPAGE_BPS = 100;  // 1% max slippage

    function executeTradeWithSlippage(
        uint amountIn,
        address[] memory path
    ) external {
        // 1. Calculate expected output
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        uint256 expectedOut = amounts[amounts.length - 1];

        // 2. Calculate minimum acceptable output
        uint256 minOut = (expectedOut * (10000 - SLIPPAGE_BPS)) / 10000;

        // 3. Execute with protection
        uint256[] memory actualAmounts = router.swapExactTokensForTokens(
            amountIn,
            minOut,  // SLIPPAGE PROTECTED
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 actualOut = actualAmounts[actualAmounts.length - 1];

        // 4. Log results
        emit TradeExecuted(
            amountIn,
            expectedOut,
            actualOut,
            actualOut >= minOut ? "success" : "slippage"
        );
    }

    // Dynamic slippage based on volatility
    function calculateDynamicSlippage(
        address token0,
        address token1
    ) internal view returns (uint256 slippageBps) {
        // Measure volatility from TWAP
        uint256 volatility = getTWAPVolatility(token0, token1);

        if (volatility < 100) {  // <1% volatility
            slippageBps = 50;    // 0.5% slippage tolerance
        } else if (volatility < 500) {  // <5% volatility
            slippageBps = 100;   // 1% slippage tolerance
        } else {  // >5% volatility
            slippageBps = 300;   // 3% slippage tolerance
            // Or: Don't trade in high volatility
        }

        return slippageBps;
    }
}
```

### Requirement 4: Position Management & Risk Limits

Track and limit total exposure.

```solidity
contract PositionManagedBot {
    mapping(address => Position) positions;

    struct Position {
        address token;
        uint256 amount;
        uint256 entryPrice;
        uint256 maxLoss;  // Stop loss
    }

    function openPosition(
        address token,
        uint256 amount,
        uint256 entryPrice,
        uint256 maxLossPercentage
    ) external {
        // 1. Validate position size
        uint256 maxPositionSize = getTotalBalance() / 10;  // Max 10% per position
        require(amount <= maxPositionSize, "Position too large");

        // 2. Calculate stop loss
        uint256 maxLoss = (amount * entryPrice * maxLossPercentage) / 10000;

        // 3. Record position
        positions[token] = Position({
            token: token,
            amount: amount,
            entryPrice: entryPrice,
            maxLoss: maxLoss
        });

        emit PositionOpened(token, amount, entryPrice);
    }

    function checkStopLoss(address token) external {
        Position storage pos = positions[token];
        require(pos.amount > 0, "No position");

        uint256 currentPrice = oracle.getPrice(token);
        uint256 currentValue = pos.amount * currentPrice;
        uint256 initialValue = pos.amount * pos.entryPrice;

        if (initialValue > currentValue) {
            uint256 loss = initialValue - currentValue;

            if (loss >= pos.maxLoss) {
                // Stop loss triggered - exit position
                exitPosition(token);
                emit StopLossTriggered(token, loss);
            }
        }
    }

    function exitPosition(address token) internal {
        Position memory pos = positions[token];

        // Sell tokens
        router.swapExactTokensForTokens(
            pos.amount,
            0,  // Accept any price (at stop loss)
            getPath(token, address(USDC)),
            address(this),
            block.timestamp + 300
        );

        delete positions[token];
        emit PositionClosed(token);
    }
}
```

---

## Attack Vectors Against Bots

### Attack 1: Sandwich Attack on Bot's Trade

```
Attacker monitors mempool for bot's large swap

1. Sees: Bot wants to buy 1000 ETH
2. Frontruns: Buys 500 ETH (moves price up)
3. Bot's trade: Gets worse price
4. Backruns: Sells 500 ETH + profit

Bot loss: ~0.5-2% from MEV extraction
Attacker profit: ~$500k on $10M trade

Protection: Use Flashbots Protect (private mempool)
```

### Attack 2: Oracle Price Manipulation

```
Attacker manipulates oracle price when bot relies on it

1. Bot uses Uniswap spot price (not TWAP)
2. Attacker flashes loan to move price 10%
3. Bot executes trade at manipulated price
4. Bot loses money, attacker profits

Protection: Use TWAP oracle, not spot price
```

### Attack 3: Bot Key Theft

```
Attacker compromises bot's private key

1. Drain all funds
2. Execute malicious trades
3. Transfer to attacker's wallet

Protection:
- Use hardware wallet or KMS
- Rate limiting + circuit breakers
- Multiple approval required
- Spend limits
```

### Attack 4: Liquidation Race

```
Multiple liquidation bots compete for same position

1. Position becomes underwater
2. Bot A sees liquidation opportunity
3. Bot B sees same opportunity
4. Both submit transactions
5. Attacker frontruns both, executes first
6. Bots lose gas, no profit

Protection:
- Unique liquidation IDs (sequential)
- Batch auction for liquidations
- Increase priority fee
```

---

## Safe Bot Architecture

### Recommended Pattern

```solidity
contract SafeTradingBot {
    // Core components
    address public owner;
    IUniswapV2Router router;
    AggregatorV3Interface oracle;  // Chainlink

    // Security
    uint256 public maxDailyLoss = 1000 * 10**18;  // $1000 max loss
    uint256 public maxTradeSize = 100 * 10**18;  // $100 max per trade
    uint256 public slippageLimit = 100;  // 1%

    mapping(address => bool) allowedTokens;
    mapping(address => bool) allowedDexRouters;

    // Tracking
    mapping(uint => Trade) trades;
    uint tradeCounter;

    struct Trade {
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOut;
        uint executedAt;
        uint profitLoss;
    }

    // Events
    event TradeExecuted(uint tradeId, uint amountIn, uint amountOut);
    event TradeFailed(string reason);
    event CircuitBreakerTriggered(string reason);

    // Core trading function
    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        bytes calldata signature  // Must be signed by owner
    ) external {
        // 1. Signature validation (external signing)
        require(
            recoverSigner(signature, abi.encode(tokenIn, tokenOut, amountIn)) == owner,
            "Invalid signature"
        );

        // 2. Pre-trade validations
        require(allowedTokens[tokenIn], "Token not allowed");
        require(allowedTokens[tokenOut], "Token not allowed");
        require(amountIn <= maxTradeSize, "Trade size exceeded");

        // 3. Price check
        uint256 currentPrice = oracle.getPrice(tokenOut);
        require(currentPrice > 0, "Invalid price");
        require(block.timestamp - lastPriceUpdate <= 1 hours, "Stale price");

        // 4. Calculate expected output
        uint256 expectedOut = (amountIn * currentPrice) / 10**18;
        uint256 minOut = (expectedOut * (10000 - slippageLimit)) / 10000;

        // 5. Pre-trade balance check
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        // 6. Execute trade
        try router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            address(this),
            block.timestamp + 300
        ) returns (uint[] memory amounts) {
            // 7. Post-trade validation
            uint256 actualOut = amounts[amounts.length - 1];
            uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

            require(balanceAfter >= balanceBefore + actualOut - 1, "Output verification failed");

            // 8. Record trade
            uint tradeId = tradeCounter++;
            trades[tradeId] = Trade({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: actualOut,
                executedAt: block.timestamp,
                profitLoss: int(actualOut) - int(expectedOut)
            });

            // 9. Check loss limits (circuit breaker)
            checkCircuitBreaker();

            emit TradeExecuted(tradeId, amountIn, actualOut);
        } catch Error(string memory reason) {
            emit TradeFailed(reason);
            revert(reason);
        }
    }

    function checkCircuitBreaker() internal {
        // Check 24h loss limit
        uint256 loss24h = calculateLoss24h();

        if (loss24h > maxDailyLoss) {
            pauseTrading();
            emit CircuitBreakerTriggered("Daily loss limit exceeded");
        }
    }

    function calculateLoss24h() internal view returns (uint256) {
        uint256 totalLoss = 0;

        for (uint i = tradeCounter - 1; i >= 0 && i >= tradeCounter - 100; i--) {
            if (block.timestamp - trades[i].executedAt <= 1 days) {
                if (trades[i].profitLoss < 0) {
                    totalLoss += uint256(-trades[i].profitLoss);
                }
            }
        }

        return totalLoss;
    }

    function pauseTrading() internal {
        // Disable all trading until reviewed
        _paused = true;
    }

    // Admin functions
    function addAllowedToken(address token) external onlyOwner {
        allowedTokens[token] = true;
    }

    function setMaxDailyLoss(uint256 amount) external onlyOwner {
        maxDailyLoss = amount;
    }

    function emergencyWithdraw() external onlyOwner {
        // Withdraw all funds in emergency
        IERC20(USDC).transfer(owner, IERC20(USDC).balanceOf(address(this)));
    }
}
```

---

## Key Security Checklist

- [ ] Private keys in hardware wallet or KMS?
- [ ] No hardcoded private keys?
- [ ] All trades signed by external signer?
- [ ] Slippage limits enforced?
- [ ] Daily loss circuit breaker active?
- [ ] Trade size limits in place?
- [ ] Rate limiting implemented?
- [ ] Price oracle freshness checked?
- [ ] TWAP used (not spot price)?
- [ ] Deadline set on all trades?
- [ ] Balance checks before/after?
- [ ] Comprehensive logging/auditing?
- [ ] Emergency pause mechanism?
- [ ] Multiple approval for withdrawals?
- [ ] Regular security audits?
- [ ] Isolated contract permissions?
- [ ] Tests cover all attack vectors?
- [ ] Sandboxed deployment (testnet first)?

---

## Deployment Strategy

### Phase 1: Testing (Testnet)
```
1. Deploy to testnet
2. Fund with test tokens
3. Run bot for 1 week
4. Monitor all trades, losses, edge cases
5. Review logs and metrics
6. Fix any issues found
```

### Phase 2: Small Production (Mainnet)
```
1. Deploy with tiny amounts ($100-1000)
2. Run for 1 month
3. Monitor 24/7
4. Establish historical performance baseline
5. Verify all circuit breakers work
```

### Phase 3: Scale Gradually
```
1. Increase to $10k after 1 month success
2. Increase to $100k after 3 months
3. Increase to $1M after 6 months
4. Regular security audits between phases
```

---

## Monitoring & Maintenance

```solidity
contract BotMonitoring {
    event DailyMetrics(
        uint totalTrades,
        uint profitableTrades,
        int totalPnL,
        uint gasSpent
    );

    function reportMetrics() external {
        uint totalTrades = tradeCounter;
        uint profitable = countProfitableTrades();
        int totalPnL = calculateTotalPnL();
        uint gasUsed = getTotalGasSpent();

        emit DailyMetrics(totalTrades, profitable, totalPnL, gasUsed);

        // Store metrics on-chain for historical analysis
    }

    function getDailyWinRate() external view returns (uint percentage) {
        uint total = tradeCounter;
        if (total == 0) return 0;

        uint wins = countProfitableTrades();
        return (wins * 100) / total;
    }
}
```

---

## Resources

- **OpenZeppelin Safe Contracts**: https://docs.openzeppelin.com/contracts/
- **Chainlink Oracles**: https://docs.chain.link/
- **Flashbots Protect**: https://protect.flashbots.net/
- **Uniswap Documentation**: https://docs.uniswap.org/

---

**End of Guide:** You now have comprehensive trading bot security knowledge. Review all patterns before deploying.
