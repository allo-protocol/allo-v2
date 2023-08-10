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
        allowedTokens[0] = NATIVE;

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

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("DonationVotingMerkleDistributionStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
        assertTrue(strategy.allowedTokens(NATIVE));
    }

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
        // address recipientId = __register_recipient();
        // DonationVotingMerkleDistributionStrategy.Recipient memory recipient =  strategy.getRecipient(recipientId);
        // assertFalse(recipient.useRegistryAnchor);
        // TODO: test other fields
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
        __register_recipient();
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(allocationStartTime + 1);

        DonationVotingMerkleDistributionStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionStrategy.ApplicationStatus[](1);
        statuses[0] = DonationVotingMerkleDistributionStrategy.ApplicationStatus({index: 0, statusRow: 1});
        strategy.reviewRecipients(statuses);
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

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(block.timestamp - 1, registrationEndTime, allocationStartTime, allocationEndTime);
    }

    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(allocationEndTime + 1 days);

        vm.expectRevert(DonationVotingMerkleDistributionStrategy.NOT_ALLOWED.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_NOT_ALLOWED_exceed_amount() public {
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(DonationVotingMerkleDistributionStrategy.NOT_ALLOWED.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.withdraw(1e18);
    }

    function test_claim() public {
        // warp past allocation end time
        vm.warp(allocationEndTime + 1 days);
    }

    function testRevert_claim_ALLOCATION_NOT_ENDED() public {
        // TODO
    }

    function testRevert_claim_INVALID_amountIsZero() public {
        // DonationVotingMerkleDistributionStrategy.Claim[] memory claims = __create_claims_data();

        // vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);
        // // warp past allocation end time
        // vm.warp(allocationEndTime + 1);
        // vm.prank(pool_admin());
        // strategy.claim(claims);
    }

    function test_updateDistribution() public {
        // TODO
    }

    function testRevert_updateDistribution_ALLOCATION_NOT_ENDED() public {
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.ALLOCATION_NOT_ENDED.selector);

        vm.prank(pool_admin());
        strategy.updateDistribution(abi.encode(""));
    }

    function testRevert_updateDistribution_UNAUTHORIZED() public {
        vm.warp(allocationEndTime + 1);
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.updateDistribution(abi.encode(""));
    }

    function test_isDistributionSet_True() public {
        // TODO
    }

    function test_isDistributionSet_False() public {
        assertFalse(strategy.isDistributionSet());
    }

    function test_hasBeenDistributed_True() public {
        // TODO
    }

    function test_hasBeenDistributed_False() public {
        assertFalse(strategy.hasBeenDistributed(0));
    }

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(address(0)));
        assertTrue(strategy.isValidAllocator(makeAddr("random")));
    }

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

    function testRevert_registerRecipient_UNAUTHORIZED() public {}

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
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.ALLOCATION_NOT_ACTIVE.selector);

        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(recipient1(), address(0), 1e18));
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        // TODO
    }

    function testRevert_allocate_INVALID_invalidToken() public virtual {
        address recipientId = __register_accept_recipient();

        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(recipientId, 1e18, address(123)));
    }

    function testRevert_allocate_INVALID_amountMismatch() public {
        address recipientId = __register_accept_recipient();
        vm.expectRevert(DonationVotingMerkleDistributionStrategy.INVALID.selector);

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate{value: 1e17}(poolId, abi.encode(recipientId, 1e18, NATIVE));
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

    function __generateRecipientWithoutId() internal returns (bytes memory) {
        return __getEncodedData(recipientAddress(), 1, "metadata");
    }

    function __generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress(), metadata);
    }

    function __register_recipient() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = strategy.registerRecipient(data, profile1_member1());
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionStrategy.ApplicationStatus[](1);
        statuses[0] =
            __buildStatusRow(0, uint8(DonationVotingMerkleDistributionStrategy.InternalRecipientStatus.Accepted));

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses);
    }

    function __register_reject_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionStrategy.ApplicationStatus[](1);
        statuses[0] =
            __buildStatusRow(0, uint8(DonationVotingMerkleDistributionStrategy.InternalRecipientStatus.Rejected));

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses);
    }

    function __register_accept_updateDistribution_recipient() internal returns (address) {
        address recipientId = __register_accept_recipient();
        vm.warp(registrationEndTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 9.9e17; // fund amount: 1e18 - fee: 1e17 = 9.9e17

        // fund pool
        allo().fundPool{value: 1e18}(poolId, 1e18);

        vm.warp(allocationEndTime + 10);

        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = bytes32("merkleProol");
        DonationVotingMerkleDistributionStrategy.Distribution memory distribution =
        DonationVotingMerkleDistributionStrategy.Distribution({
            index: 0,
            recipientId: profile1_anchor(),
            amount: 1e18,
            merkleProof: merkleProof
        });

        vm.prank(pool_admin());
        strategy.updateDistribution(abi.encode(distribution, metadata));

        return recipientId;
    }

    function __getEncodedData(address _recipientAddress, uint256 _protocol, string memory _pointer)
        internal
        virtual
        returns (bytes memory data)
    {
        Metadata memory metadata = Metadata({protocol: _protocol, pointer: _pointer});
        data = abi.encode(_recipientAddress, false, metadata);
    }

    function __buildStatusRow(uint256 _recipientIndex, uint256 _status)
        internal
        pure
        returns (DonationVotingMerkleDistributionStrategy.ApplicationStatus memory applicationStatus)
    {
        uint256 colIndex = (_recipientIndex % 64) * 4;
        uint256 currentRow = 0;

        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        applicationStatus =
            DonationVotingMerkleDistributionStrategy.ApplicationStatus({index: _recipientIndex, statusRow: statusRow});
    }

    // TODO: ADD OTHER MERKLE CHECKS
}
