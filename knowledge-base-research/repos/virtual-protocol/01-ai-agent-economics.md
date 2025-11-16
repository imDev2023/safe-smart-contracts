# Virtual Protocol - AI Agent Economics & Multi-DAO Governance

> Decentralized protocol for creating and managing AI agents with economic incentives and DAO governance

**Repo:** https://github.com/Virtual-Protocol/protocol-contracts.git
**Purpose:** Framework for instantiating, governing, and rewarding AI agents
**Key Innovation:** Multi-DAO system + Agent token-bound accounts (TBA) + Contribution tracking

---

## Architecture Overview

### Key Contracts

| Contract | Purpose | Type |
|----------|---------|------|
| **veVirtualToken** | Non-transferrable voting token for governance | ERC721-like |
| **VirtualProtocolDAO** | Main ecosystem governance | DAO |
| **VirtualGenesisDAO** | Approval for new agent instantiation | DAO |
| **AgentFactory** | Creates new agents (cloning AgentToken + AgentDAO) | Factory |
| **AgentNft** | Registry of Persona/Core/Validator personas | ERC721-like |
| **AgentToken** | Agent-specific staking token (cloned per agent) | Token |
| **AgentDAO** | Agent-specific governance (cloned per agent) | DAO |
| **ContributionNft** | Tracks contributions to agents | NFT |
| **ServiceNft** | Approved services/upgrades for agents | NFT |
| **AgentReward** | Centralized reward distribution center | Distribution |
| **TimeLockStaking** | VIRTUAL → sVIRTUAL staking pool | Staking |

---

## Virtual Agent Lifecycle

### Phase 1: Agent Genesis (Application → Instantiation)

```
Step 1: Submit Application
  └─ User calls: AgentFactory.submitApplication()
     ├─ Transfers VIRTUAL token
     ├─ Specifies symbol (becomes $PERSONA name)
     └─ Creates pending application

Step 2: Governance Proposal
  └─ Anyone calls: VirtualGenesisDAO.propose(action: VirtualFactory.executeApplication)
     └─ VirtualGenesisDAO votes on new agent approval

Step 3: Execute Proposal
  └─ VirtualGenesisDAO.execute() triggers:
     ├─ Clone AgentToken contract
     ├─ Clone AgentDAO contract
     ├─ Mint AgentNft (represents the agent/persona)
     ├─ Stake VIRTUAL → sVIRTUAL → mint $PERSONA
     └─ Create TBA (Token Bound Account) using AgentNft
```

**Result:** New AI agent with:
- Unique $PERSONA token (e.g., $ALICE for Alice agent)
- Individual AgentDAO for governance
- Individual AgentToken for staking
- TBA for account abstraction
- Transaction history on-chain

---

### Phase 2: Contribution Submission

```
Step 1: Create Proposal
  └─ Contributor calls: AgentDAO.propose(action: ServiceNft.mint)
     └─ Proposes new contribution/service upgrade

Step 2: Mint ContributionNft
  └─ Contributor calls: ContributionNft.mint(proposalId)
     ├─ Verifies caller is proposal creator
     └─ Mints proof-of-contribution NFT

Step 3: Validator Voting
  └─ Validators vote at AgentDAO on:
     - Accept contribution?
     - Update maturity score?
     - Award VIRTUAL tokens?
```

**Key Pattern:** Contribution NFT serves as authentication + proof of participation

---

### Phase 3: Agent Upgrade (Core Service Execution)

```
Step 1: Validator Vote
  └─ Validators at AgentDAO vote on ServiceNft proposal

Step 2: Execute Upgrade
  └─ AgentDAO.execute() triggers:
     ├─ Mint ServiceNft (approved service certificate)
     ├─ Update maturity score (agent quality metric)
     ├─ Update VIRTUAL core service ID
     └─ Emit events for off-chain systems

Result: Agent improved with new capability + on-chain audit trail
```

---

## Reward Distribution System

### Daily Reward Flow

```
Day Summary:
  ├─ Protocol backend calculates daily profits
  ├─ Calls: AgentReward.distributeRewards(dailyAmount)
  └─ Distributes to 5 stakeholder groups:

1. Protocol Treasury (DAO governance)
2. sVIRTUAL Stakers (token holders)
3. Validators (contributed to quality)
4. Dataset Contributors (data labeling)
5. Model Contributors (model improvements)
```

**Source:** `AgentReward.distributeRewards()` - Updates claimable amounts per stakeholder

### Reward Claiming

```
User Side:
  ├─ Stakers/Validators call: AgentReward.claimAllRewards()
  ├─ Receive earned VIRTUAL
  └─ Optional: Restake or exit

Protocol Side:
  └─ AgentReward.withdrawProtocolRewards()
     └─ Treasury withdraws ecosystem profits
```

---

## Staking & Delegation System

### VIRTUAL → $PERSONA Staking

```
User Flow:
  1. User acquires VIRTUAL tokens
  2. Calls: AgentToken.stake(validatorAddress)
     ├─ Transfers sVIRTUAL (staked VIRTUAL)
     ├─ Mints $PERSONA tokens (1:1 ratio)
     └─ Delegates voting power to validator

Result:
  - User holds $PERSONA (agent-specific token)
  - Validator has delegation vote power
  - User eligible for staking rewards

Unstaking:
  - Call: AgentToken.withdraw()
  - Burns $PERSONA
  - Returns sVIRTUAL + earned rewards
```

**Key Concept:** Voting power delegation to validators who curate agent quality

---

## Governance Tiers

### Tier 1: VirtualGenesisDAO
```
Purpose: Approve new agents
Voters: veVIRTUAL holders
Quorum: 10,000 votes (early execution possible)
Features: Early execution as soon as quorum reached (vs waiting for full period)
```

### Tier 2: VirtualProtocolDAO
```
Purpose: Ecosystem-wide decisions
Voters: veVIRTUAL holders
Scope: Protocol upgrades, fee adjustments, reward parameters
```

### Tier 3: AgentDAO (Per-Agent)
```
Purpose: Individual agent governance
Voters: $PERSONA token holders
Scope: Service upgrades, quality metrics, agent-specific improvements
```

**Hierarchical System:** VirtualGenesisDAO > VirtualProtocolDAO > Individual AgentDAOs

---

## Key Design Patterns

### 1. Cloning Pattern for Agent Instantiation

```solidity
// AgentFactory clones these per new agent:
- AgentToken (staking mechanism)
- AgentDAO (governance mechanism)

Benefits:
├─ Isolated token economics per agent
├─ Independent governance per agent
├─ No shared state between agents
└─ Scalable to thousands of agents
```

**Source Code Location:** AgentFactory.sol - uses CREATE2 for deterministic addresses

### 2. Multi-NFT Contribution Tracking

```
Three NFT Types:
├─ AgentNft - Agent identity + TBA
├─ ContributionNft - Proof of contribution submission
└─ ServiceNft - Proof of accepted contribution

Flow:
  Contribute → ContributionNft minted → Validator votes → ServiceNft minted

Benefits:
├─ On-chain audit trail
├─ Verifiable contribution history
├─ Reputation building for contributors
└─ Transparent quality metrics
```

### 3. TBA (Token Bound Account) Integration

```
AgentNft → TBA (ERC6551 or similar)
  ├─ Agent has blockchain wallet
  ├─ Can receive tokens/NFTs
  ├─ Can execute transactions
  ├─ Can hold assets earned through protocol
  └─ Programmable AI agent account
```

**Pattern:** Agent is both NFT + Account

---

## Reward Distribution Splits (Estimated)

Based on typical protocol design:

```
Daily Profits → AgentReward distributes:

├─ Protocol DAO Treasury ......... X%
├─ sVIRTUAL Stakers .............. Y%
├─ Validators (quality curators) . Z%
├─ Dataset Contributors .......... A%
└─ Model Contributors ............ B%
```

**Configuration:** Maintained in AgentReward contract, adjustable via governance

---

## Integration Points

### For External Protocols

1. **Query Agent Quality:** Check maturity score at AgentDAO
2. **Verify Contribution:** Check ServiceNft ownership/balance
3. **Agent Portfolio:** Query AgentNft holdings for Persona
4. **Reward Earning:** Integrate AgentReward distribution into strategy

### For User Interfaces

1. **Agent Discovery:** List AgentNft holders (all agents)
2. **Staking Dashboard:** Show $PERSONA holdings + rewards
3. **Contribution Feed:** Stream ContributionNft + ServiceNft mints
4. **Governance Interface:** Multi-DAO voting aggregation

---

## When to Reference Virtual Protocol

✅ Building AI agent platforms with economic incentives
✅ Multi-DAO governance systems
✅ Contribution/reputation tracking
✅ Reward distribution mechanisms
✅ Token-bound accounts (TBA) patterns
✅ Agent cloning/instantiation factories

---

## Key Files to Study

**Core Contracts:**
- `AgentFactory.sol` - Agent instantiation logic
- `AgentToken.sol` - Per-agent staking token (cloned)
- `AgentDAO.sol` - Per-agent governance (cloned)
- `AgentReward.sol` - Reward distribution center
- `VirtualGenesisDAO.sol` - Agent approval DAO

**Supporting:**
- `AgentNft.sol` - Agent identity + TBA
- `ContributionNft.sol` - Contribution tracking
- `ServiceNft.sol` - Service certificate
- `VirtualProtocolDAO.sol` - Ecosystem governance

---

**Status:** Complex multi-agent economics system
**Best For:** Building incentivized AI platforms with governance
**Difficulty:** Advanced (multiple DAOs + factory patterns)
