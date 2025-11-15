# Unsafe Delegatecall

## What It Is
`delegatecall` is a special function that executes code from a target contract while using the calling contract's storage, msg.sender, and msg.value. When used with untrusted addresses or improper storage layouts, it allows attackers to completely hijack contract storage, steal ownership, and drain funds.

## Why It Matters
Unsafe delegatecall caused the catastrophic Parity Wallet hack in November 2017, permanently freezing $280M+ in ETH. The vulnerability allowed an attacker to become the owner of the library contract and then self-destruct it, bricking hundreds of multi-sig wallets. Delegatecall gives complete storage control to external code, making it one of the most dangerous operations in Solidity.

## Vulnerable Code Example

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableProxy {
    address public owner;
    address public implementation;

    constructor() {
        owner = msg.sender;
    }

    // VULNERABILITY: Allows delegatecall to any address
    function forward(address target, bytes calldata data) public {
        (bool success,) = target.delegatecall(data);
        require(success, "Delegatecall failed");
    }

    function setImplementation(address _implementation) public {
        require(msg.sender == owner, "Not owner");
        implementation = _implementation;
    }
}

// Attack contract
contract MaliciousImplementation {
    address public owner; // Storage slot 0 - matches VulnerableProxy!

    function pwn() public {
        owner = msg.sender; // Overwrites proxy's owner!
    }
}
```

**Attack:** Attacker calls `forward(maliciousAddress, "pwn()")` and becomes owner.

## The Attack Scenario

**Parity Wallet Attack Flow:**

1. **Discovery**: Library contract had unprotected `initWallet()` function
2. **Initialization**: Attacker called `initWallet()` on library directly
3. **Ownership**: Became owner of library contract
4. **Destruction**: Called `kill()` function
5. **Self-Destruct**: Library destroyed itself
6. **Cascade**: All wallets using this library became unusable
7. **Result**: $280M frozen forever

**Numerical Example:**
```solidity
// Simplified Parity vulnerability
library WalletLibrary {
    address public owner;

    // VULNERABILITY: Not protected
    function initWallet(address _owner) public {
        owner = _owner;
    }

    // VULNERABILITY: Anyone can call if they're owner
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}

contract Wallet {
    address library;

    function() external payable {
        library.delegatecall(msg.data); // Forwards all calls to library
    }
}

// Attack:
// 1. Call WalletLibrary.initWallet(attacker) directly
// 2. Attacker becomes owner of library
// 3. Call WalletLibrary.kill()
// 4. Library destroyed
// 5. All Wallet contracts broken
```

## Prevention Methods

### Method 1: Whitelist Allowed Targets

Only allow delegatecall to trusted, pre-approved contracts.

```solidity
pragma solidity ^0.8.0;

contract WhitelistProxy {
    address public owner;
    mapping(address => bool) public allowedImplementations;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Only owner can add trusted implementations
    function addImplementation(address impl) public onlyOwner {
        allowedImplementations[impl] = true;
    }

    function removeImplementation(address impl) public onlyOwner {
        allowedImplementations[impl] = false;
    }

    // SAFE: Only whitelisted contracts
    function execute(address target, bytes calldata data) public onlyOwner {
        require(allowedImplementations[target], "Target not whitelisted");

        (bool success,) = target.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}
```

**Gas Cost**: ~2,800 gas for whitelist check
**Pros**: Simple, effective protection
**Cons**: Requires trust in whitelisted contracts

### Method 2: Proper Storage Layout (OpenZeppelin UUPS)

Use standardized proxy patterns with correct storage separation.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SecureImplementation is UUPSUpgradeable, OwnableUpgradeable {
    uint256 public value;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setValue(uint256 _value) public {
        value = _value;
    }

    // Only owner can upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// Proxy contract (deployed once, never changed)
contract ERC1967Proxy {
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address _implementation, bytes memory _data) {
        _setImplementation(_implementation);

        if (_data.length > 0) {
            (bool success,) = _implementation.delegatecall(_data);
            require(success);
        }
    }

    function _setImplementation(address newImplementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    fallback() external payable {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            let impl := sload(slot)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
```

**Gas Cost**: Standard proxy overhead (~2,600 gas per call)
**Pros**: Industry standard, battle-tested, upgradeable
**Cons**: Complex implementation, requires careful storage management

### Method 3: Immutable Implementation (Diamond Pattern)

Use diamond pattern for multi-facet upgrades with clear separation.

```solidity
pragma solidity ^0.8.0;

contract DiamondProxy {
    address public owner;

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    mapping(bytes4 => address) public selectorToFacet;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Add new functionality
    function addFacet(address facetAddress, bytes4[] memory selectors) public onlyOwner {
        for (uint256 i = 0; i < selectors.length; i++) {
            require(selectorToFacet[selectors[i]] == address(0), "Selector exists");
            selectorToFacet[selectors[i]] = facetAddress;
        }
    }

    // Remove functionality
    function removeFacet(bytes4[] memory selectors) public onlyOwner {
        for (uint256 i = 0; i < selectors.length; i++) {
            delete selectorToFacet[selectors[i]];
        }
    }

    fallback() external payable {
        address facet = selectorToFacet[msg.sig];
        require(facet != address(0), "Function not found");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
```

**Gas Cost**: ~5,000 gas overhead per call
**Pros**: Modular, can upgrade specific functions, unlimited contract size
**Cons**: Complex, higher gas costs, requires careful selector management

## Storage Collision Risks

### Dangerous Pattern

```solidity
// DANGEROUS - Storage collision
contract ProxyV1 {
    address public owner;    // slot 0
    uint256 public value;    // slot 1
}

contract ProxyV2 {
    uint256 public newValue; // slot 0 - COLLISION!
    address public owner;    // slot 1 - COLLISION!
    uint256 public value;    // slot 2
}
```

### Safe Pattern

```solidity
// SAFE - Use unstructured storage
contract SafeProxy {
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("implementation.slot");
    bytes32 private constant OWNER_SLOT = keccak256("owner.slot");

    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { impl := sload(slot) }
    }

    function _setImplementation(address newImpl) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { sstore(slot, newImpl) }
    }
}
```

## Real-World Examples

| Incident | Date | Amount | Vulnerability |
|----------|------|--------|---------------|
| **Parity Wallet Freeze** | Nov 2017 | $280M+ frozen | Unprotected library delegatecall |
| **Parity Wallet Hack** | Jul 2017 | $30M stolen | Delegatecall initialization |
| **Various Proxies** | Ongoing | Varies | Storage collisions |

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract DelegatecallTest is Test {
    VulnerableProxy public proxy;
    MaliciousImplementation public malicious;
    address public attacker = address(0x1337);

    function setUp() public {
        proxy = new VulnerableProxy();
        malicious = new MaliciousImplementation();
    }

    function testDelegatecallAttack() public {
        assertEq(proxy.owner(), address(this));

        // Attacker exploits delegatecall
        vm.prank(attacker);
        proxy.forward(
            address(malicious),
            abi.encodeWithSignature("pwn()")
        );

        // Owner changed!
        assertEq(proxy.owner(), attacker);
        console.log("Ownership stolen via delegatecall!");
    }

    function testWhitelistProtection() public {
        WhitelistProxy secureProxy = new WhitelistProxy();

        // Attempt attack without whitelist
        vm.prank(attacker);
        vm.expectRevert("Target not whitelisted");
        secureProxy.execute(
            address(malicious),
            abi.encodeWithSignature("pwn()")
        );

        console.log("Whitelist protection successful");
    }

    function testStorageCollision() public {
        // Demonstrate storage collision risk
        bytes memory initCode = abi.encodeWithSignature("setValue(uint256)", 12345);

        // Deploy proxy pointing to implementation
        // Storage layout must match!
    }
}
```

## Checklist

- [ ] Delegatecall only used with trusted contracts
- [ ] Whitelist enforced for all delegatecall targets
- [ ] Storage layout documented and verified
- [ ] ERC-1967 standard followed for proxies
- [ ] Initializers protected (no public init functions)
- [ ] Library contracts cannot be destroyed
- [ ] Storage slots use unstructured storage pattern
- [ ] Upgrade mechanism has access control
- [ ] Tests verify storage compatibility
- [ ] Diamond/UUPS pattern used if upgradeable
- [ ] Static analysis run (Slither)
- [ ] No user-controlled delegatecall addresses

## Additional Resources

**Documentation:**
- [OpenZeppelin Proxy Patterns](https://docs.openzeppelin.com/contracts/4.x/api/proxy)
- [ERC-1967: Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [EIP-2535: Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)

**Security:**
- [SWC-112: Delegatecall to Untrusted Callee](https://swcregistry.io/docs/SWC-112)
- [Parity Wallet Hack Analysis](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7)

**Tools:**
- [Slither Delegatecall Detector](https://github.com/crytic/slither)
- [OpenZeppelin Upgrades Plugin](https://docs.openzeppelin.com/upgrades-plugins)

---

**Last Updated**: November 2025
**Severity**: Critical
**OWASP Category**: [A4: Delegatecall](https://owasp.org/www-project-smart-contract-top-10/)
