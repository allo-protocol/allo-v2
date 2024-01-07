// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract MockPassportDecoder {
    struct Score {
        uint256 score;
        uint32 scorerID;
        uint8 decimals;
    }

    mapping(address => uint256) public scores;

    function setScore(address userAddress, uint256 score) external {
        scores[userAddress] = score;
    }

    function getScore(address userAddress) external view returns (uint256) {
        return scores[userAddress];
    }
}
