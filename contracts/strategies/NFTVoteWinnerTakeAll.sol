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
    /// ========= Functions ===========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public override {
        super.initialize(_poolId, _data);
        (nft, startTime, endTime) = abi.decode(_data, (ERC721, uint256, uint256));

        if (startTime >= endTime || endTime < block.timestamp) {
            revert BadTimes();
        }
    }

    function registerRecipients(bytes memory _data, address _sender)
        external
        payable
        onlyDuringAllocationPeriod
        onlyAllo
        onlyPoolManager(_sender)
        returns (address)
    {
        address[] memory newRecipients = abi.decode(_data, (address[]));

        uint256 numRecipientsLength = newRecipients.length;
        for (uint256 i; i < numRecipientsLength;) {
            isRecipient[newRecipients[i]] = true;
            unchecked {
                ++i;
            }
        }
        return address(0);
    }

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus) {
        if (isRecipient[_recipientId]) {
            return RecipientStatus.Accepted;
        } else {
            return RecipientStatus.None;
        }
    }

    function isValidAllocator(address _allocator) public view returns (bool) {
        return nft.balanceOf(_allocator) > 0;
    }

    function allocate(bytes memory _data, address _sender) external payable onlyDuringAllocationPeriod onlyAllo {
        (uint256[] memory ids, address recipient) = abi.decode(_data, (uint256[], address));
        uint256 numVotes = ids.length;
        for (uint256 i; i < numVotes;) {
            if (hasAllocated[ids[i]]) {
                revert AlreadyAllocated();
            }
            if (nft.ownerOf(ids[i]) != _sender) {
                revert NotOwnerOfNFT();
            }
            hasAllocated[ids[i]] = true;
            unchecked {
                ++i;
            }
        }
        votes[recipient] += numVotes;
        if (votes[recipient] > votes[currentWinner]) {
            currentWinner = recipient;
        }
    }

    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 recipientLength = _recipientIds.length;
        uint256[] memory payouts = new uint[](recipientLength);

        uint256 poolAmount = allo.getPool(poolId).amount;
        for (uint256 i; i < recipientLength;) {
            if (_recipientIds[i] == currentWinner) {
                payouts[i] = poolAmount;
                poolAmount = 0; // Ensure the poolAmount is not double assigned
            } else {
                payouts[i] = 0;
            }
            unchecked {
                ++i;
            }
        }
        return payouts;
    }

    function distribute(address[] memory, bytes memory, address) external onlyAllo {
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
    }
}
