# Sniper Bot Detection & Prevention

**Status:** Critical Security Guide | **Level:** Advanced | **Risk Level:** CRITICAL

## What is a Sniper Bot?

A **sniper bot** is an automated system that:
1. Monitors pending transactions (mempool)
2. Detects profitable opportunities
3. Executes trades faster than legitimate users
4. Extracts MEV (Maximal Extractable Value) before or after your trade

### Real-World Impact

```
Annual MEV extraction: $500M+ (2024)
Per-transaction loss: $100 - $10,000+ for large trades
Primary victims: DEX users, yield farmers, liquidators

Example Sniper Attack (Real):
1. User broadcasts: Swap 100k USDC → ETH
2. Sniper sees in mempool, frontruns with 5 ETH
3. User's swap executes at worse price (sniper moved market)
4. Sniper backruns: Sells ETH + profits
5. User loss: ~$5,000 MEV extraction
```

---

## Bot Detection Mechanisms

### Pattern 1: Sequence Analysis Detection

```solidity
contract BotDetector {
    mapping(address => SwapActivity) userActivity;

    struct SwapActivity {
        uint256 lastSwapTime;
        uint256 swapCount24h;
        uint256 averageTimeGap;
        uint256 totalVolume24h;
        bool isSuspicious;
    }

    function detectSniperPattern(
        address user,
        uint amountIn,
        address[] memory path
    ) external view returns (bool isSuspiciousBot) {
        SwapActivity memory activity = userActivity[user];

        // Pattern 1: Extremely frequent swaps
        if (block.timestamp - activity.lastSwapTime < 5) {
            return true;  // 5 second swaps = bot
        }

        // Pattern 2: Many tiny swaps
        if (activity.swapCount24h > 100 && amountIn < 0.1 ether) {
            return true;  // 100+ swaps of dust
        }

        // Pattern 3: Consistent timing
        if (activity.swapCount24h > 10) {
            // Calculate variance in swap timing
            uint variance = calculateTimingVariance(user);
            if (variance < 1000) {  // Very regular = bot
                return true;
            }
        }

        // Pattern 4: Specific token path targeting
        if (isKnownSniperPath(path)) {
            return true;
        }

        return false;
    }

    function calculateTimingVariance(address user) internal view returns (uint) {
        // Fetch last 20 swap timestamps
        // Calculate standard deviation
        // Return variance metric
        // (Simplified for illustration)
        return 0;
    }

    function isKnownSniperPath(address[] memory path) internal pure returns (bool) {
        // Check if path matches known sniper patterns:
        // - Flash loan borrow/repay patterns
        // - Specific stablecoin routes
        // - MEV extraction signatures
        return false;
    }
}
```

### Pattern 2: Price Impact Analysis

```solidity
contract PriceImpactMonitor {
    function detectAnomalousImpact(
        address pool,
        uint expectedPriceImpact,
        uint actualPriceImpact
    ) external pure returns (bool isDangerousBot) {
        // Legitimate trades have consistent impact
        // Snipers have sharp, asymmetric impacts

        uint impactDifference = actualPriceImpact > expectedPriceImpact
            ? actualPriceImpact - expectedPriceImpact
            : expectedPriceImpact - actualPriceImpact;

        // Difference > 20% = suspicious
        if ((impactDifference * 100) / expectedPriceImpact > 2000) {
            return true;
        }

        return false;
    }

    function analyzeSwapSequence(
        address[] memory swaps,
        uint[] memory amounts
    ) external pure returns (bool isSandwichAttack) {
        // Check for sandwich pattern:
        // 1. Large trade (amountIn >> normal)
        // 2. Your transaction
        // 3. Reverse trade (exit position)

        if (swaps.length < 3) return false;

        // Check if first and last swaps are reverses of each other
        bool isReversal = (swaps[0] == swaps[swaps.length - 1]) ||
                         (swaps[1] == swaps[swaps.length - 2]);

        if (isReversal && amounts[0] > amounts[swaps.length - 1] * 5) {
            return true;  // Classic sandwich
        }

        return false;
    }
}
```

### Pattern 3: Mempool Monitoring Detection

```solidity
interface ITransactionMonitor {
    function isFromPrivateMempool(bytes calldata tx) external view returns (bool);
    function getSourcePool(bytes calldata tx) external view returns (string memory);
    function estimateGasPrice(bytes calldata tx) external view returns (uint);
}

contract SafeSwapWithBotDetection {
    function executeWithBotProtection(
        uint amountIn,
        address[] memory path,
        uint minOut,
        ITransactionMonitor monitor
    ) external {
        // Detect if this transaction came from monitored mempool
        // (Would require custom implementation with Flashbots integration)

        // 1. Check current gas price vs market
        uint currentGas = tx.gasprice;
        uint marketGas = getMarketGasPrice();

        if (currentGas > marketGas * 150 / 100) {
            // 50% above market = likely MEV bot
            revert("Suspicious gas price");
        }

        // 2. Check if transaction has unusual gas limit
        if (gasleft() < 100000 && msg.value > 0) {
            // Low gas + trying to profit = bot
            revert("Suspicious gas usage");
        }

        // 3. Execute swap
        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            msg.sender,
            block.timestamp + 300
        );
    }
}
```

---

## Prevention Strategies

### Strategy 1: Private Mempools (Flashbots Protect)

```solidity
// Using Flashbots Protect API
contract FlashbotsProtectedSwap {
    // Transaction never enters public mempool
    // Private pool obscures your transaction from bots
    // Costs: Flashbots flashbots.net/status

    function executeViaFlashbots(
        uint amountIn,
        address[] memory path,
        uint minOut
    ) external {
        // Instead of router.swap()
        // Call flashbots endpoint privately
        // Your TX is hidden from MEV bots

        // Pseudocode:
        bytes memory tx = abi.encodeWithSelector(
            router.swapExactTokensForTokens.selector,
            amountIn,
            minOut,
            path,
            msg.sender,
            block.timestamp + 300
        );

        // Send to Flashbots Protect endpoint
        // They include in next block privately
        // Bots never see it in mempool
    }
}
```

### Strategy 2: MEV Auction / Burn

```solidity
// Protocol captures MEV instead of bots
contract MEVBurnMechanism {
    uint256 public mevBurn;

    function swapWithMEVCapture(
        uint amountIn,
        address[] memory path,
        uint minOut
    ) external {
        // 1. Execute swap normally
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));

        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            address(this),
            block.timestamp + 300
        );

        uint balanceAfter = IERC20(path[path.length - 1]).balanceOf(address(this));
        uint actualOut = balanceAfter - balanceBefore;

        // 2. If user received MORE than minOut, capture excess MEV
        uint expectedOut = calculateExpectedOutput(amountIn, path);
        uint excessMEV = actualOut > expectedOut ? actualOut - expectedOut : 0;

        if (excessMEV > 0) {
            // Burn or redirect to treasury
            mevBurn += excessMEV;
            IERC20(path[path.length - 1]).transfer(address(0), excessMEV / 2);
        }

        // 3. Transfer fair share to user
        IERC20(path[path.length - 1]).transfer(
            msg.sender,
            actualOut - (excessMEV / 2)
        );
    }
}
```

### Strategy 3: Intent-Based Architecture (UniswapX)

```solidity
// Users sign intent (not transaction)
// Solvers compete to fulfill at best price
// Eliminates frontrunning by design

contract IntentBasedSwap {
    struct SwapIntent {
        address user;
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint minAmountOut;
        uint deadline;
        bytes signature;
    }

    mapping(bytes32 => bool) executedIntents;

    function fulfillIntent(
        SwapIntent calldata intent,
        uint actualOut
    ) external {
        // 1. Verify signature (user authorized this intent, not specific path)
        require(
            verify(intent.user, intent),
            "Invalid signature"
        );

        // 2. Verify not already executed
        bytes32 intentHash = hashIntent(intent);
        require(!executedIntents[intentHash], "Already executed");

        // 3. Verify output meets minimum
        require(actualOut >= intent.minAmountOut, "Insufficient output");

        // 4. Mark as executed
        executedIntents[intentHash] = true;

        // 5. Solver (msg.sender) fulfills at their cost
        // Competition between solvers ensures best price
        // No MEV bot can frontrun - intent doesn't specify execution path

        IERC20(intent.tokenOut).transfer(intent.user, actualOut);

        emit IntentFulfilled(intentHash, actualOut, msg.sender);
    }

    function hashIntent(SwapIntent calldata intent) internal pure returns (bytes32) {
        return keccak256(abi.encode(intent));
    }

    function verify(
        address user,
        SwapIntent calldata intent
    ) internal pure returns (bool) {
        bytes32 hash = hashIntent(intent);
        // Recover signature and verify = user
        // (EIP-191 signing standard)
        return true;
    }
}
```

### Strategy 4: Rate Limiting & Account Restrictions

```solidity
contract RateLimitedSwap {
    mapping(address => UserQuota) quotas;
    mapping(address => bool) whitelisted;

    struct UserQuota {
        uint256 swapsPerHour;
        uint256 maxVolumePerHour;
        uint256 lastResetTime;
    }

    function initializeQuota(
        address user,
        uint256 maxSwapsPerHour,
        uint256 maxVolumePerHour
    ) external onlyAdmin {
        quotas[user] = UserQuota({
            swapsPerHour: maxSwapsPerHour,
            maxVolumePerHour: maxVolumePerHour,
            lastResetTime: block.timestamp
        });
    }

    function swapWithRateLimit(
        address user,
        uint amountIn,
        address[] memory path,
        uint minOut
    ) external {
        // 1. Check if user is whitelisted (bot farms)
        require(!whitelisted[user] || msg.sender == user, "Bot detected");

        // 2. Reset quota if hour has passed
        UserQuota storage quota = quotas[user];
        if (block.timestamp >= quota.lastResetTime + 1 hours) {
            quota.swapsPerHour = quotas[user].swapsPerHour;
            quota.maxVolumePerHour = quotas[user].maxVolumePerHour;
            quota.lastResetTime = block.timestamp;
        }

        // 3. Check swap count limit
        require(quota.swapsPerHour > 0, "Swap limit exceeded");
        quota.swapsPerHour--;

        // 4. Check volume limit
        require(amountIn <= quota.maxVolumePerHour, "Volume limit exceeded");
        quota.maxVolumePerHour -= amountIn;

        // 5. Execute swap
        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            user,
            block.timestamp + 300
        );
    }

    function whitelistAddress(address account) external onlyAdmin {
        // Skip rate limits for known bots (your own bot, market makers)
        whitelisted[account] = true;
    }
}
```

### Strategy 5: Commitments & Reveals (2-Step)

```solidity
// Prevent snipers from seeing your swap parameters

contract CommitRevealSwap {
    mapping(bytes32 => Commitment) commitments;

    struct Commitment {
        address user;
        bytes32 dataHash;
        uint commitTime;
        bool revealed;
    }

    // Step 1: User commits (hash of actual swap data)
    function commitSwap(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint minOut,
        uint nonce
    ) external {
        bytes32 dataHash = keccak256(abi.encode(tokenIn, tokenOut, amountIn, minOut, nonce));
        bytes32 commitmentHash = keccak256(abi.encode(msg.sender, dataHash));

        commitments[commitmentHash] = Commitment({
            user: msg.sender,
            dataHash: dataHash,
            commitTime: block.timestamp,
            revealed: false
        });

        emit CommitmentMade(commitmentHash);
    }

    // Step 2: User reveals (actual swap data)
    // At least 1 block later, bots don't have time to react
    function revealAndSwap(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint minOut,
        uint nonce
    ) external {
        bytes32 dataHash = keccak256(abi.encode(tokenIn, tokenOut, amountIn, minOut, nonce));
        bytes32 commitmentHash = keccak256(abi.encode(msg.sender, dataHash));

        Commitment storage commitment = commitments[commitmentHash];
        require(commitment.user == msg.sender, "Invalid commitment");
        require(!commitment.revealed, "Already revealed");
        require(
            block.timestamp >= commitment.commitTime + 1,
            "Must wait at least 1 block"
        );

        commitment.revealed = true;

        // Execute swap (bots had no advance notice)
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            msg.sender,
            block.timestamp + 300
        );

        emit SwapRevealed(commitmentHash);
    }
}
```

---

## Sniper Bot Attack Vectors

### ⚠️ Vector 1: Liquidity Provider Sniping

```
Attacker monitors: New token launch with low liquidity

1. Sees pending addLiquidity() tx
2. Frontruns: Contributes large liquidity
3. Your tx: Creates pool with diluted share
4. Attacker backruns: Removes liquidity + profit

Protection: Verify liquidity exists from trusted source
```

### ⚠️ Vector 2: Price Oracle Manipulation

```
Attacker targets protocols using Uniswap prices directly

1. Snipers: Buy token heavily (moves price up)
2. Your liquidation: Uses inflated price oracle
3. You get liquidated unfairly
4. Attackers: Dump tokens, profit

Protection: Use TWAP (time-weighted average price)
```

### ⚠️ Vector 3: Slippage Exhaustion

```
Multiple snipers gang up on single target

Victim: Attempts $1M swap with 1% slippage protection
Snipers: 10 bots coordinate sandwich attack

Each bot extracts 0.1%, total = 1% of victim's output
Transaction still passes (exactly at slippage limit)
Victim loses entire profit opportunity

Protection: Use adaptive slippage, more frequent checks
```

---

## Prevention Checklist

- [ ] Private mempool service enabled (Flashbots)?
- [ ] MEV-burn or capture mechanism in place?
- [ ] Rate limiting implemented?
- [ ] 2-step commit-reveal for sensitive txs?
- [ ] Intent-based architecture for applicable flows?
- [ ] TWAP oracle instead of spot price?
- [ ] Anomaly detection for user behavior?
- [ ] Gas price validation?
- [ ] Emergency pause mechanism if detected?
- [ ] User education about MEV risks?

---

## Tools & Resources

| Service | Purpose | Cost |
|---------|---------|------|
| **Flashbots Protect** | Private mempool | Free |
| **MEV-Burn Protocol** | Capture MEV | Protocol-dependent |
| **UniswapX** | Intent-based swaps | Free (incentivized) |
| **CoW Protocol** | Batch auctions | ~0.05% maker rebate |
| **MEV-Inspect** | MEV analysis | Free |

---

## Resources

- **Flashbots Docs**: https://docs.flashbots.net/
- **MEV-Burn Spec**: https://eips.ethereum.org/EIPS/eip-1559
- **UniswapX Docs**: https://uniswapx.org/

---

**Next:** Read `04-flash-swaps.md` for flash swap attack prevention.
