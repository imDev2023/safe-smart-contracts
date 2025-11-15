# Smart Contract Templates

Production-ready Solidity contract templates implementing security best practices, gas optimizations, and battle-tested patterns from the research knowledge base.

## Table of Contents

- [Overview](#overview)
- [Template Catalog](#template-catalog)
- [Usage Guidelines](#usage-guidelines)
- [Security Considerations](#security-considerations)
- [Gas Optimization Notes](#gas-optimization-notes)
- [Combining Templates](#combining-templates)
- [Customization Guide](#customization-guide)
- [Deployment Checklist](#deployment-checklist)
- [Common Patterns](#common-patterns)

---

## Overview

These templates synthesize best practices from:
- **OpenZeppelin Contracts**: Battle-tested, audited implementations
- **ConsenSys Best Practices**: Security guidelines and recommendations
- **Gas Optimization Research**: Efficient storage and computation patterns
- **Solidity Design Patterns**: Proven architectural solutions

All templates use **Solidity 0.8.20** with locked pragma for deterministic builds.

---

## Template Catalog

### 1. secure-erc20.sol (250 lines)

**Purpose**: Production-ready ERC20 token with advanced features

**Key Features**:
- OpenZeppelin ERC20 base implementation
- Role-based access control (RBAC) for minting
- Pausable functionality for emergency stops
- Burnable tokens for supply reduction
- EIP-2612 Permit for gasless approvals
- Custom errors for gas efficiency
- Max supply enforcement
- Comprehensive event logging

**When to Use**:
- Creating fungible tokens (coins, utility tokens)
- Need controlled minting with role permissions
- Require emergency pause capability
- Want gasless approval functionality (permit)

**Gas Cost Estimates**:
- Deployment: ~3,200,000 gas
- Transfer: ~51,000 gas (first transfer), ~35,000 gas (subsequent)
- Mint: ~70,000 gas
- Permit + Transfer: ~95,000 gas (saves user approval gas)

**Import Requirements**:
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
```

**Customization Points**:
- Initial supply (constructor parameter)
- Max supply (modify `maxSupply` or set to unlimited)
- Decimals (override `decimals()` function)
- Role structure (add/remove roles as needed)
- Burning restrictions (modify `burn()` if needed)

---

### 2. secure-erc721.sol (200 lines)

**Purpose**: Production-ready NFT (ERC721) implementation

**Key Features**:
- OpenZeppelin ERC721 base
- Enumerable extension (discover all tokens)
- URI Storage for flexible metadata
- Burnable for token destruction
- Ownable for admin controls
- SafeMint ensures recipients can receive NFTs
- Batch minting for efficiency
- Token counter starting at 1

**When to Use**:
- Creating NFT collections
- Need enumerable tokens (list all NFTs)
- Require metadata management
- Want batch minting capability

**Gas Cost Estimates**:
- Deployment: ~4,500,000 gas
- Mint (single): ~185,000 gas
- Mint (batch of 10): ~1,200,000 gas (~120k per NFT)
- Transfer: ~95,000 gas
- Burn: ~55,000 gas

**Import Requirements**:
```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
```

**Customization Points**:
- Max supply (constructor parameter)
- Base URI (constructor and setter)
- Royalty information (add ERC2981)
- Whitelist/allowlist minting
- Reveal mechanism for metadata

---

### 3. access-control-template.sol (150 lines)

**Purpose**: Flexible role-based access control system

**Key Features**:
- OpenZeppelin AccessControl (RBAC)
- Pre-defined roles (ADMIN, MANAGER, USER)
- Role hierarchy and administration
- Modifier-based access guards
- Role granting/revoking/renouncing
- Self-revocation protection for admin
- Event logging for transparency

**When to Use**:
- Multi-tiered permission systems
- DAO governance structures
- Complex admin hierarchies
- Need granular function-level permissions

**Gas Cost Estimates**:
- Deployment: ~1,800,000 gas
- Grant role: ~50,000 gas
- Revoke role: ~25,000 gas
- Role check (modifier): ~2,400 gas overhead

**Import Requirements**:
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";
```

**Customization Points**:
- Add custom roles (define new `bytes32` constants)
- Modify role hierarchy (change `_setRoleAdmin`)
- Create role-specific functions
- Add time-locked role changes
- Implement role transfer mechanics

**Role Hierarchy Example**:
```
DEFAULT_ADMIN_ROLE (deployer)
    └── ADMIN_ROLE
        ├── MANAGER_ROLE
        └── USER_ROLE
```

---

### 4. upgradeable-template.sol (180 lines)

**Purpose**: UUPS upgradeable contract pattern

**Key Features**:
- UUPSUpgradeable implementation
- Initializer instead of constructor
- Storage gap for future variables
- Access control on upgrades
- Version tracking
- Pausable functionality
- ReentrancyGuard protection

**When to Use**:
- Need contract upgradeability
- Long-term protocols requiring updates
- Bug fix capability
- Feature addition over time

**Gas Cost Estimates**:
- Proxy deployment: ~450,000 gas
- Implementation deployment: ~2,800,000 gas
- Initialize: ~250,000 gas
- Upgrade: ~50,000 gas
- Function call overhead: +2,000 gas (delegatecall)

**Import Requirements**:
```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
```

**CRITICAL Upgrade Rules**:
1. **Never reorder or remove existing storage variables**
2. **Only add new variables at the end**
3. **Reduce storage gap when adding variables**
4. **Maintain function signatures (don't change existing)**
5. **Test upgrades on testnet first**
6. **Verify storage layout with hardhat-storage-layout**

**Storage Gap Usage**:
```solidity
// Current state variables use 3 slots
string public version;          // slot 0
uint256 public lastUpgrade;     // slot 1
uint256 public upgradeCount;    // slot 2

// Gap reserves 47 more slots
uint256[47] private __gap;      // slots 3-49

// Total: 50 slots reserved

// When adding 2 new variables:
uint256 public newVar1;         // slot 3
uint256 public newVar2;         // slot 4
uint256[45] private __gap;      // reduce gap to 45
```

**Customization Points**:
- Business logic in example functions
- Additional access control roles
- Upgrade authorization logic
- Version numbering scheme

---

### 5. staking-template.sol (280 lines)

**Purpose**: Token staking with reward distribution

**Key Features**:
- Stake/unstake ERC20 tokens
- Continuous reward distribution
- Lockup period enforcement
- Pausable for emergencies
- ReentrancyGuard protection
- SafeERC20 for transfers
- Precise reward calculation
- AccessControl for admin

**When to Use**:
- Staking mechanisms
- Yield farming protocols
- Liquidity mining
- Token holder incentives

**Gas Cost Estimates**:
- Deployment: ~3,500,000 gas
- Stake: ~95,000 gas (first), ~70,000 gas (subsequent)
- Unstake: ~75,000 gas
- Claim rewards: ~55,000 gas
- Update rewards (internal): ~25,000 gas

**Import Requirements**:
```solidity
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
```

**Reward Calculation**:
```
Rewards = (StakedAmount × TimeElapsed × RewardRate) / TotalStaked

RewardRate is per second, scaled by 1e18 for precision
Example: 0.1 tokens per second = 100000000000000000 (1e17)
```

**Customization Points**:
- Reward calculation formula
- Lockup period duration
- Early unstake penalties
- Reward boost multipliers
- Staking tiers/levels
- Compound vs. claim rewards

**Security Notes**:
- Uses SafeERC20 (handles non-standard tokens)
- Checks-effects-interactions pattern
- Reward accounting prevents inflation attacks
- No division before multiplication

---

### 6. pausable-template.sol (120 lines)

**Purpose**: Emergency stop (circuit breaker) pattern

**Key Features**:
- Pausable contract operations
- Role-based pause controls
- Emergency withdrawal when paused
- Batch emergency operations
- whenNotPaused/whenPaused modifiers
- Pause history tracking

**When to Use**:
- Need emergency stop capability
- Bug discovery response
- Upgrade preparation
- Attack mitigation
- Controlled shutdown

**Gas Cost Estimates**:
- Deployment: ~1,600,000 gas
- Pause: ~28,000 gas
- Unpause: ~15,000 gas
- Emergency withdraw: ~45,000 gas
- Normal withdraw (not paused): ~35,000 gas

**Import Requirements**:
```solidity
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
```

**Customization Points**:
- Replace deposit/withdraw with actual business logic
- Add different pause states (partial pause)
- Time-based auto-unpause
- Multi-sig pause requirement
- Gradual unlock mechanisms

**Usage Pattern**:
```solidity
function criticalFunction() external whenNotPaused {
    // Normal operations only when not paused
}

function emergencyFunction() external whenPaused {
    // Only callable when paused
}
```

---

### 7. multisig-template.sol (280 lines)

**Purpose**: Multi-signature wallet (Gnosis Safe style)

**Key Features**:
- Multiple signers with threshold
- Off-chain signature collection
- Transaction proposal/execution
- ECDSA signature verification
- Nonce-based replay protection
- Owner management (add/remove)
- Threshold adjustment
- Support arbitrary calls

**When to Use**:
- Treasury management
- DAO execution
- Multi-party custody
- High-value operations
- Decentralized governance

**Gas Cost Estimates**:
- Deployment: ~2,800,000 gas
- Execute (2-of-3): ~95,000 gas base + call gas
- Execute (3-of-5): ~125,000 gas base + call gas
- Add owner: ~75,000 gas
- Change threshold: ~30,000 gas

**Import Requirements**:
```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
```

**Signature Format**:
```
Concatenated 65-byte signatures in ascending signer order:
[v1][r1][s1][v2][r2][s2]...[vN][rN][sN]

Each signature: 65 bytes (v: 1 byte, r: 32 bytes, s: 32 bytes)
```

**Transaction Hash**:
```solidity
keccak256(abi.encodePacked(
    contractAddress,
    to,
    value,
    data,
    nonce,
    chainId
))
```

**Customization Points**:
- Add time locks on execution
- Daily spending limits
- Transaction queuing
- Role-based thresholds (different for different operations)
- Integration with ERC20 token voting

**Security Notes**:
- Signatures must be in ascending order (prevents duplicates)
- Nonce prevents replay attacks
- Chain ID prevents cross-chain replay
- ECDSA prevents signature forgery

---

## Usage Guidelines

### Getting Started

1. **Choose appropriate template(s)** based on your requirements
2. **Review customization points** in each template
3. **Modify as needed** for your specific use case
4. **Add business logic** to example functions
5. **Test thoroughly** before deployment

### Installation

```bash
# Install OpenZeppelin contracts
npm install @openzeppelin/contracts@4.9.3

# For upgradeable contracts
npm install @openzeppelin/contracts-upgradeable@4.9.3

# Development dependencies
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
```

### Basic Deployment Example (Hardhat)

```javascript
// deploy.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with account:", deployer.address);

  // Example: Deploy ERC20
  const Token = await ethers.getContractFactory("SecureERC20Token");
  const token = await Token.deploy(
    "My Token",           // name
    "MTK",                // symbol
    ethers.parseEther("1000000")  // initial supply: 1M tokens
  );

  await token.deployed();
  console.log("Token deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

---

## Security Considerations

### Universal Best Practices

All templates implement these security measures:

1. **Locked Pragma**: `pragma solidity 0.8.20;` (deterministic builds)
2. **Custom Errors**: Gas-efficient error handling
3. **Checks-Effects-Interactions**: State changes before external calls
4. **ReentrancyGuard**: Where external calls are made
5. **Access Control**: RBAC or Ownable for admin functions
6. **Event Logging**: All important state changes
7. **Input Validation**: Zero address checks, amount validations
8. **SafeERC20**: For token transfers (handles non-standard tokens)

### Common Vulnerabilities Prevented

| Vulnerability | Prevention Method | Templates |
|--------------|-------------------|-----------|
| Reentrancy | ReentrancyGuard + CEI pattern | All with external calls |
| Integer Overflow | Solidity 0.8+ built-in checks | All |
| Access Control | RBAC/Ownable modifiers | All |
| Signature Replay | Nonce + chain ID | MultiSig |
| Upgradeable Storage Collision | Storage gaps + initializers | Upgradeable |
| Front-running | Commit-reveal (add as needed) | - |
| DoS Gas Limit | Pull over push pattern | Pausable, MultiSig |

### Testing Requirements

Before deploying:

1. **Unit Tests**: Test each function independently
2. **Integration Tests**: Test contract interactions
3. **Edge Cases**: Test boundary conditions
4. **Negative Tests**: Test unauthorized access
5. **Gas Benchmarks**: Measure operation costs
6. **Upgrade Tests**: Test upgrade path (upgradeable contracts)
7. **Testnet Deployment**: Deploy on Goerli/Sepolia first

---

## Gas Optimization Notes

### Techniques Applied

1. **Custom Errors** (vs. require strings)
   - Savings: ~20-50 gas per error
   - Example: `revert CannotMintZero()` vs `require(amount > 0, "Cannot mint zero")`

2. **Unchecked Loops**
   - Savings: ~30-40 gas per iteration
   ```solidity
   for (uint256 i = 0; i < array.length; ) {
       // loop body
       unchecked { ++i; }
   }
   ```

3. **Pre-increment** (++i vs i++)
   - Savings: ~5 gas per operation
   - Used in all loop counters

4. **Storage Packing**
   - Multiple small variables in single slot
   - Example: Use uint128 for two values instead of two uint256

5. **Immutable Variables**
   - Use `immutable` for constructor-set constants
   - Savings: ~2,100 gas per SLOAD avoided

6. **Calldata vs Memory**
   - Use `calldata` for external function parameters
   - Savings: ~60 gas per parameter

### Gas Optimization Checklist

- [ ] Use custom errors instead of require strings
- [ ] Mark constructor parameters as `immutable` when possible
- [ ] Use `calldata` for read-only external function parameters
- [ ] Pack storage variables to minimize slots
- [ ] Use unchecked arithmetic in loops
- [ ] Batch operations instead of individual calls
- [ ] Use events instead of storage where possible
- [ ] Cache array lengths in loops
- [ ] Use `++i` instead of `i++`
- [ ] Avoid unnecessary storage reads (cache in memory)

---

## Combining Templates

### Common Combinations

#### 1. Upgradeable ERC20 Token
```solidity
// Combine: upgradeable-template.sol + secure-erc20.sol
contract UpgradeableToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // Convert constructor to initialize()
    // Add storage gap
    // Use upgradeable imports
}
```

#### 2. NFT with Staking
```solidity
// Combine: secure-erc721.sol + staking-template.sol
// NFT holders stake their NFTs to earn rewards
contract StakableNFT {
    // ERC721 for NFT management
    // Staking logic adapted for NFT IDs instead of amounts
    // Reward based on NFT rarity/traits
}
```

#### 3. Multi-Sig with Time Lock
```solidity
// Combine: multisig-template.sol + pausable-template.sol
contract TimeLockMultiSig {
    // Add delay period before execution
    // Queue transactions with multisig
    // Execute after time lock expires
}
```

#### 4. Pausable Staking
```solidity
// Already combined in staking-template.sol
// Staking inherits Pausable for emergency stops
```

### Integration Patterns

**Pattern 1: Composition**
```solidity
contract Main {
    AccessControl public accessControl;

    modifier onlyAdmin() {
        require(accessControl.isAdmin(msg.sender));
        _;
    }
}
```

**Pattern 2: Inheritance**
```solidity
contract Combined is ERC20, Pausable, AccessControl {
    // Multiple inheritance with OpenZeppelin
}
```

**Pattern 3: Module System**
```solidity
contract Core {
    mapping(address => bool) public modules;

    function callModule(address module, bytes calldata data) external {
        require(modules[module]);
        module.delegatecall(data);
    }
}
```

---

## Customization Guide

### Template Modification Workflow

1. **Identify Template**: Choose base template
2. **Review Code**: Understand structure and patterns
3. **Plan Changes**: Document required modifications
4. **Modify Carefully**: Preserve security patterns
5. **Test Extensively**: Cover new functionality
6. **Audit If Needed**: For high-value contracts

### Common Customizations

#### Adding Custom Functions

```solidity
// In access-control-template.sol
// Add a manager-only function

function approveTransaction(uint256 txId) external onlyManager {
    // Custom logic here
    emit TransactionApproved(txId, msg.sender);
}
```

#### Modifying Role Structure

```solidity
// Add new role
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

// Set up in constructor
constructor() {
    _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
}
```

#### Changing Reward Formula (Staking)

```solidity
// Modify _updateReward() internal function
function _updateReward(address account) internal {
    // Custom reward calculation
    // Example: boost for long-term stakers
    uint256 stakeDuration = block.timestamp - staker.lastStakeTime;
    uint256 boost = stakeDuration > 90 days ? 2 : 1;

    uint256 earned = (staker.stakedAmount * boost * rewardRate) / 1e18;
    staker.pendingRewards += earned;
}
```

#### Adding Token Metadata (ERC721)

```solidity
// Add trait/attribute tracking
struct TokenMetadata {
    uint8 rarity;
    uint256 level;
    string category;
}

mapping(uint256 => TokenMetadata) public metadata;

function mintWithMetadata(
    address to,
    string memory uri,
    uint8 rarity,
    string memory category
) external onlyOwner {
    uint256 tokenId = safeMint(to, uri);
    metadata[tokenId] = TokenMetadata(rarity, 1, category);
}
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] **Code Review**: All functionality reviewed
- [ ] **Testing**: Full test coverage (>90%)
- [ ] **Gas Optimization**: Benchmarked and optimized
- [ ] **Security Audit**: Professional audit (for high-value)
- [ ] **Testnet Deployment**: Deployed and tested on testnet
- [ ] **Documentation**: NatSpec comments complete
- [ ] **Verify Compiler**: Using correct Solidity version
- [ ] **Dependencies**: OpenZeppelin versions locked

### Constructor Parameters

Document all deployment parameters:

```javascript
// secure-erc20.sol deployment
{
  name: "My Token",
  symbol: "MTK",
  initialSupply: "1000000" // in ether units
}

// secure-erc721.sol deployment
{
  name: "My NFT Collection",
  symbol: "MNFT",
  baseTokenURI: "ipfs://QmXx.../",
  maxSupply: "10000"
}

// staking-template.sol deployment
{
  stakingToken: "0x...",
  rewardToken: "0x...",
  rewardRatePerSecond: "100000000000000000", // 0.1 per second
  lockupPeriod: "604800" // 7 days in seconds
}

// multisig-template.sol deployment
{
  owners: ["0x123...", "0x456...", "0x789..."],
  threshold: "2" // 2-of-3
}
```

### Post-Deployment

- [ ] **Verify Contract**: On Etherscan/block explorer
- [ ] **Transfer Ownership**: From deployer to multi-sig/DAO
- [ ] **Grant Roles**: Distribute admin roles appropriately
- [ ] **Initialize**: Call initialize() for upgradeable contracts
- [ ] **Documentation**: Update with contract addresses
- [ ] **Monitor**: Set up event monitoring
- [ ] **Backup**: Save deployment artifacts and addresses

### Mainnet Deployment (Additional)

- [ ] **Final Audit**: Last security check
- [ ] **Gas Price**: Choose appropriate gas price
- [ ] **Transaction Monitoring**: Watch deployment tx
- [ ] **Immediate Verification**: Verify on Etherscan
- [ ] **Access Control**: Immediately secure admin functions
- [ ] **Announcement**: Notify users of contract address
- [ ] **Frontend Update**: Update dApp with new address

---

## Common Patterns

### 1. Checks-Effects-Interactions

Always follow this order to prevent reentrancy:

```solidity
function withdraw(uint256 amount) external {
    // CHECKS
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // EFFECTS (state changes)
    balances[msg.sender] -= amount;

    // INTERACTIONS (external calls)
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

### 2. Pull Over Push

Prefer letting users pull funds rather than pushing:

```solidity
// BAD: Push pattern
function distribute() external {
    for (uint256 i = 0; i < users.length; i++) {
        users[i].transfer(amount); // Can fail and block everyone
    }
}

// GOOD: Pull pattern
function withdraw() external {
    uint256 amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
}
```

### 3. Rate Limiting

Limit operations per time period:

```solidity
mapping(address => uint256) public lastActionTime;
uint256 public constant ACTION_COOLDOWN = 1 hours;

function rateLimit() internal {
    require(
        block.timestamp >= lastActionTime[msg.sender] + ACTION_COOLDOWN,
        "Too soon"
    );
    lastActionTime[msg.sender] = block.timestamp;
}
```

### 4. Commit-Reveal

Prevent front-running on sensitive operations:

```solidity
mapping(address => bytes32) public commitments;

function commit(bytes32 hash) external {
    commitments[msg.sender] = hash;
}

function reveal(uint256 value, bytes32 salt) external {
    require(
        commitments[msg.sender] == keccak256(abi.encodePacked(value, salt)),
        "Invalid reveal"
    );
    // Process value
}
```

### 5. Emergency Stop (Circuit Breaker)

Implemented in pausable-template.sol:

```solidity
function criticalOperation() external whenNotPaused {
    // Normal operations
}

function emergencyStop() external onlyAdmin {
    _pause();
}
```

### 6. Speed Bumps

Delay for high-value operations:

```solidity
struct DelayedAction {
    uint256 executeAfter;
    address target;
    bytes data;
}

mapping(uint256 => DelayedAction) public queue;

function propose(address target, bytes calldata data) external {
    queue[nextId++] = DelayedAction({
        executeAfter: block.timestamp + 2 days,
        target: target,
        data: data
    });
}

function execute(uint256 id) external {
    require(block.timestamp >= queue[id].executeAfter, "Too soon");
    // Execute
}
```

---

## Template Comparison Matrix

| Feature | ERC20 | ERC721 | Access | Upgradeable | Staking | Pausable | MultiSig |
|---------|-------|--------|--------|-------------|---------|----------|----------|
| Token Standard | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Access Control | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pausable | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Upgradeable | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Burnable | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Permit (EIP2612) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ReentrancyGuard | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Custom Errors | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Events | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Additional Resources

### Documentation
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [ConsenSys Best Practices](https://consensys.github.io/smart-contract-best-practices/)

### Security Tools
- **Slither**: Static analysis
- **Mythril**: Symbolic execution
- **Echidna**: Fuzzing
- **Hardhat**: Development environment
- **Foundry**: Testing framework

### Audit Services
- ConsenSys Diligence
- Trail of Bits
- OpenZeppelin
- Certora
- Quantstamp

---

## Version History

- **v1.0.0** (2024): Initial release
  - 7 Solidity templates
  - Comprehensive documentation
  - Security best practices
  - Gas optimizations

---

## Contributing

To propose improvements:
1. Review existing templates
2. Identify enhancement opportunities
3. Test changes thoroughly
4. Submit with documentation
5. Include security considerations

---

## License

MIT License - See individual template files for SPDX identifiers

---

## Support

For questions or issues:
- Review template comments and NatSpec
- Check OpenZeppelin documentation
- Consult Solidity best practices guides
- Seek professional audit for production use

---

**Remember**: These templates are starting points. Always customize for your specific use case, test thoroughly, and consider professional security audits before deploying to mainnet with real value.
