# Contract Examples Index

Complete index of all vulnerable smart contract examples in this repository.

---

## Quick Statistics

- **Total Contracts:** 24
- **Vulnerability Categories:** 12
- **Honeypot Examples:** 6
- **Real-world Examples:** 18

---

## Contracts by Vulnerability Type

### 1. Bad Randomness (1 contract)

| File | Description | Real-world |
|------|-------------|------------|
| `bad_randomness/theRun.sol` | Lottery using predictable blockhash, timestamp, and block number | Yes - theRun |

**Vulnerability:** Uses `block.blockhash`, `block.timestamp`, and `block.number` for random number generation, allowing miners and attackers to influence outcomes.

---

### 2. Denial of Service (2 contracts)

| File | Description | Real-world |
|------|-------------|------------|
| `denial_of_service/auction.sol` | Auction where failed refund blocks contract | Yes - Various auctions |
| `denial_of_service/list_dos.sol` | Bulk refund that fails if one transfer fails | Example |

**Vulnerability:** Loop-based operations that fail entirely if one iteration fails. Includes both vulnerable and secure implementations.

---

### 3. Forced Ether Reception (1 contract)

| File | Description | Real-world |
|------|-------------|------------|
| `forced_ether_reception/coin.sol` | MyAdvancedToken vulnerable to selfdestruct | Example |

**Vulnerability:** Assumes contract balance only increases through intended functions, but `selfdestruct` can force ether into any contract.

---

### 4. Honeypots (6 contracts)

| File | Description | Trap Type |
|------|-------------|-----------|
| `honeypots/KOTH/KOTH.sol` | King of the Hill throne | Variable shadowing |
| `honeypots/Multiplicator/Multiplicator.sol` | Promise to multiply investment | Balance manipulation |
| `honeypots/VarLoop/VarLoop.sol` | Loop overflow | Type confusion (var keyword) |
| `honeypots/PrivateBank/PrivateBank.sol` | Private bank with reentrancy bait | Hidden external contract |
| `honeypots/GiftBox/GiftBox.sol` | Gift box honeypot | Hidden logic |
| `honeypots/Lottery/Lottery.sol` | Lottery honeypot | Hidden logic |

**Purpose:** These contracts appear vulnerable to attract deposits, but contain hidden traps preventing withdrawal.

---

### 5. Incorrect Interface (1 contract)

| File | Description | Real-world |
|------|-------------|------------|
| `incorrect_interface/incorrect_interface.sol` | Interface signature mismatch | Example |

**Vulnerability:** Function implementation signature differs from interface declaration, causing silent failures.

---

### 6. Integer Overflow (2 contracts)

| File | Description | Real-world |
|------|-------------|------------|
| `integer_overflow/integer_overflow_1.sol` | BatchTransfer overflow | Yes - BEC Token, SMT |
| `integer_overflow/integer_overflow_minimal.sol` | Minimal overflow example | Example |

**Vulnerability:** Arithmetic operations overflow/underflow without checks (pre-Solidity 0.8.0).

**Famous Examples:**
- **BEC Token (BeautyChain):** $900M market cap wiped out
- **SMT Token (SmartMesh):** Similar overflow bug

---

### 7. Race Condition (1 contract)

| File | Description | Real-world |
|------|-------------|------------|
| `race_condition/ERC20.sol` | ERC20 approve/transferFrom race | Yes - ERC20 standard |

**Vulnerability:** approve() function allows double-spend through frontrunning when changing allowances.

---

### 8. Reentrancy (3 contracts)

| File | Description | Real-world |
|------|-------------|------------|
| `reentrancy/Reentrancy.sol` | Classic DAO-style reentrancy | Yes - The DAO |
| `reentrancy/Reentrancy_bonus.sol` | Reentrancy with bonus logic | Example |
| `reentrancy/Reentrancy_cross_function.sol` | Cross-function reentrancy | Example |

**Vulnerability:** External calls allow callback before state updates complete.

**Most Famous Example:**
- **The DAO (2016):** $60 million stolen, led to Ethereum hard fork (ETH/ETC split)

---

### 9. Unchecked External Call (1 contract)

| File | Description | Real-world |
|------|-------------|------------|
| `unchecked_external_call/unchecked_external_call.sol` | King of Ether Throne | Yes - King of Ether |

**Vulnerability:** Low-level `call()`, `send()`, `delegatecall()` return false on failure but don't revert unless checked.

---

### 10. Unprotected Function (3 contracts)

| File | Description | Real-world |
|------|-------------|------------|
| `unprotected_function/Unprotected.sol` | Generic unprotected function | Example |
| `unprotected_function/phishable.sol` | Phishable constructor | Example |
| `unprotected_function/rubixi.sol` | Rubixi ponzi scheme | Yes - Rubixi |

**Vulnerability:** Missing access control modifiers allowing anyone to call privileged functions.

**Famous Example:**
- **Rubixi:** Constructor renamed but old function remained public, allowing anyone to become owner

---

### 11. Variable Shadowing (1 contract)

| File | Description | Real-world |
|------|-------------|------------|
| `variable_shadowing/TokenSale.sol` | Token sale with shadowed owner | Example |

**Vulnerability:** Child contract re-declares parent variable, creating two separate variables with same name.

---

### 12. Wrong Constructor Name (2 contracts)

| File | Description | Real-world |
|------|-------------|------------|
| `wrong_constructor_name/incorrect_constructor.sol` | Typo in constructor name | Yes - Multiple |
| `wrong_constructor_name/old_blockhash.sol` | Old blockhash vulnerability | Example |

**Vulnerability:** Pre-0.4.22 Solidity used function name matching contract name as constructor. Typos made it a public function.

**Famous Examples:**
- **Rubixi:** DynamicPyramid renamed to Rubixi, constructor became public function
- **Multiple ICOs:** Lost funds due to constructor typos

---

## Real-world Impact Summary

### High-Impact Vulnerabilities

| Vulnerability | Estimated Losses | Notable Incidents |
|---------------|------------------|-------------------|
| Reentrancy | $60M+ | The DAO (2016) |
| Integer Overflow | $1B+ market cap | BEC Token, SMT Token |
| Unprotected Function | $30M+ | Parity Multi-sig, Rubixi |
| Wrong Constructor | Unknown | Multiple ICOs |
| Unchecked Call | Moderate | King of Ether Throne |

### Medium-Impact Vulnerabilities

| Vulnerability | Risk Level | Common In |
|---------------|-----------|-----------|
| Bad Randomness | Medium | Gambling, Lotteries |
| Denial of Service | Medium | Auctions, Airdrops |
| Race Condition | Medium | ERC20 Tokens |
| Variable Shadowing | Low-Medium | Inheritance Patterns |

---

## Contract Categories by Risk

### Critical Risk (Immediate Exploit)
1. `reentrancy/Reentrancy.sol` - Direct fund theft
2. `integer_overflow/integer_overflow_1.sol` - Token supply manipulation
3. `unprotected_function/rubixi.sol` - Ownership takeover
4. `wrong_constructor_name/incorrect_constructor.sol` - Ownership takeover

### High Risk (Exploitable)
5. `unchecked_external_call/unchecked_external_call.sol` - Silent failures
6. `denial_of_service/auction.sol` - Contract lockup
7. `bad_randomness/theRun.sol` - Outcome manipulation
8. `race_condition/ERC20.sol` - Double-spend

### Medium Risk (Requires Conditions)
9. `forced_ether_reception/coin.sol` - Logic bypass
10. `variable_shadowing/TokenSale.sol` - State confusion
11. `incorrect_interface/incorrect_interface.sol` - Silent failures

### Educational/Honeypots
12-17. All honeypot contracts (intentionally deceptive)

---

## Usage by Category

### For Security Audits
**Priority Check List:**
1. ✓ Reentrancy protection (checks-effects-interactions)
2. ✓ Access control on privileged functions
3. ✓ Integer overflow checks (or Solidity 0.8.0+)
4. ✓ External call return value checks
5. ✓ Constructor properly defined
6. ✓ No variable shadowing
7. ✓ DoS-resistant patterns (pull over push)
8. ✓ No reliance on block randomness
9. ✓ Race condition awareness in approve patterns
10. ✓ Balance manipulation resistance

### For Tool Development
**Test Dataset:**
- **True Positives:** All 24 contracts should be flagged
- **Vulnerability Types:** 12 distinct patterns
- **Real-world Cases:** 60% based on actual exploits
- **Honeypot Detection:** 6 obfuscated examples

### For Education
**Learning Path:**
1. Start with simple: `Unprotected.sol`, `incorrect_constructor.sol`
2. Classic attacks: `Reentrancy.sol`, `integer_overflow_1.sol`
3. Subtle bugs: `variable_shadowing/TokenSale.sol`, `bad_randomness/theRun.sol`
4. Advanced: Cross-function reentrancy, honeypots
5. Real-world analysis: `rubixi.sol`, `theRun.sol`

---

## File Size & Complexity

| Contract | Lines | Complexity | Difficulty |
|----------|-------|------------|------------|
| `integer_overflow_minimal.sol` | ~20 | Low | Beginner |
| `Unprotected.sol` | ~30 | Low | Beginner |
| `Reentrancy.sol` | ~40 | Medium | Intermediate |
| `theRun.sol` | ~200 | High | Advanced |
| `coin.sol` | ~300 | High | Advanced |
| `PrivateBank.sol` | ~100 | Very High | Expert |

---

## Solidity Version Compatibility

### Pre-0.5.0 Vulnerabilities (Historical)
- Wrong constructor name
- Variable shadowing (allowed)
- var keyword type confusion

### Pre-0.8.0 Vulnerabilities
- Integer overflow/underflow
- Unchecked arithmetic

### Still Relevant (All Versions)
- Reentrancy
- Unprotected functions
- Bad randomness
- Denial of Service
- Race conditions
- Forced ether reception
- Unchecked external calls
- Incorrect interfaces

---

## Quick Reference: Mitigation Patterns

| Vulnerability | Mitigation |
|---------------|------------|
| Reentrancy | Checks-Effects-Interactions, ReentrancyGuard |
| Integer Overflow | Solidity 0.8.0+, SafeMath library |
| Unprotected Function | Access control modifiers (onlyOwner, etc.) |
| Unchecked Call | Check return values, use transfer() |
| Bad Randomness | Chainlink VRF, commit-reveal schemes |
| DoS | Pull over push, gas limits, pagination |
| Wrong Constructor | Use constructor keyword (0.5.0+) |
| Variable Shadowing | Avoid redeclaring variables, use linters |
| Race Condition | increaseAllowance/decreaseAllowance |
| Forced Ether | Don't rely on exact balance checks |
| Incorrect Interface | Use interface files, type checking |

---

## Additional Files in Repository

### Documentation
- `README.md` - Master documentation (each directory)
- `CONTRACT_INDEX.md` - This file

### Total Directory Structure
```
not-so-smart/
├── README.md
├── CONTRACT_INDEX.md
├── bad_randomness/
├── denial_of_service/
├── forced_ether_reception/
├── honeypots/
│   ├── GiftBox/
│   ├── KOTH/
│   ├── Lottery/
│   ├── Multiplicator/
│   ├── PrivateBank/
│   └── VarLoop/
├── incorrect_interface/
├── integer_overflow/
├── race_condition/
├── reentrancy/
├── unchecked_external_call/
├── unprotected_function/
├── variable_shadowing/
└── wrong_constructor_name/
```

---

**Index Last Updated:** November 15, 2025
**Source Repository:** crytic/not-so-smart-contracts (archived)
**Total Contracts Indexed:** 24
