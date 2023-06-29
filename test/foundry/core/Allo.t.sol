pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {TestUtilities} from "../utils/TestUtilities.sol";

import "../../../contracts/interfaces/IAllocationStrategy.sol";
import "../../../contracts/interfaces/IDistributionStrategy.sol";

import {MockAllocation} from "../utils/MockAllocation.sol";
import {MockDistribution} from "../utils/MockDistribution.sol";
import {MockToken} from "../utils/MockToken.sol";

contract AlloTest is Test {
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        address allocationStrategy,
        address distributionStrategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    event PoolClosed(uint256 indexed poolId);

    event TreasuryUpdated(address treasury);

    event FeeUpdated(uint256 fee);

    event RegistryUpdated(address registry);

    Allo public allo;
    Registry public registry;

    address public admin;
    address public alloOwner;
    address public owner;
    address public member1;
    address public member2;
    address[] public members;
    address payable public treasury;

    address public allocationStrategy;
    address public distributionStrategy;
    address public token;

    Metadata public metadata;
    string public name;
    uint256 public nonce;

    bytes32 public identityId;

    function setUp() public {
        allo = new Allo();
        alloOwner = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        owner = makeAddr("owner");

        member1 = makeAddr("member1");
        member2 = makeAddr("member2");

        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Identity";
        nonce = 2;

        registry = new Registry();
        allo.initialize(address(registry), treasury, 1e16);
        // Note: OZ v5 will require this.
        // allo.transferOwnership(owner);

        members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        treasury = payable(makeAddr("treasury"));
        allo.updateTreasury(treasury);

        distributionStrategy = address(new MockDistribution());
        allocationStrategy = address(new MockAllocation());
        MockToken mockToken = new MockToken();
        token = address(mockToken);
        mockToken.mint(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, 1000000 * 10 ** 18);
        identityId = registry.createIdentity(nonce, name, metadata, owner, members);
    }

    function _utilCreatePool(uint256 _amount) internal returns (uint256) {
        vm.prank(owner);
        return allo.createPool(identityId, allocationStrategy, payable(distributionStrategy), token, _amount, metadata);
    }

    function _utilGetPoolInfo(uint256 poolId) internal view returns (Allo.Pool memory) {
        (
            bytes32 _identityId,
            IAllocationStrategy _allocationStrategy,
            IDistributionStrategy _distributionStrategy,
            Metadata memory _metadata
        ) = allo.pools(poolId);

        Allo.Pool memory pool = Allo.Pool({
            identityId: _identityId,
            allocationStrategy: _allocationStrategy,
            distributionStrategy: _distributionStrategy,
            metadata: _metadata
        });

        return pool;
    }

    function test_initialize() public {
        Allo coreContract = new Allo();
        vm.expectEmit(true, false, false, true);
        emit RegistryUpdated(address(registry));
        emit TreasuryUpdated(treasury);
        emit FeeUpdated(1e16);

        coreContract.initialize(address(registry), treasury, 1e16);
    }

    function test_createPoolWithCloneWithApprovedAllocationStrategy() public {
        vm.prank(alloOwner);
        allo.addToApprovedStrategies(allocationStrategy);

        vm.expectEmit(true, true, false, false);
        emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

        vm.prank(owner);
        uint256 poolId = allo.createPoolWithClone(
            identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata
        );

        assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
        assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
        assertNotEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    }

    function test_createPoolWithCloneWithApprovedDistributionStrategy() public {
        vm.prank(alloOwner);
        allo.addToApprovedStrategies(distributionStrategy);

        vm.expectEmit(true, true, false, false);
        emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

        vm.prank(owner);
        uint256 poolId = allo.createPoolWithClone(
            identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata
        );

        assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
        assertNotEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
        assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    }

    function test_createPoolWithCloneWithoutApprovedStrategies() public {
        vm.expectEmit(true, true, false, true);
        emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

        vm.prank(owner);
        uint256 poolId = allo.createPoolWithClone(
            identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata
        );

        assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
        assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
        assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    }

    function test_createPool() public {
        vm.expectEmit(true, true, false, true);
        emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

        uint256 poolId = _utilCreatePool(0);

        assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
        assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
        assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    }

    function testRevert_createPool_UNAUTHORIZED() public {
        vm.prank(makeAddr("not owner"));
        vm.expectRevert(Allo.UNAUTHORIZED.selector);

        allo.createPool(identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);
    }

    function testRevert_createPoolWithUsedAllocationStrategy_STRATEGY_ALREADY_USED() public {
        vm.prank(alloOwner);
        allo.addToUsedStrategies(allocationStrategy);

        vm.expectRevert(Allo.STRATEGY_ALREADY_USED.selector);
        _utilCreatePool(0);
    }

    function testRevert_createPoolWithUsedDistributionStrategy_STRATEGY_ALREADY_USED() public {
        vm.prank(alloOwner);
        allo.addToUsedStrategies(distributionStrategy);

        vm.expectRevert(Allo.STRATEGY_ALREADY_USED.selector);
        _utilCreatePool(0);
    }

    function test_createPoolWithTokens() public {
        vm.expectEmit(true, false, false, true);
        emit PoolCreated(
            1, identityId, allocationStrategy, payable(distributionStrategy), token, 10 * 10 ** 18, metadata
        );

        uint256 poolId = _utilCreatePool(10 * 10 ** 18);

        assertEq(_utilGetPoolInfo(poolId).identityId, identityId);
        assertEq(address(_utilGetPoolInfo(poolId).distributionStrategy), distributionStrategy);
        assertEq(address(_utilGetPoolInfo(poolId).allocationStrategy), allocationStrategy);
    }
 
    function test_applyToPool() public {
        uint256 poolId = _utilCreatePool(0);

        // apply to the pool
        uint256 applicationId = allo.applyToPool(poolId, bytes(""));
        assertEq(applicationId, 1);
    }

    function test_updatePoolMetadata() public {
        uint256 poolId = _utilCreatePool(0);

        Metadata memory updatedMetadata = Metadata({protocol: 1, pointer: "updated metadata"});

        vm.expectEmit(true, false, false, true);
        emit PoolMetadataUpdated(poolId, updatedMetadata);

        // update the metadata
        vm.prank(owner);
        allo.updatePoolMetadata(poolId, updatedMetadata);

        // check that the metadata was updated
        Allo.Pool memory pool = _utilGetPoolInfo(poolId);
        Metadata memory poolMetadata = pool.metadata;

        assertEq(poolMetadata.protocol, updatedMetadata.protocol);
        assertEq(poolMetadata.pointer, updatedMetadata.pointer);
    }

    function testRevert_updatePoolMetadata_UNAUTHORIZED() public {
        uint256 poolId = _utilCreatePool(0);
        vm.expectRevert(Allo.UNAUTHORIZED.selector);

        vm.prank(makeAddr("not owner"));
        allo.updatePoolMetadata(poolId, metadata);
    }

    function test_fundPool() public {
        uint256 poolId = _utilCreatePool(0);

        vm.expectEmit(true, false, false, true);
        emit PoolFunded(poolId, 9.9e18, 1e17);

        allo.fundPool(poolId, 10 * 10 ** 18, token);
    }

    function testRevert_fundPool_NOT_ENOUGH_FUNDS() public {
        uint256 poolId = _utilCreatePool(0);

        vm.prank(makeAddr("broke chad"));
        vm.expectRevert(Allo.NOT_ENOUGH_FUNDS.selector);

        allo.fundPool(poolId, 0, token);
    }

    function test_allocate() public {
        uint256 poolId = _utilCreatePool(0);
        // allocate to the pool should not revert
        allo.allocate(poolId, bytes(""));
    }

    function test_distribute() public {
        uint256 poolId = _utilCreatePool(0);
        // distribution to the pool should not revert
        allo.distribute(poolId, bytes(""));
    }

    function test_updateRegistry() public {
        vm.expectEmit(true, false, false, false);
        address payable newRegistry = payable(makeAddr("new registry"));
        emit RegistryUpdated(address(registry));

        vm.prank(alloOwner);
        allo.updateRegistry(newRegistry);

        assertEq(address(allo.registry()), newRegistry);
    }

    function testRevert_updateRegistry_UNAUTHORIZED() public {
        address payable newRegistry = payable(makeAddr("new registry"));
        // expect revert from solady
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo.updateRegistry(newRegistry);
    }

    function test_updateTreasury() public {
        vm.expectEmit(true, false, false, false);
        address payable newTreasury = payable(makeAddr("new treasury"));
        emit TreasuryUpdated(treasury);

        vm.prank(alloOwner);
        allo.updateTreasury(newTreasury);

        assertEq(allo.treasury(), newTreasury);
    }

    function testRevert_updateTreasury_UNAUTHORIZED() public {
        address payable newTreasury = payable(makeAddr("new treasury"));

        // expect revert from solady
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo.updateTreasury(newTreasury);
    }

    function test_updateFee() public {
        vm.expectEmit(true, false, false, false);

        uint256 newFee = 1e17;
        emit FeeUpdated(newFee);

        vm.prank(alloOwner);
        allo.updateFee(newFee);

        assertEq(allo.feePercentage(), newFee);
    }

    function testRevert_updateFee_UNAUTHORIZED() public {
        uint24 newFee = 2000;
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo.updateFee(newFee);
    }

    function test_addToApprovedStrategies() public {
        assertFalse(allo.approvedStrategies(distributionStrategy));
        assertFalse(allo.usedStrategies(distributionStrategy));

        vm.prank(alloOwner);
        allo.addToApprovedStrategies(distributionStrategy);

        assertTrue(allo.approvedStrategies(distributionStrategy));
        assertTrue(allo.usedStrategies(distributionStrategy));
    }

    function testRevert_addToApprovedStrategies_UNAUTHORIZED() public {
        vm.expectRevert();
        vm.prank(makeAddr("anon"));
        allo.addToApprovedStrategies(distributionStrategy);
    }

    function test_removeFromApprovedStrategies() public {
        vm.prank(alloOwner);
        allo.addToApprovedStrategies(distributionStrategy);

        assertTrue(allo.approvedStrategies(distributionStrategy));
        assertTrue(allo.usedStrategies(distributionStrategy));

        vm.prank(alloOwner);
        allo.removeFromApprovedStrategies(distributionStrategy);
        assertFalse(allo.approvedStrategies(distributionStrategy));
        assertTrue(allo.usedStrategies(distributionStrategy));
    }

    function testRevert_removeFromApprovedStrategies_UNAUTHORIZED() public {
        vm.expectRevert();
        vm.prank(makeAddr("anon"));
        allo.addToApprovedStrategies(distributionStrategy);
    }

    function test_addToUsedStrategies() public {
        assertFalse(allo.usedStrategies(distributionStrategy));

        vm.prank(alloOwner);
        allo.addToUsedStrategies(distributionStrategy);

        assertTrue(allo.usedStrategies(distributionStrategy));
    }

    function test_addToUsedStrategies_UNAUTHORIZED() public {
        vm.expectRevert();
        vm.prank(makeAddr("anon"));
        allo.addToUsedStrategies(distributionStrategy);
    }
}
