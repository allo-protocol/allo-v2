// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {MockMockAllo} from "test/smock/MockMockAllo.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {IBaseStrategy} from "contracts/strategies/IBaseStrategy.sol";
import {ClonesUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockToken} from "test/mocks/MockToken.sol";

contract AlloUnit is Test {
    using LibString for uint256;
    using stdStorage for StdStorage;

    MockMockAllo allo;
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public fakeRegistry;
    address public fakeStrategy;
    address payable public fakeTreasury;
    address public alloOwner;
    address public poolAdmin;
    address public poolManager;
    address public trustedForwarder;
    IAllo.Pool public fakePool;
    MockToken public fakeToken;

    function setUp() public virtual {
        allo = new MockMockAllo();
        fakeToken = new MockToken("MockToken", "MTK");
        fakeStrategy = makeAddr("fakeStrategy");
        fakePool = IAllo.Pool({
            profileId: keccak256("profileId"),
            strategy: IBaseStrategy(fakeStrategy),
            token: address(1),
            metadata: Metadata({pointer: "", protocol: 1}),
            adminRole: keccak256("adminRole"),
            managerRole: keccak256("managerRole")
        });

        fakeRegistry = makeAddr("fakeRegistry");
        fakeTreasury = payable(makeAddr("fakeTreasury"));
        alloOwner = makeAddr("alloOwner");
        poolAdmin = makeAddr("poolAdmin");
        poolManager = makeAddr("poolManager");
        trustedForwarder = makeAddr("trustedForwarder");

        // transfer ownership to alloOwner
        vm.prank(address(0));
        allo.transferOwnership(alloOwner);

        vm.startPrank(alloOwner);
        allo.updateRegistry(fakeRegistry);
        allo.updateTreasury(fakeTreasury);
        vm.stopPrank();
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

        assertEq(allo.getNonce(_creator), 0);

        deal(_creator, _msgValue);
        vm.prank(_creator);
        uint256 poolId = allo.createPool{value: _msgValue}(
            _profileId, address(_strategy), _initStrategyData, _token, _amount, _metadata, _managers
        );

        // it should increment the _nonces of the creator
        assertEq(allo.getNonce(_creator), 1);
        // it should return poolId
        assertEq(poolId, _poolId);
    }

    function test_UpdatePoolMetadataGivenSenderIsManagerOfPool(uint256 _poolId, Metadata memory _metadata) external {
        allo.mock_call__checkOnlyPoolManager(_poolId, poolManager);

        // it should call _checkOnlyPoolManager
        allo.expectCall__checkOnlyPoolManager(_poolId, poolManager);

        // it should emit event
        vm.expectEmit();
        emit IAllo.PoolMetadataUpdated(_poolId, _metadata);

        vm.prank(poolManager);
        allo.updatePoolMetadata(_poolId, _metadata);

        // it should update metadata
        assertEq(allo.getPool(_poolId).metadata.pointer, _metadata.pointer);
        assertEq(allo.getPool(_poolId).metadata.protocol, _metadata.protocol);
    }

    function test_UpdateRegistryRevertWhen_SenderIsNotOwner(address _caller, address _registry) external {
        vm.assume(_caller != alloOwner);

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateRegistry(_registry);
    }

    modifier whenSenderIsOwner() {
        vm.startPrank(alloOwner);
        _;
        vm.stopPrank();
    }

    function test_UpdateRegistryRevertWhen_NewRegistryIsZeroAddress() external whenSenderIsOwner {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.updateRegistry(address(0));
    }

    function test_UpdateRegistryWhenNewRegistryIsNotZeroAddress(address _registry) external whenSenderIsOwner {
        vm.assume(_registry != address(0));

        // registry is set to fakeRegistry
        assertEq(address(allo.getRegistry()), fakeRegistry);

        allo.expectCall__updateRegistry(_registry);
        // it should emit event
        vm.expectEmit();
        emit IAllo.RegistryUpdated(_registry);

        allo.updateRegistry(_registry);

        // it should update registry
        assertEq(address(allo.getRegistry()), _registry);
    }

    function test_UpdateTreasuryRevertWhen_SenderIsNotOwner(address _caller, address payable _treasury) external {
        vm.assume(_caller != alloOwner);

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateTreasury(_treasury);
    }

    function test_UpdateTreasuryRevertWhen_NewTreasuryIsZeroAddress() external whenSenderIsOwner {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.updateTreasury(payable(0));
    }

    function test_UpdateTreasuryGivenNewTreasuryIsNotZeroAddress(address payable _treasury)
        external
        whenSenderIsOwner
    {
        vm.assume(_treasury != address(0));

        // treasury is set to fakeTreasury
        assertEq(address(allo.getTreasury()), fakeTreasury);

        allo.expectCall__updateTreasury(_treasury);

        // it should emit event
        vm.expectEmit();
        emit IAllo.TreasuryUpdated(_treasury);

        allo.updateTreasury(_treasury);
        // it should update treasury
        assertEq(address(allo.getTreasury()), _treasury);
    }

    function test_UpdatePercentFeeRevertWhen_SenderIsNotOwner(address _caller, uint256 _percentFee) external {
        vm.assume(_caller != alloOwner);

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updatePercentFee(_percentFee);
    }

    function test_UpdatePercentFeeRevertWhen_PercentFeeIsMoreThan1e18(uint256 _percentFee) external whenSenderIsOwner {
        vm.assume(_percentFee > 1e18);

        // it should revert
        vm.expectRevert(Errors.INVALID.selector);
        allo.updatePercentFee(_percentFee);
    }

    function test_UpdatePercentFeeWhenPercentFeeIsLessThan1e18(uint256 _percentFee) external whenSenderIsOwner {
        _percentFee = bound(_percentFee, 1, 1e18);

        // percent fee is set to 0
        assertEq(allo.getPercentFee(), 0);

        allo.expectCall__updatePercentFee(_percentFee);

        // it should emit event
        vm.expectEmit();
        emit IAllo.PercentFeeUpdated(_percentFee);

        allo.updatePercentFee(_percentFee);

        // it should update percentFee
        assertEq(allo.getPercentFee(), _percentFee);
    }

    function test_UpdateBaseFeeRevertWhen_SenderIsNotOwner(address _caller, uint256 _baseFee) external {
        vm.assume(_caller != alloOwner);

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateBaseFee(_baseFee);
    }

    function test_UpdateBaseFeeWhenSenderIsOwner(uint256 _baseFee) external whenSenderIsOwner {
        // base fee is set to 0
        assertEq(allo.getBaseFee(), 0);

        allo.expectCall__updateBaseFee(_baseFee);
        // it should emit event
        vm.expectEmit();
        emit IAllo.BaseFeeUpdated(_baseFee);

        allo.updateBaseFee(_baseFee);

        // it should update baseFee
        assertEq(allo.getBaseFee(), _baseFee);
    }

    function test_UpdateTrustedForwarderRevertWhen_SenderIsNotOwner(address _caller, address _trustedForwarder)
        external
    {
        vm.assume(_caller != alloOwner);

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateTrustedForwarder(_trustedForwarder);
    }

    function test_UpdateTrustedForwarderWhenSenderIsOwner(address _trustedForwarder) external whenSenderIsOwner {
        // trustedForwarder is set to address(0)
        assertTrue(allo.isTrustedForwarder(address(0)));

        allo.expectCall__updateTrustedForwarder(_trustedForwarder);
        // it should emit event
        vm.expectEmit();
        emit IAllo.TrustedForwarderUpdated(_trustedForwarder);

        allo.updateTrustedForwarder(_trustedForwarder);
        // it should update trustedForwarder
        assertTrue(allo.isTrustedForwarder(_trustedForwarder));
    }

    function test_AddPoolManagersRevertWhen_SenderIsNotAdminOfPoolId(
        address _caller,
        uint256 _poolId,
        address[] memory _managers
    ) external {
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        vm.prank(_caller);
        allo.addPoolManagers(_poolId, _managers);
    }

    modifier whenSenderIsAdminOfPoolId(uint256 _poolId) {
        allo.mock_call__checkOnlyPoolAdmin(_poolId, poolAdmin);
        vm.startPrank(poolAdmin);
        _;
        vm.stopPrank();
    }

    function test_AddPoolManagersRevertWhen_ManagerIsZeroAddress(uint256 _poolId, address[] memory _managers)
        external
        whenSenderIsAdminOfPoolId(_poolId)
    {
        vm.assume(_managers.length > 0);
        _managers[0] = address(0);

        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        allo.addPoolManagers(_poolId, _managers);
    }

    function test_AddPoolManagersWhenManagerIsNotZeroAddress(uint256 _poolId)
        external
        whenSenderIsAdminOfPoolId(_poolId)
    {
        address[] memory _managers = new address[](1);
        _managers[0] = makeAddr("manager");

        allo.setPool(_poolId, fakePool);

        // it should call _grantRole for manager
        allo.expectCall__grantRole(keccak256("managerRole"), _managers[0]);

        allo.addPoolManagers(_poolId, _managers);
    }

    function test_RemovePoolManagersRevertWhen_SenderIsNotAdminOfPoolId(
        address _caller,
        uint256 _poolId,
        address[] memory _managers
    ) external {
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        vm.prank(_caller);
        allo.removePoolManagers(_poolId, _managers);
    }

    function test_RemovePoolManagersWhenSenderIsAdminOfPoolId(uint256 _poolId, address[] memory _managers)
        external
        whenSenderIsAdminOfPoolId(_poolId)
    {
        allo.setPool(_poolId, fakePool);

        // it should call _revokeRole for manager
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.expectCall__revokeRole(keccak256("managerRole"), _managers[i]);
        }

        allo.removePoolManagers(_poolId, _managers);
    }

    function test_AddPoolManagersInMultiplePoolsRevertWhen_SenderIsNotAdminOfAllPoolIds(
        address _caller,
        uint256[] calldata _poolIds,
        address[] calldata _managers
    ) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        vm.prank(_caller);
        allo.addPoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_AddPoolManagersInMultiplePoolsWhenSenderIsAdminOfOfAllPoolIds(uint256[] calldata _poolIds) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);

        address[] memory _managers = new address[](_poolIds.length);
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__checkOnlyPoolAdmin(_poolIds[i], poolAdmin);
            _managers[i] = makeAddr((i + 1).toString());
        }

        // it should call addPoolManagers
        // NOTE: we cant expect addPoolManagers because is a public function.
        // instead we expect the internal that is called inside addPoolManagers
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__addPoolManager(_poolIds[i], _managers[i]);
        }

        vm.prank(poolAdmin);
        allo.addPoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RemovePoolManagersInMultiplePoolsRevertWhen_SenderIsNotAdminOfAllPoolIds(
        address _caller,
        uint256[] calldata _poolIds,
        address[] calldata _managers
    ) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        vm.prank(_caller);
        allo.removePoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RemovePoolManagersInMultiplePoolsWhenSenderIsAdminOfOfAllPoolIds(uint256[] memory _poolIds)
        external
    {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);

        address[] memory _managers = new address[](_poolIds.length);
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__checkOnlyPoolAdmin(_poolIds[i], poolAdmin);
            _managers[i] = makeAddr((i + 1).toString());
        }

        // it should call removePoolManagers
        // NOTE: we cant expect removePoolManagers because is a public function.
        // instead we expect the internal that is called inside removePoolManagers
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__revokeRole(allo.getPool(_poolIds[i]).managerRole, _managers[i]);
        }

        vm.prank(poolAdmin);
        allo.removePoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RecoverFundsRevertWhen_SenderIsNotOwner(address _caller, address _recipient) external {
        vm.assume(_caller != alloOwner);

        vm.expectRevert(Ownable.Unauthorized.selector);
        // it should revert
        vm.prank(_caller);
        allo.recoverFunds(NATIVE, _recipient);
    }

    function test_RecoverFundsWhenTokenIsNative(address _recipient) external whenSenderIsOwner {
        vm.assume(_recipient != address(0));
        vm.assume(_recipient.code.length == 0);

        deal(address(allo), 100 ether);

        assertEq(_recipient.balance, 0);

        allo.recoverFunds(NATIVE, _recipient);
        // it should transfer the whole balance of native token
        assertEq(_recipient.balance, 100 ether);
        assertEq(address(allo).balance, 0);
    }

    function test_RecoverFundsWhenTokenIsNotNative(address _token, address _recipient) external whenSenderIsOwner {
        vm.assume(_token != NATIVE);
        vm.assume(_recipient != address(0));

        uint256 _tokenBalance = 10 ether;
        vm.mockCall(_token, abi.encodeWithSelector(IERC20.balanceOf.selector, address(allo)), abi.encode(_tokenBalance));
        vm.mockCall(
            _token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _tokenBalance), abi.encode(true)
        );

        // it should transfer the whole balance of tokens
        vm.expectCall(_token, abi.encodeWithSelector(IERC20.balanceOf.selector, address(allo)));
        vm.expectCall(_token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _tokenBalance));

        allo.recoverFunds(_token, _recipient);
    }

    function test_RegisterRecipientShouldTransferTheMsgvalueReceived(
        address _caller,
        uint256 _poolId,
        bytes memory _data
    ) external {
        address payable _strategy = payable(makeAddr("strategy"));
        fakePool.strategy = IBaseStrategy(_strategy);
        allo.setPool(_poolId, fakePool);

        address[] memory _recipients = new address[](1);
        _recipients[0] = address(1);

        allo.mock_call__msgSender(_caller);
        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients, _data, _caller),
            abi.encode(_recipients)
        );
        deal(_caller, 10 ether);

        vm.prank(_caller);
        allo.registerRecipient{value: 10 ether}(_poolId, _recipients, _data);
        // it should transfer the msg.value received
        assertEq(address(allo).balance, 10 ether);
    }

    function test_RegisterRecipientShouldCallRegisterOnTheStrategy(address _caller, uint256 _poolId, bytes memory _data)
        external
    {
        address[] memory _recipients = new address[](1);
        _recipients[0] = address(1);

        allo.setPool(_poolId, fakePool);

        allo.mock_call__msgSender(_caller);
        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients, _data, _caller),
            abi.encode(_recipients)
        );
        // it should call register on the strategy
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients, _data, _caller)
        );

        // it should return recipientId
        vm.prank(_caller);
        address[] memory _recipientIds = allo.registerRecipient(_poolId, _recipients, _data);
        assertEq(_recipientIds[0], _recipients[0]);
    }

    function test_BatchRegisterRecipientRevertWhen_PoolIdLengthDoesNotMatch_dataLength(
        uint256[] memory _poolIds,
        bytes[] memory _data
    ) external {
        vm.assume(_poolIds.length != _data.length);

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        // it should revert
        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);

        allo.batchRegisterRecipient(_poolIds, _recipients, _data);
    }

    function test_BatchRegisterRecipientRevertWhen_PoolIdLengthDoesNotMatch_recipientsLength(
        address[][] memory _recipients
    ) external {
        vm.assume(_recipients.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;
        bytes[] memory _data = new bytes[](1);
        _data[0] = "data";
        // it should revert
        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);

        allo.batchRegisterRecipient(_poolIds, _recipients, _data);
    }

    function test_BatchRegisterRecipientWhenPoolIdLengthMatches_dataLengthAnd_recipientsLength(address _caller)
        external
    {
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        bytes[] memory _data = new bytes[](1);
        _data[0] = "data";

        allo.setPool(_poolIds[0], fakePool);

        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients[0], _data[0], _caller),
            abi.encode(_recipients[0])
        );
        // it should call register on the strategy
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients[0], _data[0], _caller)
        );
        // it should return recipientIds
        vm.prank(_caller);
        address[][] memory _recipientIds = allo.batchRegisterRecipient(_poolIds, _recipients, _data);
        assertEq(_recipientIds[0][0], _recipients[0][0]);
    }

    function test_FundPoolRevertWhen_AmountIsZero(uint256 _poolId) external {
        // it should revert
        vm.expectRevert(Errors.INVALID.selector);

        allo.fundPool(_poolId, 0);
    }

    function test_FundPoolRevertWhen_TokenIsNativeAndValueDoesNotMatchAmount(uint256 _poolId, uint256 _amount)
        external
    {
        vm.assume(_amount > 0);

        fakePool.token = NATIVE;

        allo.setPool(_poolId, fakePool);
        // it should revert
        vm.expectRevert(Errors.ETH_MISMATCH.selector);
        allo.fundPool(_poolId, _amount);
    }

    function test_FundPoolWhenCalledWithProperParams(address _caller, uint256 _poolId, uint256 _amount) external {
        vm.assume(_amount > 0);
        fakePool.token = makeAddr("token");
        allo.setPool(_poolId, fakePool);

        allo.mock_call__msgSender(_caller);
        allo.mock_call__fundPool(_amount, _caller, _poolId, fakePool.strategy);
        // it should call _fundPool
        allo.expectCall__fundPool(_amount, _caller, _poolId, fakePool.strategy);

        vm.prank(_caller);
        allo.fundPool(_poolId, _amount);
    }

    function test_AllocateShouldCallAllocateOnTheStrategy(uint256 _poolId, uint256 _value, address _allocator)
        external
    {
        deal(_allocator, _value);
        allo.setPool(_poolId, fakePool);

        address[] memory _recipients = new address[](1);
        _recipients[0] = address(1);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 1;

        bytes memory _data = "0x";

        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.allocate.selector, _recipients, _amounts, _data, _allocator),
            abi.encode()
        );
        // it should call allocate on the strategy
        vm.expectCall(
            fakeStrategy,
            _value,
            abi.encodeWithSelector(IBaseStrategy.allocate.selector, _recipients, _amounts, _data, _allocator)
        );

        vm.prank(_allocator);
        allo.allocate{value: _value}(_poolId, _recipients, _amounts, _data);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_dataLength(bytes[] memory _datas) external {
        vm.assume(_datas.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        // it should revert
        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_valuesLength(uint256[] memory _values) external {
        vm.assume(_values.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        // it should revert
        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_recipientsLength(address[][] memory _recipients)
        external
    {
        vm.assume(_recipients.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        // it should revert
        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_amountsLength(uint256[][] memory _amounts)
        external
    {
        vm.assume(_amounts.length != 1);
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        // it should revert
        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateWhenLengthsMatches(address _caller) external {
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        uint256[] memory _values = new uint256[](1);
        _values[0] = 0;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], _caller);
        }

        // it should call allocate
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], _caller);
        }

        vm.prank(_caller);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_TotalValueDoesNotMatchMsgValue(address _caller) external {
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], _caller);
        }

        // it should revert
        vm.expectRevert(Errors.ETH_MISMATCH.selector);
        vm.prank(_caller);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_DistributeShouldCallDistributeOnTheStrategy(
        address _caller,
        uint256 _poolId,
        address[] memory _recipients,
        bytes memory _data
    ) external {
        allo.setPool(_poolId, fakePool);

        allo.mock_call__msgSender(_caller);
        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.distribute.selector, _recipients, _data, _caller),
            abi.encode()
        );
        // it should call distribute on the strategy
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.distribute.selector, _recipients, _data, _caller)
        );

        vm.prank(_caller);
        allo.distribute(_poolId, _recipients, _data);
    }

    function test_ChangeAdminRevertWhen_SenderIsNotAdminOfPoolId(address _caller, uint256 _poolId, address _newAdmin)
        external
    {
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        vm.prank(_caller);
        allo.changeAdmin(_poolId, _newAdmin);
    }

    function test_ChangeAdminRevertWhen_NewAdminIsZeroAddress(uint256 _poolId)
        external
        whenSenderIsAdminOfPoolId(_poolId)
    {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.changeAdmin(_poolId, address(0));
    }

    function test_ChangeAdminWhenNewAdminIsNotZeroAddress(uint256 _poolId, address _newAdmin)
        external
        whenSenderIsAdminOfPoolId(_poolId)
    {
        vm.assume(_newAdmin != address(0));
        // it should call _checkOnlyPoolAdmin
        allo.expectCall__checkOnlyPoolAdmin(_poolId, poolAdmin);
        // it should call _revokeRole
        allo.expectCall__revokeRole(allo.getPool(_poolId).adminRole, poolAdmin);
        // it should call _grantRole
        allo.expectCall__grantRole(allo.getPool(_poolId).adminRole, _newAdmin);

        allo.changeAdmin(_poolId, _newAdmin);
    }

    function test__checkOnlyPoolManagerRevertWhen_IsNotPoolManager(uint256 _poolId, address _poolManager) external {
        // it should revert
        allo.mock_call__isPoolManager(_poolId, _poolManager, false);
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        allo.call__checkOnlyPoolManager(_poolId, _poolManager);
    }

    function test__checkOnlyPoolManagerWhenIsPoolManager(uint256 _poolId, address _poolManager) external {
        allo.mock_call__isPoolManager(_poolId, _poolManager, true);
        // it should revert
        allo.call__checkOnlyPoolManager(_poolId, _poolManager);
    }

    function test__checkOnlyPoolAdminRevertWhen_IsNotPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should revert
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, false);
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        allo.call__checkOnlyPoolAdmin(_poolId, _poolAdmin);
    }

    function test__checkOnlyPoolAdminWhenIsPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, true);
        // it should not revert
        allo.call__checkOnlyPoolAdmin(_poolId, _poolAdmin);
    }

    function test__createPoolWhenCalledValidParams(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        // it should grant admin role to creator
        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.expectCall__grantRole(POOL_ADMIN_ROLE, address(this));
        // it should set admin role to pool manager
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        allo.expectCall__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        // it should save pool on pools mapping
        // it should call initialize on the strategy
        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.expectCall(_strategy, abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(poolId));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(allo)));
        // it should add pool managers
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(poolId, _managers[i]);
            allo.expectCall__addPoolManager(poolId, _managers[i]);
        }
        // it should emit PoolCreated event
        vm.expectEmit();
        emit IAllo.PoolCreated(poolId, _profileId, IBaseStrategy(_strategy), _token, 0, _metadata);

        allo.call__createPool(
            address(this), 0, _profileId, IBaseStrategy(_strategy), _initStrategyData, _token, 0, _metadata, _managers
        );
    }

    function test__createPoolRevertWhen_IsNotOwnerOrMemberOfProfile(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, _creator),
            abi.encode(false)
        );
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        allo.call__createPool(
            _creator,
            _msgValue,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    function test__createPoolRevertWhen_StrategyPoolIdDoesNotMatch(
        uint256 _msgValue,
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.assume(_strategy != address(vm));

        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);

        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        // we set poolId to 0 so it fails here
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(0));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(allo)));
        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);

        allo.call__createPool(
            address(this),
            _msgValue,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    function test__createPoolRevertWhen_AlloAddressDoesNotMatch(
        uint256 _msgValue,
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.assume(_strategy != address(vm));

        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);

        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(poolId));
        // we change the allo address so it reverts here
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(0)));
        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);

        allo.call__createPool(
            address(this),
            _msgValue,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    modifier whenBaseFeeIsMoreThanZero() {
        vm.prank(alloOwner);
        allo.updateBaseFee(1 ether);
        _;
    }

    modifier whenTokenIsNative(address _token) {
        _token = NATIVE;
        _;
    }

    function test__createPoolRevertWhen_BaseFeePlusAmountIsDiffFromValue(
        uint256 _msgValue,
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external whenBaseFeeIsMoreThanZero whenTokenIsNative(_token) {
        vm.assume(_strategy != address(vm));
        vm.assume(_msgValue < _amount);

        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.expectCall(_strategy, abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(poolId));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(allo)));
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(poolId, _managers[i]);
        }

        // it should revert
        vm.expectRevert(Errors.ETH_MISMATCH.selector);

        allo.call__createPool(
            address(this),
            _msgValue,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    modifier whenTokenIsNotNative(address _token) {
        vm.assume(_token != NATIVE);
        _;
    }

    function test__createPoolRevertWhen_BaseFeeIsDiffFromValue(
        uint256 _msgValue,
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external whenBaseFeeIsMoreThanZero whenTokenIsNotNative(_token) {
        vm.assume(_strategy != address(vm));

        uint256 _fee = 1 ether;
        // make sure this is true so it fails
        vm.assume(_fee != _msgValue);

        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(poolId));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(allo)));
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(poolId, _managers[i]);
        }

        // it should revert
        vm.expectRevert(Errors.ETH_MISMATCH.selector);

        allo.call__createPool(
            address(this),
            _msgValue,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    function test__createPoolWhenProvidedFeeIsCorrect(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external whenBaseFeeIsMoreThanZero {
        vm.assume(_strategy != address(0));
        vm.assume(_strategy != address(vm));
        vm.assume(_strategy != address(this));
        vm.assume(_strategy != address(allo));
        vm.assume(_token != NATIVE);
        vm.assume(_token != address(vm));
        vm.assume(_token != address(fakeToken));
        vm.assume(_token != address(allo));
        vm.assume(_token != address(this));
        assumeNotPrecompile(_strategy);

        uint256 _fee = 1 ether;
        uint256 _msgValue = _fee;

        allo.mock_call__msgSender(address(this));

        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(poolId));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(allo)));
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(poolId, _managers[i]);
        }

        // it should call _transferAmount
        // TODO:

        // it should emit event
        vm.expectEmit();
        emit IAllo.BaseFeePaid(poolId, _fee);

        deal(address(this), 10 ether);
        allo.createPoolWithCustomStrategy{value: _msgValue}(
            _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );
        assertEq(address(fakeTreasury).balance, _fee);
    }

    function test__createPoolWhenAmountIsMoreThanZero(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.assume(_amount > 0);
        vm.assume(_token != NATIVE);

        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        vm.mockCall(
            _strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getPoolId.selector), abi.encode(poolId));
        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.getAllo.selector), abi.encode(address(allo)));
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(poolId, _managers[i]);
        }

        // it should call _fundPool
        allo.mock_call__fundPool(_amount, address(this), poolId, IBaseStrategy(_strategy));
        allo.expectCall__fundPool(_amount, address(this), poolId, IBaseStrategy(_strategy));

        allo.call__createPool(
            address(this),
            _amount,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    function test__fundPoolRevertWhen_TokenIsNativeAndValueIsLessThanAmount(
        uint256 _amount,
        address _funder,
        uint256 _poolId,
        IBaseStrategy _strategy
    ) external {
        vm.assume(_amount > 0);

        fakePool.token = NATIVE;
        fakePool.strategy = _strategy;
        allo.setPool(_poolId, fakePool);
        // it should revert
        vm.expectRevert(Errors.ETH_MISMATCH.selector);
        allo.call__fundPool(_amount, _funder, _poolId, _strategy);
    }

    function test__fundPoolWhenFeeAmountIsMoreThanZero(
        uint256 _amount,
        address _funder,
        uint256 _poolId,
        address _strategy
    ) external {
        uint256 _percentFee = 1e17;
        vm.assume(_strategy != address(0));
        vm.assume(_strategy != address(vm));
        vm.assume(_funder != address(0));
        vm.assume(_amount < type(uint256).max / _percentFee);
        vm.assume(_amount * _percentFee > 1e18);
        vm.assume(_funder != _strategy);

        fakePool.token = address(fakeToken);
        deal(address(fakeToken), _funder, _amount);
        vm.prank(_funder);
        fakeToken.approve(address(allo), type(uint256).max);

        vm.prank(alloOwner);
        allo.updatePercentFee(_percentFee);
        fakePool.strategy = IBaseStrategy(_strategy);
        allo.setPool(_poolId, fakePool);

        uint256 _expectedFee = (_amount * _percentFee) / 1e18;
        uint256 _expectedAmount = _amount - _expectedFee;

        vm.mockCall(
            _strategy, abi.encodeWithSelector(IBaseStrategy.increasePoolAmount.selector, _expectedAmount), abi.encode()
        );

        // transfer fee to treasury
        // it should call getBalance on the treasury
        vm.expectCall(fakePool.token, abi.encodeWithSelector(IERC20.balanceOf.selector, address(fakeTreasury)));

        // it should transfer the fee to the treasury
        vm.expectCall(
            fakePool.token,
            abi.encodeWithSelector(IERC20.transferFrom.selector, _funder, address(fakeTreasury), _expectedFee)
        );

        // it should transfer the remaining amount to the pool
        vm.expectCall(
            fakePool.token,
            abi.encodeWithSelector(IERC20.transferFrom.selector, _funder, address(_strategy), _expectedAmount)
        );

        // it should increase the pool amount
        vm.expectCall(_strategy, abi.encodeWithSelector(IBaseStrategy.increasePoolAmount.selector, _expectedAmount));

        allo.call__fundPool(_amount, _funder, _poolId, IBaseStrategy(_strategy));
    }

    function test__fundPoolWhenFeeAmountIsZero(uint256 _amount, address _funder, uint256 _poolId, address _strategy)
        external
    {
        vm.assume(_strategy != address(0));
        vm.assume(_strategy != address(vm));
        vm.assume(_funder != address(0));
        vm.assume(_amount > 0);
        vm.assume(_funder != _strategy);

        fakePool.token = address(fakeToken);
        deal(address(fakeToken), _funder, _amount);
        vm.prank(_funder);
        fakeToken.approve(address(allo), type(uint256).max);

        vm.mockCall(_strategy, abi.encodeWithSelector(IBaseStrategy.increasePoolAmount.selector, _amount), abi.encode());

        fakePool.strategy = IBaseStrategy(_strategy);
        allo.setPool(_poolId, fakePool);

        vm.expectCall(
            fakePool.token, abi.encodeWithSelector(IERC20.transferFrom.selector, _funder, address(_strategy), _amount)
        );
        // it should increase the pool amount
        vm.expectCall(_strategy, abi.encodeWithSelector(IBaseStrategy.increasePoolAmount.selector, _amount));
        // it should emit event
        vm.expectEmit();
        emit IAllo.PoolFunded(_poolId, _amount, 0);

        allo.call__fundPool(_amount, _funder, _poolId, IBaseStrategy(_strategy));
    }

    function test__isPoolAdminWhenHasRoleAdmin(uint256 _poolId, address _poolAdmin) external {
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, true);
        // it should return true
        assertTrue(allo.call__isPoolAdmin(_poolId, _poolAdmin));
    }

    function test__isPoolAdminWhenHasNoRoleAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should return false
        assertTrue(!allo.call__isPoolAdmin(_poolId, _poolAdmin));
    }

    function test__isPoolManagerWhenHasRoleManager(uint256 _poolId, address _poolManager) external {
        vm.assume(_poolManager != address(0));
        allo.call__addPoolManager(_poolId, _poolManager);
        // it should return true
        assertTrue(allo.call__isPoolManager(_poolId, _poolManager));
    }

    function test__isPoolManagerWhenHasRoleAdmin(uint256 _poolId, address _poolManager) external {
        allo.mock_call__isPoolAdmin(_poolId, _poolManager, true);
        // it should return true
        assertTrue(allo.call__isPoolManager(_poolId, _poolManager));
    }

    function test__isPoolManagerWhenHasNoRolesAtAll(uint256 _poolId, address _poolManager) external {
        // it should return false
        assertTrue(!allo.call__isPoolManager(_poolId, _poolManager));
    }

    function test_GetFeeDenominatorShouldReturnFeeDenominator() external {
        // it should return feeDenominator
        assertEq(allo.getFeeDenominator(), 1e18);
    }

    function test_IsPoolAdminShouldCall_isPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should call _isPoolAdmin
        allo.expectCall__isPoolAdmin(_poolId, _poolAdmin);
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, false);
        bool res = allo.isPoolAdmin(_poolId, _poolAdmin);
        assertEq(res, false);
    }

    function test_IsPoolAdminShouldReturnIsPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should return isPoolAdmin
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, true);
        bool res = allo.isPoolAdmin(_poolId, _poolAdmin);
        assertEq(res, true);
    }

    function test_IsPoolManagerShouldCall_isPoolManager(uint256 _poolId, address _poolManager) external {
        // it should call _isPoolManager
        allo.expectCall__isPoolManager(_poolId, _poolManager);
        allo.mock_call__isPoolManager(_poolId, _poolManager, false);
        bool res = allo.isPoolManager(_poolId, _poolManager);
        assertEq(res, false);
    }

    function test_IsPoolManagerShouldReturnIsPoolManager(uint256 _poolId, address _poolManager) external {
        // it should return isPoolManager
        allo.mock_call__isPoolManager(_poolId, _poolManager, true);
        bool res = allo.isPoolManager(_poolId, _poolManager);
        assertEq(res, true);
    }

    function test_GetStrategyShouldReturnStrategy(address _randomStrategy, uint256 _poolId) external {
        fakePool.strategy = IBaseStrategy(_randomStrategy);
        allo.setPool(_poolId, fakePool);
        // it should return strategy
        assertEq(address(allo.getStrategy(_poolId)), _randomStrategy);
    }

    function test_GetPercentFeeShouldReturnPercentFee(uint256 _percentFee) external {
        _percentFee = bound(_percentFee, 0, 1e18);
        // it should return percentFee
        allo.call__updatePercentFee(_percentFee);
        assertEq(allo.getPercentFee(), _percentFee);
    }

    function test_GetBaseFeeShouldReturnBaseFee(uint256 _baseFee) external {
        _baseFee = bound(_baseFee, 0, 1e18);
        // it should return baseFee
        allo.call__updateBaseFee(_baseFee);
        assertEq(allo.getBaseFee(), _baseFee);
    }

    function test_GetTreasuryShouldReturnTreasury(address _treasury) external {
        vm.assume(_treasury != address(0));
        // it should return treasury
        allo.call__updateTreasury(payable(_treasury));
        assertEq(allo.getTreasury(), _treasury);
    }

    function test_GetRegistryShouldReturnRegistry(address _registry) external {
        vm.assume(_registry != address(0));
        // it should return registry
        allo.call__updateRegistry(_registry);
        assertEq(address(allo.getRegistry()), _registry);
    }

    function test_GetPoolShouldReturnPool(uint256 _poolId) external {
        allo.setPool(_poolId, fakePool);
        // it should return pool
        IAllo.Pool memory pool = allo.getPool(_poolId);
        assertEq(pool.profileId, fakePool.profileId);
        assertEq(pool.token, fakePool.token);
        assertEq(address(pool.strategy), address(fakePool.strategy));
    }

    function test_IsTrustedForwarderWhenForwarderIsTrustedForwarder(address _trustedForwarder) external {
        // it should return true
        allo.call__updateTrustedForwarder(_trustedForwarder);
        assertEq(allo.isTrustedForwarder(_trustedForwarder), true);
    }

    function test_IsTrustedForwarderWhenForwarderIsNotTrustedForwarder(address _trustedForwarder) external {
        vm.assume(_trustedForwarder != address(0));
        // it should return false
        assertEq(allo.isTrustedForwarder(_trustedForwarder), false);
    }
}
