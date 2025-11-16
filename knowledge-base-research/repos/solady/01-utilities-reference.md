# Solady: Gas-Optimized Solidity Utilities

> Comprehensive library of 50+ gas-optimized Solidity contracts and utilities

**Repo:** https://github.com/Vectorized/solady.git
**Purpose:** Production-grade, battle-tested, gas-optimized utility contracts
**Strength:** Extreme gas optimization without sacrificing safety or functionality

---

## Core Utilities by Category

### Mathematical Operations

#### FixedPointMathLib

**Location:** `src/utils/FixedPointMathLib.sol`

Lighter alternative to PRBMath, focused on WAD (18-decimal) arithmetic:

```solidity
// mulWad: (x * y) / 1e18 with overflow checking
function mulWad(uint256 x, uint256 y) returns (uint256);

// divWad: (x * 1e18) / y with overflow checking
function divWad(uint256 x, uint256 y) returns (uint256);

// rpow: Fixed-point exponentiation (x ^ y)
function rpow(uint256 x, uint256 y, uint256 base) returns (uint256);

// sqrt: Integer square root
function sqrt(uint256 x) returns (uint256);
```

**When to use:** When PRBMath is overkill; simple 18-decimal math needed

**Gas:** ~3,000-5,000 gas for mulWad (vs Solmate's equivalent)

---

### Bit Manipulation

#### LibBit

**Location:** `src/utils/LibBit.sol`

Efficient bit operations:

```solidity
function popcount(uint256 x) returns (uint256);  // Count set bits
function clz(uint256 x) returns (uint256);       // Count leading zeros
function ctz(uint256 x) returns (uint256);       // Count trailing zeros
function msb(uint256 x) returns (uint256);       // Most significant bit
function lsb(uint256 x) returns (uint256);       // Least significant bit
```

**Used in:** Uniswap V3 tick operations, bit masks

---

#### LibBitmap

**Location:** `src/utils/LibBitmap.sol`

Packed boolean storage in single slot:

```solidity
// Store 256 booleans in 1 slot
mapping(uint256 => uint256) public enabled;

function set(mapping(uint256 => uint256) storage bitmap, uint256 index) {
    bitmap[index >> 8] |= 1 << (index & 0xff);
}

function get(mapping(uint256 => uint256) storage bitmap, uint256 index)
    returns (bool) {
    return (bitmap[index >> 8] >> (index & 0xff)) & 1 == 1;
}
```

**Use case:** Allowed addresses, feature flags, whitelist (~10x cheaper than bool mapping)

**Gas savings:** 1 SSTORE covers 256 entries vs 256 SSTORE for bool mapping

---

### String & Encoding

#### LibString

**Location:** `src/utils/LibString.sol`

Efficient string conversion without external libraries:

```solidity
// Convert uint to string
function toString(uint256 x) returns (string memory);

// Convert address to hex string
function toHexString(address addr) returns (string memory);

// String equality check
function eq(string memory a, string memory b) returns (bool);
```

**Gas:** ~1,000 gas for uint256 → string conversion (vs Solmate's overhead)

---

#### Base64 & Base58

**Location:** `src/utils/Base64.sol`, `src/utils/Base58.sol`

Encoding/decoding without external deps:

```solidity
function encode(bytes memory data) returns (string memory);
function decode(string memory data) returns (bytes memory);
```

---

### Cryptography

#### ECDSA

**Location:** `src/utils/ECDSA.sol`

Signature verification:

```solidity
function recover(bytes32 hash, bytes calldata signature)
    returns (address);

function recoverCalldata(bytes32 hash, bytes calldata signature)
    returns (address);
```

**vs OpenZeppelin:** More gas-optimized, same functionality

---

#### EIP712

**Location:** `src/utils/EIP712.sol`

Typed structured data hashing:

```solidity
contract MyContract is EIP712 {
    bytes32 private _cachedChainId;
    bytes32 private _cachedNameHash;
    bytes32 private _cachedVersionHash;
    uint256 private _cachedDomainSeparator;

    bytes32 constant MY_TYPEHASH = keccak256(
        "MyStruct(address user,uint256 amount)"
    );
}
```

---

### Deployment & Cloning

#### CREATE3

**Location:** `src/utils/CREATE3.sol`

Deterministic contract deployment independent of bytecode:

```solidity
function deploy(
    bytes32 salt,
    bytes calldata creationCode,
    uint256 value
) returns (address deployed);

// Address deterministic: depends only on salt, not bytecode
address predicted = CREATE3.predictDeterministicAddress(salt);
```

**Use case:** Factory contracts, upgradeable proxies with predictable addresses

**Advantage over CREATE2:** Same address regardless of contract code changes

---

#### LibClone (Minimal Proxy)

**Location:** `src/utils/LibClone.sol`

Create minimal proxy contracts (95 gas):

```solidity
address clone = LibClone.clone(implementation);
address clone = LibClone.cloneDeterministic(implementation, salt);
```

**Gas:** 95 gas to clone vs 1e5+ gas for CREATE

**Use case:** NFT/Token factory (create thousands of contracts cheaply)

---

#### ERC1967Factory

**Location:** `src/utils/ERC1967Factory.sol`

UUPS proxy factory:

```solidity
function deploy(
    address implementation,
    bytes memory initData
) returns (address instance);
```

---

### Token Standards

#### ERC20 (Optimized)

**Location:** `src/tokens/ERC20.sol`

Gas-optimized ERC20 (~2K saved vs Solmate):

- Overflow protection
- `permit()` support (EIP-2612)
- Custom errors
- Optimized storage layout

---

#### ERC721

**Location:** `src/tokens/ERC721.sol`

ERC721 with storage hitchhiking (saves 1 storage slot):

```solidity
// Stores owner + approved in single slot
// vs OpenZeppelin: requires 2 slots
```

**Gas savings:** ~2,000 gas per mint

---

#### ERC1155

**Location:** `src/tokens/ERC1155.sol`

Multi-token standard, highly optimized

---

#### ERC4626 (Vault)

**Location:** `src/tokens/ERC4626.sol`

Tokenized vault standard for yield strategies:

```solidity
contract MyVault is ERC4626 {
    function asset() returns (address);
    function totalAssets() returns (uint256);
    function deposit(uint256 assets, address receiver)
        returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner)
        returns (uint256 shares);
}
```

**Use case:** Staking contracts, lending protocols, yield farming

---

#### ERC6909 (Multi-Token)

**Location:** `src/tokens/ERC6909.sol`

Minimal multi-token standard (like Uniswap V4 balance tracking):

```solidity
// Store multiple token balances in single contract
mapping(uint256 id => mapping(address owner => uint256 balance)) balanceOf;

function transfer(uint256 id, address to, uint256 amount);
function approve(uint256 id, address operator, uint256 amount);
```

**Use case:** DEX internal token tracking, Uniswap V4-like protocols

---

### Authorization

#### Ownable

**Location:** `src/auth/Ownable.sol`

Single owner authorization:

```solidity
function transferOwnership(address newOwner);
function renounceOwnership();
```

**Gas:** ~2,000 cheaper than OpenZeppelin

---

#### OwnableRoles

**Location:** `src/auth/OwnableRoles.sol`

Owner + multiple roles system:

```solidity
mapping(address => uint256) public rolesOf;  // Packed into 256 bits

function grantRoles(address user, uint256 roles);
function hasAllRoles(address user, uint256 roles) returns (bool);

// Usage
uint256 MINTER_ROLE = 1 << 0;
uint256 BURNER_ROLE = 1 << 1;
```

**Gas savings:** Store 256 roles per address in 1 slot

---

#### EnumerableRoles

**Location:** `src/auth/EnumerableRoles.sol`

Roles with enumeration (iterate all role holders):

```solidity
function rolesOf(address user) returns (uint256);
function roleHolders(uint256 role) returns (address[] memory);
```

---

### Storage Optimization

#### LibMap

**Location:** `src/utils/LibMap.sol`

Packed storage of unsigned integers:

```solidity
// Store 256 uint8s in 1 slot, 128 uint16s, 64 uint32s, etc.
mapping(uint256 => uint256) public packedUints;

function set(mapping(uint256 => uint256) storage m, uint256 key, uint8 value);
function get(mapping(uint256 => uint256) storage m, uint256 key)
    returns (uint8);
```

---

#### EnumerableSetLib

**Location:** `src/utils/EnumerableSetLib.sol`

Set data structure with enumeration:

```solidity
using EnumerableSetLib for EnumerableSetLib.Uint256Set;

EnumerableSetLib.Uint256Set tokenIds;

function add(EnumerableSetLib.Uint256Set storage set, uint256 value);
function remove(EnumerableSetLib.Uint256Set storage set, uint256 value);
function contains(EnumerableSetLib.Uint256Set storage set, uint256 value)
    returns (bool);
function values(EnumerableSetLib.Uint256Set storage set)
    returns (uint256[] memory);
```

---

### Utility Helpers

#### LibRLP

**Location:** `src/utils/LibRLP.sol`

RLP encoding and CREATE address computation:

```solidity
function computeAddress(address deployer, uint256 nonce)
    returns (address);
```

**Use case:** Predicting contract addresses created by EOA (for CREATE-based deployment)

---

#### DateTimeLib

**Location:** `src/utils/DateTimeLib.sol`

Date/time operations without external dependencies:

```solidity
function timestampToDate(uint256 timestamp)
    returns (uint256 year, uint256 month, uint256 day);

function dateToTimestamp(uint256 year, uint256 month, uint256 day)
    returns (uint256);
```

---

#### MerkleProofLib & MerkleTreeLib

**Location:** `src/utils/MerkleProofLib.sol`, `MerkleTreeLib.sol`

Merkle tree operations:

```solidity
function verify(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
) returns (bool);

// Generate tree
function getRoot(bytes32[] memory leaves) returns (bytes32);
```

**Use case:** Merkle proofs for whitelists, airdrops

---

#### Multicallable

**Location:** `src/utils/Multicallable.sol`

Batch multiple calls to same contract:

```solidity
contract MyContract is Multicallable {
    function multicall(bytes[] calldata data)
        payable returns (bytes[] memory results) {
        // Execute multiple calls atomically
    }
}
```

---

### Account Abstractions

#### ERC4337 (Account Abstraction)

**Location:** `src/accounts/ERC4337.sol`

Simple AA implementation for account abstraction:

```solidity
// User operations, validators, hooks
```

---

#### ERC6551 (Token Bound Accounts)

**Location:** `src/accounts/ERC6551.sol`

NFT-bound smart contract accounts:

```solidity
// Each NFT can own assets, execute transactions
```

---

## Installation & Usage

```bash
npm install solady
# or
forge install vectorized/solady
```

**Remappings:**
```
solady/=node_modules/solady/src/
```

---

## Gas Optimization Techniques Used

1. **Bit Packing:** Multiple values in single slot
2. **Assembly:** Custom code for critical paths
3. **Memory-Safe Assembly:** Validated by Solidity compiler
4. **Selector Optimization:** Custom error codes vs strings
5. **Storage Layout:** Optimal packing of state variables
6. **Inline Functions:** No library call overhead for simple operations

---

## When to Use Solady vs Alternatives

| Library | Gas Cost | Features | Maturity |
|---------|----------|----------|----------|
| **Solady** | 🟢 Lowest | Comprehensive | ✅ Production |
| **OpenZeppelin** | 🟡 Medium | Standard | ✅ Standard |
| **Solmate** | 🟡 Medium | Focused | ✅ Stable |

**Use Solady when:**
- Gas optimization is critical
- Need less common utilities (CREATE3, LibClone, etc.)
- Building protocols with thousands of contracts (NFT factories)
- Custom role/bitmap implementations needed

---

## Key Recommendations for KB Integration

1. **FixedPointMathLib:** Alternative to PRBMath for simple WAD math
2. **LibClone:** Use for NFT/token factories
3. **ERC6909:** Reference for Uniswap V4-style token tracking
4. **ERC4626:** Standard for staking/yield contracts
5. **CREATE3:** Deterministic deployment in factories
6. **OwnableRoles:** Multi-role authorization with gas savings
7. **LibBitmap:** Boolean storage optimization

---

**Status:** Ready to reference for gas-optimized implementations
**Docs:** https://vectorized.github.io/solady
