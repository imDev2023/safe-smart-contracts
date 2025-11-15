# Deduplication Rules & Strategy

**Version:** 1.0
**Created:** November 15, 2025
**Last Updated:** November 15, 2025

---

## Overview

This document defines how duplicate content is detected, handled, and merged when syncing the Research Knowledge Base into the Action Knowledge Base.

---

## Deduplication Philosophy

The Research KB intentionally contains overlapping content from multiple sources to allow comparison and cross-reference. When synthesizing into the Action KB, we must eliminate this overlap while preserving the best explanation from each source.

**Goals:**
1. **Zero overlap** - Each topic covered once, not repeated
2. **Best content** - Keep the most comprehensive/best-explained version
3. **Traceability** - Can reference back to original sources
4. **Freshness** - Regular updates as sources change

---

## Detection Strategy

### 1. Content Hash Matching
Use SHA256 hashing to detect identical content:

```bash
# Generate hash of file content
sha256sum knowledge-base-research/repos/vulnerabilities/reentrancy.md

# Compare hashes
if [ "$HASH_1" = "$HASH_2" ]; then
    echo "Identical content found"
fi
```

**Pros:** Fast, exact matches
**Cons:** Misses similar but different content

### 2. Semantic Similarity
Use text similarity algorithms to detect paraphrased content:

```
Similarity Score = matching_text / total_text_length

- Score > 0.90: Likely duplicate (>90% similar)
- Score 0.70-0.90: Probable duplicate (70-90% similar)
- Score < 0.70: Unique content (< 70% similar)
```

**Method:** Jaccard similarity, TF-IDF, or simple word overlap

**Threshold:** 0.85 (85% similar = duplicate)

### 3. Manual Review
Human review for edge cases:
- Different formatting, same content
- Multiple variations on same topic
- Content that should be merged vs kept separate

---

## Duplication Categories

### Category 1: Exact Duplicates
**Definition:** Identical content from multiple sources
**Example:** Same attack explanation in both ConsenSys and vulnerabilities repos

**Resolution:**
1. Identify all sources
2. Keep version with best presentation
3. Reference other sources in notes
4. Delete duplicates

**Example Decision:**
```
Found in:
  - repos/consensys/03-attacks/reentrancy.md (200 lines)
  - repos/vulnerabilities/reentrancy.md (250 lines)
  - repos/not-so-smart/reentrancy/ (multiple files)

Decision: Keep repos/vulnerabilities/reentrancy.md
Reason: Most comprehensive (250 lines), includes examples, real exploits
Note: Cross-reference ConsenSys version in references section
```

### Category 2: Partial Duplicates
**Definition:** Content covers same topic but different aspects
**Example:** One source explains reentrancy attack, another explains CEI pattern prevention

**Resolution:**
1. Merge into single comprehensive document
2. Combine best explanations from each
3. Maintain attribution to sources
4. Add examples from all sources

**Example Decision:**
```
Reentrancy Coverage:
  - ConsenSys: Good attack explanation
  - Vulnerabilities: Good prevention patterns
  - Patterns: Good CEI implementation

Decision: Merge all three
Result: Comprehensive reentrancy guide with:
  - Attack explanation (from ConsenSys)
  - Prevention methods (from Vulnerabilities)
  - Code examples (from Patterns)
  - Attribution to all sources
```

### Category 3: Variations
**Definition:** Same topic covered at different levels of detail
**Example:** Basic overview vs detailed deep-dive

**Resolution:**
1. Keep most detailed version in Action KB
2. Reference less detailed version for beginners
3. Link to Research KB for comparisons

**Example Decision:**
```
Integer Overflow Coverage:
  - ConsenSys: Basic explanation (1 page)
  - Vulnerabilities: Detailed with examples (5 pages)
  - Not-So-Smart: Real exploit examples

Decision: Keep Vulnerabilities version
Reason: Most comprehensive and accurate
Additional: Add Not-So-Smart examples
Reference: Link to ConsenSys for simpler overview
```

---

## Selection Criteria

When multiple versions exist, choose based on:

### 1. Completeness Score
- Code examples present? (+20 points)
- Real-world exploits documented? (+20 points)
- Prevention methods detailed? (+20 points)
- Testing examples included? (+15 points)
- Clear explanations? (+15 points)
- Graphics/diagrams? (+10 points)

**Winner:** Version with highest score

### 2. Accuracy & Recency
- Uses Solidity 0.8+ patterns? (+15 points)
- Post-merge Ethereum info? (+10 points)
- Includes recent exploits? (+10 points)
- No deprecated patterns? (+15 points)

### 3. Practical Usefulness
- Copy-paste ready code? (+15 points)
- Clear actionable advice? (+15 points)
- Good for audits? (+10 points)
- Good for learning? (+10 points)

### 4. Source Authority
- OpenZeppelin source? (+20 points)
- Trail of Bits? (+15 points)
- ConsenSys? (+15 points)
- Community maintained? (+10 points)

---

## Deduplication Workflow

### Step 1: Identify Duplicates
```bash
# 1. Hash-based detection
for file in knowledge-base-research/repos/*/*.md; do
    hash=$(sha256sum "$file" | cut -d' ' -f1)
    # Compare against all other files
done

# 2. Content-based detection
# Use Python/Node script for similarity scoring
python3 detect_duplicates.py
```

### Step 2: Score Versions
For each duplicate set:
1. Apply completeness scoring (above)
2. Apply accuracy scoring
3. Apply usefulness scoring
4. Apply authority scoring
5. **Calculate final score = average of all**

### Step 3: Select Winner
- Keep version with **highest final score**
- Document score breakdown
- Note runner-up versions for reference

### Step 4: Merge Content
```
If score difference > 20 points:
  → Keep winner, delete others

If score difference 10-20 points:
  → Keep winner, but add best parts from runner-up

If score difference < 10 points:
  → Merge both, clearly attributing each section
```

### Step 5: Add Attribution
```markdown
> **Sources:**
> - Primary: [Source A] (80 points)
> - Secondary: [Source B] (70 points)
> - Additional insights from: [Source C]
```

### Step 6: Log & Verify
```
Deduplication Log Entry:
- Topic: Reentrancy Attack
- Duplicates Found: 3
  1. consensys/03-attacks/reentrancy.md (70 points)
  2. vulnerabilities/reentrancy.md (95 points) ← WINNER
  3. not-so-smart/reentrancy/README.md (60 points)
- Action Taken: Kept #2, merged examples from #1 and #3
- Result File: action/03-attack-prevention/reentrancy.md
- Verification: ✓ Pass
```

---

## Specific Category Rules

### Vulnerabilities (10 files in action KB)
**Rule:** Exactly 10 in action KB (the top 10)

**Source Priority:**
1. Must exist in `repos/vulnerabilities/`
2. Must be in top 10 by severity
3. Must be unique (no variants like reentrancy variants separate)

**Scoring:** By severity (critical > high > medium > low)

**Examples:**
- Reentrancy: Keep comprehensive version, reference variants in notes
- Integer Overflow: Keep 0.8+ specific version
- Delegatecall: Keep Parity hack version (real example)

### Patterns (10 files in action KB)
**Rule:** Exactly 10 of most common patterns

**Source Priority:**
1. Most used in real contracts
2. Most explained in Research KB
3. Most relevant to Safe

**Scoring:** By frequency + usefulness

**Merge Rule:** Different pattern categories don't merge
**Keep Separate:**
- Reentrancy prevention (CEI pattern)
- Access Restriction pattern
- These are distinct patterns, not duplicates

### Gas Optimizations (21 techniques)
**Rule:** Top 21 by gas savings

**Source Priority:**
1. Verified benchmarks (WTF Academy)
2. Multiple sources confirming (harendra-shakya)
3. Research papers (0xisk)

**Scoring:** By gas savings percentage (measured in Foundry)

**Dedup Rule:** If multiple sources report same technique with different gas numbers, use WTF Academy's Foundry-tested number

### Quick References (5 files)
**Rule:** Exactly 5 synthesized files

**Dedup Strategy:**
- `vulnerability-matrix.md`: Merge from all vulnerability sources
- `pattern-catalog.md`: Merge from pattern sources
- `gas-optimization-wins.md`: Merge from gas sources
- `oz-quick-ref.md`: Merge from OZ documentation
- `security-checklist.md`: Merge from all sources

---

## Handling Conflicts

### Conflict Type 1: Different Explanations of Same Concept
**Example:** Two sources explain CEI pattern differently

**Resolution:**
```
Option A: Use source with clearer explanation
Option B: Merge both, showing different perspectives
Option C: Link to both in Research KB

→ Choose Option B if both are valuable
→ Add note: "Explanation A emphasizes X, Explanation B emphasizes Y"
```

### Conflict Type 2: Contradicting Information
**Example:** One source says X is safe, another says it's unsafe

**Resolution:**
```
1. Verify which is correct (research, test code, audits)
2. Keep correct information
3. Document the conflict and why one was wrong
4. Add context about when this changed

Example:
"Note: Older sources suggest tx.origin is safe in [context].
This is INCORRECT. tx.origin is never safe for authentication."
```

### Conflict Type 3: Different Severity/Priority
**Example:** Different sources rate a vulnerability differently

**Resolution:**
```
1. Use current severity (post-2024 standards)
2. Use Solidity 0.8.20+ context
3. Document historical context if relevant

Example:
"Integer overflow used to be high-risk (pre-0.8.0).
In Solidity 0.8+, automatic overflow checks make this low-risk
unless using 'unchecked' blocks."
```

---

## Automation & Scripts

### detect_duplicates.py
```python
# Detect duplicate content using:
# 1. SHA256 hashing for exact matches
# 2. Jaccard similarity for semantic matches
# Output: duplicate_groups.json
```

### merge_duplicates.py
```python
# Merge duplicate files:
# 1. Score each version
# 2. Select winner
# 3. Merge best parts if needed
# 4. Update Action KB
# 5. Log results
```

### dedup_report.py
```python
# Generate deduplication report:
# - Files analyzed
# - Duplicates found
# - Action taken
# - Coverage verification
```

---

## Quality Assurance

### Post-Dedup Verification

**Checklist:**
- [ ] All 10 vulnerabilities present in action KB
- [ ] No duplicate vulnerability files
- [ ] All patterns unique (no duplicates)
- [ ] Gas techniques ranked and unique
- [ ] Code snippets not duplicated
- [ ] All files have attribution
- [ ] All files pass quality checks
- [ ] Test coverage maintained
- [ ] Accessibility verified

### Metrics to Track

```
Deduplication Metrics:
- Duplicates found: X
- Files merged: Y
- Final file count: Z
- Content reduction: X%
- Attribution completeness: X%
- Quality score: X/100
```

---

## Maintenance Cycle

### Monthly (update-action-kb.sh)
```
1. Detect new duplicates in research KB
2. Update gas optimization rankings (if changed)
3. Merge quick-reference updates
4. Run dedup verification
5. Generate report
```

### Quarterly (quarterly-review.sh)
```
1. Full dedup analysis
2. Pattern completeness check
3. Vulnerability coverage audit
4. Template quality review
5. Generate recommendations
```

### Annually
```
1. Complete knowledge base audit
2. Source repository comparison
3. Strategic updates
4. Gap analysis
5. Future planning
```

---

## Documentation Standards

For deduplicated content, include:

```markdown
## [Topic]

[Content from winning source, optimized]

### Sources & Attribution

**Primary Source:** [Repository/File] ([Date])
- Strength: [Why this was chosen]
- Coverage: [What it covers]

**Contributed By:**
- [Source B]: [What aspect it contributed]
- [Source C]: [What aspect it contributed]

### Cross-References

- Full details in: `knowledge-base-research/repos/[path]`
- Alternative explanation: `knowledge-base-research/repos/[path]`
- Related pattern: `pattern-catalog.md#[pattern]`
```

---

## Success Criteria

The deduplication system is successful when:

✅ **Zero overlap** - No topic covered twice in Action KB
✅ **Best content** - Each topic uses best available explanation
✅ **Traceable** - Can find original sources
✅ **Automated** - Monthly sync runs automatically
✅ **Verified** - Quality checks pass
✅ **Documented** - All decisions logged
✅ **Maintained** - Regular updates happen
✅ **Complete** - All required files present

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-15 | Initial deduplication rules defined |

---

## Related Files

- `sync-config.json` - Detailed sync configuration
- `update-action-kb.sh` - Monthly update script
- `quarterly-review.sh` - Quarterly review script
- Logs: `.knowledge-base-sync/logs/deduplication.log`
