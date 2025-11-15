// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MultiSigWallet
 * @author Smart Contract Security Best Practices
 * @notice Production-ready multi-signature wallet implementation
 * @dev Implements a multi-signature wallet with:
 *      - Multiple signers with threshold requirement
 *      - Transaction proposal and execution
 *      - Off-chain signature collection (Gnosis Safe style)
 *      - Nonce tracking for replay protection
 *      - Signature verification using ECDSA
 *      - Support for arbitrary function calls
 *      - Event logging for all operations
 *
 * Security Considerations:
 * - Uses ECDSA for signature verification
 * - Nonce prevents replay attacks
 * - ReentrancyGuard prevents reentrancy
 * - Signature uniqueness enforced
 * - Proper threshold validation
 * - No duplicate signers allowed
 *
 * Pattern: Gnosis Safe-style multi-sig
 * - Signatures collected off-chain
 * - Single transaction executes with all signatures
 * - Gas efficient for signers (only executor pays gas)
 */
contract MultiSigWallet is ReentrancyGuard {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when threshold is invalid
    error InvalidThreshold();

    /// @notice Thrown when owner list is empty
    error NoOwnersProvided();

    /// @notice Thrown when owner is zero address
    error InvalidOwnerAddress();

    /// @notice Thrown when duplicate owner is detected
    error DuplicateOwner();

    /// @notice Thrown when insufficient signatures provided
    error InsufficientSignatures();

    /// @notice Thrown when signature is invalid
    error InvalidSignature();

    /// @notice Thrown when signer is not an owner
    error NotAnOwner();

    /// @notice Thrown when duplicate signature detected
    error DuplicateSignature();

    /// @notice Thrown when transaction execution fails
    error TransactionFailed();

    /// @notice Thrown when trying to add existing owner
    error OwnerAlreadyExists();

    /// @notice Thrown when trying to remove non-existent owner
    error OwnerDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Array of owner addresses
    address[] public owners;

    /// @notice Mapping to check if address is an owner (for O(1) lookup)
    mapping(address => bool) public isOwner;

    /// @notice Number of required signatures for execution
    uint256 public threshold;

    /// @notice Nonce for transaction replay protection
    /// @dev Incremented after each successful transaction
    uint256 public nonce;

    /*//////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transaction structure for execution
     * @param to Destination address
     * @param value ETH value to send
     * @param data Call data (function selector + parameters)
     * @param nonce Transaction nonce for replay protection
     */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 nonce;
    }

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when contract is deployed
    event MultiSigCreated(address[] owners, uint256 threshold);

    /// @notice Emitted when transaction is executed
    event TransactionExecuted(
        address indexed to,
        uint256 value,
        bytes data,
        uint256 nonce,
        address indexed executor
    );

    /// @notice Emitted when owner is added
    event OwnerAdded(address indexed owner);

    /// @notice Emitted when owner is removed
    event OwnerRemoved(address indexed owner);

    /// @notice Emitted when threshold is changed
    event ThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    /// @notice Emitted when ETH is deposited
    event Deposited(address indexed sender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the multi-signature wallet
     * @param owners_ Array of owner addresses
     * @param threshold_ Number of required signatures
     * @dev Validates owners and threshold
     *      Ensures no duplicate owners
     *      Threshold must be <= number of owners
     */
    constructor(address[] memory owners_, uint256 threshold_) {
        // Validation
        if (owners_.length == 0) revert NoOwnersProvided();
        if (threshold_ == 0 || threshold_ > owners_.length) revert InvalidThreshold();

        // Add owners and check for duplicates
        for (uint256 i = 0; i < owners_.length; ) {
            address owner = owners_[i];

            if (owner == address(0)) revert InvalidOwnerAddress();
            if (isOwner[owner]) revert DuplicateOwner();

            isOwner[owner] = true;
            owners.push(owner);

            unchecked {
                ++i;
            }
        }

        threshold = threshold_;

        emit MultiSigCreated(owners_, threshold_);
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSACTION EXECUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Executes a multi-sig transaction with provided signatures
     * @param to Destination address
     * @param value ETH value to send
     * @param data Call data
     * @param signatures Concatenated signatures (65 bytes each)
     * @dev Verifies signatures match threshold
     *      Checks signature uniqueness
     *      Executes transaction if valid
     *      Increments nonce after execution
     */
    function executeTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) external nonReentrant {
        // Check signature count
        if (signatures.length < threshold * 65) revert InsufficientSignatures();

        // Build transaction hash
        bytes32 txHash = getTransactionHash(to, value, data, nonce);

        // Verify signatures
        _verifySignatures(txHash, signatures);

        // Increment nonce before execution (prevent replay)
        nonce++;

        // Execute transaction
        (bool success, ) = to.call{value: value}(data);
        if (!success) revert TransactionFailed();

        emit TransactionExecuted(to, value, data, nonce - 1, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        SIGNATURE VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that signatures meet threshold and are from owners
     * @param txHash Hash of the transaction
     * @param signatures Concatenated signatures
     * @dev Checks:
     *      - Signatures are from unique owners
     *      - Signers are in ascending order (prevents duplicates)
     *      - At least threshold signatures provided
     */
    function _verifySignatures(bytes32 txHash, bytes memory signatures) internal view {
        uint256 signatureCount = signatures.length / 65;

        if (signatureCount < threshold) revert InsufficientSignatures();

        address lastSigner = address(0);

        for (uint256 i = 0; i < threshold; ) {
            // Extract signature components
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Signature format: [v (1 byte)][r (32 bytes)][s (32 bytes)]
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let signaturePos := mul(0x41, i) // 65 bytes per signature
                r := mload(add(signatures, add(signaturePos, 0x20)))
                s := mload(add(signatures, add(signaturePos, 0x40)))
                v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
            }

            // Recover signer address
            address signer = txHash.toEthSignedMessageHash().recover(v, r, s);

            // Validate signer
            if (!isOwner[signer]) revert NotAnOwner();

            // Ensure signatures are in ascending order (prevents duplicates)
            if (signer <= lastSigner) revert DuplicateSignature();

            lastSigner = signer;

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        OWNER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new owner (requires multi-sig)
     * @param newOwner Address of new owner
     * @dev Must be called via executeTransaction
     *      Cannot add existing owner or zero address
     */
    function addOwner(address newOwner) external {
        require(msg.sender == address(this), "Must be called via multi-sig");

        if (newOwner == address(0)) revert InvalidOwnerAddress();
        if (isOwner[newOwner]) revert OwnerAlreadyExists();

        isOwner[newOwner] = true;
        owners.push(newOwner);

        emit OwnerAdded(newOwner);
    }

    /**
     * @notice Removes an owner (requires multi-sig)
     * @param owner Address of owner to remove
     * @dev Must be called via executeTransaction
     *      Cannot remove if it would make threshold impossible
     */
    function removeOwner(address owner) external {
        require(msg.sender == address(this), "Must be called via multi-sig");

        if (!isOwner[owner]) revert OwnerDoesNotExist();
        if (owners.length - 1 < threshold) revert InvalidThreshold();

        isOwner[owner] = false;

        // Remove from array
        for (uint256 i = 0; i < owners.length; ) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        emit OwnerRemoved(owner);
    }

    /**
     * @notice Changes the signature threshold (requires multi-sig)
     * @param newThreshold New threshold value
     * @dev Must be called via executeTransaction
     *      Threshold must be valid (1 to number of owners)
     */
    function changeThreshold(uint256 newThreshold) external {
        require(msg.sender == address(this), "Must be called via multi-sig");

        if (newThreshold == 0 || newThreshold > owners.length) revert InvalidThreshold();

        uint256 oldThreshold = threshold;
        threshold = newThreshold;

        emit ThresholdChanged(oldThreshold, newThreshold);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates hash for transaction
     * @param to Destination address
     * @param value ETH value
     * @param data Call data
     * @param txNonce Transaction nonce
     * @return Hash of the transaction
     */
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txNonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), to, value, data, txNonce, block.chainid));
    }

    /**
     * @notice Allows contract to receive ETH
     */
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns all owners
     * @return Array of owner addresses
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Returns number of owners
     * @return Owner count
     */
    function getOwnerCount() external view returns (uint256) {
        return owners.length;
    }

    /**
     * @notice Returns current threshold
     * @return Required signature count
     */
    function getThreshold() external view returns (uint256) {
        return threshold;
    }

    /**
     * @notice Returns current nonce
     * @return Transaction nonce
     */
    function getNonce() external view returns (uint256) {
        return nonce;
    }
}
