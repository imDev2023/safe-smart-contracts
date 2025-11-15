# Gas Optimization Quick Wins

Comprehensive gas optimization techniques ranked by impact, synthesized from leading gas optimization repositories.

**Sources:**
- 0xisk/awesome-solidity-gas-optimization
- harendra-shakya/solidity-gas-optimization
- WTFAcademy/WTF-gas-optimization

**Last Updated:** November 15, 2025

---

## High Impact Optimizations (>1000 gas saved)

### 1. Short-Circuit Logic - 99.9% Savings ⚡⚡⚡

**Description:** Place cheap conditions first in logical operations to avoid expensive checks.

**Gas Savings:** Up to 99.9% when first condition fails

**Code Example:**
```solidity
// ❌ BAD: Expensive check first
function validate(address user) external view returns (bool) {
    return balanceOf(user) > 1000 && isWhitelisted(user);
    // Always calls balanceOf even if not whitelisted
}

// ✅ GOOD: Cheap check first
function validate(address user) external view returns (bool) {
    return isWhitelisted(user) && balanceOf(user) > 1000;
    // Short-circuits if not whitelisted, saves ~2000 gas
}

// ✅ BETTER: Multiple conditions ordered by cost
require(amount > 0 && msg.value >= price && hasPermission(msg.sender));
// Cheapest → Most expensive
```

**Conditions:** Order conditions from cheapest to most expensive
- Value comparisons < Storage reads < External calls

**WTF Academy Benchmark:** 99.9% savings when expensive check avoided

---

### 2. Event Storage Instead of State - 94.6% Savings ⚡⚡⚡

**Description:** Store non-critical historical data in events instead of state variables.

**Gas Savings:** 94.6% compared to storage

**Code Example:**
```solidity
// ❌ BAD: Store in array (very expensive)
contract Expensive {
    uint256[] public history; // ~20,000 gas per push

    function record(uint256 value) external {
        history.push(value); // Costs ~43,000 gas
    }
}

// ✅ GOOD: Use events (cheap)
contract Cheap {
    event ValueRecorded(uint256 indexed value, uint256 timestamp);

    function record(uint256 value) external {
        emit ValueRecorded(value, block.timestamp); // Costs ~2,300 gas
    }
}

// Off-chain: Query events to build history
// Savings: ~40,700 gas per record (94.6%)
```

**Conditions:** Use for data that doesn't need on-chain querying
- Transaction history
- Audit logs
- Historical snapshots

**WTF Academy Benchmark:** 94.6% savings (2,300 gas vs 43,000 gas)

---

### 3. Constants and Immutables - 92.9% Savings ⚡⚡⚡

**Description:** Use `constant` and `immutable` for values that don't change.

**Gas Savings:** 92.9% on reads

**Code Example:**
```solidity
// ❌ BAD: Storage variable
contract Expensive {
    uint256 public multiplier = 100; // SLOAD: 2,100 gas

    function calculate(uint256 x) external view returns (uint256) {
        return x * multiplier; // 2,100 gas to read
    }
}

// ✅ GOOD: Constant (compile-time)
contract Cheap {
    uint256 public constant MULTIPLIER = 100; // Inlined: 150 gas

    function calculate(uint256 x) external pure returns (uint256) {
        return x * MULTIPLIER; // 150 gas to read
    }
}

// ✅ GOOD: Immutable (deploy-time)
contract ChapImmutable {
    uint256 public immutable deployTime; // Set in constructor: 150 gas

    constructor() {
        deployTime = block.timestamp;
    }
}
```

**Conditions:**
- Use `constant` for compile-time values
- Use `immutable` for constructor-time values
- Never change after deployment

**WTF Academy Benchmark:** 92.9% savings (150 gas vs 2,100 gas)

---

### 4. Delete Variables for Refunds - 89.6% Savings ⚡⚡⚡

**Description:** Delete storage variables to receive gas refunds.

**Gas Savings:** 89.6% net cost (15,000 gas refund)

**Code Example:**
```solidity
contract Refunds {
    mapping(address => uint256) public balances;

    // ❌ BAD: Set to 0 (no refund)
    function withdraw() external {
        balances[msg.sender] = 0; // Costs 2,900 gas
    }

    // ✅ GOOD: Delete for refund
    function withdrawOptimized() external {
        delete balances[msg.sender]; // Costs 2,900, refunds 15,000
        // Net: -12,100 gas benefit
    }
}

// Also works for structs and arrays
struct User {
    uint256 balance;
    bool active;
}

mapping(address => User) users;

function remove(address user) external {
    delete users[user]; // Refunds for all fields
}
```

**Conditions:**
- Only applies when clearing storage
- Maximum 15,000 gas refund per slot
- Refunds capped at 50% of transaction gas

**WTF Academy Benchmark:** 89.6% effective savings with refunds

---

### 5. Unchecked Arithmetic - 70.1% Savings ⚡⚡⚡

**Description:** Use `unchecked` blocks for operations that can't overflow/underflow.

**Gas Savings:** 70.1% on arithmetic operations

**Code Example:**
```solidity
// ❌ BAD: Checked arithmetic (Solidity 0.8+)
function sumArray(uint256[] memory arr) public pure returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < arr.length; i++) {
        total += arr[i]; // Overflow check: ~100 gas per iteration
    }
    return total;
}

// ✅ GOOD: Unchecked where safe
function sumArrayOptimized(uint256[] memory arr) public pure returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < arr.length;) {
        total += arr[i];
        unchecked { i++; } // Save ~70 gas per iteration
    }
    return total;
}

// ✅ GOOD: Unchecked for entire block
function calculate(uint256 x) public pure returns (uint256) {
    unchecked {
        // Safe because we validate input
        return (x + 10) * 2 - 5;
        // Saves ~210 gas for 3 operations
    }
}
```

**Conditions:** Only use when mathematically impossible to overflow/underflow
- Loop counters (won't exceed uint256 max)
- Increments after balance checks
- Operations on validated inputs

**WTF Academy Benchmark:** 70.1% savings (21 gas vs 70 gas per operation)

---

### 6. Mapping Over Arrays - 49.6%-59.2% Savings ⚡⚡

**Description:** Use mappings instead of arrays when iteration isn't needed.

**Gas Savings:** 49.6% for reads, 59.2% for writes

**Code Example:**
```solidity
// ❌ BAD: Array for lookups
contract ArrayBased {
    address[] public users;

    function hasUser(address user) external view returns (bool) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) return true; // O(n) complexity, expensive
        }
        return false;
    }
}

// ✅ GOOD: Mapping for O(1) lookups
contract MappingBased {
    mapping(address => bool) public isUser;

    function hasUser(address user) external view returns (bool) {
        return isUser[user]; // O(1), 2,100 gas vs 5,000+ gas
    }
}

// ✅ BEST: Hybrid approach when enumeration needed
contract Hybrid {
    mapping(address => bool) public isUser;
    address[] public userList; // Only for enumeration

    function addUser(address user) external {
        require(!isUser[user]);
        isUser[user] = true;
        userList.push(user);
    }
}
```

**Conditions:**
- Use mappings for lookups/checks
- Only use arrays when iteration is required
- Consider EnumerableSet for both needs

**WTF Academy Benchmark:** 49.6-59.2% savings on operations

---

### 7. Cache Storage Variables - 52.7% Savings ⚡⚡

**Description:** Cache storage variables in memory when used multiple times.

**Gas Savings:** 52.7% on subsequent reads

**Code Example:**
```solidity
// ❌ BAD: Multiple storage reads
contract Uncached {
    uint256 public totalSupply;

    function calculate() external view returns (uint256) {
        uint256 result = totalSupply * 2;     // SLOAD: 2,100 gas
        result += totalSupply / 2;            // SLOAD: 2,100 gas
        result -= totalSupply - 100;          // SLOAD: 2,100 gas
        return result;                         // Total: 6,300 gas
    }
}

// ✅ GOOD: Cache in memory
contract Cached {
    uint256 public totalSupply;

    function calculate() external view returns (uint256) {
        uint256 supply = totalSupply;         // SLOAD: 2,100 gas
        uint256 result = supply * 2;          // MLOAD: 3 gas
        result += supply / 2;                  // MLOAD: 3 gas
        result -= supply - 100;                // MLOAD: 3 gas
        return result;                         // Total: 2,109 gas
    }
    // Savings: 4,191 gas (66.5%)
}
```

**Conditions:**
- Variable used 2+ times in function
- Especially important in loops
- Balance caching vs memory costs

**WTF Academy Benchmark:** 52.7% average savings

---

### 8. ERC1167 Minimal Proxy (Clone) - 47.8% Savings ⚡⚡

**Description:** Deploy cheap clones instead of full contracts for multiple instances.

**Gas Savings:** 47.8% on deployment

**Code Example:**
```solidity
import "@openzeppelin/contracts/proxy/Clones.sol";

contract WalletFactory {
    address public implementation;

    constructor() {
        implementation = address(new Wallet());
    }

    // ❌ BAD: Deploy new contract each time
    function createWallet() external returns (address) {
        return address(new Wallet()); // ~200,000 gas
    }

    // ✅ GOOD: Clone implementation
    function createWalletClone() external returns (address) {
        return Clones.clone(implementation); // ~45,000 gas
    }
}

// Each clone delegates calls to implementation
// Perfect for: Token instances, user wallets, game items
```

**Conditions:**
- Multiple instances of same logic needed
- State is per-instance
- Slightly higher call cost (~2,000 gas per call)

**WTF Academy Benchmark:** 47.8% deployment savings

---

## Medium Impact Optimizations (100-1000 gas saved)

### 9. Custom Errors - 38.8% Savings ⚡⚡

**Description:** Use custom errors instead of require strings (Solidity 0.8.4+).

**Gas Savings:** 38.8% on reverts

**Code Example:**
```solidity
// ❌ BAD: String errors
contract StringErrors {
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // Each string costs ~50 gas + string length in deployment
    }
}

// ✅ GOOD: Custom errors
contract CustomErrors {
    error InvalidAmount();
    error InsufficientBalance(uint256 requested, uint256 available);

    function withdraw(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(amount, balances[msg.sender]);
        }
        // Much cheaper deployment and runtime
    }
}
```

**Conditions:**
- Solidity >= 0.8.4
- Parameters provide useful debugging info
- Better than strings in every way

**WTF Academy Benchmark:** 38.8% savings (deployment and runtime)

---

### 10. Bitmap for Booleans - 37.4% Savings ⚡⚡

**Description:** Pack multiple boolean values into single uint256 using bitmaps.

**Gas Savings:** 37.4% compared to bool array/mapping

**Code Example:**
```solidity
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// ❌ BAD: Mapping of bools
contract BoolMapping {
    mapping(uint256 => bool) public flags; // 20,000 gas per set
}

// ✅ GOOD: Bitmap
contract BitmapFlags {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private flags;

    function setFlag(uint256 index) external {
        flags.set(index); // ~12,500 gas
    }

    function getFlag(uint256 index) external view returns (bool) {
        return flags.get(index);
    }
}

// Manual implementation
contract ManualBitmap {
    uint256 private bitmap;

    function setFlag(uint8 index) external {
        bitmap |= (1 << index); // Set bit at index
    }

    function clearFlag(uint8 index) external {
        bitmap &= ~(1 << index); // Clear bit at index
    }

    function getFlag(uint8 index) external view returns (bool) {
        return (bitmap >> index) & 1 == 1;
    }
}
```

**Conditions:**
- Many boolean flags (>10)
- Dense index space
- Flags related/grouped logically

**WTF Academy Benchmark:** 37.4% savings

---

### 11. uint256 in Loops - 19.6% Savings ⚡

**Description:** Use uint256 instead of smaller uints in loops (counter-intuitive but true!).

**Gas Savings:** 19.6% in loops

**Code Example:**
```solidity
// ❌ BAD: uint8 in loop
function sumBad(uint256[] memory arr) public pure returns (uint256) {
    uint256 total;
    for (uint8 i = 0; i < arr.length; i++) {
        total += arr[i]; // Extra gas for type conversion
    }
    return total;
}

// ✅ GOOD: uint256 in loop
function sumGood(uint256[] memory arr) public pure returns (uint256) {
    uint256 total;
    for (uint256 i = 0; i < arr.length; i++) {
        total += arr[i]; // Native EVM word size
    }
    return total;
}
```

**Conditions:**
- Loop counters
- Temporary variables in functions
- Not applicable to storage (use packing there)

**WTF Academy Benchmark:** 19.6% savings in loops

---

### 12. Storage Packing - 16.6% Savings ⚡

**Description:** Pack multiple variables into single storage slots.

**Gas Savings:** 16.6% average, up to 50% possible

**Code Example:**
```solidity
// ❌ BAD: Unpacked (3 slots)
struct User {
    uint256 id;        // Slot 0
    address addr;      // Slot 1
    bool active;       // Slot 2
}
// First write: 60,000 gas

// ✅ GOOD: Packed (2 slots)
struct UserOptimized {
    address addr;      // Slot 0 (20 bytes)
    uint64 id;         // Slot 0 (8 bytes)
    uint32 timestamp;  // Slot 0 (4 bytes)
    // Slot 0 total: 32 bytes = perfectly packed!
    bool active;       // Slot 1
}
// First write: 40,000 gas (33% savings)

// ✅ BEST: Fully packed (1 slot)
struct UserFullyPacked {
    address addr;      // 20 bytes
    uint64 timestamp;  // 8 bytes
    uint32 id;         // 4 bytes
    // Total: 32 bytes = 1 slot!
}
// First write: 20,000 gas (66% savings)
```

**Conditions:**
- Variables accessed together
- Types fit within 32 bytes
- Trade-off with readability

**WTF Academy Benchmark:** 16.6% average savings

---

### 13. Shorter Revert Strings - 9.0% Savings ⚡

**Description:** Use short error messages or custom errors.

**Gas Savings:** 9.0% on deployment

**Code Example:**
```solidity
// ❌ BAD: Long strings
require(amount > 0, "The amount must be greater than zero to proceed");

// ✅ BETTER: Short strings
require(amount > 0, "Amount > 0");

// ✅ BEST: Custom errors (see #9)
if (amount == 0) revert InvalidAmount();
```

**WTF Academy Benchmark:** 9.0% deployment savings

---

### 14. Pre-increment (++i) - 5.4% Savings ⚡

**Description:** Use ++i instead of i++ in loops.

**Gas Savings:** 5.4% per increment

**Code Example:**
```solidity
// ❌ BAD: Post-increment
for (uint256 i = 0; i < arr.length; i++) {
    // i++ creates temporary copy
}

// ✅ GOOD: Pre-increment
for (uint256 i = 0; i < arr.length; ++i) {
    // ++i no temporary needed
}

// ✅ BETTER: Unchecked pre-increment
for (uint256 i = 0; i < arr.length;) {
    // logic
    unchecked { ++i; }
}
```

**WTF Academy Benchmark:** 5.4% savings (6 gas per iteration)

---

## Low Impact Optimizations (<100 gas saved)

### 15. Avoid Zero Initialization - 3.2% Savings

```solidity
// ❌ BAD
uint256 total = 0;

// ✅ GOOD
uint256 total; // Defaults to 0, saves ~3 gas
```

**WTF Academy Benchmark:** 3.2% savings

---

### 16. bytes32 for Short Strings - 2.0% Savings

```solidity
// ❌ BAD: string for short values
string public name = "ABC";

// ✅ GOOD: bytes32 for ≤32 chars
bytes32 public name = "ABC";
```

**WTF Academy Benchmark:** 2.0% savings

---

### 17. Fixed-Size Arrays - 1.9% Savings

```solidity
// ❌ BAD: Dynamic array
uint256[] memory arr = new uint256[](5);

// ✅ GOOD: Fixed-size when known
uint256[5] memory arr;
```

**WTF Academy Benchmark:** 1.9% savings

---

### 18. < instead of <= - 1.2% Savings

```solidity
// ❌ BAD
require(value <= 100);

// ✅ GOOD (when possible)
require(value < 101);
```

**WTF Academy Benchmark:** 1.2% savings

---

### 19. Calldata for Read-Only Arrays - 0.8% Savings

```solidity
// ❌ BAD: memory for external
function process(uint256[] memory arr) external {
    // Copies to memory
}

// ✅ GOOD: calldata (read-only)
function process(uint256[] calldata arr) external {
    // No copy, direct access
}
```

**WTF Academy Benchmark:** 0.8% savings

---

### 20. Optimize Function Selectors - 0.4%-40.2% Savings

**Description:** Order frequently-called functions to have lower selectors.

**Code Example:**
```solidity
// Function selectors are first 4 bytes of keccak256("functionName()")
// Lower selectors = slightly cheaper calls

// Rename functions to optimize:
function transfer_H4C() external { } // Lower selector
function transfer() external { }      // Higher selector

// Tool to find optimal names:
// https://emn178.github.io/online-tools/keccak_256.html
```

**Conditions:**
- Marginal benefit (3-30 gas)
- Only worth for high-frequency functions
- Hurts readability

**WTF Academy Benchmark:** 0.4-40.2% savings based on call frequency

---

### 21. Payable Constructors - 0.1% Savings

```solidity
// ❌ BAD
constructor() {}

// ✅ GOOD: Saves 10 opcodes
constructor() payable {}
```

**WTF Academy Benchmark:** 0.1% savings (200 gas)

---

## Optimization Priority Matrix

| Priority | Optimization | Effort | Savings | When to Use |
|----------|-------------|--------|---------|-------------|
| 🔥 CRITICAL | Unchecked arithmetic | Low | 70.1% | Loops, safe math |
| 🔥 CRITICAL | Constants/immutables | Low | 92.9% | Fixed values |
| 🔥 CRITICAL | Custom errors | Low | 38.8% | All projects (0.8.4+) |
| 🔥 HIGH | Delete for refunds | Low | 89.6% | Clearing storage |
| 🔥 HIGH | Cache storage | Medium | 52.7% | Multiple reads |
| 🔥 HIGH | Mappings over arrays | Medium | 49.6% | Lookups |
| 🔥 HIGH | Event storage | Medium | 94.6% | Historical data |
| 🔥 HIGH | Short-circuit logic | Low | 99.9% | Complex conditions |
| ⚡ MEDIUM | Storage packing | Medium | 16.6% | Related variables |
| ⚡ MEDIUM | Bitmap flags | High | 37.4% | Many booleans |
| ⚡ MEDIUM | Clone pattern | Medium | 47.8% | Multiple instances |
| 💡 LOW | ++i vs i++ | Low | 5.4% | All loops |
| 💡 LOW | Calldata | Low | 0.8% | External functions |
| 💡 LOW | Avoid zero init | Low | 3.2% | All variables |

---

## Safe Smart Contract Specific Optimizations

### Multi-Sig Specific

```solidity
// 1. Pack Safe configuration
struct SafeConfig {
    address singleton;    // 20 bytes - Slot 0
    uint64 nonce;        // 8 bytes  - Slot 0
    uint32 threshold;    // 4 bytes  - Slot 0
    // Perfect 32-byte slot!
}

// 2. Bitmap for owner status
BitMaps.BitMap private ownerBitmap; // Instead of mapping(address => bool)

// 3. Unchecked nonce increment
function incrementNonce() internal {
    unchecked { nonce++; } // Nonce won't overflow in practice
}

// 4. Event for transaction history
event ExecutionSuccess(bytes32 txHash, uint256 payment);
// Instead of storing in array

// 5. Custom errors for all validations
error InvalidThreshold(uint256 provided, uint256 required);
error DuplicateOwner(address owner);
```

---

## Testing Gas Optimization

### Foundry Gas Reports

```solidity
// forge test --gas-report

contract GasTest is Test {
    function testGasComparison() public {
        uint256 gasBefore = gasleft();
        optimizedFunction();
        uint256 gasAfter = gasleft();
        console.log("Gas used:", gasBefore - gasAfter);
    }
}
```

### Hardhat Gas Reporter

```javascript
// hardhat.config.js
module.exports = {
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 21
  }
};
```

---

## Common Pitfalls

### ❌ Don't Micro-Optimize Too Early
Focus on high-impact optimizations first. Saving 5 gas isn't worth reduced readability.

### ❌ Don't Break Security for Gas
Never sacrifice safety for optimization. ReentrancyGuard overhead is worth it.

### ❌ Don't Optimize Without Measuring
Use profilers and gas reports. Your assumptions may be wrong.

### ❌ Don't Forget Deployment vs Runtime
Some optimizations save deployment gas but cost runtime gas (and vice versa).

---

## Quick Win Checklist

High-impact, low-effort optimizations to apply to every contract:

- [ ] Use Solidity 0.8.0+ for automatic overflow checks
- [ ] Mark fixed values as `constant` or `immutable`
- [ ] Use custom errors instead of require strings
- [ ] Apply `unchecked` to safe arithmetic (loops, validated math)
- [ ] Cache storage variables used multiple times
- [ ] Use `mapping` instead of array for lookups
- [ ] Order logical conditions from cheap to expensive
- [ ] Use `calldata` for read-only external function parameters
- [ ] Use `++i` instead of `i++` in loops
- [ ] Delete storage variables when no longer needed
- [ ] Pack related struct fields into slots
- [ ] Use events for historical data
- [ ] Use `clone` pattern for multiple contract instances

---

## Resources

- **WTF Academy Gas Optimization**: https://github.com/WTFAcademy/WTF-gas-optimization
- **0xisk Resource List**: https://github.com/0xisk/awesome-solidity-gas-optimization
- **Harendra Shakya Guide**: https://github.com/harendra-shakya/solidity-gas-optimization
- **Foundry Gas Tracking**: https://book.getfoundry.sh/forge/gas-tracking
- **Solidity Docs**: https://docs.soliditylang.org/en/latest/internals/optimizer.html

---

**Remember:** Optimize for maintainability first, then security, then gas. A contract that's 10% cheaper but impossible to audit is a bad trade-off.
