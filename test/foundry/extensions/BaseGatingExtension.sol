// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.22;

import "forge-std/Test.sol";

// Test libraries
import {MockGatingExtension} from "../../utils/MockGatingExtension.sol";

abstract contract BaseGatingExtension is Test {
    MockGatingExtension public gatingExtension;
    address public allo = makeAddr("allo");
    address public eas = makeAddr("eas");
    uint256 public poolId = 1;

    /// actors
    address public actor = makeAddr("actor");
    /// token
    address public token = makeAddr("token");
    address public nft = makeAddr("nft");

    function setUp() public virtual {
        gatingExtension = new MockGatingExtension(allo);

        /// initialize
        vm.prank(allo);
        gatingExtension.initialize(poolId, abi.encode(eas));
    }
}
