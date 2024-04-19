// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
import {Registry} from "../../../contracts/core/Registry.sol";

// Strategy Contracts
import {DirectGrantsLiteStrategy} from "../../../contracts/strategies/direct-grants-lite/DirectGrantsLite.sol";
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

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";

contract DirectGrantsLiteTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native, Errors {
    event Initialized(uint256 poolId, bytes data);

    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);
    event ProfileCreated(
        bytes32 profileId, uint256 nonce, string name, Metadata metadata, address indexed owner, address indexed anchor
    );
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status);

    error InvalidSignature();
    error SignatureExpired(uint256);
    error InvalidSigner();

    bool public useRegistryAnchor;
    bool public metadataRequired;

    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint256 public poolId;

    address public token;

    ISignatureTransfer public permit2;

    DirectGrantsLiteStrategy public strategy;
    MockERC20 public mockERC20;

    Metadata public poolMetadata;

    // Setup the tests
    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = uint64(block.timestamp + 10);
        registrationEndTime = uint64(block.timestamp + 300);

        useRegistryAnchor = true;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = DirectGrantsLiteStrategy(_deployStrategy());

        mockERC20 = new MockERC20();
        mockERC20.mint(address(this), 1_000_000 * 1e18);

        vm.prank(allo_owner());
        allo().updatePercentFee(0);

        vm.deal(pool_admin(), 10e18);
        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy{value: 1e18}(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                DirectGrantsLiteStrategy.InitializeData(
                    useRegistryAnchor, metadataRequired, registrationStartTime, registrationEndTime
                )
            ),
            NATIVE,
            1e18,
            poolMetadata,
            pool_managers()
        );
    }

    function _deployStrategy() internal virtual returns (address payable) {
        return payable(address(new DirectGrantsLiteStrategy(address(allo()), "DirectGrantsLiteStrategy")));
    }

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("DirectGrantsLiteStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
    }

    function test_initialize_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                DirectGrantsLiteStrategy.InitializeData(
                    useRegistryAnchor, metadataRequired, registrationStartTime, registrationEndTime
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
                DirectGrantsLiteStrategy.InitializeData(
                    useRegistryAnchor, metadataRequired, registrationStartTime, registrationEndTime
                )
            )
        );
    }

    function testRevert_initialize_INVALID() public {
        strategy = new DirectGrantsLiteStrategy(address(allo()), "DirectGrantsLiteStrategy");

        // when _registrationStartTime > _registrationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DirectGrantsLiteStrategy.InitializeData(
                    useRegistryAnchor, metadataRequired, registrationStartTime, uint64(block.timestamp)
                )
            )
        );
    }

    function test_initialize_registration_can_start_in_the_past() public {
        strategy = new DirectGrantsLiteStrategy(address(allo()), "DirectGrantsLiteStrategy");

        bytes memory data = abi.encode(
            DirectGrantsLiteStrategy.InitializeData(
                useRegistryAnchor, metadataRequired, uint64(block.timestamp - 1), registrationEndTime
            )
        );

        // Initialized should be emitted
        vm.expectEmit(true, true, false, false, address(strategy));
        emit Initialized(poolId, data);

        vm.prank(address(allo()));
        strategy.initialize(poolId, data);
    }

    // Tests that the correct recipient is returned
    function test_getRecipient() public {
        address recipientId = __register_recipient();
        DirectGrantsLiteStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertTrue(recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, recipientAddress());
        assertEq(recipient.metadata.protocol, 1);
        assertEq(keccak256(abi.encode(recipient.metadata.pointer)), keccak256(abi.encode("metadata")));
    }

    // Tests that the correct recipient status is returned
    function test_getRecipientStatus() public {
        address recipientId = __register_recipient();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Pending));
    }

    //  Tests that the correct recipient status is returned for an appeal
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

    // Tests that the pool manager can update the recipient status
    function test_reviewRecipients() public {
        __register_accept_recipient();
        assertEq(strategy.statusesBitMap(0), 2);
    }

    // Tests that only the pool admin can review recipients
    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.warp(registrationStartTime + 1);

        DirectGrantsLiteStrategy.ApplicationStatus[] memory statuses =
            new DirectGrantsLiteStrategy.ApplicationStatus[](1);
        statuses[0] = DirectGrantsLiteStrategy.ApplicationStatus({index: 0, statusRow: 1});
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function test_getPayouts() public {
        __register_accept_recipient();
        __register_recipient2();

        address[] memory recipientsIds = new address[](2);
        recipientsIds[0] = profile1_anchor();
        recipientsIds[1] = makeAddr("noRecipient");

        vm.expectRevert();
        strategy.getPayouts(recipientsIds, new bytes[](0));
    }

    // Tests that the strategy timestamps can be updated and updated correctly
    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            uint64(block.timestamp - 1), // can be set in the past
            registrationEndTime,
            pool_admin()
        );

        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            uint64(block.timestamp - 1), // can be set in the past
            registrationEndTime
        );

        assertEq(strategy.registrationStartTime(), uint64(block.timestamp - 1));
        assertEq(strategy.registrationEndTime(), registrationEndTime);
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(registrationStartTime, registrationEndTime);
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime,
            registrationStartTime - 1 // registration end time is before start time
        );
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
        DirectGrantsLiteStrategy _strategy = new DirectGrantsLiteStrategy(address(allo()), "DirectGrantsLiteStrategy");
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                DirectGrantsLiteStrategy.InitializeData(
                    false, metadataRequired, registrationStartTime, registrationEndTime
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
        DirectGrantsLiteStrategy _strategy = new DirectGrantsLiteStrategy(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                DirectGrantsLiteStrategy.InitializeData(
                    false, metadataRequired, registrationStartTime, registrationEndTime
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

    function test_allocate() public {
        address recipientId1 = __register_accept_recipient();
        address recipientId2 = __register_accept_recipient();

        DirectGrantsLiteStrategy.Allocation[] memory allocations = new DirectGrantsLiteStrategy.Allocation[](2);
        allocations[0] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId1, amount: 1e17});
        allocations[1] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId2, amount: 2e17});

        bytes memory encodedAllocations = abi.encode(allocations);

        vm.prank(pool_admin());
        emit Allocated(recipientId1, 1e17, NATIVE, pool_admin());
        emit Allocated(recipientId2, 2e17, NATIVE, pool_admin());

        allo().allocate{value: 3e17}(poolId, encodedAllocations);

        allocations[0] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId1, amount: 1e17});
        allocations[1] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId2, amount: 2e17});

        encodedAllocations = abi.encode(allocations);

        vm.prank(pool_admin());
        emit Allocated(recipientId1, 1e17, NATIVE, pool_admin());
        emit Allocated(recipientId2, 2e17, NATIVE, pool_admin());

        allo().allocate{value: 3e17}(poolId, encodedAllocations);
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId1 = __register_accept_recipient();
        address recipientId2 = __register_accept_recipient();

        DirectGrantsLiteStrategy.Allocation[] memory allocations = new DirectGrantsLiteStrategy.Allocation[](2);
        allocations[0] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId1, amount: 1e17});
        allocations[1] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId2, amount: 2e17});

        bytes memory encodedAllocations = abi.encode(allocations);

        vm.expectRevert(abi.encodeWithSelector(UNAUTHORIZED.selector));
        allo().allocate(poolId, encodedAllocations);
    }

    function testRevert_allocate_INVALID() public {
        DirectGrantsLiteStrategy.Allocation[] memory allocations = new DirectGrantsLiteStrategy.Allocation[](0);

        bytes memory encodedAllocations = abi.encode(allocations);

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));
        vm.prank(pool_admin());
        allo().allocate(poolId, encodedAllocations);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId2 = __register_accept_recipient();

        DirectGrantsLiteStrategy.Allocation[] memory allocations = new DirectGrantsLiteStrategy.Allocation[](2);
        allocations[0] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: address(0), amount: 1e17});
        allocations[1] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId2, amount: 2e17});

        bytes memory encodedAllocations = abi.encode(allocations);

        vm.prank(pool_admin());
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, address(0)));
        allo().allocate{value: 3e17}(poolId, encodedAllocations);
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    function __generateRecipientWithoutId() internal returns (bytes memory) {
        return __getEncodedData(recipientAddress(), 1, "metadata");
    }

    function __generateRecipientWithId(address _recipientId) internal pure returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress(), metadata);
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
        bytes memory data = abi.encode(profile2_anchor(), randomAddress(), metadata);
        recipientId = strategy.registerRecipient(data, profile2_member1());
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DirectGrantsLiteStrategy.ApplicationStatus[] memory statuses =
            new DirectGrantsLiteStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Accepted));

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function __register_reject_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DirectGrantsLiteStrategy.ApplicationStatus[] memory statuses =
            new DirectGrantsLiteStrategy.ApplicationStatus[](1);
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
        returns (DirectGrantsLiteStrategy.ApplicationStatus memory applicationStatus)
    {
        uint256 colIndex = (_recipientIndex % 64) * 4;
        uint256 currentRow = 0;

        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        applicationStatus = DirectGrantsLiteStrategy.ApplicationStatus({index: _recipientIndex, statusRow: statusRow});
    }

    function profile1_anchor() public pure override returns (address) {
        return 0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641;
    }

    function profile2_anchor() public pure override returns (address) {
        return 0x4E0aB029b2128e740fA408a26aC5f314e769469f;
    }

    function recipientAddress() public pure override returns (address) {
        return 0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849;
    }

    function randomAddress() public pure override returns (address) {
        return 0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99;
    }
}
