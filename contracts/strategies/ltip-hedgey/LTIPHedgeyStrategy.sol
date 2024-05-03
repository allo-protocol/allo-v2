// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../core/interfaces/IRegistry.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

// Simple LTIP
import {LTIPSimpleStrategy} from "../ltip-simple/LTIPSimpleStrategy.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @notice interface paramters to call Hedgey and create a vesting plan
interface ITokenVestingPlans {
    function createPlan(
        address recipient,
        address token,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 rate,
        uint256 period,
        address vestingAdmin,
        bool adminTransferOBO
    ) external returns (uint256 newPlanId);
}

/// @title LTIP Simple Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>, @bitbeckers
/// @notice Strategy for Long-Term Incentive Programs (LTIP) allocation with distribution vested over time. The simple strategy retains the funds in the round untill the period has expired
contract LTIPHedgeyStrategy is LTIPSimpleStrategy {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    // TODO packing
    /// @notice The parameters used to initialize the strategy
    struct InitializeParamsHedgey {
        address hedgeyContract;
        address vestingAdmin;
        bool adminTransferOBO;
        InitializeParams initializeParams;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event AdminAddressUpdated(address adminAddress, address sender);
    event AdminTransferOBOUpdated(bool adminTransferOBO, address sender);

    /// ================================
    /// ========== Storage =============
    /// ================================

    address public hedgeyContract;
    address public adminAddress;
    bool public adminTransferOBO;
    mapping(address => uint256) internal _recipientLockupTerm;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the RFP Simple Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) LTIPSimpleStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool registryGating, bool metadataRequired, uint256 allocationThreshold, uint64 registrationStartTime, uint64 registrationEndTime, uint64 allocationStartTime, uint64 allocationEndTime)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParamsHedgey memory initializeParams) = abi.decode(_data, (InitializeParamsHedgey));
        __LTIPHedgeyStrategy_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __LTIPHedgeyStrategy_init(uint256 _poolId, InitializeParamsHedgey memory _initializeParams) internal {
        // Initialize the BaseStrategy
        __LTIPSimpleStrategy_init(_poolId, _initializeParams.initializeParams);

        hedgeyContract = _initializeParams.hedgeyContract;
        adminAddress = _initializeParams.vestingAdmin;
        adminTransferOBO = _initializeParams.adminTransferOBO;
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    // TODO do we need a custom getPayouts because of the Hedgey data?

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update the default Admin wallet used when creating Hedgey plans
    /// @param _adminAddress The admin wallet to use
    function setAdminAddress(address _adminAddress) external onlyPoolManager(msg.sender) {
        adminAddress = _adminAddress;
        emit AdminAddressUpdated(_adminAddress, msg.sender);
    }

    /// @notice Update the default Admin wallet used when creating Hedgey plans
    /// @param _adminTransferOBO Set if the admin is allowed to transfer on behalf of the recipient
    function setAdminTransferOBO(bool _adminTransferOBO) external onlyPoolManager(msg.sender) {
        adminTransferOBO = _adminTransferOBO;
        emit AdminTransferOBOUpdated(_adminTransferOBO, msg.sender);
    }

    /// @notice Get the lockup term for a recipient
    /// @param _recipient The recipient to get the lockup term for
    function getRecipientLockupTerm(address _recipient) external view returns (uint256) {
        return _recipientLockupTerm[_recipient];
    }

    /// @notice Revoke the allocation and return funds to the pool
    /// @dev Callable by the pool manager
    /// @param _recipientId The id of the recipient
    function revoke(address _recipientId) external virtual onlyPoolManager(msg.sender) {
        Recipient storage recipient = _recipients[_recipientId];

        recipient.recipientStatus = Status.Canceled;

        /// TODO transfer funds back to the pool, maybe out of scope for now

        emit AllocationRevoked(_recipientId, msg.sender);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    function _transferAmount(address _token, address _recipient, uint256 _amount) internal override {
        IERC20(_token).approve(hedgeyContract, _amount);

        uint256 rate = _amount / _recipientLockupTerm[_recipient];
        uint256 hedgeyId = ITokenVestingPlans(hedgeyContract).createPlan(
            _recipient,
            _token,
            _amount,
            block.timestamp,
            0, // No cliff
            rate,
            1, // Linear period
            adminAddress,
            adminTransferOBO
        );

        emit VestingPlanCreated(hedgeyContract, hedgeyId);
    }

    /// @notice Distribute the allocated funds to a recipient as an hedgey.
    function _distribute(address[] memory, bytes memory, address _sender) internal virtual override {
        IAllo.Pool memory pool = allo.getPool(poolId);
        Recipient memory recipient = _recipients[acceptedRecipientId];

        // Check if the recipient is accepten
        if (recipient.recipientStatus != Status.Accepted) revert RECIPIENT_NOT_ACCEPTED();

        // TODO throw if already allocated (ALREADY_ALLOCATED())

        // Get the pool, subtract the amount and transfer to the recipient
        poolAmount -= recipient.allocationAmount;

        _transferAmount(pool.token, recipient.recipientAddress, recipient.allocationAmount);

        // Emit events for the milestone and the distribution
        emit Distributed(acceptedRecipientId, recipient.recipientAddress, recipient.allocationAmount, _sender);
    }

    /// TODO add method  for batch distribution

    /// ====================================
    /// ============== Hooks ===============
    /// ====================================

    function _afterRegisterRecipient(bytes memory _data, address) internal override {
        uint256 lockupTerm;
        address recipientAddress;
        (, recipientAddress,,, lockupTerm) = abi.decode(_data, (address, address, uint256, Metadata, uint256));

        _recipientLockupTerm[recipientAddress] = lockupTerm;
    }
}
