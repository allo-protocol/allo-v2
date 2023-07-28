// SPDX-License Identifier: MIT
pragma solidity 0.8.19;

import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

import {ERC721} from "@solady/tokens/ERC721.sol";

import {QVNftTieredStrategy} from "../../../contracts/strategies/qv-nft-tiered/QVNftTieredStrategy.sol";
import {QVSimpleStrategyTest} from "./QVSimpleStrategy.t.sol";

import {MockNFT} from "../../utils/MockNFT.sol";

contract QVNftTieredStrategyTest is QVSimpleStrategyTest {
    event AllocatedWithNft(address indexed recipientId, uint256 votes, address nft, address allocator);

    ERC721[] nfts = new ERC721[](2);
    uint256[] maxVoiceCreditsPerNft = new uint256[](2);

    function setUp() public override {
        nfts[0] = new MockNFT();
        nfts[1] = new MockNFT();
        maxVoiceCreditsPerNft[0] = 100;
        maxVoiceCreditsPerNft[1] = 200;

        MockNFT(address(nfts[0])).mint(randomAddress(), 5);

        _setUp();

        strategy = address(new QVNftTieredStrategy(address(allo()), "QVNftTieredStrategy"));

        _initialize();
    }

    function _initialize() internal override {
        vm.prank(address(allo()));
        QVNftTieredStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.prank(pool_admin());
        _createPoolWithCustomStrategy();
    }

    function _createPoolWithCustomStrategy() internal override {
        poolId = allo().createPoolWithCustomStrategy(
            poolIdentity_id(),
            address(strategy),
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
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

    function test_initialize() public override {
        assertEq(QVNftTieredStrategy(strategy).getPoolId(), poolId);
        assertEq(QVNftTieredStrategy(strategy).metadataRequired(), metadataRequired);
        assertEq(QVNftTieredStrategy(strategy).maxVoiceCreditsPerNft(nfts[0]), maxVoiceCreditsPerNft[0]);
        assertEq(QVNftTieredStrategy(strategy).maxVoiceCreditsPerNft(nfts[1]), maxVoiceCreditsPerNft[1]);
        assertEq(QVNftTieredStrategy(strategy).registrationStartTime(), registrationStartTime);
        assertEq(QVNftTieredStrategy(strategy).registrationEndTime(), registrationEndTime);
        assertEq(QVNftTieredStrategy(strategy).allocationStartTime(), allocationStartTime);
        assertEq(QVNftTieredStrategy(strategy).allocationEndTime(), allocationEndTime);
    }

    function test_deployment() public override {
        assertEq(address(QVNftTieredStrategy(strategy).getAllo()), address(allo()));
        assertEq(QVNftTieredStrategy(strategy).getStrategyId(), keccak256(abi.encode("QVNftTieredStrategy")));
    }

    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public override {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        QVNftTieredStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                nfts,
                maxVoiceCreditsPerNft,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function test_allocate() public override {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        vm.warp(allocationStartTime + 10);

        QVNftTieredStrategy(strategy).addAllocator(allocator);

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.prank(address(allo()));
        vm.expectEmit(true, false, false, true);

        emit AllocatedWithNft(recipientId, 2e9, address(nfts[0]), allocator);

        QVNftTieredStrategy(strategy).allocate(allocateData, allocator);
    }

    function test_isValidAllocator() public override {
        assertFalse(QVNftTieredStrategy(strategy).isValidAllocator(address(123)));
        assertTrue(QVNftTieredStrategy(strategy).isValidAllocator(randomAddress()));
    }

    function __generateAllocation(address _recipient, uint256 _amount) internal view override returns (bytes memory) {
        return abi.encode(_recipient, address(nfts[0]), 1, _amount);
    }
}
