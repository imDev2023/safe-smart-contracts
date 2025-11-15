# Not So Smart Contracts - Vulnerability Repository

This repository contains examples of common Ethereum smart contract vulnerabilities from the crytic/not-so-smart-contracts repository. Each vulnerability includes vulnerable code examples, explanations, attack scenarios, and mitigations.

**Source:** https://github.com/crytic/not-so-smart-contracts

**Note:** This repository was archived by Trail of Bits on February 24, 2023. Content has been migrated to https://secure-contracts.com/

---

## Overview

This collection contains real-world vulnerable smart contract examples organized by vulnerability type. Use these examples to:
- Learn about EVM and Solidity vulnerabilities
- Reference during security reviews
- Benchmark security and analysis tools
- Understand common attack patterns

---

## Vulnerability Categories

### 1. Bad Randomness
**Directory:** `bad_randomness/`

Pseudorandom number generation on the blockchain is generally unsafe. Block hashes, timestamps, and block numbers can be manipulated by miners.

**Files:**
- `README.md` - Detailed explanation
- `theRun.sol` - Real-world vulnerable lottery contract

**Key Issues:**
- Miner-influenced values (block hash, timestamp) are not cryptographically secure
- Everything in contracts is publicly visible
- Off-chain precalculation is faster than blockchain

---

### 2. Denial of Service (DoS)
**Directory:** `denial_of_service/`

Malicious contracts can permanently stall another contract by failing in strategic ways, particularly in loops or batch operations.

**Files:**
- `README.md` - Detailed explanation
- `auction.sol` - Vulnerable and secure auction implementations
- `list_dos.sol` - Bulk refund DoS examples

**Attack Scenarios:**
- Failed refunds blocking auctions
- Single transfer failure stopping all reimbursements
- Array spam causing gas limit issues

---

### 3. Forced Ether Reception
**Directory:** `forced_ether_reception/`

Contracts can be forced to receive ether without triggering any code using `selfdestruct`, breaking balance-based invariants.

**Files:**
- `README.md` - Detailed explanation
- `coin.sol` - MyAdvancedToken vulnerable example

**Key Mitigation:**
- Never assume how contract balance increases
- Handle unexpected balance changes

---

### 4. Honeypots
**Directory:** `honeypots/`

Smart contracts designed to entice security researchers to deposit ETH by appearing to have easy vulnerabilities, but containing hidden traps.

**Subdirectories:**
- `KOTH/` - King of the Hill variable shadowing honeypot
- `Multiplicator/` - Balance manipulation honeypot
- `VarLoop/` - Type confusion with var keyword
- `PrivateBank/` - Hidden external contract trap
- `GiftBox/` - Gift box honeypot
- `Lottery/` - Lottery honeypot

**Files:**
- `README.md` - Comprehensive honeypot analysis

---

### 5. Incorrect Interface
**Directory:** `incorrect_interface/`

Implementation uses different function signatures than the interface, causing silent failures or unexpected behavior.

**Files:**
- `README.md` - Detailed explanation
- `incorrect_interface.sol` - Interface mismatch examples

---

### 6. Integer Overflow
**Directory:** `integer_overflow/`

Arithmetic in Solidity (or EVM) is not safe by default. Numbers can overflow/underflow without warnings.

**Files:**
- `README.md` - Detailed explanation
- `integer_overflow_1.sol` - BatchTransfer overflow example
- `integer_overflow_minimal.sol` - Minimal overflow example

**Note:** Fixed in Solidity 0.8.0+ with built-in overflow checks

---

### 7. Race Condition
**Directory:** `race_condition/`

Transactions can be frontrun on the blockchain, allowing attackers to observe pending transactions and submit their own with higher gas prices.

**Files:**
- `README.md` - Detailed explanation
- `ERC20.sol` - ERC20 approve/transferFrom race condition

---

### 8. Reentrancy
**Directory:** `reentrancy/`

Calling external contracts gives them control over execution flow, allowing recursive callbacks before state updates complete.

**Files:**
- `README.md` - Detailed explanation
- `Reentrancy.sol` - Classic DAO-style reentrancy
- `Reentrancy_bonus.sol` - Reentrancy with bonus logic
- `Reentrancy_cross_function.sol` - Cross-function reentrancy

**Famous Example:** The DAO hack (2016) - $60M stolen

---

### 9. Unchecked External Call
**Directory:** `unchecked_external_call/`

Some Solidity operations silently fail without reverting. Low-level calls like `call`, `send`, and `delegatecall` return false on failure but don't revert.

**Files:**
- `README.md` - Detailed explanation
- `unchecked_external_call.sol` - King of Ether Throne example

---

### 10. Unprotected Function
**Directory:** `unprotected_function/`

Failure to use proper access control modifiers allows attackers to call privileged functions.

**Files:**
- `README.md` - Detailed explanation
- `Unprotected.sol` - Generic unprotected function
- `phishable.sol` - Phishable contract
- `rubixi.sol` - Real Rubixi ponzi scheme vulnerability

---

### 11. Variable Shadowing
**Directory:** `variable_shadowing/`

Local variable names identical to ones in outer scope can cause confusion and bugs. Solidity allows inheritance shadowing.

**Files:**
- `README.md` - Detailed explanation
- `TokenSale.sol` - Token sale shadowing example

---

### 12. Wrong Constructor Name
**Directory:** `wrong_constructor_name/`

Pre-0.4.22 Solidity used function with contract name as constructor. Typos made functions public, allowing anyone to become owner.

**Files:**
- `README.md` - Detailed explanation
- `incorrect_constructor.sol` - Missing constructor example
- `old_blockhash.sol` - Old blockhash vulnerability

**Note:** Fixed in Solidity 0.5.0+ with `constructor` keyword

---

## Statistics Summary

### Total Files Collected
- **Vulnerability Categories:** 12
- **Honeypot Examples:** 6
- **Total .sol Files:** 24
- **Total Documentation Files:** 18

### Files by Category
1. **bad_randomness:** 1 .sol file
2. **denial_of_service:** 2 .sol files
3. **forced_ether_reception:** 1 .sol file
4. **honeypots:** 6 .sol files
5. **incorrect_interface:** 1 .sol file
6. **integer_overflow:** 2 .sol files
7. **race_condition:** 1 .sol file
8. **reentrancy:** 3 .sol files
9. **unchecked_external_call:** 1 .sol file
10. **unprotected_function:** 3 .sol files
11. **variable_shadowing:** 1 .sol file
12. **wrong_constructor_name:** 2 .sol files

---

## Usage Guidelines

### For Learning
1. Read the README.md in each vulnerability directory
2. Study the vulnerable .sol examples
3. Understand the attack scenarios
4. Review recommended mitigations

### For Security Audits
- Use as reference patterns during code review
- Check for similar vulnerable patterns
- Validate mitigation strategies

### For Tool Development
- Benchmark detection tools against known vulnerabilities
- Test static analysis accuracy
- Validate symbolic execution capabilities

---

## Important Notes

### Compiler Warnings
Most recent Solidity compilers (0.8.0+) emit warnings for many of these vulnerabilities. However:
- Some rely on logic gaps in compiler/language
- Not all are caught by static analysis
- Manual review still essential

### Historical Context
- Many examples are from pre-2018 contracts
- Some vulnerabilities fixed in modern Solidity
- Patterns still relevant for legacy code audits

---

## Credits

**Original Repository:** Trail of Bits / Crytic
**Contributors:** 12+ security researchers
**License:** Apache-2.0
**Archived:** February 24, 2023

For the most up-to-date security guidance, visit:
- https://secure-contracts.com/
- https://github.com/crytic/building-secure-contracts

---

## Additional Resources

### Related Repositories
- [ConsenSys Smart Contract Best Practices](https://github.com/ConsenSys/smart-contract-best-practices)
- [SWC Registry](https://swcregistry.io/)
- [Solidity Security Blog](https://blog.soliditylang.org/category/security-alerts/)

### Security Tools
- [Slither](https://github.com/crytic/slither) - Static analysis
- [Manticore](https://github.com/trailofbits/manticore) - Symbolic execution
- [Echidna](https://github.com/crytic/echidna) - Fuzzing
- [Mythril](https://github.com/ConsenSys/mythril) - Security analysis

---

**Last Updated:** November 15, 2025
**Repository Scraped:** crytic/not-so-smart-contracts (master branch)
