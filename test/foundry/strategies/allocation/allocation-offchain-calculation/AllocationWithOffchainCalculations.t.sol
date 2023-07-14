pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../../../../contracts/interfaces/IAllocationStrategy.sol";
import {Metadata} from "../../../../../contracts/core/libraries/Metadata.sol";
import {BaseAllocationStrategy} from "../../../../../contracts/strategies/allocation/BaseAllocationStrategy.sol";

contract AllocationWithOffchainCalculationsTest is Test {
    uint256 public registerStartTime;
    uint256 public registerEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;

    bool public identityRequired;

    event RecipientSubmitted(
        uint256 indexed recipientId,
        bytes32 indexed identityId,
        address payoutAddress,
        Metadata metadata,
        address sender
    );
    event RecipientStatusUpdated(
        address indexed applicant, uint256 indexed recipientId, BaseAllocationStrategy.RecipientStatus status
    );
    event Allocated(bytes data, address indexed allocator);
    event Claimed(uint256 indexed recipientId, address receipient, uint256 amount);
    event TimestampsUpdated(
        uint256 registerStartTime, uint256 registerEndTime, uint256 votingStartTime, uint256 votingEndTime
    );

    function setUp() public {
        registerStartTime = 0;
        registerEndTime = 0;
        votingStartTime = 0;
        votingEndTime = 0;
        identityRequired = false;
    }

    function test_initialize() public {}

    function test_registerRecipients_new_recipient() public {}

    function test_registerRecipients_update_recipient() public {}

    function testRevert_registerRecipients_REGISTRATION_NOT_OPEN() public {}

    function testRevert_registerRecipients_new_recipient_UNAUTHORIZED() public {}

    function testRevert_registerRecipients_update_recipient_UNAUTHORIZED() public {}

    function test_getRecipientStatus() public {}

    function test_allocate_native() public {}

    function test_allocate_erc20() public {}

    function testRevert_allocate_NOT_ALLO() public {}

    function testRevert_allocate_VOTING_NOT_OPEN() public {}

    function testRevert_allocate_ALLOCATION_AMOUNT_MISMATCH() public {}

    function testRevert_allocate_TRANSFER_FAILED() public {}

    function test_getRecipientPayouts() public {}

    function test_reviewRecipients() public {}

    function testRevert_reviewRecipients_UNAUTHORIZED() public {}

    function test_setPayout() public {}

    function test_setPayout_UNAUTHORIZED() public {}

    function test_setPayout_INVALID_INPUT() public {}

    function test_setPayout_INVALID_RECIPIENT() public {}

    function test_claim() public {}

    function testRevert_claim_VOTING_NOT_ENDED() public {}

    function test_updateTimestamps() public {
        // Todo: test update timestamps
    }

    // INVALID_TIME
    /// @notice registerStartTime must be before registerEndTime
    function testRevert_updateTimestamps_ASBAE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be before votingEndTime
    function testRevert_updateTimestamps_VSBVE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice registerStartTime must be in the future
    function testRevert_updateTimestamps_ASINFUTURE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be in the future
    function testRevert_updateTimestamps_VSINFUTURE_INVALID_TIME() public {}
}
