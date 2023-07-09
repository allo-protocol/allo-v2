pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {SplitterDistributionStrategy} from
    "../../../../../contracts/strategies/distribution/Splitter/SplitterDistributionStrategy.sol";
import {Allo} from "../../../../../contracts/core/Allo.sol";
import {Registry} from "../../../../../contracts/core/Registry.sol";
import {Metadata} from "../../../../../contracts/core/libraries/Metadata.sol";
import {TestUtilities} from "../../../utils/TestUtilities.sol";
import "../../../../../contracts/interfaces/IAllocationStrategy.sol";
import "../../../../../contracts/interfaces/IDistributionStrategy.sol";

import {MockAllocation} from "../../../utils/MockAllocation.sol";
import {MockDistribution} from "../../../utils/MockDistribution.sol";
import {MockToken} from "../../../utils/MockToken.sol";

contract SplitterDistributionStrategyTest is Test {
    event Initialized(address allo, bytes32 identityId, uint256 indexed poolId, address token, bytes data);
    event PayoutsDistributed(
        uint256[] applicationIds, IDistributionStrategy.PayoutSummary[] payoutSummary, address sender
    );
    event PoolFundingIncreased(uint256 amount);

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
    bool public identityRequired;
    bool public initialized;

    SplitterDistributionStrategy public splitter;

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
        allo.initialize(address(registry), treasury, 1e16, 0);
        // Note: OZ v5 will require this.
        // allo.transferOwnership(owner);

        members = new address[](3);
        members[0] = member1;
        members[1] = member2;

        members[2] = owner;

        treasury = payable(makeAddr("treasury"));
        allo.updateTreasury(treasury);

        distributionStrategy = address(new MockDistribution());
        allocationStrategy = address(new MockAllocation());
        MockToken mockToken = new MockToken();
        token = address(mockToken);
        mockToken.mint(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, 1000000 * 10 ** 18);
        identityId = registry.createIdentity(nonce, name, metadata, owner, members);
        splitter = new SplitterDistributionStrategy();
        initialized = false;
    }

    function test_initialize() public {}

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {}

    function test_distribute() public {
        vm.prank(address(allo));
    }

    function testRevert_distribute_UNAUTHORIZED() public {}

    function testRevert_distribute_PAYOUT_NOT_READY() public {}

    function testRevert_distribute_ALREADY_DISTRIBUTED() public {}

    function test_poolFunded() public {}

    function testRevert_poolFunded_UNAUTHORIZED() public {}

    function testRevert_poolFunded_PAYOUT_FINALIZED() public {}

    function test_recieve() public {}

    function test_recieve_UNAUTHORIZED() public {}
}
