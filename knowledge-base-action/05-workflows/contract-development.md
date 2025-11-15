# Smart Contract Development Workflow

A step-by-step guide for developing secure smart contracts from specification through testing.

**Table of Contents**
1. [Phase 1: Planning & Design](#phase-1-planning--design)
2. [Phase 2: Architecture](#phase-2-architecture)
3. [Phase 3: Implementation](#phase-3-implementation)
4. [Phase 4: Testing](#phase-4-testing)
5. [Phase 5: Security Review](#phase-5-security-review)
6. [Phase 6: Optimization](#phase-6-optimization)
7. [Phase 7: Final Testing](#phase-7-final-testing)
8. [Phase 8: Documentation](#phase-8-documentation)
9. [Decision Trees](#decision-trees)
10. [Common Pitfalls](#common-pitfalls)

---

## Phase 1: Planning & Design
**Duration:** 1-2 days | **Deliverables:** Design document, architecture sketch | **Go/No-Go:** Design review sign-off

### 1.1 Specification
Define what the contract does:
- [ ] Core functionality list (3-5 main features)
- [ ] User roles and interactions
- [ ] Token types and economics
- [ ] Integration points with other contracts
- [ ] Expected transaction volume
- [ ] Success criteria and KPIs

### 1.2 State Design
Plan the data structures:
- [ ] List all state variables needed
- [ ] Define storage layout (consider packing)
- [ ] Identify mutable vs immutable data
- [ ] Plan for upgradeable contracts (storage gaps)
- [ ] Define initial state values

### 1.3 Access Control Design
Plan permissions:
- [ ] Who can call each function? (roles)
- [ ] Do you need role hierarchy?
- [ ] Is single-owner sufficient (Ownable) or need RBAC (AccessControl)?
- [ ] Emergency pause capabilities needed?
- [ ] Multi-sig admin control needed?

### 1.4 External Dependencies
Identify external contracts:
- [ ] ERC20 tokens needed?
- [ ] Oracle dependencies?
- [ ] Chainlink VRF or other services?
- [ ] Cross-chain interactions?
- [ ] Risk: Each external call is a security risk

**Decision:** If using tokens → Reference `ERC20` template, if governance → Reference `AccessControl` template

### 1.5 Pattern Selection
Choose relevant patterns early:
- [ ] Reentrancy protection needed? → Use Checks-Effects-Interactions pattern
- [ ] Access control? → Ownable or AccessControl pattern
- [ ] Emergency stop? → Pausable/Circuit Breaker pattern
- [ ] Upgradeable? → Proxy Delegate or UUPS pattern
- [ ] Staking/rewards? → Pull over Push pattern

See: `knowledge-base-action/01-quick-reference/pattern-catalog.md`

### 1.6 Design Review Checklist
- [ ] Requirements clear and measurable?
- [ ] State design sound (no missing variables)?
- [ ] Access control strategy appropriate?
- [ ] External dependencies minimized?
- [ ] Patterns selected are well-understood by team?
- [ ] Similar existing contracts reviewed for reference?
- [ ] Team agrees on design? (sign-off)

---

## Phase 2: Architecture
**Duration:** 1-2 days | **Deliverables:** Architecture document, contract list | **Go/No-Go:** Architecture approval

### 2.1 Contract Structure
Define contract decomposition:
- [ ] Is a single contract or multiple contracts better?
- [ ] Should core logic separate from token logic?
- [ ] Admin/upgrade contract separate?
- [ ] Create ASCII architecture diagram
- [ ] List each contract's responsibilities

**Example:**
```
Main Contract (business logic)
  ↓
Token Contract (ERC20)
  ↓
Admin Contract (AccessControl, Pausable)
```

### 2.2 Upgrade Strategy
Decide on upgradeability:
- [ ] Is contract upgradeable? (usually yes for safety)
- [ ] If yes: UUPS or Transparent Proxy?
- [ ] Storage layout implications (need storage gaps)
- [ ] Who controls upgrades? (owner, multisig, governance)
- [ ] Upgrade frequency plan

See: `02-contract-templates/upgradeable-template.sol`

### 2.3 Events & Monitoring
Plan event logging:
- [ ] List all important state changes
- [ ] Create event signatures (which params to index?)
- [ ] Off-chain indexing strategy (The Graph, etc.)
- [ ] Monitoring/alerting rules

See: `04-code-snippets/events.md`

### 2.4 OpenZeppelin Integration
Select OZ contracts to inherit from:
- [ ] Tokens: ERC20, ERC721, ERC1155?
- [ ] Security: ReentrancyGuard, Pausable?
- [ ] Access: Ownable, AccessControl?
- [ ] Utilities: SafeERC20, Address?

See: `04-code-snippets/oz-imports.md`

### 2.5 Test Scenario Planning
Plan testing approach:
- [ ] Happy path scenarios (5-10 main flows)
- [ ] Attack scenarios (test each vulnerability)
- [ ] Edge cases (min/max values, boundary conditions)
- [ ] Integration scenarios (contract interactions)
- [ ] Gas scenarios (high volume, stress test)

### 2.6 Template Selection
Choose starting templates:
- ERC20 token? → Use `02-contract-templates/secure-erc20.sol`
- NFT contract? → Use `02-contract-templates/secure-erc721.sol`
- Access control? → Use `02-contract-templates/access-control-template.sol`
- Upgradeable? → Use `02-contract-templates/upgradeable-template.sol`
- Staking? → Use `02-contract-templates/staking-template.sol`
- Emergency stop? → Use `02-contract-templates/pausable-template.sol`

### 2.7 Architecture Review Checklist
- [ ] Contract structure clear and documented?
- [ ] Upgrade strategy decided and reasonable?
- [ ] Events cover all important state changes?
- [ ] OZ contracts selected appropriately?
- [ ] Test plan comprehensive?
- [ ] Team agrees on architecture? (sign-off)

---

## Phase 3: Implementation
**Duration:** 3-5 days | **Deliverables:** Working code, passing unit tests | **Go/No-Go:** Code review

### 3.1 Setup Development Environment
```bash
# Option 1: Hardhat
npm init -y
npm install --save-dev hardhat @openzeppelin/contracts

# Option 2: Foundry
curl -L https://foundry.paradigm.xyz | bash
```

- [ ] Solidity version locked (0.8.20 recommended)
- [ ] Development dependencies installed
- [ ] Project structure set up
- [ ] .gitignore configured

### 3.2 Implement Core Functionality
Start with basic contract structure:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyContract is Ownable, ReentrancyGuard {
    // State variables
    uint256 public constant MAX_SUPPLY = 1000;

    // Events
    event ActionPerformed(address indexed user, uint256 amount);

    // Custom errors
    error ExceedsMaxSupply();
    error InvalidAmount();

    // Initialization
    constructor() {}

    // Core functions
    function coreFunction(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert InvalidAmount();
        // Implementation
        emit ActionPerformed(msg.sender, amount);
    }
}
```

**Checklist for each function:**
- [ ] Clear, documented purpose (NatSpec)
- [ ] Input validation (zero checks, bounds)
- [ ] Access control applied (modifier)
- [ ] State changes before external calls (checks-effects-interactions)
- [ ] Event emission for important changes
- [ ] Return value or revert on failure

### 3.3 Add Access Control
Implement permissions:
```solidity
// Simple approach (single owner)
function adminFunction() external onlyOwner {
    // Admin-only logic
}

// Complex approach (RBAC)
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function adminFunction() external onlyRole(ADMIN_ROLE) {
        // Admin-only logic
    }
}
```

See: `02-contract-templates/access-control-template.sol`

### 3.4 Add Security Patterns
Apply protections:

**Reentrancy Protection:**
```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyContract is ReentrancyGuard {
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;  // Effect before interaction
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);  // Interaction last
    }
}
```

**Pausable for Emergency:**
```solidity
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract MyContract is Pausable, Ownable {
    function normalFunction() external whenNotPaused {
        // Paused during emergencies
    }

    function pause() external onlyOwner {
        _pause();
    }
}
```

**SafeERC20 for Tokens:**
```solidity
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyContract {
    using SafeERC20 for IERC20;

    function transferTokens(IERC20 token, address to, uint256 amount) external {
        // Safe transfer that handles return values
        token.safeTransfer(to, amount);
    }
}
```

See: `03-attack-prevention/` guides for pattern details

### 3.5 Add Error Handling
Use custom errors instead of require strings (gas efficient):
```solidity
// Bad: Uses string (stores error message)
require(amount > 0, "Amount must be positive");  // ~140 gas

// Good: Uses custom error (31 gas)
error InvalidAmount();
if (amount == 0) revert InvalidAmount();
```

See: `04-code-snippets/errors.md` for complete list

### 3.6 Add Events
Emit for all important state changes:
```solidity
event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);

function withdraw(uint256 amount) external {
    balances[msg.sender] -= amount;
    emit Withdrawal(msg.sender, amount, block.timestamp);
    // Then external call
}
```

See: `04-code-snippets/events.md` for event patterns

### 3.7 Add NatSpec Documentation
Document all public/external functions:
```solidity
/// @notice Withdraws tokens from the contract
/// @dev Uses checks-effects-interactions pattern for reentrancy safety
/// @param amount The amount of tokens to withdraw
/// @return success True if withdrawal succeeded
function withdraw(uint256 amount) external returns (bool success) {
    // Implementation
}
```

### 3.8 Apply Gas Optimizations
Incorporate optimization opportunities:
- [ ] Use custom errors instead of require strings (~100 gas per error)
- [ ] Use unchecked for loops (when safe) (~200 gas per loop)
- [ ] Use immutable for constants (~2,000 gas first read)
- [ ] Pack storage variables (~2,000 gas per slot saved)
- [ ] Use events instead of storage for logs (~21,000 gas per log)

See: `01-quick-reference/gas-optimization-wins.md`

### 3.9 Code Quality Checklist
- [ ] No console.log statements
- [ ] No hardcoded addresses (use constructor params)
- [ ] No debugging code
- [ ] All imports necessary
- [ ] No unused variables or imports
- [ ] Consistent naming (camelCase for functions, UPPER_CASE for constants)
- [ ] Comments for complex logic
- [ ] Version pragma locked: `pragma solidity 0.8.20;`

---

## Phase 4: Testing
**Duration:** 3-5 days | **Deliverables:** 95%+ test coverage, all tests passing | **Go/No-Go:** Test report

### 4.1 Unit Tests
Test each function independently:

**Hardhat/Ethers Example:**
```javascript
describe("MyContract", function() {
    let contract, owner, user;

    beforeEach(async function() {
        [owner, user] = await ethers.getSigners();
        const MyContract = await ethers.getContractFactory("MyContract");
        contract = await MyContract.deploy();
    });

    describe("withdraw", function() {
        it("Should withdraw correct amount", async function() {
            await contract.connect(owner).deposit({value: ethers.parseEther("1")});
            const balance = await ethers.provider.getBalance(contract.address);
            expect(balance).to.equal(ethers.parseEther("1"));
        });

        it("Should revert on zero amount", async function() {
            await expect(contract.withdraw(0)).to.be.revertedWithCustomError(contract, "InvalidAmount");
        });
    });
});
```

**Foundry Example:**
```solidity
contract MyContractTest is Test {
    MyContract contract;
    address user;

    function setUp() public {
        contract = new MyContract();
        user = address(0x1);
    }

    function testWithdraw() public {
        vm.prank(user);
        contract.deposit{value: 1 ether}();

        uint256 balance = address(contract).balance;
        assertEq(balance, 1 ether);
    }

    function testWithdrawRevertOnZeroAmount() public {
        vm.expectRevert(MyContract.InvalidAmount.selector);
        contract.withdraw(0);
    }
}
```

### 4.2 Integration Tests
Test contract interactions:
- [ ] Contract A calls Contract B
- [ ] Token transfers work
- [ ] Multiple users interacting
- [ ] State consistency across calls

### 4.3 Attack Scenario Tests
Test for vulnerabilities:
```javascript
describe("Security", function() {
    it("Should protect against reentrancy", async function() {
        // Simulate reentrancy attack
        const AttackContract = await ethers.getContractFactory("ReentrancyAttack");
        const attack = await AttackContract.deploy(contract.address);

        // Should revert or prevent reentrancy
        await expect(attack.attack()).to.be.reverted;
    });

    it("Should enforce access control", async function() {
        // Non-admin cannot call admin function
        await expect(contract.connect(user).adminFunction()).to.be.revertedWithCustomError(
            contract,
            "Unauthorized"
        );
    });
});
```

See: `03-attack-prevention/` guides for test examples

### 4.4 Edge Case Testing
- [ ] Minimum values (0, 1)
- [ ] Maximum values (type limits)
- [ ] Boundary conditions
- [ ] Off-by-one errors
- [ ] Integer overflow/underflow

### 4.5 Gas Estimation
Measure gas costs:
```javascript
// Hardhat
const tx = await contract.withdraw(amount);
const receipt = await tx.wait();
console.log(`Gas used: ${receipt.gasUsed}`);

// Foundry
forge test --gas-report
```

### 4.6 Coverage Requirement
- [ ] Aim for 95%+ line coverage
- [ ] All functions tested
- [ ] All branches tested
- [ ] Both success and failure paths

```bash
# Generate coverage report
npx hardhat coverage
# or
forge coverage
```

### 4.7 Testing Checklist
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All attack scenarios tested
- [ ] 95%+ code coverage
- [ ] Gas estimates documented
- [ ] Edge cases covered
- [ ] Mainnet fork tests pass (if needed)

---

## Phase 5: Security Review
**Duration:** 2-3 days | **Deliverables:** Security audit report, issues fixed | **Go/No-Go:** Security sign-off

### 5.1 Manual Code Review

**Reviewers should check:**
- [ ] All functions have proper access control
- [ ] All external calls follow checks-effects-interactions pattern
- [ ] All events properly emitted
- [ ] No hardcoded values
- [ ] Error handling comprehensive
- [ ] No reentrancy vulnerabilities
- [ ] No integer overflow/underflow risks
- [ ] SafeERC20 used for all token transfers
- [ ] No use of tx.origin for auth
- [ ] Storage layout correct for upgradeable contracts

See: `01-quick-reference/vulnerability-matrix.md`

### 5.2 Automated Tool Scanning

**Slither (must use):**
```bash
pip install slither-analyzer
slither .
```
- [ ] All warnings reviewed
- [ ] False positives documented
- [ ] Real issues fixed

**Mythril (for critical contracts):**
```bash
pip install mythril
myth analyze contract.sol
```

**Other tools:**
- Semgrep: Pattern-based analysis
- OpenZeppelin Defender: Risk assessment
- Certora: Formal verification (for critical contracts)

### 5.3 Vulnerability Audit

Check each top 10 vulnerability:
- [ ] Reentrancy: ReentrancyGuard or CEI pattern used?
- [ ] Access Control: Proper modifiers on all state-changing functions?
- [ ] Integer Overflow: Solidity 0.8+ protects by default?
- [ ] Front-running: Mempool safety considered?
- [ ] DoS: No unbounded loops?
- [ ] Timestamp Dependence: Not using block.timestamp for critical logic?
- [ ] Unsafe Delegatecall: No delegate calls to untrusted contracts?
- [ ] Unchecked Returns: All external calls checked?
- [ ] tx.origin: Not used for authentication?
- [ ] Flash Loans: Protected against flash loan attacks?

See: `03-attack-prevention/` for detailed guidance

### 5.4 Design Pattern Verification
- [ ] Patterns correctly implemented
- [ ] No anti-patterns found
- [ ] Pattern combinations valid (e.g., Pausable + Ownable)
- [ ] State machine logic correct (if applicable)

### 5.5 Access Control Audit
- [ ] All admin functions have onlyOwner/onlyRole
- [ ] Role hierarchy makes sense
- [ ] No privilege escalation paths
- [ ] Emergency stop properly restricted

### 5.6 Security Review Checklist
- [ ] Manual code review complete
- [ ] Slither analysis clean
- [ ] Mythril analysis clean
- [ ] All top 10 vulnerabilities reviewed
- [ ] Design patterns verified
- [ ] Access control audited
- [ ] Issues found and fixed
- [ ] Team security sign-off

---

## Phase 6: Optimization
**Duration:** 1-2 days | **Deliverables:** Optimized code, gas report | **Go/No-Go:** Optimization sign-off

### 6.1 Gas Profiling
Identify high-gas operations:
```bash
forge test --gas-report
```

Top candidates for optimization:
- [ ] State variable reads (expensive)
- [ ] Loops (especially with external calls)
- [ ] Storage writes (most expensive)

### 6.2 Apply High-Impact Optimizations
See: `01-quick-reference/gas-optimization-wins.md`

**High Impact (>1000 gas savings):**
- Custom errors instead of require strings (~100 gas each)
- Unchecked loops (~200 gas)
- Immutable constants (~2,000 gas)
- Storage slot packing (~2,000 gas per slot)
- Events instead of storage (~21,000 gas per log)

**Medium Impact (100-1000 gas):**
- Function visibility optimization
- Mapping vs array
- Pre-increment (++i vs i++)

### 6.3 Storage Optimization
```solidity
// Bad: Uses 3 storage slots
uint256 flag1;      // 32 bytes
uint256 flag2;      // 32 bytes
uint256 flag3;      // 32 bytes

// Good: Uses 1 storage slot (tight packing)
uint8 flag1;        // 1 byte
uint8 flag2;        // 1 byte
uint8 flag3;        // 1 byte
                    // 29 bytes available
```

### 6.4 Loop Optimization
```solidity
// Bad: ~3,600 gas per iteration (storage read/write)
for (uint256 i = 0; i < users.length; i++) {
    balances[users[i]] += amounts[i];
}

// Good: ~100 gas per iteration (unchecked math, local copy)
uint256 length = users.length;
for (uint256 i = 0; i < length;) {
    uint256 amount = amounts[i];  // Cache in memory
    balances[users[i]] += amount;
    unchecked { i++; }
}
```

### 6.5 Measure Improvements
Before and after gas measurements:
```bash
# Before optimization
forge test --gas-report > before.txt

# After optimization
forge test --gas-report > after.txt

# Compare
diff before.txt after.txt
```

### 6.6 Optimization Checklist
- [ ] Gas profiling complete
- [ ] High-impact optimizations applied
- [ ] Storage optimized
- [ ] Loops optimized
- [ ] Improvements measured and documented
- [ ] No security regressions introduced

---

## Phase 7: Final Testing
**Duration:** 1-2 days | **Deliverables:** All tests passing, mainnet fork tests pass | **Go/No-Go:** Ready for deployment

### 7.1 Regression Testing
Ensure nothing broke during optimization:
- [ ] All original tests still pass
- [ ] Coverage maintained
- [ ] Functionality unchanged

### 7.2 Stress Testing
High-volume scenarios:
```javascript
// Simulate 1000 users withdrawing
for (let i = 0; i < 1000; i++) {
    await contract.connect(users[i]).withdraw(amount);
}
```

### 7.3 Mainnet Fork Testing
Test against current mainnet state:
```bash
forge test --fork-url $MAINNET_RPC
```

If contract interacts with:
- [ ] Uniswap? → Test against real liquidity
- [ ] Aave? → Test against real lending state
- [ ] Chainlink? → Test with real price feeds
- [ ] Other protocols? → Test against real state

### 7.4 Testnet Deployment
Deploy to public testnet (Sepolia/Goerli):
- [ ] Contract deploys successfully
- [ ] Constructor params work
- [ ] Can call all functions
- [ ] Events emit correctly
- [ ] No runtime errors

### 7.5 Multi-sig Testing (if applicable)
If using multi-sig admin:
- [ ] Can propose transactions
- [ ] Can sign transactions
- [ ] Can execute transactions
- [ ] Threshold correctly enforced
- [ ] Emergency pause works

### 7.6 Final Checklist
- [ ] All regression tests pass
- [ ] Stress tests pass
- [ ] Mainnet fork tests pass
- [ ] Testnet deployment successful
- [ ] Multi-sig tests pass (if applicable)
- [ ] No critical issues found
- [ ] Team approval for mainnet

---

## Phase 8: Documentation
**Duration:** 1-2 days | **Deliverables:** Complete documentation | **Go/No-Go:** Documentation sign-off

### 8.1 Code Documentation
Every public function documented:
```solidity
/// @notice Withdraws specified amount of tokens
/// @dev Uses checks-effects-interactions pattern to prevent reentrancy
/// @param amount The amount to withdraw (must be <= balance)
/// @return success True if withdrawal succeeded
/// @custom:warning Emits Withdrawal event
function withdraw(uint256 amount) external returns (bool success) {
```

### 8.2 Architecture Documentation
Document the system:
- Contract interactions diagram
- Data flow diagram
- State machine (if applicable)
- Upgrade path (if applicable)

### 8.3 Function Documentation
For each function:
- What it does
- Who can call it (access requirements)
- Input constraints
- Return value meaning
- Side effects (state changes, external calls)
- Events emitted

### 8.4 Known Limitations
Document any known issues:
- [ ] Precision loss (e.g., in division)
- [ ] Assumptions about external contracts
- [ ] Maximum values for parameters
- [ ] Incompatible contracts

### 8.5 Deployment Instructions
Step-by-step deployment guide:
```markdown
## Deployment

### Prerequisites
- Mainnet RPC endpoint
- Deployer account with 1 ETH
- Contract verification API key (Etherscan)

### Steps
1. Set environment variables
2. Review deployment params
3. Run deployment script
4. Verify contract on Etherscan
5. Add to monitoring

### Deployment Parameters
- initialSupply: 1,000,000 tokens
- adminAddress: 0x...
- pauseEnabled: true
```

### 8.6 Documentation Checklist
- [ ] All public functions documented
- [ ] Architecture documented
- [ ] Data flows documented
- [ ] Deployment instructions written
- [ ] Known limitations listed
- [ ] Test plan documented
- [ ] Emergency procedures documented

---

## Decision Trees

### Reentrancy Protection Needed?
```
Does contract call external contracts?
  → Yes → Do you transfer tokens/ETH before calling?
    → Yes → MUST USE checks-effects-interactions OR ReentrancyGuard
    → No → OK, effect happens during call
  → No → Not needed
```

### Access Control: Ownable vs AccessControl?
```
How many admin roles do you need?
  → Just 1 (contract owner) → Use Ownable (cheaper gas)
  → 2-5 roles → Use AccessControl (RBAC)
  → Complex hierarchy → Use AccessControl with role admin
  → Emergency pause needed? → Add Pausable regardless
```

### Pausable Needed?
```
Is this a critical protocol?
  → Yes → Add Pausable circuit breaker
    → Who can pause? (owner, admin, multisig)
    → What happens when paused? (deny deposits, allow withdrawals)
  → No → Optional, but recommended for new projects
```

### Upgradeable Contract?
```
Is this mainnet or testnet?
  → Mainnet (long-term) → Make upgradeable
    → UUPS (cheaper) or Transparent (safer)
    → Set upgrade authority (owner, multisig, timelock)
  → Testnet (testing only) → Can skip upgradeable

Could contract be buggy?
  → Yes → Make upgradeable
  → No → Can be immutable if fully audited
```

### External Calls Needed?
```
Calling external contracts (tokens, oracles)?
  → ERC20 tokens → Always use SafeERC20
  → Flash loans risky → Add flash loan guards
  → Untrusted contracts → Use checks-effects-interactions pattern
  → Unknown contracts → Maximum caution, possibly timelock
```

---

## Common Pitfalls

### 1. Forgetting ReentrancyGuard
**Problem:** External call before state update → reentrancy vulnerability
**Solution:** Use `nonReentrant` modifier or checks-effects-interactions pattern

### 2. Not Validating Inputs
**Problem:** Zero amounts, zero addresses, invalid parameters
**Solution:** Always validate: `if (amount == 0) revert InvalidAmount();`

### 3. Hardcoded Values
**Problem:** Can't change important constants without redeploying
**Solution:** Use constructor parameters or state variables

### 4. Not Emitting Events
**Problem:** No off-chain visibility, hard to track state changes
**Solution:** Emit event for all important state changes

### 5. Using String Errors
**Problem:** Wastes gas (stores error message)
**Solution:** Use custom errors (saves ~100 gas per error)

### 6. Incorrect Access Control
**Problem:** Functions accessible by wrong users
**Solution:** Add proper modifiers (onlyOwner, onlyRole, etc.)

### 7. Not Testing Edge Cases
**Problem:** Contract breaks on min/max values
**Solution:** Test 0, 1, MAX_INT, negative scenarios

### 8. Forgetting Storage Layout (upgradeable contracts)
**Problem:** Storage collision after upgrade breaks contract
**Solution:** Add storage gap, use ERC-7201 namespaced storage

### 9. Trusting Timestamps
**Problem:** Miners can manipulate block.timestamp (±15 seconds)
**Solution:** Don't use for critical randomness, use block.number instead

### 10. Silent Failures
**Problem:** External call fails silently, state inconsistent
**Solution:** Check return values, use SafeERC20 for tokens

---

## Resources

- **Templates:** `knowledge-base-action/02-contract-templates/`
- **Patterns:** `knowledge-base-action/01-quick-reference/pattern-catalog.md`
- **Vulnerabilities:** `knowledge-base-action/03-attack-prevention/`
- **Code Snippets:** `knowledge-base-action/04-code-snippets/`
- **Gas Optimization:** `knowledge-base-action/01-quick-reference/gas-optimization-wins.md`
- **Security Checklist:** `knowledge-base-action/05-workflows/pre-deployment.md`

---

**Next:** Follow [Pre-Deployment Checklist](pre-deployment.md) before deploying to mainnet.
