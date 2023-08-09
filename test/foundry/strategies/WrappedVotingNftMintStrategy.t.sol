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
// External Libraries
import {ERC20} from "solady/src/tokens/ERC20.sol";
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

    // The current winner of the pool balance
    address public currentWinner;

    // recipientId => amount
    mapping(address => uint256) private allocations;

    // Test values
    address internal nftFactoryAddress = makeAddr("nft-factory");

    // Setup the test
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

        // create the NFT with mint price of 1e16 or 0.01 ETH
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

    // Test that is will always return true for any allocator address
    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(recipient1()));
        assertTrue(strategy.isValidAllocator(no_recipient()));
        assertTrue(strategy.isValidAllocator(recipient2()));
        assertTrue(strategy.isValidAllocator(makeAddr("random Chad")));
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
        // emit NFTContractCreated(address(strategy));

        // NFT testNft = NFT(nftFactory.createNFTContract("NFT", "NFT", 1e16, address(strategy)));
    }

    // FIXME: Tests that the recipient status is updated correctly and returns the correct status
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

    // Fuzz test the timestamps with some assumtions to avoid reversion
    function testFuzz_setAllocationTimestamps(uint256 _startTime, uint256 _endTime) public {
        vm.assume(_startTime < _endTime);
        vm.assume(_startTime > block.timestamp);
        vm.assume(_startTime > 0);

        vm.prank(pool_manager1());
        strategy.setAllocationTimes(_startTime, _endTime);

        assertEq(strategy.allocationStartTime(), _startTime);
        assertEq(strategy.allocationEndTime(), _endTime);
    }

    // Tests that ths allocation timestamps are updated correctly
    function test_setAllocationTimestamps() public {
        uint256 newAllocationStartTime = block.timestamp + 1 weeks;
        uint256 newAllocationEndTime = block.timestamp + 2 weeks;

        vm.expectEmit(true, false, false, true);
        emit TimestampsUpdated(newAllocationStartTime, newAllocationEndTime, pool_manager1());

        vm.prank(pool_manager1());
        strategy.setAllocationTimes(newAllocationStartTime, newAllocationEndTime);

        assertEq(strategy.allocationStartTime(), newAllocationStartTime);
        assertEq(strategy.allocationEndTime(), newAllocationEndTime);
    }

    // Tests that this reverts when the timestamps are invalid
    function testRevert_setAllocationTimestamps_INVALID() public {
        uint256 newAllocationStartTime = block.timestamp + 1 weeks;
        uint256 newAllocationEndTime = block.timestamp + 2 weeks;

        vm.expectRevert();
        vm.prank(pool_manager1());
        strategy.setAllocationTimes(newAllocationEndTime, newAllocationStartTime);
    }

    // Tests that this reverts when the user is not the pool manager
    function test_setAllocationTimestamps_UNAUTHORIZED() public {
        uint256 newAllocationStartTime = block.timestamp + 1 weeks;
        uint256 newAllocationEndTime = block.timestamp + 2 weeks;

        vm.expectRevert();
        vm.prank(randomAddress());
        strategy.setAllocationTimes(newAllocationStartTime, newAllocationEndTime);
    }

    // Tests allocation
    function test_allocate() public {
        __allocate();

        assertEq(address(strategy).balance, 1e20);
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

    // Tests allocation reverts if amount is less than the mint price or 0
    function testRevert_allocate_INVALID_AMOUNT() public {
        bytes memory data = abi.encode(nft, recipient1());
        vm.expectRevert();

        // Sending value as zero which is also under the mint price
        vm.prank(address(strategy));
        allo().allocate{value: 0}(poolId, data);
    }

    // Tests that the payout amount and recipient address are correct
    function test_getPayouts() public {
        __allocate();
        __fund_pool();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes[] memory payoutData = new bytes[](2);
        payoutData[0] = abi.encode("");
        payoutData[1] = abi.encode("");

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, payoutData);

        // NOTE: this will be after 1% fee is taken
        assertEq(payouts[0].amount, 9.9e19);
        assertEq(payouts[0].recipientAddress, recipient1());
    }

    // Tests if the two arrays are not the same length it will revert
    function testRevert_getPayouts_BaseStrategy_ARRAY_MISMATCH() public {
        __allocate();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes[] memory payoutData = new bytes[](3);
        payoutData[0] = abi.encode("");
        payoutData[1] = abi.encode("");
        payoutData[2] = abi.encode("");

        vm.expectRevert(IStrategy.BaseStrategy_ARRAY_MISMATCH.selector);

        strategy.getPayouts(recipients, payoutData);
    }

    // Tests that the correct amount is distributed to the correct recipient
    function test_distribute() public {
        __allocate();
        __fund_pool();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes memory payoutData = abi.encode("dummy shit");

        vm.warp(allocationEndTime + 1);
        vm.prank(address(allo()));
        strategy.distribute(recipients, payoutData, address(this));

        // TODO: Check the recipients balance
    }

    // Tests that only Allo can call this function, otherwise reverts
    function testRevert_distribute_UNAUTHORIZED() public {
        __allocate();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes memory payoutData = abi.encode("dummy shit");

        vm.warp(allocationEndTime + 1);
        vm.prank(randomAddress());
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        strategy.distribute(recipients, payoutData, address(this));
    }

    // Tests that allocation has ended before distribution or it reverts
    function testRevert_distribute_ALLOCATION_NOT_ENDED() public {
        __allocate();
        __fund_pool();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes memory payoutData = abi.encode("dummy shit");

        vm.prank(address(allo()));
        vm.expectRevert(ALLOCATION_NOT_ENDED.selector);

        strategy.distribute(recipients, payoutData, address(this));
    }

    // Tests that when pool balance is 0, it reverts
    function testRevert_distribute_INVALID_POOL_AMOUNT_ZERO() public {
        __allocate();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes memory payoutData = abi.encode("dummy shit");

        vm.prank(address(allo()));
        vm.warp(allocationEndTime + 1);
        vm.expectRevert(INVALID.selector);

        strategy.distribute(recipients, payoutData, address(this));
    }

    /// TODO: NFT Contract test coverage - move?
    function test_mintTo() public {}

    // Tests that when the mint price is not paid it reverts
    function testRevert_mintTo_MintPriceNotPaid() public {
        vm.expectRevert(NFT.MintPriceNotPaid.selector);

        // Sending value as zero which is also under the mint price
        vm.prank(address(strategy));
        nft.mintTo{value: 0}(recipient1());
    }

    // Tests that when max supply is reached the mintTo reverts
    function testRevert_mintTo_MaxSupply() public {
        bytes memory data = abi.encode(nft, recipient1());
        vm.expectRevert();

        // Sending value to buy all 10_000 plus 1
        vm.deal(address(strategy), 1_001e18);
        vm.prank(address(strategy));

        allo().allocate{value: 1_001e18}(poolId, data);
    }

    // Tests that the NFT contract returns the correct tokenURI
    function test_tokenURI() public {
        assertEq(nft.tokenURI(1), "1");
    }

    // Tests that the withdrawPayments function works correctly
    function test_withdrawPayments() public {
        __allocate();
        __fund_pool();

        vm.warp(allocationEndTime + 1);
        vm.prank(address(strategy));
        nft.withdrawPayments(payable(recipient1()));

        uint256 balance = address(recipient1()).balance;

        assertEq(balance, 1e18);
    }

    // Tests that the withdrawPayments reverts if the caller is not the owner
    function testRevert_withdrawPayments_UNAUTHORIZED() public {
        __allocate();
        __fund_pool();

        vm.expectRevert();

        vm.warp(allocationEndTime + 1);
        vm.prank(randomAddress());
        nft.withdrawPayments(payable(recipient1()));
    }

    // Tests that the withdrawPayments reverts if the transfer fails WithdrawTransfer()
    // NOTE: not sure how to do this one yet
    function testRevert_withdrawPayments_WithdrawTransfer() public {
        // __allocate();
        // __fund_pool();

        // vm.expectRevert();

        // vm.warp(allocationEndTime + 1);
        // vm.prank(randomAddress());
        // nft.withdrawPayments(payable(recipient1()));
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    // Creates a test strategy to use within a test function
    function __createTestStrategy() internal returns (WrappedVotingNftMintStrategy testStrategy) {
        testStrategy = new WrappedVotingNftMintStrategy(
            address(allo()),
            "WrappedVotingNftMintStrategy"
        );
    }

    // Allocates to a recipient
    function __allocate() internal {
        bytes memory data = abi.encode(nft, recipient1());

        vm.deal(address(strategy), 1e20);
        vm.prank(address(strategy));
        vm.expectEmit(true, false, false, true);
        emit Allocated(address(nft), (1e18 / nft.MINT_PRICE()), NATIVE, recipient1());

        allo().allocate{value: 1e18}(poolId, data);
    }

    // Funds the pool with 10 ETH
    function __fund_pool() internal {
        vm.deal(address(strategy), 1e20);
        allo().fundPool{value: 1e20}(poolId, 1e20);

        assertEq(address(strategy).balance, 1e20);
    }
}
