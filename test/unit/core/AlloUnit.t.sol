// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockAllo} from "test/smock/MockMockAllo.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {IBaseStrategy} from "contracts/strategies/IBaseStrategy.sol";
import {ClonesUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";

contract Allo is Test {
    using LibString for uint256;

    MockMockAllo allo;

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    function setUp() public virtual {
        allo = new MockMockAllo();
    }

    function test_InitializeGivenUpgradeVersionIsCorrect(
        address _owner,
        address _registry,
        address payable _treasury,
        uint256 _percentFee,
        uint256 _baseFee,
        address _trustedForwarder
    ) external {
        allo.mock_call__updateRegistry(_registry);
        allo.mock_call__updateTreasury(_treasury);
        allo.mock_call__updatePercentFee(_percentFee);
        allo.mock_call__updateBaseFee(_baseFee);
        allo.mock_call__updateTrustedForwarder(_trustedForwarder);

        // it should call _initializeOwner
        allo.expectCall__initializeOwner(_owner);

        // it should call _updateRegistry
        allo.expectCall__updateRegistry(_registry);

        // it should call _updateTreasury
        allo.expectCall__updateTreasury(_treasury);

        // it should call _updatePercentFee
        allo.expectCall__updatePercentFee(_percentFee);

        // it should call _updateBaseFee
        allo.expectCall__updateBaseFee(_baseFee);

        // it should call _updateTrustedForwarder
        allo.expectCall__updateTrustedForwarder(_trustedForwarder);

        allo.initialize(_owner, _registry, _treasury, _percentFee, _baseFee, _trustedForwarder);
    }

    function test_CreatePoolWithCustomStrategyRevertWhen_StrategyIsZeroAddress(
        bytes32 _profileId,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        allo.createPoolWithCustomStrategy(
            _profileId, address(0), _initStrategyData, _token, _amount, _metadata, _managers
        );
    }

    function test_CreatePoolWithCustomStrategyWhenCallingWithProperParams(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 _poolId
    ) external {
        vm.assume(address(_strategy) != address(0));
        vm.assume(_creator != address(0));
        allo.mock_call__createPool(
            _creator,
            _msgValue,
            _profileId,
            _strategy,
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers,
            _poolId
        );

        // it should call _createPool
        allo.expectCall__createPool(
            _creator, _msgValue, _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );

        deal(_creator, _msgValue);
        vm.prank(_creator);
        uint256 poolId = allo.createPoolWithCustomStrategy{value: _msgValue}(
            _profileId, address(_strategy), _initStrategyData, _token, _amount, _metadata, _managers
        );

        // it should return poolId
        assertEq(poolId, _poolId);
    }

    function test_CreatePoolRevertWhen_StrategyIsZeroAddress(
        bytes32 _profileId,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        allo.createPool(_profileId, address(0), _initStrategyData, _token, _amount, _metadata, _managers);
    }

    function test_CreatePoolWhenCallingWithProperParams(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 _poolId
    ) external {
        vm.assume(address(_strategy) != address(0));
        vm.assume(_creator != address(0));

        address _expectedClonedStrategy = ClonesUpgradeable.predictDeterministicAddress(
            address(_strategy), keccak256(abi.encodePacked(_creator, uint256(0))), address(allo)
        );

        allo.mock_call__createPool(
            _creator,
            _msgValue,
            _profileId,
            IBaseStrategy(_expectedClonedStrategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers,
            _poolId
        );

        // it should call _createPool
        allo.expectCall__createPool(
            _creator,
            _msgValue,
            _profileId,
            IBaseStrategy(_expectedClonedStrategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );

        deal(_creator, _msgValue);
        vm.prank(_creator);
        uint256 poolId = allo.createPool{value: _msgValue}(
            _profileId, address(_strategy), _initStrategyData, _token, _amount, _metadata, _managers
        );

        // it should return poolId
        assertEq(poolId, _poolId);
    }

    function test_UpdatePoolMetadataGivenSenderIsManagerOfPool(uint256 _poolId, Metadata memory _metadata) external {
        allo.mock_call__checkOnlyPoolManager(_poolId, address(this));

        // it should call _checkOnlyPoolManager
        allo.expectCall__checkOnlyPoolManager(_poolId, address(this));

        // it should emit event
        vm.expectEmit();
        emit PoolMetadataUpdated(_poolId, _metadata);

        allo.updatePoolMetadata(_poolId, _metadata);

        // it should update metadata
        assertEq(allo.getPool(_poolId).metadata.pointer, _metadata.pointer);
        assertEq(allo.getPool(_poolId).metadata.protocol, _metadata.protocol);
    }

    function test_UpdateRegistryRevertWhen_SenderIsNotOwner(address _caller, address _registry) external {
        vm.assume(_caller != address(0)); // owner is not set so is eq to 0

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateRegistry(_registry);
    }

    function test_UpdateRegistryWhenSenderIsOwner(address _caller, address _registry) external {
        vm.assume(_caller != address(0));

        vm.prank(address(0));
        allo.transferOwnership(_caller);

        allo.mock_call__updateRegistry(_registry);

        // it should call _updateRegistry
        allo.expectCall__updateRegistry(_registry);

        vm.prank(_caller);
        allo.updateRegistry(_registry);
    }

    function test_UpdateTreasuryRevertWhen_SenderIsNotOwner(address _caller, address payable _treasury) external {
        vm.assume(_caller != address(0)); // owner is not set so is eq to 0

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateTreasury(_treasury);
    }

    function test_UpdateTreasuryWhenSenderIsOwner(address _caller, address payable _treasury) external {
        vm.assume(_caller != address(0));

        vm.prank(address(0));
        allo.transferOwnership(_caller);

        allo.mock_call__updateTreasury(_treasury);

        // it should call _updateTreasury
        allo.expectCall__updateTreasury(_treasury);

        vm.prank(_caller);
        allo.updateTreasury(_treasury);
    }

    function test_UpdatePercentFeeRevertWhen_SenderIsNotOwner(address _caller, uint256 _percentFee) external {
        vm.assume(_caller != address(0)); // owner is not set so is eq to 0

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updatePercentFee(_percentFee);
    }

    function test_UpdatePercentFeeWhenSenderIsOwner(address _caller, uint256 _percentFee) external {
        vm.assume(_caller != address(0));

        vm.prank(address(0));
        allo.transferOwnership(_caller);

        allo.mock_call__updatePercentFee(_percentFee);

        // it should call _updatePercentFee
        allo.expectCall__updatePercentFee(_percentFee);

        vm.prank(_caller);
        allo.updatePercentFee(_percentFee);
    }

    function test_UpdateBaseFeeRevertWhen_SenderIsNotOwner(address _caller, uint256 _baseFee) external {
        vm.assume(_caller != address(0)); // owner is not set so is eq to 0

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateBaseFee(_baseFee);
    }

    function test_UpdateBaseFeeWhenSenderIsOwner(address _caller, uint256 _baseFee) external {
        vm.assume(_caller != address(0));

        vm.prank(address(0));
        allo.transferOwnership(_caller);

        allo.mock_call__updateBaseFee(_baseFee);

        // it should call _updateBaseFee
        allo.expectCall__updateBaseFee(_baseFee);

        vm.prank(_caller);
        allo.updateBaseFee(_baseFee);
    }

    function test_UpdateTrustedForwarderRevertWhen_SenderIsNotOwner(address _caller, address _trustedForwarder)
        external
    {
        vm.assume(_caller != address(0)); // owner is not set so is eq to 0

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateTrustedForwarder(_trustedForwarder);
    }

    function test_UpdateTrustedForwarderWhenSenderIsOwner(address _caller, address _trustedForwarder) external {
        vm.assume(_caller != address(0));

        vm.prank(address(0));
        allo.transferOwnership(_caller);

        allo.mock_call__updateTrustedForwarder(_trustedForwarder);

        // it should call _updateTrustedForwarder
        allo.expectCall__updateTrustedForwarder(_trustedForwarder);

        vm.prank(_caller);
        allo.updateTrustedForwarder(_trustedForwarder);
    }

    function test_AddPoolManagersGivenSenderIsAdminOfPoolId(uint256 _poolId, address[] memory _managers) external {
        allo.mock_call__checkOnlyPoolAdmin(_poolId, address(this));
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(_poolId, _managers[i]);
        }

        // it should call _checkOnlyPoolAdmin
        allo.expectCall__checkOnlyPoolAdmin(_poolId, address(this));

        // it should call _addPoolManager
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.expectCall__addPoolManager(_poolId, _managers[i]);
        }

        allo.addPoolManagers(_poolId, _managers);
    }

    function test_RemovePoolManagersGivenSenderIsAdminOfPoolId(uint256 _poolId, address[] memory _managers) external {
        allo.mock_call__checkOnlyPoolAdmin(_poolId, address(this));

        // it should call _checkOnlyPoolAdmin
        allo.expectCall__checkOnlyPoolAdmin(_poolId, address(this));

        bytes32 _role = allo.getPool(_poolId).managerRole;

        // it should call _revokeRole
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.expectCall__revokeRole(_role, _managers[i]);
        }

        allo.removePoolManagers(_poolId, _managers);
    }

    function test_AddPoolManagersInMultiplePoolsGivenSenderIsAdminOfAllPoolIds(uint256[] memory _poolIds) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);

        address[] memory _managers = new address[](_poolIds.length);
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__checkOnlyPoolAdmin(_poolIds[i], address(this));
            _managers[i] = makeAddr((i + 1).toString());
        }

        // it should call addPoolManagers
        // NOTE: we cant expect addPoolManagers because is a public function.
        // instead we expect the internal that is called inside addPoolManagers
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__addPoolManager(_poolIds[i], _managers[i]);
        }

        allo.addPoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RemovePoolManagersInMultiplePoolsGivenSenderIsAdminOfAllPoolIds(uint256[] memory _poolIds) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);

        address[] memory _managers = new address[](_poolIds.length);
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__checkOnlyPoolAdmin(_poolIds[i], address(this));
            _managers[i] = makeAddr((i + 1).toString());
        }

        // it should call removePoolManagers
        // NOTE: we cant expect removePoolManagers because is a public function.
        // instead we expect the internal that is called inside removePoolManagers
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__revokeRole(allo.getPool(_poolIds[i]).managerRole, _managers[i]);
        }

        allo.removePoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RecoverFundsRevertWhen_SenderIsNotOwner() external {
        // it should revert
        vm.skip(true);
    }

    modifier whenSenderIsOwner() {
        _;
    }

    function test_RecoverFundsWhenTokenIsNative() external whenSenderIsOwner {
        // it should transfer native token
        vm.skip(true);
    }

    function test_RecoverFundsWhenTokenIsNotNative() external whenSenderIsOwner {
        // it should transfer token
        vm.skip(true);
    }

    function test_RegisterRecipientShouldCallRegisterOnTheStrategy() external {
        // it should call register on the strategy
        vm.skip(true);
    }

    function test_RegisterRecipientShouldReturnRecipientId() external {
        // it should return recipientId
        vm.skip(true);
    }

    function test_BatchRegisterRecipientRevertWhen_PoolIdLengthDoesNotMatch_dataLength() external {
        // it should revert
        vm.skip(true);
    }

    function test_BatchRegisterRecipientWhenPoolIdLengthMatches_dataLength() external {
        // it should call register on the strategy
        // it should return recipientIds
        vm.skip(true);
    }

    function test_FundPoolRevertWhen_AmountIsZero() external {
        // it should revert
        vm.skip(true);
    }

    function test_FundPoolRevertWhen_TokenIsNativeAndValueDoesNotMatchAmount() external {
        // it should revert
        vm.skip(true);
    }

    function test_FundPoolWhenCalledWithProperParams() external {
        // it should call _fundPool
        vm.skip(true);
    }

    function test_AllocateShouldCallAllocate() external {
        // it should call allocate
        vm.skip(true);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_dataLength() external {
        // it should revert
        vm.skip(true);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_valuesLength() external {
        // it should revert
        vm.skip(true);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_recipientsLength() external {
        // it should revert
        vm.skip(true);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_amountsLength() external {
        // it should revert
        vm.skip(true);
    }

    function test_BatchAllocateWhenLengthsMatches() external {
        // it should call allocate
        vm.skip(true);
    }

    function test_BatchAllocateRevertWhen_TotalValueDoesNotMatchValue() external {
        // it should revert
        vm.skip(true);
    }

    function test_DistributeShouldCallDistributeOnTheStrategy() external {
        // it should call distribute on the strategy
        vm.skip(true);
    }

    function test_ChangeAdminGivenSenderIsAdminOfPoolId() external {
        // it should call _checkOnlyPoolAdmin
        // it should call _revokeRole
        // it should call _grantRole
        vm.skip(true);
    }

    function test__checkOnlyPoolManagerShouldCall_isPoolManager() external {
        // it should call _isPoolManager
        vm.skip(true);
    }

    function test__checkOnlyPoolManagerRevertWhen_IsNotPoolManager() external {
        // it should revert
        vm.skip(true);
    }

    function test__checkOnlyPoolAdminShouldCall_isPoolAdmin() external {
        // it should call _isPoolAdmin
        vm.skip(true);
    }

    function test__checkOnlyPoolAdminRevertWhen_IsNotPoolAdmin() external {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolShouldCallIsOwnerOrMemberOfProfile() external {
        // it should call isOwnerOrMemberOfProfile
        vm.skip(true);
    }

    function test__createPoolRevertWhen_IsNotOwnerOrMemberOfProfile() external {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolShouldSavePoolOnPoolsMapping() external {
        // it should save pool on pools mapping
        vm.skip(true);
    }

    function test__createPoolShouldCall_grantRole() external {
        // it should call _grantRole
        vm.skip(true);
    }

    function test__createPoolShouldCall_setRoleAdmin() external {
        // it should call _setRoleAdmin
        vm.skip(true);
    }

    function test__createPoolShouldCallInitializeOnTheStrategy() external {
        // it should call initialize on the strategy
        vm.skip(true);
    }

    function test__createPoolShouldCallGetPoolIdOnTheStrategy() external {
        // it should call getPoolId on the strategy
        vm.skip(true);
    }

    function test__createPoolShouldEmitGetAlloOnTheStrategy() external {
        // it should emit getAllo on the strategy
        vm.skip(true);
    }

    function test__createPoolRevertWhen_PoolIdDoesNotMatch() external {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolRevertWhen_AlloDoesNotMatch() external {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolShouldCall_addPoolManagerForEachManager() external {
        // it should call _addPoolManager for each manager
        vm.skip(true);
    }

    modifier whenBaseFeeIsMoreThanZero() {
        _;
    }

    function test__createPoolWhenBaseFeeIsMoreThanZero() external whenBaseFeeIsMoreThanZero {
        // it should call _transferAmount
        // it should emit event
        vm.skip(true);
    }

    modifier whenTokenIsNative() {
        _;
    }

    function test__createPoolRevertWhen_BaseFeePlusAmountIsDiffFromValue()
        external
        whenBaseFeeIsMoreThanZero
        whenTokenIsNative
    {
        // it should revert
        vm.skip(true);
    }

    modifier whenTokenIsNotNative() {
        _;
    }

    function test__createPoolRevertWhen_BaseFeeIsDiffFromValue()
        external
        whenBaseFeeIsMoreThanZero
        whenTokenIsNotNative
    {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolWhenAmountIsMoreThanZero() external {
        // it should call _fundPool
        vm.skip(true);
    }

    function test__createPoolShouldEmitEvent() external {
        // it should emit event
        vm.skip(true);
    }

    function test__createPoolShouldReturnPoolId() external {
        // it should return poolId
        vm.skip(true);
    }

    function test__allocateShouldCallAllocateOnTheStrategy() external {
        // it should call allocate on the strategy
        vm.skip(true);
    }

    modifier whenPercentFeeIsMoreThanZero() {
        _;
    }

    function test__fundPoolWhenPercentFeeIsMoreThanZero() external whenPercentFeeIsMoreThanZero {
        // it should call getFeeDenominator
        vm.skip(true);
    }

    function test__fundPoolRevertWhen_FeeAmountPlusAmountAfterFeeDiffAmount() external whenPercentFeeIsMoreThanZero {
        // it should revert
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNative() external whenPercentFeeIsMoreThanZero {
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNotNative() external whenPercentFeeIsMoreThanZero {
        // it should call _getBalance
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNativeToken() external {
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNotNativeToken() external {
        // it should call _getBalance
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolShouldCallIncreasePoolAmountOnTheStrategy() external {
        // it should call increasePoolAmount on the strategy
        vm.skip(true);
    }

    function test__fundPoolShouldEmitEvent() external {
        // it should emit event
        vm.skip(true);
    }

    function test__isPoolAdminWhenHasRoleAdmin() external {
        // it should return true
        vm.skip(true);
    }

    function test__isPoolAdminWhenHasNoRoleAdmin() external {
        // it should return false
        vm.skip(true);
    }

    function test__isPoolManagerWhenHasRoleManager() external {
        // it should return true
        vm.skip(true);
    }

    function test__isPoolManagerWhenHasRoleAdmin() external {
        // it should return true
        vm.skip(true);
    }

    function test__isPoolManagerWhenHasNoRolesAtAll() external {
        // it should return false
        vm.skip(true);
    }

    function test__updateRegistryRevertWhen_RegistryIsZeroAddress() external {
        // it should revert
        vm.skip(true);
    }

    function test__updateRegistryGivenRegistryIsNotZeroAddress() external {
        // it should update registry
        // it should emit event
        vm.skip(true);
    }

    function test__updateTreasuryRevertWhen_TreasuryIsZeroAddress() external {
        // it should revert
        vm.skip(true);
    }

    function test__updateTreasuryGivenTreasuryIsNotZeroAddress() external {
        // it should update treasury
        // it should emit event
        vm.skip(true);
    }

    function test__updatePercentFeeRevertWhen_PercentFeeIsMoreThan1e18() external {
        // it should revert
        vm.skip(true);
    }

    function test__updatePercentFeeGivenPercentFeeIsValid() external {
        // it should update percentFee
        // it should emit event
        vm.skip(true);
    }

    function test__updateBaseFeeShouldUpdateBaseFee() external {
        // it should update baseFee
        vm.skip(true);
    }

    function test__updateBaseFeeShouldEmitEvent() external {
        // it should emit event
        vm.skip(true);
    }

    function test__updateTrustedForwarder() external {
        // it should update trustedForwarder
        // it should emit event
        vm.skip(true);
    }

    function test__addPoolManagerRevertWhen_ManagerIsZeroAddress() external {
        // it should revert
        vm.skip(true);
    }

    function test__addPoolManagerGivenManagerIsNotZeroAddress() external {
        // it should call _grantRole
        vm.skip(true);
    }

    modifier whenSenderIsTrustedForwarder() {
        _;
    }

    function test__msgSenderWhenCalldataLengthIsMoreThan20() external whenSenderIsTrustedForwarder {
        // it should return actual sender
        vm.skip(true);
    }

    function test__msgSenderWhenConditionsAreNotMet() external {
        // it should call _msgSender
        vm.skip(true);
    }

    function test__msgDataWhenCalldataLengthIsMoreThan20() external whenSenderIsTrustedForwarder {
        // it should return actual data
        vm.skip(true);
    }

    function test__msgDataWhenConditionsAreNotMet() external {
        // it should call _msgData
        vm.skip(true);
    }

    function test_GetFeeDenominatorShouldReturnFeeDenominator() external {
        // it should return feeDenominator
        vm.skip(true);
    }

    function test_IsPoolAdminShouldCall_isPoolAdmin() external {
        // it should call _isPoolAdmin
        vm.skip(true);
    }

    function test_IsPoolAdminShouldReturnIsPoolAdmin() external {
        // it should return isPoolAdmin
        vm.skip(true);
    }

    function test_IsPoolManagerShouldCall_isPoolManager() external {
        // it should call _isPoolManager
        vm.skip(true);
    }

    function test_IsPoolManagerShouldReturnIsPoolManager() external {
        // it should return isPoolManager
        vm.skip(true);
    }

    function test_GetStrategyShouldReturnStrategy() external {
        // it should return strategy
        vm.skip(true);
    }

    function test_GetPercentFeeShouldReturnPercentFee() external {
        // it should return percentFee
        vm.skip(true);
    }

    function test_GetBaseFeeShouldReturnBaseFee() external {
        // it should return baseFee
        vm.skip(true);
    }

    function test_GetTreasuryShouldReturnTreasury() external {
        // it should return treasury
        vm.skip(true);
    }

    function test_GetRegistryShouldReturnRegistry() external {
        // it should return registry
        vm.skip(true);
    }

    function test_GetPoolShouldReturnPool() external {
        // it should return pool
        vm.skip(true);
    }

    function test_IsTrustedForwarderWhenForwarderIsTrustedForwarder() external {
        // it should return true
        vm.skip(true);
    }

    function test_IsTrustedForwarderWhenForwarderIsNotTrustedForwarder() external {
        // it should return false
        vm.skip(true);
    }
}
