// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Core contracts
import {TokenVestingPlans} from "hedgey-vesting/VestingPlans/TokenVestingPlans.sol";
import {BatchPlanner} from "hedgey-vesting/Periphery/BatchPlanner.sol";
import {Accounts} from "../../shared/Accounts.sol";

contract HedgeySetup is Test, Accounts {
    TokenVestingPlans internal _vesting_;
    BatchPlanner internal _batchPlanner_;

    function __HedgeySetup() internal {
        vm.startPrank(allo_owner());

        _vesting_ = new TokenVestingPlans("TokenVestingPlans", "TVP");
        _batchPlanner_ = new BatchPlanner();

        vm.stopPrank();
    }

    function vesting() public view returns (TokenVestingPlans) {
        return _vesting_;
    }

    function batchPlanner() public view returns (BatchPlanner) {
        return _batchPlanner_;
    }
}
