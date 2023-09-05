//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {MockERC20} from "./MockERC20.sol";

contract MockERC20Vote is MockERC20 {
    function getPastVotes(address _account, uint256) public pure returns (uint256) {
        return _account == address(123) ? 0 : 1000;
    }
}
