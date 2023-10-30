// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {TestStrategy} from "../../utils/TestStrategy.sol";
import {MockStrategy} from "../../utils/MockStrategy.sol";
import {MockERC20} from "../../utils/MockERC20.sol";
import {GasHelpers} from "../../utils/GasHelpers.sol";

contract AlloTest is Test, AlloSetup, RegistrySetupFull, Native, Errors, GasHelpers {
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);
    event TreasuryUpdated(address treasury);
    event PercentFeeUpdated(uint256 percentFee);
    event BaseFeeUpdated(uint256 baseFee);
    event RegistryUpdated(address registry);
    event StrategyApproved(address strategy);
    event StrategyRemoved(address strategy);

    error AlreadyInitialized();

    address public strategy;
    MockERC20 public token;

    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public metadata = Metadata({protocol: 1, pointer: "strategy pointer"});
    string public name;
    uint256 public nonce;

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

        strategy = address(new MockStrategy(address(allo())));

        vm.startPrank(allo_owner());
        allo().transferOwnership(local());
        vm.stopPrank();
    }

    function _utilCreatePool(uint256 _amount) internal returns (uint256) {
        vm.prank(pool_admin());
        return allo().createPoolWithCustomStrategy(
            poolProfile_id(), strategy, "0x", address(token), _amount, metadata, pool_managers()
        );
    }

    function test_initialize() public {
        Allo coreContract = new Allo();
        vm.expectEmit(true, false, false, true);

        emit RegistryUpdated(address(registry()));
        emit TreasuryUpdated(address(allo_treasury()));
        emit PercentFeeUpdated(1e16);
        emit BaseFeeUpdated(1e16);

        coreContract.initialize(
            address(allo_owner()), // _owner
            address(registry()), // _registry
            allo_treasury(), // _treasury
            1e16, // _percentFee
            1e15 // _baseFee
        );

        assertEq(address(coreContract.getRegistry()), address(registry()));
        assertEq(coreContract.getTreasury(), allo_treasury());
        assertEq(coreContract.getPercentFee(), 1e16);
        assertEq(coreContract.getBaseFee(), 1e15);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        vm.expectRevert("Initializable: contract is already initialized");

        allo().initialize(
            address(allo_owner()), // _owner
            address(registry()), // _registry
            allo_treasury(), // _treasury
            1e16, // _percentFee
            1e15 // _baseFee
        );
    }

    function test_createPool() public {
        startMeasuringGas("createPool");
        allo().addToCloneableStrategies(strategy);

        vm.expectEmit(true, true, false, false);
        emit PoolCreated(1, poolProfile_id(), IStrategy(strategy), NATIVE, 0, metadata);

        vm.prank(pool_admin());
        uint256 poolId = allo().createPool(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers());

        IAllo.Pool memory pool = allo().getPool(poolId);
        stopMeasuringGas();

        assertEq(pool.profileId, poolProfile_id());
        assertNotEq(address(pool.strategy), address(strategy));
    }

    function testRevert_createPool_NOT_APPROVED_STRATEGY() public {
        vm.expectRevert(NOT_APPROVED_STRATEGY.selector);
        vm.prank(pool_admin());
        allo().createPool(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers());
    }

    function testRevert_createPoolWithCustomStrategy_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(poolProfile_id(), address(0), "0x", NATIVE, 0, metadata, pool_managers());
    }

    function testRevert_createPoolWithCustomStrategy_IS_APPROVED_STRATEGY() public {
        allo().addToCloneableStrategies(strategy);
        vm.expectRevert(IS_APPROVED_STRATEGY.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers());
    }

    function testRevert_createPool_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().createPoolWithCustomStrategy(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers());
    }

    function testRevert_createPool_poolId_MISMATCH() public {
        TestStrategy testStrategy = new TestStrategy(makeAddr("allo"), "TestStrategy");
        testStrategy.setPoolId(0);

        vm.expectRevert(MISMATCH.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(
            poolProfile_id(), address(testStrategy), "0x", NATIVE, 0, metadata, pool_managers()
        );
    }

    function testRevert_createPool_allo_MISMATCH() public {
        TestStrategy testStrategy = new TestStrategy(makeAddr("allo"), "TestStrategy");
        testStrategy.setAllo(address(0));

        vm.expectRevert(MISMATCH.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(
            poolProfile_id(), address(testStrategy), "0x", NATIVE, 0, metadata, pool_managers()
        );
    }

    function testRevert_createPool_ZERO_ADDRESS() public {
        address[] memory poolManagers = new address[](1);
        poolManagers[0] = address(0);
        vm.expectRevert(ZERO_ADDRESS.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, poolManagers);
    }

    function test_createPoolWithBaseFee() public {
        uint256 baseFee = 1e17;

        allo().updateBaseFee(baseFee);

        vm.expectEmit(true, false, false, true);
        emit BaseFeePaid(1, baseFee);

        vm.deal(address(pool_admin()), 1e18);

        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy{value: 1e17}(
            poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers()
        );
    }

    function testRevert_createPool_withBaseFee_NOT_ENOUGH_FUNDS() public {
        uint256 baseFee = 1e17;
        allo().updateBaseFee(baseFee);

        vm.expectRevert(NOT_ENOUGH_FUNDS.selector);
        _utilCreatePool(0);
    }

    function test_createPool_WithAmount() public {
        vm.expectEmit(true, false, false, true);
        emit PoolCreated(1, poolProfile_id(), IStrategy(strategy), address(token), 10 * 10 ** 18, metadata);

        uint256 poolId = _utilCreatePool(10 * 10 ** 18);

        IAllo.Pool memory pool = allo().getPool(poolId);

        assertEq(pool.profileId, poolProfile_id());
        assertEq(address(pool.strategy), strategy);
    }

    function test_updatePoolMetadata() public {
        uint256 poolId = _utilCreatePool(0);

        Metadata memory updatedMetadata = Metadata({protocol: 1, pointer: "updated metadata"});

        vm.expectEmit(true, false, false, true);
        emit PoolMetadataUpdated(poolId, updatedMetadata);

        // update the metadata
        vm.prank(pool_admin());
        allo().updatePoolMetadata(poolId, updatedMetadata);

        // check that the metadata was updated
        Allo.Pool memory pool = allo().getPool(poolId);
        Metadata memory poolMetadata = pool.metadata;

        assertEq(poolMetadata.protocol, updatedMetadata.protocol);
        assertEq(poolMetadata.pointer, updatedMetadata.pointer);
    }

    function testRevert_updatePoolMetadata_UNAUTHORIZED() public {
        uint256 poolId = _utilCreatePool(0);
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(makeAddr("not owner"));
        allo().updatePoolMetadata(poolId, metadata);
    }

    function test_updateRegistry() public {
        vm.expectEmit(true, false, false, false);
        address payable newRegistry = payable(makeAddr("new registry"));
        emit RegistryUpdated(newRegistry);

        allo().updateRegistry(newRegistry);

        assertEq(address(allo().getRegistry()), newRegistry);
    }

    function testRevert_updateRegistry_UNAUTHORIZED() public {
        address payable newRegistry = payable(makeAddr("new registry"));
        // expect revert from solady
        vm.expectRevert();

        vm.prank(makeAddr("not owner"));
        allo().updateRegistry(newRegistry);
    }

    function testRevert_updateRegistry_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        allo().updateRegistry(address(0));
    }

    function test_updateTreasury() public {
        vm.expectEmit(true, false, false, false);
        address payable newTreasury = payable(makeAddr("new treasury"));
        emit TreasuryUpdated(newTreasury);

        allo().updateTreasury(newTreasury);

        assertEq(allo().getTreasury(), newTreasury);
    }

    function testRevert_updateTreasury_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        allo().updateTreasury(payable(address(0)));
    }

    function testRevert_updateTreasury_UNAUTHORIZED() public {
        address payable newTreasury = payable(makeAddr("new treasury"));

        // expect revert from solady
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo().updateTreasury(newTreasury);
    }

    function test_updatePercentFee() public {
        vm.expectEmit(true, false, false, false);

        uint256 newFee = 1e17;
        emit PercentFeeUpdated(newFee);

        allo().updatePercentFee(newFee);

        assertEq(allo().getPercentFee(), newFee);
    }

    function test_updatePercentFee_INVALID_FEE() public {
        vm.expectRevert(INVALID_FEE.selector);
        allo().updatePercentFee(2 * 1e18);
    }

    function testRevert_updatePercentFee_UNAUTHORIZED() public {
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo().updatePercentFee(2000);
    }

    function test_updateBaseFee() public {
        vm.expectEmit(true, false, false, false);

        uint256 newBaseFee = 1e17;
        emit BaseFeeUpdated(newBaseFee);

        allo().updateBaseFee(newBaseFee);

        assertEq(allo().getBaseFee(), newBaseFee);
    }

    function test_updateBaseFee_UNAUTHORIZED() public {
        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo().updateBaseFee(1e16);
    }

    function test_addToCloneableStrategies() public {
        address _strategy = makeAddr("strategy");
        assertFalse(allo().isCloneableStrategy(_strategy));
        allo().addToCloneableStrategies(_strategy);
        assertTrue(allo().isCloneableStrategy(_strategy));
    }

    function testRevert_addToCloneableStrategies_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        allo().addToCloneableStrategies(address(0));
    }

    function testRevert_addToCloneableStrategies_UNAUTHORIZED() public {
        vm.expectRevert();
        vm.prank(makeAddr("anon"));
        address _strategy = makeAddr("strategy");
        allo().addToCloneableStrategies(_strategy);
    }

    function test_removeFromCloneableStrategies() public {
        address _strategy = makeAddr("strategy");
        allo().addToCloneableStrategies(_strategy);
        assertTrue(allo().isCloneableStrategy(_strategy));
        allo().removeFromCloneableStrategies(_strategy);
        assertFalse(allo().isCloneableStrategy(_strategy));
    }

    function testRevert_removeFromCloneableStrategies_UNAUTHORIZED() public {
        address _strategy = makeAddr("strategy");
        vm.expectRevert();
        vm.prank(makeAddr("anon"));
        allo().removeFromCloneableStrategies(_strategy);
    }

    function test_addPoolManager() public {
        uint256 poolId = _utilCreatePool(0);

        assertFalse(allo().isPoolManager(poolId, makeAddr("add manager")));
        vm.prank(pool_admin());
        allo().addPoolManager(poolId, makeAddr("add manager"));
        assertTrue(allo().isPoolManager(poolId, makeAddr("add manager")));
    }

    function testRevert_addPoolManager_UNAUTHORIZED() public {
        uint256 poolId = _utilCreatePool(0);
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().addPoolManager(poolId, makeAddr("add manager"));
    }

    function testRevert_addPoolManager_ZERO_ADDRESS() public {
        uint256 poolId = _utilCreatePool(0);
        vm.expectRevert(ZERO_ADDRESS.selector);
        vm.prank(pool_admin());
        allo().addPoolManager(poolId, address(0));
    }

    function test_removePoolManager() public {
        uint256 poolId = _utilCreatePool(0);

        assertTrue(allo().isPoolManager(poolId, pool_manager1()));
        vm.prank(pool_admin());
        allo().removePoolManager(poolId, pool_manager1());
        assertFalse(allo().isPoolManager(poolId, pool_manager1()));
    }

    function testRevert_removePoolManager_UNAUTHORIZED() public {
        uint256 poolId = _utilCreatePool(0);
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().removePoolManager(poolId, makeAddr("add manager"));
    }

    function test_recoverFunds() public {
        address user = makeAddr("recipient");

        vm.deal(address(allo()), 1e18);
        assertEq(address(allo()).balance, 1e18);
        assertEq(user.balance, 0);

        allo().recoverFunds(NATIVE, user);

        assertEq(address(allo()).balance, 0);
        assertNotEq(user.balance, 0);
    }

    function test_recoverFunds_ERC20() public {
        uint256 amount = 100;
        token.mint(address(allo()), amount);
        address user = address(0xBBB);

        assertEq(token.balanceOf(address(allo())), amount, "amount");
        assertEq(token.balanceOf(user), 0, "amount");

        allo().recoverFunds(address(token), user);

        assertEq(token.balanceOf(address(allo())), 0, "amount");
        assertEq(token.balanceOf(user), amount, "amount");
    }

    function testRevert_recoverFunds_UNAUTHORIZED() public {
        vm.expectRevert();
        vm.prank(makeAddr("anon"));
        allo().recoverFunds(address(0), makeAddr("recipient"));
    }

    function test_registerRecipient() public {
        uint256 poolId = _utilCreatePool(0);

        // apply to the pool
        allo().registerRecipient(poolId, bytes(""));
    }

    function test_batchRegisterRecipient() public {
        uint256[] memory poolIds = new uint256[](2);

        poolIds[0] = _utilCreatePool(0);

        address mockStrategy = address(new MockStrategy(address(allo())));
        vm.prank(pool_admin());
        poolIds[1] = allo().createPoolWithCustomStrategy(
            poolProfile_id(), mockStrategy, "0x", address(token), 0, metadata, pool_managers()
        );

        bytes[] memory datas = new bytes[](2);
        datas[0] = bytes("data1");
        datas[1] = "data2";
        // batch register to the pool should not revert
        allo().batchRegisterRecipient(poolIds, datas);
    }

    function testRevert_batchRegister_MISMATCH() public {
        uint256[] memory poolIds = new uint256[](2);

        poolIds[0] = _utilCreatePool(0);

        address mockStrategy = address(new MockStrategy(address(allo())));
        vm.prank(pool_admin());
        poolIds[1] = allo().createPoolWithCustomStrategy(
            poolProfile_id(), mockStrategy, "0x", address(token), 0, metadata, pool_managers()
        );

        bytes[] memory datas = new bytes[](1);
        datas[0] = bytes("data1");

        vm.expectRevert(MISMATCH.selector);

        allo().batchRegisterRecipient(poolIds, datas);
    }

    function test_fundPool() public {
        uint256 poolId = _utilCreatePool(0);

        vm.expectEmit(true, false, false, true);
        emit PoolFunded(poolId, 9.9e19, 1e18);

        allo().fundPool(poolId, 10 * 10e18);
    }

    function testRevert_fundPool_NOT_ENOUGH_FUNDS() public {
        uint256 poolId = _utilCreatePool(0);

        vm.prank(makeAddr("broke chad"));
        vm.expectRevert(NOT_ENOUGH_FUNDS.selector);

        allo().fundPool(poolId, 0);
    }

    function test_allocate() public {
        uint256 poolId = _utilCreatePool(0);
        // allocate to the pool should not revert
        allo().allocate(poolId, bytes(""));
    }

    function test_batchAllocate() public {
        uint256[] memory poolIds = new uint256[](2);

        poolIds[0] = _utilCreatePool(0);

        address mockStrategy = address(new MockStrategy(address(allo())));
        vm.prank(pool_admin());
        poolIds[1] = allo().createPoolWithCustomStrategy(
            poolProfile_id(), mockStrategy, "0x", address(token), 0, metadata, pool_managers()
        );

        bytes[] memory datas = new bytes[](2);
        datas[0] = bytes("data1");
        datas[1] = "data2";
        // allocate to the pool should not revert
        allo().batchAllocate(poolIds, datas);
    }

    function testRevert_batchAllocate_MISMATCH() public {
        uint256[] memory poolIds = new uint256[](2);

        poolIds[0] = _utilCreatePool(0);

        address mockStrategy = address(new MockStrategy(address(allo())));
        vm.prank(pool_admin());
        poolIds[1] = allo().createPoolWithCustomStrategy(
            poolProfile_id(), mockStrategy, "0x", address(token), 0, metadata, pool_managers()
        );

        bytes[] memory datas = new bytes[](1);
        datas[0] = bytes("data1");

        vm.expectRevert(MISMATCH.selector);

        allo().batchAllocate(poolIds, datas);
    }

    function test_distribute() public {
        uint256 poolId = _utilCreatePool(0);
        // distribution to the pool should not revert
        address[] memory recipientIds = new address[](1);
        allo().distribute(poolId, recipientIds, bytes(""));
    }

    function test_isPoolAdmin() public {
        uint256 poolId = _utilCreatePool(0);

        assertTrue(allo().isPoolAdmin(poolId, pool_admin()));
        assertFalse(allo().isPoolAdmin(poolId, makeAddr("not admin")));
    }

    function test_isPoolManager() public {
        uint256 poolId = _utilCreatePool(0);

        assertTrue(allo().isPoolManager(poolId, pool_manager1()));
        assertFalse(allo().isPoolManager(poolId, makeAddr("not manager")));
    }

    function test_getStartegy() public {
        uint256 poolId = _utilCreatePool(0);

        assertEq(address(allo().getStrategy(poolId)), strategy);
    }
}
