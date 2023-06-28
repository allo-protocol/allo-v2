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

// todo:
contract AlloTest is Test {
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        address allocationStrategy,
        address payable distributionStrategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount);

    event PoolClosed(uint256 indexed poolId);

    event TreasuryUpdated(address treasury);

    event FeeUpdated(uint256 fee);

    event RegistryUpdated(address registry);

    Allo allo;
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
        allo.initialize(address(registry), treasury, 1000);
        // Note: OZ v5 will requrie this.
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

    /// @notice Helper function to create a pool
    /// @param _amount The amount of tokens to fund the pool with
    /// @param fundPool Whether or not to fund the pool
    function createPoolHelper(uint256 _amount, bool fundPool) internal returns (uint256 poolId) {
        vm.prank(owner);
        if (fundPool) {
            poolId =
                allo.createPool(identityId, allocationStrategy, payable(distributionStrategy), token, _amount, metadata);
        } else {
            poolId = allo.createPool(identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);
        }
    }

    /// @notice Helper function to get pool info from mapping
    /// @param poolId The id of the pool to get info for
    function getPoolInfoHelper(uint256 poolId) public view returns (Allo.Pool memory) {
        (
            bytes32 _identityId,
            IAllocationStrategy _allocationStrategy,
            IDistributionStrategy _distributionStrategy,
            Metadata memory _metadata
        ) = allo.pools(poolId);

        Allo.Pool memory pool;
        pool.identityId = _identityId;
        pool.allocationStrategy = _allocationStrategy;
        pool.distributionStrategy = _distributionStrategy;
        pool.metadata = _metadata;

        return pool;
    }

    /// @notice Test creating a pool with no tokens
    function test_createPool() public {
        vm.expectEmit(true, true, false, false);
        emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

        uint256 poolId = createPoolHelper(0, false);

        assertEq(getPoolInfoHelper(poolId).identityId, identityId);
        assertEq(address(getPoolInfoHelper(poolId).distributionStrategy), distributionStrategy);
        assertEq(address(getPoolInfoHelper(poolId).allocationStrategy), allocationStrategy);
    }

    // Invoke createPoolWithClone -> create clones (only allocation)
    // function test_createPoolWithClone_allocation() public {
    //     vm.prank(owner);
    //     allo.addToApprovedStrategies(allocationStrategy);
    //     emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

    //     vm.prank(owner);
    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata, true, false
    //     );

    //     assertEq(getPoolInfoHelper(poolId).identityId, identityId);
    //     assertEq(address(getPoolInfoHelper(poolId).distributionStrategy), distributionStrategy);
    //     assertNotEq(address(getPoolInfoHelper(poolId).allocationStrategy), allocationStrategy);
    // }

    // Invoke createPoolWithClone -> create clones (only distribution)
    // function test_createPoolWithClone_distribution() public {
    //     vm.prank(owner);
    //     allo.addToApprovedStrategies(distributionStrategy);
    //     emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata, false, true
    //     );

    //     assertEq(getPoolInfoHelper(poolId).identityId, identityId);
    //     assertNotEq(address(getPoolInfoHelper(poolId).distributionStrategy), distributionStrategy);
    //     assertEq(address(getPoolInfoHelper(poolId).allocationStrategy), allocationStrategy);
    // }

    // Invoke createPoolWithClone -> create clones (both allocation + distribution)
    // function test_createPoolWithClone_both() public {
    //     vm.prank(owner);
    //     emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata, true, true
    //     );

    //     assertEq(getPoolInfoHelper(poolId).identityId, identityId);
    //     assertNotEq(address(getPoolInfoHelper(poolId).distributionStrategy), distributionStrategy);
    //     assertNotEq(address(getPoolInfoHelper(poolId).allocationStrategy), allocationStrategy);
    // }

    // Invoke createPoolWithClone -> set both flags as false // same createPool directly (no clones)
    // function test_createPoolWithClone_both_false() public {
    //     vm.prank(owner);
    //     emit PoolCreated(1, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

    //     uint256 poolId = allo.createPoolWithClone(
    //         identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata, false, false
    //     );

    //     assertEq(getPoolInfoHelper(poolId).identityId, identityId);
    //     assertNotEq(address(getPoolInfoHelper(poolId).distributionStrategy), distributionStrategy);
    //     assertNotEq(address(getPoolInfoHelper(poolId).allocationStrategy), allocationStrategy);
    // }

    /// @notice Invoke createPool with used strategy -> revert
    function testRevert_createPoolWithUsedStrategy() public {
        vm.prank(alloOwner);
        allo.addToUsedStrategies(allocationStrategy);

        vm.expectRevert(Allo.STRATEGY_ALREADY_USED.selector);
        createPoolHelper(0, false);
    }

    // Invoke createPool with approved strategy -> revert
    function testRevert_createPoolWithUnapprovedStrategy() public {
        vm.prank(owner);
        vm.expectRevert(Allo.STRATEGY_NOT_APPROVED.selector);
        allo.createPoolWithClone(
            identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata, true, true
        );
    }

    /// @notice Test creating a pool with tokens
    function test_createPoolWithTokens() public {
        vm.expectEmit(true, false, false, true);
        emit PoolCreated(
            1, identityId, allocationStrategy, payable(distributionStrategy), token, 10 * 10 ** 18, metadata
        );

        uint256 poolId = createPoolHelper(10 * 10 ** 18, true);

        assertEq(getPoolInfoHelper(poolId).identityId, identityId);
        assertEq(address(getPoolInfoHelper(poolId).distributionStrategy), distributionStrategy);
        assertEq(address(getPoolInfoHelper(poolId).allocationStrategy), allocationStrategy);
    }

    /// @notice Test reverting creating a pool with no tokens
    function testRevert_createPool_NO_ACCESS_TO_ROLE() public {
        vm.prank(makeAddr("not owner"));
        vm.expectRevert(Allo.NO_ACCESS_TO_ROLE.selector);

        allo.createPool(identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);
    }

    /// @notice Test updating the metadata of a pool
    function test_updatePoolMetadata() public {
        uint256 poolId = createPoolHelper(0, false);
        vm.prank(owner);

        // update the metadata
        allo.updatePoolMetadata(poolId, Metadata({protocol: 1, pointer: "updated metadata"}));

        // check that the metadata was updated
        Allo.Pool memory pool = getPoolInfoHelper(poolId);
        Metadata memory poolMetadata = pool.metadata;

        assertEq(poolMetadata.protocol, 1);
        assertEq(poolMetadata.pointer, "updated metadata");
    }

    /// @notice Test reverting updating the metadata of a pool with bad actor
    function testRevert_updatePoolMetadata_NO_ACCESS_TO_ROLE() public {
        uint256 poolId = createPoolHelper(0, false);
        vm.expectRevert(Allo.NO_ACCESS_TO_ROLE.selector);

        vm.prank(makeAddr("not owner"));
        allo.updatePoolMetadata(poolId, metadata);
    }

    /// @notice Test applying to a pool
    function test_applyToPool() public {
        // Todo:
    }

    /// @notice Test funding a pool
    /// @dev This is also tested in test_createPoolWithTokens
    // function test_fundPool() public {
    //     vm.expectEmit(true, false, false, true);

    //     uint256 poolId = createPoolHelper(10 * 10 ** 18, true);
    //     emit PoolFunded(poolId, 10 * 10 ** 18);

    //     assertEq(getPoolInfoHelper(poolId).identityId, identityId);
    // }

    /// @notice Test reverting funding a pool for insufficient funds
    /// @dev This is also tested in test_createPoolWithTokens
    function testRevert_fundPool_NOT_ENOUGH_FUNDS() public {
        uint256 poolId = createPoolHelper(0, false);

        vm.prank(makeAddr("broke chad"));
        vm.expectRevert(Allo.NOT_ENOUGH_FUNDS.selector);

        allo.fundPool(poolId, 0, token);
    }

    /// @notice Test allocating a pool
    function test_allocate() public {
        // Todo:
    }

    /// @notice Test distribute
    function test_distribute() public {
        // Todo:
    }

    /// @notice Test updating registry address
    function test_updateRegistry() public {
        vm.expectEmit(true, false, false, false);
        address payable newRegistry = payable(makeAddr("new registry"));
        emit RegistryUpdated(address(registry));

        vm.prank(alloOwner);
        allo.updateRegistry(newRegistry);

        assertEq(address(allo.registry()), newRegistry);
    }

    /// @notice Test reverting updating registry address
    function testRevert_updateRegistry_UNAUTHORIZED() public {
        address payable newRegistry = payable(makeAddr("new registry"));
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo.updateRegistry(newRegistry);
    }

    /// @notice Test updating the treasury address
    function test_updateTreasury() public {
        vm.expectEmit(true, false, false, false);
        address payable newTreasury = payable(makeAddr("new treasury"));
        emit TreasuryUpdated(treasury);

        vm.prank(alloOwner);
        allo.updateTreasury(newTreasury);

        assertEq(allo.treasury(), newTreasury);
    }

    /// @notice Test reverting updating the treasury address
    function testRevert_updateTreasury_UNAUTHORIZED() public {
        address payable newTreasury = payable(makeAddr("new treasury"));
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo.updateTreasury(newTreasury);
    }

    /// @notice Test updating the fee
    // function test_updateFee() public {
    //     vm.expectEmit(true, false, false, false);
    //     uint256 newFee = 1e16;
    //     emit FeeUpdated(newFee);

    //     vm.prank(owner);
    //     allo.updateFee(newFee);

    //     assertEq(allo.feePercentage(), newFee);
    // }

    /// @notice Test reverting updating the fee
    function testRevert_updateFee_UNAUTHORIZED() public {
        uint24 newFee = 2000;
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo.updateFee(newFee);
    }
}
