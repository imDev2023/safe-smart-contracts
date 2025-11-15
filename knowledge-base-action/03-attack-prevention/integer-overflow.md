# Integer Overflow and Underflow

## What It Is
Integer overflow occurs when an arithmetic operation exceeds the maximum value a variable type can store, causing it to wrap around to the minimum value. Integer underflow is the opposite: subtracting below the minimum value wraps to the maximum. These vulnerabilities can lead to incorrect balances, bypassed checks, and catastrophic token supply manipulation.

## Why It Matters
Integer overflow/underflow attacks have caused some of the largest losses in cryptocurrency history. The BeautyChain (BEC) token overflow led to a market cap loss of over $900 million in April 2018. SmartMesh (SMT) suffered a similar attack the same week. While Solidity 0.8.0+ introduced automatic overflow protection, edge cases still exist through typecasting, shift operations, unchecked blocks, and inline assembly. Understanding these vulnerabilities remains critical.

## Vulnerable Code Example

### Example 1: Classic Overflow (Pre-0.8.0)

```solidity
// INSECURE - Solidity < 0.8.0
pragma solidity ^0.7.0;

contract VulnerableToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    function transfer(address to, uint256 amount) public {
        // VULNERABILITY: No overflow protection
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;  // Potential underflow
        balances[to] += amount;          // Potential overflow
    }

    function batchTransfer(address[] memory recipients, uint256 amount) public {
        // VULNERABILITY: Multiplication overflow
        uint256 totalAmount = recipients.length * amount;
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amount;
        }
        balances[msg.sender] -= totalAmount;
    }
}
```

### Example 2: Solidity 0.8+ Edge Cases

```solidity
// INSECURE - Even with Solidity 0.8.0+
pragma solidity ^0.8.0;

contract ModernVulnerabilities {
    function typecastOverflow() public pure returns (uint8) {
        uint256 largeNumber = 257;
        // VULNERABILITY: Downcasting doesn't revert
        uint8 smallNumber = uint8(largeNumber);  // Returns 1, not 257!
        return smallNumber;
    }

    function shiftOperatorOverflow() public pure returns (uint8) {
        uint8 value = 200;
        // VULNERABILITY: Shift operations don't check overflow
        uint8 result = value << 2;  // 800 overflows to 32
        return result;
    }

    function uncheckedBlockVulnerability() public pure returns (uint256) {
        uint256 value = type(uint256).max;
        // VULNERABILITY: Unchecked blocks bypass overflow protection
        unchecked {
            value += 1;  // Overflows to 0 without reverting
        }
        return value;
    }

    function assemblyOverflow() public pure returns (uint8) {
        uint8 value = 255;
        // VULNERABILITY: Assembly bypasses overflow checks
        assembly {
            value := add(value, 1)  // Overflows to 0
        }
        return value;
    }
}
```

## The Attack Scenario

**BeautyChain (BEC) Attack Breakdown:**

1. **Initial Setup**: BEC token deployed without SafeMath
2. **Vulnerability Discovery**: Attacker finds `batchTransfer` overflow
3. **Exploitation Setup**: Create array with 2 addresses
4. **Overflow Trigger**: Call `batchTransfer` with amount = `2^255`
5. **Arithmetic Overflow**: `2 * 2^255 = 2^256 = 0` (wraps to zero)
6. **Check Bypass**: `require(balance >= 0)` passes
7. **Token Creation**: Each recipient gets `2^255` tokens
8. **Market Dump**: Attacker sells massive amount
9. **Total Collapse**: Token value crashes to zero

**Numerical Example:**
```
Initial State:
- Attacker balance: 100 BEC tokens
- Recipients: [0xABCD, 0x1234]
- Amount per recipient: 57,896,044,618,658,097,711,785,492,504,343,953,926,634,992,332,820,282,019,728,792,003,956,564,819,968
  (This is 2^255 in decimal)

Attack Execution:
1. Call: batchTransfer([0xABCD, 0x1234], 2^255)
2. Calculate: totalAmount = 2 * 2^255
3. Overflow: 2^256 wraps to 0
4. Check: require(100 >= 0) ✓ PASSES
5. Transfer: Each recipient gets 2^255 tokens
6. Attacker balance: 100 - 0 = 100 (unchanged!)

Result:
- Attacker still has 100 tokens
- Created 2^256 tokens from nothing
- Total supply became astronomical
- Token value → $0
- Market cap loss: $900M+
```

## Prevention Methods

### Method 1: Use Solidity 0.8.0+

Solidity 0.8.0 introduced automatic overflow/underflow checks.

```solidity
pragma solidity ^0.8.0;

contract SafeByDefault {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        // Automatically reverts on overflow/underflow
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;  // Safe: reverts on underflow
        balances[to] += amount;          // Safe: reverts on overflow
    }

    function multiplyCheck(uint256 a, uint256 b) public pure returns (uint256) {
        // Automatically reverts on overflow
        return a * b;
    }
}
```

**Gas Cost**: ~20-40 gas overhead per arithmetic operation
**Pros**: Automatic protection, no extra code needed
**Cons**: Small gas overhead, doesn't protect edge cases

### Method 2: SafeMath Library (Legacy < 0.8.0)

For older Solidity versions, use OpenZeppelin's SafeMath.

```solidity
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LegacySafeToken {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(amount);  // Safe subtraction
        balances[to] = balances[to].add(amount);                   // Safe addition
    }

    function batchTransfer(address[] memory recipients, uint256 amount) public {
        // Safe multiplication prevents overflow
        uint256 totalAmount = recipients.length.mul(amount);
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(totalAmount);

        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] = balances[recipients[i]].add(amount);
        }
    }
}
```

**Gas Cost**: ~200 gas overhead per operation
**Pros**: Comprehensive protection for old Solidity, battle-tested
**Cons**: Higher gas costs, verbose syntax, unnecessary in 0.8+

### Method 3: Safe Casting with OpenZeppelin

Protect against downcasting overflows in Solidity 0.8+.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract SafeCastExample {
    using SafeCast for uint256;

    function safeCastToUint8(uint256 value) public pure returns (uint8) {
        // Reverts if value > 255
        return value.toUint8();
    }

    function safeCastToUint128(uint256 value) public pure returns (uint128) {
        // Reverts if value > type(uint128).max
        return value.toUint128();
    }

    function processLargeToSmall(uint256 largeValue) public pure returns (uint8) {
        // SECURE: Explicitly check and revert
        require(largeValue <= type(uint8).max, "Value too large for uint8");
        return uint8(largeValue);
    }
}
```

**Gas Cost**: ~100-200 gas per safe cast
**Pros**: Explicit protection for dangerous casts
**Cons**: Requires manual application

### Method 4: Careful Use of Unchecked Blocks

Only use `unchecked` when overflow is mathematically impossible.

```solidity
pragma solidity ^0.8.0;

contract UncheckedSafe {
    function safeUncheckedExample(uint256[] memory values) public pure returns (uint256) {
        uint256 sum = 0;

        for (uint256 i = 0; i < values.length;) {
            // Regular checked addition
            sum += values[i];

            // SAFE: i can never overflow in realistic array sizes
            unchecked {
                ++i;  // Gas optimization
            }
        }

        return sum;
    }

    function calculateFee(uint256 amount, uint256 feePercent) public pure returns (uint256) {
        require(feePercent <= 100, "Invalid fee percent");

        // Safe: multiply first, then divide (fee <= amount)
        uint256 fee = (amount * feePercent) / 100;

        // SAFE: amount - fee can never underflow because fee <= amount
        unchecked {
            return amount - fee;
        }
    }

    // DANGEROUS: Don't do this
    function dangerousUnchecked(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            return a + b;  // Can overflow silently!
        }
    }
}
```

**Gas Cost**: Saves ~20-40 gas per operation in unchecked
**Pros**: Gas optimization when safe
**Cons**: Requires mathematical proof of safety, dangerous if misused

## Edge Cases and Modern Vulnerabilities

### 1. Downcasting Overflow

```solidity
pragma solidity ^0.8.0;

contract DowncastVulnerability {
    // INSECURE
    function processAge(uint256 userAge) public pure returns (uint8) {
        return uint8(userAge);  // 300 becomes 44 (300 - 256)
    }

    // SECURE
    function processAgeSafe(uint256 userAge) public pure returns (uint8) {
        require(userAge <= type(uint8).max, "Age too large");
        return uint8(userAge);
    }
}
```

### 2. Shift Operations

```solidity
pragma solidity ^0.8.0;

contract ShiftVulnerability {
    // INSECURE
    function leftShiftOverflow(uint8 value, uint8 shift) public pure returns (uint8) {
        return value << shift;  // No overflow check
    }

    // SECURE
    function leftShiftSafe(uint256 value, uint256 shift) public pure returns (uint256) {
        uint256 result = value << shift;
        require(result >> shift == value, "Shift overflow");
        return result;
    }
}
```

### 3. Assembly Usage

```solidity
pragma solidity ^0.8.0;

contract AssemblyVulnerability {
    // INSECURE
    function addUnsafe(uint256 a, uint256 b) public pure returns (uint256 result) {
        assembly {
            result := add(a, b)  // No overflow check
        }
    }

    // SECURE - Avoid assembly for arithmetic, or add checks
    function addSafe(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;  // Use Solidity's built-in checks
    }
}
```

## Real-World Examples

| Incident | Date | Amount Lost | Vulnerability Type |
|----------|------|-------------|-------------------|
| **BeautyChain (BEC)** | Apr 2018 | $900M+ market cap | batchTransfer overflow |
| **SmartMesh (SMT)** | Apr 2018 | Market crashed | Similar batchTransfer bug |
| **PoWHC** | Jul 2018 | 866 ETH | Underflow in sell function |
| **Hexagon** | Jun 2018 | Unknown | Overflow in token minting |
| **DAO Maker** | Dec 2021 | $4M | Underflow in vesting |

**BeautyChain Deep Dive:**
```solidity
// Actual vulnerable code from BEC token
function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
    uint cnt = _receivers.length;
    uint256 amount = uint256(cnt) * _value;  // OVERFLOW HERE
    require(cnt > 0 && cnt <= 20);
    require(_value > 0 && balances[msg.sender] >= amount);

    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (uint i = 0; i < cnt; i++) {
        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
}

// Attack transaction:
// _receivers = [0x..., 0x...]  (2 addresses)
// _value = 0x8000000000000000000000000000000000000000000000000000000000000000
// Result: amount = 2 * 2^255 = 0 (overflow)
```

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract OverflowTest is Test {
    ModernVulnerabilities public vuln;
    SafeCastExample public safe;

    function setUp() public {
        vuln = new ModernVulnerabilities();
        safe = new SafeCastExample();
    }

    function testTypecastOverflow() public {
        // uint256(257) cast to uint8 = 1
        uint8 result = vuln.typecastOverflow();
        assertEq(result, 1);
        console.log("Typecast overflow: 257 -> ", result);
    }

    function testShiftOverflow() public {
        // 200 << 2 = 800, but uint8 max is 255
        uint8 result = vuln.shiftOperatorOverflow();
        assertEq(result, 32);  // 800 - 768 = 32
        console.log("Shift overflow: 200 << 2 = ", result);
    }

    function testUncheckedOverflow() public {
        uint256 result = vuln.uncheckedBlockVulnerability();
        assertEq(result, 0);  // Wrapped to 0
        console.log("Unchecked overflow: max + 1 = ", result);
    }

    function testSafeCastProtection() public {
        // Should revert on overflow
        vm.expectRevert();
        safe.safeCastToUint8(300);

        // Should succeed
        uint8 result = safe.safeCastToUint8(200);
        assertEq(result, 200);
    }

    function testBuiltInProtection() public {
        // Test automatic overflow protection in 0.8+
        uint256 maxValue = type(uint256).max;

        vm.expectRevert();
        this.overflowAdd(maxValue, 1);
    }

    function overflowAdd(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function testBatchTransferVulnerability() public {
        // Simulate BEC attack
        VulnerableToken token = new VulnerableToken();

        address[] memory recipients = new address[](2);
        recipients[0] = address(0x1);
        recipients[1] = address(0x2);

        // This would overflow in Solidity < 0.8.0
        // In 0.8+, it should revert
        vm.expectRevert();
        token.batchTransfer(recipients, type(uint256).max / 2 + 1);
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Integer Overflow Tests", function () {
  it("Should demonstrate typecast overflow", async function () {
    const ModernVuln = await ethers.getContractFactory("ModernVulnerabilities");
    const vuln = await ModernVuln.deploy();

    const result = await vuln.typecastOverflow();
    expect(result).to.equal(1); // 257 -> 1
    console.log("Typecast overflow: 257 becomes", result.toString());
  });

  it("Should test safe cast protection", async function () {
    const SafeCast = await ethers.getContractFactory("SafeCastExample");
    const safe = await SafeCast.deploy();

    // Should revert on large value
    await expect(safe.safeCastToUint8(300)).to.be.reverted;

    // Should succeed on valid value
    const result = await safe.safeCastToUint8(200);
    expect(result).to.equal(200);
  });

  it("Should test built-in overflow protection", async function () {
    const SafeByDefault = await ethers.getContractFactory("SafeByDefault");
    const contract = await SafeByDefault.deploy();

    const maxUint = ethers.MaxUint256;

    // Should revert on overflow
    await expect(contract.multiplyCheck(maxUint, 2)).to.be.reverted;
  });

  it("Should test unchecked block", async function () {
    const UncheckedSafe = await ethers.getContractFactory("UncheckedSafe");
    const contract = await UncheckedSafe.deploy();

    const values = [100, 200, 300];
    const sum = await contract.safeUncheckedExample(values);
    expect(sum).to.equal(600);
  });
});
```

### Fuzzing with Echidna

```solidity
contract OverflowEchidnaTest {
    SafeByDefault target;

    constructor() {
        target = new SafeByDefault();
    }

    function echidna_no_overflow() public returns (bool) {
        // Echidna will try to find inputs that cause overflow
        try target.multiplyCheck(uint256(msg.sender), block.timestamp) {
            return true;
        } catch {
            return true; // Expected to revert on overflow
        }
    }
}
```

## Checklist

- [ ] Using Solidity 0.8.0 or higher
- [ ] SafeMath removed from 0.8+ code (not needed)
- [ ] All typecasts checked or use SafeCast
- [ ] Shift operations reviewed for overflow
- [ ] Unchecked blocks only used when mathematically safe
- [ ] Assembly arithmetic avoided or carefully reviewed
- [ ] External libraries use safe arithmetic
- [ ] Multiplication done before division to avoid precision loss
- [ ] Unit tests cover edge cases (max values, zero, etc.)
- [ ] Fuzz testing implemented
- [ ] Static analysis run (Slither, Mythril)
- [ ] Integer types appropriately sized (not too small)
- [ ] Downcasting protected
- [ ] Code audited for arithmetic operations

## Additional Resources

**Documentation:**
- [Solidity 0.8.0 Breaking Changes](https://docs.soliditylang.org/en/latest/080-breaking-changes.html)
- [OpenZeppelin SafeMath](https://docs.openzeppelin.com/contracts/4.x/api/utils#SafeMath)
- [OpenZeppelin SafeCast](https://docs.openzeppelin.com/contracts/4.x/api/utils#SafeCast)

**Security Guides:**
- [SWC-101: Integer Overflow/Underflow](https://swcregistry.io/docs/SWC-101)
- [BeautyChain Post-Mortem](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e)

**Tools:**
- [Slither Integer Overflow Detector](https://github.com/crytic/slither)
- [Echidna Fuzzer](https://github.com/crytic/echidna)
- [Manticore Symbolic Execution](https://github.com/trailofbits/manticore)

---

**Last Updated**: November 2025
**Severity**: Critical (Pre-0.8.0), High (0.8+ edge cases)
**OWASP Category**: [A3: Arithmetic Issues](https://owasp.org/www-project-smart-contract-top-10/)
