# Token Standards

OpenZeppelin provides battle-tested implementations of all major Ethereum token standards. These are the foundation for creating tradable assets, collectibles, and complex token ecosystems.

## Overview

Token contracts are smart contracts that represent something of value on the blockchain - money, collectibles, voting rights, or any other asset. OpenZeppelin implements the official ERC standards with security, gas efficiency, and extensibility in mind.

## Token Standards Covered

### 1. ERC20 - Fungible Tokens
**File**: `ERC20.md`

The most widely used token standard for fungible (interchangeable) tokens like currencies, points, and shares.

**Key Characteristics**:
- Fungible: All tokens are identical and interchangeable
- Divisible: Can be split into fractional amounts
- Transferable: Can move between addresses
- Allowances: Delegate spending to other addresses

**Common Use Cases**:
- Cryptocurrencies (DAI, USDC, LINK)
- Governance tokens (UNI, AAVE, COMP)
- Reward points and loyalty programs
- Tokenized securities and assets

### 2. ERC721 - Non-Fungible Tokens (NFTs)
**File**: `ERC721.md`

Standard for non-fungible tokens where each token is unique and not interchangeable.

**Key Characteristics**:
- Non-fungible: Each token is unique
- Indivisible: Cannot be split into fractions
- Unique metadata: Each token can have distinct properties
- Ownership tracking: Clear ownership of individual tokens

**Common Use Cases**:
- Digital art and collectibles (CryptoPunks, Bored Apes)
- Gaming items and characters
- Real estate and physical asset tokenization
- Identity and credentials
- Domain names (ENS)

### 3. ERC1155 - Multi-Token Standard
**File**: `ERC1155.md`

Advanced standard supporting both fungible and non-fungible tokens in a single contract.

**Key Characteristics**:
- Mixed token types: Fungible and non-fungible in one contract
- Batch operations: Transfer multiple token types at once
- Gas efficient: Reduced deployment and transaction costs
- Flexible: Ideal for gaming and complex ecosystems

**Common Use Cases**:
- Gaming (multiple item types in one contract)
- Virtual worlds with various asset types
- Ticketing systems (fungible and unique tickets)
- Complex token ecosystems

## Feature Comparison

| Feature | ERC20 | ERC721 | ERC1155 |
|---------|-------|--------|---------|
| Token Type | Fungible only | Non-fungible only | Both |
| Batch Transfers | No | No | Yes |
| Metadata | Contract-level | Per-token | Per-token-type |
| Gas Efficiency | High | Medium | Highest |
| Complexity | Simple | Medium | Advanced |
| Deployment Cost | Low | Medium | Medium |
| Transfer Cost | Low | Medium | Lowest (batch) |
| Use Case | Currencies | Collectibles | Gaming/Mixed |

## Common Token Extensions

OpenZeppelin provides many extensions for additional functionality:

### Security Extensions
- **Pausable**: Emergency stop mechanism
- **AccessControl**: Role-based permissions
- **Ownable**: Owner-only functions

### Token Functionality
- **Burnable**: Allow token destruction
- **Mintable**: Create new tokens
- **Capped**: Maximum supply limit
- **Snapshot**: Historical balance tracking
- **Votes**: On-chain governance support

### Economic Features
- **Permit**: Gasless approvals (ERC20)
- **FlashMint**: Flash loan functionality (ERC20)
- **Royalty**: Creator royalties (ERC721/ERC1155)
- **Enumerable**: Token enumeration (ERC721)

## Security Best Practices

### 1. Use OpenZeppelin Implementations
```solidity
// GOOD: Use audited implementations
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {}
}
```

### 2. Protect Mint Functions
```solidity
contract MyToken is ERC20, Ownable {
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

### 3. Consider Maximum Supply
```solidity
contract CappedToken is ERC20 {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;

    function mint(address to, uint256 amount) public {
        require(totalSupply() + amount <= MAX_SUPPLY, "Cap exceeded");
        _mint(to, amount);
    }
}
```

### 4. Use SafeERC20 for Interactions
```solidity
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

function deposit(IERC20 token, uint256 amount) external {
    token.safeTransferFrom(msg.sender, address(this), amount);
}
```

## Gas Optimization Tips

### ERC20
```solidity
// Use unchecked for known-safe operations
function _update(address from, address to, uint256 value) internal virtual {
    if (from == address(0)) {
        unchecked {
            _totalSupply += value;
        }
    }
    // ...
}
```

### ERC721
```solidity
// Batch mint to save gas
function batchMint(address[] calldata recipients) external {
    for (uint256 i = 0; i < recipients.length; i++) {
        _mint(recipients[i], nextTokenId++);
    }
}
```

### ERC1155
```solidity
// Use batch operations
function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
) public {
    _mintBatch(to, ids, amounts, "");
}
```

## Testing Token Contracts

### Basic ERC20 Test
```javascript
describe("ERC20", function() {
    it("should have correct initial supply", async function() {
        expect(await token.totalSupply()).to.equal(INITIAL_SUPPLY);
    });

    it("should transfer tokens", async function() {
        await token.transfer(addr1.address, 100);
        expect(await token.balanceOf(addr1.address)).to.equal(100);
    });

    it("should handle allowances", async function() {
        await token.approve(addr1.address, 100);
        await token.connect(addr1).transferFrom(owner.address, addr2.address, 100);
    });
});
```

### Basic ERC721 Test
```javascript
describe("ERC721", function() {
    it("should mint NFT", async function() {
        await nft.mint(addr1.address, 1);
        expect(await nft.ownerOf(1)).to.equal(addr1.address);
    });

    it("should transfer NFT", async function() {
        await nft.mint(addr1.address, 1);
        await nft.connect(addr1).transferFrom(addr1.address, addr2.address, 1);
        expect(await nft.ownerOf(1)).to.equal(addr2.address);
    });
});
```

## Choosing the Right Standard

### Use ERC20 when:
- All tokens are identical and interchangeable
- You need divisibility (decimal places)
- Building currencies, points, or shares
- Maximum compatibility is important

### Use ERC721 when:
- Each token is unique
- Tokens represent distinct assets
- You need individual metadata per token
- Building collectibles or NFTs

### Use ERC1155 when:
- You have multiple token types
- You need both fungible and non-fungible tokens
- Batch operations are important
- Gas efficiency is critical (gaming)
- Building complex token ecosystems

## Resources

- [OpenZeppelin ERC20 Docs](https://docs.openzeppelin.com/contracts/5.x/erc20)
- [OpenZeppelin ERC721 Docs](https://docs.openzeppelin.com/contracts/5.x/erc721)
- [OpenZeppelin ERC1155 Docs](https://docs.openzeppelin.com/contracts/5.x/erc1155)
- [Ethereum Token Standards](https://ethereum.org/en/developers/docs/standards/tokens/)

## Next Steps

For detailed implementation guides, see individual token documentation:
- [ERC20.md](./ERC20.md) - Fungible tokens
- [ERC721.md](./ERC721.md) - Non-fungible tokens (NFTs)
- [ERC1155.md](./ERC1155.md) - Multi-token standard
