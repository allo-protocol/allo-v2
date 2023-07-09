pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../../../contracts/interfaces/IAllocationStrategy.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {BaseAllocationStrategy} from "../../../../contracts/strategies/allocation/BaseAllocationStrategy.sol";

contract AllocationWithVotingBaseTest is Test {
    uint256 public recipentStartTime;
    uint256 public recipentEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;

    bool public identityRequired;

    event RecipentSubmitted(
        uint256 indexed recipentId, bytes32 indexed identityId, address recipient, Metadata metadata, address sender
    );
    event RecipentStatusUpdated(
        address indexed applicant, uint256 indexed recipentId, BaseAllocationStrategy.Status status
    );
    event Allocated(bytes data, address indexed allocator);
    event Claimed(uint256 indexed recipentId, address receipient, uint256 amount);
    event TimestampsUpdated(
        uint256 recipentStartTime, uint256 recipentEndTime, uint256 votingStartTime, uint256 votingEndTime
    );

    function setUp() public {
        recipentStartTime = 0;
        recipentEndTime = 0;
        votingStartTime = 0;
        votingEndTime = 0;
        identityRequired = false;
    }

    function test_initialize() public {}

    function test_registerRecipents_new_recipent() public {}

    function test_registerRecipents_update_recipent() public {}

    function testRevert_registerRecipents_APPLICATIONS_NOT_OPEN() public {}

    function testRevert_registerRecipents_new_recipent_UNAUTHORIZED() public {}

    function testRevert_registerRecipents_update_recipent_UNAUTHORIZED() public {}

    function test_getRecipentStatus() public {}

    function test_allocate_native() public {}

    function test_allocate_erc20() public {}

    function testRevert_allocate_NOT_ALLO() public {}

    function testRevert_allocate_VOTING_NOT_OPEN() public {}

    function testRevert_allocate_ALLOCATION_AMOUNT_MISMATCH() public {}

    function testRevert_allocate_TRANSFER_FAILED() public {}

    function test_getPayout() public {}

    function test_reviewRecipents() public {}

    function testRevert_reviewRecipents_UNAUTHORIZED() public {}

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
    /// @notice recipentStartTime must be before recipentEndTime
    function testRevert_updateTimestamps_ASBAE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be before votingEndTime
    function testRevert_updateTimestamps_VSBVE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice recipentStartTime must be in the future
    function testRevert_updateTimestamps_ASINFUTURE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be in the future
    function testRevert_updateTimestamps_VSINFUTURE_INVALID_TIME() public {}
}
