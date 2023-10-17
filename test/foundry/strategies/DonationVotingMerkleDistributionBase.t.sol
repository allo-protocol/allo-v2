// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy Contracts
import {DonationVotingMerkleDistributionBaseMock} from "../../utils/DonationVotingMerkleDistributionBaseMock.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";
// Core libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Anchor} from "../../../contracts/core/Anchor.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
// import MockERC20
import {MockERC20} from "../../utils/MockERC20.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";
import {Permit2} from "../../utils/Permit2Mock.sol";

contract DonationVotingMerkleDistributionBaseMockTest is
    PermitSignature,
    Test,
    AlloSetup,
    RegistrySetupFull,
    EventSetup,
    Native,
    Errors
{
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);
    event BatchPayoutSuccessful(address indexed sender);
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
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;
    uint256 public poolId;

    address[] public allowedTokens;
    address public token;

    ISignatureTransfer public permit2;

    DonationVotingMerkleDistributionBaseMock public strategy;
    MockERC20 public mockERC20;
    Metadata public poolMetadata;

    // Setup the tests
    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        permit2 = ISignatureTransfer(address(new Permit2()));

        registrationStartTime = uint64(block.timestamp + 10);
        registrationEndTime = uint64(block.timestamp + 300);
        allocationStartTime = uint64(block.timestamp + 301);
        allocationEndTime = uint64(block.timestamp + 600);

        useRegistryAnchor = true;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = DonationVotingMerkleDistributionBaseMock(_deployStrategy());
        mockERC20 = new MockERC20();

        mockERC20.mint(address(this), 1_000_000 * 1e18);

        allowedTokens = new address[](2);
        allowedTokens[0] = NATIVE;
        allowedTokens[1] = address(mockERC20);

        vm.prank(allo_owner());
        allo().updatePercentFee(0);

        vm.deal(pool_admin(), 1e18);
        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy{value: 1e18}(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            ),
            NATIVE,
            1e18,
            poolMetadata,
            pool_managers()
        );
    }

    function _deployStrategy() internal virtual returns (address payable) {
        return payable(
            address(
                new DonationVotingMerkleDistributionBaseMock(
                address(allo()),
                "DonationVotingMerkleDistributionBaseMock", 
                permit2
                )
            )
        );
    }

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("DonationVotingMerkleDistributionBaseMock")));
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
        new DonationVotingMerkleDistributionBaseMock(address(allo()), "DonationVotingMerkleDistributionBaseMock", permit2);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    new address[](0)
                )
            )
        );
        assertTrue(strategy.allowedTokens(address(0)));
    }

    function testRevert_initialize_withNotAllowedToken() public {
        DonationVotingMerkleDistributionBaseMock testSrategy =
        new DonationVotingMerkleDistributionBaseMock(address(allo()), "DonationVotingMerkleDistributionBaseMock", permit2);
        address[] memory tokensAllowed = new address[](1);
        tokensAllowed[0] = makeAddr("token");
        vm.prank(address(allo()));
        testSrategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    tokensAllowed
                )
            )
        );
        assertFalse(testSrategy.allowedTokens(makeAddr("not-allowed-token")));
    }

    function test_initialize_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
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
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            )
        );
    }

    function testRevert_initialize_INVALID() public {
        strategy =
        new DonationVotingMerkleDistributionBaseMock(address(allo()), "DonationVotingMerkleDistributionBaseMock", permit2);
        // when _registrationStartTime is in past
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    uint64(block.timestamp - 1),
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            )
        );

        // when _registrationStartTime > _registrationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    uint64(block.timestamp),
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            )
        );

        // when _registrationStartTime > _allocationStartTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    uint64(block.timestamp),
                    allocationEndTime,
                    allowedTokens
                )
            )
        );

        // when _allocationStartTime > _allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    uint64(block.timestamp),
                    allowedTokens
                )
            )
        );

        // when  _registrationEndTime > _allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    registrationStartTime - 1,
                    allowedTokens
                )
            )
        );
    }

    // Tests that the correct recipient is returned
    function test_getRecipient() public {
        address recipientId = __register_recipient();
        DonationVotingMerkleDistributionBaseStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
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
        strategy.registerRecipient(data, profile1_member1());

        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Appealed));
    }

    // Tests that the pool manager can update the recipient status
    function test_reviewRecipients() public {
        __register_accept_recipient();
        assertEq(strategy.statusesBitMap(0), 2);
    }

    // Tests that you can only review recipients when registration is active
    function testRevert_reviewRecipients_ALLOCATION_NOT_ACTIVE() public {
        __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        vm.warp(allocationEndTime + 1);

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 1});
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    // Tests that only the pool admin can review recipients
    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.warp(registrationStartTime + 1);

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 1});
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function test_getPayouts() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));

        address[] memory recipientsIds = new address[](2);
        recipientsIds[0] = profile1_anchor();
        recipientsIds[1] = makeAddr("noRecipient");

        bytes[] memory data = new bytes[](2);

        data[0] = abi.encode(distributions[0]);
        data[1] = abi.encode(
            DonationVotingMerkleDistributionBaseStrategy.Distribution({
                index: 1,
                recipientId: makeAddr("noRecipient"),
                amount: 1e18,
                merkleProof: new bytes32[](0)
            })
        );

        IStrategy.PayoutSummary[] memory summary = strategy.getPayouts(recipientsIds, data);

        assertEq(summary[0].amount, 1e18);
        assertEq(summary[1].amount, 0);
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
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            uint64(block.timestamp - 1), registrationEndTime, allocationStartTime, allocationEndTime
        );
    }

    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(allocationEndTime + 1 days);

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
        vm.warp(allocationEndTime + 1);

        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectEmit(false, false, false, true);
        emit DistributionUpdated(merkleRoot, metadata);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, metadata);
    }

    function testRevert_updateDistribution_INVALID() public {
        test_distribute();
        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, metadata);
    }

    function testRevert_updateDistribution_ALLOCATION_NOT_ENDED() public {
        vm.expectRevert(ALLOCATION_NOT_ENDED.selector);

        vm.prank(pool_admin());
        strategy.updateDistribution("", Metadata({protocol: 1, pointer: "metadata"}));
    }

    function testRevert_updateDistribution_UNAUTHORIZED() public {
        vm.warp(allocationEndTime + 1);
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.updateDistribution("", Metadata({protocol: 1, pointer: "metadata"}));
    }

    function test_isDistributionSet_True() public {
        vm.warp(allocationEndTime + 1);

        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, metadata);

        assertTrue(strategy.isDistributionSet());
    }

    function test_isDistributionSet_False() public {
        assertFalse(strategy.isDistributionSet());
    }

    function test_hasBeenDistributed_True() public {
        test_distribute();
        assertTrue(strategy.hasBeenDistributed(0));
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

    function test_registerRecipient_new_withRegistryAnchor() public {
        DonationVotingMerkleDistributionBaseMock _strategy =
            new DonationVotingMerkleDistributionBaseMock(address(allo()), "DonationVotingStrategy", permit2);
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    false,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            )
        );

        vm.warp(registrationStartTime + 1);

        bytes memory data = abi.encode(recipientAddress(), profile1_anchor(), Metadata(1, "metadata"));

        vm.expectEmit(false, false, false, true);
        emit Registered(profile1_anchor(), abi.encode(data, 1), address(profile1_member1()));

        vm.prank(address(allo()));
        address recipientId = _strategy.registerRecipient(data, profile1_member1());

        IStrategy.Status status = _strategy.getRecipientStatus(recipientId);

        assertEq(uint8(IStrategy.Status.Pending), uint8(status));
    }

    function testRevert_registerRecipient_new_withRegistryAnchor_UNAUTHORIZED() public {
        DonationVotingMerkleDistributionBaseMock _strategy =
            new DonationVotingMerkleDistributionBaseMock(address(allo()), "DonationVotingStrategy", permit2);
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    false,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
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

        bytes memory data = abi.encode(profile1_anchor(), address(0), metadata);
        strategy.registerRecipient(data, profile1_member1());
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        Metadata memory metadata = Metadata({protocol: 0, pointer: "metadata"});
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(INVALID_METADATA.selector);

        vm.prank(address(allo()));

        bytes memory data = abi.encode(profile1_anchor(), recipientAddress(), metadata);
        strategy.registerRecipient(data, profile1_member1());
    }

    function test_allocate() public virtual {
        __register_accept_recipient_allocate();
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);

        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(recipient1(), address(0), 1e18));
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, randomAddress()));

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
        DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
            permit: ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: NATIVE, amount: 1e18}),
                nonce: 0,
                deadline: allocationStartTime + 10000
            }),
            signature: ""
        });

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(randomAddress(), permit2Data));
    }

    function testRevert_allocate_INVALID_invalidToken() public virtual {
        address recipientId = __register_accept_recipient();

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
        DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
            permit: ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(123), amount: 1e18}),
                nonce: 0,
                deadline: allocationStartTime + 10000
            }),
            signature: ""
        });

        vm.expectRevert(INVALID.selector);

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(recipientId, permit2Data));
    }

    function testRevert_allocate_INVALID_amountMismatch() public {
        address recipientId = __register_accept_recipient();
        vm.expectRevert(INVALID.selector);

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
        DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
            permit: ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: NATIVE, amount: 1e18}),
                nonce: 0,
                deadline: allocationStartTime + 10000
            }),
            signature: ""
        });

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate{value: 1e17}(poolId, abi.encode(recipientId, permit2Data));
    }

    function test_distribute() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));

        allo().fundPool{value: 3e18}(poolId, 3e18);

        vm.prank(address(allo()));
        vm.expectEmit(false, false, false, true);
        emit FundsDistributed(
            1e18, 0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849, NATIVE, 0x236BB9Cf3dC40Df67173aF2F65b4b0d904B4eDe0
        );

        vm.expectEmit(false, false, false, true);
        emit FundsDistributed(
            2e18, 0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99, NATIVE, 0x6b0c8b268742D274f67f4235e22E10470F872f33
        );

        vm.expectEmit(false, false, false, true);
        emit BatchPayoutSuccessful(pool_admin());

        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    function testRevert_distribute_INVALID_shit() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        merkleRoot;
        vm.prank(address(allo()));
        vm.expectRevert(INVALID.selector);

        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    function testRevert_distribute_twice_to_same_recipient() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));

        allo().fundPool{value: 3e18}(poolId, 3e18);

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    function testRevert_distribute_wrongProof() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));

        allo().fundPool{value: 3e18}(poolId, 3e18);

        distributions[0].merkleProof[0] = bytes32(0);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        __register_accept_recipient();

        vm.warp(allocationEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));

        allo().fundPool{value: 3e18}(poolId, 3e18);

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));
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

        return abi.encode(_recipientId, recipientAddress(), metadata);
    }

    function __register_recipient() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = strategy.registerRecipient(data, profile1_member1());
    }

    function __register_recipient2() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.prank(address(allo()));
        bytes memory data = abi.encode(profile2_anchor(), randomAddress(), metadata);
        recipientId = strategy.registerRecipient(data, profile2_member1());
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Accepted));

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function __register_reject_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Rejected));

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusUpdated(0, statuses[0].statusRow, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function __register_accept_recipient_allocate() internal returns (address) {
        address recipientId = __register_accept_recipient();

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
        DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
            permit: ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: NATIVE, amount: 1e18}),
                nonce: 0,
                deadline: allocationStartTime + 10000
            }),
            signature: ""
        });

        vm.warp(allocationStartTime + 1);
        vm.deal(randomAddress(), 1e18);
        vm.prank(randomAddress());

        vm.expectEmit(false, false, false, true);
        emit Allocated(recipientId, 1e18, NATIVE, randomAddress());

        allo().allocate{value: 1e18}(poolId, abi.encode(recipientId, permit2Data));

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
        returns (DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus memory applicationStatus)
    {
        uint256 colIndex = (_recipientIndex % 64) * 4;
        uint256 currentRow = 0;

        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        applicationStatus = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({
            index: _recipientIndex,
            statusRow: statusRow
        });
    }

    function __getMerkleRootAndDistributions()
        internal
        view
        returns (bytes32, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory)
    {
        DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions =
            new DonationVotingMerkleDistributionBaseStrategy.Distribution[](2);

        DonationVotingMerkleDistributionBaseStrategy.Distribution memory distribution0 =
        DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 0,
            recipientId: 0x236BB9Cf3dC40Df67173aF2F65b4b0d904B4eDe0, // profile1_anchor
            // recipientAddress: '0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849',
            amount: 1e18,
            merkleProof: new bytes32[](1)
        });
        distribution0.merkleProof[0] = 0x372ce6c86f99c51f7943af06c5cf86320ac63f9a71483cdecd8170e70332ffa7;

        DonationVotingMerkleDistributionBaseStrategy.Distribution memory distribution1 =
        DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 1,
            recipientId: 0x6b0c8b268742D274f67f4235e22E10470F872f33, // profile2_anchor
            // recipientAddress: '0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99',
            amount: 2e18,
            merkleProof: new bytes32[](1)
        });
        distribution1.merkleProof[0] = 0xd67f0c989dd83f78f1ce0dc68f2119e2a044681a7c5d5f060e035551e5567b00;

        distributions[0] = distribution0;
        distributions[1] = distribution1;

        bytes32 merkleRoot = 0x0466335513002f277c01ce602eb815bb1287b06fe4fa0b59f1d030f137019f7d;

        return (merkleRoot, distributions);

        // distributions [
        // [
        //     0,
        //     '0x236BB9Cf3dC40Df67173aF2F65b4b0d904B4eDe0',
        //     '0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849',
        //     BigNumber { value: "1000000000000000000" }
        // ],
        // [
        //     1,
        //     '0x6b0c8b268742D274f67f4235e22E10470F872f33',
        //     '0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99',
        //     BigNumber { value: "2000000000000000000" }
        // ]
        // ]
        // tree.root 0x0466335513002f277c01ce602eb815bb1287b06fe4fa0b59f1d030f137019f7d
        // proof0.root [
        // '0x372ce6c86f99c51f7943af06c5cf86320ac63f9a71483cdecd8170e70332ffa7'
        // ]
        // proof1.root [
        // '0xd67f0c989dd83f78f1ce0dc68f2119e2a044681a7c5d5f060e035551e5567b00'
        // ]
    }

    function __getPermitTransferSignature(
        ISignatureTransfer.PermitTransferFrom memory permit,
        uint256 privateKey,
        bytes32 domainSeparator,
        address senderStrategy
    ) internal pure returns (bytes memory sig) {
        bytes32 _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
        bytes32 _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissions, senderStrategy, permit.nonce, permit.deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }
}
