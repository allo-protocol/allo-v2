pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {TestUtilities} from "../utils/TestUtilities.sol";

// import "../../../contracts/interfaces/IAllocationStrategy.sol";
// import "../../../contracts/interfaces/IDistributionStrategy.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

import {MockStrategy} from "../utils/MockStrategy.sol";
import {MockToken} from "../utils/MockToken.sol";

contract AlloTest is Test, AlloSetup, RegistrySetupFull {
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    event BaseFeePaid(uint256 indexed poolId, uint256 amount);

    event PoolClosed(uint256 indexed poolId);

    event TreasuryUpdated(address treasury);

    event FeePercentageUpdated(uint256 feePercentage);

    event BaseFeeUpdated(uint256 baseFee);

    event RegistryUpdated(address registry);

    event StrategyApproved(address strategy);

    event StrategyRemoved(address strategy);

    error AlreadyInitialized();

    address public strategy;
    MockToken public token;

    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public metadata = Metadata({protocol: 1, pointer: "strategy pointer"});
    string public name;
    uint256 public nonce;

    bytes32 public identityId;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        token = new MockToken();
        token.mint(local(), mintAmount);
        token.mint(allo_owner(), mintAmount);
        token.mint(pool_admin(), mintAmount);
        token.approve(address(allo()), mintAmount);

        vm.prank(pool_admin());
        token.approve(address(allo()), mintAmount);

        strategy = address(new MockStrategy(address(allo())));
    }

    function _utilCreatePool(uint256 _amount) internal returns (uint256) {
        vm.prank(pool_admin());
        return allo().createPoolWithCustomStrategy(
            identityId, strategy, "0x", address(token), _amount, metadata, pool_managers()
        );
    }

    function test_initialize() public {
        Allo coreContract = new Allo();
        vm.expectEmit(true, false, false, true);

        emit RegistryUpdated(address(registry()));
        emit TreasuryUpdated(address(allo_treasury()));
        emit FeePercentageUpdated(1e16);
        emit BaseFeeUpdated(1e16);

        coreContract.initialize(
            address(registry()), // _registry
            allo_treasury(), // _treasury
            1e16, // _feePercentage
            1e15, // _baseFee
            1e14 // _feeSkirtingBountyPercentage
        );

        assertEq(address(coreContract.getRegistry()), address(registry()));
        assertEq(coreContract.getTreasury(), allo_treasury());
        assertEq(coreContract.getFeePercentage(), 1e16);
        assertEq(coreContract.getBaseFee(), 1e15);
        assertEq(coreContract.getFeeSkirtingBountyPercentage(), 1e14);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        vm.expectRevert(AlreadyInitialized.selector);

        allo().initialize(
            address(registry()), // _registry
            allo_treasury(), // _treasury
            1e16, // _feePercentage
            1e15, // _baseFee
            1e14 // _feeSkirtingBountyPercentage
        );
    }

    // function test_createPoolWithCloneWithApprovedAllocationStrategy() public {
    //     vm.prank(alloOwner);
    //     allo.addToApprovedStrategies(allocationStrategy);

    //     vm.expectEmit(true, true, false, false);
    //     emit PoolCreated(
    //         1,
    //         identityId,
    //         IAllocationStrategy(allocationStrategy),
    //         IDistributionStrategy(distributionStrategy),
    //         address(token),
    //         0,
    //         metadata
    //     );

    //     vm.prank(owner);
    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         true,
    //         payable(distributionStrategy),
    //         "0x",
    //         false,
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );

    //     assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
    //     assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
    //     assertNotEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    // }

    // function test_createPoolWithCloneWithApprovedDistributionStrategy() public {
    //     vm.prank(alloOwner);
    //     allo.addToApprovedStrategies(distributionStrategy);

    //     vm.expectEmit(true, true, false, false);
    //     emit PoolCreated(
    //         1,
    //         identityId,
    //         IAllocationStrategy(allocationStrategy),
    //         IDistributionStrategy(distributionStrategy),
    //         address(token),
    //         0,
    //         metadata
    //     );

    //     vm.prank(owner);
    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         false,
    //         payable(distributionStrategy),
    //         "0x",
    //         true,
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );

    //     assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
    //     assertNotEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
    //     assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    // }

    // function test_createPoolWithCloneWithoutApprovedStrategies() public {
    //     vm.expectEmit(true, true, false, true);
    //     emit PoolCreated(
    //         1,
    //         identityId,
    //         IAllocationStrategy(allocationStrategy),
    //         IDistributionStrategy(distributionStrategy),
    //         address(token),
    //         0,
    //         metadata
    //     );

    //     vm.prank(owner);
    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         false,
    //         payable(distributionStrategy),
    //         "0x",
    //         false,
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );

    //     assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
    //     assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
    //     assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    // }

    // function testRevert_createPoolWithCloneWithUnapprovedAllocationStrategy_NOT_APPROVED_STRATEGY() public {
    //     vm.expectRevert(Allo.NOT_APPROVED_STRATEGY.selector);

    //     vm.prank(owner);
    //     allo.createPoolWithClone(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         true,
    //         payable(distributionStrategy),
    //         "0x",
    //         false,
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );
    // }

    // function testRevert_createPoolWithCloneWithUnapprovedDistributionStrategy_NOT_APPROVED_STRATEGY() public {
    //     vm.expectRevert(Allo.NOT_APPROVED_STRATEGY.selector);

    //     vm.prank(owner);
    //     allo.createPoolWithClone(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         false,
    //         payable(distributionStrategy),
    //         "0x",
    //         true,
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );
    // }

    // function test_createPool_shit() public {
    //     vm.expectEmit(true, true, false, true);
    //     emit PoolCreated(
    //         1,
    //         identityId,
    //         IAllocationStrategy(allocationStrategy),
    //         IDistributionStrategy(distributionStrategy),
    //         address(token),
    //         0,
    //         metadata
    //     );

    //     uint256 poolId = _utilCreatePool(0);

    //     assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
    //     assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
    //     assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);

    //     assertTrue(allo.isPoolAdmin(poolId, owner));
    //     assertFalse(allo.isPoolAdmin(poolId, members[0]));

    //     assertTrue(allo.isPoolManager(poolId, members[0]));
    //     assertTrue(allo.isPoolManager(poolId, members[1]));
    // }

    // function test_createPoolWithBaseFee() public {
    //     uint256 baseFee = 1e17;

    //     vm.prank(alloOwner);
    //     allo.updateBaseFee(baseFee);

    //     vm.expectEmit(true, false, false, true);
    //     emit BaseFeePaid(1, baseFee);

    //     vm.deal(address(owner), 1 ether);

    //     vm.prank(owner);
    //     allo.createPool{value: baseFee}(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         payable(distributionStrategy),
    //         "0x",
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );
    // }

    // function testRevert_createPool_UNAUTHORIZED() public {
    //     vm.prank(makeAddr("not owner"));
    //     vm.expectRevert(Allo.UNAUTHORIZED.selector);

    //     allo.createPool(
    //         identityId,
    //         allocationStrategy,
    //         "0x",
    //         payable(distributionStrategy),
    //         "0x",
    //         address(token),
    //         0,
    //         metadata,
    //         members
    //     );
    // }

    // function test_createPoolWithTokens() public {
    //     vm.expectEmit(true, false, false, true);
    //     emit PoolCreated(
    //         1,
    //         identityId,
    //         IAllocationStrategy(allocationStrategy),
    //         IDistributionStrategy(distributionStrategy),
    //         address(token),
    //         10 * 10 ** 18,
    //         metadata
    //     );

    //     uint256 poolId = _utilCreatePool(10 * 10 ** 18);

    //     assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
    //     assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
    //     assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    // }

    // function test_registerRecipients() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     // apply to the pool
    //     address recipientId = allo.registerRecipients(poolId, bytes(""));
    //     assertEq(recipientId, address(1));
    // }

    // function test_updatePoolMetadata() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     Metadata memory updatedMetadata = Metadata({protocol: 1, pointer: "updated metadata"});

    //     vm.expectEmit(true, false, false, true);
    //     emit PoolMetadataUpdated(poolId, updatedMetadata);

    //     // update the metadata
    //     vm.prank(owner);
    //     allo.updatePoolMetadata(poolId, updatedMetadata);

    //     // check that the metadata was updated
    //     Allo.Pool memory pool = _utilGetPoolInfo(poolId);
    //     Metadata memory poolMetadata = pool.metadata;

    //     assertEq(poolMetadata.protocol, updatedMetadata.protocol);
    //     assertEq(poolMetadata.pointer, updatedMetadata.pointer);
    // }

    // function testRevert_updatePoolMetadata_UNAUTHORIZED() public {
    //     uint256 poolId = _utilCreatePool(0);
    //     vm.expectRevert(Allo.UNAUTHORIZED.selector);

    //     vm.prank(makeAddr("not owner"));
    //     allo.updatePoolMetadata(poolId, metadata);
    // }

    // function test_fundPool() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     vm.expectEmit(true, false, false, true);
    //     emit PoolFunded(poolId, 9.9e18, 1e17);

    //     allo.fundPool(poolId, 10 * 10 ** 18, address(token));
    // }

    // function testRevert_fundPool_NOT_ENOUGH_FUNDS() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     vm.prank(makeAddr("broke chad"));
    //     vm.expectRevert(Allo.NOT_ENOUGH_FUNDS.selector);

    //     allo.fundPool(poolId, 0, address(token));
    // }

    // function test_allocate() public {
    //     uint256 poolId = _utilCreatePool(0);
    //     // allocate to the pool should not revert
    //     allo.allocate(poolId, bytes(""));
    // }

    // function test_batchAllocate() public {
    //     uint256[] memory poolIds = new uint256[](2);

    //     poolIds[0] = _utilCreatePool(0);

    //     address mockAllocation = address(new MockAllocation());
    //     address mockDistribution = address(new MockDistribution());
    //     vm.prank(owner);
    //     poolIds[1] = allo.createPool(
    //         identityId, mockAllocation, "0x", payable(mockDistribution), "0x", address(token), 0, metadata, members
    //     );

    //     bytes[] memory datas = new bytes[](2);
    //     datas[0] = bytes("data1");
    //     datas[1] = "data2";
    //     // allocate to the pool should not revert
    //     allo.batchAllocate(poolIds, datas);
    // }

    // function test_distribute() public {
    //     uint256 poolId = _utilCreatePool(0);
    //     // distribution to the pool should not revert
    //     address[] memory recipientIds = new address[](1);
    //     allo.distribute(poolId, recipientIds, bytes(""));
    // }

    // function test_updateRegistry() public {
    //     vm.expectEmit(true, false, false, false);
    //     address payable newRegistry = payable(makeAddr("new registry"));
    //     emit RegistryUpdated(address(registry));

    //     vm.prank(alloOwner);
    //     allo.updateRegistry(newRegistry);

    //     assertEq(address(allo.registry()), newRegistry);
    // }

    // function testRevert_updateRegistry_UNAUTHORIZED() public {
    //     address payable newRegistry = payable(makeAddr("new registry"));
    //     // expect revert from solady
    //     vm.expectRevert();

    //     vm.prank(makeAddr("anon"));
    //     allo.updateRegistry(newRegistry);
    // }

    // function test_updateTreasury() public {
    //     vm.expectEmit(true, false, false, false);
    //     address payable newTreasury = payable(makeAddr("new treasury"));
    //     emit TreasuryUpdated(treasury);

    //     vm.prank(alloOwner);
    //     allo.updateTreasury(newTreasury);

    //     assertEq(allo.treasury(), newTreasury);
    // }

    // function testRevert_updateTreasury_UNAUTHORIZED() public {
    //     address payable newTreasury = payable(makeAddr("new treasury"));

    //     // expect revert from solady
    //     vm.expectRevert();

    //     vm.prank(makeAddr("anon"));
    //     allo.updateTreasury(newTreasury);
    // }

    // function test_updateFee() public {
    //     vm.expectEmit(true, false, false, false);

    //     uint256 newFee = 1e17;
    //     emit FeePercentageUpdated(newFee);

    //     vm.prank(alloOwner);
    //     allo.updateFee(newFee);

    //     assertEq(allo.feePercentage(), newFee);
    // }

    // function testRevert_updateFee_UNAUTHORIZED() public {
    //     vm.expectRevert();

    //     vm.prank(makeAddr("anon"));
    //     allo.updateFee(2000);
    // }

    // function test_updateBaseFee() public {
    //     vm.expectEmit(true, false, false, false);

    //     uint256 newBaseFee = 1e17;
    //     emit BaseFeeUpdated(newBaseFee);

    //     vm.prank(alloOwner);
    //     allo.updateBaseFee(newBaseFee);
    // }

    // function test_updateBaseFee_UNAUTHORIZED() public {
    //     vm.expectRevert();

    //     vm.prank(makeAddr("anon"));
    //     allo.updateBaseFee(1e16);
    // }

    // function test_addToApprovedStrategies() public {
    //     assertFalse(allo.approvedStrategies(distributionStrategy));

    //     vm.prank(alloOwner);
    //     allo.addToApprovedStrategies(distributionStrategy);

    //     assertTrue(allo.approvedStrategies(distributionStrategy));
    // }

    // function testRevert_addToApprovedStrategies_UNAUTHORIZED() public {
    //     vm.expectRevert();
    //     vm.prank(makeAddr("anon"));
    //     allo.addToApprovedStrategies(distributionStrategy);
    // }

    // function test_removeFromApprovedStrategies() public {
    //     vm.prank(alloOwner);
    //     allo.addToApprovedStrategies(distributionStrategy);

    //     assertTrue(allo.approvedStrategies(distributionStrategy));

    //     vm.prank(alloOwner);
    //     allo.removeFromApprovedStrategies(distributionStrategy);
    //     assertFalse(allo.approvedStrategies(distributionStrategy));
    // }

    // function testRevert_removeFromApprovedStrategies_UNAUTHORIZED() public {
    //     vm.expectRevert();
    //     vm.prank(makeAddr("anon"));
    //     allo.addToApprovedStrategies(distributionStrategy);
    // }

    // function test_isPoolAdmin() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     assertTrue(allo.isPoolAdmin(poolId, owner));
    //     assertFalse(allo.isPoolAdmin(poolId, makeAddr("not admin")));
    // }

    // function test_isPoolManager() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     assertTrue(allo.isPoolManager(poolId, members[0]));
    //     assertFalse(allo.isPoolManager(poolId, makeAddr("not manager")));
    // }

    // function test_addPoolManager() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     assertFalse(allo.isPoolManager(poolId, makeAddr("not manager")));
    //     vm.prank(owner);
    //     allo.addPoolManager(poolId, makeAddr("not manager"));
    //     assertTrue(allo.isPoolManager(poolId, makeAddr("not manager")));
    // }

    // function test_removePoolManager() public {
    //     uint256 poolId = _utilCreatePool(0);

    //     assertTrue(allo.isPoolManager(poolId, members[0]));
    //     vm.prank(owner);
    //     allo.removePoolManager(poolId, members[0]);
    //     assertFalse(allo.isPoolManager(poolId, members[0]));
    // }
}
