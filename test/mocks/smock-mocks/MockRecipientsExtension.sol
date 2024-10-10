// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract MockRecipientsExtension is BaseStrategy, RecipientsExtension {
    constructor(address _allo, string memory _strategyName, bool _reviewEachStatus)
        RecipientsExtension(_allo, _strategyName, _reviewEachStatus)
    {}

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

    function __RecipientsExtension_init(IRecipientsExtension.RecipientInitializeData memory _initializeData)
        internal
        virtual
        override
    {
        super.__RecipientsExtension_init(_initializeData);
    }

    function _getRecipientStatus(address _recipientId)
        internal
        view
        virtual
        override
        returns (IRecipientsExtension.Status _returnParam0)
    {
        return super._getRecipientStatus(_recipientId);
    }

    function _updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime)
        internal
        virtual
        override
    {
        super._updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    function _checkOnlyActiveRegistration() internal view virtual override {
        super._checkOnlyActiveRegistration();
    }

    function _isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime)
        internal
        view
        virtual
        override
    {
        super._isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function _isPoolActive() internal view virtual override returns (bool _returnParam0) {
        return super._isPoolActive();
    }

    function _register(address[] memory __recipients, bytes memory __data, address _sender)
        internal
        virtual
        override(BaseStrategy, RecipientsExtension)
        returns (address[] memory _recipientIds)
    {
        return super._register(__recipients, __data, _sender);
    }

    function _getRecipient(address _recipientId)
        internal
        view
        virtual
        override
        returns (IRecipientsExtension.Recipient memory _returnParam0)
    {
        return super._getRecipient(_recipientId);
    }

    function _setRecipientStatus(address _recipientId, uint256 _status) internal virtual override {
        super._setRecipientStatus(_recipientId, _status);
    }

    function _getUintRecipientStatus(address _recipientId) internal view virtual override returns (uint8 status) {
        return super._getUintRecipientStatus(_recipientId);
    }

    function _getStatusRowColumn(address _recipientId)
        internal
        view
        virtual
        override
        returns (uint256 _returnParam0, uint256 _returnParam1, uint256 _returnParam2)
    {
        return super._getStatusRowColumn(_recipientId);
    }

    function _extractRecipientAndMetadata(bytes memory __data, address _sender)
        internal
        view
        virtual
        override
        returns (address recipientId, bool isUsingRegistryAnchor, Metadata memory metadata, bytes memory _extraData)
    {
        return super._extractRecipientAndMetadata(__data, _sender);
    }

    function _processStatusRow(uint256 _rowIndex, uint256 _fullRow)
        internal
        virtual
        override
        returns (uint256 _returnParam0)
    {
        return super._processStatusRow(_rowIndex, _fullRow);
    }

    function _reviewRecipientStatus(Status _newStatus, Status _oldStatus, uint256 _recipientIndex)
        internal
        virtual
        override
        returns (Status _reviewedStatus)
    {
        return super._reviewRecipientStatus(_newStatus, _oldStatus, _recipientIndex);
    }

    function _isProfileMember(address _anchor, address _sender)
        internal
        view
        virtual
        override
        returns (bool _returnParam0)
    {
        return super._isProfileMember(_anchor, _sender);
    }

    function _checkOnlyPoolManager(address _sender) internal view virtual override {
        super._checkOnlyPoolManager(_sender);
    }

    function _validateReviewRecipients(address _sender) internal virtual override {
        super._validateReviewRecipients(_sender);
    }

    function _processRecipient(
        address _recipientId,
        bool _isUsingRegistryAnchor,
        Metadata memory _metadata,
        bytes memory _extraData
    ) internal virtual override {
        super._processRecipient(_recipientId, _isUsingRegistryAnchor, _metadata, _extraData);
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
}
