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

    Allo allo;
    Registry public registry;

    address public admin;
    address public owner;
    address public member1;
    address public member2;
    address[] public members;
    address public notAMember;
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
        owner = makeAddr("owner");

        member1 = makeAddr("member1");
        member2 = makeAddr("member2");

        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Identity";
        nonce = 2;

        registry = new Registry();
        allo.initialize(address(registry));

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

    /// @notice Test creating a pool with no tokens
    function test_createPool() public {
        vm.expectEmit(true, true, false, false);
        emit PoolCreated(0, identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);
        vm.prank(owner);

        uint256 poolId =
            allo.createPool(identityId, allocationStrategy, payable(distributionStrategy), token, 0, metadata);

        assertEq(allo.getPoolInfo(poolId).identityId, identityId);
    }

    /// @notice Test creating a pool with tokens
    function test_createPoolWithTokens() public {
        vm.expectEmit(true, false, false, true);
        emit PoolCreated(
            0, identityId, allocationStrategy, payable(distributionStrategy), token, 10 * 10 ** 18, metadata
        );
        vm.prank(owner);

        uint256 poolId = allo.createPool(
            identityId, allocationStrategy, payable(distributionStrategy), token, 10 * 10 ** 18, metadata
        );

        assertEq(allo.getPoolInfo(poolId).identityId, identityId);
    }

    // function testRevert_createPool_NO_ACCESS_TO_ROLE() public {
    //     bytes32 identityId = registry.createIdentity(nonce, name, metadata, owner, members);
    //     allo.createPool(identityId, allocationStrategy, distributionStrategy, token, 0, metadata);

    //     vm.expectRevert(Allo.NO_ACCESS_TO_ROLE.selector);

    //     vm.prank(member1);
    //     allo.createPool(identityId, allocationStrategy, distributionStrategy, token, 0, metadata);
    // }

    // /// @notice Test updating the metadata of a pool
    // function test_updatePoolMetadata() public {
    //     // update the metadata
    //     allo.updatePoolMetadata(1, Metadata(1, "test metadata"));

    //     // check that the metadata was updated
    //     Allo.Pool memory pool = allo.getPoolInfo(1);
    //     Metadata memory poolMetadata = pool.metadata;

    //     assertEq(poolMetadata.protocol, 1);
    //     assertEq(poolMetadata.pointer, "test metadata");
    // }

    // function testRevert_updatePoolMetadata_NO_ACCESS_TO_ROLE() public {
    //     // update the metadata
    //     allo.updatePoolMetadata(1, Metadata(1, "test metadata"));

    //     vm.expectRevert(Allo.NO_ACCESS_TO_ROLE.selector);

    //     vm.prank(owner);
    //     allo.updatePoolMetadata(1, Metadata(1, "test metadata"));
    // }

    // /// @notice Test applying to a pool
    // function test_applyToPool() public {
    //     // Todo:
    // }

    // /// @notice Test funding a pool
    // /// @dev This is also tested in test_createPoolWithTokens
    // function test_fundPool() public {
    //     // Todo:
    // }

    // /// @notice Test funding a pool
    // /// @dev This is also tested in test_createPoolWithTokens
    // function testRevert_fundPool_NOT_ENOUGH_FUNDS() public {
    //     // Todo:
    // }

    // /// @notice Test allocating a pool
    // function test_allocate() public {
    //     // Todo:
    // }

    // /// @notice Test finalizing a pool
    // function test_finalize() public {
    //     // Todo:
    // }

    // /// @notice Test distribute
    // function test_distribute() public {
    //     // Todo:
    // }

    // /// @notice Test updating the treasury address
    // function test_updateTreasury() public {
    //     // Todo:
    // }

    // /// @notice Test updating the fee
    // function test_updateFee() public {
    //     // Todo:
    // }
}
