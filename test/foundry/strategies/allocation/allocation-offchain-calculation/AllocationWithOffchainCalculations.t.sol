pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../../../../contracts/interfaces/IAllocationStrategy.sol";
import {Metadata} from "../../../../../contracts/core/libraries/Metadata.sol";
import {BaseAllocationStrategy} from "../../../../../contracts/strategies/allocation/BaseAllocationStrategy.sol";

contract AllocationWithOffchainCalculationsTest is Test {
    uint256 public recipientStartTime;
    uint256 public recipientEndTime;
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
        address indexed applicant, uint256 indexed recipientId, BaseAllocationStrategy.Status status
    );
    event Allocated(bytes data, address indexed allocator);
    event Claimed(uint256 indexed recipientId, address receipient, uint256 amount);
    event TimestampsUpdated(
        uint256 recipientStartTime, uint256 recipientEndTime, uint256 votingStartTime, uint256 votingEndTime
    );

    function setUp() public {
        recipientStartTime = 0;
        recipientEndTime = 0;
        votingStartTime = 0;
        votingEndTime = 0;
        identityRequired = false;
    }

    function test_initialize() public {}

    function test_registerRecipients_new_recipient() public {}

    function test_registerRecipients_update_recipient() public {}

    function testRevert_registerRecipients_APPLICATIONS_NOT_OPEN() public {}

    function testRevert_registerRecipients_new_recipient_UNAUTHORIZED() public {}

    function testRevert_registerRecipients_update_recipient_UNAUTHORIZED() public {}

    function test_getRecipientStatus() public {}

    function test_allocate_native() public {}

    function test_allocate_erc20() public {}

    function testRevert_allocate_NOT_ALLO() public {}

    function testRevert_allocate_VOTING_NOT_OPEN() public {}

    function testRevert_allocate_ALLOCATION_AMOUNT_MISMATCH() public {}

    function testRevert_allocate_TRANSFER_FAILED() public {}

    function test_getPayout() public {}

    function test_reviewRecipients() public {}

    function testRevert_reviewRecipients_UNAUTHORIZED() public {}

    function test_setPayout() public {}

    function test_setPayout_UNAUTHORIZED() public {}

    function test_setPayout_INVALID_INPUT() public {}

    function test_setPayout_INVALID_APPLICATION() public {}

    function test_claim() public {}

    function testRevert_claim_VOTING_NOT_ENDED() public {}

    function test_updateTimestamps() public {
        // Todo: test update timestamps
    }

    // INVALID_TIME
    /// @notice recipientStartTime must be before recipientEndTime
    function testRevert_updateTimestamps_ASBAE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be before votingEndTime
    function testRevert_updateTimestamps_VSBVE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice recipientStartTime must be in the future
    function testRevert_updateTimestamps_ASINFUTURE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be in the future
    function testRevert_updateTimestamps_VSINFUTURE_INVALID_TIME() public {}
}
