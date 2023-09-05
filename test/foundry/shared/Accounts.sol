// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/StdCheats.sol";

contract Accounts is StdCheats {
    // //////////////////////
    // Protocol adresses
    // //////////////////////

    function local() public pure returns (address) {
        return 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    }

    function registry_owner() public returns (address) {
        return makeAddr("registry_owner");
    }

    function allo_owner() public returns (address) {
        return makeAddr("allo_owner");
    }

    function allo_treasury() public returns (address payable) {
        return payable(makeAddr("allo_treasury"));
    }

    // //////////////////////
    // Null Profile adresses
    // //////////////////////

    function nullProfile_owner() public pure returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function nullProfile_notAMember() public pure returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function nullProfile_member1() public pure returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function nullProfile_member2() public pure returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function nullProfile_members() public pure returns (address[] memory) {
        return new address[](2);
    }

    // //////////////////////
    // Pool adresses
    // //////////////////////

    function pool_admin() public returns (address) {
        return makeAddr("pool_admin");
    }

    function pool_notAManager() public returns (address) {
        return makeAddr("pool_notAManager");
    }

    function pool_manager1() public returns (address) {
        return makeAddr("pool_manager1");
    }

    function pool_manager2() public returns (address) {
        return makeAddr("pool_manager2");
    }

    function pool_managers() public returns (address[] memory) {
        address[] memory _members = new address[](2);
        _members[0] = pool_manager1();
        _members[1] = pool_manager2();

        return _members;
    }

    // //////////////////////
    // Profile 1 adresses
    // //////////////////////

    function profile1_owner() public returns (address) {
        return makeAddr("profile1_owner");
    }

    function profile1_notAMember() public returns (address) {
        return makeAddr("profile1_notAMember");
    }

    function profile1_member1() public returns (address) {
        return makeAddr("profile1_member1");
    }

    function profile1_member2() public returns (address) {
        return makeAddr("profile1_member2");
    }

    function profile1_members() public returns (address[] memory) {
        address[] memory _members = new address[](2);
        _members[0] = profile1_member1();
        _members[1] = profile1_member2();

        return _members;
    }

    // //////////////////////
    // Profile 2 adresses
    // //////////////////////

    function profile2_owner() public returns (address) {
        return makeAddr("profile2_owner");
    }

    function profile2_notAMember() public returns (address) {
        return makeAddr("profile2_notAMember");
    }

    function profile2_member1() public returns (address) {
        return makeAddr("profile2_member1");
    }

    function profile2_member2() public returns (address) {
        return makeAddr("profile2_member2");
    }

    function profile2_members() public returns (address[] memory) {
        address[] memory _members = new address[](2);
        _members[0] = profile2_member1();
        _members[1] = profile2_member2();

        return _members;
    }

    // //////////////////////
    // Recipient adresses
    // //////////////////////

    function recipient1() public returns (address) {
        return makeAddr("recipient1");
    }

    function recipient2() public returns (address) {
        return makeAddr("recipient2");
    }

    function recipient() public returns (address) {
        return makeAddr("recipient");
    }

    function recipientAddress() public returns (address) {
        return makeAddr("recipientAddress");
    }

    function no_recipient() public returns (address) {
        return makeAddr("no_recipient");
    }

    // //////////////////////
    // Random adresses
    // //////////////////////

    function randomAddress() public returns (address) {
        return makeAddr("random chad");
    }
}
