// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC721 } from "@solady/tokens/ERC721.sol";
import { ERC20 } from "@solady/tokens/ERC20.sol";
import { BaseStrategy } from "./BaseStrategy.sol";
import { Transfer } from "../core/libraries/Transfer.sol";

contract NFTVoteWinnerTakeAll is BaseStrategy {
    uint startTime;
    uint endTime;
    ERC721 nft;
    address winner;

    address[] memory recipients;
    mapping(address => bool) public isRecipient;
    mapping(uint => bool) public isVoted;
    mapping(address => uint) public votes;

    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external override {
        super.initialize(_identityId, _poolId, _data);
        (nft, startTime, endTime) = ERC721(abi.decode(_data, (address, uint, uint)));

        require(startTime < endTime, "start time must be before end time");
        require(endTime > block.timestamp, "end time must be in the future");
    }

    function registerRecipients(bytes memory _data, address _sender) external payable returns (address) {
        require(block.timestamp >= startTime, "voting has not started");
        require(block.timestamp <= endTime, "voting has ended");

        address[] memory newRecipients = abi.decode(_data, (address[]));

        // check to ensure gas for determining winner doesn't exceed block gas limit (just made up number for now)
        require(recipients.length + newRecipients.length < 1000, "max 1000 recipients");

        for (uint i; i < newRecipients.length; i++) {
            isRecipient[newRecipients[i]] = true;
            recipients.push(newRecipients[i]);
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

    function allocate(bytes memory _data, address _sender) external payable {
        require(block.timestamp >= startTime, "voting has not started");
        require(block.timestamp <= endTime, "voting has ended");

        (uint256[] memory ids, address recipient) = abi.decode(_data, (uint256[], address));
        uint numVotes = ids.length;
        for (uint i; i < numVotes; i++) {
            require(!isVoted[ids[i]], "already voted");
            require(nft.ownerOf(ids[i]) == msg.sender, "not owner of NFT");
            isVoted[votes[i]] = true;
        }
        votes[recipient] += numVotes;
    }

    function determineWinner() external view returns (address) {
        require(block.timestamp > endTime, "voting has not ended");
        require(winner == address(0), "winner already determined");

        uint256 maxVotes;
        address winner;
        for (uint i; i < recipients.length; i++) {
            if (votes[i] > maxVotes) {
                maxVotes = votes[i];
                winner = i;
            }
        }
        return winner;
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external {
        require(winner != address(0), "winner not determined");
        Allo.Pool memory pool = allo.pools(poolId);
        // allo.decreasePoolFunding(poolId, pool.amount);
        _transferAmount(pool.token, winner, pool.amount);
    }
}
