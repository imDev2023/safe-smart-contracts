// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title PausableContract
 * @author Smart Contract Security Best Practices
 * @notice Production-ready contract with emergency stop (circuit breaker) pattern
 * @dev Implements pausable functionality with:
 *      - Pause/unpause controls for emergency stops
 *      - Role-based access for pause permissions
 *      - Emergency withdrawal function
 *      - whenNotPaused/whenPaused modifiers
 *      - Event logging for transparency
 *      - ReentrancyGuard for safe withdrawals
 *
 * Security Considerations:
 * - Circuit breaker pattern for emergency situations
 * - Only PAUSER_ROLE can pause/unpause
 * - Emergency withdrawal available when paused
 * - Proper event emission for all state changes
 * - Gas-optimized pause checks
 *
 * Use Cases:
 * - Stop contract when bugs are discovered
 * - Prevent operations during upgrades
 * - Emergency response to attacks
 * - Controlled shutdown procedures
 */
contract PausableContract is Pausable, AccessControl, ReentrancyGuard {

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to withdraw zero balance
    error NoBalanceToWithdraw();

    /// @notice Thrown when emergency withdrawal fails
    error EmergencyWithdrawalFailed();

    /// @notice Thrown when trying to pause already paused contract
    error AlreadyPaused();

    /// @notice Thrown when trying to unpause already unpaused contract
    error AlreadyUnpaused();

    /*//////////////////////////////////////////////////////////////
                            ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role identifier for addresses that can pause/unpause
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role identifier for addresses that can perform emergency withdrawals
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Total number of times contract has been paused
    uint256 public pauseCount;

    /// @notice Timestamp of most recent pause
    uint256 public lastPauseTime;

    /// @notice Timestamp of most recent unpause
    uint256 public lastUnpauseTime;

    /// @notice Maps user addresses to their deposited balances
    mapping(address => uint256) public balances;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when contract is paused
    /// @param pauser Address that triggered the pause
    /// @param timestamp Time of pause
    event ContractPaused(address indexed pauser, uint256 timestamp);

    /// @notice Emitted when contract is unpaused
    /// @param unpauser Address that triggered the unpause
    /// @param timestamp Time of unpause
    event ContractUnpaused(address indexed unpauser, uint256 timestamp);

    /// @notice Emitted when user deposits funds
    /// @param user Address that deposited
    /// @param amount Amount deposited
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when user withdraws funds
    /// @param user Address that withdrew
    /// @param amount Amount withdrawn
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Emitted during emergency withdrawal
    /// @param user Address that withdrew
    /// @param amount Amount withdrawn
    /// @param executor Address that executed the emergency withdrawal
    event EmergencyWithdrawal(address indexed user, uint256 amount, address indexed executor);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the pausable contract
     * @dev Grants admin, pauser, and emergency roles to deployer
     *      Contract starts in unpaused state
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);

        lastUnpauseTime = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE CONTROL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses all contract operations
     * @dev Only callable by PAUSER_ROLE
     *      Blocks all functions with whenNotPaused modifier
     *      Enables functions with whenPaused modifier (emergency functions)
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        if (paused()) revert AlreadyPaused();

        _pause();

        pauseCount++;
        lastPauseTime = block.timestamp;

        emit ContractPaused(msg.sender, block.timestamp);
    }

    /**
     * @notice Unpauses contract operations
     * @dev Only callable by PAUSER_ROLE
     *      Restores normal operations
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        if (!paused()) revert AlreadyUnpaused();

        _unpause();

        lastUnpauseTime = block.timestamp;

        emit ContractUnpaused(msg.sender, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        NORMAL OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits ETH into the contract
     * @dev Only available when contract is not paused
     *      Updates user's balance
     */
    function deposit() external payable whenNotPaused {
        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraws user's deposited ETH
     * @param amount Amount to withdraw
     * @dev Only available when contract is not paused
     *      Uses checks-effects-interactions pattern
     *      Protected against reentrancy
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        // Checks
        uint256 userBalance = balances[msg.sender];
        if (userBalance == 0) revert NoBalanceToWithdraw();
        require(amount <= userBalance, "Insufficient balance");

        // Effects
        balances[msg.sender] -= amount;

        // Interactions
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emergency withdrawal function available only when paused
     * @param user Address to withdraw funds for
     * @dev Only callable by EMERGENCY_ROLE when contract is paused
     *      Allows fund recovery during emergencies
     *      Uses pull pattern for safety
     */
    function emergencyWithdraw(address payable user) external onlyRole(EMERGENCY_ROLE) whenPaused nonReentrant {
        uint256 userBalance = balances[user];
        if (userBalance == 0) revert NoBalanceToWithdraw();

        // Effects: update balance before transfer
        balances[user] = 0;

        // Interactions: transfer funds
        (bool success, ) = user.call{value: userBalance}("");
        if (!success) revert EmergencyWithdrawalFailed();

        emit EmergencyWithdrawal(user, userBalance, msg.sender);
    }

    /**
     * @notice Batch emergency withdrawal for multiple users
     * @param users Array of user addresses to withdraw for
     * @dev Only callable by EMERGENCY_ROLE when paused
     *      Efficient for recovering funds for many users
     */
    function batchEmergencyWithdraw(address payable[] calldata users)
        external
        onlyRole(EMERGENCY_ROLE)
        whenPaused
        nonReentrant
    {
        uint256 length = users.length;

        for (uint256 i = 0; i < length; ) {
            address payable user = users[i];
            uint256 userBalance = balances[user];

            if (userBalance > 0) {
                // Effects
                balances[user] = 0;

                // Interactions
                (bool success, ) = user.call{value: userBalance}("");
                if (!success) revert EmergencyWithdrawalFailed();

                emit EmergencyWithdrawal(user, userBalance, msg.sender);
            }

            unchecked {
                ++i; // Gas optimization
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns pause status and history
     * @return isPaused Current pause status
     * @return totalPauses Total number of pauses
     * @return lastPause Timestamp of last pause
     * @return lastUnpause Timestamp of last unpause
     */
    function getPauseInfo()
        external
        view
        returns (
            bool isPaused,
            uint256 totalPauses,
            uint256 lastPause,
            uint256 lastUnpause
        )
    {
        return (paused(), pauseCount, lastPauseTime, lastUnpauseTime);
    }

    /**
     * @notice Returns user's deposited balance
     * @param user User address to query
     * @return User's balance
     */
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @notice Returns contract's total ETH balance
     * @return Contract balance
     */
    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
