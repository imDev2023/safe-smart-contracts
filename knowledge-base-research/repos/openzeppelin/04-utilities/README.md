# Utility Libraries

## Overview

OpenZeppelin provides a comprehensive collection of utility libraries for common operations, data structures, and cryptographic functions. These utilities are gas-optimized, security-audited, and production-ready.

## Categories

### 1. Cryptography
- **ECDSA**: Ethereum signature verification (secp256k1)
- **P256**: P256/secp256r1 signature support
- **RSA**: RSA signature verification
- **MerkleProof**: Merkle tree proof verification
- **SignatureChecker**: Unified signature verification (EOA + ERC-1271)
- **MessageHashUtils**: Message hashing utilities

### 2. Data Structures
- **EnumerableSet**: Sets with iteration support
- **EnumerableMap**: Maps with iteration support
- **MerkleTree**: On-chain Merkle tree
- **Heap**: Binary heap / priority queue
- **BitMaps**: Packed boolean storage
- **Checkpoints**: Historical value tracking
- **DoubleEndedQueue**: Queue with pop/push on both ends

### 3. Math & Type Safety
- **Math**: Safe math operations with additional utilities
- **SignedMath**: Signed integer math utilities
- **SafeCast**: Type casting with overflow checks

### 4. String & Encoding
- **Strings**: String conversion and manipulation
- **Base64**: Base64 encoding/decoding
- **ShortStrings**: Gas-efficient short string storage

### 5. Address & Contract Operations
- **Address**: Safe address operations and contract detection
- **Create2**: Deterministic deployment utilities
- **Multicall**: Batch multiple calls in one transaction

### 6. Storage Management
- **StorageSlot**: Direct storage slot manipulation
- **TransientSlot**: Transient storage (EIP-1153)
- **SlotDerivation**: ERC-7201 namespaced storage
- **Packing**: Pack multiple values into single slots

### 7. Utilities
- **Arrays**: Array manipulation utilities
- **Time**: Time and delay management
- **Nonces**: Nonce tracking for replay protection
- **Pausable**: Emergency stop mechanism
- **ReentrancyGuard**: Reentrancy attack prevention

## Quick Reference

### Most Commonly Used

#### Address Operations
```solidity
import "@openzeppelin/contracts/utils/Address.sol";

using Address for address;

// Check if address is contract
bool isContract = addr.isContract();

// Safe function call
addr.functionCall(data);
```

#### ECDSA Signatures
```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

using ECDSA for bytes32;

address signer = messageHash.recover(signature);
```

#### EnumerableSet
```solidity
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

using EnumerableSet for EnumerableSet.AddressSet;

EnumerableSet.AddressSet private whitelist;

whitelist.add(addr);
bool contains = whitelist.contains(addr);
uint256 length = whitelist.length();
address member = whitelist.at(index);
```

#### Math Operations
```solidity
import "@openzeppelin/contracts/utils/math/Math.sol";

uint256 max = Math.max(a, b);
uint256 min = Math.min(a, b);
uint256 avg = Math.average(a, b);
uint256 sqrt = Math.sqrt(x);
```

#### Strings
```solidity
import "@openzeppelin/contracts/utils/Strings.sol";

using Strings for uint256;

string memory str = tokenId.toString();
string memory hex = value.toHexString();
```

## Gas Efficiency Tips

### 1. Use Packed Storage
```solidity
// Instead of multiple bools (each 32 bytes)
bool flag1;
bool flag2;
bool flag3;

// Use BitMap (packed in one slot)
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
BitMaps.BitMap private flags;
```

### 2. Use EnumerableSet for Membership
```solidity
// O(1) add/remove/contains
EnumerableSet.AddressSet private members;

members.add(addr);  // ~20k gas
bool exists = members.contains(addr); // ~3k gas
```

### 3. Use Math.mulDiv for Precision
```solidity
// Prevents overflow in (a * b) / c
uint256 result = Math.mulDiv(a, b, c);
```

## Security Utilities

### SafeCast (Prevent Overflow)
```solidity
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

using SafeCast for uint256;

uint128 small = largeNumber.toUint128(); // Reverts if overflow
```

### Nonces (Prevent Replay)
```solidity
import "@openzeppelin/contracts/utils/Nonces.sol";

contract MyContract is Nonces {
    function execute(uint256 nonce, bytes signature) external {
        require(nonce == _useNonce(msg.sender), "Invalid nonce");
        // Execute with signature
    }
}
```

## Best Practices

1. **Use Address.isContract** before external calls
2. **Use ECDSA for signature verification**
3. **Use MerkleProof for whitelists/airdrops**
4. **Use EnumerableSet for tracked sets**
5. **Use Math utilities for safe operations**
6. **Use StorageSlot for ERC-7201 compliance**

## Summary

OpenZeppelin utilities provide:
- **Gas-optimized** implementations
- **Security-audited** code
- **Production-ready** libraries
- **Comprehensive** functionality
- **Well-documented** APIs

Use these utilities to build safer, more efficient smart contracts.
