pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {LTIPSimpleStrategy} from "../../../contracts/strategies/ltip-simple/LTIPSimpleStrategy.sol";
import {LTIPHedgeyStrategy} from "../../../contracts/strategies/ltip-hedgey/LTIPHedgeyStrategy.sol";
import {LTIPHedgeyGovernorStrategy} from
    "../../../contracts/strategies/ltip-hedgey-governor/LTIPHedgeyGovernorStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {HedgeySetup} from "../shared/HedgeySetup.sol";
import {MockERC20} from "../../utils/MockERC20.sol";

/// @notice interface paramters to call Governor contract and get votes at a specific block
interface IGovernor {
    function getVotes(address recipient, uint256 blockNumer) external returns (uint256 votingPower);
}

contract LTIPHedgeyGovernanceStrategyTest is
    Test,
    RegistrySetupFull,
    AlloSetup,
    HedgeySetup,
    StrategySetup,
    EventSetup,
    Errors
{
    // Events
    event VestingPlanCreated(address indexed recipientId, address vestingContract, uint256 tokenId);
    event AdminAddressUpdated(address adminAddress, address sender);
    event AdminTransferOBOUpdated(bool adminTransferOBO, address sender);

    // Errors
    error INSUFFICIENT_VOTES();

    // Storage
    address payable internal _strategy;
    MockERC20 public token;
    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public poolMetadata;
    uint256 public poolId;

    bool public registryGating;
    bool public metadataRequired;
    bool public useRegistryAnchor;

    uint256 public votingThreshold;
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;
    uint64 public reviewStartTime;
    uint64 public reviewEndTime;
    uint64 public distributionStartTime;
    uint64 public distributionEndTime;
    uint64 public vestingPeriod;

    uint256 public allocationAmount;

    // Hedgey Specific
    address public hedgeyContract;
    address public vestingAdmin;
    bool public adminTransferOBO;
    uint256 public cliff;
    uint256 public rate;
    uint256 public period;

    // Governor specific
    address public governorContract;
    uint256 public timepoint;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));
        __HedgeySetup();

        token = new MockERC20();
        token.mint(local(), mintAmount);
        token.mint(allo_owner(), mintAmount);
        token.mint(pool_admin(), mintAmount);
        token.approve(address(allo()), mintAmount);

        vm.prank(pool_admin());
        token.approve(address(allo()), mintAmount);

        registrationStartTime = uint64(today());
        registrationEndTime = uint64(nextWeek());
        reviewStartTime = uint64(nextWeek());
        reviewEndTime = uint64(weekAfterNext());
        allocationStartTime = uint64(weekAfterNext());
        allocationEndTime = uint64(oneMonthFromNow());
        vestingPeriod = uint64(oneMonthFromNow());
        distributionStartTime = uint64(oneMonthFromNow());
        distributionEndTime = uint64(oneMonthFromNow() + 7 days);

        metadataRequired = true;
        registryGating = true;
        useRegistryAnchor = true;

        allocationAmount = 1 ether;

        hedgeyContract = address(_vesting_);
        vestingAdmin = pool_admin();
        adminTransferOBO = true;
        cliff = oneMonthFromNow();
        rate = 1;
        period = 7 days;

        governorContract = makeAddr("governorContract");
        timepoint = block.number;

        votingThreshold = 20;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        _strategy = _createStrategy();
        _initialize();
    }

    function _createStrategy() internal virtual returns (address payable) {
        return payable(address(new LTIPHedgeyGovernorStrategy(address(allo()), "LTIPHedgeyGovernorStrategy")));
    }

    function _initialize() internal virtual {
        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();
        vm.stopPrank();
    }

    function _createPoolWithCustomStrategy() internal virtual {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                LTIPHedgeyGovernorStrategy.InitializeParamsGovernor(
                    governorContract,
                    timepoint,
                    LTIPHedgeyStrategy.InitializeParamsHedgey(
                        hedgeyContract,
                        vestingAdmin,
                        adminTransferOBO,
                        cliff,
                        rate,
                        period,
                        LTIPSimpleStrategy.InitializeParams(
                            registryGating,
                            metadataRequired,
                            votingThreshold,
                            registrationStartTime,
                            registrationEndTime,
                            reviewStartTime,
                            reviewEndTime,
                            allocationStartTime,
                            allocationEndTime,
                            distributionStartTime,
                            distributionEndTime,
                            vestingPeriod
                        )
                    )
                )
            ),
            address(token),
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        LTIPHedgeyGovernorStrategy testStrategy =
            new LTIPHedgeyGovernorStrategy(address(allo()), "LTIPHedgeyGovernorStrategy");
        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("LTIPHedgeyGovernorStrategy")));
    }

    function test_initialize() public {
        LTIPHedgeyGovernorStrategy testStrategy =
            new LTIPHedgeyGovernorStrategy(address(allo()), "LTIPHedgeyGovernorStrategy");
        vm.prank(address(allo()));

        testStrategy.initialize(
            1337,
            abi.encode(
                LTIPHedgeyGovernorStrategy.InitializeParamsGovernor(
                    governorContract,
                    timepoint,
                    LTIPHedgeyStrategy.InitializeParamsHedgey(
                        hedgeyContract,
                        vestingAdmin,
                        adminTransferOBO,
                        cliff,
                        rate,
                        period,
                        LTIPSimpleStrategy.InitializeParams(
                            registryGating,
                            metadataRequired,
                            votingThreshold,
                            registrationStartTime,
                            registrationEndTime,
                            reviewStartTime,
                            reviewEndTime,
                            allocationStartTime,
                            allocationEndTime,
                            distributionStartTime,
                            distributionEndTime,
                            vestingPeriod
                        )
                    )
                )
            )
        );

        assertEq(testStrategy.getPoolId(), 1337);
        assertEq(testStrategy.registryGating(), registryGating);
        assertEq(testStrategy.metadataRequired(), metadataRequired);
        assertEq(testStrategy.votingThreshold(), votingThreshold);
        assertEq(testStrategy.registrationStartTime(), registrationStartTime);
        assertEq(testStrategy.registrationEndTime(), registrationEndTime);
        assertEq(testStrategy.allocationStartTime(), allocationStartTime);
        assertEq(testStrategy.allocationEndTime(), allocationEndTime);
        assertEq(testStrategy.distributionStartTime(), distributionStartTime);
        assertEq(testStrategy.distributionEndTime(), distributionEndTime);
        assertEq(testStrategy.vestingPeriod(), vestingPeriod);

        assertEq(testStrategy.hedgeyContract(), hedgeyContract);
        assertEq(testStrategy.vestingAdmin(), vestingAdmin);
        assertEq(testStrategy.adminTransferOBO(), adminTransferOBO);

        assertEq(testStrategy.governorContract(), governorContract);
        assertEq(testStrategy.timepoint(), timepoint);
    }

    function test_revoke_votes() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        // Accept

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        // Allocate
        vm.warp(allocationStartTime + 10);

        vm.mockCall(governorContract, abi.encodeWithSelector(IGovernor.getVotes.selector), abi.encode(20));

        vm.startPrank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId, 10), pool_manager1());
        vm.stopPrank();

        assertEq(ltipStrategy().votes(recipientId), 10);
        assertEq(ltipStrategy().votesCasted(pool_manager1()), 10);
        assertEq(ltipStrategy().votesCastedFor(pool_manager1(), recipientId), 10);

        // Revoke
        vm.startPrank(address(pool_manager1()));
        ltipStrategy().revokeVotes(recipientId, 5);

        assertEq(ltipStrategy().votes(recipientId), 5);
        assertEq(ltipStrategy().votesCasted(pool_manager1()), 5);
        assertEq(ltipStrategy().votesCastedFor(pool_manager1(), recipientId), 5);

        // Can't underflow
        vm.expectRevert();
        ltipStrategy().revokeVotes(recipientId, 6);
        vm.stopPrank();
    }

    function test_voting_weights() public {
        address recipientId = __register_recipient_fund_pool();
        vm.warp(reviewStartTime + 10);

        // Accept

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        // Allocate
        vm.warp(allocationStartTime + 10);
        LTIPHedgeyGovernorStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);

        vm.mockCall(governorContract, abi.encodeWithSelector(IGovernor.getVotes.selector), abi.encode(20));

        vm.startPrank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId, 10), pool_manager1());

        //insufficient voting power
        vm.expectRevert();
        ltipStrategy().allocate(abi.encode(recipientId, 11), pool_manager1());

        // sufficient voting power
        vm.mockCall(governorContract, abi.encodeWithSelector(IGovernor.getVotes.selector), abi.encode(21));
        ltipStrategy().allocate(abi.encode(recipientId, 11), pool_manager1());
        vm.stopPrank();

        // Distribute
        vm.warp(distributionStartTime + 10);

        // any one can call distribute
        address anon = makeAddr("anon");

        vm.expectEmit(true, false, false, false);
        emit VestingPlanCreated(recipientId, hedgeyContract, 0);

        vm.expectEmit(true, false, false, false);
        emit Distributed(recipientId, recipient.recipientAddress, recipient.allocationAmount, anon);

        vm.prank(address(allo()));
        ltipStrategy().distribute(recipientIds, "", anon);

        LTIPHedgeyGovernorStrategy.VestingPlan memory plan = ltipStrategy().getVestingPlan(recipientId);
        assertEq(plan.vestingContract, hedgeyContract);
    }

    function test_distribute() public {
        address recipientId = __register_recipient_fund_pool();
        vm.warp(reviewStartTime + 10);

        // Accept

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        // Allocate
        vm.warp(allocationStartTime + 10);
        LTIPHedgeyGovernorStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);

        vm.mockCall(governorContract, abi.encodeWithSelector(IGovernor.getVotes.selector), abi.encode(20));

        vm.startPrank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId, 10), pool_manager1());
        ltipStrategy().allocate(abi.encode(recipientId, 10), pool_manager2());
        vm.stopPrank();

        // Distribute
        vm.warp(distributionStartTime + 10);

        // any one can call distribute
        address anon = makeAddr("anon");

        vm.expectEmit(true, false, false, false);
        emit VestingPlanCreated(recipientId, hedgeyContract, 0);

        vm.expectEmit(true, false, false, false);
        emit Distributed(recipientId, recipient.recipientAddress, recipient.allocationAmount, anon);

        vm.prank(address(allo()));
        ltipStrategy().distribute(recipientIds, "", anon);

        LTIPHedgeyGovernorStrategy.VestingPlan memory plan = ltipStrategy().getVestingPlan(recipientId);
        assertEq(plan.vestingContract, hedgeyContract);
    }

    function test_distribute_INSUFFICIENT_VOTES() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        // Accept

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        // Allocate
        vm.warp(allocationStartTime + 10);

        vm.startPrank(address(allo()));
        // sufficient voting power
        vm.mockCall(governorContract, abi.encodeWithSelector(IGovernor.getVotes.selector), abi.encode(11));
        ltipStrategy().allocate(abi.encode(recipientId, 11), pool_manager1());
        vm.stopPrank();

        // any one can call distribute
        address anon = makeAddr("anon");

        vm.expectRevert(INSUFFICIENT_VOTES.selector);

        vm.prank(address(allo()));
        ltipStrategy().distribute(recipientIds, "", anon);
    }

    function test_update_voting_block() public {
        vm.prank(pool_manager1());
        ltipStrategy().setTimepoint(100);
        assertEq(ltipStrategy().timepoint(), 100);
    }

    // function __generateRecipientWithoutId(bool _isUsingRegistryAnchor) internal virtual returns (bytes memory) {
    //     return __getEncodedData(_isUsingRegistryAnchor, recipient(), 1e18);
    // }

    // Using with ID because we assume that the recipient has a profile in the registry
    function __generateRecipientWithId(address _recipientId) internal virtual returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipient1(), allocationAmount, metadata);
    }

    function __register_recipient() internal virtual returns (address) {
        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(profile1_anchor());

        vm.prank(address(allo()));
        address recipientId = ltipStrategy().registerRecipient(data, profile1_member1());

        LTIPHedgeyGovernorStrategy.Recipient memory receipt = ltipStrategy().getRecipient(recipientId);

        return recipientId;
    }

    function __register_recipient_fund_pool() internal virtual returns (address) {
        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(profile1_anchor());

        vm.prank(address(allo()));
        address recipientId = ltipStrategy().registerRecipient(data, profile1_member1());

        LTIPHedgeyGovernorStrategy.Recipient memory receipt = ltipStrategy().getRecipient(recipientId);

        // Fund pool
        token.mint(pool_manager1(), 100e18);
        vm.startPrank(pool_manager1());
        token.approve(address(allo()), 999999999e18);

        allo().fundPool(poolId, 10 ether);
        vm.stopPrank();

        return recipientId;
    }

    function __register_recipient2() internal virtual returns (address) {
        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(profile2_anchor());

        vm.prank(address(allo()));
        address recipientId = ltipStrategy().registerRecipient(data, profile2_member1());

        LTIPHedgeyGovernorStrategy.Recipient memory receipt = ltipStrategy().getRecipient(recipientId);

        return recipientId;
    }

    function ltipStrategy() internal view returns (LTIPHedgeyGovernorStrategy) {
        return LTIPHedgeyGovernorStrategy(_strategy);
    }

    function __getEncodedData(bool _registryAnchor, address _recipientAddress, uint256 _allocationAmount)
        internal
        virtual
        returns (bytes memory data)
    {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
        data = abi.encode(_registryAnchor, _recipientAddress, _allocationAmount, metadata);
    }
}
