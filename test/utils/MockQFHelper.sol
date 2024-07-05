// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "contracts/core/libraries/QFHelper.sol";

/// @title Mock QF Helper
/// @notice A mock contract for testing Quadratic Funding Library
contract MockQFHelper {
    using QFHelper for QFHelper.State;

    QFHelper.State internal state;

    function fundRecipients(address[] memory _recipients, uint256[] memory _amounts) public {
        state.fundRecipients(_recipients, _amounts);
    }

    function getDonations(address _recipient) public view returns (QFHelper.Donation[] memory) {
        return state.donations[_recipient];
    }

    function getCalcuateMatchingAmount(uint256 _matchingAmount)
        public
        view
        returns (address[] memory _recipients, uint256[] memory _payouts)
    {
        return state.calculateMatching(_matchingAmount);
    }
}
