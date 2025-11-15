# Smart Contract Vulnerabilities Repository

This directory contains a comprehensive collection of smart contract vulnerabilities scraped from the [kadenzipfel/smart-contract-vulnerabilities](https://github.com/kadenzipfel/smart-contract-vulnerabilities) repository.

## Repository Information

- **Source Repository**: kadenzipfel/smart-contract-vulnerabilities
- **GitHub URL**: https://github.com/kadenzipfel/smart-contract-vulnerabilities
- **Total Files Downloaded**: 38 vulnerability markdown files
- **Download Date**: November 15, 2025
- **Status**: All files successfully downloaded

## Vulnerability Categories

### Critical Vulnerabilities

1. **reentrancy.md** - Reentrancy attacks (single function, cross-function, read-only)
2. **overflow-underflow.md** - Integer overflow and underflow issues
3. **delegatecall-untrusted-callee.md** - Delegatecall to untrusted callee
4. **insufficient-access-control.md** - Insufficient access control mechanisms
5. **unchecked-return-values.md** - Unchecked return values from external calls

### Access Control & Authorization

6. **authorization-txorigin.md** - Using tx.origin for authorization
7. **default-visibility.md** - Default visibility issues
8. **insufficient-access-control.md** - Insufficient access control

### Denial of Service (DoS)

9. **dos-gas-limit.md** - DoS via gas limit manipulation
10. **dos-revert.md** - DoS via unexpected revert
11. **insufficient-gas-griefing.md** - Insufficient gas griefing attacks

### Data Manipulation & Storage

12. **arbitrary-storage-location.md** - Arbitrary storage location writes
13. **uninitialized-storage-pointer.md** - Uninitialized storage pointer vulnerabilities
14. **shadowing-state-variables.md** - State variable shadowing
15. **unencrypted-private-data-on-chain.md** - Unencrypted private data on-chain

### Randomness & Predictability

16. **weak-sources-randomness.md** - Weak sources of randomness
17. **timestamp-dependence.md** - Timestamp dependence vulnerabilities
18. **transaction-ordering-dependence.md** - Transaction ordering dependence (front-running)

### Signature & Cryptography

19. **signature-malleability.md** - Signature malleability issues
20. **unsecure-signatures.md** - Insecure signature implementations
21. **missing-protection-signature-replay.md** - Missing protection against signature replay
22. **unexpected-ecrecover-null-address.md** - Unexpected ecrecover null address return

### Code Quality & Best Practices

23. **assert-violation.md** - Assert violation issues
24. **requirement-violation.md** - Requirement violation
25. **floating-pragma.md** - Floating pragma issues
26. **outdated-compiler-version.md** - Outdated compiler version
27. **use-of-deprecated-functions.md** - Use of deprecated functions
28. **unused-variables.md** - Unused variables
29. **inadherence-to-standards.md** - Inadherence to standards

### Constructor & Inheritance

30. **incorrect-constructor.md** - Incorrect constructor implementation
31. **incorrect-inheritance-order.md** - Incorrect inheritance order

### Function Calls & Returns

32. **unsafe-low-level-call.md** - Unsafe low-level call usage
33. **unbounded-return-data.md** - Unbounded return data
34. **msgvalue-loop.md** - msg.value in loop

### Numerical & Precision Issues

35. **lack-of-precision.md** - Lack of precision in calculations
36. **off-by-one.md** - Off-by-one errors

### Smart Contract Verification

37. **asserting-contract-from-code-size.md** - Asserting contract from code size
38. **unsupported-opcodes.md** - Unsupported opcodes

### Hash & Collision

39. **hash-collision.md** - Hash collision vulnerabilities

## File Structure

All vulnerability files follow a consistent markdown format with:
- Vulnerability description
- Example vulnerable code
- Explanation of the issue
- Prevention methods
- References and sources

## Usage

These files can be used for:
- Security auditing reference
- Educational purposes
- Smart contract development best practices
- Vulnerability pattern recognition
- Security testing and validation

## Download Script

A download script (`download_script.sh`) is included in this directory for re-downloading or updating the vulnerability files from the source repository.

### To re-download all files:

```bash
cd /Volumes/Farhan/Work\ Folder/Dev/Safe-Smart-Contracts/knowledge-base-research/repos/vulnerabilities/
chmod +x download_script.sh
./download_script.sh
```

## Key Vulnerabilities Summary

### Most Critical (Based on Historical Impact)

1. **Reentrancy** - The most devastating vulnerability historically, responsible for major hacks
2. **Integer Overflow/Underflow** - Still possible in certain scenarios even with Solidity 0.8+
3. **Access Control** - Improper access restrictions leading to unauthorized actions
4. **Unchecked External Calls** - Not checking return values from external contracts
5. **Front-Running** - Transaction ordering manipulation attacks

### Prevention Best Practices

- Always use the Checks-Effects-Interactions pattern
- Implement reentrancy guards (OpenZeppelin's ReentrancyGuard)
- Use latest Solidity compiler versions
- Validate all external call return values
- Implement proper access control (Ownable, AccessControl)
- Avoid using tx.origin for authorization
- Be cautious with delegatecall to untrusted contracts
- Use SafeMath or Solidity 0.8+ for arithmetic operations
- Follow established standards (ERC20, ERC721, etc.)
- Comprehensive testing and security audits

## Repository Statistics

- Total Vulnerabilities: 38
- File Format: Markdown (.md)
- Total Size: ~80 KB
- Categories: 8 major categories

## Additional Resources

For more information and updates, visit the original repository:
- GitHub: https://github.com/kadenzipfel/smart-contract-vulnerabilities
- Vulnerabilities Directory: https://github.com/kadenzipfel/smart-contract-vulnerabilities/tree/master/vulnerabilities

## License

These files are sourced from the kadenzipfel/smart-contract-vulnerabilities repository. Please refer to the original repository for licensing information.

## Last Updated

November 15, 2025
