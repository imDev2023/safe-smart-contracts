# MEV Mitigation Strategies

**Status:** Critical Strategy Guide | **Level:** Advanced | **Impact:** Essential for protocol health

## What is MEV (Maximal Extractable Value)?

**MEV** = Value that can be extracted by reordering, censoring, or inserting transactions into blocks.

### The MEV Economy

```
Annual MEV in Ethereum (2024):
- Sandwich attacks: ~$200M
- Liquidations: ~$150M
- DEX arbitrage: ~$100M
- Other (oracle, atomic swaps): ~$50M
- Total: ~$500M+

Per-transaction impact:
- Small trade ($1k): $1-10 loss (0.1-1%)
- Medium trade ($100k): $500-5000 loss (0.5-5%)
- Large trade ($1M): $10k-100k loss (1-10%)
- Whale trades ($10M+): $100k-1M+ loss (1-10%)

Winners: Validators, attackers
Losers: Users
```

---

## MEV Categories

### Category 1: Sandwich Attacks (Front-running + Back-running)

```
Classic pattern:

Mempool: Your swap "Buy 100k USDC → ETH"

Block assembly:
1. Attacker TX: Swap 5 ETH → 250k USDC (frontr un)
   - Moves price: 1 ETH was $3000, now $2800
2. Your TX: Swap 100k USDC → 35.7 ETH (worse price!)
   - Expected: 33.3 ETH
   - Got: 35.7 ETH (missed 2.6 ETH / $7,800)
3. Attacker TX: Swap 250k USDC → 89.3 ETH (backrun)
   - Price recovered somewhat

Attacker profit: ~2-3 ETH
User loss: ~0.7 ETH = $2,100

Year for all users: ~$200M extracted
```

### Category 2: Liquidation Extraction

```
Protocol allows liquidations at small discount (e.g., 5%)

Attacker monitors:
- User positions about to be liquidatable
- Oracle prices
- Gas prices for profitable execution

Execution:
1. Liquidator authorized to:
   - Seize collateral at 5% discount
   - Get 5% penalty fee
2. Multiple liquidators compete
3. Attacker monitors and frontruns:
   - Sees liquidation transaction
   - Liquidates first (gets 5% reward)
   - Takes 5% + gas costs from victim

Annual impact: ~$150M+ extracted
```

### Category 3: Arbitrage MEV

```
Multi-venue arbitrage with public knowledge:

Uniswap: 1 ETH = 2000 USDC
Sushiswap: 1 ETH = 2010 USDC
Difference: 10 USDC / ETH

Public strategy: Buy on Uni, sell on Sushi, profit $10/ETH

Multiple bots compete:
1. Bot 1: See opportunity in mempool
2. Bot 2: Same
3. Both submit transactions
4. Attacker sees both, frontruns + inserts own tx
5. Transaction order: Attacker, Bot1, Bot2, Your Trade
6. Attacker extracts value from both bots

Arb profit: $10/ETH - MEV extraction
Bots lose: Compete but don't profit
```

---

## MEV Mitigation Strategies

### Strategy 1: Private Mempools (Flashbots Protect)

**Concept:** Hide your transaction from MEV bots entirely.

```solidity
// Normal flow (public)
// ❌ Attacker sees in mempool
// ❌ Frontrunning possible

// Private mempool flow (Flashbots)
// ✅ Only included in block (validator sees)
// ✅ Bots never see in mempool
// ❌ Cost: Validator fee (minimal, $0.01-$0.10)
// ❌ Cost: Potential latency (next block or +1)

contract PrivateMempoolSwap {
    // Send transaction directly to Flashbots Protect relay
    // https://protect.flashbots.net/

    // JSON-RPC: eth_sendPrivateTransaction
    // Body: {
    //   "jsonrpc": "2.0",
    //   "method": "eth_sendPrivateTransaction",
    //   "params": [{
    //     "tx": "0x...",
    //     "preferences": {
    //       "hints": {
    //         "calldata": true,
    //         "functionSelector": true,
    //         "logs": true
    //       }
    //     }
    //   }],
    //   "id": 1
    // }

    // Benefits:
    // 1. Sandwich attack impossible (hidden from bots)
    // 2. Slippage limited to actual price impact only
    // 3. No validator extraction (Flashbots protocol)
    // 4. Backed by academic research
}
```

### Strategy 2: Batch Auctions (CoW Protocol Pattern)

**Concept:** Batch users' intentions, solve optimally, execute atomically.

```solidity
// Instead of: Individual swap TX → Exposed to MEV
// Use: Batch of intents → Solver optimization → Atomic execution

contract BatchAuction {
    struct Order {
        address user;
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint minAmountOut;
        uint deadline;
        bytes signature;  // User signed intent
    }

    mapping(uint => Order[]) public batches;
    uint public currentBatch;
    uint public batchWindow = 12; // ~12 second batches

    // Step 1: Users submit intents (not transactions!)
    function submitOrder(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint minAmountOut,
        bytes calldata signature
    ) external {
        Order memory order = Order({
            user: msg.sender,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            minAmountOut: minAmountOut,
            deadline: block.timestamp + 300,
            signature: signature
        });

        batches[currentBatch].push(order);
        emit OrderSubmitted(msg.sender, order);
    }

    // Step 2: After batch window, solvers bid to fulfill batch
    function settleBatch(
        uint batchId,
        bytes calldata executionData  // How solver will fulfill
    ) external {
        // Solver provides best execution path
        // Batches all orders together
        // Everyone gets price benefit from batch depth
        // MEV from "intents" captured and distributed

        Order[] storage orders = batches[batchId];

        for (uint i = 0; i < orders.length; i++) {
            // Execute all orders atomically
            // Price: Best possible given batch
            // MEV benefit: Shared among users
        }
    }

    // Benefits:
    // 1. Individual orders not visible (no frontrunning)
    // 2. Batch solves optimally
    // 3. Users get best aggregate price
    // 4. MEV captured by protocol, not attackers
    // 5. Fair price discovery
}
```

### Strategy 3: MEV-Burn (EIP-1559 Style)

**Concept:** Capture MEV and burn it instead of letting attackers take it.

```solidity
contract MEVBurnedSwaps {
    // Every swap has potential MEV
    // Standard: Attacker takes MEV
    // MEV-Burn: Protocol captures MEV, burns it

    uint256 public totalMEVBurned;

    function swapWithMEVCapture(
        uint amountIn,
        address[] memory path,
        uint minOut
    ) external returns (uint actualOut) {
        // 1. Calculate fair/expected output
        uint expectedOut = calculateFairPrice(amountIn, path);

        // 2. Execute swap
        router.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            address(this),
            block.timestamp + 300
        );

        // 3. Get actual output
        actualOut = IERC20(path[path.length - 1]).balanceOf(address(this));

        // 4. Identify MEV (good luck for user = bad for attacker)
        uint mevExtracted;

        if (actualOut > expectedOut) {
            // Good luck scenario: Got better than expected
            mevExtracted = actualOut - expectedOut;
        } else if (actualOut < expectedOut * 99 / 100) {
            // Bad slippage: Likely sandwich attack
            mevExtracted = expectedOut - actualOut;
        }

        // 5. Burn half, return half to user
        if (mevExtracted > 0) {
            uint toBurn = mevExtracted / 2;
            IERC20(path[path.length - 1]).transfer(address(0), toBurn);
            totalMEVBurned += toBurn;
            actualOut -= toBurn;  // User receives less, but MEV is destroyed
        }

        // 6. Return to user
        IERC20(path[path.length - 1]).transfer(msg.sender, actualOut);

        emit SwapExecuted(msg.sender, amountIn, actualOut, mevExtracted);
    }

    function calculateFairPrice(
        uint amountIn,
        address[] memory path
    ) internal view returns (uint) {
        // Calculate theoretical output without MEV
        // Using TWAP or fair pricing oracle
        return 0;  // Simplified
    }
}
```

### Strategy 4: Intent-Based Architecture (UniswapX)

**Concept:** Users sign "intent" (not specific TX), solvers compete to fulfill optimally.

```solidity
// User signs: "I want to swap USDC → USDT, minimum 995 USDT"
// User doesn't specify: Route, slippage, timing, MEV tactics

// Solvers see intent and compete:
// Solver 1: Offers 1000 USDT via Uniswap V3
// Solver 2: Offers 1001 USDT via CoW + Batch
// Solver 3: Offers 1002 USDT via MEV-resistant arch

// User gets: Best offer (1002 USDT)
// MEV extractor: None (solvers absorb/optimize)
// Attacker: Can't frontrun, doesn't know execution path

interface IIntentRouter {
    struct SwapIntent {
        address user;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint amountIn;
        uint amountOutMinimum;
        bytes signature;
    }

    // User signs intent (not specific execution)
    function submitIntent(SwapIntent calldata intent) external;

    // Solver fulfills with best path
    function fulfillIntent(
        SwapIntent calldata intent,
        bytes calldata executionPath
    ) external;
}

contract IntentBasedSwap {
    function submitSwapIntent(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint amountIn,
        uint amountOutMin
    ) external {
        // Intent: Swap 1000 USDC → USDT, min 995
        // No executor specified
        // No path specified
        // Completely MEV-resistant

        // Signature proves user authorized
        // Solvers compete to fulfill
        // User gets best price
    }
}
```

### Strategy 5: Threshold Encryption (MPC Networks)

**Concept:** Encrypt transaction contents until block inclusion.

```solidity
// Public key cryptography prevents visualization

contract EncryptedSwap {
    struct EncryptedSwap {
        bytes encryptedData;  // Encrypted swap parameters
        address timelock;     // MPC network
        uint threshold;       // m-of-n shares needed to decrypt
    }

    // 1. User encrypts swap with MPC network's public key
    // 2. Submits encrypted transaction
    // 3. MEV bots can't see contents
    // 4. Network validates threshold
    // 5. Decrypts at block proposal time
    // 6. Attacker has insufficient time to react

    function submitEncryptedSwap(
        bytes calldata encryptedData,
        bytes calldata encryptedKey
    ) external {
        // Transaction hidden from mempool
        // Decryption happens at block time
        // No time for frontrunning

        // Trade-off: Requires MPC infrastructure (Shutter Network)
        // Cost: Small MPC fee
        // Benefit: MEV-resistance at protocol level
    }
}
```

---

## MEV Mitigation Comparison

| Strategy | Cost | MEV Protection | Latency | Complexity |
|----------|------|----------------|---------|------------|
| **Private Mempool** | $0.01-0.10 | 95% | +1 sec | Low |
| **Batch Auctions** | ~0.05% | 99% | +12 sec | Medium |
| **MEV-Burn** | Fee burn | 50% | None | Medium |
| **Intent-Based** | Solver comp | 99% | Varies | High |
| **Threshold Crypto** | ~0.10% | 99%+ | +5 sec | Very High |

---

## Real MEV Scenarios & Solutions

### Scenario 1: High Gas Market (Sandwich Favorite)

**Problem:** When gas is expensive, frontrunning sandwich attacks more profitable.

```solidity
contract GasSensitiveMitigation {
    uint public maxGasPrice = 200 gwei;  // Adjust based on risk

    function swapWithGasCheck(
        uint amountIn,
        address[] memory path,
        uint minOut
    ) external {
        // 1. Check if market conditions favor MEV
        if (tx.gasprice > maxGasPrice) {
            // High gas market = High MEV risk
            // Options:
            // a) Revert and wait for lower gas
            // b) Use private mempool (costs more but safer)
            // c) Increase slippage tolerance (accept some loss)

            if (shouldUsePrivateMempool()) {
                submitToFlashbots();  // Safe but slower
            } else {
                // Accept higher slippage
                uint adjustedMinOut = (minOut * 95) / 100;
                executeSwap(amountIn, path, adjustedMinOut);
            }
        } else {
            // Normal conditions
            executeSwap(amountIn, path, minOut);
        }
    }

    function shouldUsePrivateMempool() internal view returns (bool) {
        // Use private mempool if:
        // 1. High gas price (>150 gwei)
        // 2. Large transaction (>$10k)
        // 3. Volatile market (TWAP changed >5% in last min)
        return true;
    }
}
```

### Scenario 2: Liquidation Competition

**Problem:** Liquidators fight over rewards, creating MEV extraction.

```solidity
contract MEVFriendlyLiquidation {
    // Instead of: Open liquidation competition (MEV fest)
    // Use: Fair liquidation auction

    struct LiquidationAuction {
        address debtor;
        uint collateralAmount;
        uint debtAmount;
        uint auctionStart;
        uint highestBid;
        address highestBidder;
    }

    mapping(bytes32 => LiquidationAuction) auctions;

    function openLiquidationAuction(
        address debtor,
        uint collateralAmount,
        uint debtAmount
    ) external {
        bytes32 auctionId = keccak256(abi.encode(debtor, block.timestamp));

        auctions[auctionId] = LiquidationAuction({
            debtor: debtor,
            collateralAmount: collateralAmount,
            debtAmount: debtAmount,
            auctionStart: block.timestamp,
            highestBid: debtAmount,
            highestBidder: address(0)
        });

        emit AuctionOpened(auctionId);
    }

    function bid(
        bytes32 auctionId,
        uint bidAmount
    ) external {
        LiquidationAuction storage auction = auctions[auctionId];

        // Auction period: 30 minutes
        require(
            block.timestamp <= auction.auctionStart + 30 minutes,
            "Auction expired"
        );

        // Bid must exceed current high bid
        require(bidAmount > auction.highestBid, "Bid too low");

        // Liquidator with best offer wins
        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }

    function settleAuction(bytes32 auctionId) external {
        LiquidationAuction storage auction = auctions[auctionId];

        require(
            block.timestamp > auction.auctionStart + 30 minutes,
            "Auction not ended"
        );

        // Winner pays best price found
        // Debtor gets fair liquidation price
        // No sandwiching possible (30 min window)
        // Transparent process
    }

    // Benefits:
    // 1. Fair liquidation price discovered
    // 2. No frontrunning liquidations
    // 3. Liquidation fees transparent
    // 4. MEV captured by protocol, not attacker
}
```

---

## MEV Mitigation Checklist

- [ ] Private mempool enabled for sensitive operations?
- [ ] Batch auction system for high-risk transactions?
- [ ] MEV-Burn mechanism for capturing MEV?
- [ ] Intent-based architecture for applicable flows?
- [ ] TWAP oracle instead of spot price?
- [ ] Gas price monitoring and adaptive strategies?
- [ ] Liquidation auction instead of open competition?
- [ ] Rate limiting on critical functions?
- [ ] Cross-protocol isolation (no atomic operations)?
- [ ] Timeout/deadline enforcement?
- [ ] User education about MEV risks?
- [ ] Emergency pause on anomalous MEV?
- [ ] Monitoring system for MEV extraction?
- [ ] Regular audits of MEV vectors?

---

## Tools & Services

| Service | Purpose | Cost |
|---------|---------|------|
| **Flashbots Protect** | Private mempool | Free/donation |
| **MEV-Burn Protocol** | Capture MEV | Protocol fee |
| **CoW Protocol** | Batch auctions | ~0.05% fee |
| **Shutter Network** | Threshold crypto | ~0.10% fee |
| **MEV-Inspect** | MEV monitoring | Free |

---

## Resources

- **Flashbots Research**: https://www.flashbots.net/
- **MEV-Burn (EIP-1559)**: https://eips.ethereum.org/EIPS/eip-1559
- **CoW Protocol Docs**: https://docs.cow.fi/
- **UniswapX Docs**: https://uniswapx.org/

---

**Next:** Read `06-price-oracles.md` for oracle safety and Chainlink integration.
