// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721} from "@solady/tokens/ERC721.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {Allo} from "../core/Allo.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
import {Transfer} from "../core/libraries/Transfer.sol";

contract NFTVoteWinnerTakeAll is BaseStrategy {
    /// ================================
    /// ========== Storage =============
    /// ================================

    uint256 startTime;
    uint256 endTime;
    ERC721 nft;
    address currentWinner;

    address[] recipients;
    mapping(address => bool) public isRecipient;
    mapping(uint256 => bool) public isVoted;
    mapping(address => uint256) public votes;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error BadVotingTimes();
    error NotWithinVotingPeriod();
    error AlreadyVoted();
    error NotOwnerOfNFT();
    error VotingHasntEnded();

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

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

    function initialize(uint256 _poolId, bytes memory _data) public override {
        super.initialize(_poolId, _data);
        (nft, startTime, endTime) = abi.decode(_data, (ERC721, uint256, uint256));

        if (startTime >= endTime || endTime < block.timestamp) {
            revert BadVotingTimes();
        }
    }

    function registerRecipients(bytes memory _data, address _sender)
        external
        payable
        onlyDuringVoting
        onlyAllo
        returns (address)
    {
        address[] memory newRecipients = abi.decode(_data, (address[]));

        for (uint256 i; i < newRecipients.length;) {
            isRecipient[newRecipients[i]] = true;
            recipients.push(newRecipients[i]);
            unchecked {
                ++i;
            }
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
        uint256 numVotes = ids.length;
        for (uint256 i; i < numVotes;) {
            if (isVoted[ids[i]]) {
                revert AlreadyVoted();
            }
            if (nft.ownerOf(ids[i]) != _sender) {
                revert NotOwnerOfNFT();
            }
            isVoted[ids[i]] = true;
            unchecked {
                ++i;
            }
        }
        votes[recipient] += numVotes;
        if (votes[recipient] > votes[currentWinner]) {
            currentWinner = recipient;
        }
    }

    function getPayouts(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory payouts = new uint[](_recipientIds.length);
        for (uint256 i; i < _recipientIds.length;) {
            if (_recipientIds[i] == currentWinner) {
                (,,, payouts[i],,,) = allo.pools(poolId);
            } else {
                payouts[i] = 0;
            }
            unchecked {
                ++i;
            }
        }
        return payouts;
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external onlyAllo {
        if (block.timestamp < endTime) {
            revert VotingHasntEnded();
        }

        (,, address tokenToDistribute, uint256 amountToDistribute,,,) = allo.pools(poolId);
        // allo.decreasePoolFunding(poolId, pool.amount);
        _transferAmount(tokenToDistribute, currentWinner, amountToDistribute);
    }
}
