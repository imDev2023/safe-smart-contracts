# WTFAcademy/WTF-gas-optimization - Master Summary

## Repository Overview
- **Repository**: WTFAcademy/WTF-gas-optimization
- **URL**: https://github.com/WTFAcademy/WTF-gas-optimization
- **Description**: Solidity gas optimization techniques, verified with Foundry
- **Stars**: 221+
- **Type**: Practical examples with verified gas measurements
- **Language**: English & Chinese (中文)

## Repository Structure
```
wtf-academy/
├── README.md                           # Main documentation
├── examples/                           # Example contracts collected
│   ├── 01_Constant.sol                # Constant vs immutable vs variable
│   ├── 03_Bitmap.sol                  # Bitmap vs bool array
│   ├── 04_Unchecked.sol               # Unchecked arithmetic
│   └── 09_Packing.sol                 # Storage slot packing
├── 01_Constant/                       # Full example with tests (on GitHub)
├── 02_CalldataAndMemory/              # Full example with tests
├── 03_Bitmap/                         # Full example with tests
├── ... (24 total directories)
└── MASTER_SUMMARY.md                  # This file
```

## Content Summary

### Files Collected
- **Total Files**: 5 (locally saved)
  - 1 README.md (main documentation)
  - 4 Example Solidity contracts
  - **Note**: Full repository has 24 optimization techniques with complete test suites

### 24 Gas Optimization Techniques (All Verified with Foundry)

#### 1. Use Constant and Immutable
- **varConstant**: 161 gas ✅
- **varImmutable**: 161 gas ✅
- variable: 2,261 gas
- **Savings**: 92.9%

#### 2. Use Calldata Over Memory
- **writeByCalldata**: 67,905 gas ✅
- writeByMemory: 68,456 gas
- **Savings**: 0.8%

#### 3. Use Bitmap
- **setDataWithBitmap**: 22,366 gas ✅
- setDataWithBoolArray: 35,729 gas
- **Savings**: 37.4%

#### 4. Use Unchecked
- **forUnchecked**: 570,287 gas ✅
- forNormal: 1,910,309 gas
- **Savings**: 70.1%

#### 5. Use uint256 Over uint8
- **read Uint256**: 2,261 gas ✅
- read Uint8/32: 2,301 gas
- **UseUint256**: 42,950 gas ✅
- UseUint8: 53,427 gas
- **Savings**: 19.6% (in loops)

#### 6. Use Custom Error Over Require/Assert
- **Revert (custom error)**: 164 gas ✅
- Assert: 180 gas
- Require: 268 gas
- **Savings**: 38.8% vs require

#### 7. Use Local Variable Over Storage
- **localData**: 1,902,339 gas ✅
- storageData: 4,022,155 gas
- **Savings**: 52.7%

#### 8. Use Clone Over New/Create2
- **clone**: 41,493 gas ✅
- new: 79,515 gas
- create2: 93,031 gas
- **Savings**: 47.8% vs new

#### 9. Packing Storage Slots
- **packing**: 111,351 gas ✅
- normal: 133,521 gas
- **Savings**: 16.6%

#### 10. Use ++i as Better Increment
- **++i**: 193 gas ✅
- i++: 198 gas
- i += 1: 204 gas
- i = i + 1: 204 gas
- **Savings**: 5.4%

#### 11. Use Uint in Reentrancy Guard
- **Uint12** (non-zero to non-zero): 13,908 gas ✅
- Uint01 (0 to non-zero): 27,604 gas
- Bool: 27,757 gas
- **Savings**: 49.9%

#### 12. Use < Over <=
- **<**: 247 gas ✅
- <=: 250 gas
- **Savings**: 1.2%

#### 13. Optimized Selector/Method ID
- **optimized selector** (0x000073eb): 5,265 gas ✅
- regular selector (0xf8a8fd6d): 5,285 gas
- **Savings**: 0.4%

#### 14. Selector/Method-ID Order Matters
- **test_y2K** (0x000073eb): 98 gas ✅
- test3 (0x0a8e8e01): 120 gas
- test2 (0x66e41cb7): 142 gas
- test1 (0x0dbe671f): 164 gas
- **Savings**: 40.2% (first vs last)

#### 15. Use Shorter String in require()
- **shortString**: 2,347 gas ✅
- longString: 2,578 gas
- **Savings**: 9.0%

#### 16. Short Circuit in Logic Operation
- **shortCircuit**: 120 gas ✅
- normal: 191,282 gas
- **Savings**: 99.9%

#### 17. Delete Variables to Get Gas Refund
- **updateDelete**: 2,316 gas ✅
- **updateDefault**: 2,360 gas ✅
- update: 22,238 gas
- **Savings**: 89.6%

#### 18. Do Not Initialize State Variables with Default Values
- **testDefault**: 67,148 gas ✅
- testInitDefault: 69,376 gas
- **Savings**: 3.2%

#### 19. Swap 2 Variables in 1 Line
- **desSwap**: 282 gas
- swap: 282 gas
- **Savings**: 0% (but cleaner code)

#### 20. Set Constructor to Payable
- **payable constructor**: 67,102 gas ✅
- default: 67,171 gas
- **Savings**: 0.1% (10 opcodes removed)

#### 21. Use bytes32 for Short String
- **setBytes32**: 22,222 gas ✅
- setString: 22,682 gas
- **Savings**: 2.0%

#### 22. Use Fixed-Size Array Over Dynamic Array
- **set fixed-length array**: 2,182,608 gas ✅
- set dynamic-length array: 2,224,770 gas
- **Savings**: 1.9%

#### 23. Use Event to Store Data When Possible
- **useEvent**: 1,189 gas ✅
- useVar: 22,216 gas
- **Savings**: 94.6%

#### 24. Use Mapping Over Array When Possible
- **Mapping get**: 451 gas ✅
- Array get: 710 gas (57.5% savings)
- **Mapping insert**: 22,385 gas ✅
- Array insert: 44,442 gas (49.6% savings)
- **Mapping remove**: 305 gas ✅
- Array remove: 748 gas (59.2% savings)

## Example Contracts (Saved Locally)

### 1. Constant.sol
```solidity
contract Constant {
    uint256 public constant varConstant = 1000;  // 161 gas
}
contract Immutable {
    uint256 public immutable varImmutable = 1000;  // 161 gas
}
contract Public {
    uint256 public variable = 1000;  // 2,261 gas
}
```

### 2. Bitmap.sol
Demonstrates using uint8 bitmap instead of bool[8] array
- **Gas savings**: 37.4% (22,366 vs 35,729 gas)

### 3. Unchecked.sol
Shows unchecked arithmetic in loops
- **Gas savings**: 70.1% (570,287 vs 1,910,309 gas for 10,000 iterations)

### 4. Packing.sol
Demonstrates storage slot packing optimization
- **Gas savings**: 16.6% (111,351 vs 133,521 gas)

## Testing Methodology
All techniques verified using Foundry:
```bash
forge test --contracts [technique]/[Contract].t.sol --gas-report
```

## Gas Savings Summary
- **Highest Savings**: Short circuit (99.9%), Event storage (94.6%), Constant/Immutable (92.9%)
- **Medium Savings**: Unchecked loops (70.1%), Local variables (52.7%), Clone deployment (47.8%)
- **Small but Meaningful**: Packing (16.6%), ++i (5.4%), Shorter requires (9.0%)
- **Minor Optimizations**: bytes32 strings (2.0%), < vs <= (1.2%), payable constructor (0.1%)

## Value Proposition
This repository provides:
1. **Verified benchmarks** - All gas costs measured with Foundry
2. **Practical examples** - Working Solidity code for each technique
3. **Test suites** - Foundry tests for reproducibility
4. **Bilingual** - English and Chinese documentation
5. **Complete coverage** - 24 distinct optimization techniques
6. **Quantified savings** - Exact gas numbers for each optimization

## Use Cases
- **Learning with proof** - See actual gas measurements
- **Quick reference** - Numbered list of 24 techniques
- **Benchmarking** - Compare techniques by gas savings
- **Testing optimizations** - Use Foundry tests as templates
- **Before/after examples** - Each technique shows both approaches

## Unique Features
1. **Foundry-verified** - All gas costs are reproducible
2. **Comprehensive test suite** - Every technique has tests
3. **Quantified comparisons** - Exact gas savings percentages
4. **Organized by impact** - Can prioritize high-impact optimizations
5. **Chinese language support** - Accessible to Chinese-speaking developers
6. **Active maintenance** - Part of WTF Academy educational initiative

## Best Practices from Examples
1. Use unchecked for loops without overflow risk (70% savings)
2. Store data in events instead of storage when possible (94% savings)
3. Use constant/immutable for fixed values (93% savings)
4. Use mapping over arrays for large datasets (50-60% savings)
5. Use local variables instead of repeated storage reads (53% savings)
6. Use custom errors instead of require strings (39% savings)
7. Use bitmaps for boolean flags (37% savings)
8. Pack storage variables into same slots (17% savings)

## Reference
Lead by [@0xKaso](https://github.com/0xKaso)
Based on: [Solidity-Gas-Optimization-Tips](https://github.com/devanshbatham/Solidity-Gas-Optimization-Tips)
