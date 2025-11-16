# DEX/AMM Trading Protocols & Security Guide

**Status:** Complete | **Version:** 1.0 | **Last Updated:** November 2025

## Overview

This section covers decentralized exchanges (DEXs), automated market makers (AMMs), and all security aspects of trading protocols including:

- Uniswap V2, V3, V4 architecture
- Liquidity pool management
- Slippage protection mechanisms
- Sniper bot detection and prevention
- Flash swap attack prevention
- MEV (Maximal Extractable Value) mitigation
- Price oracle integration
- Trading bot security

## Contents

### 📚 Guides

| Guide | Topic | Level | Time |
|-------|-------|-------|------|
| **00-DEX-OVERVIEW.md** | AMM fundamentals, Uniswap architecture, constant product formula | Intermediate | 30 min |
| **01-liquidity-pools.md** | LP contract patterns, fee collection, impermanent loss | Intermediate-Advanced | 45 min |
| **02-slippage-protection.md** | Slippage mechanisms, protection patterns, dynamic slippage | Intermediate | 40 min |
| **03-sniper-bot-prevention.md** | Bot detection, private mempools, rate limiting, intent-based | Advanced | 50 min |
| **04-flash-swaps.md** | Flash loan attacks, TWAP oracles, safe patterns | Advanced | 45 min |
| **05-mev-mitigation.md** | MEV strategies, batch auctions, MEV-burn, encryption | Advanced | 50 min |
| **06-price-oracles.md** | Chainlink integration, TWAP, oracle attacks, aggregation | Intermediate-Advanced | 45 min |
| **07-trading-bot-security.md** | Bot architecture, key management, circuit breakers, monitoring | Advanced | 50 min |

**Total Content:** ~350 KB | ~50,000 words | 8+ hours of reading

## Quick Start

### For Building a Standard DEX/Token:
1. Read: `00-DEX-OVERVIEW.md` (understand AMM)
2. Read: `02-slippage-protection.md` (protect users)
3. Read: `06-price-oracles.md` (integrate Chainlink)
4. Reference: Code examples in each guide

### For Integrating Trading:
1. Read: `01-liquidity-pools.md` (understand pools)
2. Read: `03-sniper-bot-prevention.md` (MEV protection)
3. Read: `05-mev-mitigation.md` (comprehensive MEV)
4. Implement: Private mempool or intent-based

### For Building a Trading Bot:
1. Read: `00-DEX-OVERVIEW.md` (fundamentals)
2. Read: `07-trading-bot-security.md` (security)
3. Read: `06-price-oracles.md` (oracle integration)
4. Read: `03-sniper-bot-prevention.md` (bot detection)
5. Implement: All security patterns

### For Auditing a DEX Protocol:
1. Read: `02-slippage-protection.md` (slippage issues)
2. Read: `04-flash-swaps.md` (flash loan vulnerabilities)
3. Read: `05-mev-mitigation.md` (MEV risks)
4. Read: `03-sniper-bot-prevention.md` (bot attacks)
5. Create: Comprehensive audit checklist

## Key Concepts

### Automated Market Maker (AMM)
An algorithm that determines token prices based on pool reserves. Formula: **x × y = k**

### Slippage
Price difference between expected execution price and actual price due to trade size and MEV.

### MEV (Maximal Extractable Value)
Value extracted by miners/validators through transaction reordering. Annual: ~$500M+

### Impermanent Loss (IL)
Loss incurred by liquidity providers when prices diverge from their entry point.

### TWAP (Time-Weighted Average Price)
Average price over time window; immune to single-block flash attacks.

### Flash Swap / Flash Loan
Uncollateralized borrow that must be repaid in same transaction.

### Sniper Bot
Automated system that frontrunning/backruns transactions for MEV extraction.

## Critical Vulnerabilities Covered

| Vulnerability | Impact | Guide | Protection |
|----------------|--------|-------|-----------|
| **Sandwich Attack** | 0.5-10% loss per trade | 02, 03, 05 | Private mempool, batch auctions |
| **Flash Loan Attack** | $M+ protocol drain | 04, 06 | TWAP oracle, rate limiting |
| **Slippage Exploitation** | 5-50% loss | 02, 03 | AmountMin, deadline, monitoring |
| **Oracle Manipulation** | Unfair liquidations | 06 | Multiple feeds, TWAP, freshness checks |
| **MEV Extraction** | 1-10% per trade | 03, 05 | Private mempool, intents, MEV-burn |
| **Sniper Bot Detection** | Front-run losses | 03, 07 | Rate limiting, behavioral analysis |
| **Liquidation Race** | Lost opportunities | 05 | Auction mechanism, sequential IDs |

## Security Checklist

Before deploying any DEX/trading protocol:

### Core Security
- [ ] All swaps have `amountMin` or equivalent?
- [ ] All transactions have `deadline` set?
- [ ] Using TWAP oracle (not spot price)?
- [ ] Flash loan attacks mitigated?
- [ ] Reentrancy guards in place?

### MEV/Sandwich Protection
- [ ] Private mempool enabled (Flashbots)?
- [ ] Batch auction or intent-based?
- [ ] Rate limiting implemented?
- [ ] Commit-reveal for sensitive ops?

### Price Oracle Safety
- [ ] Chainlink Data Feeds integrated?
- [ ] Freshness check: <1 hour old?
- [ ] Multiple feeds (3+ for critical)?
- [ ] Price range validation?
- [ ] Fallback oracle if primary fails?

### Bot/Trading Safety
- [ ] Private key in hardware wallet?
- [ ] Daily loss circuit breaker?
- [ ] Trade size limits?
- [ ] Slippage limits per trade?
- [ ] Emergency pause mechanism?

### Testing & Monitoring
- [ ] Tests cover sandwich attacks?
- [ ] Tests cover flash loans?
- [ ] Tests cover oracle manipulation?
- [ ] Monitoring for unusual MEV?
- [ ] Regular security audits?

## Real Attacks Covered

| Attack | Year | Loss | Reference | Guide |
|--------|------|------|-----------|-------|
| **Harvest Finance Flash Loan** | 2020 | $34M | Oracle manipulation | 04, 06 |
| **The DAO Reentrancy** | 2016 | $60M | Reentrancy pattern | 03-attack-prevention |
| **Parity MultiSig Delegatecall** | 2017 | $280M | Unsafe delegatecall | 03-attack-prevention |
| **BeautyChain Integer Overflow** | 2018 | $900M | Integer bugs | 03-attack-prevention |
| **Uniswap V3 Sandwich Attack** | Ongoing | $200M/year | MEV extraction | 03, 05 |
| **Liquidation Competition** | Ongoing | $150M/year | Gas price wars | 05 |

## Integration Examples

### Swap with Protection
```solidity
// From 02-slippage-protection.md
uint expectedOut = router.getAmountsOut(amountIn, path)[path.length - 1];
uint minOut = (expectedOut * 99) / 100;  // 1% slippage

router.swapExactTokensForTokens(
    amountIn,
    minOut,  // Protected
    path,
    msg.sender,
    block.timestamp + 600  // 10 min deadline
);
```

### Oracle Integration (Chainlink)
```solidity
// From 06-price-oracles.md
AggregatorV3Interface priceFeed = AggregatorV3Interface(FEED_ADDRESS);
(uint80 roundID, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();

require(block.timestamp - timeStamp <= 1 hours, "Stale price");
require(price > 0, "Invalid price");

return uint256(price);
```

### Flash Loan Protection
```solidity
// From 04-flash-swaps.md
uint balanceBefore = token.balanceOf(address(this));

// ... execute callback ...

uint balanceAfter = token.balanceOf(address(this));
uint fee = (amount * 9) / 10000;  // 0.09% Aave fee

require(balanceAfter >= balanceBefore + fee, "Loan not repaid");
```

### MEV Protection (Private Mempool)
```solidity
// From 05-mev-mitigation.md
// Send to Flashbots Protect instead of public mempool
// Uses: eth_sendPrivateTransaction
// Result: Hidden from bots, sandwich-proof

// See Flashbots docs for implementation
```

## Tools & Services

| Tool | Purpose | Cost | Guide |
|------|---------|------|-------|
| **Chainlink Data Feeds** | Price oracles | Free-$$ | 06 |
| **Flashbots Protect** | Private mempool | Free | 05, 03 |
| **Uniswap** | DEX reference | N/A | 00, 01 |
| **CoW Protocol** | Batch auctions | ~0.05% | 05 |
| **MEV-Inspect** | MEV analysis | Free | 05 |
| **Etherscan** | Contract verification | Free | N/A |

## Common Mistakes to Avoid

❌ **Using spot price from DEX** → Use TWAP oracle instead
❌ **No slippage protection** → Set `amountMin` on all swaps
❌ **Single oracle feed** → Use 3+ feeds with fallback
❌ **Hardcoded private keys** → Use hardware wallet or KMS
❌ **No deadline** → Always set `deadline: block.timestamp + timeout`
❌ **Flash loan immunity assumed** → Validate TWAP not spot price
❌ **Liquidation as open competition** → Use auction mechanism
❌ **No rate limiting on bots** → Implement daily loss limits
❌ **Ignoring MEV** → Use private mempool or intent-based
❌ **Testing only happy path** → Test sandwich attacks, flash loans

## Additional Resources

### Uniswap
- **V3 Whitepaper**: https://uniswap.org/whitepaper-v3.pdf
- **V3 Core**: https://github.com/Uniswap/v3-core
- **V3 Periphery**: https://github.com/Uniswap/v3-periphery
- **Official Docs**: https://docs.uniswap.org/

### Chainlink
- **Data Feeds**: https://docs.chain.link/data-feeds
- **Automation**: https://docs.chain.link/chainlink-automation

### MEV Research
- **Flashbots**: https://www.flashbots.net/
- **MEV-Explore**: https://explore.flashbots.net/
- **CoW Protocol**: https://cow.fi/

### Security
- **OpenZeppelin Contracts**: https://github.com/OpenZeppelin/openzeppelin-contracts
- **SWC Registry**: https://swcregistry.io/
- **Best Practices**: https://github.com/ConsenSysDiligence/smart-contract-best-practices

## Support & Issues

Found an issue or have questions?
- Open issue on GitHub
- Review checklist in relevant guide
- Run tests from examples
- Verify on testnet first

## Version History

**v1.0** (November 2025)
- Initial release with 8 comprehensive guides
- 50,000+ words covering all DEX/trading security
- Real attack analysis
- Production-ready code patterns
- Uniswap V2/V3/V4 coverage
- Chainlink integration

---

**Status:** ✅ Complete and Production Ready

For questions, start with the relevant guide's "Quick Reference" section at the end.
