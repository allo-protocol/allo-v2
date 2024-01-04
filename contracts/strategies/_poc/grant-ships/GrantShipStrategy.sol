// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";

contract GrantShipStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Structs =============
    /// ================================

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 grantAmount;
        Metadata metadata;
        Status recipientStatus;
        Status milestonesReviewStatus;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// ===============================
    /// ========== State ==============
    /// ===============================

    /// @notice The Ship Operator Hat ID for the pool
    uint256 public shipOperatorId;

    /// @notice The address that controls aspects of this pool
    // responsible for setting the pool active and inactive
    address private _gameController;

    /// @notice Flag to check if registry gating is enabled.
    bool public registryGating;

    /// @notice Flag to check if metadata is required.
    bool public metadataRequired;

    /// @notice Flag to check if grant amount is required.
    bool public grantAmountRequired;

    /// @notice The 'Registry' contract interface.
    IRegistry private _registry;

    /// @notice The total amount allocated to grant/recipient.
    uint256 public allocatedGrantAmount;

    /// @notice This maps accepted recipients to their details
    /// @dev 'recipientId' to 'Recipient'
    mapping(address => Recipient) private _recipients;

    /// @notice This maps accepted recipients to their milestones
    /// @dev 'recipientId' to 'Milestone'
    mapping(address => Milestone[]) public milestones;

    /// @notice This maps accepted recipients to their upcoming milestone
    /// @dev 'recipientId' to 'nextMilestone'
    mapping(address => uint256) public upcomingMilestone;

    /// @notice This maps accepted recipients to their Grant Ship review rating
    /// @dev 'recipientId' to 'rating'
    mapping(address => uint256) public ratings;
    uint256 public totalRating;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// ===============================
    /// ============ Internal =========
    /// ===============================

    /// @notice Flag to check if registry gating is enabled.
    bool public registryGating;

    /// @notice Flag to check if metadata is required.
    bool public metadataRequired;

    /// @notice Flag to check if grant amount is required.
    bool public grantAmountRequired;

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __GrantShip_init(_poolId, _data);
    }

    function __GrantShip_init(uint256 _poolId, bytes memory _data) internal {
        __BaseStrategy_init(_poolId);
    }

    function _allocate(bytes memory _data, address _sender) internal virtual override {}
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}
    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        override
        returns (PayoutSummary memory)
    {}
    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {}
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {}
    function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address) {}

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
