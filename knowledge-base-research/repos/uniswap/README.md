# Uniswap Protocol Deep Dives

> Comprehensive research on Uniswap V2, V3, and V4 architectures extracted from source code

## Overview

This directory contains detailed architectural analyses of three major Uniswap protocol versions:

| Version | Focus | Use Case |
|---------|-------|----------|
| **V2** | Simple AMM with constant product formula | Basic swaps, LPs, foundational learning |
| **V3** | Concentrated liquidity with tick-based pools | Capital-efficient LPs, precise ranges |
| **V4** | Singleton PoolManager with customizable hooks | Extensible protocols, custom swap logic |

## Files Included

### 08-uniswap-v2-deep-dive.md (50 KB, 1500+ lines)

**What's Covered:**
- Complete V2 architecture with exact source code references
- Factory pattern with CREATE2 deterministic pool addresses
- Pair contract core mechanics (reserves, reentrancy guard, k invariant)
- Constant product formula: `x * y = k` with 0.3% fee
- Swap mechanism with flash swap pattern
- Liquidity provider economics and LP token mechanics
- TWAP oracle implementation using cumulative prices
- Flash swap callback system for atomic borrowing
- Safe transfer pattern for handling non-standard ERC20 tokens

**Code Snippets:**
- 100+ code snippets with exact `file:line` references
- Factory deployment logic
- Pair swap execution and fee collection
- LP token minting/burning
- TWAP accumulation tracking

**Best For:**
- Understanding fundamental AMM mechanics
- Learning the constant product formula
- Foundation for understanding V3/V4 evolution
- TWAP oracle concepts

---

### 09-uniswap-v3-deep-dive.md (65 KB, 2000+ lines)

**What's Covered:**
- Concentrated liquidity revolution: ticks, tick spacing, position management
- Tick system: conversion formula, tick spacing (1, 60, 200), bitmap optimization
- Tick math: O(1) sqrt(1.0001^tick) * 2^96 calculation using precomputed constants
- Tick bitmap: 256-tick word optimization for efficient iteration
- Position management: separate tickLower/tickUpper with unique per-user tracking
- Fee growth calculation: global tracking with "below" and "above" semantics
- Oracle system: enhanced TWAP with observation array and cardinality growth
- Multi-hop swap architecture: SwapRouter with callback-based routing
- NonfungiblePositionManager: ERC721 wrapper for on-chain position tracking
- Impermanent loss: only within [tickLower, tickUpper] concentrated range

**Code Snippets:**
- 200+ code snippets with exact source references
- TickMath bit operations for price conversion
- Tick bitmap word manipulation
- Position fee growth calculations
- Oracle observation cardinality management
- Multi-hop swap routing

**Best For:**
- Understanding concentrated liquidity paradigm shift
- Learning tick-based AMM mechanics
- TWAP oracle with block-level granularity
- Capital efficiency in liquidity provision
- Advanced DEX integrations

---

### 10-uniswap-v4-deep-dive.md (60 KB, 1800+ lines)

**What's Covered:**
- V4 architecture: Singleton PoolManager pattern replacing individual pair contracts
- Hook system with 14 permission flags encoded in hook contract address
- Concentrated liquidity: ticks and tick bitmap inherited from V3
- Core swap logic with liquidity changes at tick boundaries
- Fee growth calculation and position fee accrual
- ERC6909 multi-token standard for balance tracking (replacing LP tokens)
- Balance delta encoding: packing two int128 values into single int256
- Hook validation and execution with assembly
- Dynamic fee override via hooks
- Position tracking with salt-based uniqueness
- UnlockCallback pattern for atomic transaction structure

**Code Snippets:**
- 150+ code snippets with exact source references
- PoolManager singleton architecture
- Hook permission flag encoding
- Hook execution with assembly
- ERC6909 balance tracking
- Balance delta pack/unpack operations
- Position salt generation

**Best For:**
- Understanding next-generation AMM extensibility
- Hook system design and permission model
- Singleton contract pattern advantages/tradeoffs
- Advanced custom swap logic
- Protocol developer integrations

---

## Cross-References

### V2 vs V3 vs V4 Comparison Table

| Feature | V2 | V3 | V4 |
|---------|----|----|-----|
| **Pool Contracts** | Individual pairs | Individual pools | Singleton manager |
| **Liquidity** | Full range | Concentrated ticks | Concentrated ticks |
| **Swap Pattern** | Direct to pair | Router callback | Manager callback |
| **Position Type** | ERC20 LP tokens | ERC721 NFT positions | ERC6909 tokens |
| **Customization** | None | Oracle only | Hooks (14 types) |
| **Fee Structure** | Fixed 0.3% | Tiered (0.01-1%) | Dynamic via hooks |
| **Oracle** | TWAP (cumulative) | TWAP + observations | TWAP + observations |
| **Capital Efficiency** | 1x (baseline) | 4000x (max) | 4000x+ (custom) |

---

## Research Methodology

All content extracted directly from source code repositories:
- https://github.com/Uniswap/v2-core
- https://github.com/Uniswap/v2-periphery
- https://github.com/Uniswap/v3-core
- https://github.com/Uniswap/v3-periphery
- https://github.com/Uniswap/v4-core

**Quality Assurance:**
- Every code snippet verified against actual source
- File:line references for exact code location
- No synthesized content, pure extraction
- Covers production-grade implementations

---

## Learning Path

### For Beginners
1. Start with `08-uniswap-v2-deep-dive.md` (Factory + constant product formula)
2. Understand basic LP token mechanics
3. Learn TWAP oracle from V2 implementation

### For Advanced Learners
1. Read `08-uniswap-v2-deep-dive.md` for foundation
2. Move to `09-uniswap-v3-deep-dive.md` for concentrated liquidity concepts
3. Study tick math and fee growth calculation
4. Finish with `10-uniswap-v4-deep-dive.md` for modern architecture

### For Protocol Developers
1. Focus on `10-uniswap-v4-deep-dive.md` (current production)
2. Reference V3 for concentrated liquidity details
3. Reference V2 for foundational AMM math

---

## Integration Guides

For quick step-by-step integration instructions, see:
- `knowledge-base-action/06-defi-trading/02-slippage-protection.md`
- `knowledge-base-action/06-defi-trading/08-chainlink-datafeed-integration.md` (using oracle with Uniswap)

---

**Last Updated**: November 16, 2025
**Source Quality**: Production-grade, battle-tested implementations
**Content Type**: Research & Architecture Deep Dives (30+ min read each)
