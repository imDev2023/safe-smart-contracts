# Pre-Deployment Security Checklist

Comprehensive checklist for verifying contract security before mainnet deployment. Use this to ensure nothing is missed.

**Status:** START [ ] | STEP 1 [ ] | STEP 2 [ ] | STEP 3 [ ] | READY TO DEPLOY [ ]

---

## Pre-Deployment Timeline

- **T-14 days:** Final design review, all decisions made
- **T-10 days:** Code freeze, no new features
- **T-7 days:** Automated tool results (Slither, Mythril)
- **T-5 days:** Manual security audit complete
- **T-3 days:** All critical/high issues fixed and tested
- **T-1 day:** Final verification, all approvals
- **T-0 hours:** Deployment to mainnet
- **T+24 hours:** Post-deployment verification

---

## Step 1: Code Quality Audit (40 checks)

### Formatting & Cleanliness
- [ ] No `console.log()` statements present
- [ ] No commented-out code
- [ ] No TODO or FIXME comments (document properly or fix)
- [ ] No debug statements
- [ ] Code is properly formatted (ran prettier/solhint)
- [ ] Proper indentation throughout
- [ ] Consistent naming conventions (camelCase, UPPER_CASE)
- [ ] No unused imports
- [ ] No unused variables or functions
- [ ] No duplicate code

### Solidity Standards
- [ ] `pragma solidity` version locked (not `^` or `~`)
- [ ] Recommended: `pragma solidity 0.8.20;` (latest stable)
- [ ] All warnings from compiler addressed
- [ ] SPDX license identifier present on all files
- [ ] Solc optimization flag enabled
- [ ] Solc optimizer runs set appropriately

### Comments & Documentation
- [ ] All public functions have NatSpec documentation
- [ ] All external functions have NatSpec documentation
- [ ] Complex logic has explanatory comments
- [ ] Comments are accurate (not outdated)
- [ ] @notice, @dev, @param, @return tags used
- [ ] No misleading or incorrect comments

### Structure & Architecture
- [ ] State variables logically grouped
- [ ] Constants defined (not magic numbers)
- [ ] Immutable variables used where appropriate
- [ ] Storage layout optimized (packed)
- [ ] No unnecessary inheritance
- [ ] Functions ordered logically (external, public, internal, private)
- [ ] Constructor sets all necessary initial state
- [ ] Fallback function (if needed) properly designed

### Imports & Dependencies
- [ ] All imports are necessary
- [ ] Correct versions of OpenZeppelin imported
- [ ] No circular imports
- [ ] External dependencies documented
- [ ] Version constraints reasonable

**Checklist Result:** [ ] PASS [ ] FAIL (fix before proceeding)

---

## Step 2: Security Audit (100+ checks)

### Access Control (15 checks)
- [ ] All state-changing functions have access control
- [ ] `constructor()` initializes access control properly
- [ ] `onlyOwner`/`onlyRole` modifiers used correctly
- [ ] No functions accidentally public
- [ ] Admin functions properly restricted
- [ ] Emergency pause properly restricted
- [ ] No privilege escalation paths
- [ ] Role hierarchy makes sense
- [ ] Correct roles assigned to correct addresses
- [ ] Owner/admin address not zero address
- [ ] Multi-sig (if used) properly configured
- [ ] Two-step ownership transfer (if using Ownable)
- [ ] Role admin correctly set (if using AccessControl)
- [ ] Cannot renounce critical roles
- [ ] Access control tested with multiple accounts

### Reentrancy Protection (10 checks)
- [ ] All external contract calls identified
- [ ] Checks-effects-interactions pattern followed, OR
- [ ] `nonReentrant` modifier applied
- [ ] State updates happen before external calls
- [ ] External calls not in loops
- [ ] Protocol state consistent if call fails
- [ ] Reentrancy test cases pass
- [ ] Cross-function reentrancy considered
- [ ] No delegate calls to untrusted contracts
- [ ] Reentrancy tests in test suite

### Input Validation (12 checks)
- [ ] Zero address checks: `require(addr != address(0))`
- [ ] Zero amount checks: `require(amount > 0)`
- [ ] Maximum value checks: `require(amount <= MAX_VALUE)`
- [ ] Valid enum checks
- [ ] String length checks (if using strings)
- [ ] Array length checks
- [ ] Balance/allowance checks before transfers
- [ ] Timestamp checks reasonable (not too strict)
- [ ] Percentage checks (0-100)
- [ ] Index bounds checks
- [ ] No off-by-one errors
- [ ] All require statements have messages (or custom errors)

### Arithmetic & Math (10 checks)
- [ ] Using Solidity 0.8+ (checked overflow/underflow)
- [ ] `unchecked` only used where safe (loops, loop counters)
- [ ] Division by zero impossible: `require(divisor != 0)`
- [ ] SafeMath not needed in 0.8+ (but used for clarity if desired)
- [ ] Precision loss in division considered and documented
- [ ] Integer division rounding direction intentional
- [ ] Large number multiplication safe from overflow
- [ ] Percentage calculations precise enough
- [ ] No loss of precision due to order of operations
- [ ] Random number generation (if used) not compromised

### Token Transfers (10 checks)
- [ ] `SafeERC20` used for all ERC20 transfers
- [ ] `token.safeTransfer()` or `safeTransferFrom()` used
- [ ] Return values checked (or using SafeERC20)
- [ ] ETH transfers use `call()` not `transfer()` or `send()`
- [ ] Proper error handling for failed transfers
- [ ] No reentrancy during token transfers
- [ ] Token approvals properly managed
- [ ] Allowance underflow not possible (checked before use)
- [ ] Both ETH and token scenarios tested
- [ ] Token interactions on correct network

### State Management (12 checks)
- [ ] State variables initialized in constructor or initializer
- [ ] Immutable variables set once, not modified
- [ ] No use of deprecated storage patterns
- [ ] Storage layout preserved for upgradeable contracts
- [ ] Storage gaps added for upgradeability
- [ ] State transitions valid (state machine correct)
- [ ] No dead code or unreachable states
- [ ] Race conditions considered
- [ ] Concurrent action consistency verified
- [ ] Initialization idempotent (safe to call multiple times)
- [ ] State doesn't contradict (mutual exclusivity where needed)
- [ ] Clearing state when contracts pause/stop

### External Calls (12 checks)
- [ ] All external contracts identified
- [ ] External call targets validated (not user-supplied)
- [ ] Return values from external calls checked
- [ ] Low-level calls wrapped in try-catch or checked
- [ ] External call sequence logical (dependent calls ordered)
- [ ] Re-entrancy risks from external calls mitigated
- [ ] Calls not in loops (or loop size bounded)
- [ ] Gas limits appropriate for calls
- [ ] Timeout/deadline checks for cross-chain calls
- [ ] External contract addresses not zero
- [ ] External contract interfaces validated
- [ ] Delegatecall only to trusted code

### Event Logging (8 checks)
- [ ] Emit event for all state changes
- [ ] Event parameters indexed correctly (searchable)
- [ ] All important parameters logged
- [ ] Indexed fields are value types or bytes32
- [ ] Events match contract specification
- [ ] No sensitive data in events (visible on blockchain)
- [ ] Event emission happens after state change (for atomicity)
- [ ] Off-chain monitoring possible (events sufficient)

### Pausable/Emergency (8 checks)
- [ ] `Pausable` used (recommended for critical contracts)
- [ ] `whenNotPaused` modifier applied appropriately
- [ ] Only designated accounts can pause
- [ ] Emergency withdrawal available when paused
- [ ] Owner can unpause
- [ ] Users don't lose funds when paused
- [ ] Pause events logged
- [ ] Pause mechanism tested

### Upgradeability (10 checks, if upgradeable)
- [ ] Using UUPS or Transparent Proxy pattern
- [ ] Initializer function (not constructor) used
- [ ] Storage gap added (47 slots for future vars)
- [ ] Storage variables never deleted (only added)
- [ ] Storage layout compatible with previous version
- [ ] Upgrade restricted to authorized account
- [ ] No storage collisions from inheritance
- [ ] Version tracking implemented
- [ ] Upgrade tests included
- [ ] Rollback plan documented

### Type Safety (8 checks)
- [ ] Correct data types used (uint256, not uint)
- [ ] Type conversions explicit and safe
- [ ] No unsafe casting
- [ ] Enum values validated
- [ ] Byte arrays sized correctly
- [ ] String operations safe
- [ ] No implicit conversions
- [ ] SafeCast used for type downcasts

### Constants & Configuration (8 checks)
- [ ] Magic numbers extracted to constants
- [ ] Constants properly named (UPPER_CASE)
- [ ] Constants marked `constant` or `immutable`
- [ ] Configurable parameters in constructor
- [ ] Reasonable default values
- [ ] Parameter bounds documented
- [ ] No runtime parameter changes without authorization
- [ ] Critical constants verified

**Checklist Result:** [ ] PASS [ ] FAIL (fix before proceeding)

---

## Step 3: Vulnerability Checklist (Top 10)

Reference: `knowledge-base-action/03-attack-prevention/`

### 1. Reentrancy Protection
- [ ] All external calls are **after** state updates (checks-effects-interactions)
- [ ] OR `nonReentrant` modifier applied to vulnerable functions
- [ ] Read-only reentrancy not a problem (only state-changing calls risky)
- [ ] Test: `03-attack-prevention/reentrancy.md`

### 2. Access Control
- [ ] Admin-only functions have proper modifiers
- [ ] No public functions that should be restricted
- [ ] Default visibility not used for functions
- [ ] Ownable or AccessControl properly configured
- [ ] Test: `03-attack-prevention/access-control.md`

### 3. Integer Overflow/Underflow
- [ ] Using Solidity 0.8+ (automatic overflow checks)
- [ ] Unchecked blocks only used for loop counters
- [ ] No downcast without bounds checking (if downcasting)
- [ ] Edge cases (min, max values) tested
- [ ] Test: `03-attack-prevention/integer-overflow.md`

### 4. Front-Running/MEV
- [ ] No function depending on transaction ordering
- [ ] Atomic swaps not vulnerable to sandwich attacks
- [ ] Oracle prices not manipulable by same transaction
- [ ] Signature expiry/deadline checks present
- [ ] Test: `03-attack-prevention/frontrunning.md`

### 5. Denial of Service (DoS)
- [ ] No unbounded loops (loops bounded or off-chain)
- [ ] No external calls in loops (or small bounded loops)
- [ ] No array growth without limits
- [ ] No revert-based DoS (pull over push pattern)
- [ ] Test: `03-attack-prevention/dos-attacks.md`

### 6. Timestamp Dependence
- [ ] Block timestamp only used for rough timing, not critical logic
- [ ] Randomness not based on block.timestamp
- [ ] Chainlink VRF or equivalent used for randomness
- [ ] Block number used instead of timestamp where possible
- [ ] Test: `03-attack-prevention/timestamp-dependence.md`

### 7. Unsafe Delegatecall
- [ ] No delegatecall to untrusted contracts
- [ ] Only delegatecall to trusted/audited contracts
- [ ] Storage layout preserved across upgrades
- [ ] Proxy pattern correctly implemented
- [ ] Test: `03-attack-prevention/unsafe-delegatecall.md`

### 8. Unchecked Return Values
- [ ] All external call return values checked
- [ ] SafeERC20 used for all token transfers
- [ ] Low-level call results checked
- [ ] No silent failures
- [ ] Test: `03-attack-prevention/unchecked-returns.md`

### 9. tx.origin Usage
- [ ] tx.origin never used for authentication
- [ ] msg.sender used instead
- [ ] Contracts can safely call your contract (no phishing risk)
- [ ] Test: `03-attack-prevention/tx-origin.md`

### 10. Flash Loan Attacks
- [ ] Not vulnerable to flash loans (if relevant)
- [ ] Price oracles use TWAP, not spot price
- [ ] Multiple block checks for state changes
- [ ] No single-block arbitrage
- [ ] Test: `03-attack-prevention/flash-loan-attacks.md`

**Checklist Result:** [ ] PASS [ ] FAIL (fix before proceeding)

---

## Step 4: Test Coverage Verification (20 checks)

- [ ] Overall code coverage >95%
- [ ] All functions have test cases
- [ ] All branches tested (if/else cases)
- [ ] Happy path tested (normal use cases)
- [ ] Error paths tested (require statements)
- [ ] Edge cases tested (0, 1, MAX_VALUE)
- [ ] Boundary conditions tested
- [ ] Access control tested with multiple roles
- [ ] State transitions tested
- [ ] Event emission tested
- [ ] Event indexed parameters searchable
- [ ] Reentrancy scenarios tested
- [ ] Integration tests pass
- [ ] Mainnet fork tests pass (if applicable)
- [ ] Stress tests pass (high volume)
- [ ] Gas estimates recorded
- [ ] Performance acceptable
- [ ] Fuzzing tests pass (Echidna, if used)
- [ ] All test suites passing
- [ ] Code coverage report generated

```bash
# Generate and review coverage
npx hardhat coverage
# Target: > 95% line coverage
```

**Checklist Result:** [ ] PASS [ ] FAIL (fix before proceeding)

---

## Step 5: Gas Analysis (15 checks)

- [ ] Gas profiling completed: `forge test --gas-report`
- [ ] High-impact optimizations applied (>1000 gas)
- [ ] Custom errors used instead of require strings
- [ ] Unchecked loops applied (where safe)
- [ ] Immutable constants used
- [ ] Storage variables packed
- [ ] Events used instead of storage logging
- [ ] Function visibility optimized
- [ ] Pre-increment used (++i not i++)
- [ ] Gas costs documented
- [ ] Deployment gas cost acceptable
- [ ] Transaction gas cost acceptable
- [ ] Storage operations minimized
- [ ] Memory operations optimized
- [ ] No unnecessary state reads

See: `01-quick-reference/gas-optimization-wins.md`

**Checklist Result:** [ ] PASS [ ] PASS-WITH-NOTES [ ] FAIL

---

## Step 6: Automated Tool Results (15 checks)

### Slither (Required)
```bash
pip install slither-analyzer
slither . --json report.json
```

- [ ] Slither installed and run successfully
- [ ] All high/critical issues resolved
- [ ] Medium issues reviewed and documented
- [ ] False positives documented
- [ ] No ignored warnings
- [ ] Configuration file reviewed

### Mythril (Recommended for critical contracts)
```bash
pip install mythril
myth analyze contracts/*.sol
```

- [ ] Mythril analysis run (if applicable)
- [ ] Results reviewed
- [ ] Issues resolved or documented

### Solc Warnings
```bash
solc --version
solc contracts/*.sol
```

- [ ] No compiler warnings
- [ ] All warnings addressed or suppressed with comments
- [ ] Suppression reasons documented

### Code Style (Optional)
```bash
npx solhint contracts/**/*.sol
npx prettier --check contracts/**/*.sol
```

- [ ] Linting passes (solhint)
- [ ] Formatting consistent (prettier)

**Checklist Result:** [ ] PASS [ ] PASS-WITH-REVIEW [ ] FAIL

---

## Step 7: Deployment Configuration (25 checks)

### Network & Chain
- [ ] Correct network selected (Mainnet, not testnet)
- [ ] Chain ID verified
- [ ] RPC endpoint tested and working
- [ ] Block explorers identified and ready
- [ ] Network gas prices checked

### Deployment Parameters
- [ ] All constructor parameters prepared
- [ ] Initial state values correct
- [ ] Admin address verified (not test address)
- [ ] Significant addresses verified (not zero address)
- [ ] Initial supply/permissions set correctly
- [ ] No hardcoded testnet values
- [ ] No test private keys in code

### Deployment Account
- [ ] Deployer account identified
- [ ] Account funded with sufficient ETH
  - Estimate: (gas * gwei) + buffer
  - Example: 5M gas * 50 gwei = 0.25 ETH + 0.1 ETH buffer = 0.35 ETH
- [ ] Private key secured (hardware wallet preferred)
- [ ] Account has no other pending transactions
- [ ] Account address correct (not typo)

### Upgrade Configuration (if upgradeable)
- [ ] Proxy owner identified
- [ ] Upgrade authority set
- [ ] Timelock (if using) configured
- [ ] Upgrade delay set appropriately
- [ ] Version tracking initialized

### Configuration Files
- [ ] `.env` file correct (not committed)
- [ ] Hardhat config correct (network, signer)
- [ ] Deployment script tested on testnet
- [ ] Deployment script final and reviewed
- [ ] No debugging code in script

**Checklist Result:** [ ] PASS [ ] FAIL

---

## Step 8: Pre-Deployment Execution (20 checks)

### Local Testing
- [ ] Full test suite passes locally
- [ ] Gas report generated and reviewed
- [ ] No compilation warnings
- [ ] Hardhat/Foundry clean build succeeds

### Testnet Deployment
- [ ] Contract deploys to testnet successfully
- [ ] Constructor parameters correct
- [ ] Initial state verified
- [ ] All functions callable
- [ ] Access control working (test multiple roles)
- [ ] Pausable works (if applicable)
- [ ] Events emit correctly
- [ ] Token transfers work (if applicable)
- [ ] Contract verified on testnet block explorer
- [ ] No console logs visible

### Smoke Tests
- [ ] Core functionality works on testnet
- [ ] Emergency functions accessible
- [ ] Pause mechanism works
- [ ] Upgrade works (if applicable)
- [ ] Multi-sig works (if applicable)

### Review & Approval
- [ ] Code review completed and approved
- [ ] Security review completed and approved
- [ ] Testnet deployment verified
- [ ] Team sign-off obtained
- [ ] Final checklist review passed

**Checklist Result:** [ ] READY [ ] ISSUES-FOUND-FIX-FIRST

---

## Step 9: Monitoring Setup (10 checks)

Before deployment, prepare monitoring:

- [ ] Monitoring dashboard created
- [ ] Alert rules configured
  - Contract deployment alert
  - Function call monitoring
  - Error/revert monitoring
  - Event monitoring
  - Gas usage alerts
- [ ] Log aggregation set up (if using)
- [ ] On-call schedule established
- [ ] Incident response plan documented
- [ ] Rollback procedure documented and tested
- [ ] Emergency contacts list prepared
- [ ] Status page ready (if public service)

---

## Step 10: Deployment Day (15 checks)

### Pre-Deployment
- [ ] Team on standby
- [ ] Deployment account funded
- [ ] Deployment script ready and tested
- [ ] Network conditions reasonable (not during high congestion)
- [ ] Final code hash matches reviewed code
- [ ] No last-minute changes (code freeze)
- [ ] Communication channel open (Discord/Slack)

### Deployment
- [ ] Transaction submitted
- [ ] Transaction hash recorded
- [ ] Monitor for transaction confirmation
- [ ] Verify deployment on block explorer
- [ ] Contract address recorded
- [ ] Initial state verified
- [ ] First transactions test core functionality

### Post-Deployment
- [ ] Contract verified on Etherscan
- [ ] Monitoring active and alerting
- [ ] No errors in first hour
- [ ] Team continues monitoring (24 hours minimum)
- [ ] Documentation updated with contract address

**Deployment Status:** [ ] PENDING [ ] IN-PROGRESS [ ] COMPLETE

---

## Sign-Off Section

### Code Review Approval
- **Reviewer:** ____________________
- **Date:** ____________________
- **Notes:** ____________________________________________________

### Security Review Approval
- **Auditor:** ____________________
- **Date:** ____________________
- **Notes:** ____________________________________________________

### Product Approval
- **Product Lead:** ____________________
- **Date:** ____________________
- **Notes:** ____________________________________________________

### Legal/Compliance (if applicable)
- **Approver:** ____________________
- **Date:** ____________________
- **Notes:** ____________________________________________________

### Final Deployment Authorization
- **Authorized By:** ____________________
- **Date:** ____________________
- **Time:** ____________________
- **Contract Address:** ____________________

---

## Escalation & Issues Log

### Critical Issues Found (Stop Deployment)
| Issue | Severity | Status | Resolution | Date |
|-------|----------|--------|-----------|------|
| | | | | |

### High-Severity Issues (Fix Before Deployment)
| Issue | Severity | Status | Resolution | Date |
|-------|----------|--------|-----------|------|
| | | | | |

### Medium/Low Issues (Can Deploy With Mitigation)
| Issue | Severity | Status | Mitigation | Date |
|-------|----------|--------|-----------|------|
| | | | | |

---

## Deployment Summary

- **Contract Name:** ____________________
- **Network:** ____________________
- **Deployment Date:** ____________________
- **Contract Address:** ____________________
- **Deployer Address:** ____________________
- **Deployment Transaction:** ____________________
- **Code Coverage:** ____% (target >95%)
- **All Tests Passing:** [ ] YES [ ] NO
- **Security Audit:** [ ] PASSED [ ] PASSED-WITH-NOTES [ ] FAILED
- **Ready for Mainnet:** [ ] YES [ ] NO

---

## Post-Deployment Monitoring (24 hours)

- [ ] No error logs
- [ ] Normal transaction volumes
- [ ] Gas usage as expected
- [ ] No security alerts
- [ ] No unusual activity
- [ ] All external integrations working
- [ ] Oracle feeds working (if applicable)
- [ ] No reported issues from users
- [ ] Team satisfaction with deployment

**24-Hour Sign-Off:** [ ] APPROVED [ ] ISSUES-FOUND

---

## Resources

- **Development Guide:** `contract-development.md`
- **Quick Reference:** `01-quick-reference/security-checklist.md`
- **Vulnerabilities:** `03-attack-prevention/[vulnerability].md`
- **Code Snippets:** `04-code-snippets/`
- **Templates:** `02-contract-templates/`
- **Gas Optimization:** `01-quick-reference/gas-optimization-wins.md`

---

**Remember:** A delayed deployment due to security is better than a fast deployment with a hack.

Use this checklist every time before mainnet deployment!
