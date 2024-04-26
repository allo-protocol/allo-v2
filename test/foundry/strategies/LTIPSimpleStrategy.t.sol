pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {LTIPSimpleStrategy} from "../../../contracts/strategies/ltip-simple/LTIPSimpleStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
import {HedgeySetup} from "../shared/HedgeySetup.sol";
import {MockERC20} from "../../utils/MockERC20.sol";

contract LTIPSimpleStrategyTest is Test, RegistrySetupFull, AlloSetup, EventSetup, Errors {
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

    // TODO do we accept multiple tokens?
    address[] public allowedTokens;

    LTIPSimpleStrategy public strategy;

    MockERC20 public token;
    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public poolMetadata;

    uint256 public poolId;

    uint256 public voteThreshold;

    bool public registryGating;
    uint256 public allocationThreshold;
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;
    uint64 public distributionStartTime;
    uint64 public distributionEndTime;

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

        token = new MockERC20();
        token.mint(local(), mintAmount);
        token.mint(allo_owner(), mintAmount);
        token.mint(pool_admin(), mintAmount);
        token.approve(address(allo()), mintAmount);

        vm.prank(pool_admin());
        token.approve(address(allo()), mintAmount);

        useRegistryAnchor = false;
        metadataRequired = true;

        voteThreshold = 2;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy");

        // adminTransferOBO = true;
        // hedgeyContract = address(vesting());
        // adminAddress = address(pool_admin());

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                registryGating,
                metadataRequired,
                allocationThreshold,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                distributionStartTime,
                distributionEndTime
            ),
            address(token),
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        LTIPSimpleStrategy testStrategy = new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy");
        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("LTIPSimpleStrategy")));
    }

    function test_initialize() public {
        LTIPSimpleStrategy testStrategy = new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy");
        vm.prank(address(allo()));
        testStrategy.initialize(
            1337,
            abi.encode(
                registryGating,
                metadataRequired,
                allocationThreshold,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                distributionStartTime,
                distributionEndTime
            )
        );
        assertEq(testStrategy.getPoolId(), 1337);
        assertEq(testStrategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(testStrategy.metadataRequired(), metadataRequired);
        assertEq(testStrategy.allocationThreshold(), allocationThreshold);
        assertEq(testStrategy.registrationStartTime(), registrationStartTime);
        assertEq(testStrategy.registrationEndTime(), registrationEndTime);
        assertEq(testStrategy.allocationStartTime(), allocationStartTime);
        assertEq(testStrategy.allocationEndTime(), allocationEndTime);
        assertEq(testStrategy.distributionStartTime(), distributionStartTime);
        assertEq(testStrategy.distributionEndTime(), distributionEndTime);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        LTIPSimpleStrategy testStrategy = new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy");
        vm.startPrank(address(allo()));
        testStrategy.initialize(
            1337,
            abi.encode(
                registryGating,
                metadataRequired,
                allocationThreshold,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                distributionStartTime,
                distributionEndTime
            )
        );

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(
            1337,
            abi.encode(
                registryGating,
                metadataRequired,
                allocationThreshold,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                distributionStartTime,
                distributionEndTime
            )
        );
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        LTIPSimpleStrategy testStrategy = new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy");
        vm.expectRevert(UNAUTHORIZED.selector);
        testStrategy.initialize(
            1337,
            abi.encode(
                registryGating,
                metadataRequired,
                allocationThreshold,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                distributionStartTime,
                distributionEndTime
            )
        );
    }

    // function test_allocate() public {
    //     address recipientId = __register_setMilestones_allocate();
    //     IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
    //     assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Accepted));
    // }

    // function test_allocate_reallocating() public {
    //     address recipientId = __register_recipient();
    //     address recipientId2 = __register_recipient2();

    //     __setMilestones();

    //     assertEq(strategy.votes(recipientId), 0);
    //     assertEq(strategy.votes(recipientId2), 0);

    //     vm.prank(address(allo()));
    //     strategy.allocate(abi.encode(recipientId), address(pool_admin()));

    //     assertEq(strategy.votes(recipientId), 1);
    //     assertEq(strategy.votes(recipientId2), 0);
    //     assertEq(strategy.votedFor(address(pool_admin())), recipientId);

    //     vm.prank(address(allo()));
    //     strategy.allocate(abi.encode(recipientId2), address(pool_admin()));

    //     assertEq(strategy.votes(recipientId), 0);
    //     assertEq(strategy.votes(recipientId2), 1);
    //     assertEq(strategy.votedFor(address(pool_admin())), recipientId2);
    // }

    function testRevert_allocate_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_pool_manager"));
        strategy.allocate(abi.encode(recipientAddress()), recipient());
    }

    // function testRevert_allocate_RECIPIENT_ALREADY_ACCEPTED() public {
    //     __register_setMilestones_allocate();
    //     vm.prank(address(allo()));
    //     vm.expectRevert(RECIPIENT_ALREADY_ACCEPTED.selector);
    //     strategy.allocate(abi.encode(randomAddress()), address(pool_admin()));
    // }

    // function test_distribute() public {
    //     _register_allocate_submit_distribute();
    //     assertEq(uint8(strategy.getMilestoneStatus(0)), uint8(IStrategy.Status.Accepted));
    // }

    // function test_change_admin_address() public {
    //     vm.prank(address(pool_admin()));
    //     vm.expectEmit(true, true, false, false);
    //     emit AdminAddressUpdated(address(pool_manager1()), address(pool_admin()));

    //     strategy.setAdminAddress(address(pool_manager1()));
    //     assertEq(strategy.adminAddress(), address(pool_manager1()));
    // }

    // function test_change_admin_transfer_obo() public {
    //     vm.prank(address(pool_admin()));
    //     vm.expectEmit(true, true, false, false);
    //     emit AdminTransferOBOUpdated(false, address(pool_admin()));

    //     strategy.setAdminTransferOBO(false);
    //     assertEq(strategy.adminTransferOBO(), false);
    // }

    function test_withdraw() public {
        allo().fundPool(poolId, 1e18);
        vm.startPrank(pool_admin());
        strategy.setPoolActive(false);
        strategy.withdraw(address(token));
        assertEq(address(allo()).balance, 0);
    }

    // function __register_recipient() internal returns (address recipientId) {
    //     address sender = recipient();
    //     Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
    //     bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata, ONE_MONTH_SECONDS);
    //     vm.prank(address(allo()));
    //     recipientId = strategy.registerRecipient(data, sender);

    //     assertEq(strategy.getRecipientLockupTerm(recipientAddress()), ONE_MONTH_SECONDS);
    // }

    // function __register_recipient2() internal returns (address recipientId) {
    //     address sender = makeAddr("recipient2");
    //     Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

    //     bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata, ONE_MONTH_SECONDS * 2);
    //     vm.prank(address(allo()));
    //     recipientId = strategy.registerRecipient(data, sender);

    //     assertEq(strategy.getRecipientLockupTerm(recipientAddress()), ONE_MONTH_SECONDS * 2);
    // }
}
