pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../../../contracts/interfaces/IAllocationStrategy.sol";

contract AllocationWithVotingBaseTest is Test {
    uint256 public applicationStartTime;
    uint256 public applicationEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;

    bool public identityRequired;

    function setUp() public {
        applicationStartTime = 0;
        applicationEndTime = 0;
        votingStartTime = 0;
        votingEndTime = 0;
        identityRequired = false;
    }

    function test_ContractInitialized() public {
        // Todo: test that the contract is initialized correctly
    }

    function test_applyToPool() public {
        // Todo: test applying to the pool
    }

    function test_getApplicationStatus() public {
        // Todo:
    }

    function test_allocate_SinglePayout() public {
        // Todo: test voting on the application
    }

    function test_allocate_MultiPayout() public {
        // Todo: test voting on the application
    }

    function testRevert_allocate_NOT_ALLO() public {
        // Todo: test revert if not allo
    }

    function testRevert_allocate_VOTING_NOT_OPEN() public {
        // Todo: test revert if voting not open
    }

    function testRevert_allocate_TRANSFER_FAILED() public {
        // Todo: test revert if tranfer fails
    }

    function test_ReviewApplications() public {
        // Todo: test review applications
    }

    function testRevert_ReviewApplications_NOT_ADMIN() public {
        // Todo: test revert if not admin
    }

    function test_updateTimestamps() public {
        // Todo: test update timestamps
    }

    // INVALID_TIME
    /// @notice applicationStartTime must be before applicationEndTime
    function testRevert_updateTimestamps_ASBAE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be before votingEndTime
    function testRevert_updateTimestamps_VSBVE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice applicationStartTime must be in the future
    function testRevert_updateTimestamps_ASINFUTURE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }

    /// @notice votingStartTime must be in the future
    function testRevert_updateTimestamps_VSINFUTURE_INVALID_TIME() public {
        // Todo: test revert if invalid time
    }
}
