// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PropertiesParent} from './properties/PropertiesParent.t.sol';

contract FuzzTest is PropertiesParent {
  /// @custom:property-id 0
  /// @custom:property Check if 
  function property_sanityCheck() public view {

  }

  // This is a good place to include Forge test for debugging purposes
  function test_forgeDebug() public {
  }
}
