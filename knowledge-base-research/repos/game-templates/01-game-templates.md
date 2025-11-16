# Game NFT Templates - ERC-721 & ERC-1155 for Games

> Quick patterns for game items and multi-token systems

**Purpose:** Copy-paste templates for game NFTs
**Read Time:** 5 minutes
**Best For:** Game mechanics with unique items or mixed tokens

---

## When to Use Each Standard

### ERC-721 (Unique Items Only)
```
Use when:
├─ Each item is unique (swords, characters, land)
├─ No fungible tokens needed
├─ Simpler economics

Example: CryptoKitties, game swords, unique avatars
```

### ERC-1155 (Mixed Tokens)
```
Use when:
├─ Need both unique items AND currency
├─ Want batch operations (cheaper gas)
├─ Cleaner architecture for complex games

Example: Game item + gold coins in same contract
```

---

## Template 1: Game ERC-721 Item

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameItem is ERC721, Ownable {
    struct Item {
        string name;
        uint256 level;
        uint256 rarity; // 1=normal, 2=rare, 3=epic, 4=legendary
    }

    Item[] public items;

    // Metadata URI
    string public baseURI = "https://game.example/items/";

    constructor() ERC721("GameItem", "ITEM") {}

    // Owner creates items and assigns to player
    function createItem(
        address to,
        string memory name,
        uint256 level,
        uint256 rarity
    ) external onlyOwner {
        uint256 tokenId = items.length;
        items.push(Item(name, level, rarity));
        _mint(to, tokenId);
    }

    // Batch create (gas-efficient)
    function createBatch(
        address[] memory players,
        string[] memory names,
        uint256[] memory levels
    ) external onlyOwner {
        require(
            players.length == names.length && players.length == levels.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < players.length; i++) {
            uint256 tokenId = items.length;
            items.push(Item(names[i], levels[i], 1));
            _mint(players[i], tokenId);
        }
    }

    // Get item details
    function getItem(uint256 tokenId)
        external
        view
        returns (Item memory)
    {
        require(_exists(tokenId), "Item does not exist");
        return items[tokenId];
    }

    // Level up item (only owner)
    function levelUp(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Item does not exist");
        items[tokenId].level += 1;
    }

    // Metadata URI for OpenSea/platforms
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Item does not exist");
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }
}
```

**Key Features:**
- ✅ Item struct with properties (name, level, rarity)
- ✅ Owner-controlled minting
- ✅ Batch creation (gas-efficient)
- ✅ Metadata URI for platforms
- ✅ Level-up mechanics

**Gas Cost:** ~90k gas per mint (single), ~60k per mint (batch)

---

## Template 2: Game ERC-1155 Multi-Token System

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameTokens is ERC1155, Ownable {
    // Token IDs
    uint256 public constant SWORD = 0;      // Unique item (1 created)
    uint256 public constant GOLD = 1;       // Currency (many created)
    uint256 public constant EXPERIENCE = 2; // Currency (many created)

    string public name = "GameTokens";
    string public symbol = "GAME";

    // Rarity levels for items
    mapping(uint256 => uint256) public itemRarity;

    constructor() ERC1155("https://game.example/api/items/{id}.json") {}

    // Owner mints unique item (rarity 1)
    function mintUniqueItem(address to, uint256 itemId) external onlyOwner {
        require(balanceOf(to, itemId) == 0, "Item already exists");
        itemRarity[itemId] = 4; // legendary
        _mint(to, itemId, 1, "");
    }

    // Owner mints fungible tokens (gold, exp, etc)
    function mintCurrency(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        require(tokenId != SWORD, "Cannot mint unique items");
        _mint(to, tokenId, amount, "");
    }

    // Batch mint (multiple tokens, multiple players) - GAS EFFICIENT!
    function batchMint(
        address[] memory players,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            players.length == ids.length && ids.length == amounts.length,
            "Array mismatch"
        );

        for (uint256 i = 0; i < players.length; i++) {
            _mint(players[i], ids[i], amounts[i], "");
        }
    }

    // Burn tokens (player uses currency)
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "Not approved"
        );
        _burn(account, id, amount);
    }

    // Batch burn (multiple tokens)
    function batchBurn(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "Not approved"
        );
        _burnBatch(account, ids, amounts);
    }

    // View balance of specific token
    function balanceOf(address account, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        return super.balanceOf(account, id);
    }

    // Get all balances for player
    function getAllBalances(address player)
        external
        view
        returns (
            uint256 swords,
            uint256 gold,
            uint256 experience
        )
    {
        return (
            balanceOf(player, SWORD),
            balanceOf(player, GOLD),
            balanceOf(player, EXPERIENCE)
        );
    }
}
```

**Key Features:**
- ✅ Mixed fungible + non-fungible tokens in one contract
- ✅ Batch minting (multiple tokens, multiple players, 1 transaction)
- ✅ Batch burning (players use currency)
- ✅ Gas-efficient (vs separate ERC20 + ERC721)
- ✅ Simple balance queries

**Gas Cost:**
- Single mint: ~40k gas
- Batch mint (10 items): ~4k per item (much cheaper!)
- vs ERC20: Would need separate contract + 2 approvals

---

## Comparison: Which to Use?

| Feature | ERC-721 | ERC-1155 |
|---------|---------|----------|
| **Unique items** | ✅ Natural | ⚠️ Must manage |
| **Fungible tokens** | ❌ No | ✅ Yes |
| **Batch operations** | ❌ No | ✅ Yes |
| **Gas cost** | Higher | Lower |
| **Simplicity** | Simpler | More flexible |

**Choose ERC-721 when:**
- Only unique items (no currency)
- Simpler contract needed
- Item transferability important

**Choose ERC-1155 when:**
- Mix of items + currency
- Want batch operations
- Gas optimization needed
- Building complex game economy

---

## Game Economics Example

```solidity
// Using ERC-1155 for full game:

contract GameEconomy is GameTokens {
    uint256 public swordPrice = 100e18; // 100 GOLD

    // Player buys sword with gold
    function buySword(uint256 swordId) external {
        require(balanceOf(msg.sender, GOLD) >= swordPrice, "Insufficient gold");

        // Burn gold
        _burn(msg.sender, GOLD, swordPrice);

        // Mint sword
        _mint(msg.sender, swordId, 1, "");

        emit SwordPurchased(msg.sender, swordId);
    }

    // Player sells sword for gold
    function sellSword(uint256 swordId) external {
        require(balanceOf(msg.sender, swordId) == 1, "Don't own sword");

        // Burn sword
        _burn(msg.sender, swordId, 1);

        // Mint gold (90% of price = game fee)
        uint256 goldReturn = (swordPrice * 90) / 100;
        _mint(msg.sender, GOLD, goldReturn, "");

        emit SwordSold(msg.sender, swordId);
    }

    event SwordPurchased(address indexed player, uint256 indexed swordId);
    event SwordSold(address indexed player, uint256 indexed swordId);
}
```

---

## Integration with Uniswap (Optional)

Allow players to trade items on secondary market:

```solidity
// Players can list items on Uniswap V4 or Seaport
// ERC-1155 support in most major marketplaces:
// - OpenSea ✅
// - LooksRare ✅
// - X2Y2 ✅

// OR: Build custom marketplace:
function listItemForSale(uint256 tokenId, uint256 price) external {
    // Transfer to escrow
    safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

    // Record listing
    listings[tokenId] = Listing({
        seller: msg.sender,
        price: price
    });
}
```

---

## Best Practices

✅ **DO:**
- Use ERC-1155 for complex games (items + currency)
- Implement batch operations for gas savings
- Add metadata URIs for platform compatibility
- Implement burn mechanism for currency

❌ **DON'T:**
- Store game state in blockchain (too expensive)
- Use for real-time actions (use game server + blockchain for settlement)
- Create new contract for each item type (use ERC-1155)

---

## Copy-Paste Checklist

- [ ] Choose: ERC-721 or ERC-1155?
- [ ] Copy appropriate template
- [ ] Update token IDs and names
- [ ] Set metadata baseURI
- [ ] Test on testnet
- [ ] Run security checklist (11-oracle-security-checklist.md)

---

**Status:** Ready to integrate game items
**Files:** Template solidity at lines above
