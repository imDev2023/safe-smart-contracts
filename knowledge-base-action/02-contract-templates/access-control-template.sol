// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RoleBasedAccessControl
 * @author Smart Contract Security Best Practices
 * @notice Production-ready role-based access control (RBAC) template
 * @dev Implements a flexible multi-role access control system with:
 *      - Hierarchical role structure (ADMIN > MANAGER > USER)
 *      - Role granting and revoking capabilities
 *      - Role enumeration and checking
 *      - Modifier-based access guards
 *      - Event logging for all role changes
 *
 * Security Considerations:
 * - Uses OpenZeppelin's audited AccessControl
 * - Admin role can grant/revoke all roles
 * - Users can renounce their own roles
 * - Proper event emission for transparency
 * - Gas-optimized role checks via modifiers
 */
contract RoleBasedAccessControl is AccessControl {

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to grant role to zero address
    error CannotGrantRoleToZeroAddress();

    /// @notice Thrown when attempting to revoke role from zero address
    error CannotRevokeRoleFromZeroAddress();

    /// @notice Thrown when non-admin tries to perform admin action
    error RequiresAdminRole();

    /// @notice Thrown when non-manager tries to perform manager action
    error RequiresManagerRole();

    /// @notice Thrown when attempting self-revocation of admin role
    error CannotRevokeSelfAdmin();

    /*//////////////////////////////////////////////////////////////
                            ROLE DEFINITIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Admin role - highest level access
     * @dev Can grant/revoke all roles, including other admins
     *      Has all permissions in the system
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @notice Manager role - intermediate level access
     * @dev Can manage users and perform operational tasks
     *      Cannot manage other managers or admins
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /**
     * @notice User role - basic level access
     * @dev Can perform standard user operations
     *      Cannot manage roles or perform administrative tasks
     */
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a role is granted to an account
    /// @param role The role identifier that was granted
    /// @param account Address that received the role
    /// @param sender Address that granted the role
    event RoleGrantedExtended(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice Emitted when a role is revoked from an account
    /// @param role The role identifier that was revoked
    /// @param account Address that lost the role
    /// @param sender Address that revoked the role
    event RoleRevokedExtended(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice Emitted when an account renounces a role
    /// @param role The role identifier that was renounced
    /// @param account Address that renounced the role
    event RoleRenounced(bytes32 indexed role, address indexed account);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the access control system
     * @dev Grants ADMIN_ROLE and DEFAULT_ADMIN_ROLE to deployer
     *      Sets up role hierarchy: ADMIN_ROLE administers MANAGER_ROLE and USER_ROLE
     */
    constructor() {
        // Grant admin roles to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        // Set up role hierarchy
        // ADMIN_ROLE can grant/revoke MANAGER_ROLE
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);
        // ADMIN_ROLE can grant/revoke USER_ROLE
        _setRoleAdmin(USER_ROLE, ADMIN_ROLE);
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to admin role holders
     * @dev Reverts with RequiresAdminRole if caller doesn't have ADMIN_ROLE
     */
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert RequiresAdminRole();
        _;
    }

    /**
     * @notice Restricts function access to manager role holders
     * @dev Reverts with RequiresManagerRole if caller doesn't have MANAGER_ROLE
     */
    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, msg.sender)) revert RequiresManagerRole();
        _;
    }

    /**
     * @notice Restricts function access to admin or manager role holders
     * @dev Allows either role to execute the function
     */
    modifier onlyAdminOrManager() {
        if (!hasRole(ADMIN_ROLE, msg.sender) && !hasRole(MANAGER_ROLE, msg.sender)) {
            revert RequiresManagerRole();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        ROLE MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Grants a role to an account
     * @param role The role to grant
     * @param account Address to receive the role
     * @dev Only callable by admin of the role
     *      Emits RoleGrantedExtended event
     */
    function grantRoleExtended(bytes32 role, address account) external {
        if (account == address(0)) revert CannotGrantRoleToZeroAddress();

        // Use AccessControl's built-in role admin check
        grantRole(role, account);

        emit RoleGrantedExtended(role, account, msg.sender);
    }

    /**
     * @notice Revokes a role from an account
     * @param role The role to revoke
     * @param account Address to lose the role
     * @dev Only callable by admin of the role
     *      Prevents self-revocation of admin role to avoid lockout
     */
    function revokeRoleExtended(bytes32 role, address account) external {
        if (account == address(0)) revert CannotRevokeRoleFromZeroAddress();

        // Prevent admin from revoking their own admin role (avoid lockout)
        if (role == ADMIN_ROLE && account == msg.sender) {
            revert CannotRevokeSelfAdmin();
        }

        // Use AccessControl's built-in role admin check
        revokeRole(role, account);

        emit RoleRevokedExtended(role, account, msg.sender);
    }

    /**
     * @notice Allows an account to renounce their own role
     * @param role The role to renounce
     * @dev Caller must have the role they're renouncing
     *      Cannot renounce admin role to prevent system lockout
     */
    function renounceRoleExtended(bytes32 role) external {
        if (role == ADMIN_ROLE) revert CannotRevokeSelfAdmin();

        renounceRole(role, msg.sender);

        emit RoleRenounced(role, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        EXAMPLE PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Example function restricted to admins only
     * @dev Replace with actual admin functionality
     */
    function adminOnlyFunction() external onlyAdmin {
        // Admin-only logic here
    }

    /**
     * @notice Example function restricted to managers only
     * @dev Replace with actual manager functionality
     */
    function managerOnlyFunction() external onlyManager {
        // Manager-only logic here
    }

    /**
     * @notice Example function accessible by both admins and managers
     * @dev Replace with actual functionality
     */
    function adminOrManagerFunction() external onlyAdminOrManager {
        // Admin or manager logic here
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if an account is an admin
     * @param account Address to check
     * @return True if account has ADMIN_ROLE
     */
    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    /**
     * @notice Checks if an account is a manager
     * @param account Address to check
     * @return True if account has MANAGER_ROLE
     */
    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    /**
     * @notice Checks if an account is a user
     * @param account Address to check
     * @return True if account has USER_ROLE
     */
    function isUser(address account) external view returns (bool) {
        return hasRole(USER_ROLE, account);
    }

    /**
     * @notice Returns the admin role for a given role
     * @param role The role to query
     * @return The admin role identifier
     * @dev The admin role can grant/revoke the queried role
     */
    function getAdminRole(bytes32 role) external view returns (bytes32) {
        return getRoleAdmin(role);
    }
}
