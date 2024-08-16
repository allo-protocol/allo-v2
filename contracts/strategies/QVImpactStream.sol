// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

// Interfaces
import {IAllo} from "../core/interfaces/IAllo.sol";
// Core Contracts
import {QVSimple} from "./QVSimple.sol";

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
contract QVImpactStream is QVSimple, Multicall {
    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when the payouts are set
    /// @param payouts The payouts to distribute
    /// @param sender The sender of the transaction
    event PayoutSet(Payout[] payouts, address sender);

    /// ======================
    /// ======= Errors =======
    /// ======================

    /// @notice Thrown when payout is already set
    error PAYOUT_ALREADY_SET();

    /// @notice Thrown when the total set payout is more than the pool balance
    error PAYOUT_MORE_THAN_POOL_BALANCE();

    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @notice Returns the amount to pay to the recipient
    /// @dev recipientId => payouts
    mapping(address => uint256) public payouts;

    bool public payoutSet;

    /// ======================
    /// ======= Struct =======
    /// ======================

    /// @notice The details of the payout set by the pool managers
    struct Payout {
        address recipientId;
        uint256 amount;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @notice Constructor for the QV Impact Stream strategy
    /// @param _allo The 'Allo' contract
    constructor(address _allo) QVSimple(_allo) {}

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Add allocator array
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocators The allocator address array
    function batchAddAllocator(address[] memory _allocators) external onlyPoolManager(msg.sender) {
        uint256 length = _allocators.length;
        for (uint256 i = 0; i < length;) {
            _addAllocator(_allocators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Remove allocator array
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocators The allocators address array
    function batchRemoveAllocator(address[] memory _allocators) external onlyPoolManager(msg.sender) {
        uint256 length = _allocators.length;
        for (uint256 i = 0; i < length;) {
            _removeAllocator(_allocators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the payouts to distribute
    /// @dev Only the pool manager(s) can call this function
    /// @param _payouts The payouts to distribute
    function setPayouts(Payout[] memory _payouts) external onlyPoolManager(msg.sender) onlyAfterAllocation {
        if (payoutSet) revert PAYOUT_ALREADY_SET();
        payoutSet = true;

        uint256 totalAmount;

        uint256 length = _payouts.length;
        for (uint256 i = 0; i < length;) {
            Payout memory payout = _payouts[i];
            uint256 amount = payout.amount;
            address recipientId = payout.recipientId;

            if (amount == 0 || _getRecipientStatus(recipientId) != Status.Accepted) {
                revert RECIPIENT_ERROR(payout.recipientId);
            }

            payouts[recipientId] = amount;
            totalAmount += amount;
            unchecked {
                ++i;
            }
        }

        if (totalAmount > poolAmount) revert PAYOUT_MORE_THAN_POOL_BALANCE();

        emit PayoutSet(_payouts, msg.sender);
    }

    /// =============================
    /// ==== Internal Functions =====
    /// =============================

    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyAfterAllocation
    {
        IAllo.Pool memory pool = allo.getPool(poolId);
        address poolToken = pool.token;

        uint256 length = _recipientIds.length;
        for (uint256 i = 0; i < length;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = _recipients[recipientId];

            address recipientAddress = recipient.recipientAddress;
            uint256 amount = payouts[recipientId];

            if (amount == 0) revert RECIPIENT_ERROR(recipientId);

            delete payouts[recipientId];

            _transferAmount(poolToken, recipientAddress, amount);

            bytes memory data = abi.encode(recipientAddress, amount, _sender);

            emit Distributed(recipientId, data);

            unchecked {
                ++i;
            }
        }
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the total votes received for a recipient
    /// @param _recipient The address of the recipient
    /// @return The total votes received by the recipient
    function getTotalVotesForRecipient(address _recipient) external view returns (uint256) {
        return _votingState.recipientVotes[_recipient];
    }

    /// @notice Get the payout for a single recipient
    /// @param _recipientId The ID of the recipient
    /// @return The payout as a 'Payout' struct
    function getPayout(address _recipientId) external view returns (Payout memory) {
        uint256 amount = payouts[_recipientId];
        return Payout(_recipientId, amount);
    }

    /// @notice Transfer the funds recovered  to the recipient
    /// @dev 'msg.sender' must be pool manager
    /// @param _token The token to transfer
    /// @param _recipient The recipient
    function recoverFunds(address _token, address _recipient) external onlyPoolManager(msg.sender) {
        // Get the amount of the token to transfer, which is always the entire balance of the contract address
        uint256 amount = _token == NATIVE ? address(this).balance : IERC20Upgradeable(_token).balanceOf(address(this));

        // Transfer the amount to the recipient (pool owner)
        _transferAmount(_token, _recipient, amount);
    }
}
