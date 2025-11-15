# Unchecked Return Values

## What It Is
Many Solidity functions return boolean values to indicate success or failure, but the transaction doesn't automatically revert if the call fails. Ignoring these return values can lead to silent failures where code continues executing despite failed external calls, token transfers, or low-level operations, causing incorrect state changes and fund losses.

## Why It Matters
The King of Ether throne was hacked due to unchecked `.send()` return values, allowing attackers to claim wins without actually receiving payouts. Many early token contracts failed silently when transfers were unsuccessful. This vulnerability is particularly dangerous because it creates a false assumption of success, leading developers to update state variables or emit events for operations that never completed.

## Vulnerable Code Example

### Example 1: Unchecked send()

```solidity
// INSECURE - DO NOT USE
pragma solidity ^0.8.0;

contract VulnerableLottery {
    address public winner;
    uint256 public prize;
    bool public paidOut = false;

    function sendPrize() public {
        require(!paidOut, "Already paid");

        // VULNERABILITY: send() returns false on failure but doesn't revert
        winner.send(prize);

        // State updated even if send failed!
        paidOut = true;
    }

    function withdrawLeftover() public {
        require(paidOut, "Prize not paid yet");
        // Anyone can withdraw if send() failed but paidOut was set to true
        msg.sender.call{value: address(this).balance}("");
    }
}

// Attack: Winner with reverting fallback can cause send() to fail
contract AttackWinner {
    fallback() external payable {
        revert("I reject payments");
    }
}
```

### Example 2: Unchecked call()

```solidity
// INSECURE
pragma solidity ^0.8.0;

contract UncheckedTransfer {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        // VULNERABILITY: Doesn't check return value
        msg.sender.call{value: amount}("");

        // Balance reduced even if transfer failed!
    }
}
```

### Example 3: Unchecked ERC20 transfer()

```solidity
// INSECURE
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract UncheckedERC20 {
    IERC20 public token;

    function distributeTokens(address[] memory recipients, uint256 amount) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            // VULNERABILITY: Ignores return value
            // Some tokens (e.g., USDT) don't return bool
            token.transfer(recipients[i], amount);

            // Assumes success and continues!
        }
    }
}
```

## The Attack Scenario

**King of Ether Attack:**

1. **Initial State**: Throne contract holds 10 ETH prize
2. **Attacker Setup**: Deploys contract with reverting fallback
3. **Claim Throne**: Attacker becomes king via malicious contract
4. **Challenge**: Legitimate user tries to claim throne
5. **Failed Payment**: Contract tries to `send()` prize to attacker
6. **Silent Failure**: `send()` returns false, but not checked
7. **State Update**: `paidOut = true` set anyway
8. **Exploit**: Attacker remains king, legitimate user lost funds

**Numerical Example:**
```
Initial State:
- Contract balance: 10 ETH
- Winner: AttackContract
- Prize: 10 ETH
- paidOut: false

Attack Execution:
1. sendPrize() called
2. winner.send(10 ETH) → returns false (fallback reverts)
3. Code continues: paidOut = true
4. withdrawLeftover() now accessible
5. Attacker calls withdrawLeftover()
6. Receives 10 ETH prize

Result:
- Attacker gets prize despite send() failing
- Contract logic corrupted
- paidOut flag incorrect
```

## Prevention Methods

### Method 1: Always Check Return Values with require()

Explicitly verify success of all external calls.

```solidity
pragma solidity ^0.8.0;

contract SecureLottery {
    address public winner;
    uint256 public prize;
    bool public paidOut = false;

    function sendPrize() public {
        require(!paidOut, "Already paid");

        // CHECK return value
        (bool success,) = winner.call{value: prize}("");
        require(success, "Transfer failed");

        // Only executes if transfer succeeded
        paidOut = true;
    }
}
```

**Gas Cost**: Negligible (~100 gas for require)
**Pros**: Explicit, clear, prevents silent failures
**Cons**: Can create DoS if recipient always reverts (see DoS attacks guide)

### Method 2: Use transfer() instead of send()

`transfer()` automatically reverts on failure (but has gas limitations).

```solidity
pragma solidity ^0.8.0;

contract TransferExample {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        // Automatically reverts on failure
        payable(msg.sender).transfer(amount);
    }
}
```

**Gas Cost**: Same as send() (~2,300 gas)
**Pros**: Automatic revert, simple
**Cons**: Fixed 2,300 gas stipend (may fail with complex fallbacks), can cause DoS

### Method 3: SafeERC20 (OpenZeppelin)

Handle non-standard ERC20 tokens that don't return bool.

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SafeTokenHandler {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function distributeTokens(address[] memory recipients, uint256 amount) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            // SAFE: Reverts on failure, handles non-standard tokens
            token.safeTransfer(recipients[i], amount);
        }
    }

    function safeTransferFrom(address from, address to, uint256 amount) public {
        // SAFE: Works with USDT and other non-standard tokens
        token.safeTransferFrom(from, to, amount);
    }

    function safeApprove(address spender, uint256 amount) public {
        // SAFE: Handles approval correctly
        token.safeApprove(spender, amount);
    }
}
```

**Gas Cost**: ~200-500 gas overhead
**Pros**: Handles all ERC20 variants, battle-tested, prevents silent failures
**Cons**: Slight gas overhead

**How SafeERC20 works:**
```solidity
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
        // If no return data, assumes success (USDT case)
    }
}
```

### Method 4: Try-Catch for External Calls

Handle failures gracefully with Solidity 0.6+ try-catch.

```solidity
pragma solidity ^0.8.0;

interface IExternalContract {
    function riskyOperation() external returns (bool);
}

contract TryCatchExample {
    IExternalContract public external;
    uint256 public successCount;
    uint256 public failureCount;

    function callExternal() public {
        try external.riskyOperation() returns (bool result) {
            // Success path
            if (result) {
                successCount++;
            } else {
                failureCount++;
            }
        } catch Error(string memory reason) {
            // Catch revert with reason
            emit CallFailed(reason);
            failureCount++;
        } catch (bytes memory lowLevelData) {
            // Catch low-level failures
            emit CallFailedLowLevel(lowLevelData);
            failureCount++;
        }
    }

    event CallFailed(string reason);
    event CallFailedLowLevel(bytes data);
}
```

**Gas Cost**: ~500 gas overhead for try-catch
**Pros**: Graceful failure handling, explicit error paths
**Cons**: More complex, only for Solidity 0.6+

## Common Vulnerable Functions

### Functions that return bool:

```solidity
// All of these return bool that MUST be checked:
address.send(amount)              // Returns false on failure
address.call(data)                // Returns (bool, bytes)
address.delegatecall(data)        // Returns (bool, bytes)
address.staticcall(data)          // Returns (bool, bytes)
IERC20.transfer(to, amount)       // Returns bool
IERC20.transferFrom(from, to, amount)  // Returns bool
IERC20.approve(spender, amount)   // Returns bool
```

### Safe alternatives:

```solidity
address.transfer(amount)          // Reverts on failure (but limited gas)
SafeERC20.safeTransfer(...)       // Reverts on failure
SafeERC20.safeTransferFrom(...)   // Reverts on failure
SafeERC20.safeApprove(...)        // Reverts on failure
```

## Real-World Examples

| Incident | Date | Impact | Issue |
|----------|------|--------|-------|
| **King of Ether** | 2016 | Contract bricked | Unchecked send() |
| **Various Tokens** | 2017-2018 | Fund losses | Unchecked transfer() |
| **USDT Integration** | Ongoing | Failed transactions | Non-standard ERC20 |

**King of Ether Details:**
- Game where users compete to become "king"
- Winner receives payout via `.send()`
- Return value not checked
- Malicious contract rejects payments
- `paidOut` flag set to true anyway
- Contract becomes unusable

## Testing This

### Foundry Test Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract UncheckedReturnsTest is Test {
    VulnerableLottery public vulnerable;
    SecureLottery public secure;
    AttackWinner public attacker;

    function setUp() public {
        vulnerable = new VulnerableLottery();
        secure = new SecureLottery();
        attacker = new AttackWinner();

        vm.deal(address(vulnerable), 10 ether);
        vm.deal(address(secure), 10 ether);

        vulnerable.winner = address(attacker);
        vulnerable.prize = 10 ether;

        secure.winner = address(attacker);
        secure.prize = 10 ether;
    }

    function testUncheckedSendVulnerability() public {
        assertFalse(vulnerable.paidOut());

        // send() fails but paidOut still set to true
        vulnerable.sendPrize();

        assertTrue(vulnerable.paidOut());
        assertEq(address(vulnerable).balance, 10 ether); // Funds still there!

        console.log("Vulnerability: paidOut=true but funds not sent");
    }

    function testCheckedCallProtection() public {
        assertFalse(secure.paidOut());

        // Should revert because transfer fails
        vm.expectRevert("Transfer failed");
        secure.sendPrize();

        assertFalse(secure.paidOut());
        assertEq(address(secure).balance, 10 ether);

        console.log("Protection: Transaction reverted on failed transfer");
    }

    function testSafeERC20() public {
        SafeTokenHandler handler = new SafeTokenHandler(address(0));

        // Test with mock token that doesn't return bool
        // SafeERC20 should handle it correctly
    }
}
```

### Hardhat Test Example

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Unchecked Returns Tests", function () {
  it("Should demonstrate unchecked send vulnerability", async function () {
    const VulnerableLottery = await ethers.getContractFactory("VulnerableLottery");
    const lottery = await VulnerableLottery.deploy();

    const AttackWinner = await ethers.getContractFactory("AttackWinner");
    const attacker = await AttackWinner.deploy();

    // Fund contract
    await ethers.provider.send("hardhat_setBalance", [
      await lottery.getAddress(),
      "0x8AC7230489E80000" // 10 ETH
    ]);

    // Set attacker as winner
    await lottery.setWinner(await attacker.getAddress());
    await lottery.setPrize(ethers.parseEther("10"));

    // Send prize - will fail silently
    await lottery.sendPrize();

    // paidOut is true but funds remain
    expect(await lottery.paidOut()).to.be.true;
    expect(await ethers.provider.getBalance(await lottery.getAddress()))
      .to.equal(ethers.parseEther("10"));

    console.log("Vulnerability demonstrated: silent failure");
  });

  it("Should test checked call protection", async function () {
    const SecureLottery = await ethers.getContractFactory("SecureLottery");
    const lottery = await SecureLottery.deploy();

    const AttackWinner = await ethers.getContractFactory("AttackWinner");
    const attacker = await AttackWinner.deploy();

    await ethers.provider.send("hardhat_setBalance", [
      await lottery.getAddress(),
      "0x8AC7230489E80000"
    ]);

    await lottery.setWinner(await attacker.getAddress());
    await lottery.setPrize(ethers.parseEther("10"));

    // Should revert
    await expect(lottery.sendPrize()).to.be.revertedWith("Transfer failed");

    // State not changed
    expect(await lottery.paidOut()).to.be.false;
  });
});
```

## Checklist

- [ ] All `send()` calls have return values checked
- [ ] All `call()` calls have return values checked
- [ ] All ERC20 operations use SafeERC20
- [ ] `transfer()` used instead of `send()` where appropriate
- [ ] Low-level calls wrapped in require statements
- [ ] Try-catch used for complex external calls
- [ ] Non-standard tokens (USDT, USDC) handled correctly
- [ ] Tests verify failure scenarios
- [ ] Return values explicitly captured and checked
- [ ] No assumptions about external call success
- [ ] Static analysis run (Slither detects this)
- [ ] Audit focuses on all external interactions

## Additional Resources

**Documentation:**
- [OpenZeppelin SafeERC20](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#SafeERC20)
- [Solidity Try-Catch](https://docs.soliditylang.org/en/latest/control-structures.html#try-catch)
- [Solidity Address Members](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#members-of-addresses)

**Security:**
- [SWC-104: Unchecked Call Return Value](https://swcregistry.io/docs/SWC-104)
- [King of Ether Postmortem](https://www.kingoftheether.com/postmortem.html)
- [ConsenSys Best Practices](https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#handle-errors-in-external-calls)

**Tools:**
- [Slither Unchecked Calls Detector](https://github.com/crytic/slither)

---

**Last Updated**: November 2025
**Severity**: High
**OWASP Category**: [A7: Unchecked External Calls](https://owasp.org/www-project-smart-contract-top-10/)
