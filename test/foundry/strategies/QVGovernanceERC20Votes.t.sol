// SPDX-License Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

// External Libraries
import "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
import {MockERC20Vote} from "../../utils/MockERC20Vote.sol";
import {MockERC20} from "../../utils/MockERC20.sol";

// Core contracts
import {QVGovernanceERC20Votes} from "../../../contracts/strategies/_poc/qv-governance/QVGovernanceERC20Votes.sol";

contract QVGovernanceERC20VotesTest is QVBaseStrategyTest {
    IVotes public govToken;
    uint256 public timestamp;

    function setUp() public override {
        govToken = IVotes(address(new MockERC20Vote()));
        timestamp = block.timestamp;
        super.setUp();
    }

    function _createStrategy() internal override returns (address payable) {
        return payable(address(new QVGovernanceERC20Votes(address(allo()), "MockStrategy")));
    }

    function qvGovStrategy() internal view returns (QVGovernanceERC20Votes) {
        return (QVGovernanceERC20Votes(_strategy));
    }

    function _initialize() internal override {
        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();
    }

    function _createPoolWithCustomStrategy() internal override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(govToken),
                    timestamp,
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
    }

    function test_isValidAllocator() public override {
        assertFalse(qvGovStrategy().isValidAllocator(address(123)));
        assertTrue(qvGovStrategy().isValidAllocator(randomAddress()));
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public override {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        QVGovernanceERC20Votes(_strategy).initialize(
            poolId,
            abi.encode(
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(govToken),
                    timestamp,
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

    function test_initilize_QVGovernance() public {
        assertEq(address(govToken), address(qvGovStrategy().govToken()));
        assertEq(timestamp, qvGovStrategy().timestamp());
    }

    function testRevert_initialize_noGovToken() public {
        QVGovernanceERC20Votes strategy = new QVGovernanceERC20Votes(address(allo()), "MockStrategy");
        MockERC20 noGovToken = new MockERC20();
        // when no valid governance token is passes

        vm.expectRevert();
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(noGovToken),
                    timestamp,
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
        QVGovernanceERC20Votes strategy = new QVGovernanceERC20Votes(address(allo()), "MockStrategy");

        // when registrationStartTime is in the past
        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(govToken),
                    timestamp,
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
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(govToken),
                    timestamp,
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
        vm.stopPrank();
        vm.startPrank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(govToken),
                    timestamp,
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
                QVGovernanceERC20Votes.InitializeParamsGov(
                    address(govToken),
                    timestamp,
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

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient();
        address allocator = randomAddress();

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.startPrank(address(allo()));
        qvGovStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_tooManyVoiceCredits() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4000);

        vm.startPrank(address(allo()));
        qvGovStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_noVoiceTokens() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();
        bytes memory allocateData = __generateAllocation(recipientId, 0);

        vm.expectRevert(INVALID.selector);
        vm.startPrank(address(allo()));
        qvGovStrategy().allocate(allocateData, allocator);
    }
}
