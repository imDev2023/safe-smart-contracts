# ERC1967Proxy

## Overview

ERC1967Proxy is the foundation for upgradeable contracts in OpenZeppelin. It implements the ERC-1967 standard for proxy storage slots, ensuring implementation addresses don't collide with contract storage.

**Contract Path**: `@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol`
**Standard**: [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967)

## Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Proxy} from "../Proxy.sol";
import {ERC1967Utils} from "./ERC1967Utils.sol";

contract ERC1967Proxy is Proxy {
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
```

## Key Concepts

### Storage Slots (ERC-1967)
```solidity
// Implementation slot
// keccak256("eip1967.proxy.implementation") - 1
bytes32 internal constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

// Admin slot
// keccak256("eip1967.proxy.admin") - 1
bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
```

These specific slots are chosen to avoid collisions with normal contract storage.

## How It Works

### 1. Delegatecall Pattern
```solidity
// All calls are forwarded to implementation
fallback() external payable {
    _delegate(_implementation());
}

function _delegate(address implementation) internal {
    assembly {
        // Copy msg.data
        calldatacopy(0, 0, calldatasize())

        // Delegatecall to implementation
        let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy return data
        returndatacopy(0, 0, returndatasize())

        // Return or revert
        switch result
        case 0 { revert(0, returndatasize()) }
        default { return(0, returndatasize()) }
    }
}
```

### 2. Implementation Storage
```solidity
function _setImplementation(address newImplementation) private {
    require(newImplementation.code.length > 0, "Not a contract");

    // Store in ERC-1967 slot
    assembly {
        sstore(IMPLEMENTATION_SLOT, newImplementation)
    }
}
```

## Usage Example

```solidity
// 1. Deploy implementation
contract MyContractV1 {
    uint256 public value;

    function initialize(uint256 _value) public {
        value = _value;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }
}

// 2. Deploy proxy
const implementation = await MyContractV1.deploy();
const initData = implementation.interface.encodeFunctionData("initialize", [42]);

const proxy = await ERC1967Proxy.deploy(
    implementation.address,
    initData
);

// 3. Interact through proxy
const proxied = MyContractV1.attach(proxy.address);
await proxied.setValue(100);
console.log(await proxied.value()); // 100
```

## Best Practices

1. **Always use initializer, not constructor**
2. **Store implementation address in ERC-1967 slot**
3. **Use for basic proxy patterns**
4. **Consider TransparentProxy or UUPS for production**

## Summary

- Foundation for OpenZeppelin upgradeable contracts
- Uses standardized storage slots (ERC-1967)
- Simple delegatecall-based proxy
- Building block for more complex patterns
