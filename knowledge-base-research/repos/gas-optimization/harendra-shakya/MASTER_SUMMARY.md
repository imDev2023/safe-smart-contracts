# harendra-shakya/solidity-gas-optimization - Master Summary

## Repository Overview
- **Repository**: harendra-shakya/solidity-gas-optimization
- **URL**: https://github.com/harendra-shakya/solidity-gas-optimization
- **Description**: Extensive list of EVM gas optimization tricks and techniques
- **Stars**: 181+
- **Type**: Practical guide with detailed explanations

## Repository Structure
```
harendra-shakya/
├── README.md                 # Comprehensive optimization guide
└── MASTER_SUMMARY.md        # This file
```

## Content Summary

### Files Collected
- **Total Files**: 1
  - 1 README.md (comprehensive guide with all techniques)

### Main Gas Optimization Areas

#### 1. Storage Optimization
**Gas Costs**:
- Saving one variable: 20,000 gas
- Rewriting variable: 5,000 gas
- Reading from slot: 200 gas
- Declaration: Free (no initialization)

**Tips**:
- Always save storage variables to memory in functions
- Calculate everything in memory before updating storage
- Pack two or more storage variables into one slot
- Pack structs for efficiency
- Don't initialize zero values
- Make values constant where possible

**Refunds**:
- Zeroing storage slot: 15,000 gas refund
- Selfdestruct: 24,000 gas refund

**Data Types & Packing**:
- Use bytes32 whenever possible (most optimized)
- bytes32 cheaper than string
- Variable packing only in storage (not memory/calldata)
- Multiple small variables pack into single 32-byte slot

#### 2. Variables Optimization
- Avoid public variables
- Use global variables efficiently
- Private visibility saves gas
- Use events rather than storing data
- Name return values (avoid local variables)

**Mapping vs Array**:
- Use mapping when possible (cheaper)
- Arrays good for small datasets

**Fixed vs Dynamic**:
- Fixed size always cheaper
- Use byte32 for short strings
- Additive operations cheaper than subtractive

#### 3. Functions Optimization
- Use external over public (calldata vs memory)
- Each position adds 22 gas
- Reduce public variables
- Put often-called functions earlier
- Reduce parameters
- Payable functions save gas
- Modifiers increase code size

**Fallback Functions**:
- Cheaper than regular calls
- Don't require function signature

**View Functions**:
- Free when called externally
- Cost gas when called in transactions

#### 4. Loops Optimization
- Use memory variables
- Avoid unbounded loops
- Don't initialize to zero (uint256 index; not uint256 index = 0;)
- ++i costs less than i++

#### 5. Operations Optimization
**Order**:
- Order cheap functions before expensive
- Use short-circuiting (|| and &&)

**Unchecked**:
- Use for arithmetic without overflow/underflow risk
- Saves gas on checks from Solidity v0.8.0+

#### 6. Other Optimizations
- Remove dead code
- Try different Solidity versions
- EXTCODESIZE is expensive
- Self-destruct and factory patterns

**Libraries**:
- Complex logic in libraries saves bytecode
- But calling libraries has cost

**Errors**:
- Use require for runtime validation
- Assert for static validation
- Shorter require strings
- Assert consumes all gas on failure

**Hash Functions**:
- keccak256: 30 + 6 gas per word (best)
- sha256: 60 + 12 gas per word
- ripemd160: 600 + 120 gas per word

**ERC1167**:
- Minimal proxy for deploying contract clones
- Gas-efficient factory pattern

#### 7. Merkle Proofs
- Validate large data with small proofs
- Efficient verification mechanism

#### 8. Yul Tricks (Advanced)
- Utilize access lists
- Verify assembly is better than compiler
- Overwrite old values onto new
- Keep data in calldata
- View compiler Yul output (-yul, -ir flags)
- Vanity addresses with leading zeroes
- Sub 32-byte values case-by-case
- Writing to existing slots cheaper than new
- Negative values more expensive in calldata
- Use iszero() strategically
- Use gas() in call()
- Copy from Solmate's assembly blocks
- Store storage in code (SLOAD2)
- Skip unnecessary zero address checks
- Avoid safemath for overflow-safe operations
- L2 to L2 trustless calls

## Gas Optimization Techniques Count
- **24+ major categories**
- **100+ individual techniques**
- **Beginner to Advanced coverage**

## Tools Referenced
- Remix
- Truffle
- Eth Gas Reporter

## Additional Resources Linked
- EVM Opcodes gas costs
- Awesome Solidity Gas Optimization
- Yul Optimizations and Tricks
- Gas Puzzles

## Value Proposition
This repository provides:
- **Comprehensive coverage** of gas optimization techniques
- **Detailed explanations** of why each technique works
- **Practical tips** for immediate application
- **Advanced Yul techniques** for expert developers
- **Cost breakdowns** for various operations

## Use Cases
- Daily reference for Solidity developers
- Learning gas optimization from basics to advanced
- Audit preparation and optimization reviews
- Smart contract cost reduction
- Understanding EVM internals through gas mechanics

## Unique Features
1. Covers both high-level Solidity and low-level Yul
2. Includes specific gas cost numbers
3. Explains the "why" behind each optimization
4. References to external tools and resources
5. Organized by logical categories (Storage, Variables, Functions, etc.)
