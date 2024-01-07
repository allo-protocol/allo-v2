// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Core Contracts
import {RFPCommitteeStrategy} from "../../rfp-committee/RFPCommitteeStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";

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
        uint256 amount = _getBalance(_token, address(this));

        // Transfer the tokens to the 'msg.sender' (pool manager calling function)
        super._transferAmount(_token, msg.sender, amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    function _transferAmount(address _token, address _recipient, uint256 _amount) internal override {
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
