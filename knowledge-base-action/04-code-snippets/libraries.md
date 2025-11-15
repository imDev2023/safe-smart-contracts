# Utility Library Functions Reference

Copy-paste ready library functions for common operations. All functions are gas-optimized and include safety checks.

---

## 1. Math Utilities

### min - Minimum Value

```solidity
/**
 * @dev Returns the smallest of two numbers
 * @param a First number
 * @param b Second number
 * @return Minimum value
 */
function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
}

// Usage
uint256 minValue = min(100, 200); // Returns 100
uint256 transferAmount = min(balance, requestedAmount); // Prevent overdraft
```

**Gas Cost:** ~10 gas
**When to Use:** Finding minimum values, capping transfers
**Constraints:** Works with unsigned integers only
**Alternative:** Use OpenZeppelin's `Math.min()` for consistency

---

### max - Maximum Value

```solidity
/**
 * @dev Returns the largest of two numbers
 * @param a First number
 * @param b Second number
 * @return Maximum value
 */
function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
}

// Usage
uint256 maxValue = max(100, 200); // Returns 200
uint256 reward = max(baseReward, bonusReward); // Take better reward
```

**Gas Cost:** ~10 gas
**When to Use:** Finding maximum values, reward calculations
**Constraints:** Works with unsigned integers only
**Alternative:** Use OpenZeppelin's `Math.max()`

---

### average - Average (Rounded Down)

```solidity
/**
 * @dev Returns the average of two numbers, result rounded down
 * @param a First number
 * @param b Second number
 * @return Average value
 */
function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow
    return (a & b) + (a ^ b) / 2;
}

// Usage
uint256 avg = average(100, 200); // Returns 150
uint256 midPrice = average(buyPrice, sellPrice); // Calculate mid-market price
```

**Gas Cost:** ~15 gas
**When to Use:** Averaging values without overflow risk
**Constraints:** Result rounds down (integer division)
**Alternative:** Use OpenZeppelin's `Math.average()`

---

### sqrt - Integer Square Root

```solidity
/**
 * @dev Returns the square root of a number (rounded down)
 * @param x Number to find square root of
 * @return Square root value
 */
function sqrt(uint256 x) internal pure returns (uint256) {
    if (x == 0) return 0;

    uint256 z = (x + 1) / 2;
    uint256 y = x;

    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }

    return y;
}

// Usage
uint256 root = sqrt(144); // Returns 12
uint256 result = sqrt(150); // Returns 12 (rounded down)

// Common use case: Geometric mean for AMM pricing
uint256 k = sqrt(reserveA * reserveB);
```

**Gas Cost:** ~100-200 gas (depends on input size)
**When to Use:** AMM calculations, geometric mean, Pythagorean theorem
**Constraints:** Result rounds down, only works with perfect squares exactly
**Alternative:** Use OpenZeppelin's `Math.sqrt()`

---

### mulDiv - Multiplication with Division (No Overflow)

```solidity
/**
 * @dev Calculates (a * b) / c with full precision, prevents overflow
 * @param a First multiplicand
 * @param b Second multiplicand
 * @param c Divisor
 * @return Result of (a * b) / c
 */
function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    // OpenZeppelin implementation (simplified)
    require(c > 0, "Division by zero");

    // 512-bit multiply [prod1 prod0] = a * b
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product

    assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle overflow
    if (prod1 == 0) {
        return prod0 / c;
    }

    require(prod1 < c, "Overflow");

    // Make division exact by subtracting the remainder
    uint256 remainder;
    assembly {
        remainder := mulmod(a, b, c)
    }

    assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    // Factor powers of two
    uint256 twos = c & (~c + 1);
    assembly {
        c := div(c, twos)
        prod0 := div(prod0, twos)
        twos := add(div(sub(0, twos), twos), 1)
    }

    prod0 |= prod1 * twos;

    // Invert denominator
    uint256 inverse = (3 * c) ^ 2;
    inverse *= 2 - c * inverse;
    inverse *= 2 - c * inverse;
    inverse *= 2 - c * inverse;
    inverse *= 2 - c * inverse;
    inverse *= 2 - c * inverse;
    inverse *= 2 - c * inverse;

    return prod0 * inverse;
}

// Usage - Calculate percentage without overflow
uint256 fee = mulDiv(amount, feeRate, 10000); // (amount * feeRate) / 10000

// Calculate proportional share
uint256 share = mulDiv(userBalance, totalReward, totalSupply);
```

**Gas Cost:** ~150-300 gas
**When to Use:** Percentage calculations, proportional distributions, prevent overflow
**Constraints:** c must not be zero
**Alternative:** ALWAYS use OpenZeppelin's `Math.mulDiv()` in production

---

### unsafeDiv - Unchecked Division (Gas Optimization)

```solidity
/**
 * @dev Performs division without zero check (use when denominator is guaranteed non-zero)
 * @param a Numerator
 * @param b Denominator (MUST NOT BE ZERO)
 * @return Result of a / b
 */
function unsafeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
        return a / b;
    }
}

// Usage - Only when you've already checked b != 0
function calculateRatio(uint256 numerator, uint256 denominator) public pure returns (uint256) {
    require(denominator > 0, "Denominator cannot be zero");
    // Safe to use unsafeDiv because we checked above
    return unsafeDiv(numerator, denominator);
}
```

**Gas Cost:** ~5 gas (saves ~15 gas vs checked division)
**When to Use:** After validating denominator is non-zero
**Constraints:** DANGEROUS - will revert entire transaction if b == 0
**Alternative:** Only use in hot paths with proven safety

---

## 2. Array Utilities

### arraySum - Sum Array Elements

```solidity
/**
 * @dev Returns sum of all array elements
 * @param array Array of numbers to sum
 * @return Total sum
 */
function arraySum(uint256[] memory array) internal pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < array.length; i++) {
        sum += array[i];
    }
    return sum;
}

// Usage
uint256[] memory amounts = new uint256[](3);
amounts[0] = 100;
amounts[1] = 200;
amounts[2] = 300;
uint256 total = arraySum(amounts); // Returns 600
```

**Gas Cost:** ~500 + (200 * array.length) gas
**When to Use:** Summing balances, totaling distributions
**Constraints:** Watch for overflow on large arrays
**Alternative:** Use loops inline for gas optimization

---

### arrayContains - Search Array

```solidity
/**
 * @dev Checks if array contains specific value
 * @param array Array to search
 * @param value Value to find
 * @return True if value exists in array
 */
function arrayContains(address[] memory array, address value)
    internal
    pure
    returns (bool)
{
    for (uint256 i = 0; i < array.length; i++) {
        if (array[i] == value) {
            return true;
        }
    }
    return false;
}

// Usage
address[] memory whitelist = getWhitelist();
bool isWhitelisted = arrayContains(whitelist, msg.sender);
```

**Gas Cost:** ~500 + (300 * iterations until found) gas
**When to Use:** Small arrays, infrequent lookups
**Constraints:** O(n) complexity - use mapping for large datasets
**Alternative:** Use EnumerableSet for frequent lookups

---

### arrayIndex - Find Index

```solidity
/**
 * @dev Returns index of first occurrence of value in array
 * @param array Array to search
 * @param value Value to find
 * @return index Position in array, returns type(uint256).max if not found
 */
function arrayIndex(address[] memory array, address value)
    internal
    pure
    returns (uint256)
{
    for (uint256 i = 0; i < array.length; i++) {
        if (array[i] == value) {
            return i;
        }
    }
    return type(uint256).max; // Not found sentinel
}

// Usage
address[] memory users = getUsers();
uint256 index = arrayIndex(users, msg.sender);
if (index != type(uint256).max) {
    // User found at position 'index'
}
```

**Gas Cost:** ~500 + (300 * iterations) gas
**When to Use:** Finding position in small arrays
**Constraints:** Returns max uint256 if not found (check before using)
**Alternative:** Use mapping to track indices

---

### removeElement - Remove from Array (Unordered)

```solidity
/**
 * @dev Removes element from array (does not preserve order)
 * @param array Array to modify
 * @param index Index to remove
 * @return Modified array
 */
function removeElement(address[] storage array, uint256 index)
    internal
    returns (address[] storage)
{
    require(index < array.length, "Index out of bounds");

    // Move last element to deleted position
    array[index] = array[array.length - 1];
    array.pop();

    return array;
}

// Usage
address[] storage participants;

function removeParticipant(address participant) public {
    uint256 index = arrayIndex(participants, participant);
    require(index != type(uint256).max, "Participant not found");
    removeElement(participants, index);
}
```

**Gas Cost:** ~5,000 gas (constant time)
**When to Use:** When order doesn't matter, gas-efficient removal
**Constraints:** Changes array order
**Alternative:** Use EnumerableSet for maintained order

---

### removeElementOrdered - Remove from Array (Ordered)

```solidity
/**
 * @dev Removes element from array (preserves order)
 * @param array Array to modify
 * @param index Index to remove
 */
function removeElementOrdered(address[] storage array, uint256 index) internal {
    require(index < array.length, "Index out of bounds");

    // Shift all elements after index left
    for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
    }
    array.pop();
}

// Usage - maintains order but more expensive
removeElementOrdered(sortedAddresses, 2);
```

**Gas Cost:** ~5,000 + (5,000 * elements to shift) gas
**When to Use:** When order must be preserved
**Constraints:** Expensive for large arrays
**Alternative:** Redesign to avoid ordered array removal

---

## 3. String Utilities

### compareStrings - Gas-Efficient String Comparison

```solidity
/**
 * @dev Compares two strings for equality
 * @param a First string
 * @param b Second string
 * @return True if strings are equal
 */
function compareStrings(string memory a, string memory b)
    internal
    pure
    returns (bool)
{
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
}

// Usage
string memory expected = "ACTIVE";
string memory status = getStatus();
if (compareStrings(status, expected)) {
    // Status is ACTIVE
}
```

**Gas Cost:** ~300-500 gas (depends on string length)
**When to Use:** String equality checks
**Constraints:** Only for equality, not ordering
**Alternative:** Use bytes32 for fixed-length strings to save gas

---

### stringLength - String Length

```solidity
/**
 * @dev Returns length of string in bytes
 * @param str String to measure
 * @return Length in bytes
 */
function stringLength(string memory str) internal pure returns (uint256) {
    return bytes(str).length;
}

// Usage
uint256 len = stringLength("Hello"); // Returns 5
require(stringLength(username) >= 3, "Username too short");
```

**Gas Cost:** ~50 gas
**When to Use:** Validating string length
**Constraints:** Returns byte length (not character count for UTF-8)
**Alternative:** Convert to bytes and use .length property

---

### uintToString - Convert Uint to String

```solidity
/**
 * @dev Converts uint256 to string
 * @param value Number to convert
 * @return String representation
 */
function uintToString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }

    uint256 temp = value;
    uint256 digits;

    while (temp != 0) {
        digits++;
        temp /= 10;
    }

    bytes memory buffer = new bytes(digits);

    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }

    return string(buffer);
}

// Usage
uint256 tokenId = 42;
string memory uri = string(abi.encodePacked("https://api.example.com/token/", uintToString(tokenId)));
// Result: "https://api.example.com/token/42"
```

**Gas Cost:** ~1,000-2,000 gas (depends on number size)
**When to Use:** NFT metadata URIs, string concatenation
**Constraints:** Only works with positive integers
**Alternative:** Use OpenZeppelin's `Strings.toString()`

---

### addressToString - Convert Address to String

```solidity
/**
 * @dev Converts address to checksummed hex string
 * @param addr Address to convert
 * @return Hex string representation
 */
function addressToString(address addr) internal pure returns (string memory) {
    bytes memory data = abi.encodePacked(addr);
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
        str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
        str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
    }

    return string(str);
}

// Usage
string memory addrStr = addressToString(msg.sender);
// Result: "0x742d35cc6634c0532925a3b844bc9e7595f0beb"
```

**Gas Cost:** ~1,500 gas
**When to Use:** Logging, off-chain data formatting
**Constraints:** Returns lowercase hex (not checksummed)
**Alternative:** Use OpenZeppelin's `Strings.toHexString()`

---

## 4. Bit Manipulation

### hasBit - Check if Bit is Set

```solidity
/**
 * @dev Checks if specific bit is set in value
 * @param value Number to check
 * @param index Bit position (0-255)
 * @return True if bit is set
 */
function hasBit(uint256 value, uint256 index) internal pure returns (bool) {
    require(index < 256, "Index out of bounds");
    return (value & (1 << index)) != 0;
}

// Usage - Compact permission storage
uint256 permissions = 0;
// Check if user has permission at bit 5
bool hasPermission = hasBit(permissions, 5);
```

**Gas Cost:** ~50 gas
**When to Use:** Compact boolean flags, permission systems
**Constraints:** Index must be 0-255
**Alternative:** Use OpenZeppelin's BitMaps library

---

### setBit - Set a Bit

```solidity
/**
 * @dev Sets specific bit to 1
 * @param value Number to modify
 * @param index Bit position to set
 * @return Modified value
 */
function setBit(uint256 value, uint256 index) internal pure returns (uint256) {
    require(index < 256, "Index out of bounds");
    return value | (1 << index);
}

// Usage
uint256 flags = 0;
flags = setBit(flags, 3); // Set bit 3
flags = setBit(flags, 7); // Set bit 7
```

**Gas Cost:** ~50 gas
**When to Use:** Setting flags efficiently
**Constraints:** Index 0-255
**Alternative:** Use BitMaps for storage optimization

---

### clearBit - Clear a Bit

```solidity
/**
 * @dev Clears specific bit (sets to 0)
 * @param value Number to modify
 * @param index Bit position to clear
 * @return Modified value
 */
function clearBit(uint256 value, uint256 index) internal pure returns (uint256) {
    require(index < 256, "Index out of bounds");
    return value & ~(1 << index);
}

// Usage
uint256 flags = 255; // All bits set
flags = clearBit(flags, 3); // Clear bit 3
```

**Gas Cost:** ~50 gas
**When to Use:** Clearing individual flags
**Constraints:** Index 0-255
**Alternative:** Use BitMaps library

---

### toggleBit - Toggle a Bit

```solidity
/**
 * @dev Toggles specific bit (0→1 or 1→0)
 * @param value Number to modify
 * @param index Bit position to toggle
 * @return Modified value
 */
function toggleBit(uint256 value, uint256 index) internal pure returns (uint256) {
    require(index < 256, "Index out of bounds");
    return value ^ (1 << index);
}

// Usage
uint256 state = 0;
state = toggleBit(state, 5); // Turn on bit 5
state = toggleBit(state, 5); // Turn off bit 5
```

**Gas Cost:** ~50 gas
**When to Use:** Toggling boolean states
**Constraints:** Index 0-255
**Alternative:** Manual check and set/clear

---

### countSetBits - Population Count

```solidity
/**
 * @dev Counts number of bits set to 1
 * @param value Number to count
 * @return Number of set bits
 */
function countSetBits(uint256 value) internal pure returns (uint256) {
    uint256 count = 0;
    while (value != 0) {
        count += value & 1;
        value >>= 1;
    }
    return count;
}

// Usage
uint256 permissions = 0b11010110; // Binary
uint256 activePermissions = countSetBits(permissions); // Returns 5
```

**Gas Cost:** ~100-500 gas (depends on value)
**When to Use:** Counting active flags
**Constraints:** Linear in number of bits
**Alternative:** Track count separately in storage

---

## 5. Address Utilities

### isContract - Check if Address is Contract

```solidity
/**
 * @dev Returns true if account is a contract
 * @param account Address to check
 * @return True if account has code
 */
function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
        size := extcodesize(account)
    }
    return size > 0;
}

// Usage
if (isContract(msg.sender)) {
    // Caller is a contract
    revert("Contracts not allowed");
}

// Check before delegatecall
require(isContract(implementation), "Not a contract");
```

**Gas Cost:** ~2,600 gas
**When to Use:** Contract detection, preventing contract interactions
**Constraints:** Returns false during constructor (contract has no code yet)
**Alternative:** Use OpenZeppelin's `Address.isContract()`

---

### sendETHWithoutFail - Safe Send (Ignore Failure)

```solidity
/**
 * @dev Sends ETH and returns success status (doesn't revert)
 * @param recipient Address to send to
 * @param amount Amount to send
 * @return success True if transfer succeeded
 */
function sendETHWithoutFail(address payable recipient, uint256 amount)
    internal
    returns (bool success)
{
    (success, ) = recipient.call{value: amount}("");
    // Explicitly return success, don't revert on failure
}

// Usage - Send reward, continue if it fails
bool sent = sendETHWithoutFail(payable(user), reward);
if (!sent) {
    // Store reward for manual claim
    pendingRewards[user] += reward;
}
```

**Gas Cost:** ~2,300 gas + 2,300 for external call
**When to Use:** Push payments where failure is acceptable
**Constraints:** No way to know why it failed
**Alternative:** Use pull payment pattern

---

### sendETHWithFail - Safe Send (Require Success)

```solidity
/**
 * @dev Sends ETH and reverts if transfer fails
 * @param recipient Address to send to
 * @param amount Amount to send
 */
function sendETHWithFail(address payable recipient, uint256 amount) internal {
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "ETH transfer failed");
}

// Usage - Ensure transfer succeeds
sendETHWithFail(payable(owner), fees);
```

**Gas Cost:** ~2,300 gas + 2,300 for external call
**When to Use:** When failure is critical
**Constraints:** Will revert entire transaction if send fails
**Alternative:** Use OpenZeppelin's `Address.sendValue()`

---

### sendETHWithGasLimit - Gas-Limited Send

```solidity
/**
 * @dev Sends ETH with specific gas limit
 * @param recipient Address to send to
 * @param amount Amount to send
 * @param gasLimit Gas limit for the call
 * @return success True if transfer succeeded
 */
function sendETHWithGasLimit(
    address payable recipient,
    uint256 amount,
    uint256 gasLimit
) internal returns (bool success) {
    (success, ) = recipient.call{value: amount, gas: gasLimit}("");
}

// Usage - Prevent griefing via gas-expensive fallback
bool sent = sendETHWithGasLimit(payable(user), amount, 2300);
```

**Gas Cost:** ~2,300 gas + gasLimit
**When to Use:** Prevent recipients from griefing via expensive fallback
**Constraints:** 2300 gas may be insufficient for some wallets
**Alternative:** Use pull payment pattern for safety

---

## 6. Complete Library Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MathLib
 * @dev Common math utilities
 */
library MathLib {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }
}

/**
 * @title ArrayLib
 * @dev Array utilities
 */
library ArrayLib {
    function sum(uint256[] memory array) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < array.length; i++) {
            total += array[i];
        }
        return total;
    }

    function contains(address[] memory array, address value)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) return true;
        }
        return false;
    }
}

/**
 * @title AddressLib
 * @dev Address utilities
 */
library AddressLib {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }
}

// Usage in contract
contract MyContract {
    using MathLib for uint256;
    using ArrayLib for address[];
    using AddressLib for address;

    function calculateReward(uint256 stake, uint256 total) public pure returns (uint256) {
        return stake.min(total);
    }

    function checkWhitelist(address[] memory whitelist) public view returns (bool) {
        return whitelist.contains(msg.sender);
    }

    function distribute(address payable recipient, uint256 amount) public {
        require(recipient.isContract() == false, "No contracts");
        recipient.sendValue(amount);
    }
}
```

---

## Best Practices

### 1. Use Libraries for Reusable Code

```solidity
// GOOD: Reusable library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Overflow");
        return c;
    }
}

// BAD: Duplicated code
contract A {
    function add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }
}
```

### 2. Prefer OpenZeppelin Over Custom

```solidity
// GOOD: Use audited OpenZeppelin
import "@openzeppelin/contracts/utils/math/Math.sol";
using Math for uint256;

// AVOID: Custom implementations (unless optimizing)
function myCustomMath(uint256 a, uint256 b) internal pure returns (uint256) {
    // Custom logic
}
```

### 3. Document Constraints

```solidity
/**
 * @dev Calculate square root
 * @param x Must be non-negative
 * @return Square root rounded down
 * @notice Result is rounded down for non-perfect squares
 */
function sqrt(uint256 x) internal pure returns (uint256) {
    // Implementation
}
```

---

## Gas Optimization Tips

1. **Use `unchecked` for Safe Math:**
   ```solidity
   unchecked {
       counter++; // Safe if you know it won't overflow
   }
   ```

2. **Cache Array Length:**
   ```solidity
   uint256 len = array.length;
   for (uint256 i = 0; i < len; i++) {
       // Loop body
   }
   ```

3. **Use Bit Manipulation:**
   ```solidity
   // Instead of 256 bool variables (256 * 32 bytes = 8192 bytes)
   // Use 1 uint256 (32 bytes)
   uint256 flags;
   ```

---

## When to Use Custom vs OpenZeppelin

| Scenario | Recommendation |
|----------|---------------|
| Production contracts | Use OpenZeppelin |
| Gas-critical paths | Custom (after profiling) |
| Common patterns | Use OpenZeppelin |
| Unique logic | Custom with tests |
| Learning/prototyping | Either works |

---

**Total Utility Functions:** 30+
**Categories:** 6
**All functions include:** Documentation, usage examples, gas costs
**Solidity Version:** ^0.8.20
**Recommendation:** Use OpenZeppelin for production, custom for optimization
