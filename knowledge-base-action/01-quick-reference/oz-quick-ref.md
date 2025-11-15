# OpenZeppelin Contracts Quick Reference

One-page reference for OpenZeppelin's most essential contracts, patterns, and utilities.

**Version:** 5.x
**Last Updated:** November 15, 2025
**Docs:** https://docs.openzeppelin.com/contracts/5.x/

---

## Installation

```bash
# Hardhat/npm
npm install @openzeppelin/contracts

# Foundry
forge install OpenZeppelin/openzeppelin-contracts

# Upgradeable version
npm install @openzeppelin/contracts-upgradeable
```

**Foundry remapping:**
```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
```

---

## Security Contracts

### ReentrancyGuard
**Purpose:** Prevent reentrancy attacks
**Gas:** ~2,400 gas per protected call

```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    function withdraw(uint256 amount) external nonReentrant {
        // Protected from reentrancy
    }
}
```

**When to use:** Any function making external calls, especially with value transfer

---

### AccessControl (Role-Based)
**Purpose:** Multi-role permission system
**Gas:** ~2,000-3,000 gas per role check

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Token is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
```

**When to use:** Complex permissions, multiple admin roles, DAO governance

---

### Ownable (Single Owner)
**Purpose:** Simple single-owner access control
**Gas:** ~400 gas per check

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function adminFunction() external onlyOwner {
        // Only owner can call
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}
```

**When to use:** Simple admin functions, single administrator

**Variant:** `Ownable2Step` for safer ownership transfers (prevents accidental loss)

---

### Pausable
**Purpose:** Emergency circuit breaker
**Gas:** ~300 gas per check

```solidity
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is Pausable, Ownable {
    function transfer(address to, uint256 amount) public whenNotPaused {
        // Normal operation
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
```

**When to use:** Contracts handling value, DeFi protocols, emergency response capability

---

### SafeERC20
**Purpose:** Safe token operations handling non-standard ERC20s
**Gas:** ~500 gas overhead (worth it!)

```solidity
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault {
    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(IERC20 token, uint256 amount) external {
        token.safeTransfer(msg.sender, amount);
    }
}
```

**Methods:** `safeTransfer`, `safeTransferFrom`, `safeApprove`, `forceApprove`, `safeIncreaseAllowance`, `safeDecreaseAllowance`

**When to use:** ALL external token interactions (always!)

---

## Token Standards

### ERC20 (Fungible Tokens)

```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
```

**Common Extensions:**
- `ERC20Burnable` - Allow token burning
- `ERC20Capped` - Maximum supply limit
- `ERC20Permit` - Gasless approvals (EIP-2612)
- `ERC20Votes` - Governance voting power
- `ERC20Snapshot` - Historical balance tracking
- `ERC20FlashMint` - Flash loan support

**Gas Costs:**
- Transfer: ~21,000-50,000 gas
- Approve: ~45,000 gas
- Mint: ~50,000 gas

---

### ERC721 (NFTs)

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint256 private _tokenIds;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(address to) external returns (uint256) {
        _tokenIds++;
        _safeMint(to, _tokenIds);
        return _tokenIds;
    }
}
```

**Common Extensions:**
- `ERC721Enumerable` - Enumerate all tokens (expensive!)
- `ERC721URIStorage` - Per-token metadata URIs
- `ERC721Burnable` - Allow burning
- `ERC721Royalty` - Creator royalties (EIP-2981)

**Gas Costs:**
- Mint: ~50,000-100,000 gas
- Transfer: ~50,000-80,000 gas
- SafeMint: +5,000 gas (calls recipient)

---

### ERC1155 (Multi-Token)

```solidity
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract GameItems is ERC1155 {
    constructor() ERC1155("https://api.example.com/items/{id}.json") {}

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        _mintBatch(to, ids, amounts, "");
    }
}
```

**Gas Costs:**
- Single transfer: ~30,000 gas
- Batch transfer (5 items): ~50,000 gas (much cheaper!)

---

## Token Standard Comparison

| Feature | ERC20 | ERC721 | ERC1155 |
|---------|-------|--------|---------|
| **Type** | Fungible | Non-fungible | Both |
| **Batch Ops** | ❌ | ❌ | ✅ |
| **Gas Efficiency** | High | Medium | Highest |
| **Use Case** | Currency | Collectibles | Gaming |
| **Divisible** | ✅ | ❌ | Per-token type |
| **Transfer Cost** | ~50k | ~80k | ~30k (batch cheaper) |

---

## Upgrade Patterns

### UUPS (Recommended)
**Purpose:** Upgradeable contracts with logic in implementation
**Gas:** ~2,500 gas overhead per call

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyContractV1 is UUPSUpgradeable, OwnableUpgradeable {
    uint256 public value;

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function setValue(uint256 newValue) external onlyOwner {
        value = newValue;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
```

**Deploy:**
```solidity
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Deploy implementation
MyContractV1 impl = new MyContractV1();

// Deploy proxy
ERC1967Proxy proxy = new ERC1967Proxy(
    address(impl),
    abi.encodeCall(MyContractV1.initialize, (owner))
);
```

---

### TransparentUpgradeableProxy
**Purpose:** Separates admin and user interfaces
**Gas:** ~3,000 gas overhead per call

```solidity
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
    implementation,
    admin,
    initData
);
```

---

### Proxy Pattern Comparison

| Pattern | Gas Overhead | Proxy Size | Upgrade Logic | Best For |
|---------|--------------|------------|---------------|----------|
| **UUPS** | ~2,500 gas | Smallest | Implementation | Modern projects |
| **Transparent** | ~3,000 gas | Larger | Proxy | Production (safer) |
| **Beacon** | ~2,800 gas | Medium | Beacon | Multiple instances |

**Upgrade Rules:**
- ⚠️ NEVER change storage layout order
- ✅ Only append new variables
- ✅ Use namespaced storage (ERC-7201)
- ✅ Test upgrades thoroughly

---

## Essential Utilities

### Cryptography

```solidity
// ECDSA Signatures
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
using ECDSA for bytes32;

address signer = messageHash.recover(signature);

// Merkle Proofs
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

bool valid = MerkleProof.verify(proof, root, leaf);

// EIP-712 Typed Data
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MyContract is EIP712 {
    constructor() EIP712("MyContract", "1") {}
}
```

**Gas Costs:**
- ECDSA recover: ~3,000 gas
- Merkle verify (depth 8): ~5,000 gas

---

### Data Structures

```solidity
// EnumerableSet (O(1) operations)
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
using EnumerableSet for EnumerableSet.AddressSet;

EnumerableSet.AddressSet private whitelist;
whitelist.add(addr);                    // ~20k gas
bool exists = whitelist.contains(addr); // ~3k gas
address member = whitelist.at(0);       // Enumerate

// BitMaps (packed booleans)
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
using BitMaps for BitMaps.BitMap;

BitMaps.BitMap private flags;
flags.set(index);     // ~12k gas vs 20k for bool
bool value = flags.get(index);

// EnumerableMap
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
using EnumerableMap for EnumerableMap.AddressToUintMap;

EnumerableMap.AddressToUintMap private balances;
balances.set(addr, value);
(bool exists, uint256 value) = balances.tryGet(addr);
```

---

### Math

```solidity
import "@openzeppelin/contracts/utils/math/Math.sol";

// Basic operations
uint256 max = Math.max(a, b);
uint256 min = Math.min(a, b);
uint256 avg = Math.average(a, b);
uint256 sqrt = Math.sqrt(x);

// Precision-safe multiplication/division
uint256 result = Math.mulDiv(a, b, c); // (a * b) / c without overflow

// Rounding modes
uint256 ceil = Math.mulDiv(a, b, c, Math.Rounding.Ceil);
uint256 floor = Math.mulDiv(a, b, c, Math.Rounding.Floor);

// SafeCast (prevent downcasting overflow)
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
using SafeCast for uint256;

uint128 small = large.toUint128(); // Reverts if overflow
```

---

### String & Address Utils

```solidity
// String conversions
import "@openzeppelin/contracts/utils/Strings.sol";
using Strings for uint256;

string memory str = tokenId.toString();
string memory hex = value.toHexString();

// Address operations
import "@openzeppelin/contracts/utils/Address.sol";
using Address for address;

bool isContract = addr.isContract();
addr.functionCall(data);              // Safe call
addr.functionCallWithValue(data, value);
```

---

### Nonces (Replay Protection)

```solidity
import "@openzeppelin/contracts/utils/Nonces.sol";

contract MyContract is Nonces {
    function executeWithSignature(
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(nonce == _useNonce(msg.sender), "Invalid nonce");
        // Verify signature and execute
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }
}
```

---

## Common Patterns

### 1. Secure Token Vault
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount)
        external
        nonReentrant
        whenNotPaused
    {
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function emergencyPause() external onlyOwner {
        _pause();
    }
}
```

---

### 2. Mintable NFT with Access Control
```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MintableNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _tokenIds;

    constructor() ERC721("MyNFT", "MNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to) external onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIds++;
        _safeMint(to, _tokenIds);
        return _tokenIds;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

---

### 3. Upgradeable ERC20 with Permit
```solidity
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyTokenV1 is
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    function initialize(address initialOwner) public initializer {
        __ERC20_init("MyToken", "MTK");
        __ERC20Permit_init("MyToken");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        _mint(initialOwner, 1000000 * 10**18);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
```

---

## Gas Cost Summary

| Contract/Operation | Gas Cost | Notes |
|-------------------|----------|-------|
| **Security** |||
| ReentrancyGuard check | ~2,400 | Per protected call |
| Ownable check | ~400 | Per onlyOwner |
| AccessControl check | ~2,000-3,000 | Per role check |
| Pausable check | ~300 | Per whenNotPaused |
| SafeERC20 overhead | ~500 | Worth it for safety |
| **Tokens** |||
| ERC20 transfer | ~21,000-50,000 | Depends on implementation |
| ERC721 mint | ~50,000-100,000 | +5,000 for safeMint |
| ERC1155 transfer | ~30,000 | Batch is much cheaper |
| **Utilities** |||
| ECDSA recover | ~3,000 | Signature verification |
| Merkle verify (d=8) | ~5,000 | 8-level tree |
| EnumerableSet add | ~20,000 | First write |
| BitMap set | ~12,500 | vs 20k for bool |
| **Proxies** |||
| UUPS overhead | ~2,500 | Per call |
| Transparent overhead | ~3,000 | Per call |

---

## Essential Imports Cheatsheet

```solidity
// Security
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// Utilities
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// Upgradeable (note: contracts-upgradeable package)
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
```

---

## Best Practices

### ✅ DO
- Use `SafeERC20` for all external token interactions
- Apply `nonReentrant` to functions making external calls
- Use `custom errors` instead of require strings (0.8.4+)
- Inherit from OZ contracts, don't modify them
- Use OZ Upgrades plugin for proxy deployments
- Lock pragma to specific version
- Test thoroughly with OZ test helpers

### ❌ DON'T
- Copy-paste OZ code (use imports)
- Modify OZ contracts directly
- Skip access control on privileged functions
- Use `tx.origin` for authorization
- Ignore return values from token calls
- Change storage layout in upgradeable contracts
- Deploy without auditing upgrade logic

---

## Resources

- **Docs**: https://docs.openzeppelin.com/contracts/5.x/
- **API Reference**: https://docs.openzeppelin.com/contracts/5.x/api/token/ERC20
- **Wizard**: https://wizard.openzeppelin.com/ (contract generator)
- **Forum**: https://forum.openzeppelin.com/
- **Security**: https://contracts.openzeppelin.com/security
- **GitHub**: https://github.com/OpenZeppelin/openzeppelin-contracts
- **Upgrades Plugin**: https://docs.openzeppelin.com/upgrades-plugins

---

**Pro Tip:** Use OpenZeppelin Wizard (https://wizard.openzeppelin.com/) to generate contract boilerplate with the exact features you need!
