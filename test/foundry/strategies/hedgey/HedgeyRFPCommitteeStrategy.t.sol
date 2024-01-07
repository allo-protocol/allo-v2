pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {HedgeyRFPCommitteeStrategy} from "../../../../contracts/strategies/_poc/hedgey/HedgeyRFPCommitteeStrategy.sol";
import {RFPSimpleStrategy} from "../../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";
// Internal libraries
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
// Test libraries
import {AlloSetup} from "../../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../../shared/RegistrySetup.sol";
import {EventSetup} from "../../shared/EventSetup.sol";
import {HedgeySetup} from "./HedgeySetup.sol";
import {MockERC20} from "../../../utils/MockERC20.sol";

contract HedgeyRFPCommitteeStrategyTest is Test, RegistrySetupFull, AlloSetup, HedgeySetup, EventSetup, Errors {
    // Events
    event Voted(address indexed recipientId, address voter);
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);
    event PlanCreated(
        uint256 indexed id,
        address indexed recipient,
        address indexed token,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 end,
        uint256 rate,
        uint256 period,
        address vestingAdmin,
        bool adminTransferOBO
    );
    event AdminAddressUpdated(address adminAddress, address sender);
    event AdminTransferOBOUpdated(bool adminTransferOBO, address sender);

    bool public useRegistryAnchor;
    bool public metadataRequired;

    address[] public allowedTokens;

    HedgeyRFPCommitteeStrategy public strategy;

    MockERC20 public token;
    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public poolMetadata;

    uint256 public poolId;

    uint256 public maxBid;

    uint256 public voteThreshold;

    // Hedgey Specific
    bool public adminTransferOBO;
    address public hedgeyContract;
    address public adminAddress;

    uint256 public constant ONE_MONTH_SECONDS = 2628000;

    struct TestStruct {
        uint256 a;
        uint256 b;
        uint256 c;
        bool d;
    }

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

        useRegistryAnchor = false;
        metadataRequired = true;

        maxBid = 1e18;

        voteThreshold = 2;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new HedgeyRFPCommitteeStrategy(address(allo()), "HedgeyRFPCommitteeStrategy");

        adminTransferOBO = true;
        hedgeyContract = address(vesting());
        adminAddress = address(pool_admin());

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                adminTransferOBO,
                hedgeyContract,
                adminAddress,
                voteThreshold,
                maxBid,
                useRegistryAnchor,
                metadataRequired
            ),
            address(token),
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        HedgeyRFPCommitteeStrategy testStrategy =
            new HedgeyRFPCommitteeStrategy(address(allo()), "HedgeyRFPCommitteeStrategy");
        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("HedgeyRFPCommitteeStrategy")));
    }

    function test_initialize() public {
        HedgeyRFPCommitteeStrategy testStrategy =
            new HedgeyRFPCommitteeStrategy(address(allo()), "HedgeyRFPCommitteeStrategy");
        vm.prank(address(allo()));
        testStrategy.initialize(
            1337,
            abi.encode(
                adminTransferOBO,
                hedgeyContract,
                adminAddress,
                voteThreshold,
                maxBid,
                useRegistryAnchor,
                metadataRequired
            )
        );
        assertEq(testStrategy.getPoolId(), 1337);
        assertEq(testStrategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(testStrategy.metadataRequired(), metadataRequired);
        assertEq(testStrategy.maxBid(), maxBid);
        assertEq(testStrategy.voteThreshold(), voteThreshold);

        assertEq(testStrategy.adminTransferOBO(), adminTransferOBO);
        assertEq(testStrategy.hedgeyContract(), hedgeyContract);
        assertEq(testStrategy.adminAddress(), adminAddress);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        HedgeyRFPCommitteeStrategy testStrategy =
            new HedgeyRFPCommitteeStrategy(address(allo()), "HedgeyRFPCommitteeStrategy");
        vm.startPrank(address(allo()));
        testStrategy.initialize(
            1337,
            abi.encode(
                adminTransferOBO,
                hedgeyContract,
                adminAddress,
                voteThreshold,
                maxBid,
                useRegistryAnchor,
                metadataRequired
            )
        );

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(
            1337,
            abi.encode(
                adminTransferOBO,
                hedgeyContract,
                adminAddress,
                voteThreshold,
                maxBid,
                useRegistryAnchor,
                metadataRequired
            )
        );
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        HedgeyRFPCommitteeStrategy testStrategy =
            new HedgeyRFPCommitteeStrategy(address(allo()), "HedgeyRFPCommitteeStrategy");
        vm.expectRevert(UNAUTHORIZED.selector);
        testStrategy.initialize(
            1337,
            abi.encode(
                adminTransferOBO,
                hedgeyContract,
                adminAddress,
                voteThreshold,
                maxBid,
                useRegistryAnchor,
                metadataRequired
            )
        );
    }

    function test_allocate() public {
        address recipientId = __register_setMilestones_allocate();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Accepted));
    }

    function test_allocate_reallocating() public {
        address recipientId = __register_recipient();
        address recipientId2 = __register_recipient2();

        __setMilestones();

        assertEq(strategy.votes(recipientId), 0);
        assertEq(strategy.votes(recipientId2), 0);

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_admin()));

        assertEq(strategy.votes(recipientId), 1);
        assertEq(strategy.votes(recipientId2), 0);
        assertEq(strategy.votedFor(address(pool_admin())), recipientId);

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId2), address(pool_admin()));

        assertEq(strategy.votes(recipientId), 0);
        assertEq(strategy.votes(recipientId2), 1);
        assertEq(strategy.votedFor(address(pool_admin())), recipientId2);
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_pool_manager"));
        strategy.allocate(abi.encode(recipientAddress()), recipient());
    }

    function testRevert_allocate_RECIPIENT_ALREADY_ACCEPTED() public {
        __register_setMilestones_allocate();
        vm.prank(address(allo()));
        vm.expectRevert(RECIPIENT_ALREADY_ACCEPTED.selector);
        strategy.allocate(abi.encode(randomAddress()), address(pool_admin()));
    }

    function test_distribute() public {
        _register_allocate_submit_distribute();
        assertEq(uint8(strategy.getMilestoneStatus(0)), uint8(IStrategy.Status.Accepted));
    }

    function test_change_admin_address() public {
        vm.prank(address(pool_admin()));
        vm.expectEmit(true, true, false, false);
        emit AdminAddressUpdated(address(pool_manager1()), address(pool_admin()));

        strategy.setAdminAddress(address(pool_manager1()));
        assertEq(strategy.adminAddress(), address(pool_manager1()));
    }

    function test_change_admin_transfer_obo() public {
        vm.prank(address(pool_admin()));
        vm.expectEmit(true, true, false, false);
        emit AdminTransferOBOUpdated(false, address(pool_admin()));

        strategy.setAdminTransferOBO(false);
        assertEq(strategy.adminTransferOBO(), false);
    }

    function test_withdraw() public {
        allo().fundPool(poolId, 1e18);
        vm.startPrank(pool_admin());
        strategy.setPoolActive(false);
        strategy.withdraw(address(token));
        assertEq(address(allo()).balance, 0);
    }

    function __register_recipient() internal returns (address recipientId) {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata, ONE_MONTH_SECONDS);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);

        assertEq(strategy.getRecipientLockupTerm(recipientAddress()), ONE_MONTH_SECONDS);
    }

    function __register_recipient2() internal returns (address recipientId) {
        address sender = makeAddr("recipient2");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata, ONE_MONTH_SECONDS * 2);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);

        assertEq(strategy.getRecipientLockupTerm(recipientAddress()), ONE_MONTH_SECONDS * 2);
    }

    function __setMilestones() internal {
        HedgeyRFPCommitteeStrategy.Milestone[] memory milestones = new HedgeyRFPCommitteeStrategy.Milestone[](1);
        HedgeyRFPCommitteeStrategy.Milestone memory milestone = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 1e18,
            milestoneStatus: IStrategy.Status.Pending
        });

        milestones[0] = milestone;

        vm.prank(address(pool_admin()));
        strategy.setMilestones(milestones);
    }

    function __register_setMilestones_allocate() internal returns (address recipientId) {
        recipientId = __register_recipient();
        __setMilestones();

        vm.expectEmit();
        emit Voted(recipientId, address(pool_admin()));

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_admin()));

        vm.expectEmit();
        emit Voted(recipientId, address(pool_manager1()));
        vm.expectEmit();
        emit Allocated(recipientId, 1e18, address(token), address(0));

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_manager1()));
    }

    function __register_setMilestones_allocate_submitUpcomingMilestone() internal returns (address recipientId) {
        recipientId = __register_setMilestones_allocate();
        vm.expectEmit();
        emit MilstoneSubmitted(0);
        vm.prank(recipient());
        strategy.submitUpcomingMilestone(Metadata({protocol: 1, pointer: "metadata"}));
    }

    function _register_allocate_submit_distribute() internal returns (address recipientId) {
        recipientId = __register_setMilestones_allocate_submitUpcomingMilestone();

        vm.expectEmit(true, false, false, true);
        emit PoolFunded(poolId, 9.9e19, 1e18);

        allo().fundPool(poolId, 10 * 10e18);

        vm.expectEmit(true, true, true, false);
        emit PlanCreated(
            1,
            recipientAddress(),
            address(token),
            1e18,
            block.timestamp,
            0,
            block.timestamp + ONE_MONTH_SECONDS + 1,
            1,
            1e18 / ONE_MONTH_SECONDS,
            address(pool_admin()),
            adminTransferOBO
        );

        vm.expectEmit(true, false, false, true);
        emit Distributed(recipientId, recipientAddress(), 1e18, pool_admin());

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }
}
