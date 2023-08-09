// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Test contracts
import "forge-std/Test.sol";
import {CREATE3} from "solady/src/utils/CREATE3.sol";

// Interfaces
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
import {IRegistry} from "../../../contracts/core/IRegistry.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
// Strategy Contracts
import {DonationVotingMerkleDistributionStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution/DonationVotingMerkleDistributionStrategy.sol";
// Core libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Anchor} from "../../../contracts/core/Anchor.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract DonationVotingMerkleDistributionStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native {
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);
    event BatchPayoutSuccessful(address indexed sender);
    event ProfileCreated(
        bytes32 profileId, uint256 nonce, string name, Metadata metadata, address indexed owner, address indexed anchor
    );

    bool public useRegistryAnchor;
    bool public metadataRequired;

    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;
    uint256 public poolId;

    address[] public allowedTokens;
    address public token;

    DonationVotingMerkleDistributionStrategy public strategy;
    Metadata public poolMetadata;

    // Setup the tests
    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = block.timestamp + 10;
        registrationEndTime = block.timestamp + 300;
        allocationStartTime = block.timestamp + 301;
        allocationEndTime = block.timestamp + 600;

        useRegistryAnchor = true;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy =
            new DonationVotingMerkleDistributionStrategy(address(allo()), "DonationVotingMerkleDistributionStrategy");

        allowedTokens = new address[](1);
        allowedTokens[0] = address(0);

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    // Tests the deployment of the strategy
    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("DonationVotingMerkleDistributionStrategy")));
    }

    // Tests that the strategy is initialized correctly
    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
        assertTrue(strategy.allowedTokens(address(0)));
    }

    // Tests that the strategy can be initialized with no allowed tokens, otherwise reverts
    function testRevert_initialize_withNoAllowedToken() public {
        strategy =
            new DonationVotingMerkleDistributionStrategy(address(allo()), "DonationVotingMerkleDistributionStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                new address[](0)
            )
        );
        assertTrue(strategy.allowedTokens(address(0)));
    }

    // Tests that the strategy reverts when non-allowed tokens are used
    function testRevert_initialize_withNotAllowedToken() public {
        DonationVotingMerkleDistributionStrategy testSrategy =
            new DonationVotingMerkleDistributionStrategy(address(allo()), "DonationVotingMerkleDistributionStrategy");
        address[] memory tokensAllowed = new address[](1);
        tokensAllowed[0] = makeAddr("token");
        vm.prank(address(allo()));
        testSrategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                tokensAllowed
            )
        );
        assertFalse(testSrategy.allowedTokens(makeAddr("not-allowed-token")));
    }

    // Tests that only the pool admin can initialize the strategy
    function test_initialize_BaseStrategy_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );
    }

    // Tests that the strategy can only be initialized once
    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );
    }

    // Tests when initializing the strategy with invalid timestamps for 5 scenarios
    function testRevert_initialize_INVALID() public {
        strategy =
            new DonationVotingMerkleDistributionStrategy(address(allo()), "DonationVotingMerkleDistributionStrategy");
        // when _registrationStartTime is in past
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                block.timestamp - 1,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        // when _registrationStartTime > _registrationEndTime
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                block.timestamp,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        // when _registrationStartTime > _allocationStartTime
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                block.timestamp,
                allocationEndTime,
                allowedTokens
            )
        );

        // when _allocationStartTime > _allocationEndTime
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                block.timestamp,
                allowedTokens
            )
        );

        // when  _registrationEndTime > _allocationEndTime
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                registrationStartTime - 1,
                allowedTokens
            )
        );
    }

    // Tests that the correct recipient is returned
    function test_getRecipient() public {
        // __register_recipient();
        // strategy.getRecipient(recipient1());
    }

    // Tests that the correct internal recipient status is returned
    function test_getInternalRecipientStatus() public {
        // TODO
    }

    // Tests that the correct recipient status is returned
    function test_getRecipientStatus() public {
        // TODO
    }

    //  Tests that the correct recipient status is returned for an appeal
    function test_getRecipientStatus_appeal() public {
        // TODO
    }

    // Tests that the pool manager can update the recipient status
    function test_reviewRecients() public {
        // TODO
    }

    // Tests that you can only review recipients when registration is active
    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        // TODO
    }

    // Tests that only the pool admin can review recipients
    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        // TODO
    }

    // Tests that the strategy timestamps can be updated and updated correctly
    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10, pool_admin()
        );

        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );

        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime + 10);
    }

    // Tests that only the pool admin can update the timestamps
    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    // Tests that the timestamps are valid otherwise reverts
    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(block.timestamp - 1, registrationEndTime, allocationStartTime, allocationEndTime);
    }

    // Tests for when the allocation has not ended, should revert
    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(allocationEndTime + 1 days);

        vm.expectRevert(DonationVotingMerkleDistributionStrategy.NOT_ALLOWED.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    // Tests for when the withdraw amount is greater than the balance of the pool
    function testRevert_withdraw_NOT_ALLOWED_exceed_amount() public {
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    // Tests that only the pool manager can withdraw funds
    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.withdraw(1e18);
    }

    // Tests the claim function
    function test_claim() public {
        // warp past allocation end time
        vm.warp(allocationEndTime + 1 days);
    }

    function testRevert_claim_ALLOCATION_NOT_ENDED() public {
        // TODO
    }

    function testRevert_claim() public {
        // TODO
    }

    function test_updateDistribution() public {
        // TODO
    }

    function testRevert_updateDistribution_ALLOCATION_NOT_ENDED() public {
        // TODO
    }

    function testRevert_updateDistribution_UNAUTHORIZED() public {
        // TODO
    }

    function test_isDistributionSet() public {
        // TODO
    }

    function test_hasBeenDistributed() public {
        // TODO
    }

    // Tests that an address is a valid allocator
    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(address(0)));
        assertTrue(strategy.isValidAllocator(makeAddr("random")));
    }

    // Tests if the pool is active after the registration time begins
    function test_isPoolActive() public {
        assertFalse(strategy.isPoolActive());
        vm.warp(registrationStartTime + 1);
        assertTrue(strategy.isPoolActive());
    }

    function test_registerRecipient_new() public {
        // __create_profile_register_recipient();
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        // TODO
    }

    function test_registerRecipient_appeal() public {
        // TODO
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        // TODO
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        // TODO
    }

    function testRevert_registerRecipient_isUsingRegistryAnchor_UNAUTHORIZED() public {
        // TODO
    }

    function testRevert_registerRecipient_withAnchorGating_UNAUTHORIZED() public {
        // TODO
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        // TODO
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        // TODO
    }

    function test_allocate() public {
        // TODO
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        // TODO
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        // TODO
    }

    function testRevert_allocate_INVALID_invalidToken() public virtual {
        // TODO
    }

    function testRevert_allocate_INVALID_amountMismatch() public {
        // TODO
    }

    function test_distribute() public {
        // TODO
    }

    function testRevert_distribute_twice_to_same_recipient() public {
        // TODO
    }

    function testRevert_distribute_RECIPIENT_ERROR() public {
        // TODO
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    // Helper function to register a recipient
    // function __register_recipient() internal {
    //     Metadata memory metadata = __get_metadata(1, "Profile2");
    //     IRegistry.Profile memory profile = allo().getRegistry().getProfileById(0xce6ccaa269c65528ca658852ba7db8f27381e06b52e4b77db17c9a1475b22bc4);
    //     bytes memory data = abi.encode(recipient1(), 0xE4C662c4b8018EEA89294209Cd34Efb150EF4297, metadata);

    //     // warp to registration start time
    //     vm.warp(registrationStartTime + 1);
    //     vm.prank(pool_admin());
    //     allo().registerRecipient(poolId, data);
    // }

    // Helper function to create a profile
    // function __create_profile() internal returns (bytes32 profileId) {
    //     Metadata memory metadata = __get_metadata(1, "ProfileMetadata");
    //     address[] memory poolMembers = new address[](2);
    //     poolMembers[0] = pool_manager1();
    //     poolMembers[1] = recipient1();

    //     // NOTE: how to know the anchor it will emit without creating profile?
    //     // How to get the profile id without creating profile yet?
    //     // 0xd35eb5538c1856e9010643a255dde8e41acf0a3349042b857f6f1a4cd5b05097
    //     address anchor = __generateAnchor(0xd35eb5538c1856e9010643a255dde8e41acf0a3349042b857f6f1a4cd5b05097, "Chad");
    //     vm.expectEmit(true, false, false, true);
    //     emit ProfileCreated(profileId, 1, "Chad", metadata, pool_manager1(), anchor);

    //     profileId = allo().getRegistry().createProfile(1, "Chad", metadata, pool_manager1(), poolMembers);
    //     emit log_bytes32(profileId);
    // }

    function __generateAnchor(bytes32 _profileId, string memory _name) internal returns (address anchor) {
        bytes32 salt = keccak256(abi.encodePacked(_profileId, _name));

        bytes memory creationCode = abi.encodePacked(type(Anchor).creationCode, abi.encode(_profileId));

        anchor = CREATE3.deploy(salt, creationCode, 0);
    }

    function __get_metadata(uint256 _protocol, string memory _pointer)
        internal
        pure
        returns (Metadata memory metadata)
    {
        metadata = Metadata({protocol: _protocol, pointer: _pointer});
    }

    // TODO: ADD OTHER MERKLE CHECKS
}
