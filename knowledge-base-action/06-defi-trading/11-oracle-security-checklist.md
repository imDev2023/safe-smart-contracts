# Oracle Security Checklist

> Quick security verification for oracle integration (3 min read)

## Price Feed Safety (10 items)

- [ ] **Staleness Check**: Verify `updatedAt` is recent (< 1 hour)
  ```solidity
  require(block.timestamp - updatedAt < 1 hours, "Price too old");
  ```

- [ ] **Zero Price Check**: Reject if price = 0
  ```solidity
  require(price > 0, "Invalid price");
  ```

- [ ] **Decimal Handling**: Convert to correct decimals (Chainlink = 8, expect 18)
  ```solidity
  uint256 normalizedPrice = uint256(price) * 10**10;
  ```

- [ ] **Negative Price Handling**: Handle signed integer safely
  ```solidity
  require(price > 0, "Price must be positive");
  ```

- [ ] **Multi-Oracle Consensus**: Don't rely on single feed
  ```solidity
  uint256 primary = chainlinkPrice();
  uint256 fallback = bandProtocolPrice();
  require(abs(primary - fallback) < tolerance, "Price divergence");
  ```

- [ ] **Sequencer Uptime Check** (L2 chains only):
  ```solidity
  AggregatorV3Interface sequencerFeed = AggregatorV3Interface(0x...);
  (, int256 answer, , uint256 updatedAt, ) = sequencerFeed.latestRoundData();
  require(answer == 1, "Sequencer down");
  require(block.timestamp - updatedAt < 60, "Sequencer status stale");
  ```

- [ ] **Deviation Threshold**: Check price doesn't deviate from TWAP
  ```solidity
  uint256 twapPrice = getTWAPPrice();
  require(price < twapPrice * 1.05, "Price +5% deviation");
  require(price > twapPrice / 1.05, "Price -5% deviation");
  ```

- [ ] **Upper Bound Check**: Reject unreasonably high prices
  ```solidity
  require(price < MAX_REASONABLE_PRICE, "Price too high");
  ```

- [ ] **Access Control**: Only trusted addresses can update critical values
  ```solidity
  require(msg.sender == priceAdmin, "Not authorized");
  ```

- [ ] **Event Logging**: Emit events for price updates and failures
  ```solidity
  event PriceFetched(uint256 indexed price, uint256 timestamp);
  emit PriceFetched(price, block.timestamp);
  ```

## Chainlink Specific (8 items)

- [ ] **AggregatorV3Interface Used**: Correct interface imported
  ```solidity
  import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
  ```

- [ ] **latestRoundData Verification**: All return values validated
  ```solidity
  (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
  require(answeredInRound >= roundId, "Stale round");
  ```

- [ ] **Subscription Funded** (VRF): LINK balance checked
  ```solidity
  (, , , uint96 balance, ) = vrfCoordinator.getSubscriptionDetail(subscriptionId);
  require(balance > 0, "No LINK in subscription");
  ```

- [ ] **Gas Limit Reasonable** (VRF/Automation):
  - VRF: 100,000 - 500,000 (typical)
  - Automation: 500,000 - 2,000,000 (typical)

- [ ] **Feed Whitelisting**: Contract specifies which feeds are acceptable
  ```solidity
  mapping(address => bool) public authorizedFeeds;
  require(authorizedFeeds[feedAddress], "Unauthorized feed");
  ```

- [ ] **Request Tracking** (VRF/Automation):
  ```solidity
  mapping(uint256 => RequestState) public requests;
  mapping(uint256 => bool) public processed;
  ```

- [ ] **Callback Errors Handled**: Failed callbacks don't break contract
  ```solidity
  try vrfCoordinator.requestRandomWords(...) returns (uint256 requestId) {
      // Success
  } catch {
      // Fallback to pseudorandom or retry
  }
  ```

- [ ] **Documentation**: Feed address and contract interaction documented
  ```
  ETH/USD Feed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
  Data: 8 decimals, rounds answered >= roundId
  ```

## Multi-Oracle Pattern (6 items)

- [ ] **Primary + Fallback**: Two feeds minimum
  ```solidity
  if (chainlinkFeed.stale()) {
      price = bandProtocolFeed.getPrice();
  } else {
      price = chainlinkFeed.getPrice();
  }
  ```

- [ ] **Weighted Average**: Combine multiple sources
  ```solidity
  price = (chainlink * 70 + band * 20 + pyth * 10) / 100;
  ```

- [ ] **Consensus Check**: Requires N/M feeds to agree
  ```solidity
  uint256[] memory prices = new uint256[](3);
  prices[0] = chainlinkPrice();
  prices[1] = bandPrice();
  prices[2] = pythPrice();

  sort(prices);
  uint256 median = prices[1]; // Use median
  ```

- [ ] **Timeout Fallback**: If all feeds stale, use last known good price
  ```solidity
  if (allFeedsStale()) {
      require(lastValidPrice != 0, "No price available");
      price = lastValidPrice;
  }
  ```

- [ ] **Divergence Detection**: Alert if feeds disagree significantly
  ```solidity
  uint256 max = max(prices);
  uint256 min = min(prices);
  require(max - min < max / 20, "Feeds diverged >5%");
  ```

- [ ] **Feed Health Monitoring**: Track which feeds fail
  ```solidity
  mapping(address => uint256) public feedFailures;
  if (feedFails()) {
      feedFailures[feed]++;
      if (feedFailures[feed] > MAX_FAILURES) {
          removeFeed(feed);
      }
  }
  ```

## Flash Loan Protection (4 items)

- [ ] **TWAP Fallback**: Use time-weighted average price
  ```solidity
  // TWAP is resistant to single-block price manipulations
  uint256 twapPrice = getTWAPPrice();
  ```

- [ ] **Time Lock**: Prices used from previous blocks
  ```solidity
  // Use price from block.timestamp - 1 minute
  // Prevents flash loan same-block manipulation
  ```

- [ ] **Minimum Liquidity Check**: Pool has enough liquidity
  ```solidity
  require(getUniswapLiquidity() > MIN_LIQUIDITY, "Low liquidity");
  ```

- [ ] **Post-Action Validation**: Check invariants after oracle call
  ```solidity
  uint256 balanceBefore = getBalance();
  // Oracle call here
  uint256 balanceAfter = getBalance();
  require(balanceAfter >= balanceBefore, "Balance decreased");
  ```

## VRF Security (4 items)

- [ ] **Request Nonce**: Each request has unique nonce
  ```solidity
  mapping(uint256 => bool) public requestProcessed;
  require(!requestProcessed[requestId], "Already processed");
  requestProcessed[requestId] = true;
  ```

- [ ] **Callback Gas Limit Sufficient**: Won't run out of gas
  ```solidity
  // Test with actual data to ensure completeness
  // Gas needed = actual + safety buffer
  ```

- [ ] **Proof Validation**: Chainlink proof verified on-chain
  ```solidity
  // Chainlink validates: sha256(proof || preimage) == output
  // This happens automatically in fulfillRandomWords
  ```

- [ ] **Timeout Handling**: Stale requests handled gracefully
  ```solidity
  if (block.timestamp - requestTime > TIMEOUT) {
      // Retry or fallback to pseudorandom
  }
  ```

## Testing Checklist (5 items)

- [ ] **Unit Tests**: Each price feed tested in isolation
  - Test staleness detection
  - Test zero price handling
  - Test decimal conversion

- [ ] **Integration Tests**: Multiple feeds working together
  - Test consensus logic
  - Test fallback triggers
  - Test divergence detection

- [ ] **Fork Tests**: Test against actual Chainlink on mainnet
  ```bash
  forge test --fork-url $ETH_RPC_URL
  ```

- [ ] **Gas Tests**: Ensure gas limits are sufficient
  ```solidity
  uint256 gasUsed = 100000; // Measured from test
  require(callbackGasLimit > gasUsed * 1.2, "Gas limit too low");
  ```

- [ ] **Mocking**: Contract works with mock oracles
  ```solidity
  contract MockAggregator {
      function latestRoundData() external view returns (...) {
          return (0, mockPrice, 0, block.timestamp, 0);
      }
  }
  ```

## Deployment Checklist (5 items)

- [ ] **Feed Addresses Correct**: Triple-check feed contract addresses
  ```
  ✓ Mainnet ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
  ✓ Arbitrum ETH/USD: 0x639Fe6ab55C921f74e7fac19EEa543D3497e63A8
  ```

- [ ] **VRF Subscription Funded**: LINK tokens in subscription
  - Min 5 LINK for testing
  - Min 50 LINK for production

- [ ] **Automation Upkeep Registered**: Contract addresses correct
  - checkUpkeep function accessible
  - performUpkeep function executable

- [ ] **Access Control Deployed**: Only authorized addresses can call
  ```solidity
  require(hasRole(PRICE_UPDATER_ROLE, msg.sender));
  ```

- [ ] **Monitoring Enabled**: Alerts configured for:
  - Price staleness
  - Feed failures
  - Automation execution failures
  - VRF callback failures

---

**Use case-specific**: See `02-slippage-protection-checklist.md`
**Integration steps**: See `08-chainlink-datafeed-integration.md`
