// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title UpgradeableContract
 * @author Smart Contract Security Best Practices
 * @notice Production-ready upgradeable contract template using UUPS pattern
 * @dev Implements UUPS (Universal Upgradeable Proxy Standard) with:
 *      - Initializer pattern instead of constructor
 *      - Storage gap for future storage variables
 *      - Access control for upgrade authorization
 *      - Version tracking for upgrade history
 *      - Pausable for emergency stops
 *      - ReentrancyGuard for external call safety
 *
 * Security Considerations:
 * - Uses UUPS pattern (upgrade logic in implementation, not proxy)
 * - Only UPGRADER_ROLE can authorize upgrades
 * - Initializers protected from re-initialization
 * - Storage layout preserved with gaps
 * - Version tracking for auditability
 * - Locked pragma for deterministic builds
 *
 * IMPORTANT: When upgrading, ensure:
 * 1. Storage layout is preserved (don't reorder/remove variables)
 * 2. Add new storage variables at the end
 * 3. Reduce storage gap accordingly
 * 4. Test upgrade thoroughly on testnet first
 */
contract UpgradeableContract is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting unauthorized upgrade
    error UnauthorizedUpgrade();

    /// @notice Thrown when new implementation is zero address
    error InvalidImplementation();

    /// @notice Thrown when version string is empty
    error EmptyVersion();

    /*//////////////////////////////////////////////////////////////
                            ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role identifier for addresses that can upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Role identifier for addresses that can pause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Current version of the contract implementation
    /// @dev Increment this with each upgrade for tracking
    string public version;

    /// @notice Timestamp of the last upgrade
    uint256 public lastUpgradeTimestamp;

    /// @notice Counter for total number of upgrades
    uint256 public upgradeCount;

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Storage gap for future upgrades
     * @notice Reserved storage slots to allow for new variables in upgrades
     *
     * How to use:
     * - When adding new state variables, reduce this gap accordingly
     * - Each uint256 slot = 1 gap element
     * - Example: Adding 3 new uint256 variables? Reduce gap from 50 to 47
     *
     * Current gap: 47 slots
     * Used slots: 3 (version, lastUpgradeTimestamp, upgradeCount)
     * Total: 50 slots reserved for this contract's storage
     */
    uint256[47] private __gap;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when contract is upgraded to new implementation
    /// @param previousImplementation Address of old implementation
    /// @param newImplementation Address of new implementation
    /// @param version New version string
    /// @param upgrader Address that performed the upgrade
    event ContractUpgraded(
        address indexed previousImplementation,
        address indexed newImplementation,
        string version,
        address indexed upgrader
    );

    /// @notice Emitted when contract is initialized
    /// @param admin Address granted admin role
    /// @param version Initial version string
    event ContractInitialized(address indexed admin, string version);

    /// @notice Emitted when contract is paused
    /// @param pauser Address that paused the contract
    event ContractPaused(address indexed pauser);

    /// @notice Emitted when contract is unpaused
    /// @param pauser Address that unpaused the contract
    event ContractUnpaused(address indexed pauser);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor is disabled in upgradeable contracts
     * @dev Use initialize() instead
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the upgradeable contract
     * @param initialAdmin Address to receive admin and upgrader roles
     * @param initialVersion Version string for this implementation
     * @dev Replaces constructor for upgradeable contracts
     *      Can only be called once per proxy deployment
     *      Initializes all inherited contracts
     */
    function initialize(address initialAdmin, string memory initialVersion) public initializer {
        if (bytes(initialVersion).length == 0) revert EmptyVersion();

        // Initialize inherited contracts
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(UPGRADER_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);

        // Initialize version tracking
        version = initialVersion;
        lastUpgradeTimestamp = block.timestamp;
        upgradeCount = 0;

        emit ContractInitialized(initialAdmin, initialVersion);
    }

    /*//////////////////////////////////////////////////////////////
                        UPGRADE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation contract
     * @dev Only callable by UPGRADER_ROLE
     *      Required by UUPS pattern
     *      Validates new implementation address
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        if (newImplementation == address(0)) revert InvalidImplementation();
    }

    /**
     * @notice Upgrades to a new implementation and updates version
     * @param newImplementation Address of the new implementation
     * @param newVersion Version string for the new implementation
     * @dev Only callable by UPGRADER_ROLE
     *      Records upgrade timestamp and increments counter
     */
    function upgradeToAndCall(
        address newImplementation,
        string memory newVersion,
        bytes memory data
    ) public payable onlyRole(UPGRADER_ROLE) {
        if (bytes(newVersion).length == 0) revert EmptyVersion();

        address oldImplementation = _getImplementation();

        // Perform the upgrade
        upgradeToAndCall(newImplementation, data);

        // Update version tracking
        version = newVersion;
        lastUpgradeTimestamp = block.timestamp;
        upgradeCount++;

        emit ContractUpgraded(oldImplementation, newImplementation, newVersion, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses the contract
     * @dev Only callable by PAUSER_ROLE
     *      Use for emergency stops
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract
     * @dev Only callable by PAUSER_ROLE
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        EXAMPLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Example function that can be paused
     * @dev Replace with actual business logic
     *      whenNotPaused ensures function is disabled when paused
     */
    function exampleFunction() external whenNotPaused {
        // Your business logic here
    }

    /**
     * @notice Example function with reentrancy protection
     * @dev Replace with actual business logic
     *      nonReentrant prevents reentrancy attacks
     */
    function exampleWithReentrancyGuard() external nonReentrant {
        // External call logic here
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current implementation address
     * @return Address of current implementation contract
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Returns upgrade history information
     * @return Current version string
     * @return Timestamp of last upgrade
     * @return Total number of upgrades performed
     */
    function getUpgradeInfo()
        external
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        return (version, lastUpgradeTimestamp, upgradeCount);
    }
}
