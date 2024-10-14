// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PropertiesParent} from "./properties/PropertiesParent.t.sol";

contract FuzzTest is PropertiesParent {
    /// @custom:property-id 0
    /// @custom:property Check if
    function property_sanityCheck() public {
        assertTrue(address(allo) != address(0), "sanity check");
        assertTrue(address(registry) != address(0), "sanity check");
        assertEq(address(treasury), allo.getTreasury(), "sanity check");
        assertEq(percentFee, allo.getPercentFee(), "sanity check");
        assertEq(baseFee, allo.getBaseFee(), "sanity check");
        assertTrue(allo.isTrustedForwarder(forwarder), "sanity check");
    }

    // This is a good place to include Forge test for debugging purposes
    function test_forgeDebug() public {
        handler_createPool(1 ether);
    }
}
