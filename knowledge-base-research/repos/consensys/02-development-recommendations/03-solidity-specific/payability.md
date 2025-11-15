# Payability

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

Starting from Solidity `0.4.0`, every function that is receiving ether must use `payable` modifier, otherwise if the transaction has `msg.value > 0` will revert ([except when forced](https://consensysdiligence.github.io/smart-contract-best-practices/attacks/force-feeding/)).

> **Note**: Something that might not be obvious: The `payable` modifier only applies to calls from _external_ contracts. If I call a non-payable function in the payable function in the same contract, the non-payable function won't fail, though `msg.value` is still set.
