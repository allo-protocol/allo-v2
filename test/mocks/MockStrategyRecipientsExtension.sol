// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Test} from "forge-std/Test.sol";

contract MockStrategyRecipientsExtension is BaseStrategy, RecipientsExtension, Test {
    constructor(address _allo, bool _reviewEachStatus) RecipientsExtension(_allo, _reviewEachStatus) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        RecipientInitializeData memory _initializeData = abi.decode(_data, (RecipientInitializeData));
        __RecipientsExtension_init(_initializeData);
    }

    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {}

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {}

    function mock_call___RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData memory _initializeData)
        public
    {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "__RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData)", _initializeData
            ),
            abi.encode()
        );
    }

    function __RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData memory _initializeData)
        internal
        override
    {
        (bool _success, bytes memory _data) = address(this).call(
            abi.encodeWithSignature(
                "__RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData)", _initializeData
            )
        );

        if (_success) return abi.decode(_data, ());
        else return super.__RecipientsExtension_init(_initializeData);
    }

    function call___RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData memory _initializeData)
        public
    {
        return __RecipientsExtension_init(_initializeData);
    }

    function expectCall___RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData memory _initializeData)
        public
    {
        vm.expectCall(
            address(this),
            abi.encodeWithSignature(
                "__RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData)", _initializeData
            )
        );
    }

    function mock_call__getRecipientStatus(address _recipientId, IRecipientsExtension.Status _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_getRecipientStatus(address)", _recipientId),
            abi.encode(_returnParam0)
        );
    }

    function _getRecipientStatus(address _recipientId)
        internal
        view
        override
        returns (IRecipientsExtension.Status _returnParam0)
    {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_getRecipientStatus(address)", _recipientId));

        if (_success) return abi.decode(_data, (IRecipientsExtension.Status));
        else return super._getRecipientStatus(_recipientId);
    }

    function call__getRecipientStatus(address _recipientId)
        public
        returns (IRecipientsExtension.Status _returnParam0)
    {
        return _getRecipientStatus(_recipientId);
    }

    function expectCall__getRecipientStatus(address _recipientId) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_getRecipientStatus(address)", _recipientId));
    }

    function mock_call__updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "_updatePoolTimestamps(uint64,uint64)", _registrationStartTime, _registrationEndTime
            ),
            abi.encode()
        );
    }

    function _updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) internal override {
        (bool _success, bytes memory _data) = address(this).call(
            abi.encodeWithSignature(
                "_updatePoolTimestamps(uint64,uint64)", _registrationStartTime, _registrationEndTime
            )
        );

        if (_success) return abi.decode(_data, ());
        else return super._updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    function call__updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        return _updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    function expectCall__updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.expectCall(
            address(this),
            abi.encodeWithSignature(
                "_updatePoolTimestamps(uint64,uint64)", _registrationStartTime, _registrationEndTime
            )
        );
    }

    function mock_call__checkOnlyActiveRegistration() public {
        vm.mockCall(address(this), abi.encodeWithSignature("_checkOnlyActiveRegistration()"), abi.encode());
    }

    function _checkOnlyActiveRegistration() internal view override {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_checkOnlyActiveRegistration()"));

        if (_success) return abi.decode(_data, ());
        else return super._checkOnlyActiveRegistration();
    }

    function call__checkOnlyActiveRegistration() public {
        return _checkOnlyActiveRegistration();
    }

    function expectCall__checkOnlyActiveRegistration() public {
        vm.expectCall(address(this), abi.encodeWithSignature("_checkOnlyActiveRegistration()"));
    }

    function mock_call__isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature(
                "_isPoolTimestampValid(uint64,uint64)", _registrationStartTime, _registrationEndTime
            ),
            abi.encode()
        );
    }

    function _isPoolTimestampValidHelper(uint64 _registrationStartTime, uint64 _registrationEndTime) internal view {
        (bool _success, bytes memory _data) = address(this).staticcall(
            abi.encodeWithSignature(
                "_isPoolTimestampValid(uint64,uint64)", _registrationStartTime, _registrationEndTime
            )
        );

        if (_success) return abi.decode(_data, ());
        else return super._isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function call__isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        return _isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function expectCall__isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.expectCall(
            address(this),
            abi.encodeWithSignature(
                "_isPoolTimestampValid(uint64,uint64)", _registrationStartTime, _registrationEndTime
            )
        );
    }

    function __isPoolTimestampValidCastToPure(function(uint64, uint64) internal view fnIn)
        internal
        pure
        returns (function(uint64, uint64) internal pure fnOut)
    {
        assembly {
            fnOut := fnIn
        }
    }

    function _isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime) internal pure override {
        return
            __isPoolTimestampValidCastToPure(_isPoolTimestampValidHelper)(_registrationStartTime, _registrationEndTime);
    }

    function mock_call__isPoolActive(bool _returnParam0) public {
        vm.mockCall(address(this), abi.encodeWithSignature("_isPoolActive()"), abi.encode(_returnParam0));
    }

    function _isPoolActive() internal view override returns (bool _returnParam0) {
        (bool _success, bytes memory _data) = address(this).staticcall(abi.encodeWithSignature("_isPoolActive()"));

        if (_success) return abi.decode(_data, (bool));
        else return super._isPoolActive();
    }

    function call__isPoolActive() public returns (bool _returnParam0) {
        return _isPoolActive();
    }

    function expectCall__isPoolActive() public {
        vm.expectCall(address(this), abi.encodeWithSignature("_isPoolActive()"));
    }

    function mock_call__register(
        address[] memory __recipients,
        bytes memory _data,
        address _sender,
        address[] memory _recipientIds
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_register(address[],bytes,address)", __recipients, _data, _sender),
            abi.encode(_recipientIds)
        );
    }

    function _register(address[] memory __recipients, bytes memory _data, address _sender)
        internal
        override(BaseStrategy, RecipientsExtension)
        returns (address[] memory _recipientIds)
    {
        (bool _success, bytes memory __data) = address(this).call(
            abi.encodeWithSignature("_register(address[],bytes,address)", __recipients, _data, _sender)
        );

        if (_success) return abi.decode(__data, (address[]));
        else return super._register(__recipients, _data, _sender);
    }

    function call__register(address[] memory __recipients, bytes memory _data, address _sender)
        public
        returns (address[] memory _recipientIds)
    {
        return _register(__recipients, _data, _sender);
    }

    function expectCall__register(address[] memory __recipients, bytes memory _data, address _sender) public {
        vm.expectCall(
            address(this), abi.encodeWithSignature("_register(address[],bytes,address)", __recipients, _data, _sender)
        );
    }

    function mock_call__getRecipient(address _recipientId, IRecipientsExtension.Recipient memory _returnParam0)
        public
    {
        vm.mockCall(
            address(this), abi.encodeWithSignature("_getRecipient(address)", _recipientId), abi.encode(_returnParam0)
        );
    }

    function _getRecipient(address _recipientId)
        internal
        view
        override
        returns (IRecipientsExtension.Recipient memory _returnParam0)
    {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_getRecipient(address)", _recipientId));

        if (_success) return abi.decode(_data, (IRecipientsExtension.Recipient));
        else return super._getRecipient(_recipientId);
    }

    function call__getRecipient(address _recipientId)
        public
        returns (IRecipientsExtension.Recipient memory _returnParam0)
    {
        return _getRecipient(_recipientId);
    }

    function expectCall__getRecipient(address _recipientId) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_getRecipient(address)", _recipientId));
    }

    function mock_call__setRecipientStatus(address _recipientId, uint256 _status) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_setRecipientStatus(address,uint256)", _recipientId, _status),
            abi.encode()
        );
    }

    function _setRecipientStatus(address _recipientId, uint256 _status) internal override {
        (bool _success, bytes memory _data) =
            address(this).call(abi.encodeWithSignature("_setRecipientStatus(address,uint256)", _recipientId, _status));

        if (_success) return abi.decode(_data, ());
        else return super._setRecipientStatus(_recipientId, _status);
    }

    function call__setRecipientStatus(address _recipientId, uint256 _status) public {
        return _setRecipientStatus(_recipientId, _status);
    }

    function expectCall__setRecipientStatus(address _recipientId, uint256 _status) public {
        vm.expectCall(
            address(this), abi.encodeWithSignature("_setRecipientStatus(address,uint256)", _recipientId, _status)
        );
    }

    function mock_call__getUintRecipientStatus(address _recipientId, uint8 status) public {
        vm.mockCall(
            address(this), abi.encodeWithSignature("_getUintRecipientStatus(address)", _recipientId), abi.encode(status)
        );
    }

    function _getUintRecipientStatus(address _recipientId) internal view override returns (uint8 status) {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_getUintRecipientStatus(address)", _recipientId));

        if (_success) return abi.decode(_data, (uint8));
        else return super._getUintRecipientStatus(_recipientId);
    }

    function call__getUintRecipientStatus(address _recipientId) public returns (uint8 status) {
        return _getUintRecipientStatus(_recipientId);
    }

    function expectCall__getUintRecipientStatus(address _recipientId) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_getUintRecipientStatus(address)", _recipientId));
    }

    function mock_call__getStatusRowColumn(
        address _recipientId,
        uint256 _returnParam0,
        uint256 _returnParam1,
        uint256 _returnParam2
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_getStatusRowColumn(address)", _recipientId),
            abi.encode(_returnParam0, _returnParam1, _returnParam2)
        );
    }

    function _getStatusRowColumn(address _recipientId)
        internal
        view
        override
        returns (uint256 _returnParam0, uint256 _returnParam1, uint256 _returnParam2)
    {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_getStatusRowColumn(address)", _recipientId));

        if (_success) return abi.decode(_data, (uint256, uint256, uint256));
        else return super._getStatusRowColumn(_recipientId);
    }

    function call__getStatusRowColumn(address _recipientId)
        public
        returns (uint256 _returnParam0, uint256 _returnParam1, uint256 _returnParam2)
    {
        return _getStatusRowColumn(_recipientId);
    }

    function expectCall__getStatusRowColumn(address _recipientId) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_getStatusRowColumn(address)", _recipientId));
    }

    function mock_call__extractRecipientAndMetadata(
        bytes memory _data,
        address _sender,
        address _returnParam0,
        bool _returnParam1,
        Metadata memory _returnParam2,
        bytes memory _returnParam3
    ) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_extractRecipientAndMetadata(bytes,address)", _data, _sender),
            abi.encode(_returnParam0, _returnParam1, _returnParam2, _returnParam3)
        );
    }

    function _extractRecipientAndMetadata(bytes memory _data, address _sender)
        internal
        view
        override
        returns (address recipientId, bool isUsingRegistryAnchor, Metadata memory metadata, bytes memory _extraData)
    {
        (bool _success, bytes memory __data) = address(this).staticcall(
            abi.encodeWithSignature("_extractRecipientAndMetadata(bytes,address)", _data, _sender)
        );

        if (_success) return abi.decode(__data, (address, bool, Metadata, bytes));
        else return super._extractRecipientAndMetadata(_data, _sender);
    }

    function call__extractRecipientAndMetadata(bytes memory _data, address _sender)
        public
        returns (address recipientId, bool isUsingRegistryAnchor, Metadata memory metadata, bytes memory _extraData)
    {
        return _extractRecipientAndMetadata(_data, _sender);
    }

    function expectCall__extractRecipientAndMetadata(bytes memory _data, address _sender) public {
        vm.expectCall(
            address(this), abi.encodeWithSignature("_extractRecipientAndMetadata(bytes,address)", _data, _sender)
        );
    }

    function mock_call__isProfileMember(address _anchor, address _sender, bool _returnParam0) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("_isProfileMember(address,address)", _anchor, _sender),
            abi.encode(_returnParam0)
        );
    }

    function _isProfileMember(address _anchor, address _sender) internal view override returns (bool _returnParam0) {
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature("_isProfileMember(address,address)", _anchor, _sender));

        if (_success) return abi.decode(_data, (bool));
        else return super._isProfileMember(_anchor, _sender);
    }

    function call__isProfileMember(address _anchor, address _sender) public returns (bool _returnParam0) {
        return _isProfileMember(_anchor, _sender);
    }

    function expectCall__isProfileMember(address _anchor, address _sender) public {
        vm.expectCall(address(this), abi.encodeWithSignature("_isProfileMember(address,address)", _anchor, _sender));
    }

    function set_recipientsCounter(uint256 _recipientsCounter) public {
        recipientsCounter = _recipientsCounter;
    }

    function set_registrationStartTime(uint64 _registrationStartTime) public {
        registrationStartTime = _registrationStartTime;
    }

    function set_registrationEndTime(uint64 _registrationEndTime) public {
        registrationEndTime = _registrationEndTime;
    }

    function set__recipients(address _key0, IRecipientsExtension.Recipient memory _value) public {
        _recipients[_key0] = _value;
    }

    function set_recipientToStatusIndexes(address _key0, uint64 _value) public {
        _recipients[_key0].statusIndex = _value;
    }

    function set_recipientIndexToRecipientId(uint256 _key0, address _value) public {
        recipientIndexToRecipientId[_key0] = _value;
    }

    function set_statusesBitMap(uint256 _key0, uint256 _value) public {
        statusesBitMap[_key0] = _value;
    }

    function set_metadataRequired(bool _metadataRequired) public {
        metadataRequired = _metadataRequired;
    }

    bool internal forceAccept;

    event ReviewRecipientStatus(Status _newStatus, Status _oldStatus, uint256 _recipientIndex);

    function expose_processStatusRow(uint256 _rowIndex, uint256 _fullRow, bool _forceAccept)
        external
        returns (uint256)
    {
        forceAccept = _forceAccept;
        return _processStatusRow(_rowIndex, _fullRow);
    }

    function _reviewRecipientStatus(Status _newStatus, Status _oldStatus, uint256 _recipientIndex)
        internal
        virtual
        override
        returns (Status _reviewedStatus)
    {
        emit ReviewRecipientStatus(_newStatus, _oldStatus, _recipientIndex);
        if (forceAccept) {
            return Status.Accepted;
        } else {
            return super._reviewRecipientStatus(_newStatus, _oldStatus, _recipientIndex);
        }
    }
}
