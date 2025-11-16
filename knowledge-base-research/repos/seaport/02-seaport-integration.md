# Seaport NFT Marketplace - Quick Integration Guide

**Protocol:** Seaport (OpenSea)
**Purpose:** Safe & efficient NFT buying/selling
**Latest Version:** 1.6
**Gas Efficient:** Yes (optimized order matching)
**Time to Read:** 8 minutes

---

## What is Seaport?

Seaport is OpenSea's battle-tested NFT marketplace protocol:
- Accept arbitrary offers (1+ items)
- Require specific consideration (payment + fees)
- Multi-token support (ERC721, ERC1155, ERC20)
- Royalty enforcement via consideration split

---

## Core Concepts

### Offer & Consideration

```solidity
struct OrderComponents {
  address offerer;           // Who is offering items
  OfferItem[] offer;         // Items to give (NFT, ERC20)
  ConsiderationItem[] consideration; // Items to receive (payment)
  OrderType orderType;       // Full/Partial/Contract
  uint256 startTime;         // Order valid from
  uint256 endTime;           // Order expires at
}

struct OfferItem {
  ItemType itemType;         // ERC721, ERC1155, ERC20, etc
  address token;             // Token address
  uint256 identifierOrCriteria; // Token ID (NFT) or criteria
  uint256 startAmount;       // Starting amount
  uint256 endAmount;         // Ending amount (for dutch)
}

struct ConsiderationItem {
  ItemType itemType;
  address token;             // Payment token
  uint256 startAmount;       // Starting payment
  uint256 endAmount;         // Ending payment
  address payable recipient; // Where payment goes
}
```

### Order Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Full Order** | Must match exactly | Fixed price listings |
| **Partial Order** | Can be filled multiple times | Divisible items |
| **Contract Order** | Custom fulfillment logic | Advanced strategies |

---

## Basic Integration: List & Sell NFT

### Step 1: Create Listing

```solidity
pragma solidity ^0.8.17;

import "seaport/contracts/interfaces/SeaportInterface.sol";

contract NFTMarketplace {
  SeaportInterface public seaport =
    SeaportInterface(0x00000000000001ad428e4906aE43D8F9852d0dD6);

  // Create listing: Sell NFT for ETH
  function listNFTForETH(
    address nftContract,
    uint256 tokenId,
    uint256 priceInETH
  ) external returns (bytes32 orderHash) {
    // Offer: Give our NFT
    OfferItem[] memory offer = new OfferItem[](1);
    offer[0] = OfferItem({
      itemType: ItemType.ERC721,
      token: nftContract,
      identifierOrCriteria: tokenId,
      startAmount: 1,
      endAmount: 1
    });

    // Consideration: Receive ETH (for us) + fee (for protocol)
    ConsiderationItem[] memory consideration = new ConsiderationItem[](2);

    // Primary receiver (us)
    consideration[0] = ConsiderationItem({
      itemType: ItemType.NATIVE,  // ETH
      token: address(0),
      startAmount: priceInETH,
      endAmount: priceInETH,
      payable(msg.sender)         // Seller
    });

    // Secondary receiver (platform fee - 2.5%)
    consideration[1] = ConsiderationItem({
      itemType: ItemType.NATIVE,
      token: address(0),
      startAmount: priceInETH / 40, // 2.5%
      endAmount: priceInETH / 40,
      payable(0xOPENSEA_TREASURY)   // OpenSea
    });

    OrderComponents memory orderComponents = OrderComponents({
      offerer: msg.sender,
      offer: offer,
      consideration: consideration,
      orderType: OrderType.FULL_OPEN,
      startTime: block.timestamp,
      endTime: block.timestamp + 30 days,
      zoneHash: bytes32(0),
      salt: uint256(keccak256(abi.encodePacked(block.timestamp))),
      conduitKey: bytes32(0)
    });

    // Create order (returns hash)
    orderHash = seaport.getOrderHash(orderComponents);
    return orderHash;
  }
}
```

### Step 2: Sign Order

```javascript
// Frontend: Sign with ethers.js
const order = {
  offerer: userAddress,
  offer: [{
    itemType: 2,  // ERC721
    token: nftAddress,
    identifierOrCriteria: tokenId,
    startAmount: "1",
    endAmount: "1"
  }],
  consideration: [{
    itemType: 0,  // NATIVE (ETH)
    token: "0x0000000000000000000000000000000000000000",
    identifierOrCriteria: "0",
    startAmount: ethers.utils.parseEther("2.5"),
    endAmount: ethers.utils.parseEther("2.5"),
    recipient: userAddress
  }],
  orderType: 2,  // FULL_OPEN
  startTime: Math.floor(Date.now() / 1000),
  endTime: Math.floor(Date.now() / 1000) + 2592000, // 30 days
  zoneHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  salt: "1234567890",
  conduitKey: "0x0000000000000000000000000000000000000000000000000000000000000000"
};

// Sign using EIP-712
const signature = await signer._signTypedData(
  domain,
  types,
  order
);
```

### Step 3: Buyer Fulfills Order

```solidity
function buyNFT(
  Order calldata order,
  bytes calldata signature
) external payable {
  // Fulfill order
  seaport.fulfillOrder{value: msg.value}(
    order,
    fulfillmentComponents
  );
}
```

---

## Advanced: Multi-Item Offer

```solidity
// Bundle multiple NFTs with single price
function bundleNFTs(
  address[] calldata nftAddresses,
  uint256[] calldata tokenIds,
  uint256 bundlePrice
) external returns (bytes32) {
  // Offer: Multiple NFTs
  OfferItem[] memory offer = new OfferItem[](nftAddresses.length);
  for (uint256 i = 0; i < nftAddresses.length; i++) {
    offer[i] = OfferItem({
      itemType: ItemType.ERC721,
      token: nftAddresses[i],
      identifierOrCriteria: tokenIds[i],
      startAmount: 1,
      endAmount: 1
    });
  }

  // Consideration: Bundle price in ETH
  ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
  consideration[0] = ConsiderationItem({
    itemType: ItemType.NATIVE,
    token: address(0),
    startAmount: bundlePrice,
    endAmount: bundlePrice,
    payable(msg.sender)
  });

  OrderComponents memory orderComponents = OrderComponents({
    offerer: msg.sender,
    offer: offer,
    consideration: consideration,
    orderType: OrderType.FULL_OPEN,
    startTime: block.timestamp,
    endTime: block.timestamp + 30 days,
    zoneHash: bytes32(0),
    salt: uint256(keccak256(abi.encodePacked(block.timestamp))),
    conduitKey: bytes32(0)
  });

  return seaport.getOrderHash(orderComponents);
}
```

---

## Security Checklist

- ✅ Verify NFT contract is legitimate (check on Etherscan)
- ✅ Set reasonable time windows (startTime < endTime)
- ✅ Include platform fees in consideration
- ✅ Use OrderType.FULL_OPEN for simple listings
- ✅ Always verify order before fulfilling
- ✅ Check token approval before listing (approve Seaport)

---

## Key Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| Seaport 1.6 | `0x0000000000000068F116a894984e2DB1123eB395` |
| Seaport 1.5 | `0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC` |
| ConduitController | `0x00000000F9490004C11Cef243f5400493c00Ad63` |
| SeaportValidator | `0x00e5F120f500006757E984F1DED400fc00370000` |

---

## Resources

- **Docs:** https://docs.opensea.io/reference/seaport-overview
- **GitHub:** https://github.com/ProjectOpenSea/seaport
- **Validator Tool:** https://github.com/ProjectOpenSea/seaport-validator

---

**Complexity:** Medium
**Gas Cost:** 80-150K (depends on items)
**Audited:** Yes (multiple audits)
**Battle-tested:** Yes ($1B+ in volume)
