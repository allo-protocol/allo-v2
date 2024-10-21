// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlersParent} from "../handlers/HandlersParent.t.sol";

contract PropertiesAllo is HandlersParent {
    ///@custom:property-id 1
    ///@custom:proprty one should always be able to pull/push correct (based on strategy) allocation for recipient
    function property_correctAllocation() public {}

    ///@custom:property-id 2
    ///@custom:proprty a token allocation never “disappears” (withdraw cannot impact an allocation)

    ///@custom:property-id 3
    ///@custom:proprty an address can only withdraw if has allocation

    ///@custom:property-id 4
    ///@custom:proprty profile owner can always create a pool

    ///@custom:property-id 5
    ///@custom:proprty profile owner is the only one who can always add/remove/modify profile members (name ⇒ new anchor())

    ///@custom:property-id 6
    ///@custom:proprty profile owner is the only one who can always initiate a change of profile owner (2 steps)

    ///@custom:property-id 7
    ///@custom:proprty profile member can always create a pool

    ///@custom:property-id 8
    ///@custom:proprty only profile owner or member can create a pool

    ///@custom:property-id 9
    ///@custom:proprty initial admin is always the creator of the pool

    ///@custom:property-id 10
    ///@custom:proprty pool admin can always change admin (but not to address(0))

    ///@custom:property-id 11
    ///@custom:proprty pool admin can always add/remove pool managers

    ///@custom:property-id 12
    ///@custom:proprty pool manager can always withdraw within strategy limits/logic

    ///@custom:property-id 13
    ///@custom:proprty pool manager can always change metadata

    ///@custom:property-id 14
    ///@custom:proprty allo owner can always change base fee (flat) and percent flee (./. funding amt) to any arbitrary value (max 100%)

    ///@custom:property-id 15
    ///@custom:proprty allo owner can always change the treasury address/trustred forwarded/etc

    ///@custom:property-id 16
    ///@custom:proprty allo owner can always recover funds from allo contract ( (non-)native token )

    ///@custom:property-id 17
    ///@custom:proprty only funds not allocated can be withdrawn

    ///@custom:property-id 18
    ///@custom:proprty anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee

    ///@custom:property-id 19
    ///@custom:proprty every deposit/pool creation must take the correct fee on the amount deposited, forwarded to the treasury
}
