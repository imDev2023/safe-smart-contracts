# Seaport NFT Marketplace - Deep Dive

**Source:** https://github.com/ProjectOpenSea/seaport
**Purpose:** Efficient NFT trading protocol with flexible offer/consideration
**Latest Version:** 1.6
**Battle-tested:** $1B+ in transaction volume
**Security:** Multiple professional audits

---

## Problem Seaport Solves

### Pre-Seaport NFT Trading

1. **Separate contracts for each use case:**
   - Buy fixed-price listing
   - Sell with auction
   - Make offer on item
   - Each required different contract interaction

2. **Limited composability:**
   - Couldn't bundle NFTs
   - Couldn't specify multi-recipient sales
   - Royalties handled ad-hoc

3. **Gas inefficiency:**
   - Multiple contract calls for complex trades
   - No batch operations

### Seaport Solution

- **Unified interface:** One contract handles all trade types
- **Flexible offer/consideration:** Bundle any items with any requirements
- **Efficient matching:** Optimized order fulfillment
- **Royalty support:** Native consideration splitting

---

## Architecture

### Core Components

```
SeaportInterface (Main)
    ├─ OrderValidator
    │   ├─ Validates order structure
    │   ├─ Checks signatures
    │   └─ Verifies time windows
    │
    ├─ FulfillmentApplier
    │   ├─ Matches offer items to consideration
    │   ├─ Calculates amounts (linear scaling)
    │   └─ Applies fulfillments
    │
    ├─ TokenTransferrer
    │   ├─ ERC721 transfers
    │   ├─ ERC1155 batch transfers
    │   ├─ ERC20 transfers
    │   └─ Native ETH transfers
    │
    └─ ConduitController
        ├─ Pre-approved conduits
        ├─ Batch token transfers
        └─ Gas optimization
```

### Key Data Structures

#### Order Components

```solidity
struct OrderComponents {
  address offerer;                          // Who offering items
  address zone;                             // Additional validation logic (optional)
  OfferItem[] offer;                        // What offerer gives
  ConsiderationItem[] consideration;        // What offerer receives
  OrderType orderType;                      // Full/Partial/Contract
  uint256 startTime;                        // When order becomes valid
  uint256 endTime;                          // When order expires
  bytes32 zoneHash;                         // Hash for zone validation
  uint256 salt;                             // Unique identifier (replay prevention)
  bytes32 conduitKey;                       // Which conduit for transfers (optional)
}
```

#### Item Types

```solidity
enum ItemType {
  NATIVE,                      // 0: Native token (ETH)
  ERC20,                       // 1: ERC20 token
  ERC721,                      // 2: ERC721 NFT
  ERC721_WITH_CRITERIA,        // 3: ERC721 with traits
  ERC1155,                     // 4: ERC1155 multi-token
  ERC1155_WITH_CRITERIA        // 5: ERC1155 with traits
}
```

#### Offer Item

```solidity
struct OfferItem {
  ItemType itemType;                        // Type of item
  address token;                            // Token contract
  uint256 identifierOrCriteria;             // Token ID or trait hash
  uint256 startAmount;                      // Starting amount (dutch)
  uint256 endAmount;                        // Ending amount (dutch)
}
```

**Note:** Linear scaling between startAmount/endAmount allows dutch auctions

#### Consideration Item

```solidity
struct ConsiderationItem {
  ItemType itemType;
  address token;
  uint256 identifierOrCriteria;
  uint256 startAmount;
  uint256 endAmount;
  address payable recipient;                // Where this item goes (crucial for fees)
}
```

---

## Order Types

### 1. Full Order

```
Characteristics:
├─ Must match exactly (no partial fills)
├─ All offer items must be fulfilled
├─ All consideration items must be received
└─ Offerer keeps any surplus

Use Case:
├─ Fixed-price listings
├─ Auction (all-or-nothing)
└─ Bundle sales

Example: "Sell NFT for exactly 2.5 ETH"
```

### 2. Partial Order

```
Characteristics:
├─ Can be filled multiple times
├─ Amounts scale with fill fraction
├─ Useful for selling fractions
└─ Each fill independent

Use Case:
├─ Divisible asset sales
├─ Liquid staking derivatives
└─ Fractional NFTs

Example: "Sell 1000 ERC20 tokens at 1 ETH each (can buy 1, 100, or all)"
```

### 3. Contract Order

```
Characteristics:
├─ Custom fulfillment logic
├─ Zone can define validation
├─ Advanced use cases only
└─ Most complex

Use Case:
├─ Conditional orders
├─ Advanced strategies
└─ Custom validation rules
```

---

## Fulfillment Mechanism

### How Orders Match

```
Order A: Offerer sells NFT, wants ETH
Order B: Taker buys NFT with ETH

Fulfillment Components:
├─ Fulfillment[0] = (Order A's offer[0] → Order B's consideration[0])
│  (NFT from A → B)
│
└─ Fulfillment[1] = (Order B's offer[0] → Order A's consideration[0])
   (ETH from B → A)
```

### Linear Scaling (Dutch Auctions)

```solidity
// Auction that decreases price over time
startAmount: 10 ETH   (highest price)
endAmount:   1 ETH    (lowest price)
startTime:   now
endTime:     now + 24 hours

// At T=0 hours:  Price = 10 ETH
// At T=12 hours: Price = 5.5 ETH  (linear interpolation)
// At T=24 hours: Price = 1 ETH
```

---

## Advanced Features

### 1. Royalty Support via Consideration Split

```solidity
// Seller wants 2.5 ETH
// Platform gets 2.5% fee
// Creator gets 2.5% royalty

consideration[0] = ConsiderationItem({
  itemType: NATIVE,
  token: address(0),
  startAmount: 2.5 ether,        // Seller
  endAmount: 2.5 ether,
  recipient: seller               // Goes to seller
});

consideration[1] = ConsiderationItem({
  itemType: NATIVE,
  token: address(0),
  startAmount: 0.0625 ether,     // 2.5% fee
  endAmount: 0.0625 ether,
  recipient: platformTreasury     // Goes to platform
});

consideration[2] = ConsiderationItem({
  itemType: NATIVE,
  token: address(0),
  startAmount: 0.0625 ether,     // 2.5% royalty
  endAmount: 0.0625 ether,
  recipient: creatorAddress       // Goes to creator
});

// Total: 2.625 ETH from buyer
```

### 2. Bulk Ordering with Conduits

**Conduit:** Pre-approved spender for efficient batch transfers

```solidity
// Without conduit: Buyer approves Seaport
// With conduit: Buyer approves Conduit (once), Seaport uses it

Benefits:
├─ Fewer approval transactions
├─ Gas efficiency for bulk ops
└─ Better UX (setup once, use many times)
```

### 3. Zone Validation

**Zone:** Optional contract that validates additional conditions

```solidity
interface IZone {
  function isValidOrder(
    Order memory order,
    bytes32 orderHash,
    uint256 context
  ) external view returns (bytes4 validOrderMagicValue);
}

Use Cases:
├─ Restricted offers (whitelist)
├─ Time-based conditions
├─ Merkle tree validation
└─ Custom business logic
```

---

## Security Model

### 1. Order Signature Verification (EIP-712)

```solidity
// Offerer signs order with their private key
// Signature prevents unauthorized modifications

struct EIP712Domain {
  string name;
  string version;
  uint256 chainId;
  address verifyingContract;
}

Benefits:
├─ Off-chain order creation (no gas)
├─ Replay protection (chainId included)
├─ Non-custodial (no smart contract wallets needed)
```

### 2. Time Window Validation

```solidity
// Order only valid within time window
if (block.timestamp < startTime) REVERT;     // Too early
if (block.timestamp > endTime) REVERT;       // Expired

Protection:
├─ Prevents use of stale orders
├─ Limits exposure if key compromised
└─ Forces periodic re-signing
```

### 3. Salt (Replay Prevention)

```solidity
// Each order needs unique salt
// Prevents same order being filled twice

uint256 salt = uint256(keccak256(abi.encodePacked(block.timestamp)));
// or
uint256 salt = 12345;  // Manual tracking
```

---

## Gas Optimization Strategies

### 1. Efficient Item Transfer

```
ERC721 single:      ~50K gas
ERC1155 batch:      ~35K gas
ERC20:              ~35K gas
Native (ETH):       ~21K gas

Seaport optimizations:
├─ Batch ERC1155 in single call
├─ Assembly for tight loops
└─ Conduit for pre-approved transfers
```

### 2. Batch Fulfillment

```solidity
// Single transaction handles multiple order components
// More efficient than separate transfers

Savings:
├─ 21K gas per tx (fixed overhead)
├─ Batch enables up to 48 items per tx
└─ Significant savings for complex orders
```

---

## Common Patterns

### Pattern 1: Simple Fixed Price Sale

```solidity
// Seller: Lists NFT at 2.5 ETH

order = OrderComponents({
  offerer: seller,
  offer: [ERC721(nftAddress, tokenId, 1, 1)],
  consideration: [
    NATIVE(ETH, 2.5e18, 2.5e18, seller),
    NATIVE(ETH, 0.0625e18, 0.0625e18, platformFee)
  ],
  orderType: FULL_OPEN,
  startTime: now,
  endTime: now + 30 days,
  ...
});

// Buyer: Calls fulfillOrder with 2.5625 ETH
```

### Pattern 2: Bundle Sale

```solidity
// Seller: Lists 3 NFTs bundled for 5 ETH

offer: [
  ERC721(nft1, id1, 1, 1),
  ERC721(nft2, id2, 1, 1),
  ERC721(nft3, id3, 1, 1)
],
consideration: [
  NATIVE(5e18, 5e18, seller)
]
```

### Pattern 3: Dutch Auction

```solidity
// Price decreases over time

offer: [ERC721(nft, id, 1, 1)],
consideration: [
  NATIVE(
    10e18,     // Start: 10 ETH
    1e18,      // End: 1 ETH
    seller
  )
]
startTime: now,
endTime: now + 1 days   // Price drops linearly
```

---

## Comparison with Other Marketplaces

| Feature | Seaport | LooksRare | Magic Eden |
|---------|---------|-----------|-----------|
| **Gas Efficiency** | High (batch) | Medium | Medium |
| **Multi-offer** | ✅ Yes | ❌ No | ❌ No |
| **Royalty Support** | ✅ Native | ✅ Enforced | ✅ Enforced |
| **Chain Support** | 10+ chains | 1-2 chains | Solana |
| **Auction Types** | ✅ Dutch + more | ✅ Auctions | ✅ Basic |
| **Decentralized** | ✅ Full | ⚠️ Partial | ❌ No |

---

## Deployment & Addresses

### Cross-Chain Deployment (Same Address)

```
0x0000000000000068F116a894984e2DB1123eB395  (Seaport 1.6)
0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC  (Seaport 1.5)

Deployed on: Ethereum, Polygon, Arbitrum, Optimism, Avalanche, etc
```

**Benefit:** Same contract address on all chains = easier integration

---

## Integration Best Practices

### 1. Order Validation

```solidity
// Always validate orders before execution
├─ Check offerer has items
├─ Verify consideration recipient
├─ Validate time windows
└─ Check for signature replay
```

### 2. Slippage Management

```solidity
// For scaled amounts (dutch auctions)
├─ Calculate min/max acceptable amounts
├─ Set deadline (block.timestamp check)
└─ Monitor oracle prices
```

### 3. Error Handling

```solidity
try seaport.fulfillOrder(order, components) {
  // Success
} catch Error(string memory reason) {
  // Handle specific error
} catch {
  // Generic failure
}
```

---

## Resources

- **Documentation:** https://docs.opensea.io/reference/seaport-overview
- **GitHub:** https://github.com/ProjectOpenSea/seaport
- **Deployed Contracts:** https://github.com/ProjectOpenSea/seaport/tree/main/deployments
- **Validator Tool:** Validate orders before execution

---

**Complexity:** High (complex order structures)
**Security Audits:** Multiple (professional audits)
**Production Ready:** Yes ($1B+ volume)
**Learning Curve:** Medium (good documentation available)
