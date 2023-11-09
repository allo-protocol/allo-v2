// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {MicroGrantsStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract MicroGrantsStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    event Allocated(address indexed recipientId, IStrategy.Status status, address sender);

    MicroGrantsStrategy strategy;

    bool public useRegistryAnchor;

    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    uint256 public maxRequestedAmount;
    uint256 public approvalThreshold;

    Metadata public poolMetadata;
    uint256 public poolId;

    mapping(address => MicroGrantsStrategy.Recipient) internal _recipients;
    mapping(address => bool) public allocators;
    mapping(address => mapping(address => bool)) public allocated;
    mapping(address => mapping(IStrategy.Status => uint256)) public recipientAllocations;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        useRegistryAnchor = true;
        allocationStartTime = uint64(block.timestamp);
        allocationEndTime = uint64(block.timestamp + 1 days);
        maxRequestedAmount = 0;
        approvalThreshold = 0;

        strategy = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        MicroGrantsStrategy strategy_ = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");

        assertTrue(address(strategy_) != address(0));
        assertTrue(address(strategy_.getAllo()) == address(allo()));
        assertTrue(strategy_.getStrategyId() == keccak256(abi.encode("MicroGrantsStrategy")));
    }
}
