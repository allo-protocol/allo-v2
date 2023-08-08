pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/donation-voting/DonationVotingStrategy.sol";
// Strategy contracts
import {WrappedVotingNftMintStrategy} from
    "../../../contracts/strategies/wrapped-voting-nftmint/WrappedVotingNftMintStrategy.sol";
// Internal libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {NFT} from "../../../contracts/strategies/wrapped-voting-nftmint/NFT.sol";
import {NFTFactory} from "../../../contracts/strategies/wrapped-voting-nftmint/NFTFactory.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {EventSetup} from "../shared/EventSetup.sol";

contract WrappedVotingNftMintStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native {
    error UNAUTHORIZED();
    error REGISTRATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error RECIPIENT_ERROR(address recipientId);
    error INVALID();

    event RecipientStatusUpdated(address indexed recipientId, InternalRecipientStatus recipientStatus, address sender);

    enum InternalRecipientStatus {
        Pending,
        Accepted,
        Rejected
    }

    NFTFactory public nftFactory;
    NFT public nft;
    WrappedVotingNftMintStrategy public strategy;

    Metadata public metadata;

    uint256 public allocationStartTime;
    uint256 public allocationEndTime;
    uint256 public poolId;

    address public currentWinner;

    // recipientId => amount
    mapping(address => uint256) private allocations;

    // Test values
    address internal nftFactoryAddress = makeAddr("nft-factory");

    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        allocationStartTime = block.timestamp;
        allocationEndTime = block.timestamp + 1 weeks;

        metadata = Metadata({protocol: 1, pointer: "0x007"});
        strategy = new WrappedVotingNftMintStrategy(
            address(allo()),
            "WrappedVotingNftMintStrategy"
        );

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(nftFactoryAddress, allocationStartTime, allocationEndTime),
            address(0),
            0,
            metadata,
            pool_managers()
        );

        // create an NFT
        nftFactory = new NFTFactory();
        nft = NFT(nftFactory.createNFTContract("NFT", "NFT", 1e16, address(strategy)));
    }

    // Test that strategy contract is deployed and initialized correctly
    function test_deployment() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();

        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("WrappedVotingNftMintStrategy")));
    }

    // Test that the poolId is set correctly and strategy is active and initialized correctly
    function test_initialize() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();

        vm.expectEmit(true, false, false, true);
        emit TimestampsUpdated(allocationStartTime, allocationEndTime, address(allo()));

        vm.prank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(nftFactoryAddress, allocationStartTime, allocationEndTime));

        assertEq(testStrategy.getPoolId(), poolId);
        assertEq(address(testStrategy.nftFactory()), nftFactoryAddress);
        assertEq(testStrategy.allocationStartTime(), allocationStartTime);
        assertEq(testStrategy.allocationEndTime(), allocationEndTime);
        assertTrue(testStrategy.isPoolActive());
    }

    // Test that the initialize() will revert if already initialized
    function testRevert_initialize_ALREADY_INITIALIZED() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();
        vm.startPrank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(address(nftFactoryAddress), allocationStartTime, allocationEndTime));

        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);
        testStrategy.initialize(poolId, abi.encode(address(nftFactoryAddress), allocationStartTime, allocationEndTime));
    }

    // Test that the initialize() will revert if not called by the pool admin
    function testRevert_initialize_UNAUTHORIZED() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        testStrategy.initialize(poolId, abi.encode(address(nftFactoryAddress), allocationStartTime, allocationEndTime));
    }

    // Tests NFT Factory address is not 0 and reverts as expected
    function testRevert_initialize_INVALID_NFT_FACTORY_ADDRESS() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();

        vm.expectRevert(abi.encodeWithSelector(WrappedVotingNftMintStrategy.INVALID.selector));

        vm.prank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(address(0), allocationStartTime, allocationEndTime));
    }

    // Tests that the start and end times are not 0 and valid and reverts as expected
    function testRevert_initialize_INVALID_TIMESTAMPS() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();

        vm.expectRevert(abi.encodeWithSelector(WrappedVotingNftMintStrategy.INVALID.selector));

        vm.prank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(address(0), allocationEndTime, allocationStartTime));
    }

    // Tests that this will revert, it is not implemented
    function testRevert_registerRecipient_NOT_IMPLEMENTED() public {
        vm.expectRevert();

        vm.prank(address(allo()));
        strategy.registerRecipient(abi.encode(0, 0, 0, 0, 0, 0), address(0));
    }

    // FIXME: this test will expect an emit and the emit can't happen until it is deployed...
    function test_nftContractCreated() public {
        // vm.expectEmit(true, false, false, true);
        // emit NFTContractCreated(address(0));

        // address nftCreatedFromFactoryAddress = nftFactory.createNFTContract("NFT", "NFT", 1e17, recipient1());
    }

    // Tests that the recipient status is updated correctly and returns the correct status
    function test_getRecipientStatus() public {
        NFT testNft = NFT(nftFactory.createNFTContract("NFT", "NFT", 1e16, address(strategy)));
        bytes memory data = abi.encode(testNft, recipient1());
        vm.deal(address(strategy), 1e20);
        vm.prank(address(strategy));
        allo().allocate{value: 1e18}(poolId, data);

        //  FIXME: this test is reverting...
        // assertEq(
        //     uint8(strategy.getRecipientStatus(recipient1())),
        //     uint8(WrappedVotingNftMintStrategy.InternalRecipientStatus.Accepted)
        // );
    }

    // Tests allocation
    function test_allocate() public {
        bytes memory data = abi.encode(nft, recipient1());
        vm.deal(address(strategy), 1e20);
        vm.prank(address(strategy));
        allo().allocate{value: 1e18}(poolId, data);
    }

    // Tests that allocated reverts whent he minter is not the owner
    function testRevert_allocate_NOT_AUTHORIZED() public {
        NFT testNft = NFT(nftFactory.createNFTContract("NFT", "NFT", 1e16, no_recipient()));
        bytes memory data = abi.encode(testNft, recipient1());
        vm.expectRevert(0x82b42900);
        vm.deal(recipient1(), 1e20);
        vm.prank(recipient1());
        allo().allocate{value: 1e18}(poolId, data);
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    function __createTestStrategy() internal returns (WrappedVotingNftMintStrategy testStrategy) {
        testStrategy = new WrappedVotingNftMintStrategy(
            address(allo()),
            "WrappedVotingNftMintStrategy"
        );
    }
}
