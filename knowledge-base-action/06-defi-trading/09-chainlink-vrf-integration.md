# Chainlink VRF Integration Guide

> Integrate Chainlink VRF for provably fair randomness (5 min read)

## Quick Integration (4 steps)

### Step 1: Set Up Subscription
```
1. Go to https://vrf.chain.link
2. Click "Create Subscription"
3. Fund with LINK tokens
4. Copy Subscription ID
5. Add your contract as consumer
```

### Step 2: Import VRF Consumer
```solidity
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Lottery is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface internal vrfCoordinator;
    uint64 internal subscriptionId;
    bytes32 internal keyHash; // Gas lane key hash
    uint32 internal callbackGasLimit = 100000;
    uint16 internal requestConfirmations = 3;
    uint32 internal numWords = 1; // Number of random words

    constructor(
        address vrfCoordinatorAddress,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }
}
```

### Step 3: Request Randomness
```solidity
mapping(uint256 => address) public requestIdToSender;

function requestRandomWinner() external returns (uint256) {
    uint256 requestId = vrfCoordinator.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
    );

    requestIdToSender[requestId] = msg.sender;
    return requestId;
}
```

### Step 4: Handle Random Number
```solidity
function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
) internal override {
    address winner = requestIdToSender[requestId];
    uint256 randomNumber = randomWords[0];
    uint256 winnerIndex = randomNumber % participants.length;

    // Pay winner
    payable(participants[winnerIndex]).transfer(prize);
}
```

## Configuration by Chain

### Ethereum Mainnet
```solidity
address VRF_COORDINATOR = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
bytes32 KEY_HASH = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
uint64 SUBSCRIPTION_ID = YOUR_SUBSCRIPTION_ID;
```

### Arbitrum
```solidity
address VRF_COORDINATOR = 0x50d47e4142D4ccB4ee4E2299f8891cBb64fc50e1;
bytes32 KEY_HASH = 0x27f86d03787ec002d30e21c3fac3d1c45ce7d0439018de51df1979eac6ccc500;
```

### Polygon
```solidity
address VRF_COORDINATOR = 0xAE975071Be8F8eE67addBC1A82909F32bAccaD3c;
bytes32 KEY_HASH = 0xd4bb89654db74673a187bd804519e7ba3544eb21fbee16de3b23c35bde64b47b;
```

## Full Working Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract SimpleRaffle is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface internal vrfCoordinator;
    uint64 internal subscriptionId;
    bytes32 internal keyHash;
    uint32 internal callbackGasLimit = 100000;
    uint16 internal requestConfirmations = 3;
    uint32 internal numWords = 1;

    address payable[] public participants;
    address payable public winner;
    uint256 public lastRequestId;

    event WinnerSelected(address indexed winner, uint256 prize);

    constructor(
        address vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    // Users enter raffle by sending ETH
    function enter() external payable {
        require(msg.value >= 0.1 ether, "Minimum 0.1 ETH");
        participants.push(payable(msg.sender));
    }

    // Trigger random winner selection
    function pickWinner() external returns (uint256 requestId) {
        require(participants.length > 0, "No participants");

        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        lastRequestId = requestId;
        return requestId;
    }

    // Chainlink callback (automatic)
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(requestId == lastRequestId, "Invalid request");

        uint256 randomWord = randomWords[0];
        uint256 winnerIndex = randomWord % participants.length;
        winner = participants[winnerIndex];

        uint256 prize = address(this).balance;
        winner.transfer(prize);

        emit WinnerSelected(winner, prize);

        // Reset for next raffle
        delete participants;
    }

    receive() external payable {}
}
```

## Cost Analysis

```
VRF v2 Pricing (per request):
- Flat fee:        0.25 LINK
- Per word fee:    0.001 LINK (per random word)
- Gas premium:     Premium % of txn gas

Total ≈ 5-50 LINK per request
(Ethereum mainnet with 1-3 words)
```

## Best Practices

### ✅ DO:

```solidity
// 1. Set appropriate request confirmations
uint16 requestConfirmations = 3; // 3 blocks minimum

// 2. Set reasonable gas limit
uint32 callbackGasLimit = 100000; // Enough for your logic

// 3. Validate subscription has LINK
require(vrfCoordinator.getSubscriptionDetail(subscriptionId).balance > minLink);

// 4. Handle request timeout
mapping(uint256 => uint256) public requestTimestamps;

function timeoutRequest(uint256 requestId) external {
    require(block.timestamp - requestTimestamps[requestId] > 1 days);
    // Refund or retry
}

// 5. Use request ID as unique identifier
mapping(uint256 => RequestState) public requests;
```

### ❌ DON'T:

```solidity
// 1. Don't use randomness for critical decisions without confirmation
// Miners can predict future randomness

// 2. Don't set gas limit too low
callbackGasLimit = 10000; // ⚠️ Will run out of gas

// 3. Don't ignore callback failures
// If fulfillRandomWords fails, retry mechanism is needed

// 4. Don't reuse request IDs
mapping(uint256 => bool) processed;
require(!processed[requestId], "Already processed");
processed[requestId] = true;
```

## Security Considerations

### Randomness Fairness
- VRF uses ECVRF (Elliptic Curve VRF)
- Cryptographically proves randomness wasn't pre-determined
- Resistant to miner manipulation

### Verification
```solidity
// Chainlink provides proof of randomness
// contract validates: sha256(proof + seed) == output
// Prevents Chainlink from cheating
```

### Request Timeouts
```solidity
// Requests can time out if:
// - Subscription runs out of LINK
// - Network congestion
// - Chainlink network issues

// Always have fallback mechanism:
if (requestTimedOut(requestId)) {
    selectWinnerDeterministically();
}
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Low gas limit | Callback fails | Increase to 100k+ |
| Expired LINK | Requests rejected | Monitor subscription |
| Race conditions | Multiple fulfillments | Use nonce tracking |
| Insufficient randomness | Predictable outcome | Use all random words |

---

**For price feeds**: See `08-chainlink-datafeed-integration.md`
**For automation**: See `09-chainlink-automation-integration.md`
**Deep dive**: See `knowledge-base-research/repos/chainlink/11-chainlink-oracle-deep-dive.md`
