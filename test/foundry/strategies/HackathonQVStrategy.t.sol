// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
import {HackathonQVStrategy} from "../../../contracts/strategies/qv-hackathon/HackathonQVStrategy.sol";
import {MockERC721} from "../../utils/MockERC721.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";
// External Libraries
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    IEAS,
    RevocationRequest
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {
    ISchemaRegistry,
    ISchemaResolver,
    SchemaRecord
} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";
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
        maxVoiceCreditsPerAllocator = 10;

        easInfo = HackathonQVStrategy.EASInfo({
            eas: eas,
            schemaRegistry: schemaRegistry,
            schemaUID: 0,
            schema: "idk",
            revocable: false
        });

        nft = new MockERC721();
        for (uint256 i = 1; i <= 10; i++) {
            nft.mint(randomAddress(), i);
        }

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

    function _createStrategy() internal override returns (address) {
        return address(new HackathonQVStrategy(address(allo()), "MockStrategy"));
    }

    function hQvStrategy() internal view returns (HackathonQVStrategy) {
        return (HackathonQVStrategy(payable(_strategy)));
    }

    function _initialize() internal override {
        vm.startPrank(address(allo()));
        hQvStrategy().initialize(
            poolId,
            abi.encode(
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
                )
            )
        );

        _createPoolWithCustomStrategy();
        _fundPool(poolId);
    }

    function _createPoolWithCustomStrategy() internal override {
        vm.stopPrank();
        vm.startPrank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
                )
            ),
            NATIVE,
            0 ether, // TODO: setup tests for failed transfers when a value is passed here.
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
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
                )
            )
        );

        assertEq(newStrategy.maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);

        // TODO
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public override {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        qvStrategy().initialize(
            poolId,
            abi.encode(
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
                )
            )
        );
    }

    // NOTE: overriding so it does not run the underyling test
    function test_registerRecipient_appeal() public override {}

    function testRevert_registerRecipient_INVALID_METADATA() public override {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();

        // pointer is empty
        vm.expectRevert(QVBaseStrategy.INVALID_METADATA.selector);
        Metadata memory metadata = Metadata({protocol: 1, pointer: ""});

        bytes memory data = abi.encode(profile1_anchor(), recipient1(), metadata);

        vm.startPrank(address(allo()));
        qvStrategy().registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(QVBaseStrategy.INVALID_METADATA.selector);
        metadata = Metadata({protocol: 0, pointer: "metadata"});

        data = abi.encode(profile1_anchor(), recipient1(), metadata);

        vm.startPrank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
    }

    /// @notice Tests that a recipient can only be registered by pool manager
    function testRevert_registerRecipient_UNAUTHORIZED() public override {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(profile1_anchor(), recipient1(), metadata);

        vm.expectRevert();

        vm.prank(randomAddress());
        qvStrategy().registerRecipient(data, sender);
    }

    /// @notice Tests that this reverts when the recipient is not valid
    function testRevert_registerRecipient_RECIPIENT_ERROR() public override {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();

        // pointer is empty
        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, profile1_anchor()));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(profile1_anchor(), address(0), metadata);

        vm.startPrank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
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
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
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
    function testRevert_setPayoutPercentages_ALLOCATION_STARTED() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 6e17;
        amounts[1] = 4e17;

        vm.expectRevert(HackathonQVStrategy.ALLOCATION_STARTED.selector);
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

        vm.expectRevert(QVBaseStrategy.INVALID.selector);

        vm.prank(pool_admin());
        hQvStrategy().setPayoutPercentages(amounts);
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

    function __register_recipient() internal override returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.startPrank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = hQvStrategy().registerRecipient(data, recipient1());

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 6e17;
        amounts[1] = 4e17;

        vm.stopPrank();

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
        return uint8(IStrategy.RecipientStatus.Accepted);
    }

    function test_reviewRecipient_reviewTreshold() public override {
        // no threshold
    }

    function test_reviewRecipient_reviewTreshold_noStatusChange() public override {
        // no threshold
    }
}
