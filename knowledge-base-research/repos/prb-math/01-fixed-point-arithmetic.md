# PRB Math: Fixed-Point Arithmetic Library

> Gas-efficient fixed-point math for Solidity with type safety and advanced functions

**Repo:** https://github.com/PaulRBerg/prb-math.git
**Purpose:** Advanced mathematical operations on fixed-point numbers with 18-decimal precision
**Key Strength:** Type-safe via user-defined value types, overflow-safe via mulDiv, intuitive API

---

## Core Concepts

### Fixed-Point Number Formats

**UD60x18 (Unsigned)** - 60 digits integer + 18 decimals
```
Range: 0 to 2^256 - 1
Decimal representation: x / 1e18
Example: UD60x18(1e18) = 1.0
```

**SD59x18 (Signed)** - 59 digits integer + 18 decimals
```
Range: -(2^255) to 2^255 - 1
Decimal representation: x / 1e18
Example: SD59x18(1e18) = 1.0, SD59x18(-1e18) = -1.0
```

### Type Safety via User-Defined Value Types

```solidity
// Before: Easy to confuse uint256 with different scales
uint256 price = 1e18;  // Is this 1 USD or 1 WEI?

// With PRBMath: Explicit type
import { UD60x18, wrap } from "@prb/math/src/UD60x18.sol";

UD60x18 price = wrap(1e18);  // Clearly represents 1.0
```

---

## Critical Functions

### 1. mul() / div() - Safe Arithmetic

**Problem:** Integer multiplication can overflow

```solidity
// Dangerous - overflows silently
uint256 result = (a * b) / 1e18;

// Safe - checks before multiplying
result = PRBMath.mul(a, b);  // Uses mulDiv internally
```

**Implementation:** `mulDiv(x, y, denominator)` prevents overflow by:
1. Computing full 512-bit product of x × y
2. Dividing by denominator in one operation
3. Returning 256-bit result

**Source:** `src/ud60x18/Math.sol` and `src/sd59x18/Math.sol`

### 2. exp() / ln() - Exponentials & Logarithms

```solidity
// e^x (natural exponential)
UD60x18 result = exp(x);

// ln(x) (natural logarithm)
UD60x18 logResult = ln(x);

// 2^x (power of 2)
UD60x18 powResult = exp2(x);

// log10(x)
UD60x18 log10Result = log10(x);
```

**Use Cases:**
- Compound interest: `balance = principal × exp(rate × time)`
- Volatility calculations: `sigma = ln(price_new / price_old)`
- Geometric mean: `geomMean = exp((ln(a) + ln(b)) / 2)`

**Source:** `src/ud60x18/Math.sol:200-400`

### 3. pow() - Arbitrary Powers

```solidity
// x^y (x raised to power y)
UD60x18 result = pow(base, exponent);

// Example: staking APY
// 1 year APY = base^(1 year in seconds)
```

**Implementation:** Uses logarithmic approach: `x^y = e^(y × ln(x))`

### 4. sqrt() - Square Root

```solidity
// Square root
UD60x18 sqrtVal = sqrt(x);

// Circular area: A = pi * r^2, so r = sqrt(A / pi)
```

---

## Integration with Solidity Types

### Converting to/from uint256

```solidity
import { UD60x18, wrap, unwrap } from "@prb/math/src/UD60x18.sol";

// uint256 → UD60x18 (wrap)
uint256 rawValue = 5e18;
UD60x18 fixedValue = wrap(rawValue);

// UD60x18 → uint256 (unwrap)
uint256 backToUint = unwrap(fixedValue);
```

### Casting Between Formats

```solidity
import { UD60x18, SD59x18 } from "@prb/math/src/";
import { toSD59x18 } from "@prb/math/src/UD60x18.sol";
import { toUD60x18 } from "@prb/math/src/SD59x18.sol";

UD60x18 positive = wrap(5e18);
SD59x18 signed = toSD59x18(positive);

SD59x18 negative = wrap(-3e18);
// UD60x18 unsigned = toUD60x18(negative);  // ❌ Would panic on negative
```

---

## Architecture

### File Structure

```
src/
├── SD59x18.sol (and SD1x18.sol)     ← Signed types
├── UD60x18.sol (and UD21x18.sol)    ← Unsigned types
├── sd59x18/
│   ├── Math.sol                      ← exp, ln, pow, sqrt, etc.
│   ├── Casting.sol                   ← Type conversions
│   ├── Constants.sol                 ← E, PI, LN2, etc.
│   ├── Conversions.sol               ← to/from int, uint
│   ├── Errors.sol                    ← Custom errors
│   ├── Helpers.sol                   ← avg, ceil, floor, etc.
│   └── ValueType.sol                 ← User-defined value type
├── ud60x18/                          ← Same structure for unsigned
└── Common.sol                        ← Shared utilities
```

---

## Key Implementation Details

### mul() Safety

**Source:** `src/Common.sol`

```
Problem: a * b can overflow uint256
Solution: Use 512-bit intermediate (via assembly) then divide

Algorithm:
1. Compute prod0 = (a * b) % 2^256  (lower 256 bits)
2. Compute prod1 = (a * b) / 2^256  (upper 256 bits)
3. If prod1 == 0: return prod0 / denominator
4. If prod1 > 0: check denominator > prod1, then compute result
```

### exp() Implementation

**Source:** `src/ud60x18/Math.sol:200-250`

Uses Taylor series expansion for e^x:
```
e^x = 1 + x + x²/2! + x³/3! + ...
```

With optimization for common cases and overflow checks:
- `uEXP_MAX_INPUT` = ~133 (prevents overflow at e^133)
- Returns zero if input too large
- Maintains precision using fixed-point arithmetic

### ln() Implementation

**Source:** `src/ud60x18/Math.sol:300-350`

Uses bit-by-bit algorithm similar to Newton's method:
```
If x < 1: ln(x) = -ln(1/x)
If x ≥ 1: uses optimization + polynomial approximation
```

---

## When to Use PRBMath vs Alternatives

| Library | Format | Gas Cost | Type Safety | Best For |
|---------|--------|----------|-------------|----------|
| **PRBMath** | Decimal (59.18 / 60.18) | Medium | ✅ Yes (UDT) | Intuitive, financial math |
| **Solmate** | Decimal (18-decimal WAD) | Low | ❌ No | Gas-optimized, simple |
| **ABDKMath** | Binary (64x64) | Very Low | ❌ No | Extreme gas efficiency |

**Use PRBMath when:**
- Intuitive decimal-based math is important
- Type safety reduces bugs
- Complex functions (exp, ln, pow) are needed
- Gas cost is secondary to correctness

---

## Constants Provided

```solidity
UD60x18.ZERO = 0
UD60x18.UNIT = 1e18  // Represents 1.0

// Mathematical constants
E = ~2.71828 (in fixed-point)
PI = ~3.14159
LN2 = ~0.69314
LOG2_10 = ~3.32192
LOG2_E = ~1.44269
```

**Source:** `src/ud60x18/Constants.sol`

---

## Gas Optimization Notes

- **User-defined value types:** Zero runtime overhead (compile-time only)
- **Free functions:** No library call overhead
- **mulDiv:** Optimized in assembly, gas-efficient despite overflow checking
- **Tradeoff:** Complex functions (exp, pow) cost more gas than simple mul/div

---

## Common Integration Pattern

```solidity
import { UD60x18, wrap, unwrap } from "@prb/math/src/UD60x18.sol";
import { mul, div, exp, ln } from "@prb/math/src/ud60x18/Math.sol";

contract YieldCalculator {
    function compoundInterest(
        uint256 principal,
        uint256 annualRateWad,  // 18-decimal (0.05e18 = 5%)
        uint256 years
    ) external pure returns (uint256) {
        UD60x18 p = wrap(principal);
        UD60x18 r = wrap(annualRateWad);
        UD60x18 t = wrap(years * 1e18);

        // A = P * e^(r*t)
        UD60x18 exponent = mul(r, t);
        UD60x18 result = mul(p, exp(exponent));

        return unwrap(result);
    }
}
```

---

## Error Handling

```solidity
import { Errors as UD60x18Errors } from "@prb/math/src/ud60x18/Errors.sol";

// Custom errors (no reason strings - gas efficient)
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);
error PRBMath_UD60x18_Pow_Overflow(UD60x18 x, UD60x18 y);
```

---

## When NOT to Use

- **Pure integer math:** Use Solidity's native `* / +` operators
- **Extreme gas optimization:** Use Solmate or assembly math
- **Binary fixed-point:** Use ABDKMath64x64
- **Approximate results acceptable:** Consider lookup tables

---

**Status:** Ready to integrate with smart contracts requiring advanced mathematical operations
**Install:** `npm install @prb/math` + add to remappings.txt
