// SPDX-License Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
// Core contracts
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";

contract QVSimpleStrategyTest is QVBaseStrategyTest {
    event AllocatorAdded(address indexed allocator, address sender);
    event AllocatorRemoved(address indexed allocator, address sender);
    event VoiceCreditsUpdated(address indexed allocator, uint256 voiceCredits, address sender);

    uint256 public maxVoiceCreditsPerAllocator;

    function setUp() public override {
        maxVoiceCreditsPerAllocator = 100;
        super.setUp();
    }

    function _createStrategy() internal override returns (address payable) {
        return payable(address(new QVSimpleStrategy(address(allo()), "MockStrategy")));
    }

    function _initialize() internal override {
        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();
        qvSimpleStrategy().addAllocator(randomAddress());
    }

    function _createPoolWithCustomStrategy() internal override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            ),
            address(token),
            0 ether, // TODO: setup tests for failed transfers when a value is passed here.
            poolMetadata,
            pool_managers()
        );

        qvSimpleStrategy().addAllocator(randomAddress());
    }

    function test_initialize_maxVoiceCreditsPerAllocator() public virtual {
        assertEq(qvSimpleStrategy().maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);
    }

    function test_initialize_UNAUTHORIZED() public override {
        vm.startPrank(allo_owner());
        QVSimpleStrategy strategy = new QVSimpleStrategy(address(allo()), "MockStrategy");
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.stopPrank();
        vm.startPrank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public override {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        QVSimpleStrategy(_strategy).initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function testRevert_initialize_INVALID() public override {
        QVSimpleStrategy strategy = new QVSimpleStrategy(address(allo()), "MockStrategy");

        // when registrationStartTime is in the past
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        uint64(today() - 1),
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        // when registrationStartTime > registrationEndTime
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        uint64(weekAfterNext()),
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );

        // when allocationStartTime > allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        registrationEndTime,
                        uint64(oneMonthFromNow() + today()),
                        allocationEndTime
                    )
                )
            )
        );

        // when  registrationEndTime > allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        2,
                        registrationStartTime,
                        uint64(oneMonthFromNow() + today()),
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    function test_addAllocator() public {
        vm.startPrank(pool_manager1());
        address allocator = makeAddr("allocator");

        vm.expectEmit(false, false, false, true);
        emit AllocatorAdded(allocator, pool_manager1());

        qvSimpleStrategy().addAllocator(allocator);
    }

    function testRevert_addAllocator_UNAUTHORIZED() public {
        vm.startPrank(randomAddress());
        address allocator = makeAddr("allocator");

        vm.expectRevert(UNAUTHORIZED.selector);

        qvSimpleStrategy().addAllocator(allocator);
    }

    function test_removeAllocator() public {
        vm.startPrank(pool_manager1());
        address allocator = makeAddr("allocator");

        vm.expectEmit(false, false, false, true);
        emit AllocatorRemoved(allocator, pool_manager1());

        qvSimpleStrategy().removeAllocator(allocator);
    }

    function testRevert_removeAllocator_UNAUTHORIZED() public {
        vm.startPrank(randomAddress());
        address allocator = makeAddr("allocator");

        vm.expectRevert(UNAUTHORIZED.selector);

        qvSimpleStrategy().removeAllocator(allocator);
    }

    function test_isValidAllocator() public override {
        assertFalse(qvSimpleStrategy().isValidAllocator(address(0)));
        assertFalse(qvSimpleStrategy().isValidAllocator(address(123)));
        assertTrue(qvSimpleStrategy().isValidAllocator(randomAddress()));
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId = __register_reject_recipient();
        address allocator = makeAddr("allocator");

        vm.expectRevert(abi.encodeWithSelector(UNAUTHORIZED.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.startPrank(address(allo()));
        qvSimpleStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        qvSimpleStrategy().addAllocator(allocator);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.stopPrank();
        vm.startPrank(address(allo()));
        qvSimpleStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_tooManyVoiceCredits() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        qvSimpleStrategy().addAllocator(allocator);

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 400);

        vm.stopPrank();

        vm.startPrank(address(allo()));
        qvSimpleStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_noVoiceTokens() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();
        vm.startPrank(pool_manager1());
        qvSimpleStrategy().addAllocator(allocator);
        bytes memory allocateData = __generateAllocation(recipientId, 0);

        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        qvSimpleStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_voiceTokensMismatch() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        vm.warp(allocationStartTime + 10);

        qvSimpleStrategy().addAllocator(allocator);

        vm.expectRevert(INVALID.selector);

        vm.stopPrank();
        bytes memory allocateData = __generateAllocation(recipientId, 0);
        vm.startPrank(address(allo()));
        qvSimpleStrategy().allocate(allocateData, allocator);
    }

    function qvSimpleStrategy() internal view returns (QVSimpleStrategy) {
        return (QVSimpleStrategy(_strategy));
    }
}
