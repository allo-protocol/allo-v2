// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAllo} from "../core/IAllo.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
import {ERC721} from "@solady/tokens/ERC721.sol";

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
        super.initialize(_poolId, _data);
        (nft, startTime, endTime) = abi.decode(_data, (ERC721, uint256, uint256));

        if (startTime >= endTime || endTime < block.timestamp) {
            revert BadTimes();
        }
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus) {
        if (isRecipient[_recipientId]) {
            return RecipientStatus.Accepted;
        } else {
            return RecipientStatus.None;
        }
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

    function registerRecipient(bytes memory _data, address _sender)
        external
        payable
        onlyDuringAllocationPeriod
        onlyAllo
        onlyPoolManager(_sender)
        returns (address)
    {
        address recipientId = abi.decode(_data, (address));

        isRecipient[recipientId] = true;

        emit Registered(recipientId, "", _sender);

        return recipientId;
    }

    function allocate(bytes memory _data, address _sender) external payable onlyDuringAllocationPeriod onlyAllo {
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

    function distribute(address[] memory, bytes memory, address _sender) external onlyAllo {
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

        emit Distributed(currentWinner, currentWinner, amountToDistribute, _sender);
    }
}
