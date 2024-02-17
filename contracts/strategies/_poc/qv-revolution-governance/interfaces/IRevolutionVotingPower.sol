// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;


/**
 * @title IRevolutionVotingPower
 * @dev This interface defines the methods for the RevolutionVotingPower contract for art piece management and voting.
 */
interface IRevolutionVotingPower {

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *  POINTS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function getPointsMinter() external view returns (address);

    function getPointsVotes(address account) external view returns (uint256);

    function getPastPointsVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getPointsSupply() external view returns (uint256);

    function getPastPointsSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *  TOKEN
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function getTokenMinter() external view returns (address);

    function getTokenVotes(address account) external view returns (uint256);

    function getPastTokenVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getTokenSupply() external view returns (uint256);

    function getPastTokenSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *  VOTES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function getVotes(address account) external view returns (uint256);

    function getVotesWithWeights(
        address account,
        uint256 erc20PointsVoteWeight,
        uint256 erc721TokenVoteWeight
    ) external view returns (uint256);

    function getTotalVotesSupply() external view returns (uint256);

    function getTotalVotesSupplyWithWeights(
        uint256 erc20PointsVoteWeight,
        uint256 erc721TokenVoteWeight
    ) external view returns (uint256);

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *  PAST VOTES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getPastVotesWithWeights(
        address account,
        uint256 blockNumber,
        uint256 erc20PointsVoteWeight,
        uint256 erc721TokenVoteWeight
    ) external view returns (uint256);

    function getPastTotalVotesSupply(uint256 blockNumber) external view returns (uint256);

    function getPastTotalVotesSupplyWithWeights(
        uint256 blockNumber,
        uint256 erc20PointsVoteWeight,
        uint256 erc721TokenVoteWeight
    ) external view returns (uint256);

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *  CALCULATE VOTES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    struct BalanceAndWeight {
        uint256 balance;
        uint256 voteWeight;
    }

    function calculateVotesWithWeights(
        BalanceAndWeight calldata points,
        BalanceAndWeight calldata token
    ) external pure returns (uint256);

    function calculateVotes(uint256 pointsBalance, uint256 tokenBalance) external view returns (uint256);
}
