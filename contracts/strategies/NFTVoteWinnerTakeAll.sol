// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC721 } from "@solady/tokens/ERC721.sol";
import { ERC20 } from "@solady/tokens/ERC20.sol";
import { BaseStrategy } from "./BaseStrategy.sol";
import { Transfer } from "../core/libraries/Transfer.sol";

contract NFTVoteWinnerTakeAll is BaseStrategy {

    /// ================================
    /// ========== Storage =============
    /// ================================

    uint startTime;
    uint endTime;
    ERC721 nft;
    address currentWinner;

    address[] memory recipients;
    mapping(address => bool) public isRecipient;
    mapping(uint => bool) public isVoted;
    mapping(address => uint) public votes;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error BadVotingTimes();
    error NotWithinVotingPeriod();
    error AlreadyVoted();
    error NotOwnerOfNFT();
    error VotingHasntEnded();

    /// ===============================
    /// ========= Modifiers ===========
    /// ===============================

    modifier onlyDuringVoting() {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert NotWithinVotingPeriod();
        }
        _;
    }

    /// ===============================
    /// ========= Functions ===========
    /// ===============================

    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external override {
        super.initialize(_identityId, _poolId, _data);
        (nft, startTime, endTime) = ERC721(abi.decode(_data, (address, uint, uint)));

        if (startTime >= endTime || endTime < block.timestamp) {
            revert BadVotingTimes();
        }
    }

    function registerRecipients(bytes memory _data, address _sender) external payable onlyDuringVoting onlyAllo returns (address) {
        address[] memory newRecipients = abi.decode(_data, (address[]));

        for (uint i; i < newRecipients.length;) {
            isRecipient[newRecipients[i]] = true;
            recipients.push(newRecipients[i]);
            unchecked { ++i }
        }
    }

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus) {
        if (isRecipient[_recipientId]) {
            return RecipientStatus.Accepted;
        } else {
            return RecipientStatus.None;
        }
    }

    function isValidAllocator(address _voter) public view returns (bool) {
        return nft.balanceOf(_voter) > 0;
    }

    function allocate(bytes memory _data, address _sender) external payable onlyDuringVoting onlyAllo {
        (uint256[] memory ids, address recipient) = abi.decode(_data, (uint256[], address));
        uint numVotes = ids.length;
        for (uint i; i < numVotes;) {
            if (isVoted[ids[i]]) {
                revert AlreadyVoted();
            }
            if (nft.ownerOf(ids[i]) != _sender) {
                revert NotOwnerOfNFT();
            }
            isVoted[ids[i]] = true;
            unchecked { ++i }
        }
        votes[recipient] += numVotes;
        if (votes[recipient] > votes[currentWinner]) {
            currentWinner = recipient;
        }
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external onlyAllo {
        if (block.timestamp < endTime) {
            revert VotingHasntEnded();
        }

        Allo.Pool memory pool = allo.pools(poolId);
        // allo.decreasePoolFunding(poolId, pool.amount);
        _transferAmount(pool.token, currentWinner, pool.amount);
    }
}
