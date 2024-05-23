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
import {StrategySetup} from "../shared/StrategySetup.sol";
import {HedgeySetup} from "../shared/HedgeySetup.sol";
import {MockERC20} from "../../utils/MockERC20.sol";

contract LTIPSimpleStrategyTest is Test, RegistrySetupFull, AlloSetup, StrategySetup, EventSetup, Errors {
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
    event Reviewed(address indexed recipientId, IStrategy.Status status, address sender);
    event RecipientStatusUpdated(
        address indexed recipientId, uint256 applicationId, IStrategy.Status status, address sender
    );

    // Errors

    error REVIEW_NOT_ACTIVE();

    // TODO do we accept multiple tokens?
    address[] public allowedTokens;

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

    // Hedgey Specific
    bool public adminTransferOBO;
    address public hedgeyContract;
    address public adminAddress;

    uint256 public constant ONE_MONTH_SECONDS = 2628000;

    // struct TestStruct {
    //     uint256 a;
    //     uint256 b;
    //     uint256 c;
    //     bool d;
    // }

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

        registrationStartTime = uint64(today());
        registrationEndTime = uint64(nextWeek());
        reviewStartTime = uint64(nextWeek());
        reviewEndTime = uint64(weekAfterNext());
        allocationStartTime = uint64(weekAfterNext());
        allocationEndTime = uint64(oneMonthFromNow());
        vestingPeriod = uint64(oneMonthFromNow());

        metadataRequired = true;
        registryGating = true;
        useRegistryAnchor = true;

        votingThreshold = 2;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        _strategy = _createStrategy();
        _initialize();
    }

    function _createStrategy() internal virtual returns (address payable) {
        return payable(address(new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy")));
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
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        LTIPSimpleStrategy testStrategy = new LTIPSimpleStrategy(address(allo()), "LTIPSimpleStrategy");
        vm.startPrank(address(allo()));
        testStrategy.initialize(
            1337,
            abi.encode(
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
        );

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(
            1337,
            abi.encode(
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
        );
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        address recipientId = __register_recipient();

        LTIPSimpleStrategy.Recipient memory receipt = ltipStrategy().getRecipient(recipientId);
        assertEq(receipt.useRegistryAnchor, useRegistryAnchor);
        assertEq(receipt.recipientAddress, recipient1());
        assertEq(receipt.metadata.pointer, "metadata");
        assertEq(receipt.metadata.protocol, 1);
    }

    function test_reviewRecipients_reject() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Rejected;

        vm.expectEmit(true, false, false, false);
        emit Reviewed(recipientId, IStrategy.Status.Rejected, pool_admin());

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Rejected), uint8(recipient.recipientStatus));
    }

    function test_reviewRecipients_accept() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Accepted;

        vm.expectEmit(true, false, false, false);
        emit Reviewed(recipientId, IStrategy.Status.Accepted, pool_admin());

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Accepted), uint8(recipient.recipientStatus));
    }

    function test_reviewRecipients_UNAUTHORIZED() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Rejected;

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(pool_notAManager());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);
    }

    function test_reviewRecipients_REVIEW_INACTIVE() public {
        address recipientId = __register_recipient();
        vm.warp(reviewEndTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Canceled;

        vm.expectRevert(REVIEW_NOT_ACTIVE.selector);
        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);
    }

    function test_reviewRecipients_RECIPIENT_ERROR() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Canceled;

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientIds[0]));
        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Pending), uint8(recipient.recipientStatus));
    }

    function test_allocate() public {
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

        vm.expectEmit(true, false, false, false);
        emit Voted(recipientId, pool_manager1());

        vm.prank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager1());

        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Accepted), uint8(recipient.recipientStatus));

        uint256 votes = ltipStrategy().votes(recipientId);
        assertEq(votes, 1);
    }

    function test_allocate_reallocate() public {
        address recipientId = __register_recipient();
        address recipientId2 = __register_recipient2();
        vm.warp(reviewStartTime + 10);

        // Accept

        address[] memory recipientIds = new address[](2);
        recipientIds[0] = recipientId;
        recipientIds[1] = recipientId2;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](2);
        Statuses[0] = IStrategy.Status.Accepted;
        Statuses[1] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        ltipStrategy().reviewRecipients(recipientIds, Statuses);

        // Allocate
        vm.warp(allocationStartTime + 10);

        // First vote on recipientId
        vm.expectEmit(true, false, false, false);
        emit Voted(recipientId, pool_manager1());

        vm.prank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager1());

        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Accepted), uint8(recipient.recipientStatus));

        uint256 votes = ltipStrategy().votes(recipientId);
        assertEq(votes, 1);

        // Second vote on recipientId2
        vm.expectEmit(true, false, false, false);
        emit Voted(recipientId2, pool_manager1());

        vm.prank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId2), pool_manager1());

        LTIPSimpleStrategy.Recipient memory recipient2 = ltipStrategy().getRecipient(recipientId2);
        assertEq(uint8(IStrategy.Status.Accepted), uint8(recipient2.recipientStatus));

        // Allocation is now set to recipientId2
        uint256 votes2 = ltipStrategy().votes(recipientId2);
        assertEq(votes2, 1);

        uint256 votesRecipientId = ltipStrategy().votes(recipientId);
        assertEq(votesRecipientId, 0);
    }

    function test_allocate_voting_threshold() public {
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
        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);

        vm.expectEmit(true, false, false, false);
        emit Voted(recipientId, pool_manager1());

        vm.startPrank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager1());

        vm.expectEmit();
        emit Voted(recipientId, address(pool_manager2()));
        vm.expectEmit();
        emit Allocated(recipientId, recipient.allocationAmount, address(token), address(0));

        ltipStrategy().allocate(abi.encode(recipientId), pool_manager2());

        uint256 votes = ltipStrategy().votes(recipientId);
        assertEq(votes, 2);
    }

    function test_allocate_UNAUTHORIZED() public {
        address recipientId = __register_recipient();
        // Allocate
        vm.warp(allocationStartTime + 10);

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(pool_notAManager());
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager1());

        uint256 votes = ltipStrategy().votes(recipientId);
        assertEq(votes, 0);
    }

    function test_allocate_RECIPIENT_NOT_ACCEPTED() public {
        address recipientId = __register_recipient();
        // Allocate
        vm.warp(allocationStartTime + 10);

        vm.expectRevert(RECIPIENT_NOT_ACCEPTED.selector);

        vm.prank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager1());

        uint256 votes = ltipStrategy().votes(recipientId);
        assertEq(votes, 0);
    }


    function testRevert_allocate_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_pool_manager"));
        ltipStrategy().allocate(abi.encode(recipientAddress()), recipient());
    }

    function test_distribute() public {
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
        LTIPSimpleStrategy.Recipient memory recipient = ltipStrategy().getRecipient(recipientId);

        vm.startPrank(address(allo()));
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager1());
        ltipStrategy().allocate(abi.encode(recipientId), pool_manager2());

        // Distribute
        vm.warp(distributionStartTime + 10);

        // any one can call distribute
        address anon = makeAddr("anon");

        vm.expectEmit(true, false, false, false);
        emit Distributed(recipientId, recipient.recipientAddress, recipient.allocationAmount, anon);
        ltipStrategy().distribute(recipientIds, "", anon);
    }


    function test_distribute_RECIPIENT_NOT_ACCEPTED() public {
        address recipientId = __register_recipient();
        vm.warp(reviewStartTime + 10);

        // Accept

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory Statuses = new IStrategy.Status[](1);
        Statuses[0] = IStrategy.Status.Accepted;

        // Distribute
        vm.warp(distributionStartTime + 10);

        // any one can call distribute
        address anon = makeAddr("anon");

        vm.expectRevert(RECIPIENT_NOT_ACCEPTED.selector); 
        vm.prank(address(allo()));
        ltipStrategy().distribute(recipientIds, "", anon);
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
        ltipStrategy().setPoolActive(false);
        ltipStrategy().withdraw(address(token));
        assertEq(address(allo()).balance, 0);
    }

    // function __generateRecipientWithoutId(bool _isUsingRegistryAnchor) internal virtual returns (bytes memory) {
    //     return __getEncodedData(_isUsingRegistryAnchor, recipient(), 1e18);
    // }

    // Using with ID because we assume that the recipient has a profile in the registry
    function __generateRecipientWithId(address _recipientId) internal virtual returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipient1(), metadata);
    }

    function __register_recipient() internal virtual returns (address) {
        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(profile1_anchor());

        vm.prank(address(allo()));
        address recipientId = ltipStrategy().registerRecipient(data, profile1_member1());

        LTIPSimpleStrategy.Recipient memory receipt = ltipStrategy().getRecipient(recipientId);
        assertTrue(receipt.useRegistryAnchor);

        return recipientId;
    }

    function __register_recipient2() internal virtual returns (address) {
        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(profile2_anchor());

        vm.prank(address(allo()));
        address recipientId = ltipStrategy().registerRecipient(data, profile2_member1());

        LTIPSimpleStrategy.Recipient memory receipt = ltipStrategy().getRecipient(recipientId);
        assertTrue(receipt.useRegistryAnchor);

        return recipientId;
    }

    function ltipStrategy() internal view returns (LTIPSimpleStrategy) {
        return LTIPSimpleStrategy(_strategy);
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
