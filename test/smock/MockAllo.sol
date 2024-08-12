// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {
    AccessControlUpgradeable,
    AddressUpgradeable,
    Allo,
    Clone,
    ContextUpgradeable,
    ERC165Upgradeable,
    Errors,
    IAccessControlUpgradeable,
    IAllo,
    IERC165Upgradeable,
    IERC20Upgradeable,
    IRegistry,
    IStrategy,
    Initializable,
    MathUpgradeable,
    Metadata,
    Native,
    Ownable,
    ReentrancyGuardUpgradeable,
    SignedMathUpgradeable,
    StringsUpgradeable,
    Transfer
} from "../../contracts/core/Allo.sol";

contract MockAllo is Allo, Test {
    function set_baseFee(uint256 _baseFee) public {
        baseFee = _baseFee;
    }

    function call_baseFee() public view returns (uint256) {
        return baseFee;
    }

    function mock_call_initialize(
        address _owner,
        address _registry,
        address payable _treasury,
        uint256 _percentFee,
        uint256 _baseFee,
        address __trustedForwarder
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "initialize(address,address,address payable,uint256,uint256,address)",
                _owner,
                _registry,
                _treasury,
                _percentFee,
                _baseFee,
                __trustedForwarder
            ),
            abi.encode()
        );
    }

    function mock_call_createPoolWithCustomStrategy(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 poolId
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "createPoolWithCustomStrategy(bytes32,address,bytes,address,uint256,Metadata,address[])",
                _profileId,
                _strategy,
                _initStrategyData,
                _token,
                _amount,
                _metadata,
                _managers
            ),
            abi.encode(poolId)
        );
    }

    function mock_call_createPool(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 poolId
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "createPool(bytes32,address,bytes,address,uint256,Metadata,address[])",
                _profileId,
                _strategy,
                _initStrategyData,
                _token,
                _amount,
                _metadata,
                _managers
            ),
            abi.encode(poolId)
        );
    }

    function mock_call_updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("updatePoolMetadata(uint256,Metadata)", _poolId, _metadata),
            abi.encode()
        );
    }

    function mock_call_updateRegistry(address _registry) public {
        vm.mockCall(address(this), abi.encodeWithSignature("updateRegistry(address)", _registry), abi.encode());
    }

    function mock_call_updateTreasury(address payable _treasury) public {
        vm.mockCall(address(this), abi.encodeWithSignature("updateTreasury(address payable)", _treasury), abi.encode());
    }

    function mock_call_updatePercentFee(uint256 _percentFee) public {
        vm.mockCall(address(this), abi.encodeWithSignature("updatePercentFee(uint256)", _percentFee), abi.encode());
    }

    function mock_call_updateBaseFee(uint256 _baseFee) public {
        vm.mockCall(address(this), abi.encodeWithSignature("updateBaseFee(uint256)", _baseFee), abi.encode());
    }

    function mock_call_updateTrustedForwarder(address __trustedForwarder) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("updateTrustedForwarder(address)", __trustedForwarder), abi.encode()
        );
    }

    function mock_call_addPoolManagers(uint256 _poolId, address[] calldata _managers) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("addPoolManagers(uint256,address[])", _poolId, _managers),
            abi.encode()
        );
    }

    function mock_call_removePoolManagers(uint256 _poolId, address[] calldata _managers) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("removePoolManagers(uint256,address[])", _poolId, _managers),
            abi.encode()
        );
    }

    function mock_call_addPoolManagersInMultiplePools(uint256[] calldata _poolIds, address[] calldata _managers)
        public
    {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("addPoolManagersInMultiplePools(uint256[],address[])", _poolIds, _managers),
            abi.encode()
        );
    }

    function mock_call_removePoolManagersInMultiplePools(uint256[] calldata _poolIds, address[] calldata _managers)
        public
    {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("removePoolManagersInMultiplePools(uint256[],address[])", _poolIds, _managers),
            abi.encode()
        );
    }

    function mock_call_recoverFunds(address _token, address _recipient) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("recoverFunds(address,address)", _token, _recipient), abi.encode()
        );
    }

    function mock_call_registerRecipient(uint256 _poolId, bytes memory _data, address _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("registerRecipient(uint256,bytes)", _poolId, _data),
            abi.encode(_returnParam0)
        );
    }

    function mock_call_batchRegisterRecipient(
        uint256[] memory _poolIds,
        bytes[] memory _data,
        address[] memory recipientIds
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("batchRegisterRecipient(uint256[],bytes[])", _poolIds, _data),
            abi.encode(recipientIds)
        );
    }

    function mock_call_fundPool(uint256 _poolId, uint256 _amount) public {
        vm.mockCall(address(this), abi.encodeWithSignature("fundPool(uint256,uint256)", _poolId, _amount), abi.encode());
    }

    function mock_call_allocate(uint256 _poolId, bytes memory _data) public {
        vm.mockCall(address(this), abi.encodeWithSignature("allocate(uint256,bytes)", _poolId, _data), abi.encode());
    }

    function mock_call_batchAllocate(uint256[] calldata _poolIds, uint256[] calldata _values, bytes[] memory _datas)
        public
    {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("batchAllocate(uint256[],uint256[],bytes[])", _poolIds, _values, _datas),
            abi.encode()
        );
    }

    function mock_call_distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("distribute(uint256,address[],bytes)", _poolId, _recipientIds, _data),
            abi.encode()
        );
    }

    function mock_call_changeAdmin(uint256 _poolId, address _newAdmin) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("changeAdmin(uint256,address)", _poolId, _newAdmin), abi.encode()
        );
    }

    function mock_call__checkOnlyPoolManager(uint256 _poolId, address _address) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_checkOnlyPoolManager(uint256,address)", _poolId, _address),
            abi.encode()
        );
    }

    function _checkOnlyPoolManager(uint256 _poolId, address _address) internal view override {
        (bool _success, bytes memory _data) = address(this).staticcall(
            abi.encodeWithSignature("_checkOnlyPoolManager(uint256,address)", _poolId, _address)
        );

        if (_success) return abi.decode(_data, ());
        else return super._checkOnlyPoolManager(_poolId, _address);
    }

    function call__checkOnlyPoolManager(uint256 _poolId, address _address) public {
        return _checkOnlyPoolManager(_poolId, _address);
    }

    function expectCall__checkOnlyPoolManager(uint256 _poolId, address _address) public {
        vm.expectCall(
            address(this), abi.encodeWithSignature("_checkOnlyPoolManager(uint256,address)", _poolId, _address)
        );
    }

    function mock_call__checkOnlyPoolAdmin(uint256 _poolId, address _address) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_checkOnlyPoolAdmin(uint256,address)", _poolId, _address),
            abi.encode()
        );
    }

    function _checkOnlyPoolAdmin(uint256 _poolId, address _address) internal view override {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_checkOnlyPoolAdmin(uint256,address)", _poolId, _address));

        if (_success) return abi.decode(_data, ());
        else return super._checkOnlyPoolAdmin(_poolId, _address);
    }

    function call__checkOnlyPoolAdmin(uint256 _poolId, address _address) public {
        return _checkOnlyPoolAdmin(_poolId, _address);
    }

    function expectCall__checkOnlyPoolAdmin(uint256 _poolId, address _address) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_checkOnlyPoolAdmin(uint256,address)", _poolId, _address));
    }

    function mock_call__createPool(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 poolId
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "_createPool(address,uint256,bytes32,IStrategy,bytes,address,uint256,Metadata,address[])",
                _creator,
                _msgValue,
                _profileId,
                _strategy,
                _initStrategyData,
                _token,
                _amount,
                _metadata,
                _managers
            ),
            abi.encode(poolId)
        );
    }

    function _createPool(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) internal override returns (uint256 poolId) {
        (bool _success, bytes memory _data) = address(this).call(
            abi.encodeWithSignature(
                "_createPool(address,uint256,bytes32,IStrategy,bytes,address,uint256,Metadata,address[])",
                _creator,
                _msgValue,
                _profileId,
                _strategy,
                _initStrategyData,
                _token,
                _amount,
                _metadata,
                _managers
            )
        );

        if (_success) {
            return abi.decode(_data, (uint256));
        } else {
            return super._createPool(
                _creator, _msgValue, _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
            );
        }
    }

    function call__createPool(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) public returns (uint256 poolId) {
        return _createPool(
            _creator, _msgValue, _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );
    }

    function expectCall__createPool(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) public {
        vm.expectCall(
            address(this),
            abi.encodeWithSignature(
                "_createPool(address,uint256,bytes32,IStrategy,bytes,address,uint256,Metadata,address[])",
                _creator,
                _msgValue,
                _profileId,
                _strategy,
                _initStrategyData,
                _token,
                _amount,
                _metadata,
                _managers
            )
        );
    }

    function mock_call__allocate(uint256 _poolId, address _allocator, uint256 _value, bytes memory _data) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_allocate(uint256,address,uint256,bytes)", _poolId, _allocator, _value, _data),
            abi.encode()
        );
    }

    function _allocate(uint256 _poolId, address _allocator, uint256 _value, bytes memory _data) internal override {
        (bool _success, bytes memory _data) = address(this).call(
            abi.encodeWithSignature("_allocate(uint256,address,uint256,bytes)", _poolId, _allocator, _value, _data)
        );

        if (_success) return abi.decode(_data, ());
        else return super._allocate(_poolId, _allocator, _value, _data);
    }

    function call__allocate(uint256 _poolId, address _allocator, uint256 _value, bytes memory _data) public {
        return _allocate(_poolId, _allocator, _value, _data);
    }

    function expectCall__allocate(uint256 _poolId, address _allocator, uint256 _value, bytes memory _data) public {
        vm.expectCall(
            address(this),
            abi.encodeWithSignature("_allocate(uint256,address,uint256,bytes)", _poolId, _allocator, _value, _data)
        );
    }

    function mock_call__fundPool(uint256 _amount, address _funder, uint256 _poolId, IStrategy _strategy) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "_fundPool(uint256,address,uint256,IStrategy)", _amount, _funder, _poolId, _strategy
            ),
            abi.encode()
        );
    }

    function _fundPool(uint256 _amount, address _funder, uint256 _poolId, IStrategy _strategy) internal override {
        (bool _success, bytes memory _data) = address(this).call(
            abi.encodeWithSignature(
                "_fundPool(uint256,address,uint256,IStrategy)", _amount, _funder, _poolId, _strategy
            )
        );

        if (_success) return abi.decode(_data, ());
        else return super._fundPool(_amount, _funder, _poolId, _strategy);
    }

    function call__fundPool(uint256 _amount, address _funder, uint256 _poolId, IStrategy _strategy) public {
        return _fundPool(_amount, _funder, _poolId, _strategy);
    }

    function expectCall__fundPool(uint256 _amount, address _funder, uint256 _poolId, IStrategy _strategy) public {
        vm.expectCall(
            address(this),
            abi.encodeWithSignature(
                "_fundPool(uint256,address,uint256,IStrategy)", _amount, _funder, _poolId, _strategy
            )
        );
    }

    function mock_call__isPoolAdmin(uint256 _poolId, address _address, bool _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_isPoolAdmin(uint256,address)", _poolId, _address),
            abi.encode(_returnParam0)
        );
    }

    function _isPoolAdmin(uint256 _poolId, address _address) internal view override returns (bool _returnParam0) {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_isPoolAdmin(uint256,address)", _poolId, _address));

        if (_success) return abi.decode(_data, (bool));
        else return super._isPoolAdmin(_poolId, _address);
    }

    function call__isPoolAdmin(uint256 _poolId, address _address) public returns (bool _returnParam0) {
        return _isPoolAdmin(_poolId, _address);
    }

    function expectCall__isPoolAdmin(uint256 _poolId, address _address) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_isPoolAdmin(uint256,address)", _poolId, _address));
    }

    function mock_call__isPoolManager(uint256 _poolId, address _address, bool _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_isPoolManager(uint256,address)", _poolId, _address),
            abi.encode(_returnParam0)
        );
    }

    function _isPoolManager(uint256 _poolId, address _address) internal view override returns (bool _returnParam0) {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_isPoolManager(uint256,address)", _poolId, _address));

        if (_success) return abi.decode(_data, (bool));
        else return super._isPoolManager(_poolId, _address);
    }

    function call__isPoolManager(uint256 _poolId, address _address) public returns (bool _returnParam0) {
        return _isPoolManager(_poolId, _address);
    }

    function expectCall__isPoolManager(uint256 _poolId, address _address) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_isPoolManager(uint256,address)", _poolId, _address));
    }

    function mock_call__updateRegistry(address _registry) public {
        vm.mockCall(address(this), abi.encodeWithSignature("_updateRegistry(address)", _registry), abi.encode());
    }

    function _updateRegistry(address _registry) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_updateRegistry(address)", _registry));

        if (_success) return abi.decode(_data, ());
        else return super._updateRegistry(_registry);
    }

    function call__updateRegistry(address _registry) public {
        return _updateRegistry(_registry);
    }

    function expectCall__updateRegistry(address _registry) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_updateRegistry(address)", _registry));
    }

    function mock_call__updateTreasury(address payable _treasury) public {
        vm.mockCall(address(this), abi.encodeWithSignature("_updateTreasury(address payable)", _treasury), abi.encode());
    }

    function _updateTreasury(address payable _treasury) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_updateTreasury(address payable)", _treasury));

        if (_success) return abi.decode(_data, ());
        else return super._updateTreasury(_treasury);
    }

    function call__updateTreasury(address payable _treasury) public {
        return _updateTreasury(_treasury);
    }

    function expectCall__updateTreasury(address payable _treasury) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_updateTreasury(address payable)", _treasury));
    }

    function mock_call__updatePercentFee(uint256 _percentFee) public {
        vm.mockCall(address(this), abi.encodeWithSignature("_updatePercentFee(uint256)", _percentFee), abi.encode());
    }

    function _updatePercentFee(uint256 _percentFee) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_updatePercentFee(uint256)", _percentFee));

        if (_success) return abi.decode(_data, ());
        else return super._updatePercentFee(_percentFee);
    }

    function call__updatePercentFee(uint256 _percentFee) public {
        return _updatePercentFee(_percentFee);
    }

    function expectCall__updatePercentFee(uint256 _percentFee) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_updatePercentFee(uint256)", _percentFee));
    }

    function mock_call__updateBaseFee(uint256 _baseFee) public {
        vm.mockCall(address(this), abi.encodeWithSignature("_updateBaseFee(uint256)", _baseFee), abi.encode());
    }

    function _updateBaseFee(uint256 _baseFee) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_updateBaseFee(uint256)", _baseFee));

        if (_success) return abi.decode(_data, ());
        else return super._updateBaseFee(_baseFee);
    }

    function call__updateBaseFee(uint256 _baseFee) public {
        return _updateBaseFee(_baseFee);
    }

    function expectCall__updateBaseFee(uint256 _baseFee) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_updateBaseFee(uint256)", _baseFee));
    }

    function mock_call__updateTrustedForwarder(address __trustedForwarder) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("_updateTrustedForwarder(address)", __trustedForwarder), abi.encode()
        );
    }

    function _updateTrustedForwarder(address __trustedForwarder) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_updateTrustedForwarder(address)", __trustedForwarder));

        if (_success) return abi.decode(_data, ());
        else return super._updateTrustedForwarder(__trustedForwarder);
    }

    function call__updateTrustedForwarder(address __trustedForwarder) public {
        return _updateTrustedForwarder(__trustedForwarder);
    }

    function expectCall__updateTrustedForwarder(address __trustedForwarder) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_updateTrustedForwarder(address)", __trustedForwarder));
    }

    function mock_call__addPoolManager(uint256 _poolId, address _manager) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("_addPoolManager(uint256,address)", _poolId, _manager), abi.encode()
        );
    }

    function _addPoolManager(uint256 _poolId, address _manager) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_addPoolManager(uint256,address)", _poolId, _manager));

        if (_success) return abi.decode(_data, ());
        else return super._addPoolManager(_poolId, _manager);
    }

    function call__addPoolManager(uint256 _poolId, address _manager) public {
        return _addPoolManager(_poolId, _manager);
    }

    function expectCall__addPoolManager(uint256 _poolId, address _manager) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_addPoolManager(uint256,address)", _poolId, _manager));
    }

    function mock_call__msgSender(address _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("_msgSender()"), abi.encode(_returnParam0));
    }

    function _msgSender() internal view override returns (address _returnParam0) {
        (bool _success, bytes memory _data) = address(this).staticcall(abi.encodeWithSignature("_msgSender()"));

        if (_success) return abi.decode(_data, (address));
        else return super._msgSender();
    }

    function call__msgSender() public returns (address _returnParam0) {
        return _msgSender();
    }

    function expectCall__msgSender() public {
        vm.expectCall(address(this), abi.encodeWithSignature("_msgSender()"));
    }

    function mock_call_getFeeDenominator(uint256 FEE_DENOMINATOR) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getFeeDenominator()"), abi.encode(FEE_DENOMINATOR));
    }

    function mock_call_isPoolAdmin(uint256 _poolId, address _address, bool _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("isPoolAdmin(uint256,address)", _poolId, _address),
            abi.encode(_returnParam0)
        );
    }

    function mock_call_isPoolManager(uint256 _poolId, address _address, bool _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("isPoolManager(uint256,address)", _poolId, _address),
            abi.encode(_returnParam0)
        );
    }

    function mock_call_getStrategy(uint256 _poolId, address _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getStrategy(uint256)", _poolId), abi.encode(_returnParam0));
    }

    function mock_call_getPercentFee(uint256 _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getPercentFee()"), abi.encode(_returnParam0));
    }

    function mock_call_getBaseFee(uint256 _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getBaseFee()"), abi.encode(_returnParam0));
    }

    function mock_call_getTreasury(address payable _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getTreasury()"), abi.encode(_returnParam0));
    }

    function mock_call_getRegistry(IRegistry _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getRegistry()"), abi.encode(_returnParam0));
    }

    function mock_call_getPool(uint256 _poolId, IAllo.Pool memory _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("getPool(uint256)", _poolId), abi.encode(_returnParam0));
    }

    function mock_call_isTrustedForwarder(address forwarder, bool _returnParam0) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("isTrustedForwarder(address)", forwarder), abi.encode(_returnParam0)
        );
    }
}
