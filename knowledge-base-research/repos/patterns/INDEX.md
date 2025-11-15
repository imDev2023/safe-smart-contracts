# Solidity Design Patterns - Complete Index

**Source:** https://fravoll.github.io/solidity-patterns/

---

## Quick Navigation

- [Behavioral Patterns](#behavioral-patterns)
- [Security Patterns](#security-patterns)
- [Upgradeability Patterns](#upgradeability-patterns)
- [Economic Patterns](#economic-patterns)
- [Pattern Comparison Matrix](#pattern-comparison-matrix)

---

## Behavioral Patterns

Patterns that define how contracts interact and behave.

### 1. Guard Check
**File:** `01-behavioral/guard-check.md`
**URL:** https://fravoll.github.io/solidity-patterns/guard_check.html

**Summary:** Ensure that the behavior of a smart contract and its input parameters are as expected.

**Key Features:**
- Three methods: `require()`, `revert()`, `assert()`
- Input validation and state checking
- Invariant verification
- Gas refund differences

**When to Use:**
- Validate user inputs
- Check contract state before execution
- Verify invariants
- Rule out impossible conditions

**Related Patterns:** Access Restriction, State Machine, Checks Effects Interactions

---

### 2. State Machine
**File:** `01-behavioral/state-machine.md`
**URL:** https://fravoll.github.io/solidity-patterns/state_machine.html

**Summary:** Enable a contract to go through different stages with different corresponding functionality exposed.

**Key Features:**
- Enum-based stage representation
- Timed transitions
- Manual transitions
- Stage-specific function access

**When to Use:**
- Multi-stage contract lifecycle
- Stage-restricted functions
- Auctions, crowdfunding, gambling

**Related Patterns:** Access Restriction, Guard Check

---

### 3. Oracle
**File:** `01-behavioral/oracle.md`
**URL:** https://fravoll.github.io/solidity-patterns/oracle.html

**Summary:** Gain access to data stored outside of the blockchain.

**Key Features:**
- Query external data sources
- Callback pattern
- Trust considerations
- Decentralized oracle options

**When to Use:**
- Need external data (prices, results, weather)
- Scheduled function execution
- Random number generation
- Real-world event triggers

**Known Services:** Oraclize/Provable, Town Crier, Reality Keys

---

### 4. Randomness
**File:** `01-behavioral/randomness.md`
**URL:** https://fravoll.github.io/solidity-patterns/randomness.html

**Summary:** Generate a random number of a predefined interval in the deterministic environment of a blockchain.

**Key Features:**
- Block hash PRNG
- Commit-reveal scheme
- Trusted party seed
- Oracle-based randomness

**When to Use:**
- Gaming and gambling
- Random selection
- Lottery systems
- Non-predictable outcomes

**Trade-offs:** Security vs Cost vs Delay vs Randomness quality

---

## Security Patterns

Security-focused design patterns to protect against common vulnerabilities.

### 5. Access Restriction
**File:** `02-security/access-restriction.md`
**URL:** https://fravoll.github.io/solidity-patterns/access_restriction.html

**Summary:** Restrict the access to contract functionality according to suitable criteria.

**Key Features:**
- Function modifiers for access control
- Owner-based restrictions
- Time-based restrictions
- Payment-based restrictions

**When to Use:**
- Admin-only functions
- Role-based access control
- Time-locked operations
- Paid feature access

**Related Patterns:** Guard Check, State Machine, Emergency Stop

---

### 6. Checks Effects Interactions
**File:** `02-security/checks-effects-interactions.md`
**URL:** https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html

**Summary:** Reduce the attack surface for malicious contracts trying to hijack control flow after an external call.

**Key Features:**
- Three-step pattern: Checks → Effects → Interactions
- Reentrancy prevention
- State update before external calls
- "Optimistic accounting"

**When to Use:**
- Any external call
- Ether transfers
- Contract interactions
- Preventing reentrancy attacks

**Critical Example:** DAO exploit prevention

---

### 7. Secure Ether Transfer
**File:** `02-security/secure-ether-transfer.md`
**URL:** https://fravoll.github.io/solidity-patterns/secure_ether_transfer.html

**Summary:** Secure transfer of ether from a contract to another address.

**Key Features:**
- Three methods: `transfer()`, `send()`, `call.value()`
- Gas forwarding differences
- Exception propagation
- Method comparison

**Recommendations:**
- **Use `transfer()`** for most cases (2300 gas, auto-revert)
- **Use `send()`** for custom error handling
- **Use `call.value()`** as last resort (adjustable gas)

**When to Use:**
- Any ether transfer from contract
- Payment processing
- Refunds and withdrawals

---

### 8. Pull over Push
**File:** `02-security/pull-over-push.md`
**URL:** https://fravoll.github.io/solidity-patterns/pull_over_push.html

**Summary:** Shift the risk associated with transferring ether to the user.

**Key Features:**
- User-initiated withdrawals
- Balance tracking via mapping
- Isolated transfer failures
- No cascading failures

**When to Use:**
- Multiple ether transfers
- Avoiding transfer risk
- User has incentive to withdraw
- Preventing DoS attacks

**Trade-off:** Security ↑ User Experience ↓

---

### 9. Emergency Stop
**File:** `02-security/emergency-stop.md`
**URL:** https://fravoll.github.io/solidity-patterns/emergency_stop.html

**Summary:** Add an option to disable critical contract functionality in case of an emergency.

**Key Features:**
- Circuit breaker pattern
- Boolean flag for stopped state
- Function modifier restrictions
- Resumable/non-resumable options

**When to Use:**
- Pause contract capability needed
- Guard against unknown bugs
- Prepare for potential failures
- Emergency response mechanism

**Trade-off:** Security ↑ Decentralization ↓

---

## Upgradeability Patterns

Patterns for creating upgradeable smart contracts.

### 10. Proxy Delegate
**File:** `03-upgradeability/proxy-delegate.md`
**URL:** https://fravoll.github.io/solidity-patterns/proxy_delegate.html

**Summary:** Introduce the possibility to upgrade smart contracts without breaking any dependencies.

**Key Features:**
- `delegatecall` mechanism
- Proxy forwards calls to delegate
- Execution in proxy context
- Inline assembly for return values

**Requirements:**
- Advanced Solidity knowledge
- Understanding of delegatecall
- Storage must be append-only

**When to Use:**
- Upgradeable contract logic
- Maintain single address
- Complex DApps
- Long-term projects

**Related Patterns:** Eternal Storage

---

### 11. Eternal Storage
**File:** `03-upgradeability/eternal-storage.md`
**URL:** https://fravoll.github.io/solidity-patterns/eternal_storage.html

**Summary:** Keep contract storage after a smart contract upgrade.

**Key Features:**
- Separate storage contract
- Key-value storage with hash keys
- Flexible data type support
- No storage migration needed

**When to Use:**
- Upgradeable contracts
- Avoid storage migration
- Accept complex syntax
- Long-term storage preservation

**Implementation:**
- Mappings for each data type
- `keccak256()` hash keys
- Access restriction on setters
- Wrapper functions for usability

---

## Economic Patterns

Gas optimization patterns for cost-effective smart contracts.

### 12. String Equality Comparison
**File:** `04-economic/string-equality-comparison.md`
**URL:** https://fravoll.github.io/solidity-patterns/string_equality_comparison.html

**Summary:** Check for the equality of two provided strings in a way that minimizes average gas consumption.

**Key Features:**
- Hash-based comparison
- Length check optimization
- Stable gas costs
- ~40% savings for different lengths

**Method:**
1. Check string lengths
2. Hash both strings with `keccak256()`
3. Compare hashes

**When to Use:**
- String comparison needed
- Strings longer than 2 characters
- Minimize average gas across various inputs

**Gas:** Very stable, ~1261 gas regardless of string length

---

### 13. Tight Variable Packing
**File:** `04-economic/tight-variable-packing.md`
**URL:** https://fravoll.github.io/solidity-patterns/tight_variable_packing.html

**Summary:** Optimize gas consumption when storing or loading statically-sized variables.

**Key Features:**
- Pack variables into 32-byte slots
- Use smaller data types (uint8, uint16, bytes1)
- Order variables correctly
- ~64% gas savings on storage

**When to Use:**
- Multiple statically-sized state variables
- Structs with multiple fields
- Can use smaller data types
- Storage-heavy contracts

**Example:** Pack 8 × `uint8` = 1 storage slot instead of 8 slots

**Trade-off:** Gas Savings ↑ Readability ↓

---

### 14. Memory Array Building
**File:** `04-economic/memory-array-building.md`
**URL:** https://fravoll.github.io/solidity-patterns/memory_array_building.html

**Summary:** Aggregate and retrieve data from contract storage in a gas efficient way.

**Key Features:**
- `view` functions are free (external calls)
- Rebuild arrays in memory
- No storage costs for queries
- Aggregate data on-the-fly

**When to Use:**
- Retrieve aggregated data
- Avoid query gas costs
- Data attributes change frequently
- External data access

**Implementation:**
1. Store data in array of structs
2. Track counts in mapping
3. Build filtered array in memory
4. Return IDs, query individually

**Gas:** 0 for external calls, enables free data aggregation

---

## Pattern Comparison Matrix

### By Complexity

| Complexity | Patterns |
|------------|----------|
| **Beginner** | Guard Check, Access Restriction, Secure Ether Transfer |
| **Intermediate** | State Machine, Checks Effects Interactions, Pull over Push, Emergency Stop, String Equality, Tight Variable Packing, Memory Array Building |
| **Advanced** | Oracle, Randomness, Proxy Delegate, Eternal Storage |

### By Gas Impact

| Impact | Patterns |
|--------|----------|
| **Reduces Gas** | Tight Variable Packing, Memory Array Building, String Equality Comparison |
| **Increases Gas** | Pull over Push, Eternal Storage, Proxy Delegate |
| **Neutral** | Guard Check, Access Restriction, State Machine, Checks Effects Interactions, Secure Ether Transfer, Emergency Stop |
| **Variable** | Oracle, Randomness |

### By Security Focus

| Security Level | Patterns |
|----------------|----------|
| **High Security** | Checks Effects Interactions, Secure Ether Transfer, Access Restriction, Guard Check, Emergency Stop |
| **Medium Security** | Pull over Push, State Machine |
| **Security Trade-off** | Proxy Delegate, Eternal Storage, Oracle, Randomness |

### By Use Case

| Use Case | Recommended Patterns |
|----------|---------------------|
| **Payment Processing** | Secure Ether Transfer, Checks Effects Interactions, Pull over Push |
| **Access Control** | Access Restriction, Guard Check, State Machine |
| **Upgradeability** | Proxy Delegate, Eternal Storage |
| **Gas Optimization** | Tight Variable Packing, Memory Array Building, String Equality Comparison |
| **External Data** | Oracle, Randomness |
| **Emergency Response** | Emergency Stop, Access Restriction |
| **Multi-Phase Contracts** | State Machine, Access Restriction |

---

## Pattern Dependencies Graph

```
Guard Check
    ├── Access Restriction
    │       ├── State Machine
    │       ├── Emergency Stop
    │       └── Eternal Storage
    ├── State Machine
    ├── Checks Effects Interactions
    │       └── Pull over Push
    └── Randomness

Secure Ether Transfer
    └── Pull over Push

Proxy Delegate
    └── Eternal Storage (often combined)
```

---

## Quick Reference: When to Use Which Pattern

### I need to...

**...validate inputs**
→ Guard Check

**...restrict function access**
→ Access Restriction

**...prevent reentrancy**
→ Checks Effects Interactions

**...transfer ether safely**
→ Secure Ether Transfer

**...handle multiple payments**
→ Pull over Push

**...pause my contract**
→ Emergency Stop

**...make my contract upgradeable**
→ Proxy Delegate + Eternal Storage

**...manage contract lifecycle**
→ State Machine

**...access external data**
→ Oracle

**...generate randomness**
→ Randomness (with trusted party) or Oracle

**...optimize gas costs**
→ Tight Variable Packing, Memory Array Building, String Equality Comparison

---

## All Patterns Alphabetically

1. Access Restriction
2. Checks Effects Interactions
3. Emergency Stop
4. Eternal Storage
5. Guard Check
6. Memory Array Building
7. Oracle
8. Proxy Delegate
9. Pull over Push
10. Randomness
11. Secure Ether Transfer
12. State Machine
13. String Equality Comparison
14. Tight Variable Packing

---

## All Patterns by File Path

```
01-behavioral/guard-check.md
01-behavioral/state-machine.md
01-behavioral/oracle.md
01-behavioral/randomness.md
02-security/access-restriction.md
02-security/checks-effects-interactions.md
02-security/secure-ether-transfer.md
02-security/pull-over-push.md
02-security/emergency-stop.md
03-upgradeability/proxy-delegate.md
03-upgradeability/eternal-storage.md
04-economic/string-equality-comparison.md
04-economic/tight-variable-packing.md
04-economic/memory-array-building.md
```

---

*Complete index of all 14 Solidity design patterns from fravoll/solidity-patterns*
