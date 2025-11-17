# ChainRunners Contract Template

**Type:** On-Chain Art

**Published:** 24 November 2021

## Description

ChainRunners created a 32x32 pixel art all stored on chain. See how on chain pixel generation works.

## Features

- Pixel Art Generation
- On-Chain Storage
- ERC721

## Source Repository

Repository: [marcelc63/popular-contract-templates](https://github.com/marcelc63/popular-contract-templates)  
Branch: `chainrunners-template`

## Contract Code

### ChainRunnersTypes.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ChainRunnersTypes {
  struct ChainRunner {
    uint256 dna;
  }
}

```

## Related Vulnerabilities

This template includes protections against:
- Overflow/Underflow (Solidity 0.8+)
- Safe Transfer implementations

## Integration Guidelines

This template is designed for:
- Production deployment
- Community/DAO projects
- NFT launches
- Token creation

---

**Source:** marcelc63/popular-contract-templates  
**License:** Based on repository license  
