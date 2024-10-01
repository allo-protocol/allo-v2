// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockBaseStrategy} from "test/smock/MockMockBaseStrategy.sol";
import {IBaseStrategy} from "strategies/IBaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract BaseStrategy is Test {
    MockMockBaseStrategy baseStrategy;
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        baseStrategy = new MockMockBaseStrategy(address(0));
    }

    function test___BaseStrategy_initShouldCallOnlyAllo(uint256 _poolId) external {
        vm.assume(_poolId != 0);
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        baseStrategy.call___BaseStrategy_init(_poolId);
    }

    function test___BaseStrategy_initRevertWhen_PoolIdIsZero(uint256 _currentPoolId, uint256 _poolId) external {
        vm.assume(_currentPoolId != 0);
        baseStrategy.mock_call__checkOnlyAllo();

        baseStrategy.set__poolId(_currentPoolId);

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        baseStrategy.call___BaseStrategy_init(_poolId);
    }

    function test___BaseStrategy_initRevertWhen_PoolIdArgumentIsZero() external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_INVALID_POOL_ID.selector);

        baseStrategy.call___BaseStrategy_init(0);
    }

    function test___BaseStrategy_initShouldSetPoolId(uint256 _poolId) external {
        vm.assume(_poolId != 0);
        baseStrategy.mock_call__checkOnlyAllo();

        baseStrategy.call___BaseStrategy_init(_poolId);

        // It should set poolId
        assertEq(baseStrategy.getPoolId(), _poolId);
    }

    function test_IncreasePoolAmountShouldCallOnlyAllo(uint256 _amount) external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        baseStrategy.increasePoolAmount(_amount);
    }

    function test_IncreasePoolAmountShouldCall_beforeIncreasePoolAmount(uint256 _amount) external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call _beforeIncreasePoolAmount
        baseStrategy.expectCall__beforeIncreasePoolAmount(_amount);

        baseStrategy.increasePoolAmount(_amount);
    }

    function test_IncreasePoolAmountShouldAddAmountToPoolAmount(uint256 _previousAmount, uint256 _amount) external {
        vm.assume(_amount < type(uint256).max - _previousAmount);
        baseStrategy.mock_call__checkOnlyAllo();
        baseStrategy.set__poolAmount(_previousAmount);

        baseStrategy.increasePoolAmount(_amount);

        // It should add amount to poolAmount
        assertEq(baseStrategy.getPoolAmount(), _previousAmount + _amount);
    }

    function test_IncreasePoolAmountShouldCall_afterIncreasePoolAmount(uint256 _amount) external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call _afterIncreasePoolAmount
        baseStrategy.expectCall__afterIncreasePoolAmount(_amount);

        baseStrategy.increasePoolAmount(_amount);
    }

    function test_WithdrawWhenTokenIsNotPoolToken(
        address _poolToken,
        address _token,
        uint256 _amount,
        address _recipient
    ) external {
        vm.assume(_token != NATIVE);
        vm.assume(_token != _poolToken);
        vm.assume(_token != address(vm));
        vm.assume(_token != 0x000000000000000000636F6e736F6c652e6c6f67);

        uint256 poolAmountBefore = baseStrategy.getPoolAmount();

        baseStrategy.mock_call__checkOnlyPoolManager(address(this));

        vm.mockCall(_token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _amount), abi.encode(true));
        vm.mockCall(
            address(0),
            abi.encodeWithSelector(IAllo.getPool.selector, 0),
            abi.encode(
                IAllo.Pool({
                    profileId: bytes32(0),
                    strategy: IBaseStrategy(address(0)),
                    token: _poolToken,
                    metadata: Metadata({protocol: 0, pointer: ""}),
                    managerRole: bytes32(0),
                    adminRole: bytes32(0)
                })
            )
        );

        // It should call onlyPoolManager
        baseStrategy.expectCall__checkOnlyPoolManager(address(this));

        // It should call _beforeWithdraw
        baseStrategy.expectCall__beforeWithdraw(_token, _amount, _recipient);

        // It should call getPool at allo
        vm.expectCall(address(0), abi.encodeWithSelector(IAllo.getPool.selector, 0));

        // It should call transfer at token
        vm.expectCall(_token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _amount));

        // It should call _afterWithdraw
        baseStrategy.expectCall__afterWithdraw(_token, _amount, _recipient);

        // It should emit event
        vm.expectEmit();
        emit IBaseStrategy.Withdrew(_token, _amount, _recipient);

        // It should not change the pool amount
        assertEq(baseStrategy.getPoolAmount(), poolAmountBefore);

        baseStrategy.withdraw(_token, _amount, _recipient);
    }

    modifier whenTokenIsPoolToken(address _token, uint256 _amount, address _recipient, uint256 _contractBalance) {
        vm.assume(_token != NATIVE);
        vm.assume(_token != address(vm));
        vm.assume(_token != 0x000000000000000000636F6e736F6c652e6c6f67);

        baseStrategy.mock_call__checkOnlyPoolManager(address(this));

        vm.mockCall(
            _token,
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(baseStrategy)),
            abi.encode(_contractBalance)
        );
        vm.mockCall(_token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _amount), abi.encode(true));
        vm.mockCall(
            address(0),
            abi.encodeWithSelector(IAllo.getPool.selector, 0),
            abi.encode(
                IAllo.Pool({
                    profileId: bytes32(0),
                    strategy: IBaseStrategy(address(0)),
                    token: _token,
                    metadata: Metadata({protocol: 0, pointer: ""}),
                    managerRole: bytes32(0),
                    adminRole: bytes32(0)
                })
            )
        );
        _;
    }

    function test_WithdrawWhenTokenIsPoolToken(
        address _token,
        uint256 _amount,
        address _recipient,
        uint256 _contractBalance,
        uint256 _poolAmount
    ) external whenTokenIsPoolToken(_token, _amount, _recipient, _contractBalance) {
        vm.assume(_contractBalance > _amount);

        _poolAmount = bound(_poolAmount, 0, _contractBalance - _amount);
        baseStrategy.set__poolAmount(_poolAmount);

        // It should call balanceOf at token
        vm.expectCall(_token, abi.encodeWithSelector(IERC20.balanceOf.selector, address(baseStrategy)));

        baseStrategy.withdraw(_token, _amount, _recipient);
    }

    function test_WithdrawRevertWhen_AmountIsGreaterThanBalanceMinusPoolAmount(
        address _token,
        uint256 _amount,
        address _recipient,
        uint256 _contractBalance,
        uint256 _poolAmount
    ) external whenTokenIsPoolToken(_token, _amount, _recipient, _contractBalance) {
        vm.assume(_contractBalance > 0);
        _poolAmount = bound(_poolAmount, 1, _contractBalance);
        _amount = bound(_amount, _contractBalance - _poolAmount + 1, _contractBalance);
        baseStrategy.set__poolAmount(_poolAmount);

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_WITHDRAW_MORE_THAN_POOL_AMOUNT.selector);

        baseStrategy.withdraw(_token, _amount, _recipient);
    }

    function test_RegisterWhenParametersAreValid(address[] memory _recipients, bytes memory _data, address _sender)
        external
    {
        baseStrategy.mock_call__checkOnlyAllo();
        baseStrategy.mock_call__register(_recipients, _data, _sender, _recipients);

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        // It should call _beforeRegisterRecipient
        baseStrategy.expectCall__beforeRegisterRecipient(_recipients, _data, _sender);

        // It should call _register
        baseStrategy.expectCall__register(_recipients, _data, _sender);

        // It should call _afterRegisterRecipient
        baseStrategy.expectCall__afterRegisterRecipient(_recipients, _data, _sender);

        address[] memory _recipientIds = baseStrategy.register(_recipients, _data, _sender);

        // It should return _recipientIds
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            assertEq(_recipientIds[i], _recipients[i]);
        }
    }

    function test_AllocateWhenParametersAreValid(
        address[] memory _recipients,
        uint256[] memory _amounts,
        bytes memory _data,
        address _sender
    ) external {
        baseStrategy.mock_call__checkOnlyAllo();
        baseStrategy.mock_call__allocate(_recipients, _amounts, _data, _sender);

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        // It should call _beforeAllocate
        baseStrategy.expectCall__beforeAllocate(_recipients, _data, _sender);

        // It should call _allocate
        baseStrategy.expectCall__allocate(_recipients, _amounts, _data, _sender);

        // It should call _afterAllocate
        baseStrategy.expectCall__afterAllocate(_recipients, _data, _sender);

        baseStrategy.allocate(_recipients, _amounts, _data, _sender);
    }

    function test_DistributeWhenParametersAreValid(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
    {
        baseStrategy.mock_call__checkOnlyAllo();
        baseStrategy.mock_call__distribute(_recipientIds, _data, _sender);

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        // It should call _beforeDistribute
        baseStrategy.expectCall__beforeDistribute(_recipientIds, _data, _sender);

        // It should call _distribute
        baseStrategy.expectCall__distribute(_recipientIds, _data, _sender);

        // It should call _afterDistribute
        baseStrategy.expectCall__afterDistribute(_recipientIds, _data, _sender);

        baseStrategy.distribute(_recipientIds, _data, _sender);
    }

    function test__checkOnlyAlloRevertWhen_CallerIsNotAllo(address _caller) external {
        vm.assume(_caller != address(baseStrategy.getAllo()));

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_UNAUTHORIZED.selector);

        vm.prank(_caller);
        baseStrategy.call__checkOnlyAllo();
    }

    function test__checkOnlyPoolManagerShouldCallIsPoolManagerAtAllo() external {
        vm.mockCall(
            address(baseStrategy.getAllo()),
            abi.encodeWithSelector(IAllo.isPoolManager.selector, baseStrategy.getPoolId(), address(this)),
            abi.encode(true)
        );

        // It should call isPoolManager at allo
        vm.expectCall(
            address(baseStrategy.getAllo()),
            abi.encodeWithSelector(IAllo.isPoolManager.selector, baseStrategy.getPoolId(), address(this))
        );

        baseStrategy.call__checkOnlyPoolManager(address(this));
    }

    function test__checkOnlyPoolManagerRevertWhen_CallerIsNotPoolManager() external {
        vm.mockCall(
            address(baseStrategy.getAllo()),
            abi.encodeWithSelector(IAllo.isPoolManager.selector, baseStrategy.getPoolId(), address(this)),
            abi.encode(false)
        );

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_UNAUTHORIZED.selector);

        baseStrategy.call__checkOnlyPoolManager(address(this));
    }
}
