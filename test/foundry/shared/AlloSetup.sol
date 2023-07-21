// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Allo} from "../../../contracts/core/Allo.sol";
import {Accounts} from "./Accounts.sol";

contract AlloSetup is Accounts {
    Allo internal _allo_;

    function __AlloSetup(address _registry) internal {
        _allo_ = new Allo();

        _allo_.initialize(
            _registry, // _registry
            allo_treasury(), // _treasury
            1e16, // _feePercentage
            0, // _baseFee
            0 // _feeSkirtingBountyPercentage
        );
    }

    function allo() public view returns (Allo) {
        return _allo_;
    }
}
