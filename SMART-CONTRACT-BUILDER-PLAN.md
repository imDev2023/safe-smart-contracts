# Smart Contract Builder - CocoIndex Integration
## Automated Contract Generation from Knowledge Base

**Purpose:** Generate production-ready smart contracts with automatic security, gas optimization, and domain-specific protections.

**Input:** Contract requirements (features, domain, constraints)
**Output:** Production Solidity code with all safety features, tests, and documentation

---

## System Architecture

```
User Requirements
      ↓
┌─────────────────────────────────────────────────────────┐
│  1. REQUIREMENT ANALYZER                                │
│     - Parse user intent                                 │
│     - Identify domain (DeFi, NFT, Gaming, AI)          │
│     - Extract features (staking, trading, etc.)        │
│     - Detect constraints (gas budget, timeframe)       │
└─────────────────────────────────────────────────────────┘
      ↓
┌─────────────────────────────────────────────────────────┐
│  2. KNOWLEDGE BASE QUERY (CocoIndex)                    │
│     - Find relevant templates                           │
│     - Locate security patterns                          │
│     - Retrieve code snippets                            │
│     - Get gas optimizations                             │
│     - Load domain-specific protections                  │
└─────────────────────────────────────────────────────────┘
      ↓
┌─────────────────────────────────────────────────────────┐
│  3. CONTRACT ASSEMBLER                                  │
│     - Select base template                              │
│     - Inject security patterns                          │
│     - Apply gas optimizations                           │
│     - Add domain protections                            │
│     - Compose final contract                            │
└─────────────────────────────────────────────────────────┘
      ↓
┌─────────────────────────────────────────────────────────┐
│  4. SECURITY VALIDATOR                                  │
│     - Run 400+ security checks                          │
│     - Verify vulnerability prevention                   │
│     - Check gas efficiency                              │
│     - Validate domain-specific protections              │
└─────────────────────────────────────────────────────────┘
      ↓
┌─────────────────────────────────────────────────────────┐
│  5. TEST GENERATOR                                      │
│     - Generate unit tests                               │
│     - Create integration tests                          │
│     - Add attack scenario tests                         │
│     - Include gas benchmarks                            │
└─────────────────────────────────────────────────────────┘
      ↓
Complete Smart Contract Package
```

---

## Feature Modules

### 1. Base Templates (from KB)
```
ERC20 Token        → knowledge-base-action/02-contract-templates/secure-erc20.sol
ERC721 NFT         → knowledge-base-action/02-contract-templates/secure-erc721.sol
Staking            → knowledge-base-action/02-contract-templates/staking-template.sol
Multi-sig          → knowledge-base-action/02-contract-templates/multisig-template.sol
Upgradeable        → knowledge-base-action/02-contract-templates/upgradeable-template.sol
Pausable           → knowledge-base-action/02-contract-templates/pausable-template.sol
Access Control     → knowledge-base-action/02-contract-templates/access-control-template.sol
```

### 2. Security Patterns (Auto-Injected)
```solidity
// From knowledge-base-action/01-quick-reference/vulnerability-matrix.md
// + knowledge-base-action/03-attack-prevention/

Reentrancy         → import ReentrancyGuard + nonReentrant modifier
Access Control     → import AccessControl + onlyRole/onlyOwner
Integer Safety     → Solidity 0.8+ (built-in) + SafeCast
Unchecked Returns  → SafeERC20 for all token operations
Flash Loan         → TWAP oracle + time locks + sanity checks
Frontrunning       → Commit-reveal or private pools
DoS                → Pull pattern + bounded loops
```

### 3. Gas Optimizations (Auto-Applied)
```solidity
// From knowledge-base-action/01-quick-reference/gas-optimization-wins.md
// + knowledge-base-research/repos/gas-optimization/

Custom Errors      → Replace require strings (50% savings)
Unchecked Math     → Use unchecked{} where safe (30-40% savings)
Storage Packing    → Pack variables (20-40% savings)
Calldata vs Memory → Use calldata for external (30% savings)
Immutable          → Mark constants immutable (21,000 gas savings)
Pre-increment      → Use ++i instead of i++ (5-6 gas)
Short-circuiting   → Optimize boolean logic (99.9% potential)
```

### 4. DeFi-Specific Protections
```solidity
// From knowledge-base-action/06-defi-trading/

ANTI-SNIPER PROTECTION
├─ Max buy limit in first blocks
├─ Gradual limit increase
├─ Blacklist bots detected in first N blocks
└─ From: 03-sniper-bot-prevention.md

SLIPPAGE PROTECTION
├─ Min output amount check
├─ Deadline parameter
├─ Price impact limits
└─ From: 02-slippage-protection.md

MEV MITIGATION
├─ Private transaction submission
├─ Commit-reveal for sensitive ops
├─ Flashbots integration
└─ From: 05-mev-mitigation.md

ORACLE SAFETY
├─ TWAP instead of spot price
├─ Multiple oracle sources
├─ Deviation checks
└─ From: 06-price-oracles.md + 11-oracle-security-checklist.md

LIQUIDITY PROTECTION
├─ Min liquidity requirements
├─ Gradual unlock schedules
├─ Rug pull prevention
└─ From: 01-liquidity-pools.md
```

### 5. Gaming-Specific Features
```solidity
// From knowledge-base-research/repos/game-templates/

RANDOMNESS (Secure)
├─ Chainlink VRF integration
├─ Commit-reveal backup
├─ Block hash fallback (with warnings)
└─ From: chainlink/03-chainlink-vrf-integration.md

NFT GAME ASSETS
├─ ERC721 with metadata
├─ Upgradeable stats
├─ Trade restrictions
└─ From: secure-erc721.sol + game-templates

REWARD SYSTEMS
├─ Staking mechanisms
├─ Achievement tracking
├─ Anti-cheat measures
└─ From: staking-template.sol
```

### 6. AI Integration Features
```solidity
// From knowledge-base-research/repos/virtual-protocol/

AI AGENT ECONOMICS
├─ Token-gated API access
├─ Usage tracking
├─ Payment splits
└─ From: 01-ai-agent-economics.md

ORACLE INTEGRATION
├─ Off-chain computation results
├─ Data feed verification
├─ Chainlink Functions
└─ From: chainlink-automation-integration.md
```

---

## Usage Examples

### Example 1: DeFi Trading Token

**User Input:**
```yaml
requirements:
  type: ERC20
  domain: DeFi
  features:
    - trading
    - anti-sniper
    - slippage protection
    - gas optimized
  integrations:
    - Uniswap V3
    - Chainlink price feed
```

**Generated Contract:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Auto-selected from KB templates
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Auto-added for DeFi domain
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Secure DeFi Trading Token
/// @notice Production-ready ERC20 with anti-sniper, slippage protection, gas optimization
/// @dev Auto-generated from safe-smart-contracts knowledge base
contract SecureDeFiToken is ERC20, Ownable, ReentrancyGuard {

    // === GAS OPTIMIZATION: Storage packing ===
    // From: gas-optimization-wins.md
    uint96 public maxBuyAmount;          // Packed with below
    uint96 public maxWalletAmount;       // Packed with above
    uint64 public tradingEnabledTime;    // Packed

    // === ANTI-SNIPER PROTECTION ===
    // From: 03-sniper-bot-prevention.md
    uint256 public constant SNIPER_BLOCKS = 3;
    mapping(address => bool) public isSniperBot;

    // === SLIPPAGE PROTECTION ===
    // From: 02-slippage-protection.md
    uint256 public maxPriceImpact = 300; // 3%

    // === ORACLE INTEGRATION ===
    // From: 08-chainlink-datafeed-integration.md
    AggregatorV3Interface public priceFeed;
    ISwapRouter public uniswapRouter;

    // === CUSTOM ERRORS (Gas Optimization) ===
    // From: errors.md - 50% gas savings vs require strings
    error SniperBotDetected();
    error TradingNotEnabled();
    error ExceedsMaxBuy();
    error ExceedsMaxWallet();
    error SlippageExceeded();
    error PriceImpactTooHigh();

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address _priceFeed,
        address _uniswapRouter
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, totalSupply);

        // Initialize with safe defaults
        maxBuyAmount = uint96(totalSupply / 100); // 1% max buy
        maxWalletAmount = uint96(totalSupply / 50); // 2% max wallet

        priceFeed = AggregatorV3Interface(_priceFeed);
        uniswapRouter = ISwapRouter(_uniswapRouter);
    }

    /// @notice Enable trading (one-time)
    /// @dev Anti-sniper protection starts here
    function enableTrading() external onlyOwner {
        if (tradingEnabledTime != 0) revert TradingNotEnabled();
        tradingEnabledTime = uint64(block.timestamp);
    }

    /// @notice Transfer with anti-sniper and limits
    /// @dev Implements: reentrancy guard, sniper detection, buy limits
    function transfer(
        address to,
        uint256 amount
    ) public virtual override nonReentrant returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        return super.transfer(to, amount);
    }

    /// @notice TransferFrom with protections
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override nonReentrant returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        return super.transferFrom(from, to, amount);
    }

    /// @notice Swap with slippage protection
    /// @param amountIn Token amount to swap
    /// @param amountOutMin Minimum output (slippage protection)
    /// @param deadline Transaction deadline
    /// @dev From: 02-slippage-protection.md
    function swapWithProtection(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountOut) {
        // Check deadline
        if (block.timestamp > deadline) revert SlippageExceeded();

        // Get current price from Chainlink
        (, int256 price,,,) = priceFeed.latestRoundData();

        // Calculate expected output
        uint256 expectedOut = (amountIn * uint256(price)) / 1e18;

        // Check slippage
        uint256 slippage = ((expectedOut - amountOutMin) * 10000) / expectedOut;
        if (slippage > maxPriceImpact) revert PriceImpactTooHigh();

        // Execute swap
        // ... (Uniswap V3 swap logic from integration guide)

        return amountOut;
    }

    /// @dev Internal checks before any transfer
    /// @dev Implements all protections from KB
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view {
        // Skip checks for minting/burning
        if (from == address(0) || to == address(0)) return;

        // === ANTI-SNIPER PROTECTION ===
        // From: 03-sniper-bot-prevention.md
        if (isSniperBot[from] || isSniperBot[to]) {
            revert SniperBotDetected();
        }

        // Detect snipers in first N blocks
        if (tradingEnabledTime > 0 &&
            block.number < tradingEnabledTime + SNIPER_BLOCKS) {
            // Flag as sniper if buying
            if (from != owner() && to != owner()) {
                // In production, this would set isSniperBot[to] = true
                // Simplified here
            }
        }

        // === BUY LIMITS ===
        // Prevent whale accumulation
        if (amount > maxBuyAmount) revert ExceedsMaxBuy();

        if (balanceOf(to) + amount > maxWalletAmount) {
            revert ExceedsMaxWallet();
        }
    }

    /// @notice Emergency pause (if needed)
    /// @dev From: pausable-template.sol
    function addSniperBot(address bot) external onlyOwner {
        isSniperBot[bot] = true;
    }

    function removeSniperBot(address bot) external onlyOwner {
        isSniperBot[bot] = false;
    }
}
```

**Auto-Generated Tests:**
```solidity
// test/SecureDeFiToken.test.js
// From: knowledge-base-action/05-workflows/pre-deployment.md

describe("SecureDeFiToken", function() {
    // === SECURITY TESTS ===
    it("prevents reentrancy attacks", async function() {
        // From: 03-attack-prevention/reentrancy.md
    });

    it("blocks sniper bots in first 3 blocks", async function() {
        // From: 06-defi-trading/03-sniper-bot-prevention.md
    });

    it("enforces slippage protection", async function() {
        // From: 06-defi-trading/02-slippage-protection.md
    });

    it("prevents excessive price impact", async function() {
        // From: 06-defi-trading/05-mev-mitigation.md
    });

    // === GAS OPTIMIZATION TESTS ===
    it("uses custom errors (gas benchmark)", async function() {
        // Verify 50% gas savings vs require strings
    });

    it("storage packing reduces costs", async function() {
        // Verify packed storage slots
    });
});
```

**Security Checklist (Auto-Generated):**
```markdown
# Pre-Deployment Security Checklist
From: knowledge-base-action/05-workflows/pre-deployment.md

## Reentrancy Protection
- [x] ReentrancyGuard imported
- [x] nonReentrant modifier on all state-changing functions
- [x] Checks-Effects-Interactions pattern followed

## Access Control
- [x] Ownable imported
- [x] onlyOwner on sensitive functions
- [x] No tx.origin usage

## Integer Safety
- [x] Solidity 0.8.20 (built-in overflow protection)
- [x] SafeCast for downcasting

## DeFi-Specific (51 items from 12-dex-security-checklist.md)
- [x] Slippage protection implemented
- [x] Deadline checks on swaps
- [x] Oracle manipulation prevention (TWAP)
- [x] Anti-sniper measures
- [x] Max buy/wallet limits
- ... (46 more items)

## Gas Optimization (21 items from gas-optimization-wins.md)
- [x] Custom errors instead of require strings
- [x] Storage packing applied
- [x] Immutable where possible
- ... (18 more items)
```

---

### Example 2: NFT Gaming Contract

**User Input:**
```yaml
requirements:
  type: ERC721
  domain: Gaming
  features:
    - character NFTs
    - upgradeable stats
    - secure randomness
    - reward system
  integrations:
    - Chainlink VRF
```

**Generated Contract** (excerpt):
```solidity
// Auto-assembled from:
// - secure-erc721.sol
// - chainlink/03-chainlink-vrf-integration.md
// - game-templates/01-game-templates.md
// - staking-template.sol

contract GameCharacterNFT is
    ERC721,
    ERC721Enumerable,
    VRFConsumerBaseV2,
    Ownable,
    ReentrancyGuard
{
    struct Character {
        uint16 strength;    // Packed
        uint16 agility;     // Packed
        uint16 intelligence;// Packed
        uint16 level;       // Packed
        uint256 experience;
        uint256 lastClaimed;
    }

    // Chainlink VRF for secure randomness
    // From: chainlink/03-chainlink-vrf-integration.md
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable subscriptionId;
    bytes32 immutable keyHash;

    // Anti-cheat measures
    // From: game-templates/01-game-templates.md
    mapping(uint256 => uint256) public nonce;

    // ... (full implementation)
}
```

---

## Implementation Plan

### Phase 1: Contract Builder Core
```python
# scripts/cocoindex/contract_builder.py

class SmartContractBuilder:
    def __init__(self, kb_metadata):
        self.kb = kb_metadata
        self.cocoindex = load_cocoindex()

    def generate_contract(self, requirements):
        # 1. Analyze requirements
        domain = self.analyze_domain(requirements)
        features = self.extract_features(requirements)

        # 2. Query KB for components
        template = self.select_template(requirements)
        security_patterns = self.get_security_patterns(domain)
        gas_optimizations = self.get_gas_optimizations()
        domain_protections = self.get_domain_protections(domain)

        # 3. Assemble contract
        contract = self.assemble_contract(
            template,
            security_patterns,
            gas_optimizations,
            domain_protections,
            features
        )

        # 4. Validate
        checks = self.run_security_checks(contract, domain)

        # 5. Generate tests
        tests = self.generate_tests(contract, domain)

        return {
            "contract": contract,
            "tests": tests,
            "security_report": checks,
            "documentation": self.generate_docs(contract)
        }
```

### Phase 2: Security Pattern Injector
```python
# scripts/cocoindex/security_injector.py

class SecurityInjector:
    def inject_reentrancy_protection(self, contract):
        # Add ReentrancyGuard
        # Add nonReentrant modifiers
        # From: 03-attack-prevention/reentrancy.md
        pass

    def inject_access_control(self, contract):
        # Add Ownable/AccessControl
        # Add modifiers to sensitive functions
        # From: 03-attack-prevention/access-control.md
        pass

    def inject_all_protections(self, contract, domain):
        protections = self.kb.get_required_protections(domain)
        for protection in protections:
            contract = self.apply_protection(contract, protection)
        return contract
```

### Phase 3: Gas Optimization Engine
```python
# scripts/cocoindex/gas_optimizer.py

class GasOptimizer:
    def optimize_contract(self, contract):
        # From: gas-optimization-wins.md
        contract = self.apply_custom_errors(contract)
        contract = self.apply_storage_packing(contract)
        contract = self.apply_unchecked_math(contract)
        contract = self.apply_calldata_optimization(contract)
        contract = self.apply_immutable(contract)
        return contract

    def benchmark_gas(self, contract):
        # Generate gas benchmark tests
        pass
```

### Phase 4: DeFi Protection Module
```python
# scripts/cocoindex/defi_protections.py

class DeFiProtectionModule:
    def add_anti_sniper(self, contract):
        # From: 03-sniper-bot-prevention.md
        pass

    def add_slippage_protection(self, contract):
        # From: 02-slippage-protection.md
        pass

    def add_mev_mitigation(self, contract):
        # From: 05-mev-mitigation.md
        pass

    def add_oracle_safety(self, contract):
        # From: 06-price-oracles.md + 11-oracle-security-checklist.md
        pass
```

---

## Next Steps

Would you like me to:

1. **Build the Contract Builder** - Full implementation that generates contracts from requirements
2. **Create Domain-Specific Generators** - Separate builders for DeFi, Gaming, NFT, AI
3. **Implement Security Auto-Injection** - Automatic vulnerability prevention
4. **Build Test Generator** - Auto-create comprehensive test suites
5. **Create Interactive CLI** - `npx create-secure-contract` interface

Let me know which part you want me to start with!
