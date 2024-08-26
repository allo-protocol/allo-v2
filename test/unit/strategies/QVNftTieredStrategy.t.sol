// SPDX-License Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

// External Libraries
import {ERC721} from "solady/tokens/ERC721.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
import {MockERC721} from "../../utils/MockERC721.sol";

// Core contracts
import {QVNftTieredStrategy} from "../../../contracts/strategies/_poc/qv-nft-tiered/QVNftTieredStrategy.sol";

contract QVNftTieredStrategyTest is QVBaseStrategyTest {
    ERC721[] public nfts = new ERC721[](2);
    uint256[] public maxVoiceCreditsPerNft = new uint256[](2);

    function setUp() public override {
        nfts[0] = (ERC721(address(new MockERC721())));
        nfts[1] = (ERC721(address(new MockERC721())));

        maxVoiceCreditsPerNft[0] = (1000);
        maxVoiceCreditsPerNft[1] = (100);

        super.setUp();
    }

    function _createStrategy() internal override returns (address payable) {
        return payable(address(new QVNftTieredStrategy(address(allo()), "MockStrategy")));
    }

    function qvNftStrategy() internal view returns (QVNftTieredStrategy) {
        return (QVNftTieredStrategy(_strategy));
    }

    function _initialize() internal override {
        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();

        MockERC721(payable(address(nfts[0]))).mint(randomAddress(), 1);
        MockERC721(payable(address(nfts[1]))).mint(randomAddress(), 1);
    }

    function _createPoolWithCustomStrategy() internal override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            ),
            address(token),
            0 ether, // TODO: setup tests for failed transfers when a value is passed here.
            poolMetadata,
            pool_managers()
        );
    }

    function test_initialize_nftTiered() public {
        vm.startPrank(allo_owner());
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");

        assertEq(strategy.maxVoiceCreditsPerNft(nfts[0]), 0);
        assertEq(strategy.maxVoiceCreditsPerNft(nfts[1]), 0);

        vm.stopPrank();
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        assertEq(address(strategy.nfts(0)), address(nfts[0]));
        assertEq(address(strategy.nfts(1)), address(nfts[1]));
        assertEq(strategy.maxVoiceCreditsPerNft(nfts[0]), maxVoiceCreditsPerNft[0]);
        assertEq(strategy.maxVoiceCreditsPerNft(nfts[1]), maxVoiceCreditsPerNft[1]);
    }

    function test_initialize_UNAUTHORIZED() public override {
        vm.startPrank(allo_owner());
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.stopPrank();
        vm.startPrank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_initialize_arrayLengthMismatch_INVALID() public {
        vm.startPrank(allo_owner());
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");

        uint256[] memory wrongMaxVoiceCreditsPerNftLength = new uint256[](3);
        wrongMaxVoiceCreditsPerNftLength[0] = (1337);
        wrongMaxVoiceCreditsPerNftLength[1] = (420);
        wrongMaxVoiceCreditsPerNftLength[2] = (69);

        vm.expectRevert(INVALID.selector);

        vm.stopPrank();
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    wrongMaxVoiceCreditsPerNftLength,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        vm.startPrank(allo_owner());
        strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");
        ERC721[] memory wrongNftsLength = new ERC721[](3);
        wrongNftsLength[0] = (ERC721(address(new MockERC721())));
        wrongNftsLength[1] = (ERC721(address(new MockERC721())));
        wrongNftsLength[2] = (ERC721(address(new MockERC721())));

        vm.expectRevert(INVALID.selector);

        vm.stopPrank();
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    wrongNftsLength,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public override {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        QVNftTieredStrategy(_strategy).initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_initialize_INVALID() public override {
        QVNftTieredStrategy strategy = new QVNftTieredStrategy(address(allo()), "MockStrategy");

        // when registrationStartTime is in the past
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        uint64(today() - 1),
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        // when registrationStartTime > registrationEndTime
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        uint64(weekAfterNext()),
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        // when allocationStartTime > allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        uint64(oneMonthFromNow() + today()),
                        allocationEndTime
                    )
                )
            )
        );

        // when  registrationEndTime > allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVNftTieredStrategy.InitializeParamsNft(
                    nfts,
                    maxVoiceCreditsPerNft,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        uint64(oneMonthFromNow() + today()),
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId = __register_reject_recipient();
        address allocator = makeAddr("allocator");

        vm.expectRevert(abi.encodeWithSelector(UNAUTHORIZED.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.startPrank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient();
        address allocator = randomAddress();

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.startPrank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_tooManyVoiceCredits() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4000);

        vm.startPrank(address(allo()));
        qvNftStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_noVoiceTokens() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();
        bytes memory allocateData = __generateAllocation(recipientId, 0);

        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
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
