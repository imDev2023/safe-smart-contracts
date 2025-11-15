// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title StakingContract
 * @author Smart Contract Security Best Practices
 * @notice Production-ready staking contract with rewards distribution
 * @dev Implements a token staking system with:
 *      - Token staking and unstaking
 *      - Reward calculation and distribution
 *      - Lockup periods for unstaking
 *      - Pausable for emergency stops
 *      - ReentrancyGuard for security
 *      - AccessControl for admin functions
 *      - SafeERC20 for token transfers
 *
 * Security Considerations:
 * - Uses SafeERC20 to handle token transfers safely
 * - ReentrancyGuard prevents reentrancy attacks
 * - Follows checks-effects-interactions pattern
 * - Pausable for emergency situations
 * - No division before multiplication (precision)
 * - Proper reward accounting per user
 */
contract StakingContract is ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when staking zero tokens
    error CannotStakeZero();

    /// @notice Thrown when unstaking zero tokens
    error CannotUnstakeZero();

    /// @notice Thrown when trying to unstake more than staked balance
    error InsufficientStakedBalance();

    /// @notice Thrown when trying to claim with no rewards
    error NoRewardsToClaim();

    /// @notice Thrown when unstaking before lockup period ends
    error StillInLockupPeriod();

    /// @notice Thrown when reward rate is zero
    error InvalidRewardRate();

    /// @notice Thrown when trying to withdraw more than available
    error InsufficientRewardBalance();

    /*//////////////////////////////////////////////////////////////
                            ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role for pausing/unpausing the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role for managing reward parameters
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The token being staked
    IERC20 public immutable stakingToken;

    /// @notice The token given as rewards (can be same as staking token)
    IERC20 public immutable rewardToken;

    /// @notice Reward rate per second (in reward token wei per staked token wei)
    /// @dev Scaled by 1e18 for precision
    uint256 public rewardRatePerSecond;

    /// @notice Lockup period in seconds before unstaking is allowed
    uint256 public lockupPeriod;

    /// @notice Total tokens currently staked
    uint256 public totalStaked;

    /// @notice Tracks last update time for reward calculations
    uint256 public lastUpdateTime;

    /// @notice Accumulated reward per token staked (scaled by 1e18)
    uint256 public rewardPerTokenStored;

    /*//////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Information about a staker
     * @param stakedAmount Total tokens staked by user
     * @param rewardDebt Rewards already accounted for
     * @param lastStakeTime Timestamp of most recent stake
     * @param pendingRewards Rewards calculated but not yet claimed
     */
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 lastStakeTime;
        uint256 pendingRewards;
    }

    /*//////////////////////////////////////////////////////////////
                            MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps user address to their staking information
    mapping(address => StakerInfo) public stakers;

    /// @notice User's reward per token paid (for reward calculation)
    mapping(address => uint256) public userRewardPerTokenPaid;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when user stakes tokens
    event Staked(address indexed user, uint256 amount, uint256 timestamp);

    /// @notice Emitted when user unstakes tokens
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);

    /// @notice Emitted when user claims rewards
    event RewardClaimed(address indexed user, uint256 amount, uint256 timestamp);

    /// @notice Emitted when reward rate is updated
    event RewardRateUpdated(uint256 oldRate, uint256 newRate, address indexed updatedBy);

    /// @notice Emitted when lockup period is updated
    event LockupPeriodUpdated(uint256 oldPeriod, uint256 newPeriod, address indexed updatedBy);

    /// @notice Emitted when rewards are deposited into contract
    event RewardsDeposited(uint256 amount, address indexed depositor);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the staking contract
     * @param stakingToken_ Address of token to be staked
     * @param rewardToken_ Address of token given as reward
     * @param rewardRatePerSecond_ Initial reward rate per second (scaled by 1e18)
     * @param lockupPeriod_ Lockup period in seconds
     */
    constructor(
        address stakingToken_,
        address rewardToken_,
        uint256 rewardRatePerSecond_,
        uint256 lockupPeriod_
    ) {
        stakingToken = IERC20(stakingToken_);
        rewardToken = IERC20(rewardToken_);
        rewardRatePerSecond = rewardRatePerSecond_;
        lockupPeriod = lockupPeriod_;
        lastUpdateTime = block.timestamp;

        // Grant roles to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(REWARD_MANAGER_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stakes tokens into the contract
     * @param amount Amount of tokens to stake
     * @dev Updates rewards before staking
     *      Uses SafeERC20 for safe token transfer
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert CannotStakeZero();

        // Update rewards before changing stake
        _updateReward(msg.sender);

        // Effects: update staker info
        StakerInfo storage staker = stakers[msg.sender];
        staker.stakedAmount += amount;
        staker.lastStakeTime = block.timestamp;
        totalStaked += amount;

        // Interactions: transfer tokens from user
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Unstakes tokens from the contract
     * @param amount Amount of tokens to unstake
     * @dev Enforces lockup period
     *      Updates rewards before unstaking
     */
    function unstake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert CannotUnstakeZero();

        StakerInfo storage staker = stakers[msg.sender];

        if (staker.stakedAmount < amount) revert InsufficientStakedBalance();

        // Check lockup period
        if (block.timestamp < staker.lastStakeTime + lockupPeriod) {
            revert StillInLockupPeriod();
        }

        // Update rewards before changing stake
        _updateReward(msg.sender);

        // Effects: update staker info
        staker.stakedAmount -= amount;
        totalStaked -= amount;

        // Interactions: transfer tokens to user
        stakingToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        REWARD FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claims all pending rewards
     * @dev Updates rewards before claiming
     *      Transfers reward tokens to user
     */
    function claimReward() external nonReentrant whenNotPaused {
        _updateReward(msg.sender);

        StakerInfo storage staker = stakers[msg.sender];
        uint256 reward = staker.pendingRewards;

        if (reward == 0) revert NoRewardsToClaim();

        // Effects: reset pending rewards
        staker.pendingRewards = 0;

        // Interactions: transfer reward tokens
        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward, block.timestamp);
    }

    /**
     * @notice Deposits reward tokens into contract for distribution
     * @param amount Amount of reward tokens to deposit
     * @dev Only callable by REWARD_MANAGER_ROLE
     */
    function depositRewards(uint256 amount) external onlyRole(REWARD_MANAGER_ROLE) {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsDeposited(amount, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the reward rate
     * @param newRewardRate New reward rate per second (scaled by 1e18)
     * @dev Only callable by REWARD_MANAGER_ROLE
     */
    function setRewardRate(uint256 newRewardRate) external onlyRole(REWARD_MANAGER_ROLE) {
        if (newRewardRate == 0) revert InvalidRewardRate();

        _updateRewardPerToken();

        uint256 oldRate = rewardRatePerSecond;
        rewardRatePerSecond = newRewardRate;

        emit RewardRateUpdated(oldRate, newRewardRate, msg.sender);
    }

    /**
     * @notice Updates the lockup period
     * @param newLockupPeriod New lockup period in seconds
     * @dev Only callable by REWARD_MANAGER_ROLE
     */
    function setLockupPeriod(uint256 newLockupPeriod) external onlyRole(REWARD_MANAGER_ROLE) {
        uint256 oldPeriod = lockupPeriod;
        lockupPeriod = newLockupPeriod;

        emit LockupPeriodUpdated(oldPeriod, newLockupPeriod, msg.sender);
    }

    /**
     * @notice Pauses the contract
     * @dev Only callable by PAUSER_ROLE
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev Only callable by PAUSER_ROLE
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates global reward per token value
     * @dev Called before any stake/unstake/claim operation
     */
    function _updateRewardPerToken() internal {
        if (totalStaked == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        uint256 rewardToDistribute = timeElapsed * rewardRatePerSecond;

        // Update reward per token (scaled by 1e18 for precision)
        rewardPerTokenStored += (rewardToDistribute * 1e18) / totalStaked;
        lastUpdateTime = block.timestamp;
    }

    /**
     * @notice Updates reward for a specific user
     * @param account User address to update rewards for
     */
    function _updateReward(address account) internal {
        _updateRewardPerToken();

        StakerInfo storage staker = stakers[account];

        if (staker.stakedAmount > 0) {
            // Calculate earned rewards since last update
            uint256 earned = (staker.stakedAmount *
                (rewardPerTokenStored - userRewardPerTokenPaid[account])) / 1e18;

            staker.pendingRewards += earned;
        }

        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns pending rewards for a user
     * @param account User address
     * @return Pending reward amount
     */
    function pendingReward(address account) external view returns (uint256) {
        StakerInfo memory staker = stakers[account];

        if (totalStaked == 0) {
            return staker.pendingRewards;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        uint256 rewardToDistribute = timeElapsed * rewardRatePerSecond;
        uint256 newRewardPerToken = rewardPerTokenStored + (rewardToDistribute * 1e18) / totalStaked;

        uint256 earned = (staker.stakedAmount * (newRewardPerToken - userRewardPerTokenPaid[account])) /
            1e18;

        return staker.pendingRewards + earned;
    }

    /**
     * @notice Returns staked balance for a user
     * @param account User address
     * @return Staked token amount
     */
    function stakedBalance(address account) external view returns (uint256) {
        return stakers[account].stakedAmount;
    }

    /**
     * @notice Returns time remaining in lockup period
     * @param account User address
     * @return Seconds remaining (0 if lockup expired)
     */
    function lockupRemaining(address account) external view returns (uint256) {
        StakerInfo memory staker = stakers[account];
        uint256 unlockTime = staker.lastStakeTime + lockupPeriod;

        if (block.timestamp >= unlockTime) {
            return 0;
        }

        return unlockTime - block.timestamp;
    }
}
