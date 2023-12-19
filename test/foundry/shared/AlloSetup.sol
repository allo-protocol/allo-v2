// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Core contracts
import {Allo} from "../../../contracts/core/Allo.sol";
import {Accounts} from "./Accounts.sol";

contract AlloSetup is Test, Accounts {
    Allo internal _allo_;

    function __AlloSetup(address _registry) internal {
        vm.startPrank(allo_owner());
        _allo_ = new Allo();

        _allo_.initialize(
            allo_owner(), // _owner
            _registry, // _registry
            allo_treasury(), // _treasury
            1e16, // _percentFee
            0 // _baseFee
        );
        vm.stopPrank();
    }

    function __AlloSetupLive() internal {
        _allo_ = Allo(0x1133eA7Af70876e64665ecD07C0A0476d09465a1);
    }

    function allo() public view returns (Allo) {
        return _allo_;
    }
}
