pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {WrappedVotingNftMintStrategy} from
    "../../../contracts/strategies/_poc/wrapped-voting-nftmint/WrappedVotingNftMintStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {NFT} from "../../../contracts/strategies/_poc/wrapped-voting-nftmint/NFT.sol";
import {NFTFactory} from "../../../contracts/strategies/_poc/wrapped-voting-nftmint/NFTFactory.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {EventSetup} from "../shared/EventSetup.sol";
import {MockRevertingReceiver} from "../../utils/MockRevertingReceiver.sol";

contract WrappedVotingNftMintStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native, Errors {
    event RecipientStatusUpdated(address indexed recipientId, Status recipientStatus, address sender);

    enum Status {
        Pending,
        Accepted,
        Rejected
    }

    NFTFactory public nftFactory;
    NFT public nft;
    WrappedVotingNftMintStrategy public strategy;

    Metadata public metadata;

    uint64 public allocationStartTime;
    uint64 public allocationEndTime;
    uint256 public poolId;

    // The current winner of the pool balance
    address public currentWinner;

    // recipientId => amount
    mapping(address => uint256) private allocations;

    // Test values
    address internal nftFactoryAddress;

    // Setup the test
    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        // create the nft factory
        nftFactory = new NFTFactory();
        nftFactoryAddress = address(nftFactory);

        allocationStartTime = uint64(block.timestamp);
        allocationEndTime = uint64(block.timestamp + 1 weeks);

        metadata = Metadata({protocol: 1, pointer: "0x007"});
        strategy = new WrappedVotingNftMintStrategy(address(allo()), "WrappedVotingNftMintStrategy");

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(nftFactoryAddress, allocationStartTime, allocationEndTime),
            NATIVE,
            0,
            metadata,
            pool_managers()
        );

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

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(poolId, abi.encode(address(nftFactoryAddress), allocationStartTime, allocationEndTime));
    }

    // Test that the initialize() will revert if not called by the pool admin
    function testRevert_initialize_UNAUTHORIZED() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();
        vm.expectRevert(UNAUTHORIZED.selector);

        testStrategy.initialize(poolId, abi.encode(address(nftFactoryAddress), allocationStartTime, allocationEndTime));
    }

    // Tests NFT Factory address is not 0 and reverts as expected
    function testRevert_initialize_INVALID_NFT_FACTORY_ADDRESS() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));

        vm.prank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(address(0), allocationStartTime, allocationEndTime));
    }

    // Tests that the start and end times are not 0 and valid and reverts as expected
    function testRevert_initialize_INVALID_TIMESTAMPS() public {
        WrappedVotingNftMintStrategy testStrategy = __createTestStrategy();

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));

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

    function test_getRecipientStatus() public {
        address testNft = nftFactory.createNFTContract("NFT", "NFT", 1e16, randomAddress());

        assertEq(uint8(strategy.getRecipientStatus(testNft)), uint8(IStrategy.Status.Accepted));

        address noNft = makeAddr("no-nft");
        assertEq(uint8(strategy.getRecipientStatus(noNft)), uint8(IStrategy.Status.None));
    }

    // Fuzz test the timestamps with some assumtions to avoid reversion
    function testFuzz_setAllocationTimestamps(uint64 _startTime, uint64 _endTime) public {
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
        uint64 newAllocationStartTime = uint64(block.timestamp + 1 weeks);
        uint64 newAllocationEndTime = uint64(block.timestamp + 2 weeks);

        vm.expectEmit(true, false, false, true);
        emit TimestampsUpdated(newAllocationStartTime, newAllocationEndTime, pool_manager1());

        vm.prank(pool_manager1());
        strategy.setAllocationTimes(newAllocationStartTime, newAllocationEndTime);

        assertEq(strategy.allocationStartTime(), newAllocationStartTime);
        assertEq(strategy.allocationEndTime(), newAllocationEndTime);
    }

    // Tests that this reverts when the timestamps are invalid
    function testRevert_setAllocationTimestamps_INVALID() public {
        uint64 newAllocationStartTime = uint64(block.timestamp + 1 weeks);
        uint64 newAllocationEndTime = uint64(block.timestamp + 2 weeks);

        vm.expectRevert();
        vm.prank(pool_manager1());
        strategy.setAllocationTimes(newAllocationEndTime, newAllocationStartTime);
    }

    // Tests that this reverts when the user is not the pool manager
    function test_setAllocationTimestamps_UNAUTHORIZED() public {
        uint64 newAllocationStartTime = uint64(block.timestamp + 1 weeks);
        uint64 newAllocationEndTime = uint64(block.timestamp + 2 weeks);

        vm.expectRevert();
        vm.prank(randomAddress());
        strategy.setAllocationTimes(newAllocationStartTime, newAllocationEndTime);
    }

    // Tests allocation
    function test_allocate() public {
        address payable recipientNft = payable(__allocate());

        assertEq(strategy.allocations(recipientNft), 1);
        assertEq(strategy.currentWinner(), recipientNft);
        assertEq(NFT(recipientNft).balanceOf(makeAddr("allocator")), 1);
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
        address recipientNft = __allocate();
        __fund_pool();

        address[] memory recipients = new address[](2);
        recipients[0] = recipientNft;
        recipients[1] = recipient2();

        bytes[] memory payoutData = new bytes[](2);
        payoutData[0] = abi.encode("");
        payoutData[1] = abi.encode("");

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, payoutData);

        // NOTE: this will be after 1% fee is taken
        assertEq(payouts[0].amount, 9.9e19);
        assertEq(payouts[0].recipientAddress, recipientNft);

        assertEq(payouts[1].amount, 0);
        assertEq(payouts[1].recipientAddress, recipient2());
    }

    // Tests if the two arrays are not the same length it will revert
    function testRevert_getPayouts_ARRAY_MISMATCH() public {
        __allocate();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient2();

        bytes[] memory payoutData = new bytes[](3);
        payoutData[0] = abi.encode("");
        payoutData[1] = abi.encode("");
        payoutData[2] = abi.encode("");

        vm.expectRevert(ARRAY_MISMATCH.selector);

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
        vm.expectRevert(UNAUTHORIZED.selector);

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

    function testRevert_mintTo_MaxSupply() public {
        NFT tmpNft = new NFT("Hello", "World", 1, randomAddress());

        address minter = makeAddr("minter");
        vm.deal(minter, 1e18);
        vm.startPrank(minter);
        for (uint256 i; i < tmpNft.TOTAL_SUPPLY(); i++) {
            tmpNft.mintTo{value: 1}(minter);
        }

        vm.expectRevert(NFT.MaxSupply.selector);
        tmpNft.mintTo{value: 1}(minter);
    }

    function testRevert_nft_RevertingReceiver() public {
        address revertingReceiver = address(new MockRevertingReceiver());
        NFT tmpNft = new NFT("Hello", "World", 1, randomAddress());

        address minter = makeAddr("minter");
        vm.deal(minter, 1e18);
        vm.startPrank(minter);

        tmpNft.mintTo{value: 1}(minter);

        vm.stopPrank();
        vm.startPrank(randomAddress());
        vm.expectRevert(NFT.WithdrawTransfer.selector);
        tmpNft.withdrawPayments(payable(revertingReceiver));
    }

    // Tests that when the mint price is not paid it reverts
    function testRevert_mintTo_MintPriceNotPaid() public {
        vm.expectRevert(NFT.MintPriceNotPaid.selector);

        // Sending value as zero which is also under the mint price
        vm.prank(address(strategy));
        nft.mintTo{value: 0}(recipient1());
    }

    // Tests that the NFT contract returns the correct tokenURI
    function test_tokenURI() public {
        assertEq(nft.tokenURI(1), "1");
    }

    // Tests that the withdrawPayments function works correctly
    function test_withdrawPayments() public {
        address payable nftAddress = payable(__allocate());

        vm.prank(randomAddress()); //owner
        NFT(nftAddress).withdrawPayments(payable(recipient1()));

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
        testStrategy = new WrappedVotingNftMintStrategy(address(allo()), "WrappedVotingNftMintStrategy");
    }

    // Allocates to a recipient
    function __allocate() internal returns (address recipientNFT) {
        recipientNFT = nftFactory.createNFTContract("test", "test", 1e18, randomAddress());
        bytes memory data = abi.encode(recipientNFT);

        address allocator = makeAddr("allocator");
        vm.deal(address(allo()), 1e18);
        vm.expectEmit(true, false, false, true);
        emit Allocated(recipientNFT, 1, NATIVE, allocator);

        vm.startPrank(address(allo()));
        strategy.allocate{value: 1e18}(data, allocator);
        vm.stopPrank();
    }

    // Funds the pool with 10 ETH
    function __fund_pool() internal {
        vm.deal(address(strategy), 1e20);
        allo().fundPool{value: 1e20}(poolId, 1e20);
    }
}
