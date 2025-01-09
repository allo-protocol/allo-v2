// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
import {Registry} from "../../../contracts/core/Registry.sol";

// Strategy Contracts
import {EasyRetroFundingStrategy} from "../../../contracts/strategies/_poc/easy-rf/EasyRetroFundingStrategy.sol";
// Core libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Anchor} from "../../../contracts/core/Anchor.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
// import ERC20 mocks
import {MockERC20} from "../../utils/MockERC20.sol";

contract EasyRetroFundingStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native, Errors {
    event Initialized(uint256 poolId, bytes data);

    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);
    event DistributionUpdated(Metadata metadata);
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);
    event BatchPayoutSuccessful(address indexed sender);
    event ProfileCreated(
        bytes32 profileId, uint256 nonce, string name, Metadata metadata, address indexed owner, address indexed anchor
    );
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status);
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender, address origin);

    error InvalidSignature();
    error SignatureExpired(uint256);
    error InvalidSigner();

    bool public useRegistryAnchor;
    bool public metadataRequired;

    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public poolStartTime;
    uint64 public poolEndTime;
    uint256 public poolId;

    address public token;

    EasyRetroFundingStrategy public strategy;
    MockERC20 public mockERC20;

    Metadata public poolMetadata;

    // Setup the tests
    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = uint64(block.timestamp + 10);
        registrationEndTime = uint64(block.timestamp + 300);
        poolStartTime = uint64(block.timestamp + 301);
        poolEndTime = uint64(block.timestamp + 600);

        useRegistryAnchor = true;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = EasyRetroFundingStrategy(_deployStrategy());

        mockERC20 = new MockERC20();
        mockERC20.mint(address(this), 1_000_000 * 1e18);

        vm.prank(allo_owner());
        allo().updatePercentFee(0);

        vm.deal(pool_admin(), 1e18);
        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy{value: 1e18}(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    poolStartTime,
                    poolEndTime
                )
            ),
            NATIVE,
            1e18,
            poolMetadata,
            pool_managers()
        );
    }

    function _deployStrategy() internal virtual returns (address payable) {
        return payable(address(new EasyRetroFundingStrategy(address(allo()), "EasyRetroFundingStrategy")));
    }

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("EasyRetroFundingStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.poolStartTime(), poolStartTime);
        assertEq(strategy.poolEndTime(), poolEndTime);
    }

    function test_initialize_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    poolStartTime,
                    poolEndTime
                )
            )
        );
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    poolStartTime,
                    poolEndTime
                )
            )
        );
    }

    function testRevert_initialize_INVALID() public {
        strategy = new EasyRetroFundingStrategy(address(allo()), "EasyRetroFundingStrategy");

        // when _registrationStartTime > _registrationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    uint64(block.timestamp),
                    poolStartTime,
                    poolEndTime
                )
            )
        );

        // when _registrationStartTime > _poolStartTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    uint64(block.timestamp),
                    poolEndTime
                )
            )
        );

        // when _poolStartTime > _poolEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    poolStartTime,
                    uint64(block.timestamp)
                )
            )
        );

        // when  _registrationEndTime > _poolEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    poolStartTime,
                    registrationStartTime - 1
                )
            )
        );
    }

    function test_initialize_registration_can_start_in_the_past() public {
        strategy = new EasyRetroFundingStrategy(address(allo()), "EasyRetroFundingStrategy");

        bytes memory data = abi.encode(
            EasyRetroFundingStrategy.InitializeData(
                useRegistryAnchor,
                metadataRequired,
                uint64(block.timestamp - 1),
                registrationEndTime,
                poolStartTime,
                poolEndTime
            )
        );

        // Initialized should be emitted
        vm.expectEmit(true, true, false, false, address(strategy));
        emit Initialized(poolId, data);

        vm.prank(address(allo()));
        strategy.initialize(poolId, data);
    }

    // // Tests that the correct recipient is returned
    function test_getRecipient() public {
        address recipientId = __register_recipient();
        EasyRetroFundingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertTrue(recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, profile1_member1());
        assertEq(recipient.metadata.protocol, 1);
        assertEq(keccak256(abi.encode(recipient.metadata.pointer)), keccak256(abi.encode("metadata")));
    }

    // // Tests that the correct recipient status is returned
    function test_getRecipientStatus() public {
        address recipientId = __register_recipient();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Pending));
    }

    // //  Tests that the correct recipient status is returned for an appeal
    function test_register_getRecipientStatus_appeal() public {
        address recipientId = __register_reject_recipient();
        bytes memory data = __generateRecipientWithId(profile1_anchor());

        vm.expectEmit(false, false, false, true);
        emit UpdatedRegistration(profile1_anchor(), data, profile1_member1(), 4);

        vm.prank(address(allo()));
        __isOwnerOrMemberOfProfileTrue();
        strategy.registerRecipient(data, profile1_member1());

        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Appealed));
    }

    // // Tests that the pool manager can update the recipient status
    function test_reviewRecipients() public {
        __register_accept_recipient();
        assertEq(strategy.statusesBitMap(0), 2);
    }

    // // Tests that only the pool admin can review recipients
    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.warp(registrationStartTime + 1);

        EasyRetroFundingStrategy.ApplicationStatus[] memory statuses =
            new EasyRetroFundingStrategy.ApplicationStatus[](1);
        statuses[0] = EasyRetroFundingStrategy.ApplicationStatus({index: 0, statusRow: 1});
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function test_getPayouts() public {
        __register_accept_recipient();
        __register_recipient2();

        vm.warp(poolEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(Metadata(1, "metadata"));

        address[] memory recipientsIds = new address[](2);
        recipientsIds[0] = profile1_anchor();
        recipientsIds[1] = makeAddr("noRecipient");

        bytes[] memory data = new bytes[](2);

        data[0] =
            abi.encode(EasyRetroFundingStrategy.Distribution({index: 1, recipientId: recipientsIds[0], amount: 1e18}));
        data[1] = abi.encode(
            EasyRetroFundingStrategy.Distribution({index: 1, recipientId: makeAddr("noRecipient"), amount: 1e18})
        );

        IStrategy.PayoutSummary[] memory summary = strategy.getPayouts(recipientsIds, data);

        assertEq(summary[0].amount, 1e18);
        assertEq(summary[1].amount, 0);
    }

    // // Tests that the strategy timestamps can be updated and updated correctly
    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            uint64(block.timestamp - 1), // can be set in the past
            registrationEndTime,
            poolStartTime,
            poolEndTime + 10,
            pool_admin()
        );

        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            uint64(block.timestamp - 1), // can be set in the past
            registrationEndTime,
            poolStartTime,
            poolEndTime + 10
        );

        assertEq(strategy.registrationStartTime(), uint64(block.timestamp - 1));
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.poolStartTime(), poolStartTime);
        assertEq(strategy.poolEndTime(), poolEndTime + 10);
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(registrationStartTime, registrationEndTime, poolStartTime, poolEndTime + 10);
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime,
            registrationStartTime - 1, // registration end time is before start time
            poolStartTime,
            poolEndTime
        );

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime,
            registrationEndTime,
            registrationStartTime - 1, // allocation start tie is before registration end time
            poolEndTime
        );

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime,
            registrationEndTime,
            poolStartTime,
            poolStartTime - 1 // allocation end time is before start time
        );
    }

    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(poolEndTime + 1 days);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.withdraw(NATIVE);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.withdraw(NATIVE);
    }

    function test_withdraw() public {
        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = pool_admin().balance;

        vm.prank(pool_admin());
        strategy.withdraw(NATIVE);

        assertEq(pool_admin().balance, balanceBefore + 1e18);
    }

    function test_updateDistribution() public {
        vm.warp(poolEndTime + 1);

        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectEmit(false, false, false, true);
        emit DistributionUpdated(metadata);

        vm.prank(pool_admin());
        strategy.updateDistribution(metadata);
    }

    function testRevert_updateDistribution_INVALID() public {
        test_distribute();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updateDistribution(metadata);
    }

    function testRevert_updateDistribution_UNAUTHORIZED() public {
        vm.warp(poolEndTime + 1);
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.updateDistribution(Metadata({protocol: 1, pointer: "metadata"}));
    }

    function test_isDistributionSet_True() public {
        vm.warp(poolEndTime + 1);

        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.prank(pool_admin());
        strategy.updateDistribution(metadata);

        assertTrue(strategy.isDistributionSet());
    }

    function test_isDistributionSet_False() public {
        assertFalse(strategy.isDistributionSet());
    }

    // function test_hasBeenDistributed_True() public {
    //     test_distribute();
    //     assertTrue(strategy.hasBeenDistributed(0));
    // }

    function test_hasBeenDistributed_False() public {
        assertFalse(strategy.hasBeenDistributed(0));
    }

    function test_isValidAllocator() public {
        assertFalse(strategy.isValidAllocator(address(0)));
        assertFalse(strategy.isValidAllocator(makeAddr("random")));
    }

    function test_isPoolActive() public {
        assertFalse(strategy.isPoolActive());
        vm.warp(registrationStartTime + 1);
        assertTrue(strategy.isPoolActive());
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        EasyRetroFundingStrategy _strategy = new EasyRetroFundingStrategy(address(allo()), "EasyRetroFundingStrategy");
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    false, metadataRequired, registrationStartTime, registrationEndTime, poolStartTime, poolEndTime
                )
            )
        );

        vm.warp(registrationStartTime + 1);

        bytes memory data = abi.encode(recipientAddress(), profile1_anchor(), Metadata(1, "metadata"));

        vm.expectEmit(false, false, false, true);
        emit Registered(profile1_anchor(), abi.encode(data, 1), address(profile1_member1()));
        __isOwnerOrMemberOfProfileTrue();

        vm.prank(address(allo()));
        address recipientId = _strategy.registerRecipient(data, profile1_member1());

        IStrategy.Status status = _strategy.getRecipientStatus(recipientId);

        assertEq(uint8(IStrategy.Status.Pending), uint8(status));
    }

    function testRevert_registerRecipient_new_withRegistryAnchor_UNAUTHORIZED() public {
        EasyRetroFundingStrategy _strategy = new EasyRetroFundingStrategy(address(allo()), "EasyRetroFundingStrategy");
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                EasyRetroFundingStrategy.InitializeData(
                    false, metadataRequired, registrationStartTime, registrationEndTime, poolStartTime, poolEndTime
                )
            )
        );

        vm.warp(registrationStartTime + 1);

        bytes memory data = abi.encode(recipientAddress(), profile1_anchor(), Metadata(1, "metadata"));

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(address(allo()));
        _strategy.registerRecipient(data, profile2_member1());
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        strategy.registerRecipient(data, profile2_member1());
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        strategy.registerRecipient(data, profile1_member1());
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));

        vm.prank(address(allo()));

        __isOwnerOrMemberOfProfileTrue();
        bytes memory data = abi.encode(profile1_anchor(), address(0), metadata);
        strategy.registerRecipient(data, profile1_member1());
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        Metadata memory metadata = Metadata({protocol: 0, pointer: "metadata"});
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(INVALID_METADATA.selector);

        vm.prank(address(allo()));

        __isOwnerOrMemberOfProfileTrue();
        bytes memory data = abi.encode(profile1_anchor(), recipientAddress(), metadata);
        strategy.registerRecipient(data, profile1_member1());
    }

    function test_distribute() public {
        __register_accept_recipient();
        __register_recipient2();

        vm.warp(poolEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(Metadata(1, "metadata"));

        allo().fundPool{value: 3e18}(poolId, 3e18);

        vm.prank(address(allo()));
        vm.expectEmit(false, false, false, true);
        emit FundsDistributed(1e18, profile1_member1(), NATIVE, profile1_anchor());

        vm.expectEmit(false, false, false, true);
        emit FundsDistributed(2e18, profile2_member1(), NATIVE, profile2_anchor());

        vm.expectEmit(false, false, false, true);
        emit BatchPayoutSuccessful(pool_admin());

        EasyRetroFundingStrategy.Distribution[] memory distributions = new EasyRetroFundingStrategy.Distribution[](2);
        distributions[0] =
            EasyRetroFundingStrategy.Distribution({index: 0, recipientId: profile1_anchor(), amount: 1e18});
        distributions[1] =
            EasyRetroFundingStrategy.Distribution({index: 1, recipientId: profile2_anchor(), amount: 2e18});

        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR() public {
        __register_accept_recipient();
        __register_recipient2();

        EasyRetroFundingStrategy.Distribution[] memory distributions = new EasyRetroFundingStrategy.Distribution[](2);
        distributions[0] =
            EasyRetroFundingStrategy.Distribution({index: 0, recipientId: profile1_notAMember(), amount: 1e18});

        // invalid recipientId
        distributions[1] = EasyRetroFundingStrategy.Distribution({index: 1, recipientId: randomAddress(), amount: 2e18});

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_notAMember()));

        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    function testRevert_distribute_twice_to_same_recipient() public {
        EasyRetroFundingStrategy.Distribution[] memory distributions = new EasyRetroFundingStrategy.Distribution[](2);
        distributions[0] =
            EasyRetroFundingStrategy.Distribution({index: 0, recipientId: profile1_anchor(), amount: 1e18});
        distributions[1] =
            EasyRetroFundingStrategy.Distribution({index: 1, recipientId: profile1_anchor(), amount: 2e18});

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(poolEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(Metadata(1, "metadata"));

        allo().fundPool{value: 3e18}(poolId, 3e18);

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    function __generateRecipientWithoutId() internal returns (bytes memory) {
        return __getEncodedData(recipientAddress(), 1, "metadata");
    }

    function __generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, profile1_member1(), metadata);
    }

    function __isOwnerOrMemberOfProfileTrue() internal {
        vm.mockCall(
            address(registry()), abi.encodeWithSelector(Registry.isOwnerOrMemberOfProfile.selector), abi.encode(true)
        );
    }

    function __register_recipient() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        __isOwnerOrMemberOfProfileTrue();

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = strategy.registerRecipient(data, profile1_member1());
    }

    function __register_recipient2() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        __isOwnerOrMemberOfProfileTrue();

        vm.prank(address(allo()));
        bytes memory data = abi.encode(profile2_anchor(), profile2_member1(), metadata);
        recipientId = strategy.registerRecipient(data, profile2_member1());
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        EasyRetroFundingStrategy.ApplicationStatus[] memory statuses =
            new EasyRetroFundingStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Accepted));

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function __register_reject_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        EasyRetroFundingStrategy.ApplicationStatus[] memory statuses =
            new EasyRetroFundingStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Rejected));

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusUpdated(0, statuses[0].statusRow, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses, refRecipientsCounter);
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
        returns (EasyRetroFundingStrategy.ApplicationStatus memory applicationStatus)
    {
        uint256 colIndex = (_recipientIndex % 64) * 4;
        uint256 currentRow = 0;

        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        applicationStatus = EasyRetroFundingStrategy.ApplicationStatus({index: _recipientIndex, statusRow: statusRow});
    }
}
