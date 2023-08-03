pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {IAllo} from "../../../contracts/core/Allo.sol";
import {Allo} from "../../../contracts/core/Allo.sol";
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {QVGovernanceERC20Votes} from "../../../contracts/strategies/qv-governance/QVGovernanceERC20Votes.sol";
import {MockERC20} from "../../utils/MockERC20.sol";

contract QVGovernanceERC20VotesTest is Test {
    struct InitializationData {
        address govToken;
        uint256 timestamp;
        uint256 reviewThreshold;
        bool registryGating;
        bool metadataRequired;
        uint256 registrationStartTime;
        uint256 registrationEndTime;
        uint256 allocationStartTime;
        uint256 allocationEndTime;
    }

    Allo public allo;
    QVGovernanceERC20Votes public strategy;
    MockERC20 public token;

    function setUp() public {
        allo = new Allo();
        // InitializationData memory data = InitializationData(address(allo), 0, 0, false, false, 0, 0, 0, 0);

        token = new MockERC20();
        // strategy = new QVGovernanceERC20Votes(address(0), "QVGovernanceERC20Votes");
        // strategy.initialize(0, abi.encode(data));
    }

    function test_initialize() public {}

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {}

    function test_reviewRecipients() public {}

    function testRevert_reviewRecipients_INVALID() public {}

    function testRevert_reviewRecipients_RECIPIENT_ERROR() public {}

    function test_isValidAllocator() public {}

    function test_allocate() public {}

    function testRevert_allocate_INVALID() public {}

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {}

    function testRevert_allocate_INSUFFICIENT_VOICE_CREDITS() public {}
}
