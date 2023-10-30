// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
import {HackathonQVStrategy} from "../../../contracts/strategies/_poc/qv-hackathon/HackathonQVStrategy.sol";
import {MockERC721} from "../../utils/MockERC721.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

import {
    Attestation, AttestationRequest, AttestationRequestData, IEAS, RevocationRequest
} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry, ISchemaResolver, SchemaRecord} from "eas-contracts/ISchemaRegistry.sol";
// Mocks
import {MockEAS, MockSchemaRegistry} from "../../utils/MockEAS.sol";

/// @title HackathonQVStrategyTest
/// @notice This contract tests the HackathonQVStrategy contract
/// @author allo-team
contract HackathonQVStrategyTest is QVBaseStrategyTest, Native {
    ISchemaRegistry public schemaRegistry;
    HackathonQVStrategy.EASInfo public easInfo;
    MockERC721 public nft;
    IEAS public eas;

    uint256 public maxVoiceCreditsPerAllocator;

    // Set up the tests
    function setUp() public override {
        eas = IEAS(address(new MockEAS()));
        schemaRegistry = ISchemaRegistry(address(new MockSchemaRegistry()));
        maxVoiceCreditsPerAllocator = 5;

        easInfo = HackathonQVStrategy.EASInfo({
            eas: eas,
            schemaRegistry: schemaRegistry,
            schemaUID: 0,
            schema: "idk",
            revocable: false
        });

        nft = new MockERC721();
        nft.mint(randomAddress(), 1);

        /**
         */
        super.setUp();

        useRegistryAnchor = true;

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();
        vm.startPrank(profile1_owner());
        registry().addMembers(profile1_id(), recipients);
        vm.stopPrank();

        __setAllowedRecipientId();
    }

    function _createStrategy() internal override returns (address payable) {
        return payable(address(new HackathonQVStrategy(address(allo()), "MockStrategy")));
    }

    function hQvStrategy() internal view returns (HackathonQVStrategy) {
        return (HackathonQVStrategy(payable(_strategy)));
    }

    function _initialize() internal override {
        _createPoolWithCustomStrategy();
        _fundPool(poolId);
    }

    function _createPoolWithCustomStrategy() internal override {
        vm.startPrank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                HackathonQVStrategy.InitializeParamsHack(
                    easInfo,
                    address(nft),
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        true,
                        metadataRequired,
                        0,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            ),
            NATIVE,
            0 ether,
            poolMetadata,
            pool_managers()
        );
        vm.stopPrank();
    }

    function _fundPool(uint256 poolId) internal {
        vm.deal(pool_admin(), 2e18);
        vm.startPrank(pool_admin());
        allo().fundPool{value: 1 ether}(poolId, 1 ether);
        vm.stopPrank();
    }

    // ==========================================================================

    function test_contract_deployment() public {
        HackathonQVStrategy newStrategy = new HackathonQVStrategy(address(allo()), "MockStrategy");

        vm.startPrank(address(allo()));
        newStrategy.initialize(
            poolId,
            abi.encode(
                HackathonQVStrategy.InitializeParamsHack(
                    easInfo,
                    address(nft),
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        true,
                        metadataRequired,
                        0,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        (IEAS eas_, ISchemaRegistry schemaReg_, bytes32 schemaUid_, string memory schema_, bool revocable_) =
            newStrategy.easInfo();

        assertEq(newStrategy.maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);
        assertEq(address(eas_), address(eas));
        assertEq(address(schemaReg_), address(schemaRegistry));
        assertEq(schemaUid_, bytes32("123"));
        assertEq(schema_, easInfo.schema);
        assertEq(revocable_, easInfo.revocable);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public override {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        qvStrategy().initialize(
            poolId,
            abi.encode(
                HackathonQVStrategy.InitializeParamsHack(
                    easInfo,
                    address(nft),
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        true,
                        metadataRequired,
                        0,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_initialize_INVALID_SCHEMA() public {
        HackathonQVStrategy hStrategy = HackathonQVStrategy(payable(_createStrategy()));

        HackathonQVStrategy.EASInfo memory easInfoFalse = HackathonQVStrategy.EASInfo({
            eas: eas,
            schemaRegistry: schemaRegistry,
            schemaUID: bytes32("123"),
            schema: "", // length == 0
            revocable: false // false != true
        });

        vm.expectRevert(HackathonQVStrategy.INVALID_SCHEMA.selector);

        vm.startPrank(address(allo()));
        hStrategy.initialize(
            poolId,
            abi.encode(
                HackathonQVStrategy.InitializeParamsHack(
                    easInfoFalse,
                    address(nft),
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        true,
                        metadataRequired,
                        0,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        easInfoFalse.revocable = true;

        vm.expectRevert(HackathonQVStrategy.INVALID_SCHEMA.selector);

        hStrategy.initialize(
            poolId,
            abi.encode(
                HackathonQVStrategy.InitializeParamsHack(
                    easInfoFalse,
                    address(nft),
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        true,
                        metadataRequired,
                        0,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function test_register() public {
        address recipientId = __register_recipient();
        HackathonQVStrategy.Recipient memory recipient = hQvStrategy().getRecipient(recipientId);

        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Accepted));
    }

    function test_registerRecipient_appeal() public override {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        address recipientId = hQvStrategy().registerRecipient(data, recipient1());

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory recipientStatuses = new IStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.Rejected;
        vm.prank(pool_admin());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // appeal
        vm.prank(address(allo()));
        hQvStrategy().registerRecipient(data, recipient1());

        HackathonQVStrategy.Recipient memory recipient = hQvStrategy().getRecipient(recipientId);

        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Appealed));
    }

    function testRevert_registerRecipient_INVALID_METADATA() public override {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();

        // pointer is empty
        vm.expectRevert(INVALID_METADATA.selector);
        Metadata memory metadata = Metadata({protocol: 1, pointer: ""});

        bytes memory data = abi.encode(profile1_anchor(), recipient1(), metadata);

        vm.startPrank(address(allo()));
        qvStrategy().registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(INVALID_METADATA.selector);
        metadata = Metadata({protocol: 0, pointer: "metadata"});

        data = abi.encode(profile1_anchor(), recipient1(), metadata);

        vm.startPrank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
    }

    /// @notice Tests that a recipient can only be registered by pool manager
    function testRevert_registerRecipient_UNAUTHORIZED() public override {
        vm.warp(registrationStartTime + 1);

        address sender = profile2_member1();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(profile2_anchor(), sender, metadata);

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(address(allo()));
        hQvStrategy().registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_UNAUTHORIZED_recipientIdToUIDIsZero() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(randomAddress(), recipient1(), metadata);

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(address(allo()));
        hQvStrategy().registerRecipient(data, sender);
    }

    /// @notice Tests that this reverts when the recipient is not valid
    function testRevert_registerRecipient_RECIPIENT_ERROR() public override {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();

        // pointer is empty
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(profile1_anchor(), address(0), metadata);

        vm.startPrank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId = __register_accept_recipient();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.warp(allocationStartTime + 10);
        bytes memory allocation = __generateAllocation(recipientId, 1);
        vm.startPrank(address(allo()));
        qvStrategy().allocate(allocation, makeAddr("bob"));
    }

    function testRevert_allocate_INVALID_noVoiceCreditsLeft() public {
        address recipientId = __register_accept_recipient();

        vm.warp(allocationStartTime + 10);
        bytes memory allocation = __generateAllocation(recipientId, 5);
        vm.startPrank(address(allo()));
        qvStrategy().allocate(allocation, randomAddress());

        vm.expectRevert(INVALID.selector);

        qvStrategy().allocate(allocation, randomAddress());
        vm.stopPrank();
    }

    function testRevert_allocate_INVALID_noPayoutPercentages() public {
        address recipientId = __register_recipient_noPayoutPercentages();

        vm.warp(allocationStartTime + 10);
        bytes memory allocation = __generateAllocation(recipientId, 5);
        vm.startPrank(address(allo()));

        vm.expectRevert(INVALID.selector);

        qvStrategy().allocate(allocation, randomAddress());
        vm.stopPrank();
    }

    /// @notice Tests distribute
    function test_distribute() public override {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = profile1_anchor();

        assertEq((address(hQvStrategy())).balance, 0.99 ether);

        vm.startPrank(address(allo()));
        vm.expectEmit(true, false, false, false);

        // 0.594 ether == winner
        emit Distributed(profile1_anchor(), recipient1(), 0.594 ether, pool_admin());

        hQvStrategy().distribute(recipients, "", pool_admin());
    }

    /// @notice Tests getPayouts
    function test_getPayouts() public override {
        __register_accept_allocate_recipient();

        QVBaseStrategy.PayoutSummary[] memory payouts = hQvStrategy().getPayouts(new address[](1), new bytes[](1));

        assertEq(payouts[0].recipientAddress, recipient1());
        assertEq(payouts[0].amount, 0.594 ether);
    }

    /// @notice Tests if an address is a valid allocator
    function test_isValidAllocator() public override {
        assertTrue(qvStrategy().isValidAllocator(randomAddress()));
        assertFalse(qvStrategy().isValidAllocator(address(123)));
    }

    function test_setAllowedRecipientIds() public {
        vm.startPrank(pool_admin());
        uint256 poolId_ = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(new HackathonQVStrategy(address(allo()), "MockStrategy")),
            abi.encode(
                HackathonQVStrategy.InitializeParamsHack(
                    easInfo,
                    address(nft),
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        true,
                        metadataRequired,
                        0,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            ),
            NATIVE,
            0 ether,
            poolMetadata,
            pool_managers()
        );

        HackathonQVStrategy newStrategy = HackathonQVStrategy(payable(address(allo().getPool(poolId_).strategy)));

        bytes memory aesData = abi.encode("attestation data");

        address[] memory recipients = new address[](1);
        recipients[0] = profile1_anchor();

        newStrategy.setAllowedRecipientIds(recipients, uint64(allocationEndTime + 30 days), aesData);
        vm.stopPrank();

        assertTrue(newStrategy.recipientIdToUID(profile1_anchor()) != bytes32(0));
    }

    function testRevert_setAllowedRecipientIds_ALREADY_ADDED() public {
        vm.expectRevert(HackathonQVStrategy.ALREADY_ADDED.selector);
        __setAllowedRecipientId();
    }

    function test_onRevoke() public {
        vm.prank(address(eas));
        Attestation memory attestation;
        assertTrue(hQvStrategy().revoke(attestation));
    }

    function test_onAttest() public {
        vm.prank(address(eas));
        Attestation memory attestation;
        assertTrue(hQvStrategy().attest(attestation));
    }

    function test_isPayable() public {
        assertTrue(hQvStrategy().isPayable());
    }

    function test_getSchema() public {
        SchemaRecord memory schema = hQvStrategy().getSchema(bytes32("1"));
        SchemaRecord memory mockSchema = SchemaRecord(bytes32("123"), ISchemaResolver(address(0)), true, "123");
        assertEq(keccak256(abi.encode(mockSchema)), keccak256(abi.encode(schema)));
    }

    function test_getAttestation() public {
        Attestation memory mockAttestation = Attestation({
            uid: bytes32("123"),
            schema: bytes32("123"),
            time: 1,
            expirationTime: 2,
            revocationTime: 3,
            refUID: bytes32("123"),
            recipient: address(123),
            attester: address(123),
            revocable: true,
            data: abi.encode("123")
        });

        Attestation memory attestation = hQvStrategy().getAttestation(bytes32("1"));
        assertEq(keccak256(abi.encode(mockAttestation)), keccak256(abi.encode(attestation)));
    }

    /// @notice Tests the payout percentages can be set - no event is emitted on this call
    function test_setPayoutPercentages() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 6e17;
        amounts[1] = 4e17;

        vm.prank(pool_admin());
        hQvStrategy().setPayoutPercentages(amounts);
    }

    /// @notice Tests the payout percentages will revert if allocation has started
    function testRevert_setPayoutPercentages_ALLOCATION_ACTIVE() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 6e17;
        amounts[1] = 4e17;

        vm.expectRevert(ALLOCATION_ACTIVE.selector);
        vm.warp(allocationStartTime + 10);
        vm.prank(pool_admin());
        hQvStrategy().setPayoutPercentages(amounts);
    }

    /// @notice Tests the payout percentages will revert if list is out of order
    function testRevert_setPayoutPercentages_INVALID_OUT_OF_ORDER() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4e17;
        amounts[1] = 6e17;

        vm.expectRevert();

        vm.prank(pool_admin());
        hQvStrategy().setPayoutPercentages(amounts);
    }

    /// @notice Tests the payout percentages will revert if amounts don't add up to 1e18
    function testRevert_setPayoutPercentages_INVALID_AMOUNT() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 6e17;
        amounts[1] = 3e17;

        vm.expectRevert(INVALID.selector);

        vm.prank(pool_admin());
        hQvStrategy().setPayoutPercentages(amounts);
    }

    function test_isAttestationExpired() public {
        assertFalse(hQvStrategy().isAttestationExpired(profile1_anchor()));

        vm.warp(allocationEndTime + 10);
        assertTrue(hQvStrategy().isAttestationExpired(profile1_anchor()));
    }

    function test_winnerlist() public {
        // create some hackers
        address[] memory hacker = new address[](10);
        address[] memory hackerAnchors = new address[](10);

        for (uint256 i; i < 10; i++) {
            string memory hackerName = string(abi.encode("Hacker ", i));
            hacker[i] = makeAddr(hackerName);

            vm.prank(hacker[i]);
            bytes32 profileId =
                registry().createProfile(0, hackerName, Metadata(1, hackerName), hacker[i], new address[](0));

            hackerAnchors[i] = registry().getProfileById(profileId).anchor;
        }

        // create some allocators
        address[] memory allocators = new address[](10);
        for (uint256 i; i < 10; i++) {
            allocators[i] = makeAddr(string(abi.encode("Allocator ", i)));
            nft.mint(allocators[i], i + 2);
        }

        // setAllowedRecipientIds

        vm.startPrank(pool_admin());
        hQvStrategy().setAllowedRecipientIds(
            hackerAnchors, uint64(allocationEndTime + 30 days), abi.encode("attestation data")
        );

        // setPayoutPercentages for 4 winner

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 4e17;
        amounts[1] = 3e17;
        amounts[2] = 2e17;
        amounts[3] = 1e17;

        hQvStrategy().setPayoutPercentages(amounts);

        vm.stopPrank();

        // register recipients

        vm.warp(registrationStartTime + 10);

        vm.startPrank(address(allo()));

        bytes memory data_;

        for (uint256 i; i < 10; i++) {
            data_ = abi.encode(hackerAnchors[i], hacker[i], Metadata(1, string(abi.encode("Hacker ", i))));
            hQvStrategy().registerRecipient(data_, hacker[i]);
        }

        // allocate

        vm.warp(allocationStartTime + 10);

        for (uint256 i; i < 10; i++) {
            data_ = abi.encode(
                hackerAnchors[i],
                i + 2, // nft id to vote with
                1 // vote credits to allocate
            );

            hQvStrategy().allocate(data_, allocators[i]);

            assertEq(hQvStrategy().voiceCreditsUsedPerNftId(i + 2), 1);

            if (i < 4) {
                assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[i]) == i);
                assertTrue(hQvStrategy().indexToRecipientId(i) == hackerAnchors[i]);
            } else {
                assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[i]) == 0);
                assertTrue(hQvStrategy().indexToRecipientId(i) == address(0));
            }
        }

        // current winner list:
        // 0: hacker 0, allocated votes: 1
        // 1: hacker 1, allocated votes: 1
        // 2: hacker 2, allocated votes: 1
        // 3: hacker 3, allocated votes: 1

        // not in list:
        // hacker 4
        // hacker 5
        // hacker 6
        // hacker 7
        // hacker 8
        // hacker 9

        // allocate vote for hacker 5

        data_ = abi.encode(
            hackerAnchors[4],
            2, // nft id to vote with
            1 // vote credits to allocate
        );

        hQvStrategy().allocate(data_, allocators[0]);

        // expect hacker 5 at index 0
        // hacker 0 at index 1
        // hacker 1 at index 2
        // hacker 2 at index 3
        // hacker 3 not in list

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[4]) == 0);
        assertTrue(hQvStrategy().indexToRecipientId(0) == hackerAnchors[4]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[0]) == 1);
        assertTrue(hQvStrategy().indexToRecipientId(1) == hackerAnchors[0]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[1]) == 2);
        assertTrue(hQvStrategy().indexToRecipientId(2) == hackerAnchors[1]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[2]) == 3);
        assertTrue(hQvStrategy().indexToRecipientId(3) == hackerAnchors[2]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[3]) == 0);
        assertTrue(hQvStrategy().indexToRecipientId(4) == address(0));

        // current winner list:
        // 0: hacker 4, allocated votes: 2
        // 1: hacker 0, allocated votes: 1
        // 2: hacker 1, allocated votes: 1
        // 3: hacker 2, allocated votes: 1

        // not in list:
        // hacker 3
        // hacker 4
        // hacker 6
        // hacker 7
        // hacker 8
        // hacker 9

        // allocate vote for hacker 6

        data_ = abi.encode(
            hackerAnchors[5],
            2, // nft id to vote with
            2 // vote credits to allocate
        );

        hQvStrategy().allocate(data_, allocators[0]);

        // expect
        // hacker 5 at index 0
        // hacker 4 at index 1
        // hacker 0 at index 2
        // hacker 1 at index 3
        // hacker 2 not in list

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[5]) == 0);
        assertTrue(hQvStrategy().indexToRecipientId(0) == hackerAnchors[5]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[4]) == 1);
        assertTrue(hQvStrategy().indexToRecipientId(1) == hackerAnchors[4]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[0]) == 2);
        assertTrue(hQvStrategy().indexToRecipientId(2) == hackerAnchors[0]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[1]) == 3);
        assertTrue(hQvStrategy().indexToRecipientId(3) == hackerAnchors[1]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[2]) == 0);
        assertTrue(hQvStrategy().indexToRecipientId(4) == address(0));

        // current winner list:
        // 0: hacker 5, allocated votes: 3
        // 1: hacker 4, allocated votes: 2
        // 2: hacker 0, allocated votes: 1
        // 3: hacker 1, allocated votes: 1

        // not in list:
        // hacker 2
        // hacker 3
        // hacker 4
        // ...

        // allocate 2 vote for hacker 0

        data_ = abi.encode(
            hackerAnchors[0],
            3, // nft id to vote with
            2 // vote credits to allocate
        );

        hQvStrategy().allocate(data_, allocators[1]);

        // expect hacker 0 at index 1

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[5]) == 0);
        assertTrue(hQvStrategy().indexToRecipientId(0) == hackerAnchors[5]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[0]) == 1);
        assertTrue(hQvStrategy().indexToRecipientId(1) == hackerAnchors[0]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[4]) == 2);
        assertTrue(hQvStrategy().indexToRecipientId(2) == hackerAnchors[4]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[1]) == 3);
        assertTrue(hQvStrategy().indexToRecipientId(3) == hackerAnchors[1]);

        assertTrue(hQvStrategy().recipientIdToIndex(hackerAnchors[2]) == 0);
        assertTrue(hQvStrategy().indexToRecipientId(4) == address(0));

        // current winner list:
        // 0: hacker 5, allocated votes: 3
        // 1: hacker 0, allocated votes: 3
        // 2: hacker 4, allocated votes: 2
        // 3: hacker 1, allocated votes: 1

        // not in list:
        // hacker 2
        // hacker 3
        // hacker 6
        // ...

        vm.stopPrank();

        // getPayouts

        uint256 balance = address(hQvStrategy()).balance;

        IStrategy.PayoutSummary[] memory payoutSummary = hQvStrategy().getPayouts(hackerAnchors, new bytes[](10));

        assertTrue(payoutSummary.length == 4);

        assertTrue(payoutSummary[0].recipientAddress == hacker[5]);
        assertTrue(payoutSummary[0].amount == balance * amounts[0] / 1e18);

        assertTrue(payoutSummary[1].recipientAddress == hacker[0]);
        assertTrue(payoutSummary[1].amount == balance * amounts[1] / 1e18);

        assertTrue(payoutSummary[2].recipientAddress == hacker[4]);
        assertTrue(payoutSummary[2].amount == balance * amounts[2] / 1e18);

        assertTrue(payoutSummary[3].recipientAddress == hacker[1]);
        assertTrue(payoutSummary[3].amount == balance * amounts[3] / 1e18);
    }

    // ==========================================================================

    function __setAllowedRecipientId() internal {
        bytes memory easData = abi.encode("attestation data");

        address[] memory recipients = new address[](1);
        recipients[0] = profile1_anchor();

        vm.startPrank(pool_admin());
        hQvStrategy().setAllowedRecipientIds(recipients, uint64(allocationEndTime + 30 days), easData);
        vm.stopPrank();
    }

    function __register_recipient_noPayoutPercentages() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.startPrank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = hQvStrategy().registerRecipient(data, recipient1());
        vm.stopPrank();
    }

    function __register_recipient() internal override returns (address recipientId) {
        recipientId = __register_recipient_noPayoutPercentages();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 6e17;
        amounts[1] = 4e17;

        vm.prank(pool_admin());
        hQvStrategy().setPayoutPercentages(amounts);
    }

    function __register_accept_recipient() internal override returns (address) {
        return __register_recipient();
    }

    function __register_accept_allocate_recipient() internal override returns (address) {
        address recipientId = __register_accept_recipient();

        vm.warp(allocationStartTime + 10);
        bytes memory allocation = __generateAllocation(recipientId, 1);
        vm.startPrank(address(allo()));
        qvStrategy().allocate(allocation, randomAddress());

        vm.warp(allocationEndTime + 10);

        return recipientId;
    }

    function __generateAllocation(address _recipient, uint256 _amount) internal pure override returns (bytes memory) {
        return abi.encode(_recipient, 1, _amount);
    }

    function __generateRecipientWithId(address _recipientId) internal override returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipient1(), metadata);
    }

    function __afterRegistrationStatus() internal pure override returns (uint8) {
        return uint8(IStrategy.Status.Accepted);
    }

    function test_reviewRecipient_reviewTreshold() public override {
        // no threshold
    }

    function test_reviewRecipient_reviewTreshold_noStatusChange() public override {
        // no threshold
    }

    function test_registerRecipient_accepted() public override {}

    function testRevert_fundPool_afterDistribution() public override {}
}
