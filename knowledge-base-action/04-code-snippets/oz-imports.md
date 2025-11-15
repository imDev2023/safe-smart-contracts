# OpenZeppelin Imports Reference

Complete import statements organized by category. Copy-paste ready for Solidity 0.8.20+.

---

## 1. Token Standards

### ERC20 (Fungible Tokens)

```solidity
// Basic ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ERC20 with burn functionality
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// ERC20 with pausable transfers
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

// ERC20 with capped supply
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

// ERC20 with snapshot capability (for dividends/governance)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

// ERC20 with voting/delegation (governance tokens)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// ERC20 with gasless approvals (EIP-2612)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// Safe wrapper for ERC20 interactions
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ERC20 interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

**Gas Cost:** ~50,000 gas per transfer, ~20,000 for balance checks
**When to Use:** Creating fungible tokens (currencies, rewards, governance)

---

### ERC721 (Non-Fungible Tokens)

```solidity
// Basic ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// ERC721 with URI storage per token
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// ERC721 with token enumeration
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// ERC721 with burn functionality
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// ERC721 with pausable transfers
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

// ERC721 with royalty support (EIP-2981)
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

// ERC721 interface
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    constructor(address initialOwner)
        ERC721("MyNFT", "MNFT")
        Ownable(initialOwner)
    {}

    function mint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Required override
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

**Gas Cost:** ~60,000 gas per mint, ~70,000 per transfer
**When to Use:** NFT collections, digital art, gaming items, certificates

---

### ERC1155 (Multi-Token Standard)

```solidity
// Basic ERC1155
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// ERC1155 with burn functionality
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

// ERC1155 with pausable transfers
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

// ERC1155 with supply tracking
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

// ERC1155 interface
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameItems is ERC1155, Ownable {
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant SWORD = 2;

    constructor(address initialOwner)
        ERC1155("https://game.example/api/item/{id}.json")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 id, uint256 amount) public onlyOwner {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, "");
    }
}
```

**Gas Cost:** ~45,000 gas per single transfer, ~100,000 for batch of 10 items
**When to Use:** Gaming (multiple item types), mixed token ecosystems, batch operations

---

## 2. Security Contracts

### Access Control

```solidity
// Single owner pattern
import "@openzeppelin/contracts/access/Ownable.sol";

// Two-step ownership transfer (safer)
import "@openzeppelin/contracts/access/Ownable2Step.sol";

// Role-based access control (RBAC)
import "@openzeppelin/contracts/access/AccessControl.sol";

// AccessControl with enumerable roles
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

// AccessControl with default admin rules
import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        // Minting logic
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        // Pause logic
    }
}
```

**Gas Cost:** Ownable check ~400 gas, AccessControl check ~2,000-3,000 gas
**When to Use:** Ownable for simple admin, AccessControl for multi-role systems

---

### Protection Mechanisms

```solidity
// Reentrancy protection
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Circuit breaker (pause mechanism)
import "@openzeppelin/contracts/utils/Pausable.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is ReentrancyGuard, Pausable, Ownable {
    mapping(address => uint256) public balances;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function deposit() public payable whenNotPaused {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public nonReentrant whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
```

**Gas Cost:** ReentrancyGuard ~2,400 gas, Pausable check ~300 gas
**When to Use:** Always use ReentrancyGuard with external calls, Pausable for emergency stops

---

## 3. Utilities

### Cryptography

```solidity
// ECDSA signature verification
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Merkle proof verification
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// EIP-712 structured data hashing
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// Message hashing utilities
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// Unified signature checker (EOA + ERC-1271)
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureVerifier {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    function verify(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedHash.recover(signature);
        return recoveredSigner == signer;
    }
}
```

**Gas Cost:** ECDSA recovery ~3,000 gas, Merkle proof ~3,000-5,000 gas per level
**When to Use:** Signature verification, whitelists, airdrops, gasless transactions

---

### Data Structures

```solidity
// Enumerable Set (AddressSet, UintSet, Bytes32Set)
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Enumerable Map
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// Bit manipulation for boolean packing
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// Historical value tracking (checkpoints)
import "@openzeppelin/contracts/utils/structs/Checkpoints.sol";

// Double-ended queue
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Whitelist {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whitelistedAddresses;

    function addToWhitelist(address addr) public {
        whitelistedAddresses.add(addr);
    }

    function removeFromWhitelist(address addr) public {
        whitelistedAddresses.remove(addr);
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return whitelistedAddresses.contains(addr);
    }

    function getWhitelistLength() public view returns (uint256) {
        return whitelistedAddresses.length();
    }

    function getWhitelistedAt(uint256 index) public view returns (address) {
        return whitelistedAddresses.at(index);
    }
}
```

**Gas Cost:** EnumerableSet add/remove ~20,000 gas, contains check ~3,000 gas
**When to Use:** When you need to iterate over mappings, track sets with enumeration

---

### Math & Safety

```solidity
// Math utilities (min, max, average, etc.)
import "@openzeppelin/contracts/utils/math/Math.sol";

// Signed integer math
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

// Type casting with overflow checks
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract MathExample {
    using Math for uint256;
    using SafeCast for uint256;

    function calculateReward(uint256 stake, uint256 rate) public pure returns (uint256) {
        // Prevent overflow in multiplication before division
        return Math.mulDiv(stake, rate, 10000);
    }

    function safeCast(uint256 largeNumber) public pure returns (uint128) {
        return largeNumber.toUint128(); // Reverts if overflow
    }

    function getMaxValue(uint256 a, uint256 b) public pure returns (uint256) {
        return Math.max(a, b);
    }
}
```

**Gas Cost:** Math operations ~100-300 gas
**When to Use:** Precision calculations, preventing overflow/underflow

---

### Address Utilities

```solidity
// Address utility functions
import "@openzeppelin/contracts/utils/Address.sol";

// String conversion utilities
import "@openzeppelin/contracts/utils/Strings.sol";

// Arrays utilities
import "@openzeppelin/contracts/utils/Arrays.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AddressUtils {
    using Address for address;
    using Address for address payable;
    using Strings for uint256;

    function isContractAddress(address addr) public view returns (bool) {
        return addr.isContract();
    }

    function sendValue(address payable recipient, uint256 amount) public {
        recipient.sendValue(amount); // Reverts on failure
    }

    function uintToString(uint256 tokenId) public pure returns (string memory) {
        return tokenId.toString(); // "42" -> "42"
    }

    function addressToHexString(address addr) public pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }
}
```

**Gas Cost:** isContract ~2,600 gas, sendValue ~2,300 gas + transfer cost
**When to Use:** Safe address operations, string conversions for metadata

---

## 4. Upgradeable Contracts

```solidity
// Initializable (replaces constructor)
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// UUPS upgradeable
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// ERC1967 proxy
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Transparent upgradeable proxy
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// Beacon proxy
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyContractV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public value;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        value = 0;
    }

    function setValue(uint256 newValue) public onlyOwner {
        value = newValue;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
```

**Gas Cost:** Initialize ~50,000 gas, upgrade ~30,000 gas
**When to Use:** When contracts need to be upgradeable post-deployment

---

## 5. Math & Safety (Detailed)

```solidity
// SafeCast for different integer types
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Example usage in contract
using SafeCast for uint256;

uint128 smallNumber = largeNumber.toUint128(); // Safe downcast
int256 signedNumber = unsignedNumber.toInt256(); // Safe sign conversion
```

**Common SafeCast Functions:**
- `toUint8()`, `toUint16()`, `toUint32()`, `toUint64()`, `toUint128()`, `toUint256()`
- `toInt8()`, `toInt16()`, `toInt32()`, `toInt64()`, `toInt128()`, `toInt256()`

**Gas Cost:** ~100 gas per cast with check
**When to Use:** Downcasting integers, converting between signed/unsigned

---

## 6. Storage Management

```solidity
// Storage slot manipulation
import "@openzeppelin/contracts/utils/StorageSlot.sol";

// ERC-7201 namespaced storage
import "@openzeppelin/contracts/utils/SlotDerivation.sol";

// Transient storage (EIP-1153)
import "@openzeppelin/contracts/utils/TransientSlot.sol";
```

**Usage Example:**
```solidity
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract StorageExample {
    // ERC-7201 compliant namespace
    bytes32 private constant MY_STORAGE_LOCATION =
        keccak256(abi.encode(uint256(keccak256("example.storage.MyContract")) - 1))
        & ~bytes32(uint256(0xff));

    struct MyStorage {
        uint256 value;
        address owner;
    }

    function _getStorage() private pure returns (MyStorage storage $) {
        assembly {
            $.slot := MY_STORAGE_LOCATION
        }
    }

    function setValue(uint256 newValue) public {
        MyStorage storage $ = _getStorage();
        $.value = newValue;
    }
}
```

**Gas Cost:** Storage slot access ~2,100 gas (warm) / ~2,100 gas (cold)
**When to Use:** Upgradeable contracts, avoiding storage collisions

---

## Import Patterns

### Pattern 1: Secure Token
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
```

### Pattern 2: DeFi Vault
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
```

### Pattern 3: NFT Collection
```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
```

### Pattern 4: Governance
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
```

---

## Installation

### Hardhat
```bash
npm install @openzeppelin/contracts
npm install @openzeppelin/contracts-upgradeable  # For upgradeable contracts
```

### Foundry
```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

---

## Version Compatibility

- OpenZeppelin Contracts v5.x requires Solidity ^0.8.20
- OpenZeppelin Contracts v4.x requires Solidity ^0.8.0

**Breaking Changes in v5.x:**
- Custom errors instead of string reverts (gas efficient)
- Namespaced storage (ERC-7201)
- Ownable requires initialOwner parameter
- Updated AccessControl patterns

---

## Best Practices

1. Always import from `@openzeppelin/contracts/` (not node_modules path)
2. Use specific extensions when needed (don't import everything)
3. For upgradeable contracts, use `@openzeppelin/contracts-upgradeable/`
4. Combine security contracts (ReentrancyGuard + Pausable + AccessControl)
5. Use SafeERC20 for all external token interactions
6. Prefer AccessControl over Ownable for complex systems
7. Always use latest stable version
8. Audit imports before mainnet deployment

---

## Gas Optimization Tips

**Low Cost Imports:**
- Ownable: ~400 gas per check
- Pausable: ~300 gas per check

**Medium Cost Imports:**
- ReentrancyGuard: ~2,400 gas per call
- AccessControl: ~2,000-3,000 gas per check

**Higher Cost Imports:**
- EnumerableSet: ~20,000 gas per add/remove
- ERC721Enumerable: Additional ~30,000 gas per mint

Choose based on your security vs gas tradeoff requirements.

---

**Total Import Categories:** 6
**Total Imports Documented:** 60+
**OpenZeppelin Version:** 5.x
**Solidity Version:** ^0.8.20
