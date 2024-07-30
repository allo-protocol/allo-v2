// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
// Inherited LTIP Hedgey Strategy
import {LTIPHedgeyStrategy} from "../ltip-hedgey/LTIPHedgeyStrategy.sol";

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

/// @notice interface paramters to call Governor contract and get votes at a specific block
interface IGovernor {
    function getVotes(address recipient, uint256 timepoint) external view returns (uint256 votingPower);
}

/// @title LTIP Hedgey Governor Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>, @bitbeckers
/// @notice Strategy for Long-Term Incentive Programs (LTIP) allocation with distribution vested over time. Votes are weighted according to token delegation balances and payouts are distributed as Hedgey vesting plans.
contract LTIPHedgeyGovernorStrategy is LTIPHedgeyStrategy {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice The parameters used to initialize the strategy
    struct InitializeParamsGovernor {
        address governorContract;
        uint256 timepoint;
        InitializeParamsHedgey initializeParams;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Error emitted when the voter has no -delegated- tokens to determine voting weight
    error VOTING_WEIGHT_ZERO();

    /// @notice Error emitted when the voter will exceed their voting weight by casting votes
    error VOTING_EXCEEDS_WEIGHT();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the point in time to check -delegated- token balances against is updated
    /// @param adminAddress The address of the admin
    /// @param timepoint The new block number (or timestamp given the contract supports it)
    event TimepointUpdated(address adminAddress, uint256 timepoint);

    /// @notice Emitted when a voter -partially- revokes their allocated votes
    /// @param recipient The recipient of the votes
    /// @dev This could bring recipients below threshold, but won't affect already created plans
    event VotesRevoked(address recipient);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The address of the governor contract to get voting power from
    address public governorContract;
    /// @notice The block number (or timestamp) to get voting balances from the Governor contract
    uint256 public timepoint;
    /// @notice The total number of votes casted by an address
    mapping(address => uint256) public votesCasted;
    /// @notice The number of votes casted for a recipient by an address
    mapping(address => mapping(address => uint256)) public votesCastedFor;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the LTIP Hedgey Governor Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) LTIPHedgeyStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (address governorContract, uint256 votingBlock, InitializeParamsHedgey initializeParams)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __LTIPHedgeyGovernorStrategy_init(_poolId, _data);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the underlying strategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _data The initialize params
    function __LTIPHedgeyGovernorStrategy_init(uint256 _poolId, bytes memory _data) internal {
        (address _governorContract, uint256 _timepoint, InitializeParamsHedgey memory _initializeParamsHedgey) =
            abi.decode(_data, (address, uint256, InitializeParamsHedgey));
        __LTIPHedgeyStrategy_init(_poolId, _initializeParamsHedgey);

        if (_timepoint == 0) revert INVALID();
        if (_governorContract == address(0)) revert ZERO_ADDRESS();

        timepoint = _timepoint;
        governorContract = _governorContract;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update the block number to get voting balances from the Governor contract
    /// @param _timepoint The new block number
    function setTimepoint(uint256 _timepoint) external onlyPoolManager(msg.sender) {
        if (_timepoint == 0) revert INVALID();
        timepoint = _timepoint;
        emit TimepointUpdated(msg.sender, _timepoint);
    }

    /// @notice Revokes allocated votes from a recipient
    /// @param _recipientId The recipient to revoke votes from
    /// @param _votes The number of votes to revoke
    function revokeVotes(address _recipientId, uint256 _votes) external nonReentrant {
        // Will revert if the updated balances would underflow
        uint256 _votesCastedFor = votesCastedFor[msg.sender][_recipientId] - _votes;
        uint256 _updatedVotesCasted = votesCasted[msg.sender] - _votes;
        uint256 _updatedVotes = votes[_recipientId] - _votes;

        // Update the votes
        votes[_recipientId] = _updatedVotes;
        votesCasted[msg.sender] = _updatedVotesCasted;
        votesCastedFor[msg.sender][_recipientId] = _votesCastedFor;

        emit VotesRevoked(_recipientId);

        if (votes[_recipientId] < votingThreshold) {
            emit AllocationRevoked(_recipientId, msg.sender);
        }
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Allocate (delegated) voting weight to a recipient. In the Governor strategy, we check the votes at a specific block
    /// @dev '_sender' must have a balance > 0 of delegate tokens
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyActiveAllocation
    {
        // Decode the '_data'
        (address recipientId, uint256 _votes) = abi.decode(_data, (address, uint256));
        Recipient memory recipient = _recipients[recipientId];

        if (recipient.recipientStatus != Status.Accepted) revert RECIPIENT_NOT_ACCEPTED();

        uint256 _votingPower = IGovernor(governorContract).getVotes(_sender, timepoint);
        uint256 _votesCasted = votesCasted[_sender];

        if (_votingPower == 0) revert VOTING_WEIGHT_ZERO();
        if (_votesCasted + _votes > _votingPower) revert VOTING_EXCEEDS_WEIGHT();

        // Increment the votes for the recipient
        votes[recipientId] += _votes;
        votesCasted[_sender] += _votes;
        votesCastedFor[_sender][recipientId] += _votes;

        // Emit the event
        emit Voted(recipientId, _sender);

        if (votes[recipientId] >= votingThreshold) {
            emit Allocated(recipientId, recipient.allocationAmount, allo.getPool(poolId).token, _sender);
        }
    }

    /// ====================================
    /// ============== Hooks ===============
    /// ====================================

    /// @notice Checks if address is eligible allocator.
    /// @dev This is used to check if the allocator is a pool manager and able to allocate funds from the pool
    /// @param _allocator Address of the allocator
    /// @return 'true' if the allocator is a pool manager, otherwise false
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return IGovernor(governorContract).getVotes(_allocator, timepoint) > 0;
    }
}
