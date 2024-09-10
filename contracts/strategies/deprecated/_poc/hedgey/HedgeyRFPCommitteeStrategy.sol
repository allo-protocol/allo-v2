// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Core Contracts
import {RFPCommitteeStrategy} from "../../rfp-committee/RFPCommitteeStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";

// Internal Libraries
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

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

contract HedgeyRFPCommitteeStrategy is RFPCommitteeStrategy {
    using Transfer for address;

    /// ================================
    /// ========== Storage =============
    /// ================================

    mapping(address => uint256) internal _recipientLockupTerm;

    struct HedgeyInitializeParamsCommittee {
        bool adminTransferOBO;
        address hedgeyContract;
        address adminAddress;
        InitializeParamsCommittee params;
    }

    bool public adminTransferOBO;
    address public hedgeyContract;
    address public adminAddress;

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event AdminAddressUpdated(address adminAddress, address sender);
    event AdminTransferOBOUpdated(bool adminTransferOBO, address sender);

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) RFPCommitteeStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external override {
        (HedgeyInitializeParamsCommittee memory hedgeyInitializeParamsCommittee) =
            abi.decode(_data, (HedgeyInitializeParamsCommittee));
        __HedgeyRPFCommiteeStrategy_init(_poolId, hedgeyInitializeParamsCommittee);
    }

    function __HedgeyRPFCommiteeStrategy_init(
        uint256 _poolId,
        HedgeyInitializeParamsCommittee memory _hedgeyInitializeParamsCommittee
    ) internal {
        // Initialize the RPFCommiteeStrategy
        __RPFCommiteeStrategy_init(_poolId, _hedgeyInitializeParamsCommittee.params);

        // Set the strategy specific variables
        adminTransferOBO = _hedgeyInitializeParamsCommittee.adminTransferOBO;
        hedgeyContract = _hedgeyInitializeParamsCommittee.hedgeyContract;
        adminAddress = _hedgeyInitializeParamsCommittee.adminAddress;
    }

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

    /// @notice Withdraw the tokens from the pool
    /// @dev Callable by the pool manager
    /// @param _token The token to withdraw
    function withdraw(address _token) external virtual override onlyPoolManager(msg.sender) onlyInactivePool {
        uint256 amount = _token.getBalance(address(this));

        // Transfer the tokens to the 'msg.sender' (pool manager calling function)
        _token.transferAmount(msg.sender, amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Distribute the upcoming milestone to acceptedRecipientId.
    /// @dev '_sender' must be a pool manager to distribute.
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory, bytes memory, address _sender)
        internal
        virtual
        override
        onlyInactivePool
        onlyPoolManager(_sender)
    {
        // check to make sure there is a pending milestone
        if (upcomingMilestone >= milestones.length) revert INVALID_MILESTONE();

        IAllo.Pool memory pool = allo.getPool(poolId);
        Milestone storage milestone = milestones[upcomingMilestone];
        Recipient memory recipient = _recipients[acceptedRecipientId];

        // Check if the milestone is pending
        if (milestone.milestoneStatus != Status.Pending) revert INVALID_MILESTONE();

        // Calculate the amount to be distributed for the milestone
        uint256 amount = (recipient.proposalBid * milestone.amountPercentage) / 1e18;

        // Get the pool, subtract the amount and transfer to the recipient
        poolAmount -= amount;
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        // Set the milestone status to 'Accepted'
        milestone.milestoneStatus = Status.Accepted;

        // Increment the upcoming milestone
        upcomingMilestone++;

        // Emit events for the milestone and the distribution
        emit MilestoneStatusChanged(upcomingMilestone, Status.Accepted);
        emit Distributed(acceptedRecipientId, recipient.recipientAddress, amount, _sender);
    }

    function _transferAmount(address _token, address _recipient, uint256 _amount) internal {
        IERC20(_token).approve(hedgeyContract, _amount);

        uint256 rate = _amount / _recipientLockupTerm[_recipient];
        ITokenVestingPlans(hedgeyContract).createPlan(
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
    }

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
