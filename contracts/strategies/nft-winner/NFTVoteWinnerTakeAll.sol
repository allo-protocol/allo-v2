// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// External Libraries
import {ERC721} from "@solady/tokens/ERC721.sol";
// Interfaces
import {IAllo} from "../../core/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";

contract NFTVoteWinnerTakeAll is BaseStrategy {
    /// ================================
    /// ========== Storage =============
    /// ================================

    uint256 startTime;
    uint256 endTime;
    ERC721 nft;
    address currentWinner;

    mapping(address => bool) public isRecipient;
    mapping(uint256 => bool) public hasAllocated;
    mapping(address => uint256) public votes;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error BadTimes();
    error NotWithinAllocationPeriod();
    error AlreadyAllocated();
    error NotOwnerOfNFT();
    error AllocationHasntEnded();
    error ZERO_AMOUNT();

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Modifiers ===========
    /// ===============================

    modifier onlyDuringAllocationPeriod() {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert NotWithinAllocationPeriod();
        }
        _;
    }

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public override {
        (ERC721 _nft, uint256 _startTime, uint256 _endTime) = abi.decode(_data, (ERC721, uint256, uint256));
        __NFTVoteWinnerStrategy_init(_poolId, _nft, _startTime, _endTime);
    }

    function __NFTVoteWinnerStrategy_init(uint256 _poolId, ERC721 _nft, uint256 _startTime, uint256 _endTime)
        internal
    {
        if (_startTime >= _endTime || _endTime < block.timestamp) {
            revert BadTimes();
        }
        __BaseStrategy_init(_poolId);
        nft = _nft;
        startTime = _startTime;
        endTime = _endTime;
        _setPoolActive(true);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus) {
        if (isRecipient[_recipientId]) {
            return RecipientStatus.Accepted;
        }
        return RecipientStatus.None;
    }

    function getPayouts(address[] memory, bytes memory, address) external view returns (PayoutSummary[] memory) {
        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        payouts[0] = PayoutSummary(currentWinner, allo.getPool(poolId).amount);
        return payouts;
    }

    function isValidAllocator(address _allocator) public view returns (bool) {
        return nft.balanceOf(_allocator) > 0;
    }

    /// ===============================
    /// ========= Functions ===========
    /// ===============================

    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyDuringAllocationPeriod
        returns (address)
    {
        address recipientId = abi.decode(_data, (address));

        isRecipient[recipientId] = true;

        emit Registered(recipientId, "", _sender);

        return recipientId;
    }

    function _allocate(bytes memory _data, address _sender) internal override onlyDuringAllocationPeriod {
        (uint256[] memory nftIds, address recipientId) = abi.decode(_data, (uint256[], address));
        uint256 numVotes = nftIds.length;
        for (uint256 i; i < numVotes;) {
            uint256 nftId = nftIds[i];

            if (nft.ownerOf(nftId) != _sender) {
                revert NotOwnerOfNFT();
            }

            if (hasAllocated[nftId]) {
                revert AlreadyAllocated();
            }

            hasAllocated[nftId] = true;

            unchecked {
                ++i;
            }
        }

        votes[recipientId] += numVotes;
        if (votes[recipientId] > votes[currentWinner]) {
            currentWinner = recipientId;
        }

        emit Allocated(recipientId, numVotes, address(0), _sender);
    }

    function _distribute(address[] memory, bytes memory, address _sender) internal override {
        if (block.timestamp < endTime) {
            revert AllocationHasntEnded();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        uint256 amountToDistribute = pool.amount;

        if (amountToDistribute == 0) {
            revert ZERO_AMOUNT();
        }

        allo.decreasePoolTotalFunding(poolId, amountToDistribute);
        _transferAmount(pool.token, currentWinner, amountToDistribute);

        _setPoolActive(false);

        emit Distributed(currentWinner, currentWinner, amountToDistribute, _sender);
    }
}
