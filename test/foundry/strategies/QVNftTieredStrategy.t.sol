// SPDX-License Identifier: MIT
pragma solidity 0.8.19;

// Interfaces
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

// External Libraries
import {ERC721} from "solady/src/tokens/ERC721.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
import {MockERC20Vote} from "../../utils/MockERC20Vote.sol";
import {MockNFT} from "../../utils/MockNFT.sol";

// Core contracts
import {QVNftTieredStrategy} from "../../../contracts/strategies/qv-nft-tiered/QVNftTieredStrategy.sol";

contract QVNftTieredStrategyTest is QVBaseStrategyTest {
    ERC721[] public nfts = new ERC721[](2);
    uint256[] public maxVoiceCreditsPerNft = new uint256[](2);

    function setUp() public override {
        nfts[0] = (ERC721(address(new MockNFT())));
        nfts[1] = (ERC721(address(new MockNFT())));

        maxVoiceCreditsPerNft[0] = (1000);
        maxVoiceCreditsPerNft[1] = (100);

        super.setUp();
    }

    function _createStrategy() internal override returns (address) {
        return address(new QVNftTieredStrategy(address(allo()), "MockStrategy"));
    }

    function qvNftStrategy() internal view returns (QVNftTieredStrategy) {
        return (QVNftTieredStrategy(_strategy));
    }

    function _initialize() internal override {
        vm.prank(address(allo()));
        qvNftStrategy().initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();

        MockNFT(address(nfts[0])).mint(randomAddress(), 1);
        MockNFT(address(nfts[1])).mint(randomAddress(), 1);
    }

    function _createPoolWithCustomStrategy() internal override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            ),
            address(token),
            0 ether, // TODO: setup tests for failed transfers when a value is passed here.
            poolMetadata,
            pool_managers()
        );
    }

    function test_initialize_nftTiered() public {
        assertEq(address(qvNftStrategy().nfts(0)), address(nfts[0]));
        assertEq(address(qvNftStrategy().nfts(1)), address(nfts[1]));
        assertEq(qvNftStrategy().maxVoiceCreditsPerNft(nfts[0]), maxVoiceCreditsPerNft[0]);
        assertEq(qvNftStrategy().maxVoiceCreditsPerNft(nfts[1]), maxVoiceCreditsPerNft[1]);
    }

    function test_initialize_UNAUTHORIZED() public override {
        vm.prank(allo_owner());
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_arrayLengthMismatch_INVALID() public {
        vm.prank(allo_owner());
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");

        uint256[] memory wrongMaxVoiceCreditsPerNftLength = new uint256[](3);
        wrongMaxVoiceCreditsPerNftLength[0] = (1337);
        wrongMaxVoiceCreditsPerNftLength[1] = (420);
        wrongMaxVoiceCreditsPerNftLength[2] = (69);

        vm.expectRevert(QVBaseStrategy.INVALID.selector);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                wrongMaxVoiceCreditsPerNftLength,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.prank(allo_owner());
        strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");
        ERC721[] memory wrongNftsLength = new ERC721[](3);
        wrongNftsLength[0] = (ERC721(address(new MockNFT())));
        wrongNftsLength[1] = (ERC721(address(new MockNFT())));
        wrongNftsLength[2] = (ERC721(address(new MockNFT())));

        vm.expectRevert(QVBaseStrategy.INVALID.selector);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                wrongNftsLength,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public override {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        QVNftTieredStrategy(_strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_INVALID() public override {
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");

        // when registrationStartTime is in the past
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                today() - 1,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when registrationStartTime > registrationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                weekAfterNext(),
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when allocationStartTime > allocationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                registrationEndTime,
                oneMonthFromNow() + today(),
                allocationEndTime
            )
        );

        // when  registrationEndTime > allocationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                2,
                registrationStartTime,
                oneMonthFromNow() + today(),
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId = __register_reject_recipient();
        address allocator = makeAddr("allocator");

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.UNAUTHORIZED.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.prank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient();
        address allocator = randomAddress();

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.prank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_tooManyVoiceCredits() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.INVALID.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4000);

        vm.prank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_noVoiceTokens() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();
        bytes memory allocateData = __generateAllocation(recipientId, 0);

        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function __generateAllocation(address _recipient, uint256 _amount) internal view override returns (bytes memory) {
        return abi.encode(_recipient, nfts[0], 1, _amount);
    }

    function test_isValidAllocator() public override {
        assertFalse(qvNftStrategy().isValidAllocator(address(123)));
        assertTrue(qvNftStrategy().isValidAllocator(randomAddress()));
    }
}
