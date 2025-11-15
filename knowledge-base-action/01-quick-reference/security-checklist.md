# Smart Contract Security Checklist

Pre-deployment security checklist synthesized from ConsenSys best practices, vulnerability databases, and security tools documentation.

**Last Updated:** November 15, 2025
**Sources:** ConsenSys Best Practices, SWC Registry, OpenZeppelin Docs

---

## How to Use This Checklist

1. Check off each item as you complete it
2. Items marked **CRITICAL** must be completed before deployment
3. Document why any item is not applicable
4. Review this checklist at each development milestone
5. Have another developer verify the checklist

---

## 1. Code Security Checks

### Reentrancy Protection (CRITICAL)
- [ ] **All functions making external calls use `nonReentrant` modifier**
  - *Why:* Prevents reentrancy attacks that can drain contract funds
  - *Reference:* The DAO hack (2016), $50M stolen via reentrancy
  - *Solution:* `import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"`

- [ ] **Checks-Effects-Interactions pattern followed in all functions**
  - *Why:* Defense-in-depth against reentrancy
  - *Pattern:* 1) Validate inputs, 2) Update state, 3) Make external calls
  - *Example:* Update balance BEFORE transfer, not after

- [ ] **No cross-function reentrancy vulnerabilities**
  - *Why:* Attacker can reenter different function sharing state
  - *Check:* Map all functions with shared state and external calls
  - *Tool:* Slither's reentrancy detector

- [ ] **No read-only reentrancy issues with external contracts**
  - *Why:* Other contracts reading your state during external calls
  - *Check:* State changes before any external calls
  - *Example:* Oracle contracts reading stale balances

- [ ] **Pull-over-push pattern used for payments**
  - *Why:* Prevents DoS when payment fails
  - *Implementation:* Users withdraw funds vs. contract pushes
  - *Reference:* ConsenSys Best Practices - External Calls

---

### Access Control (CRITICAL)
- [ ] **All privileged functions have access control modifiers**
  - *Why:* Prevent unauthorized access to admin functions
  - *Tools:* `onlyOwner`, `onlyRole(ROLE)`, custom modifiers
  - *Check:* No public/external admin functions without protection

- [ ] **`msg.sender` used for authorization, NEVER `tx.origin`**
  - *Why:* `tx.origin` vulnerable to phishing attacks
  - *Attack:* Malicious contract can call your contract via user
  - *Rule:* `tx.origin` should never appear in your code

- [ ] **Role-based access control properly implemented**
  - *Why:* Granular permissions reduce attack surface
  - *Implementation:* OpenZeppelin AccessControl
  - *Check:* Roles clearly defined and minimal

- [ ] **Ownership can be transferred safely (2-step if critical)**
  - *Why:* Prevent accidental ownership loss
  - *Solution:* Use `Ownable2Step` instead of `Ownable`
  - *Check:* New owner must accept ownership

- [ ] **DEFAULT_ADMIN_ROLE restricted and properly managed**
  - *Why:* Admin role can grant/revoke all other roles
  - *Best Practice:* Use multisig or governance contract
  - *Check:* Not assigned to EOA in production

---

### Input Validation (CRITICAL)
- [ ] **All external inputs validated with `require` or custom errors**
  - *Why:* Malicious inputs can cause unexpected behavior
  - *Check:* Every external parameter has validation
  - *Examples:* Non-zero addresses, value ranges, array lengths

- [ ] **Address parameters checked for zero address**
  - *Why:* Tokens sent to address(0) are lost forever
  - *Pattern:* `require(recipient != address(0), "Zero address")`
  - *Exceptions:* Burning tokens intentionally

- [ ] **Array indices validated before access**
  - *Why:* Prevent out-of-bounds access and storage corruption
  - *Check:* `require(index < array.length)`
  - *Critical:* Especially with user-provided indices

- [ ] **Integer overflow/underflow handled (Solidity 0.8+ or SafeMath)**
  - *Why:* Arithmetic errors can cause loss of funds
  - *Solution:* Use Solidity >=0.8.0 (built-in checks)
  - *Check:* SafeCast used for type conversions

- [ ] **Division by zero prevented**
  - *Why:* Causes transaction revert, potential DoS
  - *Pattern:* `require(denominator != 0, "Division by zero")`
  - *Check:* All division operations

---

### External Contract Interactions (CRITICAL)
- [ ] **Return values from external calls checked**
  - *Why:* Unchecked calls can silently fail
  - *Pattern:* `(bool success, ) = addr.call(...); require(success);`
  - *Tool:* Use `Address.functionCall()` from OpenZeppelin

- [ ] **SafeERC20 used for all token interactions**
  - *Why:* Handles non-standard ERC20 implementations
  - *Import:* `@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol`
  - *Methods:* `safeTransfer`, `safeTransferFrom`, `safeApprove`

---

## 2. Test Coverage

### Unit Testing (CRITICAL)
- [ ] **100% line coverage for critical functions**
  - *Why:* Untested code often contains bugs
  - *Critical:* Transfer, withdraw, mint, burn, admin functions
  - *Tool:* `forge coverage` or `hardhat-coverage`

- [ ] **Edge cases tested (zero values, max values, empty arrays)**
  - *Why:* Edge cases commonly reveal bugs
  - *Examples:* 0 amount transfers, uint256.max values, empty arrays
  - *Pattern:* Boundary value analysis

- [ ] **Access control tested (unauthorized access attempts)**
  - *Why:* Verify protection works as intended
  - *Tests:* Call restricted functions from non-authorized accounts
  - *Pattern:* Expect revert with correct error

- [ ] **Reentrancy attack scenarios tested**
  - *Why:* Verify nonReentrant modifier works
  - *Implementation:* Create malicious contract attempting reentrancy
  - *Pattern:* Expect revert with "ReentrancyGuard" error

- [ ] **Integer overflow/underflow edge cases tested**
  - *Why:* Verify arithmetic safety
  - *Tests:* Operations near type limits (0, max uint256)
  - *Pattern:* Expect revert on overflow (0.8+)

---

### Integration Testing
- [ ] **Multi-contract interactions tested**
  - *Why:* Bugs often emerge at integration points
  - *Scenarios:* Token approvals, proxy upgrades, external calls
  - *Tool:* Foundry fork testing

- [ ] **Upgrade paths tested (if upgradeable)**
  - *Why:* Upgrades can corrupt state if done wrong
  - *Tests:* Deploy V1, set state, upgrade to V2, verify state
  - *Tool:* OpenZeppelin Upgrades plugin

- [ ] **Fork testing against mainnet contracts (if applicable)**
  - *Why:* Test against real contract behavior
  - *Tool:* `forge test --fork-url $RPC_URL`
  - *Scenarios:* DEX integrations, oracle calls

- [ ] **Gas limit scenarios tested (DoS prevention)**
  - *Why:* Unbounded loops can make functions uncallable
  - *Tests:* Large arrays, many iterations
  - *Pattern:* Verify gas stays under block limit

- [ ] **Event emission verified for state changes**
  - *Why:* Events critical for off-chain indexing
  - *Pattern:* `vm.expectEmit()` in Foundry
  - *Check:* All state changes emit appropriate events

---

### Invariant/Fuzz Testing
- [ ] **Invariant tests for critical properties**
  - *Why:* Catch bugs normal tests miss
  - *Invariants:* Total supply == sum of balances, etc.
  - *Tool:* Foundry invariant testing

- [ ] **Fuzz testing for input validation**
  - *Why:* Test with random inputs
  - *Pattern:* `function testFuzz_transfer(uint256 amount) public`
  - *Tool:* Foundry fuzzing, Echidna

- [ ] **Stateful fuzzing for complex workflows**
  - *Why:* Find bugs in state transitions
  - *Tool:* Echidna, Foundry invariant tests
  - *Scenarios:* Multi-step operations

---

## 3. Design Review

### Architecture
- [ ] **Contract architecture follows principle of least privilege**
  - *Why:* Minimize damage from compromised component
  - *Pattern:* Separate concerns, minimal permissions
  - *Check:* Each contract has minimal necessary permissions

- [ ] **External dependencies minimized and audited**
  - *Why:* Dependencies introduce risk
  - *Rule:* Only use audited libraries (OpenZeppelin, Solmate)
  - *Check:* Review all `import` statements

- [ ] **Upgrade mechanism secure (if upgradeable)**
  - *Why:* Upgrades are high-risk operations
  - *Best Practice:* Timelock + multisig control
  - *Check:* Not controlled by single EOA

- [ ] **Emergency stop mechanism implemented**
  - *Why:* Allow response to discovered vulnerabilities
  - *Implementation:* OpenZeppelin Pausable
  - *Check:* Can pause without bricking contract

- [ ] **Circuit breaker won't brick contract permanently**
  - *Why:* Need recovery path from paused state
  - *Check:* Unpause function exists and accessible
  - *Pattern:* Separate pause/unpause permissions

---

### Economic Model
- [ ] **Token economics reviewed for manipulation vectors**
  - *Why:* Economic attacks can drain value
  - *Check:* Flash loan attacks, oracle manipulation
  - *Tools:* Economic modeling, game theory analysis

- [ ] **Price oracle manipulation considered**
  - *Why:* Manipulated prices = loss of funds
  - *Solutions:* TWAP, multiple oracles, bounds checking
  - *Check:* Not relying on single-block prices

- [ ] **Flash loan attack vectors analyzed**
  - *Why:* Instant liquidity enables complex attacks
  - *Mitigations:* Reentrancy guards, oracle TWAP, invariants
  - *Check:* Critical operations safe with instant liquidity

- [ ] **Fee structure prevents griefing**
  - *Why:* Malicious users can make contract unusable
  - *Check:* Fees cover gas costs, prevent spam
  - *Example:* Minimum deposit amounts

- [ ] **No unbounded growth of storage costs**
  - *Why:* Can make contract too expensive to use
  - *Check:* Bounded arrays, pagination, cleanup mechanisms
  - *Pattern:* Pull payments, enumeration limits

---

### Data Structures
- [ ] **Storage layout documented (especially for upgradeable)**
  - *Why:* Prevent storage collisions during upgrades
  - *Tool:* Hardhat storage layout, Foundry
  - *Pattern:* Comment each storage variable with slot

- [ ] **No storage collisions in inheritance**
  - *Why:* Wrong inheritance order corrupts state
  - *Rule:* Follow C3 linearization (most specific last)
  - *Check:* Use storage layout analysis tools

- [ ] **Gas-efficient data structures used**
  - *Why:* High gas = poor UX
  - *Examples:* Mappings for lookups, packed structs
  - *Reference:* Gas optimization guide

- [ ] **Enumerability considered (avoid if unnecessary)**
  - *Why:* Enumeration is expensive
  - *Trade-off:* Storage cost vs. query capability
  - *Alternative:* Events + off-chain indexing

- [ ] **BitMaps used for multiple booleans (>10)**
  - *Why:* 37.4% gas savings vs. bool mapping
  - *Implementation:* OpenZeppelin BitMaps
  - *Check:* Dense boolean flags

---

## 4. Gas Optimization

### Storage Optimization
- [ ] **Constants and immutables used for fixed values**
  - *Why:* 92.9% gas savings on reads
  - *Pattern:* `uint256 public constant FEE = 100`
  - *Check:* No storage vars that never change

- [ ] **Storage variables packed into 32-byte slots**
  - *Why:* 16.6% average savings, up to 50% possible
  - *Pattern:* Group related small types together
  - *Tool:* Hardhat storage layout analyzer

- [ ] **Storage cached in memory for multiple reads**
  - *Why:* 52.7% savings on subsequent reads
  - *Pattern:* `uint256 supply = totalSupply;` before loop
  - *Rule:* Cache if used 2+ times

- [ ] **Delete used to clear storage (gas refunds)**
  - *Why:* 89.6% effective savings with refunds
  - *Pattern:* `delete balances[user];` vs `= 0`
  - *Benefit:* 15,000 gas refund per slot

- [ ] **Mappings used instead of arrays for lookups**
  - *Why:* 49.6-59.2% savings on operations
  - *Trade-off:* No enumeration capability
  - *Check:* Only use arrays when iteration needed

---

### Function Optimization
- [ ] **Custom errors used instead of require strings**
  - *Why:* 38.8% savings on deployment and reverts
  - *Requires:* Solidity >=0.8.4
  - *Pattern:* `error InsufficientBalance(uint256 requested, uint256 available);`

- [ ] **Unchecked used for safe arithmetic**
  - *Why:* 70.1% savings on operations
  - *Safe for:* Loop counters, post-validation math
  - *Pattern:* `unchecked { ++i; }` in loops

- [ ] **Function visibility optimized (external vs public)**
  - *Why:* External cheaper for calldata parameters
  - *Rule:* Use `external` unless called internally
  - *Savings:* Variable, mostly deployment

- [ ] **Calldata used for read-only external parameters**
  - *Why:* 0.8% savings vs memory
  - *Pattern:* `function f(uint256[] calldata arr) external`
  - *Rule:* Always use calldata if not modifying

- [ ] **Short-circuit logic optimized (cheap checks first)**
  - *Why:* Up to 99.9% savings when first fails
  - *Pattern:* `require(cheapCheck && expensiveCheck)`
  - *Order:* Value comparisons → Storage → External calls

---

### Loop Optimization
- [ ] **Loops use unchecked increment**
  - *Why:* 70.1% savings per iteration
  - *Pattern:* `unchecked { ++i; }` vs `i++`
  - *Safe:* Loop counters won't overflow

- [ ] **Pre-increment used (++i vs i++)**
  - *Why:* 5.4% savings (no temp variable)
  - *Pattern:* `for (uint i = 0; i < len; ++i)`
  - *Combine with:* Unchecked for maximum savings

- [ ] **Loop bounds cached**
  - *Why:* Avoid repeated storage reads
  - *Pattern:* `uint256 len = arr.length;` before loop
  - *Savings:* ~2,100 gas per iteration

- [ ] **Zero initialization avoided**
  - *Why:* 3.2% savings (defaults to 0)
  - *Pattern:* `uint256 i;` vs `uint256 i = 0;`
  - *Rule:* Never explicitly initialize to 0

- [ ] **No unbounded loops**
  - *Why:* Can exceed block gas limit (DoS)
  - *Solution:* Pagination, pull patterns
  - *Check:* Maximum iterations calculable

---

## 5. External Calls

### Call Safety
- [ ] **External calls use low-level call, not transfer/send**
  - *Why:* 2300 gas limit can cause failures
  - *Pattern:* `(bool success, ) = addr.call{value: amount}("");`
  - *Check:* Always verify success

- [ ] **Reentrancy guard on all functions with external calls**
  - *Why:* Primary defense against reentrancy
  - *Implementation:* OpenZeppelin ReentrancyGuard
  - *Check:* Every external call protected

- [ ] **Gas forwarding considered (avoid gas() if possible)**
  - *Why:* Can enable griefing attacks
  - *Best Practice:* Let EVM manage gas
  - *Check:* No `.gas()` in production code

- [ ] **Delegatecall only to trusted contracts**
  - *Why:* Callee can modify caller storage
  - *Rule:* Never delegatecall user input
  - *Pattern:* Whitelist of approved implementations

- [ ] **Contract existence checked before low-level call**
  - *Why:* Calls to non-contracts return success=true
  - *Tool:* `Address.isContract()` from OpenZeppelin
  - *Pattern:* Verify before critical calls

---

### Token Interactions
- [ ] **SafeERC20 library used for all ERC20 calls**
  - *Why:* Handles non-standard tokens
  - *Critical:* Prevents silent failures
  - *Methods:* safeTransfer, safeTransferFrom, safeApprove

- [ ] **Token balances checked before and after (if critical)**
  - *Why:* Handles fee-on-transfer tokens
  - *Pattern:* Record balance before/after transfer
  - *Check:* Actual received amount

- [ ] **Approve reset to 0 before new approval (if needed)**
  - *Why:* Some tokens require approve(0) first
  - *Solution:* Use `forceApprove` from SafeERC20
  - *Tokens:* USDT and others

- [ ] **No assumptions about token decimal places**
  - *Why:* Not all tokens use 18 decimals
  - *Pattern:* Call `token.decimals()` explicitly
  - *Check:* Calculations account for decimals

- [ ] **Handles tokens with fee-on-transfer**
  - *Why:* Received amount < sent amount
  - *Pattern:* Check balance delta, not transfer param
  - *Example:* Reflect tokens, Safemoon

---

## 6. State Management

### State Updates
- [ ] **State updated before external calls (CEI pattern)**
  - *Why:* Prevents reentrancy
  - *Pattern:* Checks → Effects → Interactions
  - *Check:* No state changes after external calls

- [ ] **No state modified in view/pure functions**
  - *Why:* Violates function guarantees
  - *Check:* Compiler should catch this
  - *Tool:* Static analysis

- [ ] **Events emitted for all state changes**
  - *Why:* Critical for off-chain tracking
  - *Pattern:* Emit immediately after state update
  - *Check:* Every storage write has event

- [ ] **Timestamp dependence minimized**
  - *Why:* Miners can manipulate ±15 seconds
  - *Safe:* Long periods (>15 sec tolerance)
  - *Unsafe:* Randomness, precise timing

- [ ] **Block number used instead of timestamp where applicable**
  - *Why:* More predictable than timestamp
  - *Use for:* Ordering, relative timing
  - *Note:* Block time varies by network

---

### State Consistency
- [ ] **No storage gaps in upgradeable contracts**
  - *Why:* Prevents adding state in base contracts
  - *Pattern:* `uint256[50] private __gap;`
  - *Check:* All base contracts have gaps

- [ ] **Storage layout validated before upgrades**
  - *Why:* Prevents storage corruption
  - *Tool:* OpenZeppelin Upgrades plugin
  - *Command:* `npx hardhat validate`

- [ ] **Initialization can't be called twice**
  - *Why:* Prevents reinitialization attacks
  - *Pattern:* `initializer` modifier from OZ
  - *Check:* One-time initialization enforced

- [ ] **No selfdestruct in upgradeable contracts**
  - *Why:* Can brick all proxies
  - *Rule:* Never use selfdestruct with proxies
  - *Check:* No `selfdestruct` keyword

- [ ] **No constructor in upgradeable implementation**
  - *Why:* Constructor runs on implementation, not proxy
  - *Solution:* Use `initialize()` function
  - *Pattern:* Replace constructor with initializer

---

## 7. Access Control

### Permission Management
- [ ] **Principle of least privilege applied**
  - *Why:* Minimize damage from compromise
  - *Pattern:* Minimal necessary permissions
  - *Check:* Each role has specific limited purpose

- [ ] **Admin functions can't be called by regular users**
  - *Why:* Prevent unauthorized access
  - *Check:* All admin functions have modifiers
  - *Test:* Attempt calls from non-admin accounts

- [ ] **Multisig or governance controls critical functions**
  - *Why:* Single key = single point of failure
  - *Pattern:* Gnosis Safe for admin role
  - *Check:* No EOA admin in production

- [ ] **Role assignment/revocation properly restricted**
  - *Why:* Prevent privilege escalation
  - *Pattern:* Only admin can grant roles
  - *Check:* Role management has access control

- [ ] **Ownership transfer is two-step process**
  - *Why:* Prevent accidental loss of ownership
  - *Implementation:* Ownable2Step
  - *Pattern:* Propose → Accept

---

### Authorization Logic
- [ ] **Authorization checks can't be bypassed**
  - *Why:* Core security mechanism
  - *Check:* No public functions circumventing checks
  - *Test:* Attempt unauthorized access

- [ ] **No tx.origin used for authentication**
  - *Why:* Vulnerable to phishing
  - *Rule:* Always use msg.sender
  - *Check:* Search codebase for tx.origin

- [ ] **Signature verification secure (EIP-712)**
  - *Why:* Prevents signature replay attacks
  - *Implementation:* OpenZeppelin EIP712
  - *Include:* Chain ID, contract address, nonce

- [ ] **Nonces used to prevent replay attacks**
  - *Why:* Prevent signature reuse
  - *Implementation:* OpenZeppelin Nonces
  - *Pattern:* Increment after use

- [ ] **Permit functions protected from front-running**
  - *Why:* Attacker can steal allowance
  - *Pattern:* Check allowance before use
  - *Standard:* EIP-2612 Permit

---

## 8. Tool Verification

### Static Analysis (CRITICAL)
- [ ] **Slither run with no high/critical findings**
  - *Why:* Catches common vulnerabilities automatically
  - *Command:* `slither .`
  - *Action:* Fix or document all findings

- [ ] **Mythril scan completed**
  - *Why:* Symbolic execution finds edge cases
  - *Command:* `myth analyze contract.sol`
  - *Note:* Can produce false positives

- [ ] **Solhint/Solidity linter passed**
  - *Why:* Code quality and style issues
  - *Command:* `solhint "contracts/**/*.sol"`
  - *Config:* Use security ruleset

- [ ] **Compiler warnings addressed**
  - *Why:* Warnings often indicate real issues
  - *Rule:* Zero compiler warnings
  - *Check:* `-Wall` flag enabled

---

### Testing Tools
- [ ] **Coverage reports reviewed (>90% critical code)**
  - *Why:* Untested code = unverified code
  - *Tool:* forge coverage / hardhat-coverage
  - *Target:* 100% for critical functions

- [ ] **Gas reports generated and reviewed**
  - *Why:* Identify expensive operations
  - *Tool:* hardhat-gas-reporter, forge test --gas-report
  - *Action:* Optimize high-gas functions

- [ ] **Integration tests on testnet passed**
  - *Why:* Real network conditions differ from local
  - *Networks:* Goerli, Sepolia, etc.
  - *Duration:* Run for sufficient time

- [ ] **Upgrade simulation successful (if upgradeable)**
  - *Why:* Catch upgrade issues before mainnet
  - *Tool:* OpenZeppelin Defender
  - *Test:* Full upgrade workflow

---

### Security Tools
- [ ] **Echidna/fuzzing run on critical functions**
  - *Why:* Find edge cases and invariant violations
  - *Tool:* Echidna, Foundry invariant tests
  - *Duration:* Minimum 100k runs

- [ ] **Manticore symbolic execution (if applicable)**
  - *Why:* Formal verification of properties
  - *Use for:* Critical financial logic
  - *Note:* Resource intensive

- [ ] **Formal verification for critical invariants**
  - *Why:* Mathematical proof of correctness
  - *Tools:* Certora, runtime verification
  - *Apply to:* Core financial logic

---

## 9. Pre-Deployment

### Code Finalization
- [ ] **All TODO/FIXME comments resolved**
  - *Why:* Indicates incomplete work
  - *Command:* `grep -r "TODO\|FIXME" contracts/`
  - *Rule:* Zero TODO in production

- [ ] **Dead code removed**
  - *Why:* Increases attack surface needlessly
  - *Check:* Unused functions, imports, variables
  - *Tool:* Slither detector

- [ ] **Pragma locked to specific version**
  - *Why:* Prevent unexpected compiler changes
  - *Pattern:* `pragma solidity 0.8.20;` not `^0.8.0`
  - *Check:* No floating pragmas

- [ ] **Dependencies locked to specific versions**
  - *Why:* Prevent supply chain attacks
  - *File:* package-lock.json / foundry.toml
  - *Check:* Exact versions, not ranges

- [ ] **Natspec documentation complete**
  - *Why:* Critical for auditors and users
  - *Required:* All public/external functions
  - *Include:* @param, @return, @notice, @dev

---

### Security Verification
- [ ] **Professional audit completed**
  - *Why:* Expert review finds issues you missed
  - *Timing:* After code freeze
  - *Action:* Address all findings

- [ ] **Audit recommendations implemented**
  - *Why:* Audits only useful if acted upon
  - *Track:* Document all changes
  - *Verify:* Re-audit if major changes

- [ ] **Bug bounty program prepared**
  - *Why:* Ongoing security research
  - *Platform:* Immunefi, HackerOne
  - *Timing:* Launch with or before deployment

- [ ] **Incident response plan documented**
  - *Why:* Speed crucial during attacks
  - *Include:* Contact info, pause procedures
  - *Practice:* Run tabletop exercises

- [ ] **Multisig signers verified and prepared**
  - *Why:* Critical for emergency response
  - *Check:* All signers have hardware wallets
  - *Test:* Practice transaction signing

---

### Deployment Checklist
- [ ] **Deployment script tested on testnet**
  - *Why:* Catch deployment issues safely
  - *Verify:* Same script for mainnet
  - *Check:* Contract initialization correct

- [ ] **Contract addresses verified on deployment**
  - *Why:* Ensure correct contract deployed
  - *Check:* Constructor args, owner, initial state
  - *Tool:* Foundry verify, Hardhat verify

- [ ] **Source code verified on Etherscan**
  - *Why:* Transparency and trust
  - *Command:* `hardhat verify` or manual
  - *Check:* Constructor arguments correct

- [ ] **Initial parameters validated**
  - *Why:* Wrong params can brick contract
  - *Check:* Owner address, thresholds, limits
  - *Verify:* Read contract state after deployment

- [ ] **Upgrade admin transferred to multisig**
  - *Why:* Single EOA admin = risk
  - *Timing:* Immediately after deployment
  - *Verify:* Admin role transferred successfully

---

### Post-Deployment Monitoring
- [ ] **Monitoring and alerting configured**
  - *Why:* Detect attacks in real-time
  - *Tools:* OpenZeppelin Defender, Tenderly
  - *Monitor:* Large txs, admin calls, pauses

- [ ] **Emergency contact list maintained**
  - *Why:* Fast response to incidents
  - *Include:* Team, auditors, exchanges
  - *Update:* Keep current

- [ ] **Documentation published**
  - *Why:* Users need to understand contracts
  - *Include:* Architecture, usage, risks
  - *Where:* Docs site, GitHub

- [ ] **User education materials prepared**
  - *Why:* Prevent user errors
  - *Include:* Tutorials, FAQs, warnings
  - *Example:* How to revoke approvals

---

## Critical Path Summary

**Must-do before deployment (in order):**

1. ✅ Slither + Mythril clean
2. ✅ 100% test coverage on critical functions
3. ✅ All high/critical severity findings addressed
4. ✅ Access control tested and verified
5. ✅ Professional audit completed and findings addressed
6. ✅ Testnet deployment and testing
7. ✅ Source code verified on block explorer
8. ✅ Admin keys secured (multisig/governance)
9. ✅ Monitoring and alerting active
10. ✅ Incident response plan documented

---

## Common Vulnerabilities Quick Check

| Vulnerability | Checked? | Prevention |
|--------------|----------|------------|
| Reentrancy | [ ] | nonReentrant + CEI pattern |
| Access Control | [ ] | onlyOwner/onlyRole modifiers |
| Integer Overflow | [ ] | Solidity 0.8+ or SafeMath |
| Unchecked Calls | [ ] | Verify return values |
| tx.origin Auth | [ ] | Use msg.sender only |
| DoS with Revert | [ ] | Pull-over-push pattern |
| Timestamp Manipulation | [ ] | Use block.number or tolerance |
| Delegatecall | [ ] | Whitelist targets only |
| Signature Replay | [ ] | Nonces + EIP-712 |
| Uninitialized Storage | [ ] | Initialize all variables |
| Storage Collision | [ ] | Correct inheritance order |
| Frontrunning | [ ] | Commit-reveal or MEV protection |

---

## Resources

### Security References
- **ConsenSys Best Practices**: https://consensys.github.io/smart-contract-best-practices/
- **SWC Registry**: https://swcregistry.io/
- **OpenZeppelin Security**: https://docs.openzeppelin.com/contracts/5.x/api/security
- **Rekt News**: https://rekt.news/ (learn from hacks)

### Tools
- **Slither**: https://github.com/crytic/slither
- **Mythril**: https://github.com/ConsenSys/mythril
- **Echidna**: https://github.com/crytic/echidna
- **Foundry**: https://book.getfoundry.sh/
- **Hardhat**: https://hardhat.org/

### Audit Firms
- Trail of Bits
- OpenZeppelin
- Consensys Diligence
- Certora
- Runtime Verification

---

## Final Sign-Off

**Before deploying to mainnet:**

| Checkpoint | Completed | Verified By | Date |
|-----------|-----------|-------------|------|
| Code security checks | [ ] | __________ | ____ |
| Test coverage >90% | [ ] | __________ | ____ |
| Design review | [ ] | __________ | ____ |
| Gas optimization | [ ] | __________ | ____ |
| Static analysis clean | [ ] | __________ | ____ |
| Professional audit | [ ] | __________ | ____ |
| Testnet deployment | [ ] | __________ | ____ |
| Documentation complete | [ ] | __________ | ____ |
| Multisig configured | [ ] | __________ | ____ |
| Monitoring active | [ ] | __________ | ____ |

**Deployment Authorization:**
- Lead Developer: _________________ Date: _______
- Security Lead: _________________ Date: _______
- Project Manager: _________________ Date: _______

---

**Remember:** This checklist is a starting point. Every project has unique risks. Always perform custom security analysis based on your specific contract functionality and threat model.

**When in doubt, pause deployment and get another review.**
