pragma solidity 0.8.19;

import "forge-std/Test.sol";

// interfaces
import {IAllo} from "../../../contracts/core/Allo.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/donation-voting/DonationVotingStrategy.sol";

contract DonationVotingStrategyTest is Test {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    event Appealed(address indexed recipientId, bytes data, address sender);
    event RecipientStatusUpdated(
        address indexed recipientId, DonationVotingStrategy.InternalRecipientStatus recipientStatus, address sender
    );
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);
    event TimestampsUpdated(
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime,
        address sender
    );

    function setUp() public {
        // NOTE: setup
    }

    function test_deployment() public {}

    function test_initialize() public {}

    function testRevert_initialize_INVALID() public {
        // when _registrationStartTime is in past

        // when _registrationStartTime > _registrationEndTime is in past

        // when _registrationStartTime > _allocationStartTime

        // when _allocationStartTime > _allocationEndTime

        // when  _registrationEndTime > _allocationEndTime
    }

    function test_getRecipient() public {}

    function test_getInternalRecipientStatus() public {}

    function test_getRecipientStatus() public {}

    function test_getPayouts() public {}

    function test_isValidAllocator() public {}

    function test_reviewRecipients() public {}

    function testRevert_reviewRecipients_INVALID() public {}

    function testRevert_reviewRecipients_RECIPIENT_ERROR() public {}

    function testRevert_reviewRecipients_UNAUTHORIZED() public {}

    function test_setPayout() public {}

    function testRevert_setPayout() public {}

    function test_claim() public {}

    function testRevert_claim() public {}

    function test_updatePoolTimestamps() public {}

    function testRevert_updatePoolTimestamps_INVALID() public {}

    function test_withdraw() public {}

    function testRevert_withdraw_NOT_ALLOWED() public {}

    function testRevert_withdraw_UNAUTHORIZED() public {}

    function test_registerRecipient_new() public {}

    function test_registerRecipient_appeal() public {}

    function testRevert_registerRecipient_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_withoutAnchorGating_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_withAnchorGating_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {}

    function testRevert_registerRecipient_INVALID_METADATA() public {}

    function test_allocate() public {}

    function testRevert_allocate_RECIPIENT_ERROR() public {}

    function testRevert_allocate_INVALID_invalidToken() public {}

    function testRevert_allocate_INVALID_amountMismatch() public {}

    function test_distribute() public {}

    function testRevert_distribute_RECIPIENT_ERROR() public {}
}
