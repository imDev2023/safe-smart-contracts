# Solidity Design Patterns

A comprehensive collection of design and programming patterns for Solidity smart contract development, scraped from the fravoll/solidity-patterns documentation website.

**Source:** https://fravoll.github.io/solidity-patterns/

**Note:** This document contains patterns for Solidity version 0.4.20. Newer versions might have changed some functionalities.

---

## Overview

This repository contains 14 Solidity design patterns organized into 4 categories. Each pattern consists of code samples and detailed explanations, including background, implications, and additional information.

---

## Pattern Categories

### 1. Behavioral Patterns (4 patterns)

Patterns that define how contracts interact and behave.

| Pattern | Description |
|---------|-------------|
| **Guard Check** | Ensure that the behavior of a smart contract and its input parameters are as expected |
| **State Machine** | Enable a contract to go through different stages with different corresponding functionality exposed |
| **Oracle** | Gain access to data stored outside of the blockchain |
| **Randomness** | Generate a random number of a predefined interval in the deterministic environment of a blockchain |

### 2. Security Patterns (5 patterns)

Security-focused design patterns to protect against common vulnerabilities.

| Pattern | Description |
|---------|-------------|
| **Access Restriction** | Restrict the access to contract functionality according to suitable criteria |
| **Checks Effects Interactions** | Reduce the attack surface for malicious contracts trying to hijack control flow after an external call |
| **Secure Ether Transfer** | Secure transfer of ether from a contract to another address |
| **Pull over Push** | Shift the risk associated with transferring ether to the user |
| **Emergency Stop** | Add an option to disable critical contract functionality in case of an emergency |

### 3. Upgradeability Patterns (2 patterns)

Patterns for creating upgradeable smart contracts.

| Pattern | Description |
|---------|-------------|
| **Proxy Delegate** | Introduce the possibility to upgrade smart contracts without breaking any dependencies |
| **Eternal Storage** | Keep contract storage after a smart contract upgrade |

### 4. Economic Patterns (3 patterns)

Gas optimization patterns for cost-effective smart contracts.

| Pattern | Description |
|---------|-------------|
| **String Equality Comparison** | Check for the equality of two provided strings in a way that minimizes average gas consumption |
| **Tight Variable Packing** | Optimize gas consumption when storing or loading statically-sized variables |
| **Memory Array Building** | Aggregate and retrieve data from contract storage in a gas efficient way |

---

## Directory Structure

```
patterns/
├── 01-behavioral/
│   ├── guard-check.md
│   ├── state-machine.md
│   ├── oracle.md
│   └── randomness.md
├── 02-security/
│   ├── access-restriction.md
│   ├── checks-effects-interactions.md
│   ├── secure-ether-transfer.md
│   ├── pull-over-push.md
│   └── emergency-stop.md
├── 03-upgradeability/
│   ├── proxy-delegate.md
│   └── eternal-storage.md
├── 04-economic/
│   ├── string-equality-comparison.md
│   ├── tight-variable-packing.md
│   └── memory-array-building.md
└── README.md (this file)
```

---

## Pattern Details by Category

### Behavioral Patterns

#### Guard Check
- **Intent:** Validate inputs, check contract state, and ensure invariants hold
- **Key Methods:** `require()`, `revert()`, `assert()`
- **Use Cases:** Input validation, state verification, invariant checking

#### State Machine
- **Intent:** Manage contract lifecycle through distinct stages
- **Key Concepts:** Enums for stages, timed transitions, access control per stage
- **Use Cases:** Auctions, crowdfunding, multi-phase contracts

#### Oracle
- **Intent:** Access external data not available on blockchain
- **Key Services:** Oraclize (now Provable), Town Crier, Reality Keys
- **Use Cases:** Price feeds, sports results, weather data, scheduled execution

#### Randomness
- **Intent:** Generate pseudorandom numbers in a deterministic environment
- **Approaches:** Block hash PRNG, Oracle RNG, Collaborative PRNG
- **Use Cases:** Gambling, lotteries, random selection

### Security Patterns

#### Access Restriction
- **Intent:** Control who can call specific functions
- **Key Concepts:** Modifiers, role-based access, time-based restrictions
- **Use Cases:** Admin functions, owner-only operations, paid access

#### Checks Effects Interactions
- **Intent:** Prevent reentrancy attacks
- **Pattern Order:** 1) Checks → 2) Effects → 3) Interactions
- **Protection:** Guards against reentrancy vulnerabilities like the DAO hack

#### Secure Ether Transfer
- **Methods:** `transfer()`, `send()`, `call.value()`
- **Recommendation:** Use `transfer()` for most cases (2300 gas, auto-revert)
- **Use Cases:** Safe ether transfers, payment processing

#### Pull over Push
- **Intent:** Isolate payment failures, shift risk to users
- **Key Concept:** Users withdraw funds instead of receiving pushes
- **Trade-off:** Security vs user experience

#### Emergency Stop
- **Intent:** Pause contract in case of discovered vulnerabilities
- **Implementation:** Circuit breaker pattern with boolean flag
- **Use Cases:** Bug discovery, security incidents, maintenance

### Upgradeability Patterns

#### Proxy Delegate
- **Intent:** Upgrade contract logic without changing address
- **Key Mechanism:** `delegatecall` for execution in proxy context
- **Limitations:** Storage structure must be append-only
- **Advanced Concept:** Requires understanding of inline assembly

#### Eternal Storage
- **Intent:** Separate storage from logic for upgrades
- **Key Concept:** Key-value storage with hash-based keys
- **Flexibility:** Supports any data type through mappings
- **Trade-off:** Complexity vs upgradeability

### Economic Patterns

#### String Equality Comparison
- **Intent:** Compare strings efficiently with stable gas costs
- **Method:** Hash comparison + length check
- **Gas Savings:** ~40% for different lengths, stable for all inputs
- **Use Cases:** String validation, comparison operations

#### Tight Variable Packing
- **Intent:** Pack multiple variables into single storage slots
- **Key Concept:** EVM stores 32 bytes per slot
- **Gas Savings:** Up to 64% for storage operations
- **Example:** Pack uint8, uint16, bytes1 together

#### Memory Array Building
- **Intent:** Aggregate data without storage costs
- **Key Modifier:** `view` functions are free when called externally
- **Method:** Rebuild arrays in memory on each query
- **Use Cases:** Data aggregation, filtering, owner-based queries

---

## Important Notes

### Disclaimer
This repository is **not under active development** and some (if not most) sections might be outdated. There is **no liability** for any damages caused by the use of these patterns.

### Version Compatibility
- Patterns documented for Solidity 0.4.20
- Some features may have changed in newer versions
- Always test patterns with your target Solidity version

### Security Considerations
- All code samples are for educational purposes
- Code has **not been professionally audited**
- Use at your own risk in production
- Always conduct thorough testing and audits

---

## Common Use Cases

### For Beginners
1. **Guard Check** - Learn proper input validation
2. **Access Restriction** - Understand access control
3. **Secure Ether Transfer** - Safe payment handling

### For Intermediate Developers
1. **State Machine** - Multi-phase contract design
2. **Checks Effects Interactions** - Reentrancy protection
3. **Pull over Push** - Payment pattern design

### For Advanced Developers
1. **Proxy Delegate** - Upgradeable architecture
2. **Eternal Storage** - Storage separation
3. **Memory Array Building** - Gas optimization

---

## Pattern Relationships

### Commonly Combined Patterns
- **Access Restriction** + **Guard Check** = Secure function execution
- **Checks Effects Interactions** + **Secure Ether Transfer** = Reentrancy protection
- **Proxy Delegate** + **Eternal Storage** = Full upgradeability
- **State Machine** + **Access Restriction** = Stage-based permissions
- **Pull over Push** + **Checks Effects Interactions** = Safe payment processing

### Pattern Dependencies
- **Access Restriction** uses **Guard Check**
- **State Machine** uses **Access Restriction** and **Guard Check**
- **Emergency Stop** uses **Access Restriction**
- **Pull over Push** uses **Checks Effects Interactions**

---

## Statistics

- **Total Categories:** 4
- **Total Patterns:** 14
- **Behavioral Patterns:** 4
- **Security Patterns:** 5
- **Upgradeability Patterns:** 2
- **Economic Patterns:** 3

---

## Bibliography

For sources and references used in these patterns, visit the original documentation:
https://fravoll.github.io/solidity-patterns/bibliography.html

---

## License

This content is sourced from the fravoll/solidity-patterns repository and documentation website. All credit goes to the original authors.

**Original Source:** https://fravoll.github.io/solidity-patterns/

---

*Last Updated: 2025*
*Scraped from: https://fravoll.github.io/solidity-patterns/*
