// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title SecureERC20Token
 * @author Smart Contract Security Best Practices
 * @notice Production-ready ERC20 token implementation with advanced security features
 * @dev Implements ERC20 standard with the following security features:
 *      - Role-based access control (RBAC) for administrative functions
 *      - Pausable functionality for emergency stops
 *      - Burnable tokens for supply reduction
 *      - EIP-2612 Permit for gasless approvals
 *      - Custom errors for gas efficiency
 *      - Comprehensive event logging
 *
 * Security Considerations:
 * - Uses OpenZeppelin's battle-tested contracts
 * - Follows checks-effects-interactions pattern
 * - Implements proper access controls on sensitive functions
 * - No transfer/send usage (gas stipend issues)
 * - Locked pragma for deterministic builds
 */
contract SecureERC20Token is ERC20, ERC20Burnable, ERC20Permit, Pausable, AccessControl {

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to mint to the zero address
    error CannotMintToZeroAddress();

    /// @notice Thrown when attempting to mint zero tokens
    error CannotMintZeroTokens();

    /// @notice Thrown when minting would exceed the maximum supply
    error ExceedsMaxSupply();

    /// @notice Thrown when trying to set max supply below current supply
    error MaxSupplyTooLow();

    /*//////////////////////////////////////////////////////////////
                            ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role identifier for addresses that can mint new tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role identifier for addresses that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum token supply that can ever exist
    /// @dev Set to max uint256 by default (effectively unlimited), can be changed by admin
    uint256 public maxSupply;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when tokens are minted to an address
    /// @param to Address receiving the minted tokens
    /// @param amount Amount of tokens minted
    /// @param minter Address that initiated the minting
    event TokensMinted(address indexed to, uint256 amount, address indexed minter);

    /// @notice Emitted when the maximum supply is updated
    /// @param oldMaxSupply Previous maximum supply value
    /// @param newMaxSupply New maximum supply value
    /// @param updatedBy Address that updated the max supply
    event MaxSupplyUpdated(uint256 oldMaxSupply, uint256 newMaxSupply, address indexed updatedBy);

    /// @notice Emitted when contract is paused
    /// @param account Address that paused the contract
    event ContractPaused(address indexed account);

    /// @notice Emitted when contract is unpaused
    /// @param account Address that unpaused the contract
    event ContractUnpaused(address indexed account);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the ERC20 token with name, symbol, and initial supply
     * @param name_ Token name (e.g., "My Token")
     * @param symbol_ Token symbol (e.g., "MTK")
     * @param initialSupply_ Initial token supply to mint to deployer (in wei units)
     * @dev Grants DEFAULT_ADMIN_ROLE, MINTER_ROLE, and PAUSER_ROLE to deployer
     *      Sets max supply to type(uint256).max by default
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        // Grant roles to contract deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // Set max supply to maximum possible value (effectively unlimited)
        maxSupply = type(uint256).max;

        // Mint initial supply to deployer if specified
        if (initialSupply_ > 0) {
            _mint(msg.sender, initialSupply_);
            emit TokensMinted(msg.sender, initialSupply_, msg.sender);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        MINTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints new tokens to a specified address
     * @param to Address to receive the newly minted tokens
     * @param amount Amount of tokens to mint (in wei units)
     * @dev Only callable by addresses with MINTER_ROLE
     *      Validates:
     *      - Recipient is not zero address
     *      - Amount is greater than zero
     *      - New total supply does not exceed max supply
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        // Input validation
        if (to == address(0)) revert CannotMintToZeroAddress();
        if (amount == 0) revert CannotMintZeroTokens();

        // Check max supply constraint
        if (totalSupply() + amount > maxSupply) revert ExceedsMaxSupply();

        // Effects: mint tokens
        _mint(to, amount);

        // Emit event for tracking
        emit TokensMinted(to, amount, msg.sender);
    }

    /**
     * @notice Updates the maximum token supply
     * @param newMaxSupply New maximum supply value
     * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
     *      New max supply must be >= current total supply
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newMaxSupply < totalSupply()) revert MaxSupplyTooLow();

        uint256 oldMaxSupply = maxSupply;
        maxSupply = newMaxSupply;

        emit MaxSupplyUpdated(oldMaxSupply, newMaxSupply, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses all token transfers
     * @dev Only callable by addresses with PAUSER_ROLE
     *      When paused, transfers/mints/burns are blocked
     *      Useful for emergency stops when bugs are discovered
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses all token transfers
     * @dev Only callable by addresses with PAUSER_ROLE
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Hook that is called before any token transfer
     * @dev Overrides required by Solidity due to multiple inheritance
     *      Enforces pause functionality - transfers blocked when paused
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the remaining number of tokens that can be minted
     * @return The difference between max supply and current total supply
     */
    function remainingMintableSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    /**
     * @notice Checks if the contract supports a given interface
     * @param interfaceId The interface identifier to check
     * @return True if the interface is supported
     * @dev Required override for AccessControl
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
