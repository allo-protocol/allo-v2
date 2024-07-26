// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
// Inherited simple LTIP
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

/// @title LTIP Hedgey Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>, @bitbeckers
/// @notice Strategy for Long-Term Incentive Programs (LTIP) allocation with distribution vested over time. Vesting plans are created using Hedgey.
contract LTIPHedgeyStrategy is LTIPSimpleStrategy {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice The parameters used to initialize the strategy
    struct InitializeParamsHedgey {
        address hedgeyContract;
        address vestingAdmin;
        bool adminTransferOBO;
        uint256 cliff;
        uint256 rate;
        uint256 period;
        InitializeParams initializeParams;
    }

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the admin address of the Hedgey vesting plan is updated
    /// @param adminAddress The new admin address
    /// @param sender The address that sent the transaction
    /// @dev This does not impact already created plans
    event AdminAddressUpdated(address adminAddress, address sender);

    /// @notice Emitted when the admin transfer OBO is updated
    /// @param adminTransferOBO The new admin transfer OBO
    /// @param sender The address that sent the transaction
    event AdminTransferOBOUpdated(bool adminTransferOBO, address sender);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The contract that mints the Hedgey vesting plans
    address public hedgeyContract;

    /// @notice The admin address of the Hedgey vesting plan, this address can revoke created plans
    address public vestingAdmin;

    /// @notice Toggle to allow the vestingAdmin to transfer a plan and NFT to another wallet on behalf of (OBO) a beneficiary. To be used only for emergencies.
    bool public adminTransferOBO;

    /// @notice A cliff date which is a discrete date where tokens are not vested until this date, and then vest in a large single chunk on the cliff date
    uint256 public cliff;

    /// @notice The amount of tokens that vest in a single period
    uint256 public rate;

    /// @notice The amount of time in between each vesting time stamp, in seconds. A period of 1 means that tokens vest every second in a 'streaming' style.
    uint256 public period;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the LTIP Hedgey Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) LTIPSimpleStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (address hedgeyContract, address vestingAdmin, bool adminTransferOBO, InitializeParams initializeParams)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParamsHedgey memory initializeParamsHedgey) = abi.decode(_data, (InitializeParamsHedgey));
        __LTIPHedgeyStrategy_init(_poolId, initializeParamsHedgey);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the LTIPSimpleStrategy
    /// @dev You only need to pass the 'poolId' and the `initializeParams` to initialize the LTIPSimpleStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __LTIPHedgeyStrategy_init(uint256 _poolId, InitializeParamsHedgey memory _initializeParams) internal {
        // Initialize the BaseStrategy
        __LTIPSimpleStrategy_init(_poolId, _initializeParams.initializeParams);

        if (_initializeParams.hedgeyContract == address(0)) revert ZERO_ADDRESS();
        if (_initializeParams.vestingAdmin == address(0)) revert ZERO_ADDRESS();
        hedgeyContract = _initializeParams.hedgeyContract;
        vestingAdmin = _initializeParams.vestingAdmin;
        adminTransferOBO = _initializeParams.adminTransferOBO;
        cliff = _initializeParams.cliff;
        rate = _initializeParams.rate;
        period = _initializeParams.period;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update the default admin wallet used when creating Hedgey plans
    /// @param _vestingAdmin The new admin address
    function setVestingAdmin(address _vestingAdmin) external onlyPoolManager(msg.sender) {
        if (_vestingAdmin == address(0)) revert ZERO_ADDRESS();
        vestingAdmin = _vestingAdmin;
        emit AdminAddressUpdated(vestingAdmin, msg.sender);
    }

    /// @notice Update the default admin wallet used when creating Hedgey plans
    /// @param _adminTransferOBO Set if the admin is allowed to transfer on behalf of the recipient
    function setAdminTransferOBO(bool _adminTransferOBO) external onlyPoolManager(msg.sender) {
        adminTransferOBO = _adminTransferOBO;
        emit AdminTransferOBOUpdated(_adminTransferOBO, msg.sender);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Creates a Hedgey vesting plan for the recipient
    /// @param recipientId The recipient ID
    /// @param recipientAddress The recipient address
    /// @param _token The address of the tokens to vest
    /// @param _amount The amount to vest
    function _vestAmount(address recipientId, address recipientAddress, address _token, uint256 _amount)
        internal
        virtual
        override
    {
        IERC20(_token).approve(hedgeyContract, _amount);

        uint256 hedgeyId = ITokenVestingPlans(hedgeyContract).createPlan(
            recipientAddress, _token, _amount, block.timestamp, cliff, rate, period, vestingAdmin, adminTransferOBO
        );

        _vestingPlans[recipientId] = VestingPlan(hedgeyContract, hedgeyId);
        _transferAmount(_token, address(hedgeyContract), _amount);

        emit VestingPlanCreated(recipientId, hedgeyContract, hedgeyId);
    }
}
