// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Interfaces
import {IAllo} from "../../core/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Native} from "../../core/libraries/Native.sol";
import {NFT} from "./NFT.sol";
import {NFTFactory} from "./NFTFactory.sol";

contract WrappedVotingNftMintStrategy is Native, BaseStrategy, Initializable, ReentrancyGuard {
    enum InternalRecipientStatus {
        Pending,
        Accepted,
        Rejected
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error REGISTRATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error RECIPIENT_ERROR(address recipientId);
    error INVALID();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event Appealed(address indexed recipientId, bytes data, address sender);
    event RecipientStatusUpdated(address indexed recipientId, InternalRecipientStatus recipientStatus, address sender);
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);
    event TimestampsUpdated(uint256 allocationStartTime, uint256 allocationEndTime, address sender);

    /// ================================
    /// ========== Modifier ============
    /// ================================

    modifier onlyActiveAllocation() {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyAfterAllocation() {
        if (block.timestamp < allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
        _;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    NFTFactory public nftFactory;

    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    // The current winner of the pool balance
    address public currentWinner;

    // recipientId => amount
    mapping(address => uint256) public allocations;

    /// ================================
    /// ========== Constructor =========
    /// ================================

    /// @notice Constructor for initializing the WrappedVotingStrategy contract
    /// @param _allo The address of the ALLO contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ================================
    /// ========== Initializer =========
    /// ================================

    /// @notice Initializes the WrappedVotingStrategy contract
    /// @param _poolId The ID of the pool
    /// @param _data The data containing the NFTFactory address, allocation start time, and allocation end time
    function initialize(uint256 _poolId, bytes memory _data) external override {
        (address nftFactoryAddress, uint256 _allocationStartTime, uint256 _allocationEndTime) =
            abi.decode(_data, (address, uint256, uint256));
        __WrappedVotingStrategy_init(_poolId, nftFactoryAddress, _allocationStartTime, _allocationEndTime);
    }

    /// ====================
    /// ===== External =====
    /// ====================

    function setAllocationTimes(uint256 _allocationStartTime, uint256 _allocationEndTime)
        external
        onlyPoolManager(msg.sender)
    {
        _setAllocationTimes(_allocationStartTime, _allocationEndTime);
    }

    /// ====================
    /// ===== Internal =====
    /// ====================

    function _setAllocationTimes(uint256 _allocationStartTime, uint256 _allocationEndTime) internal {
        _isPoolTimestampValid(_allocationStartTime, _allocationEndTime);

        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit TimestampsUpdated(allocationStartTime, allocationEndTime, msg.sender);
    }

    /// @notice Internal function to initialize the WrappedVotingStrategy
    /// @param _poolId The ID of the pool
    /// @param _nftFactory The address of the NFTFactory contract
    /// @param _allocationStartTime The start time of the allocation period
    /// @param _allocationEndTime The end time of the allocation period
    function __WrappedVotingStrategy_init(
        uint256 _poolId,
        address _nftFactory,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal {
        __BaseStrategy_init(_poolId);

        if (_nftFactory == address(0)) {
            revert INVALID();
        }

        nftFactory = NFTFactory(_nftFactory);

        _isPoolTimestampValid(_allocationStartTime, _allocationEndTime);

        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit TimestampsUpdated(allocationStartTime, allocationEndTime, msg.sender);
    }

    /// @notice Returns the status of the recipient based on whether it is an NFT contract created by the factory
    /// @param _recipientId The address of the recipient
    /// @return The RecipientStatus of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        return nftFactory.isNFTContract(_recipientId) ? RecipientStatus.Accepted : RecipientStatus.None;
    }

    /// @notice Internal function to register a recipient (reverts as it is not implemented)
    function _registerRecipient(bytes memory, address) internal pure override returns (address) {
        revert();
    }

    /// @notice Internal function to allocate based on the given data.
    /// @param _data The data containing NFT information
    function _allocate(bytes memory _data, address _sender) internal override {
        // decode the data to get the NFT contract
        (address nft) = abi.decode(_data, (address));
        uint256 mintPrice = NFT(nft).MINT_PRICE();
        if (msg.value == 0 || msg.value < mintPrice) {
            revert INVALID();
        }

        // divide the amount sent by the mint price to get the amount of NFTs to mint
        // NOTE: what do we do with the leftover wei?
        uint256 amount = msg.value / mintPrice;

        // mint the NFT's to the sender
        for (uint256 i = 0; i < amount;) {
            NFT(nft).mintTo{value: mintPrice}(_sender);
            unchecked {
                i++;
            }
        }

        // add the amount to the sender's allocation
        allocations[nft] += amount;

        // if the sender's allocation is greater than the current winner's allocation, set the current winner to the sender
        if (allocations[nft] > allocations[currentWinner]) {
            currentWinner = nft;
        }

        // emit the event
        emit Allocated(address(nft), amount, NATIVE, _sender);
    }

    /// @notice Internal function to distribute the tokens to the winner
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory, bytes memory, address _sender) internal override onlyAfterAllocation {
        IAllo.Pool memory pool = allo.getPool(poolId);

        if (poolAmount == 0) {
            revert INVALID();
        }

        poolAmount = 0;

        _transferAmount(pool.token, currentWinner, poolAmount);

        emit Distributed(currentWinner, currentWinner, poolAmount, _sender);
    }

    /// @notice Internal function to check if the pool timestamp is valid
    /// @param _allocationStartTime The start time of the allocation period
    /// @param _allocationEndTime The end time of the allocation period
    function _isPoolTimestampValid(uint256 _allocationStartTime, uint256 _allocationEndTime) internal view {
        if (block.timestamp > _allocationStartTime || _allocationStartTime > _allocationEndTime) {
            revert INVALID();
        }
    }

    /// @notice Internal function to check if the pool is active
    /// @return A boolean indicating whether the pool is active
    function _isPoolActive() internal view override returns (bool) {
        return allocationStartTime <= block.timestamp && block.timestamp <= allocationEndTime;
    }

    /// @notice Internal function to get the payout summary for the recipient
    /// @param _recipientId The address of the recipient
    /// @return The PayoutSummary for the recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        if (_recipientId != currentWinner) return PayoutSummary(_recipientId, 0);
        return PayoutSummary(currentWinner, poolAmount);
    }

    /// @notice Returns true for any allocator address (always returns true)
    /// @return A boolean indicating whether the allocator is valid, always true in this case
    function _isValidAllocator(address) internal pure override returns (bool) {
        return true;
    }
}
