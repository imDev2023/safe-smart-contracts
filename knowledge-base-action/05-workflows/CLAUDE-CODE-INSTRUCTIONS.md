# Claude Code Project Instructions
## Smart Contract Development with Dual Knowledge Base Strategy

**Version:** 2.0
**Last Updated:** November 15, 2025
**Status:** Production Ready

> This file is read automatically by Claude Code when you start a project in this directory. Follow these instructions strictly for building secure, production-ready smart contracts.

---

## 🎯 Core Philosophy

You have TWO complementary knowledge bases:

- **ACTION KB** (31 files) - Fast, production-ready guidance
- **RESEARCH KB** (200+ files) - Deep understanding and novel patterns

**Your job:** Know when to use each.

---

## 📚 Knowledge Base Structure

### ACTION KB (knowledge-base-action/)
**31 files organized in 6 sections**

```
00-START-HERE.md                    Master navigation for all users

01-quick-reference/                 Fast lookup (1-5 min)
├── vulnerability-matrix.md         20 vulnerabilities at a glance
├── pattern-catalog.md              10 design patterns
├── gas-optimization-wins.md        21 techniques ranked by impact
├── oz-quick-ref.md                 OpenZeppelin quick reference
└── security-checklist.md           360+ pre-deployment items

02-contract-templates/              Production-ready code (copy-paste)
├── secure-erc20.sol
├── secure-erc721.sol
├── access-control-template.sol
├── upgradeable-template.sol
├── staking-template.sol
├── pausable-template.sol
└── multisig-template.sol

03-attack-prevention/               Vulnerability guides (all 10)
├── reentrancy.md
├── access-control.md
├── integer-overflow.md
├── frontrunning.md
├── dos-attacks.md
├── timestamp-dependence.md
├── unsafe-delegatecall.md
├── unchecked-returns.md
├── tx-origin.md
└── flash-loan-attacks.md

04-code-snippets/                   Copy-paste components (172+ snippets)
├── oz-imports.md
├── modifiers.md
├── events.md
├── errors.md
└── libraries.md

05-workflows/                       Step-by-step processes
├── contract-development.md        8-phase development (2-4 weeks)
└── pre-deployment.md              400+ verification items
```

### RESEARCH KB (knowledge-base-research/)
**200+ files from 8 authoritative sources**

```
repos/
├── consensys/                      65 files - Best practices & attacks
├── vulnerabilities/                42 files - Detailed vulnerability analysis
├── not-so-smart/                   45 files - Real exploit examples
├── patterns/                       16 files - Design patterns deep dive
├── gas-optimization/               12 files - 100+ optimization techniques
└── openzeppelin/                   16 files - Reference implementations
```

---

## 🎯 Decision Tree: Which KB to Use?

```
START: Do I have a clear path to the solution?
│
├─ Is this a standard contract type (ERC20/721/multisig)?
│  ├─ YES → Use ACTION KB templates ONLY
│  │         (Copy-paste, customize, done in 2-4 hours)
│  └─ NO → Continue
│
├─ Does ACTION KB have a template or quick-ref for this?
│  ├─ YES → Use ACTION KB (fast path)
│  └─ NO → Continue
│
├─ Is this a quick security check?
│  ├─ YES → ACTION KB vulnerability-matrix.md (5 min)
│  └─ NO → Continue
│
├─ Do I need to UNDERSTAND WHY something works?
│  ├─ YES → Use RESEARCH KB (study multiple sources)
│  └─ NO → Continue
│
├─ Am I building something NOVEL/COMPLEX?
│  ├─ YES → Use RESEARCH KB + ACTION KB (combine patterns)
│  └─ NO → Continue
│
├─ Does the CLIENT need detailed explanation?
│  ├─ YES → Use RESEARCH KB (authoritative sources + evidence)
│  └─ NO → Continue
│
└─ Am I debugging UNUSUAL behavior?
   ├─ Start ACTION KB (common issues)
   └─ If not found → RESEARCH KB (edge cases)
```

---

## 📋 When to Use ACTION KB Only

### Scenario 1: Standard Contract Building
**Time:** 2-4 hours
**Complexity:** Low
**Value:** $5K-15K

```
Examples:
- Build an ERC20 token
- Build an NFT collection
- Build a multi-sig wallet
- Build standard staking

Process:
1. Read: 00-START-HERE.md
2. Copy: 02-contract-templates/[template].sol
3. Customize for requirements
4. Apply: 01-quick-reference/ (security, gas, patterns)
5. Use: 04-code-snippets/ (modifiers, events, errors)
6. Follow: 05-workflows/pre-deployment.md
7. Deploy

Knowledge Base Used: 95% ACTION, 5% RESEARCH
```

### Scenario 2: Quick Security Check
**Time:** 15-30 minutes
**Complexity:** Very Low

```
Examples:
- "Is this vulnerable?"
- "Did I check everything?"
- "What security features should this have?"

Process:
1. Read: 01-quick-reference/vulnerability-matrix.md (20 items)
2. Read: 01-quick-reference/security-checklist.md (relevant sections)
3. For specific attacks: 03-attack-prevention/ (specific file)

Knowledge Base Used: 100% ACTION KB
```

### Scenario 3: Code Snippet Lookup
**Time:** 5-10 minutes
**Complexity:** Very Low

```
Examples:
- "How do I write a modifier for access control?"
- "What should this event look like?"
- "How do I import from OpenZeppelin?"

Process:
1. Go to: 04-code-snippets/
2. Copy-paste the snippet
3. Customize for your contract

Knowledge Base Used: 100% ACTION KB
```

### Scenario 4: Gas Optimization Quick Tips
**Time:** 10-20 minutes
**Complexity:** Low

```
Process:
1. Read: 01-quick-reference/gas-optimization-wins.md
2. Apply top 10 techniques
3. Estimate savings

Knowledge Base Used: 100% ACTION KB
```

---

## 🔬 When to Use BOTH KBs (50/50)

### Scenario 1: Moderate Complexity Contracts
**Time:** 8-16 hours
**Complexity:** Moderate
**Value:** $15K-30K

```
Examples:
- Custom staking with tiered rewards
- Multi-token system
- Advanced governance
- Hybrid contract combining multiple patterns

Process:
Phase 1: ACTION KB - Get oriented
1. Read: 00-START-HERE.md
2. Read: 01-quick-reference/pattern-catalog.md
3. Find closest template
4. Plan customizations

Phase 2: RESEARCH KB - Understand deeply
1. Study: knowledge-base-research/repos/openzeppelin/
2. Analyze: knowledge-base-research/repos/patterns/
3. Review: knowledge-base-research/repos/consensys/
4. Compare approaches

Phase 3: Synthesis
1. Decide which patterns to combine
2. Plan trade-offs
3. Explain WHY this approach

Phase 4: ACTION KB - Build & optimize
1. Start with closest template
2. Customize based on research
3. Apply security from: 01-quick-reference/vulnerability-matrix.md
4. Apply gas optimizations
5. Use snippets from: 04-code-snippets/

Phase 5: ACTION KB - Final verification
1. Follow: 05-workflows/pre-deployment.md
2. Self-audit against: 03-attack-prevention/ (all 10)

Knowledge Base Used: 40% ACTION, 60% RESEARCH
```

### Scenario 2: Client Needs Detailed Explanation
**Time:** 2-6 hours
**Complexity:** Medium
**Goal:** Client education

```
Examples:
- "Why AccessControl instead of Ownable?"
- "Why use a proxy pattern?"
- "Explain the security trade-offs"

Process:
1. RESEARCH KB: Study topic in depth
   - repos/openzeppelin/
   - repos/consensys/
   - repos/patterns/

2. Synthesize: Compare approaches
   - List pros/cons with sources
   - Cite real-world examples
   - Show trade-offs

3. ACTION KB: Show practical implementation
   - Code example from templates
   - Reference quick-ref
   - Gas cost comparison

4. Create: Deliverable document with sources cited

Knowledge Base Used: 30% ACTION, 70% RESEARCH
```

---

## 🏆 When to Use RESEARCH KB Heavy (70%+)

### Scenario 1: Novel/Complex Patterns
**Time:** 16-40 hours
**Complexity:** High
**Value:** $30K-100K+

```
Examples:
- Novel DeFi protocol design
- Custom governance mechanism
- Experimental token economics
- Complex state machine

Process:
Phase 1: RESEARCH KB (Deep dive)
1. Study all relevant sources:
   - knowledge-base-research/repos/openzeppelin/ (patterns)
   - knowledge-base-research/repos/patterns/ (design patterns)
   - knowledge-base-research/repos/consensys/ (security)
   - knowledge-base-research/repos/gas-optimization/ (efficiency)

2. Compare: Multiple implementations of similar concepts
3. Analyze: Trade-offs of each approach
4. Synthesize: Novel combination of patterns

Phase 2: Planning (with RESEARCH backing)
1. Document approach with sources cited
2. Explain WHY this design
3. Highlight security considerations
4. Estimate gas costs

Phase 3: ACTION KB (Build using best practices)
1. Create custom template based on research
2. Apply ACTION KB standards
3. Use snippets from 04-code-snippets/
4. Follow 05-workflows/ (modified for complexity)

Phase 4: Validation
1. Security audit against 03-attack-prevention/
2. Gas optimization review
3. Test coverage planning

Knowledge Base Used: 20% ACTION, 80% RESEARCH
```

### Scenario 2: Incident Response / Debugging
**Time:** 2-8 hours
**Complexity:** High
**Goal:** Identify and fix exploit

```
Examples:
- Contract was exploited, understand why
- Unusual behavior under specific conditions
- Edge case handling needed

Process:
Phase 1: ACTION KB (Quick diagnosis)
1. Check: 03-attack-prevention/ (relevant vulnerabilities)
2. Check: 01-quick-reference/vulnerability-matrix.md

Phase 2: RESEARCH KB (Deep analysis)
If not found in ACTION KB:
1. Study: knowledge-base-research/repos/vulnerabilities/
2. Review: knowledge-base-research/repos/not-so-smart/
3. Compare: knowledge-base-research/repos/consensys/
4. Research: Similar exploits/edge cases

Phase 3: Root cause analysis
1. Understand attack vector fully
2. Cite sources
3. Assess damage

Phase 4: ACTION KB (Solution)
1. Create fix using best practices
2. Verify against security checklist
3. Test thoroughly

Knowledge Base Used: 20% ACTION, 80% RESEARCH
```

### Scenario 3: Academic/Research Work
**Time:** 20-60 hours
**Complexity:** Very High
**Goal:** Novel contribution to field

```
Process:
1. Extensive RESEARCH KB study
2. Identify gap or opportunity
3. Design novel solution
4. Implement with ACTION KB standards
5. Write comprehensive documentation

Knowledge Base Used: 10% ACTION, 90% RESEARCH
```

---

## 🎬 Prompt Templates

### Template 1: Standard Building (ACTION KB Only)
```
Build me a [CONTRACT TYPE] using knowledge-base-action/:

Requirements:
[Your requirements here]

Process:
1. Use template: knowledge-base-action/02-contract-templates/[TEMPLATE].sol
2. Check security: knowledge-base-action/01-quick-reference/vulnerability-matrix.md
3. Apply gas optimizations: knowledge-base-action/01-quick-reference/gas-optimization-wins.md
4. Use snippets: knowledge-base-action/04-code-snippets/
5. Follow workflow: knowledge-base-action/05-workflows/contract-development.md

Constraints:
- Must pass all 360+ items in security-checklist.md
- Must prevent all 10 vulnerabilities in attack-prevention/
- Estimated gas cost at [CHAIN] gas prices
```

### Template 2: Moderate Complexity (BOTH KBs)
```
Build me a [CONTRACT TYPE] using BOTH knowledge bases:

Requirements:
[Your requirements]

Phase 1: RESEARCH KB (Understanding)
1. Research similar patterns in: knowledge-base-research/repos/
2. Compare at least 3 approaches
3. Explain your chosen approach with sources cited
4. Highlight trade-offs and risks

Phase 2: ACTION KB (Implementation)
1. Start with closest template: 02-contract-templates/
2. Apply customizations based on research
3. Use snippets: 04-code-snippets/
4. Verify security: 03-attack-prevention/
5. Optimize gas: 01-quick-reference/gas-optimization-wins.md
6. Follow: 05-workflows/

Phase 3: Validation
1. Self-audit against pre-deployment.md
2. Test plan
3. Deployment instructions

Expected outcome: Production-ready contract with design explained
```

### Template 3: Novel Pattern (RESEARCH KB Heavy)
```
Design a [NOVEL PATTERN] for [USE CASE] using BOTH knowledge bases:

Requirements:
[Your requirements]

Phase 1: COMPREHENSIVE RESEARCH (knowledge-base-research/)
1. Study: repos/openzeppelin/ (patterns & security contracts)
2. Study: repos/patterns/ (design patterns)
3. Study: repos/consensys/ (best practices)
4. Study: repos/gas-optimization/ (efficiency techniques)

Analysis:
- Compare 3+ approaches for similar problems
- Document pros/cons with sources
- Identify best patterns to combine
- Highlight security considerations

Phase 2: Design Synthesis
Explain:
- Your approach (with RESEARCH citations)
- Why this design (security/efficiency/scalability)
- Potential risks and mitigations
- Gas cost estimate

Phase 3: Implementation (ACTION KB)
1. Implement using best practices
2. Apply all security standards
3. Optimize gas
4. Generate tests

Phase 4: Documentation
- Comprehensive comments in code
- Design document with sources
- Test plan
- Deployment instructions

Expected outcome: Novel, well-researched, production-ready solution
```

### Template 4: Security Audit (BOTH KBs)
```
Audit this contract using BOTH knowledge bases:

Contract: [PATH or ADDRESS]

Phase 1: Quick Scan (ACTION KB)
1. Check against: vulnerability-matrix.md (20 items)
2. Check against: security-checklist.md (360+ items)
3. For issues found, check: 03-attack-prevention/

Phase 2: Deep Analysis (RESEARCH KB)
For each issue:
1. Research: repos/vulnerabilities/
2. Compare: repos/not-so-smart/
3. Study: repos/consensys/
4. Find: Similar exploits or patterns

Phase 3: Report
For each issue:
- Severity (Critical/High/Medium/Low)
- Description (what it is)
- Example (from RESEARCH KB)
- Impact (what can go wrong)
- Fix (with code, from ACTION KB)
- Prevention (for future)

Deliverable:
- Executive summary (1 page)
- Detailed findings (sources cited)
- Risk assessment
- Recommended fixes with code
```

### Template 5: Gas Optimization Deep Dive (RESEARCH KB Heavy)
```
Optimize this contract for maximum gas efficiency:

Contract: [PATH]
Target: [% reduction or absolute gas limit]

Phase 1: RESEARCH KB Analysis (knowledge-base-research/)
1. Study: repos/gas-optimization/ (all techniques)
2. Study: repos/openzeppelin/ (gas-efficient patterns)
3. Identify: All optimization opportunities
4. Estimate: Savings for each technique

Phase 2: Implementation Strategy
1. Rank optimizations by impact
2. Plan for no security regressions
3. Estimate total savings

Phase 3: Implement (ACTION KB standards)
1. Apply optimizations iteratively
2. Benchmark after each change
3. Verify no security impact
4. Document all changes

Phase 4: Verification
- Before/after gas costs
- Security re-verification
- Complete change log
- Cost/benefit analysis

Deliverable:
- Optimized contract
- Detailed optimization report
- Benchmark data
- All changes documented with sources
```

---

## ⚡ Quick Command Reference

### For Standard Projects
```
1. Read: knowledge-base-action/00-START-HERE.md
2. Copy: knowledge-base-action/02-contract-templates/[template].sol
3. Use: search.sh --templates
4. Follow: knowledge-base-action/05-workflows/contract-development.md
```

### For Security Review
```
1. Check: search.sh --vulnerabilities
2. Use: knowledge-base-action/01-quick-reference/security-checklist.md
3. Reference: knowledge-base-action/03-attack-prevention/
4. Validate: knowledge-base-action/05-workflows/pre-deployment.md
```

### For Novel Patterns
```
1. Research: knowledge-base-research/repos/openzeppelin/
2. Study: knowledge-base-research/repos/patterns/
3. Analyze: knowledge-base-research/repos/consensys/
4. Implement: Using ACTION KB templates as foundation
5. Validate: Using ACTION KB verification processes
```

### Search Knowledge Base
```
./search.sh "keyword"              # Search for topic
./search.sh --templates            # List all templates
./search.sh --vulnerabilities      # List all attacks
./search.sh --patterns             # List all patterns
./search.sh --stats                # Show statistics
./search.sh --help                 # Full help menu
```

---

## ✅ Mandatory Checklist Before EVERY Project

### Before Writing ANY Code
- [ ] Read: `knowledge-base-action/00-START-HERE.md`
- [ ] Use decision tree: ACTION KB only? Or BOTH?
- [ ] Select template/pattern to base work on
- [ ] Check: Does `knowledge-base-action/vulnerability-matrix.md` apply?

### Before Submitting Contract
- [ ] Read: `knowledge-base-action/05-workflows/pre-deployment.md`
- [ ] Complete: All 400+ verification items
- [ ] Check: All 10 vulnerabilities from `03-attack-prevention/`
- [ ] Apply: Top 10 gas optimizations
- [ ] Generate: Testing plan

### Before Deploying
- [ ] Testnet deployment passed
- [ ] All tests pass
- [ ] Gas costs acceptable
- [ ] Security audit clean (using KB)
- [ ] Client review complete

---

## 🎓 Knowledge Base Usage Patterns

### Pattern 1: Copy-Paste Fast Track (Standard Projects)
```
Time: 2-4 hours
Knowledge: ACTION KB only (templates + quick-ref)
Skill needed: Low

Process:
1. Find template
2. Copy-paste
3. Customize
4. Security check
5. Deploy

Example: ERC20 token
```

### Pattern 2: Thoughtful Building (Moderate Projects)
```
Time: 8-16 hours
Knowledge: ACTION KB + RESEARCH KB (50/50)
Skill needed: Medium

Process:
1. Research approach
2. Plan design
3. Build from template
4. Add custom features
5. Security audit
6. Optimize gas
7. Deploy

Example: Custom staking system
```

### Pattern 3: Expert Craftsmanship (Novel Projects)
```
Time: 20-60 hours
Knowledge: RESEARCH KB heavy + ACTION KB standards
Skill needed: High

Process:
1. Study multiple sources in RESEARCH KB
2. Design novel solution
3. Document approach
4. Implement with ACTION KB standards
5. Comprehensive testing
6. Deploy

Example: Novel DeFi protocol
```

---

## 🔴 Critical Rules - NEVER Break These

### Rule 1: Security First, Always
```
❌ Never skip security checks
✅ Always check vulnerability-matrix.md
✅ Always check pre-deployment.md
✅ Always check relevant attack-prevention guides

When in doubt: Be MORE secure, not less
```

### Rule 2: Use Templates When Possible
```
❌ Never write contracts from scratch
✅ Always start with closest template
✅ Always customize incrementally
✅ Always reference what you change and why

Reason: Templates are battle-tested
```

### Rule 3: Copy-Paste from KB Only
```
❌ Never write custom modifiers if KB has them
❌ Never write custom errors without checking KB
✅ Always use KB snippets when available
✅ Always cite source in code comments

Reason: KB code is audited and proven
```

### Rule 4: Explain Trade-Offs
```
❌ Never make decision without understanding trade-offs
✅ Always document WHY you chose each approach
✅ Always explain security vs. efficiency trade-offs
✅ Always cite sources (especially from RESEARCH KB)

Reason: Client needs to understand risks
```

### Rule 5: Complete Security Audit
```
❌ Never declare contract "done" without full audit
✅ Always run through ALL 360+ security items
✅ Always check against ALL 10 critical attacks
✅ Always estimate and optimize gas costs

Reason: Security is non-negotiable
```

---

## 🎯 Success Metrics

You've used the KB correctly when:

### For Standard Projects
- ✅ Used ACTION KB template as base
- ✅ Modified minimally for requirements
- ✅ Passed all 360+ security checks
- ✅ Applied top 10 gas optimizations
- ✅ Generated in 2-4 hours
- ✅ Client happy with cost

### For Complex Projects
- ✅ Researched multiple approaches in RESEARCH KB
- ✅ Documented design with sources
- ✅ Explained trade-offs clearly
- ✅ Implemented with ACTION KB standards
- ✅ Passed all security checks
- ✅ Optimized gas thoroughly
- ✅ Generated in 8-16 hours
- ✅ Client understands WHY

### For Novel Projects
- ✅ Studied multiple RESEARCH sources
- ✅ Synthesized novel design
- ✅ Documented comprehensively
- ✅ Implemented expertly
- ✅ Near-perfect security audit
- ✅ Novel gas optimizations found
- ✅ Generated in 20-40 hours
- ✅ Client sees innovation

---

## 📞 Troubleshooting

### Problem: Don't know where to start
**Solution:** Read `knowledge-base-action/00-START-HERE.md` first, then use decision tree above

### Problem: Can't find template for my use case
**Solution:** Use BOTH KBs - research similar patterns, combine them

### Problem: Security concern not in vulnerability-matrix.md
**Solution:** Check all 10 guides in `03-attack-prevention/`, then RESEARCH KB

### Problem: Gas costs too high
**Solution:** Apply `gas-optimization-wins.md`, then research `repos/gas-optimization/`

### Problem: Can't explain design decision to client
**Solution:** Use RESEARCH KB sources - cite them when explaining

### Problem: Weird behavior in contract
**Solution:** Start ACTION KB → If not found → RESEARCH KB edge cases

---

## 🚀 You're Ready When

You understand:

- ✅ When to use ACTION KB (standard, quick)
- ✅ When to use RESEARCH KB (novel, deep)
- ✅ How to follow decision tree
- ✅ Complete security checklist
- ✅ How to explain trade-offs
- ✅ How to cite sources
- ✅ Complete pre-deployment workflow

**Now build amazing smart contracts.** 🎉

---

**Last Updated:** November 15, 2025
**Status:** Production Ready ✅
**Questions?** See `knowledge-base-action/00-START-HERE.md`
